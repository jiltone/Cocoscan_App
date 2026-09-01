import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Confidence tiers used across Result/History/Analytics screens
/// (report Section 3.7.1 / 5.4): >=85% Confirmed, >=60% Uncertain,
/// otherwise Low_Confidence.
enum ConfidenceTier { confirmed, uncertain, lowConfidence }

class ClassificationResult {
  final String label;
  final double confidence;
  final ConfidenceTier tier;
  final Map<String, double> probabilities;

  const ClassificationResult({
    required this.label,
    required this.confidence,
    required this.tier,
    required this.probabilities,
  });
}

/// On-device TFLite inference service (report Section 4.2.1).
///
/// The model was converted with post-training DEFAULT quantisation from a
/// ResNet50-derived classifier, so the input must be normalised with the
/// same "caffe style" mean subtraction ResNet50 uses at training time — a
/// mismatch here (e.g. EfficientNet-style [-1, 1] scaling) would produce
/// plausible-looking but systematically wrong predictions rather than an
/// obvious failure.
class TfliteService {
  static final TfliteService _instance = TfliteService._internal();
  factory TfliteService() => _instance;
  TfliteService._internal();

  static const int inputSize = 224;
  // ImageNet BGR channel means used by tf.keras.applications.resnet50
  // preprocess_input (mode='caffe').
  static const List<double> _bgrMeans = [103.939, 116.779, 123.68];

  Interpreter? _interpreter;
  List<String> _classNames = [];
  bool _isReady = false;

  bool get isReady => _isReady;
  List<String> get classNames => List.unmodifiable(_classNames);

  Future<bool> loadModel() async {
    if (_isReady) return true;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/coconut_disease_model.tflite',
      );
      final labelsRaw = await rootBundle.loadString(
        'assets/models/class_names.txt',
      );
      _classNames = labelsRaw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _isReady = _interpreter != null && _classNames.isNotEmpty;
      return _isReady;
    } catch (e) {
      // Asset not bundled yet (see assets/models/README.md) — caller should
      // fall back to the server-side /api/classify endpoint.
      _isReady = false;
      return false;
    }
  }

  /// Builds the [1, 224, 224, 3] nested input tensor tflite_flutter expects,
  /// with RGB -> BGR channel order and ImageNet caffe-style mean subtraction.
  List<List<List<List<double>>>> _preprocess(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image at ${imageFile.path}');
    }
    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            pixel.b - _bgrMeans[0],
            pixel.g - _bgrMeans[1],
            pixel.r - _bgrMeans[2],
          ];
        });
      }),
    ];
  }

  ConfidenceTier _tierFor(double confidence) {
    if (confidence >= 0.85) return ConfidenceTier.confirmed;
    if (confidence >= 0.60) return ConfidenceTier.uncertain;
    return ConfidenceTier.lowConfidence;
  }

  Future<ClassificationResult> classify(File imageFile) async {
    if (!_isReady) {
      final loaded = await loadModel();
      if (!loaded) {
        throw StateError(
          'TFLite model/labels not bundled. Add assets/models/coconut_disease_model.tflite '
          'and class_names.txt, or use BackendService.predict() for server-side inference.',
        );
      }
    }

    final input = _preprocess(imageFile);
    final output = [List.filled(_classNames.length, 0.0)];

    _interpreter!.run(input, output);

    final probs = output[0];
    var topIndex = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[topIndex]) topIndex = i;
    }

    final probabilities = <String, double>{
      for (var i = 0; i < _classNames.length; i++) _classNames[i]: probs[i],
    };

    final confidence = probs[topIndex];
    return ClassificationResult(
      label: _classNames[topIndex],
      confidence: confidence,
      tier: _tierFor(confidence),
      probabilities: probabilities,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isReady = false;
  }
}
