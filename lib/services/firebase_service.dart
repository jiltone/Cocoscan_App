import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _tokenKey = 'firebase_user_id';

  static Future<String?> getCurrentUserId() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) return currentUser.uid;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, userId);
  }

  static Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Login failed: user is null.');

      await saveCurrentUserId(user.uid);

      // Get user profile from Firestore
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      Map<String, dynamic> userData;

      if (!userDoc.exists) {
        // Auto-create a minimal profile so the app doesn't crash
        userData = {
          'name': user.displayName ?? email.split('@').first,
          'email': email,
          'role': 'Farmer',
          'plantation': '',
          'phone': '',
          'avatar': '',
          'createdAt': FieldValue.serverTimestamp(),
          'stats': {
            'totalScans': 0,
            'diseasesFound': 0,
            'healthyTrees': 0,
            'reportScore': 0.0,
          },
        };
        await userRef.set(userData);
      } else {
        userData = userDoc.data()!;
      }

      return {
        'user': {
          'id': user.uid,
          'name': userData['name'] ?? '',
          'email': user.email ?? '',
          'role': userData['role'] ?? 'Farmer',
          'plantation': userData['plantation'] ?? '',
          'phone': userData['phone'] ?? '',
          'avatar': userData['avatar'] ?? '',
          'stats': userData['stats'] ?? {
            'totalScans': 0,
            'diseasesFound': 0,
            'healthyTrees': 0,
            'reportScore': 0.0,
          },
        }
      };
    } on FirebaseAuthException catch (e) {
      // Give friendly messages for common auth errors
      final msg = switch (e.code) {
        'user-not-found'   => 'No account found for this email.',
        'wrong-password'   => 'Incorrect password. Please try again.',
        'invalid-email'    => 'The email address is not valid.',
        'user-disabled'    => 'This account has been disabled.',
        'too-many-requests'=> 'Too many attempts. Please try again later.',
        _                  => e.message ?? e.code,
      };
      throw Exception('Login failed: $msg');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? plantation,
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Registration failed.');

      // Create user profile in Firestore
      final userData = {
        'name': name,
        'email': email,
        'role': role,
        'plantation': plantation ?? '',
        'phone': phone ?? '',
        'avatar': '',
        'createdAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalScans': 0,
          'diseasesFound': 0,
          'healthyTrees': 0,
          'reportScore': 0.0,
        },
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
      await saveCurrentUserId(user.uid);

      return {
        'user': {
          'id': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'plantation': plantation ?? '',
          'phone': phone ?? '',
          'stats': userData['stats'],
        }
      };
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User profile not found.');

      final userData = userDoc.data()!;
      return {
        'id': userId,
        'name': userData['name'] ?? '',
        'email': userData['email'] ?? '',
        'role': userData['role'] ?? 'Farmer',
        'plantation': userData['plantation'] ?? '',
        'phone': userData['phone'] ?? '',
        'avatar': userData['avatar'] ?? '',
        'stats': userData['stats'] ?? {
          'totalScans': 0,
          'diseasesFound': 0,
          'healthyTrees': 0,
          'reportScore': 0.0,
        },
      };
    } catch (e) {
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? plantation,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (plantation != null) updates['plantation'] = plantation;

      if (updates.isEmpty) return;
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  static Future<String> uploadProfileAvatar({
    required Uint8List avatarBytes,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      final imageRef = _storage
          .ref()
          .child('avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putData(
        avatarBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final imageUrl = await imageRef.getDownloadURL();

      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set({'avatar': imageUrl}, SetOptions(merge: true));
      await _auth.currentUser?.updatePhotoURL(imageUrl);
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  static Future<List<dynamic>> getScans() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      final scansQuery = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return scansQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'disease': data['disease'] ?? '',
          'tree': data['tree'] ?? '',
          'confidence': data['confidence'] ?? 0.0,
          'status': data['status'] ?? '',
          'date': _formatDate(data['createdAt']),
          'sector': data['sector'] ?? '',
          'location': data['location'] ?? '',
          'model': data['model'] ?? '',
          'processingTime': data['processingTime'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load scans: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> predict({
    required File image,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      // Upload image to Firebase Storage
      final imageRef = _storage.ref().child('scans/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putFile(image);
      final imageUrl = await imageRef.getDownloadURL();

      // Simulate AI prediction (in real app, this would call an AI service)
      final prediction = _simulatePrediction();

      // Save scan to Firestore
      final scanData = {
        'userId': userId,
        'disease': prediction['disease'],
        'tree': prediction['treeId'],
        'confidence': prediction['confidence'],
        'status': prediction['status'],
        'sector': 'Sector A',
        'location': prediction['location'],
        'model': prediction['model'],
        'processingTime': prediction['processingTime'],
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final scanRef = await _firestore.collection('scans').add(scanData);

      // Update user stats
      await _updateUserStats(userId, prediction['status'] == 'HEALTHY');

      return {
        'prediction': prediction,
        'scan': {
          'id': scanRef.id,
          ...scanData,
          'date': _formatDate(Timestamp.now()),
        },
      };
    } catch (e) {
      throw Exception('Prediction failed: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    await clearCurrentUserId();
  }

  static Future<void> _updateUserStats(String userId, bool isHealthy) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final currentStats = userDoc.data()?['stats'] ?? {
      'totalScans': 0,
      'diseasesFound': 0,
      'healthyTrees': 0,
      'reportScore': 0.0,
    };

    final newStats = {
      'totalScans': (currentStats['totalScans'] ?? 0) + 1,
      'diseasesFound': isHealthy
          ? (currentStats['diseasesFound'] ?? 0)
          : (currentStats['diseasesFound'] ?? 0) + 1,
      'healthyTrees': isHealthy
          ? (currentStats['healthyTrees'] ?? 0) + 1
          : (currentStats['healthyTrees'] ?? 0),
      'reportScore': _calculateReportScore(currentStats, isHealthy),
    };

    await userRef.update({'stats': newStats});
  }

  static double _calculateReportScore(Map<String, dynamic> currentStats, bool isHealthy) {
    final totalScans = (currentStats['totalScans'] ?? 0) + 1;
    final healthyTrees = isHealthy
        ? (currentStats['healthyTrees'] ?? 0) + 1
        : (currentStats['healthyTrees'] ?? 0);

    // Simple scoring algorithm
    final healthRatio = healthyTrees / totalScans;
    return double.parse((3 + totalScans * 0.1 + healthRatio * 2).toStringAsFixed(1));
  }

  static Map<String, dynamic> _simulatePrediction() {
    final diseases = [
      {'name': 'Leaf Spot', 'status': 'CONFIRMED'},
      {'name': 'Lethal Yellowing', 'status': 'UNCERTAIN'},
      {'name': 'Bud Rot', 'status': 'CONFIRMED'},
      {'name': 'Stem Bleeding', 'status': 'UNCERTAIN'},
      {'name': 'Healthy', 'status': 'HEALTHY'}
    ];

    final random = DateTime.now().millisecondsSinceEpoch % diseases.length;
    final disease = diseases[random];
    final confidence = 0.60 + (DateTime.now().second % 41) / 100;

    return {
      'disease': disease['name'],
      'confidence': double.parse(confidence.toStringAsFixed(2)),
      'status': disease['status'],
      'statusColor': disease['status'] == 'CONFIRMED' ? '#D32F2F' :
                    disease['status'] == 'UNCERTAIN' ? '#FBC02D' : '#388E3C',
      'treeId': 'Tree #${String.fromCharCode(65 + (DateTime.now().second % 26))}-${1 + (DateTime.now().minute % 99)}',
      'location': 'Sector A — Row 4, Plot 14',
      'model': 'CocoScan AI v2.1 (MobileNet)',
      'processingTime': '${(1.2 + (DateTime.now().millisecond % 60) / 100).toStringAsFixed(1)} seconds',
      'probabilities': diseases.map((item) => ({
        'label': item['name'],
        'value': item['name'] == disease['name'] ? confidence : (0.01 + (DateTime.now().microsecond % 30) / 100)
      })).toList(),
    };
  }

  static String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
    return DateTime.now().toString().split(' ')[0];
  }

  // ── Plantations & Trees ────────────────────────────────────────────────

  static Future<String> addPlantation(String name, double lat, double lng) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated.');
    
    final docRef = await _firestore.collection('users').doc(userId).collection('plantations').add({
      'name': name,
      'latitude': lat,
      'longitude': lng,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<List<Map<String, dynamic>>> getPlantations() async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated.');

    final query = await _firestore.collection('users').doc(userId).collection('plantations').orderBy('createdAt').get();
    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<String> addTree({
    required String plantationId,
    required String treeId,
    required String disease,
    required String status,
    required int confidence,
    required double lat,
    required double lng,
  }) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated.');

    final docRef = await _firestore.collection('users').doc(userId)
        .collection('plantations').doc(plantationId)
        .collection('trees').add({
      'treeId': treeId,
      'disease': disease,
      'status': status,
      'confidence': confidence,
      'latitude': lat,
      'longitude': lng,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<List<Map<String, dynamic>>> getTrees(String plantationId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated.');

    final query = await _firestore.collection('users').doc(userId)
        .collection('plantations').doc(plantationId)
        .collection('trees').get();
    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Future<void> removeTree(String plantationId, String treeDocId) async {
    final userId = await getCurrentUserId();
    if (userId == null) throw Exception('Not authenticated.');

    await _firestore.collection('users').doc(userId)
        .collection('plantations').doc(plantationId)
        .collection('trees').doc(treeDocId).delete();
  }
}
