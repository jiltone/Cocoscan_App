import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'treatment_screen.dart';

class XAIScreen extends StatefulWidget {
  const XAIScreen({super.key});
  @override
  State<XAIScreen> createState() => _XAIScreenState();
}

class _XAIScreenState extends State<XAIScreen> with TickerProviderStateMixin {
  double _opacity = 0.65;
  String _mode = 'Grad-CAM';
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;
  late Animation<double> _pulse;
  late Animation<double> _ripple;

  final _modes = {
    'Grad-CAM': 'Uses gradients to highlight image regions important for prediction.',
    'LIME': 'Identifies superpixels contributing most to the disease diagnosis.',
    'Overlay': 'Combines original image and heatmap for full transparency.',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rippleCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat();
    _ripple = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
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
                      onTap: () => setState(() => _mode = mode),
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
                // Dark background
                Container(
                  width: double.infinity, height: double.infinity,
                  decoration: const BoxDecoration(gradient: AppColors.darkGradient),
                  child: Center(
                    child: Icon(Icons.image_rounded, size: 80,
                        color: Colors.white.withOpacity(0.07)),
                  ),
                ),

                // Heatmap (Grad-CAM / Overlay)
                if (_mode == 'Grad-CAM' || _mode == 'Overlay')
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Opacity(
                        opacity: _opacity,
                        child: Container(
                          width: 220, height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.red.withOpacity(_pulse.value * 0.95),
                                Colors.orange.withOpacity(_pulse.value * 0.65),
                                Colors.yellow.withOpacity(_pulse.value * 0.35),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.35, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Ripple effect
                Center(
                  child: AnimatedBuilder(
                    animation: _ripple,
                    builder: (_, __) => Opacity(
                      opacity: (1 - _ripple.value) * 0.4,
                      child: Container(
                        width: 80 + _ripple.value * 200,
                        height: 80 + _ripple.value * 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red.withOpacity(0.6), width: 2),
                        ),
                      ),
                    ),
                  ),
                ),

                // LIME segments
                if (_mode == 'LIME')
                  Center(
                    child: Opacity(
                      opacity: _opacity,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(children: [
                          Positioned(top: 20, left: 10,
                            child: Container(width: 80, height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.yellow, width: 1.5),
                                borderRadius: BorderRadius.circular(4)),
                            )),
                          Positioned(bottom: 20, right: 10,
                            child: Container(width: 60, height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange, width: 1.5),
                                borderRadius: BorderRadius.circular(4)),
                            )),
                          Center(child: Text('High\nImportance',
                            style: const TextStyle(color: Colors.greenAccent,
                                fontSize: 13, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center)),
                        ]),
                      ),
                    ),
                  ),

                // Disease region label
                Positioned(top: 70, right: 50,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Disease Region',
                          style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _LegendItem(Colors.red, 'High attention'),
                      const SizedBox(height: 6),
                      _LegendItem(Colors.orange, 'Medium attention'),
                      const SizedBox(height: 6),
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
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.psychology_rounded, color: AppColors.primaryGlow, size: 14),
                      SizedBox(width: 5),
                      Text('92% confidence', style: TextStyle(
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
                  Expanded(child: Text('Why did the model predict Leaf Spot?',
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
            _InfoItem('Grad-CAM',
                'Uses gradient information to highlight which regions of the image '
                'were most important for the prediction. Red = high importance.'),
            const SizedBox(height: 12),
            _InfoItem('LIME',
                'Divides the image into segments and tests which ones most affect '
                'the prediction. Green segments = positive contribution.'),
            const SizedBox(height: 12),
            _InfoItem('Overlay',
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
