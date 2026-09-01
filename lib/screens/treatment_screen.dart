import 'package:flutter/material.dart';
import '../data/disease_info.dart';
import '../theme/app_theme.dart';
import 'ai_treatment_assistant_screen.dart';

/// Auto-recommends the treatment plan for whichever disease was diagnosed
/// (lib/data/disease_info.dart) — previously this screen always showed a
/// hardcoded "Leaf Spot" demo plan regardless of diseaseKey.
class TreatmentScreen extends StatelessWidget {
  final String diseaseKey;
  final double confidence;

  const TreatmentScreen({
    super.key,
    this.diseaseKey = 'Gray_Leaf_Spot',
    this.confidence = 0.92,
  });

  DiseaseInfo get _info => diseaseInfoByKey[diseaseKey] ?? diseaseInfoByKey['Healthy_Leaves']!;
  bool get _isHealthy => diseaseKey == 'Healthy_Leaves';
  Color get _accent => _isHealthy ? AppColors.healthy : AppColors.confirmed;

  static const _stepIcons = [
    Icons.fence_rounded,
    Icons.content_cut_rounded,
    Icons.sanitizer_rounded,
    Icons.air_rounded,
    Icons.camera_alt_rounded,
  ];

  Color _urgencyColor(String urgency) {
    switch (urgency) {
      case 'Immediate':
        return const Color(0xFFD32F2F);
      case 'Within 24 hrs':
      case 'Within 48 hrs':
        return const Color(0xFFF57C00);
      case 'After lab results':
        return const Color(0xFF7B1FA2);
      case 'This week':
      case '2 weeks':
        return const Color(0xFF1565C0);
      case 'N/A':
        return AppColors.healthy;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_isHealthy ? 'Care Guide' : 'Treatment Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      floatingActionButton: _isHealthy
          ? null
          : FloatingActionButton.extended(
              heroTag: 'treatment_ai_assistant_fab',
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Ask AI Assistant'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiTreatmentAssistantScreen(
                    diseaseKey: diseaseKey,
                    confidence: confidence,
                  ),
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disease summary
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_isHealthy ? Icons.eco_rounded : Icons.coronavirus_rounded,
                        color: _accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Treating: ${info.label}', style: AppTextStyles.heading3),
                        const SizedBox(height: 2),
                        Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                            style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                              '${info.treatmentSteps.length}-Step ${_isHealthy ? 'Care Guide' : 'Treatment Plan'}',
                              style: TextStyle(color: _accent,
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Warning banner — only for diseases with a specific warning
            // (e.g. Leaf_Yellowing/WCLWD has no chemical cure).
            if (info.warning != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.confirmed.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.confirmed.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.confirmed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(info.warning!,
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.confirmed, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 16),

            Text(_isHealthy ? 'Care Guide' : 'Treatment Steps', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(
              _isHealthy
                  ? 'No disease detected — here\'s how to keep it that way'
                  : 'Follow these steps in order for best results',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),

            // Steps — auto-recommended from the diagnosed disease.
            ...info.treatmentSteps.asMap().entries.map((entry) {
              final i = entry.key;
              return _buildStep(entry.value, icon: _stepIcons[i % _stepIcons.length],
                  isLast: i == info.treatmentSteps.length - 1);
            }),

            if (!_isHealthy) ...[
              const SizedBox(height: 8),
              // Contact officer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need Expert Help?', style: AppTextStyles.heading3),
                          Text('Contact your agricultural officer', style: AppTextStyles.body),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Call', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(TreatmentStep t, {required IconData icon, required bool isLast}) {
    final urgencyColor = _urgencyColor(t.urgency);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text('${t.step}', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: AppDecorations.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t.title, style: AppTextStyles.heading3.copyWith(fontSize: 14))),
                        if (t.urgency != 'N/A')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(t.urgency, style: TextStyle(
                              color: urgencyColor, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(t.description, style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
