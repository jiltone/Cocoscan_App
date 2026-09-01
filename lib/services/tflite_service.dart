// tflite_flutter (and the ffi package it depends on) uses dart:ffi, which
// is not available when compiling for Flutter Web — so pick the real
// implementation on IO platforms (Android/iOS/Windows/macOS/Linux) and a
// no-op stub on web, mirroring the existing file_helper.dart pattern.
export 'tflite_service_stub.dart' if (dart.library.io) 'tflite_service_io.dart';
