import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

import 'tflite_service.dart';

/// The single entry point screens should call to classify a leaf photo.
///
/// Mirrors the degrade-gracefully behaviour described in report Section 4.1:
/// classification tries on-device TFLite first (works offline in a
/// plantation with no signal); if the bundled model/labels aren't present it
/// falls back to the FastAPI `/api/classify` endpoint over HTTP.
///
/// Image data is always passed as bytes, never a file path — `dart:io`'s
/// `File` (and anything built on `http.MultipartFile.fromPath`) silently
/// throws `Unsupported operation: Platform._operatingSystem` on Flutter
/// Web, since dart:io compiles there but most of it isn't actually
/// implemented. `file` is accepted only to enable the on-device TFLite path
/// on native platforms — pass null on web (it's ignored there anyway, since
/// tflite_service_stub.dart always reports "not ready").
class InferenceService {
  /// Points at backend_python's uvicorn server. Auto-picks a sane default
  /// per platform, but a physical device on the same Wi-Fi still needs this
  /// overridden to your machine's LAN IP (e.g. 'http://192.168.1.23:8000')
  /// — that can't be auto-detected.
  static String baseUrl = _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    // 10.0.2.2 is the Android emulator's alias for the host machine's
    // localhost — unreachable from anywhere else (web, desktop, a real
    // phone), which is exactly the class of bug that silently broke
    // classify() when testing in Chrome.
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static Future<ClassificationResult> classify({
    required Uint8List bytes,
    File? file,
  }) async {
    if (file != null) {
      try {
        return await TfliteService().classify(file);
      } catch (_) {
        // Model/labels not bundled, or web stub — fall through to backend.
      }
    }
    return _classifyViaBackend(bytes);
  }

  static Future<ClassificationResult> _classifyViaBackend(Uint8List bytes) async {
    final uri = Uri.parse('$baseUrl/api/classify');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'scan.jpg'));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw StateError('Backend classify failed (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final probabilities = (body['probabilities'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    final tierName = body['tier'] as String;
    final tier = switch (tierName) {
      'Confirmed' => ConfidenceTier.confirmed,
      'Uncertain' => ConfidenceTier.uncertain,
      _ => ConfidenceTier.lowConfidence,
    };

    return ClassificationResult(
      label: body['prediction'] as String,
      confidence: (body['confidence'] as num).toDouble(),
      tier: tier,
      probabilities: probabilities,
    );
  }

  /// Placeholder per-tree canopy detector (report Table 4.2 —
  /// backend_python's /api/drone/analyse does not run a real detector, it
  /// returns plausible synthetic per-tree results so the drone workflow can
  /// be exercised end to end). [lat]/[lng] anchor the detected trees near
  /// the plantation's location.
  static Future<List<DroneDetectedTree>> droneAnalyse({
    required Uint8List bytes,
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('$baseUrl/api/drone/analyse').replace(
      queryParameters: {'lat': '$lat', 'lng': '$lng'},
    );
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'drone.jpg'));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw StateError('Drone analyse failed (${response.statusCode}): ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['trees'] as List)
        .map((e) => DroneDetectedTree.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the Grad-CAM / LIME explanation image (base64 PNG) for a photo.
  /// Explanation generation only runs server-side (report Section 4.1) —
  /// there is no on-device fallback, so this screen should show an
  /// "unavailable offline" state on failure.
  static Future<String> explanationImageBase64({
    required Uint8List bytes,
    required bool lime,
  }) async {
    final uri = Uri.parse('$baseUrl/api/${lime ? 'lime' : 'gradcam'}');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'scan.jpg'));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw StateError('Explanation request failed (${response.statusCode}): ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['image_base64'] as String;
  }
}

class DroneDetectedTree {
  final double lat;
  final double lng;
  final String prediction;
  final double confidence;

  const DroneDetectedTree({
    required this.lat,
    required this.lng,
    required this.prediction,
    required this.confidence,
  });

  factory DroneDetectedTree.fromJson(Map<String, dynamic> json) => DroneDetectedTree(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        prediction: json['prediction'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );
}
