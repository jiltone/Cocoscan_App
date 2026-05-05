import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'xai_screen.dart';
import 'treatment_screen.dart';

class PredictionResultScreen extends StatefulWidget {
  const PredictionResultScreen({super.key});
  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;
  bool _expanded = false;

  static const _disease    = 'Leaf Spot';
  static const _confidence = 0.92;
  static const _status     = 'CONFIRMED';
  static const _treeId     = 'Tree #A-14';
  static const _statusColor = AppColors.confirmed;

  static const _allProbs = {
    'Leaf Spot'        : 0.92,
    'Healthy'          : 0.04,
    'Lethal Yellowing' : 0.02,
    'Bud Rot'          : 0.01,
    'Stem Bleeding'    : 0.01,
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(begin: 0, end: _confidence).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 200), () => _animCtrl.forward());
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: _share),
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: _download),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Main result card ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_statusColor.withOpacity(0.06), Colors.white],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _statusColor.withOpacity(0.25)),
                boxShadow: [BoxShadow(
                    color: _statusColor.withOpacity(0.08),
                    blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.warning_amber_rounded, color: _statusColor, size: 14),
                      SizedBox(width: 6),
                      Text(_status, style: TextStyle(
                        color: _statusColor, fontSize: 12, fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Disease name
                  Text(_disease, style: AppTextStyles.heading1.copyWith(
                      fontSize: 34, color: _statusColor)),
                  const SizedBox(height: 4),
                  const Text(_treeId, style: AppTextStyles.body),
                  const SizedBox(height: 8),
                  const Text('Scanned just now', style: AppTextStyles.caption),
                  const SizedBox(height: 22),

                  // Animated confidence ring
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => _ConfidenceRing(
                        confidence: _progressAnim.value,
                        color: _statusColor),
                  ),
                  const SizedBox(height: 18),

                  // Thresholds
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _ThresholdRow(label: 'Confirmed (>85%)', value: 85,
                            current: (_confidence*100).toInt(), color: AppColors.confirmed),
                        const SizedBox(height: 8),
                        _ThresholdRow(label: 'Uncertain (60–85%)', value: 60,
                            current: (_confidence*100).toInt(), color: AppColors.uncertain),
                        const SizedBox(height: 8),
                        _ThresholdRow(label: 'Inconclusive (<60%)', value: 0,
                            current: (_confidence*100).toInt(), color: AppColors.healthy),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Disease info ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppDecorations.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('About Leaf Spot', style: AppTextStyles.heading3),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Icon(
                          _expanded ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Leaf Spot (Pestalotiopsis palmarum) is a fungal disease '
                      'that causes brown circular spots with yellow halos on coconut '
                      'palm leaves. It thrives in humid conditions and can spread '
                      'rapidly through a plantation if left untreated.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 12),
                    const _InfoChip(label: 'Fungal Disease', icon: Icons.science_rounded),
                    const SizedBox(height: 6),
                    const _InfoChip(label: 'Highly Contagious', icon: Icons.warning_rounded),
                    const SizedBox(height: 6),
                    const _InfoChip(label: 'Treatable with Fungicide',
                        icon: Icons.check_circle_rounded),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Confidence breakdown ──────────────────────────────
            const Text('Confidence Breakdown', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppDecorations.card,
              child: Column(
                children: _allProbs.entries.map((e) => AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => _ProbBar(
                        label: e.key,
                        prob: e.key == _disease
                            ? _progressAnim.value
                            : e.value,
                        isTop: e.key == _disease)
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Captured image placeholder ────────────────────────
            const Text('Captured Image', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            Container(
              height: 190,
              decoration: BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_rounded, size: 56,
                        color: Colors.white.withOpacity(0.25)),
                    const SizedBox(height: 10),
                    Text('Captured leaf image',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Tap to view full resolution',
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Location & metadata ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card,
              child: const Column(
                children: [
                  _MetaRow(Icons.location_on_outlined, 'Location',
                      'Sector A — Row 4, Plot 14'),
                  Divider(height: 20),
                  _MetaRow(Icons.calendar_today_rounded, 'Date & Time',
                      'Apr 29, 2026 · 01:50 AM'),
                  Divider(height: 20),
                  _MetaRow(Icons.device_hub_rounded, 'Model',
                      'CocoScan AI v2.1 (MobileNet)'),
                  Divider(height: 20),
                  _MetaRow(Icons.speed_rounded, 'Processing Time', '1.4 seconds'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const XAIScreen())),
                  icon: const Icon(Icons.psychology_rounded),
                  label: const Text('View XAI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TreatmentScreen())),
                  icon: const Icon(Icons.healing_rounded),
                  label: const Text('Treatment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _share() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sharing result...')));

  void _download() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Downloading PDF report...')));
}

class _ConfidenceRing extends StatelessWidget {
  final double confidence;
  final Color color;
  const _ConfidenceRing({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140, height: 140,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Outer track
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: confidence,
            strokeWidth: 12,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        // Inner
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${(confidence * 100).toInt()}%',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
          const Text('Confidence',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ]),
      ],
    ),
  );
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final int value, current;
  final Color color;
  const _ThresholdRow({required this.label, required this.value,
      required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    final active = current >= value;
    return Row(children: [
      Icon(active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: active ? color : AppColors.divider, size: 16),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(
        fontSize: 13, color: active ? color : AppColors.textSecondary,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}

class _ProbBar extends StatelessWidget {
  final String label;
  final double prob;
  final bool isTop;
  const _ProbBar({required this.label, required this.prob, required this.isTop});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: isTop ? FontWeight.w700 : FontWeight.w400,
            color: isTop ? AppColors.primary : AppColors.textSecondary),
            overflow: TextOverflow.ellipsis)),
          Text('${(prob * 100).toStringAsFixed(1)}%', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: isTop ? AppColors.primary : AppColors.textSecondary)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: prob, minHeight: 7,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(
                isTop ? AppColors.primary : AppColors.divider.withOpacity(0.6)),
          ),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.primary, size: 15),
    const SizedBox(width: 7),
    Text(label, style: const TextStyle(
        fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
  ]);
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _MetaRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.primary, size: 18),
    const SizedBox(width: 12),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption),
        Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    ),
  ]);
}
