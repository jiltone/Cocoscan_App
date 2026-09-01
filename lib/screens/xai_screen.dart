import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/inference_service.dart';
import '../theme/app_theme.dart';
import 'treatment_screen.dart';

class XAIScreen extends StatefulWidget {
  /// The captured leaf photo's raw bytes, used to generate the explanation.
  /// Optional so existing call sites keep compiling; pass it to see a real
  /// Grad-CAM/LIME image instead of the "unavailable" placeholder.
  ///
  /// Deliberately bytes, not a dart:io File: File I/O isn't actually
  /// implemented on Flutter Web despite compiling there (throws
  /// "Unsupported operation: Platform._operatingSystem" at runtime), so a
  /// File-based version of this screen always failed on web. The bytes are
  /// already in memory from the camera capture anyway — no disk read needed
  /// on any platform.
  final Uint8List? imageBytes;
  final String predictedLabel;
  final double confidence;

  const XAIScreen({
    super.key,
    this.imageBytes,
    this.predictedLabel = 'Leaf Spot',
    this.confidence = 0.92,
  });

  @override
  State<XAIScreen> createState() => _XAIScreenState();
}

class _XAIScreenState extends State<XAIScreen> {
  double _opacity = 0.65;
  String _mode = 'Grad-CAM';

  final _modes = {
    'Grad-CAM': 'Gradient-weighted Class Activation Mapping highlights the image '
        'regions that most influenced the prediction. Warmer colours (red/orange) '
        'indicate higher model attention.',
    'LIME': 'Divides the image into superpixels and tests which ones most affect '
        'the prediction. Highlighted segments contributed most to the diagnosis.',
    'Overlay': 'Combines the original image and the Grad-CAM heatmap so you can '
        'see exactly which leaf features triggered the diagnosis.',
  };

  // image_base64 per mode, fetched from the FastAPI /api/gradcam and
  // /api/lime endpoints (Overlay reuses the Grad-CAM image at a different
  // blend alpha, applied client-side via the opacity slider).
  final Map<String, String?> _images = {'Grad-CAM': null, 'LIME': null, 'Overlay': null};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) _loadExplanation(_mode);
  }

  Future<void> _loadExplanation(String mode) async {
    if (widget.imageBytes == null) return;
    final needsLime = mode == 'LIME';
    final key = needsLime ? 'LIME' : 'Grad-CAM';
    if (_images[key] != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final base64Image = await InferenceService.explanationImageBase64(
        bytes: widget.imageBytes!,
        lime: needsLime,
      );
      if (!mounted) return;
      setState(() {
        _images[key] = base64Image;
        if (key == 'Grad-CAM') _images['Overlay'] = base64Image;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'AI Explanation is unavailable offline. Reconnect and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('XAI Explanation'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: _showInfo),
          IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading XAI image...')))),
        ],
      ),
      body: Column(
        children: [

          // ── Mode selector ─────────────────────────────────────
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: _modes.keys.map((mode) {
                final sel = _mode == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _mode = mode);
                        _loadExplanation(mode);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: sel ? AppColors.primaryGradient : null,
                          color: sel ? null : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(mode, textAlign: TextAlign.center,
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white54,
                            fontSize: 12.5,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── XAI Image view ────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Dark background / fallback
                Container(
                  width: double.infinity, height: double.infinity,
                  decoration: const BoxDecoration(gradient: AppColors.darkGradient),
                  child: Center(
                    child: Icon(Icons.image_rounded, size: 80,
                        color: Colors.white.withOpacity(0.07)),
                  ),
                ),

                // Real Grad-CAM / LIME / Overlay image from the backend
                if (_images[_mode] != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _mode == 'Overlay' ? _opacity : 1.0,
                      child: Image.memory(
                        base64Decode(_images[_mode]!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGlow),
                  )
                else if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ]),
                    ),
                  )
                else if (widget.imageBytes == null)
                  Center(
                    child: Text('No captured image supplied to this screen.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ),

                // Colour legend
                Positioned(bottom: 20, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _LegendItem(Colors.red, 'High attention'),
                      SizedBox(height: 6),
                      _LegendItem(Colors.orange, 'Medium attention'),
                      SizedBox(height: 6),
                      _LegendItem(Colors.yellow, 'Low attention'),
                    ]),
                  ),
                ),

                // Confidence badge
                Positioned(top: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.psychology_rounded, color: AppColors.primaryGlow, size: 14),
                      const SizedBox(width: 5),
                      Text('${(widget.confidence * 100).toStringAsFixed(1)}% ${widget.predictedLabel}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Opacity slider ────────────────────────────────────
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Icon(Icons.opacity, color: Colors.white54, size: 18),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.1, max: 1.0,
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.white12,
                  onChanged: (v) => setState(() => _opacity = v),
                ),
              ),
              Text('${(_opacity * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),

          // ── Explanation panel ─────────────────────────────────
          Container(
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.psychology_rounded, color: AppColors.primaryGlow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Why did the model predict ${widget.predictedLabel}?',
                    style: AppTextStyles.heading3.copyWith(color: Colors.white, fontSize: 14))),
                ]),
                const SizedBox(height: 10),
                Text(_modes[_mode]!, style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.6)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TreatmentScreen())),
                    icon: const Icon(Icons.healing_rounded),
                    label: const Text('See Treatment Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About XAI Techniques',
                style: AppTextStyles.heading2.copyWith(color: Colors.white)),
            const SizedBox(height: 16),
            const _InfoItem('Grad-CAM',
                'Uses gradient information to highlight which regions of the image '
                'were most important for the prediction. Red = high importance.'),
            const SizedBox(height: 12),
            const _InfoItem('LIME',
                'Divides the image into segments and tests which ones most affect '
                'the prediction. Green segments = positive contribution.'),
            const SizedBox(height: 12),
            const _InfoItem('Overlay',
                'Shows both the original image and the heatmap combined, so you '
                'can see exactly which leaf features triggered the diagnosis.'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 7),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);
}

class _InfoItem extends StatelessWidget {
  final String title, desc;
  const _InfoItem(this.title, this.desc);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(
          color: AppColors.primaryGlow, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(desc, style: TextStyle(
          color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5)),
    ],
  );
}
