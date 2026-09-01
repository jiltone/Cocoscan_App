/// Tree tagging method (report Section 4.2.4): a tree is either placed by
/// tapping the map in Add Mode ("Manual") or produced by a disease scan.
enum TreeLabel { healthy, diseased, uncertain, manual }

class PlantationTree {
  final String id;
  final double lat;
  final double lng;
  final TreeLabel label;
  final String taggingMethod; // 'Manual' or 'Scanned'
  final String? diseaseName;

  /// Optional custom name/label for this tree (e.g. "North corner", "Near
  /// well") — shown instead of the auto-numbered "Tree N" once set.
  final String? name;

  const PlantationTree({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    required this.taggingMethod,
    this.diseaseName,
    this.name,
  });

  PlantationTree copyWith({
    TreeLabel? label,
    String? diseaseName,
    String? name,
    String? taggingMethod,
  }) =>
      PlantationTree(
        id: id,
        lat: lat,
        lng: lng,
        label: label ?? this.label,
        taggingMethod: taggingMethod ?? this.taggingMethod,
        diseaseName: diseaseName ?? this.diseaseName,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'label': label.name,
        'taggingMethod': taggingMethod,
        'diseaseName': diseaseName,
        'name': name,
      };

  factory PlantationTree.fromJson(Map<String, dynamic> json) => PlantationTree(
        id: json['id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        label: TreeLabel.values.firstWhere((e) => e.name == json['label'],
            orElse: () => TreeLabel.manual),
        taggingMethod: json['taggingMethod'] as String? ?? 'Manual',
        diseaseName: json['diseaseName'] as String?,
        name: json['name'] as String?,
      );
}

class BoundaryPoint {
  final double lat;
  final double lng;
  const BoundaryPoint(this.lat, this.lng);

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
  factory BoundaryPoint.fromJson(Map<String, dynamic> json) =>
      BoundaryPoint((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
}

/// A farmer assigned to a plantation by its Agricultural Officer. A
/// lightweight name/email snapshot is stored alongside the uid so the
/// member list can render without an extra `users` lookup per farmer.
class PlantationMember {
  final String uid;
  final String name;
  final String email;
  const PlantationMember({required this.uid, required this.name, required this.email});

  Map<String, dynamic> toJson() => {'uid': uid, 'name': name, 'email': email};
  factory PlantationMember.fromJson(Map<String, dynamic> json) => PlantationMember(
        uid: json['uid'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );
}

class Plantation {
  final String id;
  final String name;
  final List<BoundaryPoint> boundaryPoints;
  final DateTime createdAt;
  final List<PlantationTree> trees;

  /// Only an Agricultural Officer can create a plantation (see
  /// PlantationProvider) — [officerId]/[officerName] identify who did.
  final String officerId;
  final String officerName;

  /// Farmers assigned to this plantation by the officer. A plantation is
  /// visible to its officer and to every farmer listed here (see
  /// PlantationProvider.load's officerId==uid / memberUids array-contains
  /// query).
  final List<PlantationMember> members;

  const Plantation({
    required this.id,
    required this.name,
    required this.boundaryPoints,
    required this.createdAt,
    required this.officerId,
    required this.officerName,
    this.trees = const [],
    this.members = const [],
  });

  Plantation copyWith({List<PlantationTree>? trees, List<PlantationMember>? members}) => Plantation(
        id: id,
        name: name,
        boundaryPoints: boundaryPoints,
        createdAt: createdAt,
        officerId: officerId,
        officerName: officerName,
        trees: trees ?? this.trees,
        members: members ?? this.members,
      );

  /// Firestore document fields — excludes [id] (that's the doc id) and
  /// [createdAt] (set via FieldValue.serverTimestamp() on create, so it's
  /// added separately by the caller rather than serialised here).
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'boundaryPoints': boundaryPoints.map((e) => e.toJson()).toList(),
        'officerId': officerId,
        'officerName': officerName,
        'memberUids': members.map((m) => m.uid).toList(),
        'members': members.map((m) => m.toJson()).toList(),
        'trees': trees.map((e) => e.toJson()).toList(),
      };

  factory Plantation.fromFirestore(String id, Map<String, dynamic> json) => Plantation(
        id: id,
        name: json['name'] as String? ?? '',
        boundaryPoints: (json['boundaryPoints'] as List? ?? [])
            .map((e) => BoundaryPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        officerId: json['officerId'] as String? ?? '',
        officerName: json['officerName'] as String? ?? '',
        trees: (json['trees'] as List? ?? [])
            .map((e) => PlantationTree.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        members: (json['members'] as List? ?? [])
            .map((e) => PlantationMember.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
