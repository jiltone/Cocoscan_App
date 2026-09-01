import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/plantation.dart';
import '../theme/app_theme.dart';

/// Lets an Agricultural Officer mark a plantation's boundary by tapping
/// points on the map, plus a "Use current location" button that drops a
/// point at their live GPS position. Tap any placed marker to remove just
/// that point. Returns the finished List<BoundaryPoint> via Navigator.pop
/// when at least 3 points have been placed (a boundary needs 3+ points to
/// enclose an area).
class PlantationBoundaryScreen extends StatefulWidget {
  const PlantationBoundaryScreen({super.key});

  @override
  State<PlantationBoundaryScreen> createState() => _PlantationBoundaryScreenState();
}

class _PlantationBoundaryScreenState extends State<PlantationBoundaryScreen> {
  final List<LatLng> _points = [];
  GoogleMapController? _mapController;
  bool _locating = false;
  String? _locationError;

  static const _fallbackCenter = LatLng(6.0535, 80.2210); // Weligama, Sri Lanka

  @override
  void initState() {
    super.initState();
    // Default the map to the officer's live location on open, rather than
    // the hardcoded fallback — this only re-centers the camera, it does not
    // drop a boundary point (that's what the "Use Current Location" button
    // is for).
    _centerOnCurrentLocation();
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 17),
      );
    } catch (_) {
      // Silently keep the fallback center — this is just a convenience
      // default, not a required step.
    }
  }

  void _addPoint(LatLng point) {
    setState(() => _points.add(point));
  }

  void _removePointAt(int index) {
    setState(() => _points.removeAt(index));
  }

  void _undoLast() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off.');
      }
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      _addPoint(point);
      await _mapController?.animateCamera(CameraUpdate.newLatLng(point));
    } catch (e) {
      setState(() => _locationError = 'Could not get current location: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _finish() {
    if (_points.length < 3) return;
    Navigator.pop(context, _points.map((p) => BoundaryPoint(p.latitude, p.longitude)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Plantation Boundary'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo last point',
            onPressed: _points.isEmpty ? null : _undoLast,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _points.length < 3
                      ? 'Tap the map to drop boundary points (need at least 3). Tap a point to remove it.'
                      : '${_points.length} points placed — tap a point to remove it, or "Save Boundary" when done.',
                  style: AppTextStyles.body,
                ),
                if (_locationError != null) ...[
                  const SizedBox(height: 6),
                  Text(_locationError!, style: const TextStyle(color: AppColors.confirmed, fontSize: 12)),
                ],
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: _fallbackCenter, zoom: 17),
              mapType: MapType.satellite,
              onMapCreated: (controller) => _mapController = controller,
              onTap: _addPoint,
              markers: {
                for (var i = 0; i < _points.length; i++)
                  Marker(
                    markerId: MarkerId('point_$i'),
                    position: _points[i],
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(title: 'Point ${i + 1} — tap to remove'),
                    onTap: () => _removePointAt(i),
                  ),
              },
              polygons: _points.length >= 3
                  ? {
                      Polygon(
                        polygonId: const PolygonId('boundary'),
                        points: _points,
                        strokeColor: AppColors.primary,
                        strokeWidth: 3,
                        fillColor: AppColors.primary.withOpacity(0.18),
                      ),
                    }
                  : {},
              polylines: _points.length == 2
                  ? {
                      Polyline(
                        polylineId: const PolylineId('boundary_line'),
                        points: _points,
                        color: AppColors.primary,
                        width: 3,
                      ),
                    }
                  : {},
            ),
          ),

          // Buttons live in their own bar below the map, not floating on
          // top of it — a FloatingActionButton stacked over GoogleMap on
          // Flutter Web can register the same tap on both the button AND
          // the underlying map platform view (a known google_maps_flutter_web
          // limitation), which was adding an unwanted boundary point every
          // time "Use Current Location" or "Save Boundary" was pressed.
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded),
                      label: const Text('Current Location'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _points.length >= 3 ? _finish : null,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Boundary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
