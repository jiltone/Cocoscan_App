import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/disease_info.dart';
import '../providers/scan_history_provider.dart';
import '../services/firebase_service.dart';
import '../services/tflite_service.dart' show ClassificationResult;
import '../theme/app_theme.dart';
import '../utils/file_helper.dart';
import 'plantation_detail_screen.dart';
import 'xai_screen.dart';
import 'treatment_screen.dart';

class PredictionResultScreen extends StatefulWidget {
  final String? imagePath;

  /// Internal class key, e.g. 'Gray_Leaf_Spot' or 'Healthy_Leaves' — must
  /// match a key in diseaseInfoByKey (lib/data/disease_info.dart) and
  /// backend_python/class_names.json.
  final String diseaseKey;
  final double confidence;

  /// 'CONFIRMED' | 'UNCERTAIN' | 'HEALTHY'. Healthy_Leaves is never treated
  /// as a disease tier — it gets its own status regardless of confidence.
  final String status;

  /// Full probability breakdown keyed by the same internal class keys.
  /// Falls back to a single-entry map from [diseaseKey]/[confidence] when
  /// not supplied (keeps old no-arg call sites compiling).
  final Map<String, double>? probabilities;

  /// Present only when reached from a fresh scan (camera_screen.dart) —
  /// enables the "Save to History" button. Both are needed to call
  /// FirebaseService.saveScanToHistory: [classification] for the prediction
  /// fields, [imageBytes] for the Firestore thumbnail.
  final ClassificationResult? classification;
  final Uint8List? imageBytes;

  /// Compressed thumbnail from a saved history entry (History screen ->
  /// tapping a card) — there's no raw file/bytes for an old scan, only the
  /// base64 thumbnail Firestore stored. Ignored when [imageBytes] is set
  /// (a fresh scan's bytes are always the better source).
  final String? imageBase64;

  /// Present only when this scan came from a plantation tree's "Scan for
  /// disease" action (camera_screen.dart's plantationId/treeId, or
  /// plantation_detail_screen.dart's drone-scan path) — saves the scan
  /// tagged to that plantation (see FirebaseService.saveScanToHistory) and
  /// shows a "View Plantation" button instead of nothing.
  final String? plantationId;
  final String? plantationName;
  final String? treeId;

