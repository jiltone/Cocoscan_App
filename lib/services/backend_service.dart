import 'dart:io';
import 'dart:typed_data';

import 'firebase_service.dart';

class BackendService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    return await FirebaseService.login(email: email, password: password);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? plantation,
    String? phone,
  }) async {
    return await FirebaseService.register(
      name: name,
      email: email,
      password: password,
      role: role,
      plantation: plantation,
      phone: phone,
    );
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return await FirebaseService.getProfile();
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? plantation,
  }) async {
    await FirebaseService.updateProfile(
      name: name,
      email: email,
      phone: phone,
      plantation: plantation,
    );
  }

  static Future<String> uploadProfileAvatar({
    required Uint8List avatarBytes,
  }) async {
    return await FirebaseService.uploadProfileAvatar(avatarBytes: avatarBytes);
  }

  static Future<List<dynamic>> getScans() async {
    return await FirebaseService.getScans();
  }

  static Future<Map<String, dynamic>> predict({
    required File image,
  }) async {
    return await FirebaseService.predict(image: image);
  }

  static Future<void> logout() async {
    await FirebaseService.logout();
  }
}
