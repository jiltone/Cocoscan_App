import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';

class LocationSelectionScreen extends StatefulWidget {
  final LatLng initialPosition;
  const LocationSelectionScreen({super.key, required this.initialPosition});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Plantation Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 18.0),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onCameraMove: (pos) => _selectedLocation = pos.target,
          ),
          // A pin in the center of the screen
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35.0),
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedLocation),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
