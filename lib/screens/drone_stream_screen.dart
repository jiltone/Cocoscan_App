import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Live drone camera feed over RTSP/HTTP (or any URL libVLC can demux) —
/// lets an officer/farmer connect to their drone's video stream and capture
/// a still frame to feed into the same disease classifier used for
/// phone-camera scans (see InferenceService.classify).
///
/// Native platforms only. flutter_vlc_player wraps libVLC via platform
/// channels, which has no web implementation — this screen shows an
/// explanatory message on web instead of attempting to connect.
class DroneStreamScreen extends StatefulWidget {
  const DroneStreamScreen({super.key});

  @override
  State<DroneStreamScreen> createState() => _DroneStreamScreenState();
}

class _DroneStreamScreenState extends State<DroneStreamScreen> {
  static const _prefsKey = 'cocoscan_drone_stream_url';
  final _urlController = TextEditingController();
  VlcPlayerController? _vlcController;
  bool _connecting = false;
  bool _connected = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && mounted) _urlController.text = saved;
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, url);

      _vlcController?.dispose();
      _vlcController = VlcPlayerController.network(
        url,
        autoPlay: true,
        hwAcc: HwAcc.full,
        options: VlcPlayerOptions(),
      );
      setState(() {
        _connected = true;
        _connecting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not connect to $url: $e';
        _connecting = false;
      });
    }
  }

  Future<void> _captureAndReturn() async {
    if (_vlcController == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final frame = await _vlcController!.takeSnapshot();
      if (!mounted) return;
      Navigator.pop(context, frame);
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Frame capture failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _vlcController?.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Drone Camera'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
      ),
      body: kIsWeb ? _webUnsupported() : _nativeBody(),
      floatingActionButton: (!kIsWeb && _connected)
          ? FloatingActionButton.extended(
              heroTag: 'drone_capture_fab',
              onPressed: _capturing ? null : _captureAndReturn,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: _capturing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.camera_alt_rounded),
              label: Text(_capturing ? 'Capturing...' : 'Capture & Scan'),
            )
          : null,
    );
  }

  Widget _webUnsupported() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            const Text("Live drone video isn't supported in the web build.",
                style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Run this app on Android, Windows, macOS, or Linux to connect to a drone camera stream.',
              style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center,
            ),
          ]),
        ),
      );

  Widget _nativeBody() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF111111),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'rtsp://192.168.x.x:554/stream or http://...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _connecting ? null : _connect,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
                child: _connecting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Connect'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_error!, style: const TextStyle(color: AppColors.confirmed, fontSize: 12)),
          ),
        Expanded(
          child: _connected && _vlcController != null
              ? VlcPlayer(
                  controller: _vlcController!,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                )
              : Center(
                  child: Text("Enter your drone's stream URL and tap Connect.",
                      style: TextStyle(color: Colors.white.withOpacity(0.4))),
                ),
        ),
      ],
    );
  }
}
