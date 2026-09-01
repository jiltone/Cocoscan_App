import 'dart:io';

/// Web build of the TFLite service. `tflite_flutter` depends on `dart:ffi`,
/// which Flutter Web does not support, so this platform always reports
/// "not ready" and `InferenceService` falls back to calling the FastAPI
/// `/api/classify` endpoint instead (see tflite_service.dart for the
/// conditional export that picks this file on web).
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

class TfliteService {
  static final TfliteService _instance = TfliteService._internal();
  factory TfliteService() => _instance;
  TfliteService._internal();

  bool get isReady => false;
  List<String> get classNames => const [];

  Future<bool> loadModel() async => false;

  Future<ClassificationResult> classify(File imageFile) async {
    throw StateError(
      'On-device TFLite inference is not available on this platform (web). '
      'Use InferenceService, which falls back to the FastAPI backend automatically.',
    );
  }

  void dispose() {}
}
