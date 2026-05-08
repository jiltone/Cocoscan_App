import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'prediction_result_screen.dart';

class CameraScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const CameraScreen({super.key, this.onBack});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  // ── Camera state ────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _ctrl;
  bool _cameraReady = false;
  bool _flashOn = false;
  int _camIndex = 0;          // 0 = back, 1 = front
  String _captureMode = 'Leaf'; // Leaf | Tree | Gallery
  String _cameraSource = 'Device'; // Device | Drone
  bool _gridOn = true;
  String _hdrMode = 'Auto';
  String _aspectRatio = '4:3';
  String _quality = 'High';
  bool _analyzing = false;
  String? _errorMsg;

  // ── Animations ──────────────────────────────────────────────────
  late AnimationController _scanlineCtrl;
  late Animation<double> _scanlineAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scanlineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _scanlineAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scanlineCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMsg = 'No camera found on this device.');
        return;
      }
      await _startController(_cameras[_camIndex]);
    } catch (e) {
      setState(() => _errorMsg = 'Camera error: $e');
    }
  }

  Future<void> _startController(CameraDescription cam) async {
    final ctrl = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      if (!mounted) return;
      _ctrl?.dispose();
      setState(() {
        _ctrl = ctrl;
        _cameraReady = true;
        _errorMsg = null;
      });
    } catch (e) {
      setState(() => _errorMsg = 'Could not open camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_ctrl == null || !_cameraReady) return;
    setState(() => _flashOn = !_flashOn);
    await _ctrl!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _camIndex = (_camIndex + 1) % _cameras.length;
    setState(() => _cameraReady = false);
    await _startController(_cameras[_camIndex]);
  }

  // ── Capture from camera ─────────────────────────────────────────
  Future<void> _captureAndAnalyze() async {
    if (_analyzing || _ctrl == null || !_cameraReady) return;
    setState(() => _analyzing = true);
    try {
      final file = await _ctrl!.takePicture();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionResultScreen(imagePath: file.path),
        ),
      ).then((_) => setState(() => _analyzing = false));
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capture failed: $e'),
          backgroundColor: const Color(0xFF81C784),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Pick from gallery ───────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    if (_analyzing) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null || !mounted) return;
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionResultScreen(imagePath: file.path),
      ),
    ).then((_) => setState(() => _analyzing = false));
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
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

          // ── Camera preview OR placeholder ──────────────────────
          if (_cameraSource == 'Drone')
            _buildDronePlaceholder()
          else if (_cameraReady && _ctrl != null)
            Positioned.fill(child: CameraPreview(_ctrl!))
          else
            _buildPlaceholder(),

          // ── Grid Overlay ────────────────────────────────────────
          if (_gridOn && (_cameraReady || _cameraSource == 'Drone'))
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),

          // ── Dark vignette overlay ───────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                ),
              ),
            ),
          ),

          // ── Scan frame ─────────────────────────────────────────
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: _frameSize,
              height: _frameHeight,
              child: Stack(
                children: [
                  for (final align in [
                    Alignment.topLeft, Alignment.topRight,
                    Alignment.bottomLeft, Alignment.bottomRight
                  ])
                    Align(
                      alignment: align,
                      child: SizedBox(
                        width: 44, height: 44,
                        child: CustomPaint(painter: _CornerPainter(align)),
                      ),
                    ),

                  if (!_analyzing)
                    AnimatedBuilder(
                      animation: _scanlineAnim,
                      builder: (_, __) => Positioned(
                        top: _scanlineAnim.value * (_frameHeight - 4),
                        left: 10, right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              AppColors.primaryGlow.withOpacity(0.9),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),

                  if (_analyzing)
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) =>
                            Transform.scale(scale: _pulseAnim.value, child: child),
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

          // ── Analysing overlay ───────────────────────────────────
          if (_analyzing)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 120),
                    CircularProgressIndicator(
                        color: AppColors.primaryGlow,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round),
                    SizedBox(height: 20),
                    Text('Analyzing leaf…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('AI model processing image',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // ── Top bar ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Back button (works both in nav shell and pushed route)
                  _CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: _goBack,
                  ),
                  const SizedBox(width: 10),
                  const Spacer(),
                  _CircleBtn(
                    icon: _flashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap: _toggleFlash,
                    active: _flashOn,
                  ),
                  const SizedBox(width: 10),
                  _CircleBtn(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: _flipCamera,
                  ),
                ],
              ),
            ),
          ),

          // ── Hint chip ───────────────────────────────────────────
          Center(
            child: Align(
              alignment: const Alignment(0, -0.55),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  _captureMode == 'Leaf'
                      ? '🌿  Position coconut leaf inside frame'
                      : _captureMode == 'Tree'
                          ? '🌴  Capture the full coconut tree'
                          : '🖼️  Choose an image from gallery',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // ── Bottom controls ─────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 42),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.88)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['Leaf', 'Tree', 'Gallery'].map((mode) {
                        final sel = _captureMode == mode;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _captureMode = mode);
                            if (mode == 'Gallery') _pickFromGallery();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(mode,
                                style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : Colors.white60,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  fontSize: 13,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SideBtn(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(width: 36),

                      // Shutter button
                      GestureDetector(
                        onTap: _captureMode == 'Gallery'
                            ? _pickFromGallery
                            : _captureAndAnalyze,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _analyzing ? 72 : 80,
                          height: _analyzing ? 72 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.45),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _analyzing
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5))
                                : Container(
                                    width: 62,
                                    height: 62,
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 36),

                      _SideBtn(
                        icon: Icons.tune_rounded,
                        label: 'Settings',
                        onTap: _showSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Error banner ────────────────────────────────────────
          if (_errorMsg != null)
            Positioned(
              bottom: 160,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_errorMsg!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050F05), Color(0xFF0A1A0A), Color(0xFF050F0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_rounded,
                  size: 56, color: Colors.white.withOpacity(0.18)),
              const SizedBox(height: 12),
              Text(
                _errorMsg != null ? 'Camera unavailable' : 'Opening camera…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 13,
                    letterSpacing: 0.5),
              ),
              if (_errorMsg == null) ...[
                const SizedBox(height: 20),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGlow,
                      strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildDronePlaceholder() => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A2A), Color(0xFF050F1A), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_takeoff_rounded, size: 64, color: AppColors.primaryGlow.withOpacity(0.8)),
              const SizedBox(height: 16),
              const Text('Connecting to Drone Feed...', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.primaryGlow, strokeWidth: 2),
            ],
          ),
        ),
      );

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Camera Settings',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: AppColors.primaryGlow, size: 20),
                title: const Text('Camera Source', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: DropdownButton<String>(
                  value: _cameraSource,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: AppColors.primaryGlow, fontSize: 13, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  items: ['Device', 'Drone'].map((s) => DropdownMenuItem(value: s, child: Text('$s Camera'))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => _cameraSource = val);
                      setState(() => _cameraSource = val);
                    }
                  },
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_rounded, color: AppColors.primaryGlow, size: 20),
                title: const Text('Grid Overlay', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: Switch(
                  value: _gridOn,
                  activeColor: AppColors.primaryGlow,
                  onChanged: (val) {
                    setModalState(() => _gridOn = val);
                    setState(() => _gridOn = val);
                  },
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              _buildDropdownSetting('HDR', Icons.hdr_on_rounded, _hdrMode, ['Auto', 'On', 'Off'], (val) {
                setModalState(() => _hdrMode = val!);
                setState(() => _hdrMode = val!);
              }),
              _buildDropdownSetting('Aspect Ratio', Icons.aspect_ratio_rounded, _aspectRatio, ['4:3', '16:9', '1:1'], (val) {
                setModalState(() => _aspectRatio = val!);
                setState(() => _aspectRatio = val!);
              }),
              _buildDropdownSetting('Quality', Icons.high_quality_rounded, _quality, ['High', 'Medium', 'Low'], (val) {
                setModalState(() => _quality = val!);
                setState(() => _quality = val!);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(String label, IconData icon, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGlow, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: DropdownButton<String>(
        value: currentValue,
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        underline: const SizedBox(),
        items: options.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _CircleBtn(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color:
                active ? AppColors.primary : Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

class _SideBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _SideBtn(
      {required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SettingTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primaryGlow, size: 20),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: Text(value,
            style: const TextStyle(
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    final double w3 = size.width / 3;
    final double h3 = size.height / 3;

    canvas.drawLine(Offset(w3, 0), Offset(w3, size.height), paint);
    canvas.drawLine(Offset(w3 * 2, 0), Offset(w3 * 2, size.height), paint);
    canvas.drawLine(Offset(0, h3), Offset(size.width, h3), paint);
    canvas.drawLine(Offset(0, h3 * 2), Offset(size.width, h3 * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