  const PredictionResultScreen({
    super.key,
    this.imagePath,
    this.diseaseKey = 'Gray_Leaf_Spot',
    this.confidence = 0.92,
    this.status = 'CONFIRMED',
    this.probabilities,
    this.classification,
    this.imageBytes,
    this.imageBase64,
    this.plantationId,
    this.plantationName,
    this.treeId,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;
  bool _expanded = false;

  bool _saving = false;
  bool _saved = false;
  String? _saveError;

  late final DiseaseInfo _info =
      diseaseInfoByKey[widget.diseaseKey] ?? diseaseInfoByKey['Healthy_Leaves']!;
  bool get _isHealthy => widget.diseaseKey == 'Healthy_Leaves';
  Color get _statusColor =>
      _isHealthy ? AppColors.healthy : (widget.status == 'CONFIRMED' ? AppColors.confirmed : AppColors.uncertain);
  String get _statusLabel => _isHealthy ? 'HEALTHY' : widget.status;
  Map<String, double> get _probs =>
      widget.probabilities ?? {widget.diseaseKey: widget.confidence};

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _progressAnim = Tween<double>(begin: 0, end: widget.confidence).animate(
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
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: _statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(_statusLabel, style: TextStyle(
                        color: _statusColor, fontSize: 12, fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Disease name
                  Text(_info.label, style: AppTextStyles.heading1.copyWith(
                      fontSize: 34, color: _statusColor)),
                  if (_info.causalAgent != null) ...[
                    const SizedBox(height: 4),
                    Text(_info.causalAgent!, style: AppTextStyles.body),
                  ],
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
                            current: (widget.confidence*100).toInt(), color: AppColors.confirmed),
                        const SizedBox(height: 8),
                        _ThresholdRow(label: 'Uncertain (60–85%)', value: 60,
                            current: (widget.confidence*100).toInt(), color: AppColors.uncertain),
                        const SizedBox(height: 8),
                        _ThresholdRow(label: 'Inconclusive (<60%)', value: 0,
                            current: (widget.confidence*100).toInt(), color: AppColors.healthy),
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
                      Text('About ${_info.label}', style: AppTextStyles.heading3),
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
                    Text(
                      _isHealthy
                          ? 'This tree shows no visible signs of disease across all seven '
                            'trained classes. Continue routine monitoring and re-scan periodically.'
                          : _info.warning ??
                              '${_info.label} is one of six coconut leaf/stem diseases this model '
                              'was trained to detect${_info.causalAgent != null ? ' (${_info.causalAgent})' : ''}.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 12),
                    if (_isHealthy)
                      const _InfoChip(label: 'No Disease Detected', icon: Icons.check_circle_rounded)
                    else ...[
                      _InfoChip(
                        label: _info.curable ? 'Treatable' : 'No Chemical Cure',
                        icon: _info.curable ? Icons.check_circle_rounded : Icons.warning_rounded,
                      ),
                      const SizedBox(height: 6),
                      const _InfoChip(label: 'See Treatment Plan for next steps',
                          icon: Icons.healing_rounded),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Healthy status — separate from the disease list, since
            // Healthy is not a disease and shouldn't be scored alongside
            // the 6 trained disease classes. ─────────────────────────
            Builder(builder: (_) {
              final healthyProb = _probs['Healthy_Leaves'] ?? 0.0;
              final healthyIsTop = widget.diseaseKey == 'Healthy_Leaves';
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.healthy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.healthy.withOpacity(healthyIsTop ? 0.6 : 0.3),
                      width: healthyIsTop ? 2 : 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.healthy.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.eco_rounded, color: AppColors.healthy, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Healthy',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                                  color: AppColors.healthy)),
                          Text('Not a disease — shown separately from the 6 disease classes',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => Text(
                          '${((healthyIsTop ? _progressAnim.value : healthyProb) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.healthy)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // ── Disease probabilities (the 6 trained disease classes only)
            const Text('Disease Probabilities', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            const Text('The 6 diseases this model detects — Healthy is scored separately above.',
                style: AppTextStyles.caption),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppDecorations.card,
              child: Builder(builder: (_) {
                final diseaseEntries = _probs.entries.where((e) => e.key != 'Healthy_Leaves').toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                if (diseaseEntries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No disease probability data available.', style: AppTextStyles.body),
                  );
                }
                return Column(
                  children: diseaseEntries.map((e) {
                    final entryInfo = diseaseInfoByKey[e.key];
                    final isTop = e.key == widget.diseaseKey;
                    return AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => _ProbBar(
                          label: entryInfo?.label ?? e.key,
                          prob: isTop ? _progressAnim.value : e.value,
                          isTop: isTop,
                          isHealthy: false),
                    );
                  }).toList(),
                );
              }),
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
              clipBehavior: Clip.hardEdge,
              child: _buildCapturedImage(),
            ),
            const SizedBox(height: 24),

            // ── Location & metadata ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card,
              child: Column(
                children: [
                  const _MetaRow(Icons.calendar_today_rounded, 'Date & Time',
                      'Scanned just now'),
                  const Divider(height: 20),
                  const _MetaRow(Icons.device_hub_rounded, 'Model',
                      'CocoScan ResNet50 (7-class)'),
                  const Divider(height: 20),
                  _MetaRow(Icons.category_rounded, 'Predicted Class', widget.diseaseKey),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Save to History ────────────────────────────────────
            // Only shown for a fresh scan (classification + imageBytes come
            // from camera_screen.dart) — saving is an explicit action, not
            // automatic, so re-opening an old result never re-saves it.
            if (widget.classification != null && widget.imageBytes != null) ...[
              SizedBox(
                width: double.infinity,
                child: _saved
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_rounded, color: AppColors.healthy),
                        label: const Text('Saved to History'),
                        style: OutlinedButton.styleFrom(
                          disabledForegroundColor: AppColors.healthy,
                          side: const BorderSide(color: AppColors.healthy, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _saving ? null : _saveToHistory,
                        icon: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_alt_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save to History'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_saveError!,
                      style: const TextStyle(color: AppColors.confirmed, fontSize: 12)),
                ),
              const SizedBox(height: 12),
            ],

            // ── View Plantation ─────────────────────────────────────
            // Only present when this scan came from a plantation tree's
            // "Scan for disease" action — jumps back to where the scan
            // started instead of leaving no way back but the OS back
            // button through the camera screen.
            if (widget.plantationId != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlantationDetailScreen(plantationId: widget.plantationId!)),
                  ),
                  icon: const Icon(Icons.park_rounded),
                  label: Text(widget.plantationName != null
                      ? 'View ${widget.plantationName}'
                      : 'View Plantation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Action buttons ────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => XAIScreen(
                        imageBytes: widget.imageBytes,
                        predictedLabel: _info.label,
                        confidence: widget.confidence,
                      ))),
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
                      MaterialPageRoute(builder: (_) => TreatmentScreen(
                        diseaseKey: widget.diseaseKey,
                        confidence: widget.confidence,
                      ))),
                  icon: Icon(_isHealthy ? Icons.eco_rounded : Icons.healing_rounded),
                  label: Text(_isHealthy ? 'Care Tips' : 'Treatment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isHealthy ? AppColors.healthy : AppColors.primary,
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

  Future<void> _saveToHistory() async {
    if (widget.classification == null || widget.imageBytes == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final result = await FirebaseService.saveScanToHistory(
        classification: widget.classification!,
        imageBytes: widget.imageBytes!,
        plantationId: widget.plantationId,
        plantationName: widget.plantationName,
        treeId: widget.treeId,
      );
      if (!mounted) return;
      // Update the shared history list immediately — HistoryScreen stays
      // mounted in MainShell's IndexedStack the whole time, so without this
      // it wouldn't see the new scan until a full app restart.
      context.read<ScanHistoryProvider>().prepend(
            Map<String, dynamic>.from(result['scan'] as Map),
          );
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Could not save: $e';
      });
    }
  }

  Widget _buildCapturedImage() {
    // A fresh scan's in-memory bytes are always the best source (works on
    // every platform, including web, unlike a file path).
    if (widget.imageBytes != null) {
      return Image.memory(widget.imageBytes!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    // Re-opened from History — no raw bytes, only the compressed thumbnail
    // Firestore stored.
    if (widget.imageBase64 != null && widget.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(base64Decode(widget.imageBase64!),
            fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      } catch (_) {
        // Fall through to the placeholder below on a corrupt/undecodable value.
      }
    }

    final hasImage = widget.imagePath != null && widget.imagePath!.isNotEmpty;
    final imageFile = hasImage && !kIsWeb
        ? createFile(widget.imagePath!)
        : null;

    if (imageFile != null) {
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Center(
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
  final bool isHealthy;
  const _ProbBar({
    required this.label,
    required this.prob,
    required this.isTop,
    this.isHealthy = false,
  });

  @override
  Widget build(BuildContext context) {
    // Healthy is always rendered in the "healthy" green, whether or not it's
    // the top prediction — it's a different kind of outcome, not just
    // another disease competing for probability mass.
    final color = isHealthy
        ? AppColors.healthy
        : (isTop ? AppColors.primary : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Row(children: [
                if (isHealthy) ...[
                  const Icon(Icons.eco_rounded, size: 13, color: AppColors.healthy),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(label, style: TextStyle(
                    fontSize: 13, fontWeight: (isTop || isHealthy) ? FontWeight.w700 : FontWeight.w400,
                    color: color),
                    overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Text('${(prob * 100).toStringAsFixed(1)}%', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: prob, minHeight: 7,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                  (isTop || isHealthy) ? color : AppColors.divider.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
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
