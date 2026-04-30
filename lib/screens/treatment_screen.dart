import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  static const _treatments = [
    _TreatmentStep(
      step: 1,
      title: 'Isolate the Affected Tree',
      description: 'Immediately mark the affected tree and avoid cross-contamination with tools used on it. Do not move infected leaves to other areas of the plantation.',
      icon: Icons.fence_rounded,
      urgency: 'Immediate',
      urgencyColor: Color(0xFFD32F2F),
    ),
    _TreatmentStep(
      step: 2,
      title: 'Remove Infected Leaves',
      description: 'Carefully remove all heavily spotted or yellowing leaves. Place them in sealed bags and dispose of them away from the plantation — do not compost.',
      icon: Icons.content_cut_rounded,
      urgency: 'Within 24 hrs',
      urgencyColor: Color(0xFFF57C00),
    ),
    _TreatmentStep(
      step: 3,
      title: 'Apply Copper Fungicide',
      description: 'Spray copper oxychloride (3g/litre of water) on the remaining leaves, focusing on the undersides. Apply in the early morning or late evening to avoid leaf burn.',
      icon: Icons.sanitizer_rounded,
      urgency: 'Within 48 hrs',
      urgencyColor: Color(0xFFF57C00),
    ),
    _TreatmentStep(
      step: 4,
      title: 'Improve Air Circulation',
      description: 'Prune nearby vegetation that reduces airflow around the tree. High humidity promotes Leaf Spot spread — better circulation helps prevent recurrence.',
      icon: Icons.air_rounded,
      urgency: 'This week',
      urgencyColor: Color(0xFF1565C0),
    ),
    _TreatmentStep(
      step: 5,
      title: 'Follow-up Inspection',
      description: 'Re-scan the tree after 2 weeks. If disease has spread despite treatment, contact your local agricultural officer for advanced fungicide options.',
      icon: Icons.camera_alt_rounded,
      urgency: '2 weeks',
      urgencyColor: Color(0xFF2E7D32),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Treatment Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
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
                      color: AppColors.confirmed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.eco_rounded, color: AppColors.confirmed, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Treating: Leaf Spot', style: AppTextStyles.heading3),
                        const SizedBox(height: 2),
                        Text('Tree #A-14  ·  Confidence: 92%', style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.confirmed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('5-Step Treatment Plan',
                              style: TextStyle(color: AppColors.confirmed,
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Severity warning
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
                    child: Text(
                      'Leaf Spot is contagious. Treat immediately to prevent spread to healthy trees nearby.',
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.confirmed, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Treatment Steps', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text('Follow these steps in order for best results', style: AppTextStyles.body),
            const SizedBox(height: 16),

            // Steps
            ..._treatments.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              return _buildStep(t, isLast: i == _treatments.length - 1);
            }),

            const SizedBox(height: 24),

            // Products section
            Text('Recommended Products', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _ProductCard(
              name: 'Copper Oxychloride 50% WP',
              dose: '3g per litre of water',
              icon: Icons.sanitizer_rounded,
            ),
            const SizedBox(height: 10),
            _ProductCard(
              name: 'Mancozeb 75% WP',
              dose: '2.5g per litre of water (alternative)',
              icon: Icons.science_rounded,
            ),
            const SizedBox(height: 24),

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Need Expert Help?', style: AppTextStyles.heading3),
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
        ),
      ),
    );
  }

  Widget _buildStep(_TreatmentStep t, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
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
                        Icon(t.icon, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t.title, style: AppTextStyles.heading3.copyWith(fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.urgencyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(t.urgency, style: TextStyle(
                            color: t.urgencyColor, fontSize: 10, fontWeight: FontWeight.w600)),
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

class _TreatmentStep {
  final int step;
  final String title, description, urgency;
  final IconData icon;
  final Color urgencyColor;
  const _TreatmentStep({required this.step, required this.title, required this.description,
      required this.icon, required this.urgency, required this.urgencyColor});
}

class _ProductCard extends StatelessWidget {
  final String name, dose;
  final IconData icon;
  const _ProductCard({required this.name, required this.dose, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: AppDecorations.card,
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.heading3.copyWith(fontSize: 13)),
              Text('Dosage: $dose', style: AppTextStyles.caption),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      ],
    ),
  );
}
