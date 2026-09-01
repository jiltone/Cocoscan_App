import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/yolo_service.dart';
import '../services/firebase_service.dart';
import 'prediction_result_screen.dart';
import 'location_selection_screen.dart';
class DroneReportScreen extends StatefulWidget {
  const DroneReportScreen({super.key});
  @override
  State<DroneReportScreen> createState() => _DroneReportScreenState();
}

class _DroneReportScreenState extends State<DroneReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _processing = false;
  File? _selectedFile;
  final YoloService _yoloService = YoloService();
  GoogleMapController? _mapController;
  bool _locationPermissionGranted = false;
  bool _addMode = false;

  BitmapDescriptor? _healthyIcon;
  BitmapDescriptor? _diseasedIcon;
  BitmapDescriptor? _uncertainIcon;

  String? _selectedPlantationId;
  List<_PlantationData> _plantations = [];
  LatLng _currentMapCenter = const LatLng(7.4818, 80.3609);

  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(7.4818, 80.3609),
    zoom: 18.0,
  );
  
  final Set<Marker> _markers = {};

  List<_TreeData> _trees = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _requestLocationPermission();
    _loadCustomIcons();
    _loadFirebaseData();
  }

  Future<void> _loadFirebaseData() async {
    try {
      final plantations = await FirebaseService.getPlantations();
      if (!mounted) return;
      if (plantations.isNotEmpty) {
        _plantations = plantations.map((p) => _PlantationData(
          p['id'], p['name'], LatLng(p['latitude'], p['longitude'])
        )).toList();
        _selectedPlantationId = _plantations.first.id;
        _currentMapCenter = _plantations.first.location;
        _initialPosition = CameraPosition(target: _currentMapCenter, zoom: 18.0);
        await _loadTreesForPlantation(_selectedPlantationId!);
      } else {
        _plantations = [];
        _trees = [];
        _initializeMarkers();
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadTreesForPlantation(String plantationId) async {
    try {
      final trees = await FirebaseService.getTrees(plantationId);
      if (!mounted) return;
      _trees = trees.map((t) => _TreeData(
        t['id'], t['treeId'], t['disease'], t['status'], t['confidence'],
        t['status'] == 'HEALTHY' ? const Color(0xFF2E7D32) : t['status'] == 'CONFIRMED' ? const Color(0xFFD32F2F) : const Color(0xFFF57C00),
        LatLng(t['latitude'], t['longitude'])
      )).toList();
      _initializeMarkers();
    } catch (e) {
      debugPrint("Error loading trees: $e");
    }
  }

  Future<void> _loadCustomIcons() async {
    _healthyIcon = await _getMarkerIcon(const Color(0xFF2E7D32));
    _diseasedIcon = await _getMarkerIcon(const Color(0xFFD32F2F));
    _uncertainIcon = await _getMarkerIcon(const Color(0xFFF57C00));
    _initializeMarkers(); 
  }

  Future<BitmapDescriptor> _getMarkerIcon(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final Paint paint = Paint()..color = color.withOpacity(0.2);
    canvas.drawCircle(const Offset(40, 40), 40, paint);
    
    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(40, 40), 40, borderPaint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.nature.codePoint),
      style: TextStyle(
        fontSize: 50.0,
        fontFamily: Icons.nature.fontFamily,
        package: Icons.nature.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(15, 15));

    final ui.Image image = await pictureRecorder.endRecording().toImage(80, 80);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
        });

        try {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
              
          final newPos = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
          );
          
          setState(() {
            _initialPosition = newPos;
          });

          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newCameraPosition(newPos));
          }
        } catch (e) {
          debugPrint("Could not fetch location: $e");
        }
      }
    }
  }

  void _initializeMarkers() {
    _markers.clear();
    for (int i = 0; i < _trees.length; i++) {
      final t = _trees[i];
      _markers.add(
        Marker(
          markerId: MarkerId(t.id),
          position: t.location,
          infoWindow: InfoWindow(title: 'Tree ${t.id}', snippet: t.disease),
          icon: t.status == 'HEALTHY' ? (_healthyIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)) : 
                t.status == 'CONFIRMED' ? (_diseasedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)) : 
                (_uncertainIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
          onTap: () => _showRemoveTreeDialog(t.id),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmed  = _trees.where((t) => t.status == 'CONFIRMED').length;
    final uncertain  = _trees.where((t) => t.status == 'UNCERTAIN').length;
    final healthy    = _trees.where((t) => t.status == 'HEALTHY').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Drone Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Map View'),
            Tab(text: 'Tree List'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Upload bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded, 
                            color: AppColors.primary, 
                            size: 18
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile != null 
                                  ? _selectedFile!.path.split('/').last.split('\\').last 
                                  : 'Tap to upload image/video', 
                              style: AppTextStyles.body.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _processing ? null : _processVideo,
                  icon: _processing
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(_processing ? 'Analysing...' : 'Analyse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Tab 1 — Map view
                _buildMapView(),

                // Tab 2 — Tree list
                _buildTreeList(),

                // Tab 3 — Summary
                _buildSummary(confirmed, uncertain, healthy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isLoadingData
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : _plantations.isEmpty
                      ? const Text('No Plantations', style: AppTextStyles.heading3)
                      : DropdownButton<String>(
                          value: _selectedPlantationId,
                          items: _plantations.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: AppTextStyles.heading3))).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _selectedPlantationId = val);
                              final selected = _plantations.firstWhere((p) => p.id == val);
                              _mapController?.animateCamera(CameraUpdate.newLatLng(selected.location));
                              await _loadTreesForPlantation(val);
                            }
                          },
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        ),
              IconButton(
                icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                onPressed: _showAddPlantationFlow,
              )
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_trees.length} trees scanned', style: AppTextStyles.body),
              Row(
                children: [
                  const Text('Add Mode', style: AppTextStyles.body),
                  Switch(
                    value: _addMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _addMode = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend
          const Row(
            children: [
              _MapLegend(color: Color(0xFF2E7D32), label: 'Healthy'),
              SizedBox(width: 12),
              _MapLegend(color: Color(0xFFD32F2F), label: 'Diseased'),
              SizedBox(width: 12),
              _MapLegend(color: Color(0xFFF57C00), label: 'Uncertain'),
            ],
          ),
          const SizedBox(height: 16),

          // Google Map
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: _initialPosition,
                mapType: MapType.normal,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: _locationPermissionGranted,
                markers: _markers,
                onTap: (LatLng location) {
                  if (_addMode) {
                    _showAddTreeDialog(location);
                  }
                },
                onCameraMove: (pos) {
                  _currentMapCenter = pos.target;
                },
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _trees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = _trees[i];
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PredictionResultScreen())),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.card,
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.nature, color: t.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tree #${t.id}', style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                      Text(t.disease, style: AppTextStyles.body),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.status, style: TextStyle(
                        color: t.color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text('${t.confidence}%', style: TextStyle(
                      color: t.color, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(int confirmed, int uncertain, int healthy) {
    final total = _trees.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(children: [
            _SummaryCard(label: 'Total Trees', value: '$total', icon: Icons.nature,
                color: AppColors.primary),
            const SizedBox(width: 10),
            _SummaryCard(label: 'Diseased', value: '$confirmed', icon: Icons.warning_rounded,
                color: const Color(0xFFD32F2F)),
            const SizedBox(width: 10),
            _SummaryCard(label: 'Healthy', value: '$healthy', icon: Icons.check_circle_rounded,
                color: const Color(0xFF2E7D32)),
          ]),
          const SizedBox(height: 20),

          // Disease breakdown
          const Text('Disease Breakdown', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          _DiseaseRow(disease: 'Leaf Spot',         count: 3, total: total, color: const Color(0xFFD32F2F)),
          const SizedBox(height: 8),
          _DiseaseRow(disease: 'Lethal Yellowing',  count: 1, total: total, color: const Color(0xFFE65100)),
          const SizedBox(height: 8),
          _DiseaseRow(disease: 'Stem Bleeding',     count: 1, total: total, color: const Color(0xFFF57C00)),
          const SizedBox(height: 8),
          _DiseaseRow(disease: 'Healthy',           count: healthy, total: total, color: const Color(0xFF2E7D32)),
          const SizedBox(height: 24),

          // Urgent action
          const Text('Urgent Actions Required', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                _UrgentRow(tree: 'Tree A-03', action: 'Lethal Yellowing — Remove immediately'),
                Divider(height: 16),
                _UrgentRow(tree: 'Tree A-02', action: 'Leaf Spot — Apply fungicide within 24hrs'),
                Divider(height: 16),
                _UrgentRow(tree: 'Tree A-07', action: 'Leaf Spot — Apply fungicide within 24hrs'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Download Full PDF Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'mp4'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _processVideo() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or video first.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
      return;
    }
    if (_plantations.isEmpty || _selectedPlantationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a plantation first!')));
      return;
    }

    setState(() => _processing = true);
    
    // Call the YOLO service foundation
    var predictions = await _yoloService.detectCoconutTrees(_selectedFile!);
    
    if (mounted) {
      try {
        for (int i = 0; i < predictions.length; i++) {
          final newId = 'D-${_trees.length + 1}';
          final confidence = (predictions[i]['confidenceInClass'] * 100).toInt();
          double latOffset = (i * 0.0002) + 0.0001;
          double lngOffset = (i * 0.0002) - 0.0001;
          final loc = LatLng(_initialPosition.target.latitude + latOffset, _initialPosition.target.longitude + lngOffset);
          
          final docId = await FirebaseService.addTree(
            plantationId: _selectedPlantationId!,
            treeId: newId,
            disease: 'Detected',
            status: 'UNCERTAIN',
            confidence: confidence,
            lat: loc.latitude,
            lng: loc.longitude,
          );
          
          _trees.add(_TreeData(docId, newId, 'Detected', 'UNCERTAIN', confidence, const Color(0xFFF57C00), loc));
        }
        setState(() {
          _processing = false;
          _initializeMarkers();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis complete! Found ${predictions.length} coconut trees.', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.primary,
          ),
        );
      } catch (e) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving drone trees: $e')));
      }
    }
  }

  void _showAddPlantationFlow() async {
    final LatLng? selectedLoc = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => LocationSelectionScreen(initialPosition: _currentMapCenter))
    );
    
    if (selectedLoc == null || !mounted) return;

    final TextEditingController nameCtrl = TextEditingController();
    bool isSaving = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Plantation'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(hintText: 'Plantation Name', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameCtrl.text.isNotEmpty) {
                  setDialogState(() => isSaving = true);
                  try {
                    final newId = await FirebaseService.addPlantation(nameCtrl.text.trim(), selectedLoc.latitude, selectedLoc.longitude);
                    if (!mounted) return;
                    setState(() {
                      _plantations.add(_PlantationData(newId, nameCtrl.text.trim(), selectedLoc));
                      _selectedPlantationId = newId;
                    });
                    Navigator.pop(context);
                    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: selectedLoc, zoom: 18.0)));
                    await _loadTreesForPlantation(newId);
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add'),
            )
          ],
        )
      )
    );
  }

  void _showAddTreeDialog(LatLng location) {
    if (_plantations.isEmpty || _selectedPlantationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a plantation first!')));
      return;
    }
    bool isSaving = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Coconut Tree Manually'),
            content: const Text('Do you want to label a tree at this location?'),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  try {
                    final newId = 'M-${_trees.length + 1}';
                    final docId = await FirebaseService.addTree(
                      plantationId: _selectedPlantationId!,
                      treeId: newId,
                      disease: 'Manual Add',
                      status: 'HEALTHY',
                      confidence: 100,
                      lat: location.latitude,
                      lng: location.longitude,
                    );
                    if (!mounted) return;
                    setState(() {
                      _trees.add(_TreeData(docId, newId, 'Manual Add', 'HEALTHY', 100, const Color(0xFF2E7D32), location));
                      _initializeMarkers();
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Tree'),
              ),
            ],
          )
        );
      },
    );
  }

  void _showRemoveTreeDialog(String treeId) {
    if (_selectedPlantationId == null) return;
    final tree = _trees.firstWhere((t) => t.id == treeId);
    bool isRemoving = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Remove Tree'),
            content: Text('Are you sure you want to remove Tree $treeId?'),
            actions: [
              TextButton(
                onPressed: isRemoving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isRemoving ? null : () async {
                  setDialogState(() => isRemoving = true);
                  try {
                    await FirebaseService.removeTree(_selectedPlantationId!, tree.docId);
                    if (mounted) {
                      setState(() {
                        _trees.removeWhere((t) => t.docId == tree.docId);
                        _initializeMarkers();
                      });
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    setDialogState(() => isRemoving = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: isRemoving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        );
      },
    );
  }
}

class _PlantationData {
  final String id;
  final String name;
  final LatLng location;
  const _PlantationData(this.id, this.name, this.location);
}

class _TreeData {
  final String docId;
  final String id, disease, status;
  final int confidence;
  final Color color;
  final LatLng location;
  const _TreeData(this.docId, this.id, this.disease, this.status, this.confidence, this.color, this.location);
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _DiseaseRow extends StatelessWidget {
  final String disease;
  final int count, total;
  final Color color;
  const _DiseaseRow({required this.disease, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = count / total;
    return Row(children: [
      SizedBox(width: 130, child: Text(disease, style: AppTextStyles.body.copyWith(fontSize: 13))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct, minHeight: 8,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      )),
      const SizedBox(width: 8),
      Text('$count', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
    ]);
  }
}

class _UrgentRow extends StatelessWidget {
  final String tree, action;
  const _UrgentRow({required this.tree, required this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.warning_rounded, color: Color(0xFFD32F2F), size: 16),
    const SizedBox(width: 8),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tree, style: AppTextStyles.heading3.copyWith(fontSize: 13, color: const Color(0xFFD32F2F))),
        Text(action, style: AppTextStyles.body.copyWith(fontSize: 12)),
      ],
    )),
  ]);
}
