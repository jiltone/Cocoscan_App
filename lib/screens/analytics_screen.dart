import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/disease_info.dart';
import '../providers/scan_history_provider.dart';
import '../theme/app_theme.dart';

/// Analytics used to be a fully static demo screen (every number hardcoded).
/// Everything here is now derived from ScanHistoryProvider's real scan list.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanHistoryProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final allScans = context.watch<ScanHistoryProvider>().scans;
    final data = _AnalyticsData.compute(allScans, _period);

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
              ...['Week', 'Month', 'Year'].map((p) {
                final sel = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _period = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.divider)),
                      child: Text(p, style: TextStyle(
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
                _OverviewTab(period: _period, data: data),
                _DiseasesTab(period: _period, data: data),
                _TrendsTab(data: data),
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

// ── Real-data model ──────────────────────────────────────────────────

class _DiseaseStat {
  final String key, name, causalAgent;
  final int count;
  final double percentage;
  final Color color;
  const _DiseaseStat({
    required this.key, required this.name, required this.causalAgent,
    required this.count, required this.percentage, required this.color,
  });
}

class _AnalyticsData {
  final int totalScans;
  final int confirmedCount;
  final int uncertainCount;
  final int healthyCount;
  final int avgConfidencePercent;
  final List<int> last7DaysCounts; // oldest -> newest
  final List<_DiseaseStat> diseaseBreakdown;
  final List<int> last6MonthsHealthy;
  final List<int> last6MonthsDiseased;
  final List<String> last6MonthsLabels;
  final List<String> insights;

  const _AnalyticsData({
    required this.totalScans,
    required this.confirmedCount,
    required this.uncertainCount,
    required this.healthyCount,
    required this.avgConfidencePercent,
    required this.last7DaysCounts,
    required this.diseaseBreakdown,
    required this.last6MonthsHealthy,
    required this.last6MonthsDiseased,
    required this.last6MonthsLabels,
    required this.insights,
  });

  static const _colors = [
    AppColors.confirmed, AppColors.uncertain, Color(0xFF7B1FA2), AppColors.secondary, Color(0xFF00695C),
  ];

  static DateTime? _tsOf(dynamic scan) {
    final ms = scan['timestampMs'] as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static _AnalyticsData compute(List<dynamic> allScans, String period) {
    final now = DateTime.now();
    final cutoff = switch (period) {
      'Week' => now.subtract(const Duration(days: 7)),
      'Year' => now.subtract(const Duration(days: 365)),
      _ => now.subtract(const Duration(days: 30)),
    };
    // Scans with no timestamp (legacy docs) are kept regardless of period —
    // excluding them would just hide old data again, the opposite of what
    // getScans() was fixed to do.
    final scans = allScans.where((s) {
      final ts = _tsOf(s);
      return ts == null || ts.isAfter(cutoff);
    }).toList();

    var confirmed = 0, uncertain = 0, healthy = 0;
    var confidenceSum = 0.0;
    final diseaseCounts = <String, int>{};

    for (final s in scans) {
      final status = s['status'] as String? ?? 'UNCERTAIN';
      confidenceSum += (s['confidence'] as num? ?? 0).toDouble();
      if (status == 'HEALTHY') {
        healthy++;
      } else {
        if (status == 'CONFIRMED') confirmed++;
        if (status == 'UNCERTAIN') uncertain++;
        final key = s['diseaseKey'] as String? ?? 'Gray_Leaf_Spot';
        diseaseCounts[key] = (diseaseCounts[key] ?? 0) + 1;
      }
    }
    final diseasedTotal = confirmed + uncertain;

    final sorted = diseaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final breakdown = <_DiseaseStat>[];
    for (var i = 0; i < sorted.length; i++) {
      final info = diseaseInfoByKey[sorted[i].key];
      breakdown.add(_DiseaseStat(
        key: sorted[i].key,
        name: info?.label ?? sorted[i].key,
        causalAgent: info?.causalAgent ?? '—',
        count: sorted[i].value,
        percentage: diseasedTotal == 0 ? 0.0 : sorted[i].value / diseasedTotal,
        color: _colors[i % _colors.length],
      ));
    }

    // Last 7 calendar days, always — independent of the period selector,
    // which only scopes the KPI cards / disease breakdown above.
    final last7 = List<int>.filled(7, 0);
    for (final s in allScans) {
      final ts = _tsOf(s);
      if (ts == null) continue;
      final daysAgo = now.difference(DateTime(ts.year, ts.month, ts.day)).inDays;
      if (daysAgo >= 0 && daysAgo < 7) last7[6 - daysAgo]++;
    }

    // Last 6 months healthy vs diseased, from the full history (trends need
    // a longer view than any single period selection).
    final monthHealthy = List<int>.filled(6, 0);
    final monthDiseased = List<int>.filled(6, 0);
    final monthLabels = List<String>.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return names[m.month - 1];
    });
    for (final s in allScans) {
      final ts = _tsOf(s);
      if (ts == null) continue;
      final monthsAgo = (now.year - ts.year) * 12 + (now.month - ts.month);
      if (monthsAgo < 0 || monthsAgo > 5) continue;
      final idx = 5 - monthsAgo;
      if ((s['status'] as String?) == 'HEALTHY') {
        monthHealthy[idx]++;
      } else {
        monthDiseased[idx]++;
      }
    }

    final insights = <String>[];
    if (scans.isEmpty) {
      insights.add('No scans recorded in this period yet — results will appear here once you start scanning.');
    } else {
      if (breakdown.isNotEmpty) {
        final top = breakdown.first;
        insights.add('${top.name} is the most common finding this $period — '
            '${top.count} case${top.count == 1 ? '' : 's'} (${(top.percentage * 100).round()}% of diseased scans).');
      }
      final healthyPct = scans.isEmpty ? 0 : (healthy / scans.length * 100).round();
      insights.add('$healthyPct% of scans this $period came back healthy.');
      if (uncertain > 0) {
        insights.add('$uncertain scan${uncertain == 1 ? '' : 's'} came back Uncertain — '
            'consider a manual field inspection for those trees.');
      }
    }

    return _AnalyticsData(
      totalScans: scans.length,
      confirmedCount: confirmed,
      uncertainCount: uncertain,
      healthyCount: healthy,
      avgConfidencePercent: scans.isEmpty ? 0 : ((confidenceSum / scans.length) * 100).round(),
      last7DaysCounts: last7,
      diseaseBreakdown: breakdown,
      last6MonthsHealthy: monthHealthy,
      last6MonthsDiseased: monthDiseased,
      last6MonthsLabels: monthLabels,
      insights: insights,
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String period;
  final _AnalyticsData data;
  const _OverviewTab({required this.period, required this.data});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI cards
        Row(children: [
          _KpiCard('Total Scans', '${data.totalScans}', 'This $period',
              Icons.camera_alt_rounded, AppColors.primary),
          const SizedBox(width: 12),
          _KpiCard('Confirmed Cases', '${data.confirmedCount}', 'This $period',
              Icons.warning_amber_rounded, AppColors.confirmed),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _KpiCard('Healthy Trees', '${data.healthyCount}', 'This $period',
              Icons.check_circle_outline_rounded, AppColors.healthy),
          const SizedBox(width: 12),
          _KpiCard('Avg Confidence', '${data.avgConfidencePercent}%', 'This $period',
              Icons.psychology_rounded, const Color(0xFF4527A0)),
        ]),
        const SizedBox(height: 24),

        const Text('Scans per Day', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text('Last 7 days', style: AppTextStyles.caption),
        const SizedBox(height: 14),
        _BarChart(values: data.last7DaysCounts),
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
        Text(value, style: const TextStyle(
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

class _BarChart extends StatelessWidget {
  final List<int> values;
  const _BarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List<String>.generate(7, (i) {
      const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      final d = now.subtract(Duration(days: 6 - i));
      return names[d.weekday - 1];
    });
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b).toDouble();
    final safeMax = max == 0 ? 1.0 : max;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(days.length, (i) {
          final frac = values[i] / safeMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${values[i]}', style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400 + i * 80),
                      height: frac * 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryGlow],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[i], style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Diseases tab ──────────────────────────────────────────────────────

class _DiseasesTab extends StatelessWidget {
  final String period;
  final _AnalyticsData data;
  const _DiseasesTab({required this.period, required this.data});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Disease Breakdown', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text('All confirmed & uncertain detections this $period',
            style: AppTextStyles.body),
        const SizedBox(height: 16),
        if (data.diseaseBreakdown.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No disease cases in this period.', style: AppTextStyles.body),
          )
        else
          ...data.diseaseBreakdown.map((d) => Padding(
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
                        Text(d.causalAgent, style: AppTextStyles.caption.copyWith(
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

// ── Trends tab ────────────────────────────────────────────────────────

class _TrendsTab extends StatelessWidget {
  final _AnalyticsData data;
  const _TrendsTab({required this.data});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Trends', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        const Text('Healthy vs. diseased scans, last 6 months', style: AppTextStyles.body),
        const SizedBox(height: 16),
        _MonthlyTrendChart(
          labels: data.last6MonthsLabels,
          healthy: data.last6MonthsHealthy,
          diseased: data.last6MonthsDiseased,
        ),
        const SizedBox(height: 24),
        const Text('Key Insights', style: AppTextStyles.heading3),
        const SizedBox(height: 14),
        ...data.insights.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InsightCard(
            icon: Icons.insights_rounded,
            body: text,
            color: AppColors.primary,
          ),
        )),
        const SizedBox(height: 40),
      ],
    ),
  );
}

class _MonthlyTrendChart extends StatelessWidget {
  final List<String> labels;
  final List<int> healthy;
  final List<int> diseased;
  const _MonthlyTrendChart({required this.labels, required this.healthy, required this.diseased});

  @override
  Widget build(BuildContext context) {
    final maxH = healthy.isEmpty ? 0 : healthy.reduce((a, b) => a > b ? a : b);
    final maxD = diseased.isEmpty ? 0 : diseased.reduce((a, b) => a > b ? a : b);
    final max = (maxH > maxD ? maxH : maxD).toDouble();
    final safeMax = max == 0 ? 1.0 : max;

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
              children: List.generate(labels.length, (i) => Expanded(
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
                                height: (healthy[i] / safeMax) * 90,
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
                                height: (diseased[i] / safeMax) * 90,
                                color: AppColors.confirmed.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(labels[i], style: AppTextStyles.caption),
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
  final String body;
  final Color color;
  const _InsightCard({required this.icon, required this.body, required this.color});

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
        child: Text(body, style: AppTextStyles.body.copyWith(fontSize: 13)),
      ),
    ]),
  );
}
