import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  String _period = 'Month';
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: _exportPdf),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,  
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Diseases'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Text('Period:', style: AppTextStyles.caption),
              const SizedBox(width: 10),
              ...[' Week', ' Month', ' Year'].map((p) {
                final sel = _period == p.trim();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _period = p.trim()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.divider)),
                      child: Text(p.trim(), style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }),
            ]),
          ),

          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(period: _period),
                _DiseasesTab(),
                _TrendsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting PDF report...')));
  }
}

class _OverviewTab extends StatelessWidget {
  final String period;
  const _OverviewTab({required this.period});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI cards
        Row(children: [
          _KpiCard('Total Scans', '47', '+12 this $period',
              Icons.camera_alt_rounded, AppColors.primary),
          const SizedBox(width: 12),
          _KpiCard('Confirmed Cases', '18', '+3 this $period',
              Icons.warning_amber_rounded, AppColors.confirmed),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _KpiCard('Healthy Trees', '29', '+9 this $period',
              Icons.check_circle_outline_rounded, AppColors.healthy),
          const SizedBox(width: 12),
          _KpiCard('Avg Confidence', '84%', '+2% accuracy',
              Icons.psychology_rounded, const Color(0xFF4527A0)),
        ]),
        const SizedBox(height: 24),

        // Health Index
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Plantation Health Index',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HealthBar('Sector A', 0.72, Colors.white),
                      const SizedBox(height: 10),
                      _HealthBar('Sector B', 0.91, Colors.white),
                      const SizedBox(height: 10),
                      _HealthBar('Sector C', 0.85, Colors.white),
                      const SizedBox(height: 10),
                      _HealthBar('Sector D', 0.68, Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(children: [
                  const Text('87%', style: TextStyle(
                      color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                  Text('Overall', style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ]),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Weekly bar chart (manual)
        Text('Scans per Day', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text('This $period', style: AppTextStyles.caption),
        const SizedBox(height: 14),
        _BarChart(),
        const SizedBox(height: 40),
      ],
    ),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value, subtitle;
  final IconData icon;
  final Color color;
  const _KpiCard(this.label, this.value, this.subtitle, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.caption, maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _HealthBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 56,
      child: Text(label, style: TextStyle(color: color.withOpacity(0.8),
          fontSize: 11, fontWeight: FontWeight.w500))),
    const SizedBox(width: 8),
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value, minHeight: 7,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ),
    const SizedBox(width: 8),
    Text('${(value * 100).toInt()}%',
        style: TextStyle(color: color.withOpacity(0.9),
            fontSize: 11, fontWeight: FontWeight.w700)),
  ]);
}

class _BarChart extends StatelessWidget {
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final _values = [8, 12, 6, 15, 9, 3, 7];

  @override
  Widget build(BuildContext context) {
    final max = _values.reduce((a, b) => a > b ? a : b).toDouble();
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_days.length, (i) {
          final frac = _values[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${_values[i]}', style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400 + i * 80),
                      height: frac * 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryGlow],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_days[i], style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DiseasesTab extends StatelessWidget {
  final _diseases = [
    _DiseaseAnalysis('Leaf Spot', 19, 0.40, AppColors.confirmed,
        'Pestalotiopsis palmarum'),
    _DiseaseAnalysis('Lethal Yellowing', 13, 0.27, AppColors.uncertain,
        'Phytoplasma disease'),
    _DiseaseAnalysis('Bud Rot', 9, 0.19, const Color(0xFF7B1FA2),
        'Phytophthora palmivora'),
    _DiseaseAnalysis('Stem Bleeding', 7, 0.15, AppColors.secondary,
        'Thielaviopsis paradoxa'),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Disease Breakdown', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text('All confirmed detections this period',
            style: AppTextStyles.body),
        const SizedBox(height: 16),
        ..._diseases.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: d.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13)),
                    child: Icon(Icons.eco_rounded, color: d.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: AppTextStyles.heading3.copyWith(fontSize: 15)),
                      Text(d.scientificName, style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.italic)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${d.count}', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: d.color)),
                    const Text('cases', style: AppTextStyles.caption),
                  ]),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${(d.percentage * 100).toInt()}% of all cases',
                      style: TextStyle(fontSize: 12, color: d.color,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: d.percentage, minHeight: 8,
                    backgroundColor: d.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(d.color),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );
}

class _DiseaseAnalysis {
  final String name, scientificName;
  final int count;
  final double percentage;
  final Color color;
  const _DiseaseAnalysis(this.name, this.count, this.percentage,
      this.color, this.scientificName);
}

class _TrendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Trends', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text('Disease cases by month', style: AppTextStyles.body),
        const SizedBox(height: 16),
        _MonthlyTrendChart(),
        const SizedBox(height: 24),
        const Text('Key Insights', style: AppTextStyles.heading3),
        const SizedBox(height: 14),
        _InsightCard(
          icon: Icons.trending_up_rounded,
          title: 'Leaf Spot increasing',
          body: 'Detected +42% more Leaf Spot cases compared to last month, '
              'likely due to high humidity in Sector A.',
          color: AppColors.confirmed,
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.trending_down_rounded,
          title: 'Bud Rot decreasing',
          body: 'Bud Rot cases dropped by 18% following treatment campaigns in Sector D.',
          color: AppColors.healthy,
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.lightbulb_outline_rounded,
          title: 'Recommendation',
          body: 'Increase scanning frequency in Sector A & B — early detection is '
              'critical this season.',
          color: AppColors.secondary,
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}

class _MonthlyTrendChart extends StatelessWidget {
  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  final _healthy = [28, 31, 29, 35, 38, 34];
  final _diseased = [14, 11, 13, 9, 7, 10];

  @override
  Widget build(BuildContext context) {
    final maxH = _healthy.reduce((a, b) => a > b ? a : b);
    final maxD = _diseased.reduce((a, b) => a > b ? a : b);
    final max = (maxH > maxD ? maxH : maxD).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Column(
        children: [
          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 12, height: 12, color: AppColors.healthy),
            const SizedBox(width: 6),
            const Text('Healthy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 20),
            Container(width: 12, height: 12, color: AppColors.confirmed),
            const SizedBox(width: 6),
            const Text('Diseased', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_months.length, (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              child: Container(
                                height: (_healthy[i] / max) * 90,
                                color: AppColors.healthy.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              child: Container(
                                height: (_diseased[i] / max) * 90,
                                color: AppColors.confirmed.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_months[i], style: AppTextStyles.caption),
                    ],
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  const _InsightCard(
      {required this.icon, required this.title, required this.body,
       required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.heading3.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(body, style: AppTextStyles.body.copyWith(fontSize: 13)),
        ]),
      ),
    ]),
  );
}
