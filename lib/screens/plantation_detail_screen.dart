import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/plantation.dart';
import '../providers/plantation_provider.dart';
import '../services/firebase_service.dart';
import '../services/inference_service.dart';
import '../services/tflite_service.dart' show ConfidenceTier;
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import 'drone_stream_screen.dart';
import 'manage_farmers_screen.dart';
import 'prediction_result_screen.dart';

/// Plantation Detail: Map View / Tree List / Summary tabs
/// (report Section 4.2.4, Figures 4.6–4.8).
class PlantationDetailScreen extends StatefulWidget {
  final String plantationId;
  const PlantationDetailScreen({super.key, required this.plantationId});

  @override
  State<PlantationDetailScreen> createState() => _PlantationDetailScreenState();
}

class _PlantationDetailScreenState extends State<PlantationDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _addMode = false;
  bool _droneDetecting = false;
  String? _currentUid;
  final Map<String, BitmapDescriptor> _treeIcons = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    FirebaseService.getCurrentUserId().then((uid) {
      if (mounted) setState(() => _currentUid = uid);
    });
    _loadTreeIcons();
  }

  /// Renders a coconut-palm emoji onto a coloured circular badge for each
  /// tree status, replacing the generic Google Maps pin marker. Built at
  /// runtime (no image asset needed) via dart:ui canvas drawing. Cached per
  /// (status, taggingMethod) pair — a small corner badge (📷 Scanned vs
  /// 📍 Manual) shows how the tree was added, on top of the status colour.
  Future<void> _loadTreeIcons() async {
    final entries = <MapEntry<String, BitmapDescriptor>>[];
    for (final label in TreeLabel.values) {
      for (final method in ['Manual', 'Scanned']) {
        final icon = await _buildTreeIcon(_markerColor(label), scanned: method == 'Scanned');
        entries.add(MapEntry(_iconKey(label, method), icon));
      }
    }
    if (!mounted) return;
    setState(() => _treeIcons.addEntries(entries));
  }

  String _iconKey(TreeLabel label, String taggingMethod) => '${label.name}_$taggingMethod';

  Future<BitmapDescriptor> _buildTreeIcon(Color color, {required bool scanned}) async {
    // Smaller than the original 96px badge — that rendered noticeably
    // larger than a normal map pin and crowded the map when several trees
    // sat close together.
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final bgPaint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 3, bgPaint);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(text: '🌴', style: TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2 - 1),
    );

    // Tagging-method badge, bottom-right corner.
    const badgeRadius = 10.0;
    final badgeCenter = Offset(size - badgeRadius + 1, size - badgeRadius + 1);
    canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      badgeCenter, badgeRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final badgePainter = TextPainter(
      text: TextSpan(text: scanned ? '📷' : '📍', style: const TextStyle(fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    badgePainter.paint(
      canvas,
      Offset(badgeCenter.dx - badgePainter.width / 2, badgeCenter.dy - badgePainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Used where a ClassificationResult (with a real ConfidenceTier) is
  /// available — device/drone camera scans. A non-healthy prediction only
  /// counts as "Confirmed diseased" when the model's own confidence tier
  /// says so; anything less certain is TreeLabel.uncertain rather than
  /// being forced straight to diseased.
  TreeLabel _labelForClassification(String prediction, ConfidenceTier tier) {
    if (prediction == 'Healthy_Leaves') return TreeLabel.healthy;
    return tier == ConfidenceTier.confirmed ? TreeLabel.diseased : TreeLabel.uncertain;
  }

  /// Used for the bulk drone-detect placeholder endpoint, which only
  /// returns a raw confidence float rather than a computed tier — applies
  /// the same 85%/60% thresholds as the backend (report Section 3.7.1).
  TreeLabel _labelForConfidence(String prediction, double confidence) {
    if (prediction == 'Healthy_Leaves') return TreeLabel.healthy;
    return confidence >= 0.85 ? TreeLabel.diseased : TreeLabel.uncertain;
  }

  /// Drone Detect: pick a drone-captured aerial photo of the plantation and
  /// run it through the placeholder canopy detector (report Table 4.2),
  /// bulk-adding every tree it reports instead of tapping them in one by
  /// one. This is a separate flow from live drone video scanning (see
  /// drone_stream_screen.dart) — that captures one frame for one tree's
  /// disease scan, this analyses a whole-canopy photo for multiple trees
  /// at once.
  Future<void> _runDroneDetect(Plantation plantation) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Take Aerial Photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose Drone Photo from Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null || !mounted) return;

    setState(() => _droneDetecting = true);
    try {
      final bytes = await file.readAsBytes();
      final anchor = plantation.boundaryPoints.isNotEmpty
          ? plantation.boundaryPoints.first
          : (plantation.trees.isNotEmpty
              ? BoundaryPoint(plantation.trees.first.lat, plantation.trees.first.lng)
              : const BoundaryPoint(6.0535, 80.2210));
      final detected = await InferenceService.droneAnalyse(
        bytes: bytes, lat: anchor.lat, lng: anchor.lng,
      );
      final trees = detected.map((d) => PlantationTree(
            id: '${DateTime.now().millisecondsSinceEpoch}_${d.lat}_${d.lng}',
            lat: d.lat,
            lng: d.lng,
            label: _labelForConfidence(d.prediction, d.confidence),
            taggingMethod: 'Scanned',
            diseaseName: d.prediction == 'Healthy_Leaves' ? null : d.prediction,
          ));
      if (!mounted) return;
      await context.read<PlantationProvider>().addDetectedTrees(plantation.id, trees.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drone detected ${detected.length} trees.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drone detect failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _droneDetecting = false);
    }
  }

  Color _markerColor(TreeLabel label) {
    switch (label) {
      case TreeLabel.diseased:
        return Colors.red;
      case TreeLabel.uncertain:
        return Colors.orange;
      case TreeLabel.healthy:
      case TreeLabel.manual:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantation = context.watch<PlantationProvider>().byId(widget.plantationId);
    if (plantation == null) {
      return const Scaffold(body: Center(child: Text('Plantation not found')));
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(plantation.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_currentUid != null && _currentUid == plantation.officerId)
            IconButton(
              icon: const Icon(Icons.group_rounded),
              tooltip: 'Manage Farmers',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageFarmersScreen(plantationId: plantation.id)),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          // The app's default TabBarTheme uses dark green text (meant for a
          // light background) — left unset here, "Map View"/"Tree List"/
          // "Summary" were nearly invisible against this AppBar's dark
          // green background.
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          tabs: const [
            Tab(text: 'Map View'),
            Tab(text: 'Tree List'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _mapView(plantation),
          _treeList(plantation),
          _summary(plantation),
        ],
      ),
    );
  }

  LatLng _boundaryCentroid(List<BoundaryPoint> points) {
    final lat = points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
    final lng = points.map((p) => p.lng).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lng);
  }

  LatLngBounds _boundaryBounds(List<BoundaryPoint> points) {
    var minLat = points.first.lat, maxLat = points.first.lat;
    var minLng = points.first.lng, maxLng = points.first.lng;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  Widget _mapView(Plantation plantation) {
    // A freshly created plantation has a boundary but zero trees yet — the
    // map must centre on that boundary, not fall through to trees (empty)
    // and then a hardcoded default, which was showing an unrelated location
    // for every new plantation.
    final center = plantation.boundaryPoints.isNotEmpty
        ? _boundaryCentroid(plantation.boundaryPoints)
        : (plantation.trees.isNotEmpty
            ? LatLng(plantation.trees.first.lat, plantation.trees.first.lng)
            : const LatLng(6.0535, 80.2210)); // fallback: Weligama, Sri Lanka

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text('${plantation.trees.length} trees mapped', style: AppTextStyles.body),
              ),
              ChoiceChip(
                label: const Text('Manual'),
                selected: _addMode,
                selectedColor: AppColors.primary.withOpacity(0.15),
                onSelected: (v) => setState(() => _addMode = v),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: _droneDetecting
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.airplanemode_active_rounded, size: 16, color: AppColors.secondary),
                label: const Text('Drone Detect'),
                onPressed: _droneDetecting ? null : () => _runDroneDetect(plantation),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              _legendDot(AppColors.healthy, 'Healthy / Manual'),
              const SizedBox(width: 14),
              _legendDot(AppColors.confirmed, 'Diseased'),
              const SizedBox(width: 14),
              _legendDot(AppColors.uncertain, 'Uncertain'),
            ],
          ),
        ),
        if (_addMode)
          Container(
            width: double.infinity,
            color: AppColors.primary.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text('Manual Add Mode is on — tap the map to place a tree.',
                style: AppTextStyles.caption),
          ),
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 18),
            mapType: MapType.satellite,
            onMapCreated: (controller) {
              // Auto-focus on the plantation's marked boundary rather than
              // leaving the map at whatever zoom/framing
              // initialCameraPosition happened to guess — this is what was
              // missing/showing nothing useful right after creating a
              // plantation.
              if (plantation.boundaryPoints.length >= 3) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(_boundaryBounds(plantation.boundaryPoints), 60),
                  );
                });
              }
            },
            polygons: plantation.boundaryPoints.length >= 3
                ? {
                    Polygon(
                      polygonId: const PolygonId('plantation_boundary'),
                      points: plantation.boundaryPoints.map((p) => LatLng(p.lat, p.lng)).toList(),
                      strokeColor: AppColors.primary,
                      strokeWidth: 3,
                      fillColor: AppColors.primary.withOpacity(0.12),
                    ),
                  }
                : {},
            markers: plantation.trees.asMap().entries.map((entry) {
              final tree = entry.value;
              return Marker(
                markerId: MarkerId(tree.id),
                position: LatLng(tree.lat, tree.lng),
                icon: _treeIcons[_iconKey(tree.label, tree.taggingMethod)] ?? BitmapDescriptor.defaultMarker,
                anchor: const Offset(0.5, 0.5),
                infoWindow: InfoWindow(title: tree.name ?? 'Tree ${entry.key + 1}'),
                onTap: () => _showTreeActions(plantation, tree),
              );
            }).toSet(),
            onTap: _addMode
                ? (latLng) => context
                    .read<PlantationProvider>()
                    .addTree(plantation.id, latLng.latitude, latLng.longitude)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _treeList(Plantation plantation) {
    if (plantation.trees.isEmpty) {
      return const Center(child: Text('No trees pinned yet.', style: AppTextStyles.body));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plantation.trees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tree = plantation.trees[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: AppDecorations.card,
          child: Row(
            children: [
              Icon(Icons.park_rounded, color: _markerColor(tree.label)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tree.name ?? 'Tree ${index + 1}',
                        style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                    Text('${tree.lat.toStringAsFixed(5)}, ${tree.lng.toStringAsFixed(5)}',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tree.taggingMethod.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () => _showTreeActions(plantation, tree),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(Plantation plantation) {
    final total = plantation.trees.length;
    final confirmed = plantation.trees.where((t) => t.label == TreeLabel.diseased).length;
    final uncertainCount = plantation.trees.where((t) => t.label == TreeLabel.uncertain).length;
    final manual = plantation.trees.where((t) => t.taggingMethod == 'Manual').length;
    final scanned = total - manual;
    final rate = total == 0 ? 0.0 : confirmed / total;

    final breakdown = <String, int>{};
    for (final t in plantation.trees) {
      final key = t.diseaseName ?? (t.taggingMethod == 'Manual' ? 'Not scanned' : 'Healthy');
      breakdown[key] = (breakdown[key] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _statTile(Icons.park_rounded, '$total', 'Total Trees', AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _statTile(Icons.warning_rounded, '$confirmed', 'Confirmed', AppColors.confirmed)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statTile(Icons.help_outline_rounded, '$uncertainCount', 'Uncertain', AppColors.uncertain)),
          const SizedBox(width: 10),
          Expanded(child: _statTile(Icons.pin_drop_rounded, '$manual', 'Manual marks', AppColors.secondary)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Disease Rate', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text('${(rate * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.heading1.copyWith(color: AppColors.confirmed, fontSize: 24)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.confirmed),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Disease Breakdown', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        ...breakdown.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppDecorations.card,
                child: Row(children: [
                  Expanded(child: Text(e.key, style: AppTextStyles.body)),
                  Text('${e.value} (${total == 0 ? 0 : (e.value / total * 100).toStringAsFixed(0)}%)',
                      style: AppTextStyles.heading3.copyWith(fontSize: 13)),
                ]),
              ),
            )),
        if (scanned == 0) const SizedBox.shrink(),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ],
      );

  Widget _statTile(IconData icon, String value, String label, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.card,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
          Text(label, style: AppTextStyles.caption),
        ]),
      );

  void _showTreeActions(Plantation plantation, PlantationTree tree) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Scan with Device Camera'),
              subtitle: const Text('Open the phone camera and attach the result to this tree'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraScreen(
                      plantationId: plantation.id,
                      treeId: tree.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.airplanemode_active_rounded, color: AppColors.secondary),
              title: const Text('Scan with Drone Camera'),
              subtitle: const Text('Capture a frame from a live drone video feed'),
              onTap: () {
                Navigator.pop(sheetContext);
                _scanTreeWithDrone(plantation, tree);
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: AppColors.secondary),
              title: const Text('Rename tree'),
              subtitle: Text(tree.name ?? 'Give this tree a custom label'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _renameTree(plantation, tree);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.secondary),
              title: const Text('Edit status'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _editLabel(plantation, tree);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.confirmed),
              title: const Text('Remove tree'),
              onTap: () {
                context.read<PlantationProvider>().removeTree(plantation.id, tree.id);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameTree(Plantation plantation, PlantationTree tree) async {
    final controller = TextEditingController(text: tree.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename tree'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. North corner, Near well'),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      await context.read<PlantationProvider>().renameTree(plantation.id, tree.id, name);
    }
  }

  Future<void> _editLabel(Plantation plantation, PlantationTree tree) async {
    final label = await showDialog<TreeLabel>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Set tree label'),
        children: TreeLabel.values
            .map((l) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, l),
                  child: Text(l.name),
                ))
            .toList(),
      ),
    );
    if (label != null && mounted) {
      await context.read<PlantationProvider>().setTreeStatus(plantation.id, tree.id, label);
    }
  }

  /// Opens the live drone video feed, captures a frame, classifies it, and
  /// attaches the result to [tree] — the drone-camera counterpart to
  /// scanning with the device camera (see CameraScreen's plantationId/treeId
  /// params for that path).
  Future<void> _scanTreeWithDrone(Plantation plantation, PlantationTree tree) async {
    final frame = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (_) => const DroneStreamScreen()),
    );
    if (frame == null || frame is! List<int> || !mounted) return;
    final bytes = Uint8List.fromList(frame);

    try {
      final classification = await InferenceService.classify(bytes: bytes);
      if (!mounted) return;
      await context.read<PlantationProvider>().setTreeLabel(
            plantation.id,
            tree.id,
            _labelForClassification(classification.label, classification.tier),
            diseaseName: classification.label == 'Healthy_Leaves' ? null : classification.label,
            taggingMethod: 'Scanned',
          );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
            diseaseKey: classification.label,
            confidence: classification.confidence,
            status: classification.label == 'Healthy_Leaves'
                ? 'HEALTHY'
                : (classification.tier == ConfidenceTier.confirmed ? 'CONFIRMED' : 'UNCERTAIN'),
            probabilities: classification.probabilities,
            // These two were missing entirely before — without them the
            // Save to History button never appeared for a drone-camera tree
            // scan (it only showed for device-camera scans).
            classification: classification,
            imageBytes: bytes,
            plantationId: plantation.id,
            plantationName: plantation.name,
            treeId: tree.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drone scan failed: $e')),
      );
    }
  }
}
