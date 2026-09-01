import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/disease_info.dart';
import 'inference_service.dart';
import 'tflite_service.dart' show ClassificationResult, ConfidenceTier;

/// Images are stored as small compressed base64 thumbnails directly on the
/// Firestore document, not in Firebase Cloud Storage — Storage requires the
/// (paid) Blaze billing plan to actually provision a bucket, while
/// Firestore's free tier already covers this app's needs. Keep thumbnails
/// well under Firestore's 1 MiB document limit.
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Decodes [bytes], downsizes so neither dimension exceeds [maxDimension],
  /// re-encodes as JPEG at [quality] and returns it base64-encoded. Pure
  /// in-memory byte processing (package:image), so it works on every
  /// platform including web. Returns null if the bytes aren't a decodable
  /// image — callers should treat that as "no thumbnail", not a hard error.
  static String? _compressToBase64Jpeg(
    Uint8List bytes, {
    required int maxDimension,
    required int quality,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final resized = (decoded.width > maxDimension || decoded.height > maxDimension)
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimension : null,
            height: decoded.height > decoded.width ? maxDimension : null,
          )
        : decoded;
    final jpeg = img.encodeJpg(resized, quality: quality);
    return base64Encode(jpeg);
  }

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

  /// Every registered Farmer account — used by an Agricultural Officer to
  /// pick who to assign to a plantation (see ManageFarmersScreen).
  static Future<List<Map<String, dynamic>>> getFarmers() async {
    final query = await _firestore.collection('users').where('role', isEqualTo: 'Farmer').get();
    return query.docs
        .map((doc) => {
              'uid': doc.id,
              'name': doc.data()['name'] ?? '',
              'email': doc.data()['email'] ?? '',
            })
        .toList();
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

      final avatarBase64 = _compressToBase64Jpeg(avatarBytes, maxDimension: 200, quality: 70);
      if (avatarBase64 == null) {
        throw Exception('Could not decode the selected image.');
      }

      final userRef = _firestore.collection('users').doc(userId);
      await userRef.set({'avatar': avatarBase64}, SetOptions(merge: true));
      // Note: no updatePhotoURL() call — Firebase Auth's photoURL field
      // expects an actual URL, not a base64 blob, and has its own length
      // limit. The avatar lives on the Firestore user doc only.
      return avatarBase64;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  static String _normalizeStatus(dynamic raw) {
    final s = (raw ?? '').toString().toUpperCase();
    if (s == 'CONFIRMED' || s == 'UNCERTAIN' || s == 'HEALTHY') return s;
    return s.isEmpty ? 'UNCERTAIN' : s;
  }

  /// Older scan documents (saved before diseaseKey was added) only have the
  /// display name (e.g. "Gray Leaf Spot") — reverse-look-up the internal
  /// key so History can still fully reconstruct those results when tapped.
  static String _guessDiseaseKey(String displayName) {
    for (final entry in diseaseInfoByKey.entries) {
      if (entry.value.label == displayName) return entry.key;
    }
    return 'Gray_Leaf_Spot';
  }

  /// Reads every scan for the current user and sorts client-side rather
  /// than via a Firestore orderBy — orderBy silently drops any document
  /// missing that exact field, which hid every older scan written before
  /// this schema (they use 'timestamp'/'diseaseName'/'tier' instead of
  /// 'createdAt'/'disease'/'status'). Reading both schemas here means old
  /// history is visible again instead of just working around the missing
  /// composite index.
  static Future<List<dynamic>> getScans() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      final scansQuery = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .get();

      final scans = scansQuery.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'] ?? data['timestamp'];
        final diseaseName = (data['disease'] ?? data['diseaseName'] ?? '') as String;
        final probabilitiesRaw = data['probabilities'];
        return {
          'id': doc.id,
          'diseaseKey': data['diseaseKey'] as String? ?? _guessDiseaseKey(diseaseName),
          'disease': diseaseName,
          'tree': data['tree'] ?? '',
          'confidence': (data['confidence'] as num?)?.toDouble() ?? 0.0,
          'status': _normalizeStatus(data['status'] ?? data['tier']),
          'date': _formatDate(timestamp),
          // Raw epoch ms (not just the display string above) so Home/
          // Analytics can bucket by real day/week/month instead of
          // re-parsing a formatted date string.
          'timestampMs': timestamp is Timestamp ? timestamp.millisecondsSinceEpoch : null,
          'sector': data['sector'] ?? '',
          'location': data['location'] ?? '',
          'model': data['model'] ?? '',
          'processingTime': data['processingTime'] ?? '',
          'imageBase64': data['imageBase64'],
          'probabilities': probabilitiesRaw is Map
              ? probabilitiesRaw.map((k, v) => MapEntry(k as String, (v as num).toDouble()))
              : null,
          'plantationId': data['plantationId'],
          'plantationName': data['plantationName'],
          'plantationTreeId': data['plantationTreeId'],
          '_sortTs': timestamp,
        };
      }).toList();

      scans.sort((a, b) {
        final ta = a['_sortTs'];
        final tb = b['_sortTs'];
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return (tb as Timestamp).compareTo(ta as Timestamp);
      });
      for (final s in scans) {
        (s as Map).remove('_sortTs');
      }
      return scans;
    } catch (e) {
      throw Exception('Failed to load scans: ${e.toString()}');
    }
  }

  /// Runs the classifier only — no Firestore write. [imageFile] is optional
  /// and only enables the on-device TFLite path (pass null on web; dart:io
  /// File operations aren't actually supported there despite compiling).
  static Future<ClassificationResult> classifyOnly({
    required Uint8List imageBytes,
    File? imageFile,
  }) {
    return InferenceService.classify(bytes: imageBytes, file: imageFile);
  }

  /// Explicit "Save to History" action — persists a classification already
  /// produced by [classifyOnly] to the `scans` collection, with a
  /// compressed thumbnail stored directly on the document (see class doc
  /// comment: no Firebase Storage bucket).
  ///
  /// [plantationId]/[plantationName]/[treeId] are set only when this scan
  /// came from a plantation tree's "Scan for disease" action — they let
  /// History distinguish plantation scans from personal ones and let
  /// PredictionResultScreen offer a "View Plantation" shortcut.
  static Future<Map<String, dynamic>> saveScanToHistory({
    required ClassificationResult classification,
    required Uint8List imageBytes,
    String? plantationId,
    String? plantationName,
    String? treeId,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated.');

      // A missing/undecodable image is non-fatal: the scan still saves,
      // just without a thumbnail.
      final imageBase64 = _compressToBase64Jpeg(imageBytes, maxDimension: 320, quality: 55);
      final prediction = _predictionFromClassification(classification);

      final scanData = {
        'userId': userId,
        'diseaseKey': prediction['diseaseKey'],
        'disease': prediction['disease'],
        'tree': prediction['treeId'],
        'confidence': prediction['confidence'],
        'status': prediction['status'],
        'sector': 'Sector A',
        'location': prediction['location'],
        'model': prediction['model'],
        'processingTime': prediction['processingTime'],
        'imageBase64': imageBase64,
        // Full breakdown so re-opening a saved scan from History shows the
        // real per-class probabilities, not just a single-entry fallback.
        'probabilities': classification.probabilities,
        'plantationId': plantationId,
        'plantationName': plantationName,
        'plantationTreeId': treeId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final scanRef = await _firestore.collection('scans').add(scanData);
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
      throw Exception('Failed to save scan: ${e.toString()}');
    }
  }

  /// Convenience wrapper combining [classifyOnly] + [saveScanToHistory] for
  /// call sites that want the old auto-save-on-classify behaviour.
  static Future<Map<String, dynamic>> predict({
    required Uint8List imageBytes,
    File? imageFile,
  }) async {
    final classification = await classifyOnly(imageBytes: imageBytes, imageFile: imageFile);
    return saveScanToHistory(classification: classification, imageBytes: imageBytes);
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

  /// Builds the scan/prediction map from a real ClassificationResult
  /// (7 classes: 6 diseases + Healthy_Leaves). Healthy_Leaves always gets
  /// its own 'HEALTHY' status — it is never scored as a disease tier, even
  /// though it shares the same softmax output as the other 6 classes.
  static Map<String, dynamic> _predictionFromClassification(ClassificationResult result) {
    final info = diseaseInfoByKey[result.label] ?? diseaseInfoByKey['Healthy_Leaves']!;
    final isHealthy = result.label == 'Healthy_Leaves';
    final status = isHealthy
        ? 'HEALTHY'
        : (result.tier == ConfidenceTier.confirmed ? 'CONFIRMED' : 'UNCERTAIN');

    return {
      'diseaseKey': result.label,
      'disease': info.label,
      'confidence': result.confidence,
      'status': status,
      'statusColor': isHealthy ? '#2E7D32' : (status == 'CONFIRMED' ? '#D32F2F' : '#FBC02D'),
      'treeId': 'Tree #${String.fromCharCode(65 + (DateTime.now().second % 26))}-${1 + (DateTime.now().minute % 99)}',
      'location': 'Unmapped scan',
      'model': 'CocoScan ResNet50 (7-class)',
      'processingTime': '—',
      'probabilities': result.probabilities.entries
          .map((e) => {'label': e.key, 'value': e.value})
          .toList(),
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
