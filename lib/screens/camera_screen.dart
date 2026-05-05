import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'prediction_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  bool _flashOn = false;
  bool _analyzing = false;
  String _captureMode = 'Leaf';
  int _zoom = 1;

  late AnimationController _scanlineCtrl;
  late Animation<double> _scanlineAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scanlineCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _scanlineAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scanlineCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanlineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double get _frameSize => _captureMode == 'Leaf' ? 280.0 : 320.0;
  double get _frameHeight => _captureMode == 'Leaf' ? 280.0 : 200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── Camera viewfinder (simulated) ────────────────────────
          Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF050F05), Color(0xFF0A1A0A), Color(0xFF050F0F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded,
                      size: 56, color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 12),
                  Text('Live Camera Preview',
                      style: TextStyle(color: Colors.white.withOpacity(0.2),
                          fontSize: 13, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),

          // ── Animated scan frame ──────────────────────────────────
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: _frameSize,
              height: _frameHeight,
              child: Stack(
                children: [
                  // Corner brackets
                  for (final align in [Alignment.topLeft, Alignment.topRight,
                                       Alignment.bottomLeft, Alignment.bottomRight])
                    Align(
                      alignment: align,
                      child: SizedBox(
                        width: 44, height: 44,
                        child: CustomPaint(painter: _CornerPainter(align)),
                      ),
                    ),

                  // Animated scan line
                  if (!_analyzing)
                    AnimatedBuilder(
                      animation: _scanlineAnim,
                      builder: (_, __) => Positioned(
                        top: _scanlineAnim.value * (_frameHeight - 4),
                        left: 10, right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent,
                                AppColors.primaryGlow.withOpacity(0.8),
                                Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Analyzing indicator
                  if (_analyzing)
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGlow, width: 2),
                          ),
                          child: const Icon(Icons.psychology_rounded,
                              color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Analyzing overlay ────────────────────────────────────
          if (_analyzing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),
                    const CircularProgressIndicator(
                      color: AppColors.primaryGlow, strokeWidth: 3,
                      strokeCap: StrokeCap.round),
                    const SizedBox(height: 20),
                    const Text('Analyzing leaf...', style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('AI model processing image',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  ],
                ),
              ),
            ),

          // ── Top controls ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 10),
                  // Zoom selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [1, 2, 3].map((z) => GestureDetector(
                        onTap: () => setState(() => _zoom = z),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _zoom == z ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text('${z}x', style: TextStyle(
                            color: _zoom == z ? Colors.white : Colors.white60,
                            fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      )).toList(),
                    ),
                  ),
                  const Spacer(),
                  _CircleBtn(
                    icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    onTap: () => setState(() => _flashOn = !_flashOn),
                    active: _flashOn,
                  ),
                  const SizedBox(width: 10),
                  _CircleBtn(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── Mode label chip ──────────────────────────────────────
          Center(
            child: Align(
              alignment: const Alignment(0, -0.55),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  _captureMode == 'Leaf'
                      ? 'Position leaf inside frame'
                      : _captureMode == 'Tree'
                      ? 'Capture the full coconut tree'
                      : 'Select from gallery',
                  style: TextStyle(color: Colors.white.withOpacity(0.85),
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 42),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode selector tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Leaf', 'Tree', 'Gallery'].map((mode) {
                        final selected = _captureMode == mode;
                        return GestureDetector(
                          onTap: () => setState(() => _captureMode = mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: selected
                                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 10, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Text(mode, style: TextStyle(
                              color: selected ? Colors.white : Colors.white60,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 13,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Capture buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gallery
                      _SideBtn(
                        icon: Icons.photo_library_rounded,
                        onTap: _captureMode == 'Gallery' ? _analyze : () {},
                        label: 'Gallery',
                      ),
                      const SizedBox(width: 36),

                      // Shutter
                      GestureDetector(
                        onTap: _analyzing ? null : _analyze,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _analyzing ? 72 : 80,
                          height: _analyzing ? 72 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 20, spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _analyzing
                                ? const SizedBox(width: 28, height: 28,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : Container(
                                    width: 62, height: 62,
                                    decoration: const BoxDecoration(
                                        color: Colors.white, shape: BoxShape.circle),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),

                      // Settings
                      _SideBtn(
                        icon: Icons.tune_rounded,
                        onTap: _showSettings,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _analyze() async {
    if (_analyzing) return;
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const PredictionResultScreen()));
  }

  void _showSettings() {
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
            Text('Camera Settings',
                style: AppTextStyles.heading3.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            const _SettingTile(icon: Icons.timer_rounded, label: 'Timer', value: 'Off'),
            const _SettingTile(icon: Icons.grid_on_rounded, label: 'Grid', value: 'Enabled'),
            const _SettingTile(icon: Icons.hdr_on_rounded, label: 'HDR', value: 'Auto'),
            const _SettingTile(icon: Icons.aspect_ratio_rounded, label: 'Aspect Ratio', value: '4:3'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _CircleBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

class _SideBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _SideBtn({required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      const SizedBox(height: 5),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6),
          fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SettingTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primaryGlow, size: 20),
    title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
    trailing: Text(value, style: const TextStyle(
        color: AppColors.textSecondary, fontSize: 13)),
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  const _CornerPainter(this.alignment);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGlow
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    final l = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final t = alignment == Alignment.topLeft || alignment == Alignment.topRight;

    final x = l ? 0.0 : size.width;
    final y = t ? 0.0 : size.height;
    final dx = l ? len : -len;
    final dy = t ? len : -len;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
