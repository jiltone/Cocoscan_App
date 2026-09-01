import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/plantation.dart';

/// State for the Plantation Mapper (report Section 4.2.4), backed by a
/// top-level Firestore `plantations` collection so a plantation created by
/// an Agricultural Officer is visible to the farmers they assign to it —
/// SharedPreferences (this provider's original implementation) can't be
/// shared across devices/accounts, which is the whole point of officer ->
/// farmer assignment.
///
/// Visibility (see [load]): an officer sees every plantation where
/// officerId == their uid; a farmer sees every plantation where
/// memberUids array-contains their uid.
class PlantationProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('plantations');

  List<Plantation> _plantations = [];
  bool _loaded = false;
  bool _loading = false;

  List<Plantation> get plantations => List.unmodifiable(_plantations);
  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  Future<void> load({required String uid, required String role}) async {
    _loading = true;
    notifyListeners();
    try {
      final query = role == 'Agricultural Officer'
          ? _collection.where('officerId', isEqualTo: uid)
          : _collection.where('memberUids', arrayContains: uid);
      final snapshot = await query.get();
      _plantations = snapshot.docs
          .map((doc) => Plantation.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Plantation> createPlantation({
    required String officerId,
    required String officerName,
    required String name,
    required List<BoundaryPoint> boundary,
  }) async {
    final plantation = Plantation(
      id: '',
      name: name,
      boundaryPoints: boundary,
      createdAt: DateTime.now(),
      officerId: officerId,
      officerName: officerName,
    );
    final docRef = await _collection.add({
      ...plantation.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final saved = plantation._withId(docRef.id);
    _plantations = [saved, ..._plantations];
    notifyListeners();
    return saved;
  }

  Plantation? byId(String id) {
    try {
      return _plantations.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _updatePlantation(String plantationId, Plantation Function(Plantation) transform) async {
    final index = _plantations.indexWhere((p) => p.id == plantationId);
    if (index == -1) return;
    final updated = transform(_plantations[index]);
    _plantations[index] = updated;
    notifyListeners();
    await _collection.doc(plantationId).update(updated.toFirestore());
  }

  Future<void> addFarmer(String plantationId, PlantationMember member) {
    return _updatePlantation(plantationId, (p) {
      if (p.members.any((m) => m.uid == member.uid)) return p;
      return p.copyWith(members: [...p.members, member]);
    });
  }

  Future<void> removeFarmer(String plantationId, String uid) {
    return _updatePlantation(plantationId,
        (p) => p.copyWith(members: p.members.where((m) => m.uid != uid).toList()));
  }

  Future<void> addTree(String plantationId, double lat, double lng) {
    final tree = PlantationTree(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      lat: lat,
      lng: lng,
      label: TreeLabel.manual,
      taggingMethod: 'Manual',
    );
    return _updatePlantation(plantationId, (p) => p.copyWith(trees: [...p.trees, tree]));
  }

  /// Bulk-adds trees detected by the drone placeholder detector
  /// (InferenceService.droneAnalyse) — each becomes a 'Scanned' tree
  /// pre-labelled with its detected disease/health status.
  Future<void> addDetectedTrees(String plantationId, List<PlantationTree> trees) {
    return _updatePlantation(plantationId, (p) => p.copyWith(trees: [...p.trees, ...trees]));
  }

  /// [diseaseName] always overwrites (including to null, to clear a stale
  /// disease name when a rescanned tree comes back healthy) — copyWith's
  /// `??` merge can't express "clear this field", so the replacement tree
  /// is built directly here instead.
  ///
  /// [taggingMethod] should be passed as 'Scanned' when this is the result
  /// of an actual camera/drone scan (see camera_screen.dart and
  /// _scanTreeWithDrone) so a tree that was originally placed manually and
  /// later scanned moves out of the Summary tab's "Not scanned" bucket.
  /// Leave it null for a manual status override (Edit status dialog).
  Future<void> setTreeLabel(
    String plantationId,
    String treeId,
    TreeLabel label, {
    String? diseaseName,
    String? taggingMethod,
  }) {
    return _updatePlantation(plantationId, (p) {
      final trees = p.trees.map((t) {
        if (t.id != treeId) return t;
        return PlantationTree(
          id: t.id,
          lat: t.lat,
          lng: t.lng,
          label: label,
          taggingMethod: taggingMethod ?? t.taggingMethod,
          diseaseName: diseaseName,
          name: t.name,
        );
      }).toList();
      return p.copyWith(trees: trees);
    });
  }

  /// Manual status override (Edit status dialog) — changes only [label],
  /// leaving diseaseName/taggingMethod exactly as they were. Distinct from
  /// [setTreeLabel] because that method always overwrites diseaseName
  /// (correct for a real scan result, wrong for "I just think this tree
  /// looks uncertain" with no new diagnosis attached).
  Future<void> setTreeStatus(String plantationId, String treeId, TreeLabel label) {
    return _updatePlantation(plantationId, (p) {
      final trees = p.trees.map((t) => t.id == treeId ? t.copyWith(label: label) : t).toList();
      return p.copyWith(trees: trees);
    });
  }

  Future<void> removeTree(String plantationId, String treeId) {
    return _updatePlantation(
        plantationId, (p) => p.copyWith(trees: p.trees.where((t) => t.id != treeId).toList()));
  }

  Future<void> renameTree(String plantationId, String treeId, String name) {
    return _updatePlantation(plantationId, (p) {
      final trees = p.trees.map((t) => t.id == treeId ? t.copyWith(name: name) : t).toList();
      return p.copyWith(trees: trees);
    });
  }
}

extension _WithId on Plantation {
  Plantation _withId(String newId) => Plantation(
        id: newId,
        name: name,
        boundaryPoints: boundaryPoints,
        createdAt: createdAt,
        officerId: officerId,
        officerName: officerName,
        trees: trees,
        members: members,
      );
}
