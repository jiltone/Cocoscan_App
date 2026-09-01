import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_history_provider.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_utils.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';
import 'prediction_result_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final String userName;
  final String? avatarUrl;
  final void Function(int)? onTabChange;
  const HomeScreen({
    super.key,
    required this.role,
    this.userName = '',
    this.avatarUrl,
    this.onTabChange,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    // MainShell keeps every tab mounted via IndexedStack, so this only runs
    // once — ScanHistoryProvider.prepend() (from a "Save to History" action
    // elsewhere) is what keeps this screen's real data in sync afterwards.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanHistoryProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scans = context.watch<ScanHistoryProvider>().scans;
    final stats = _HomeStats.from(scans);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Expandable AppBar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 208,
            collapsedHeight: 70,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252), shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Stack(
                  children: [
                    // Background deco
                    Positioned(top: -30, right: -30,
                      child: Container(width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)))),
                    Positioned(bottom: -40, left: -20,
                      child: Container(width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04)))),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                // Greeting
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_greeting(), style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13)),
                                      Text(
                                        widget.userName.isEmpty ? 'Loading...' : widget.userName,
                                        style: const TextStyle(
                                          color: Colors.white, fontSize: 22,
                                          fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.white.withOpacity(0.3)),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              widget.role == 'Farmer'
                                                  ? Icons.person_rounded
                                                  : Icons.badge_rounded,
                                              size: 12, color: Colors.white),
                                            const SizedBox(width: 5),
                                            Text(widget.role, style: const TextStyle(
                                              color: Colors.white, fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                          ]),
                                      ),
                                    ],
                                  ),
                                ),

                                // Avatar
                                GestureDetector(
                                  onTap: () => widget.onTabChange?.call(4),
                                  child: Container(
                                    width: 54, height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.4), width: 2),
                                    ),
                                    child: ClipOval(
                                      child: avatarImageProvider(widget.avatarUrl) != null
                                          ? Image(
                                              image: avatarImageProvider(widget.avatarUrl)!,
                                              width: 54,
                                              height: 54,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            )
                                          : const Icon(Icons.person_rounded,
                                              color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Stats row ─────────────────────────────────
                    Row(children: [
                      _StatCard(label: 'Scans Today', value: '${stats.scansToday}',
                          icon: Icons.camera_alt_rounded, color: AppColors.primary,
                          trend: '${stats.total} total'),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Diseases Found', value: '${stats.diseasedCount}',
                          icon: Icons.warning_amber_rounded, color: AppColors.confirmed,
                          trend: '${stats.uncertainCount} uncertain'),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Tree Health', value: '${stats.healthyPercent}%',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.healthy, trend: '${stats.healthyCount} healthy'),
                    ]),
                    const SizedBox(height: 24),

                    // ── Health Banner ─────────────────────────────
                    _HealthBanner(stats: stats),
                    const SizedBox(height: 24),

                    // ── Quick Actions ─────────────────────────────
                    const _SectionHeader(title: 'Quick Actions', onSeeAll: null),
                    const SizedBox(height: 14),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 115,
                      ),
                      children: [
                        _ActionCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Scan Leaf',
                          subtitle: 'Take a photo',
                          color: AppColors.primary,
                          onTap: () => widget.onTabChange?.call(1),
                        ),
                        _ActionCard(
                          icon: Icons.park_rounded,
                          label: 'Plantation',
                          subtitle: 'Map & manage trees',
                          color: AppColors.secondary,
                          onTap: () => widget.onTabChange?.call(2),
                        ),
                        _ActionCard(
                          icon: Icons.history_rounded,
                          label: 'Scan History',
                          subtitle: 'Past results',
                          color: const Color(0xFF00695C),
                          onTap: () => widget.onTabChange?.call(3),
                        ),
                        _ActionCard(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          subtitle: 'Disease trends',
                          color: const Color(0xFF4527A0),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Disease Overview ──────────────────────────
                    _SectionHeader(title: 'Disease Overview',
                        onSeeAll: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                    const SizedBox(height: 14),
                    _DiseaseOverviewCard(breakdown: stats.diseaseBreakdown),
                    const SizedBox(height: 24),

                    // ── Recent Alerts ─────────────────────────────
                    _SectionHeader(title: 'Recent Alerts',
                        onSeeAll: () => widget.onTabChange?.call(3)),
                    const SizedBox(height: 12),
                    if (stats.recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No scans yet — tap Quick Scan to get started.',
                            style: AppTextStyles.body),
                      )
                    else
                      ...stats.recent.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertCard(data: a,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PredictionResultScreen(
                              diseaseKey: a.diseaseKey,
                              confidence: a.confidenceValue,
                              status: a.status,
                              imageBase64: a.imageBase64,
                              plantationId: a.plantationId,
                              plantationName: a.plantationName,
                            ),
                          )),
                        ),
                      )),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Floating action button
      floatingActionButton: FloatingActionButton.extended(
        // MainShell keeps every tab mounted via IndexedStack, so unnamed FABs
        // on different tabs collide ("multiple heroes share the same tag")
        // the moment any navigation triggers a Hero search.
        heroTag: 'home_quick_scan_fab',
        onPressed: () => widget.onTabChange?.call(1),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Quick Scan', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 6,
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: AppTextStyles.heading3),
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: const Text('See All',
            style: TextStyle(color: AppColors.primary, fontSize: 13,
                fontWeight: FontWeight.w600)),
        ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon,
      required this.color, required this.trend});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              // Trend text length varies a lot with real data ("22 total"
              // vs "3 uncertain"). Ellipsis alone still has a non-zero
              // minimum render width and could overflow by a fraction of a
              // pixel in this very tight space — FittedBox scales the text
              // down instead, so it can never overflow regardless of length.
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.healthy.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(trend,
                        maxLines: 1,
                        style: const TextStyle(
                            color: AppColors.healthy, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

class _HealthBanner extends StatelessWidget {
  final _HomeStats stats;
  const _HealthBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final healthyFraction = stats.total == 0 ? 0.0 : stats.healthyCount / stats.total;
    final needsAttention = 100 - stats.healthyPercent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.primary,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plantation Health Report',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  stats.total == 0
                      ? 'No scans recorded yet'
                      : '${stats.total} scan${stats.total == 1 ? '' : 's'} recorded',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: healthyFraction,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${stats.healthyPercent}% healthy — $needsAttention% need attention',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${stats.healthyPercent}%', style: const TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
            Text('Healthy', style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class _DiseaseOverviewCard extends StatelessWidget {
  final List<_DiseaseRow> breakdown;
  const _DiseaseOverviewCard({required this.breakdown});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: AppDecorations.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Disease Distribution',
                style: AppTextStyles.heading3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('All Time',
                  style: TextStyle(color: AppColors.primary,
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (breakdown.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No confirmed or uncertain cases yet.', style: AppTextStyles.body),
          )
        else
          ...breakdown.map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(
                        color: d.color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(d.label, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                  ]),
                  Text('${(d.value * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: d.color)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: d.value,
                  minHeight: 7,
                  backgroundColor: d.color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(d.color),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}

class _DiseaseRow {
  final String label;
  final double value;
  final Color color;
  const _DiseaseRow(this.label, this.value, this.color);
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    ),
  );
}

class _AlertData {
  final String disease, tree, confidence, status, time;
  final Color statusColor;
  final IconData icon;

  // Carried through so tapping a Recent Alert can reopen the real saved
  // result via PredictionResultScreen instead of doing nothing.
  final String diseaseKey;
  final double confidenceValue;
  final String? imageBase64;
  final String? plantationId;
  final String? plantationName;

  const _AlertData(this.disease, this.tree, this.confidence,
      this.status, this.time, this.statusColor, this.icon, {
    required this.diseaseKey,
    required this.confidenceValue,
    this.imageBase64,
    this.plantationId,
    this.plantationName,
  });
}

class _AlertCard extends StatelessWidget {
  final _AlertData data;
  final VoidCallback onTap;
  const _AlertCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: data.statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.disease, style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('${data.tree}  ·  ${data.time}', style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: data.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(data.status, style: TextStyle(
                  color: data.statusColor, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 4),
              Text(data.confidence, style: TextStyle(
                color: data.statusColor, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Derives every Home-page number from the real scan list (ScanHistoryProvider)
/// instead of the hardcoded demo values this screen used to show — "Scans
/// Today", disease distribution, and Recent Alerts are all computed here.
class _HomeStats {
  final int total;
  final int scansToday;
  final int healthyCount;
  final int diseasedCount;
  final int uncertainCount;
  final int healthyPercent;
  final List<_DiseaseRow> diseaseBreakdown;
  final List<_AlertData> recent;

  const _HomeStats({
    required this.total,
    required this.scansToday,
    required this.healthyCount,
    required this.diseasedCount,
    required this.uncertainCount,
    required this.healthyPercent,
    required this.diseaseBreakdown,
    required this.recent,
  });

  static const _diseaseColors = [
    AppColors.confirmed, AppColors.uncertain, Color(0xFF7B1FA2), AppColors.secondary,
  ];

  static _HomeStats from(List<dynamic> scans) {
    if (scans.isEmpty) {
      return const _HomeStats(total: 0, scansToday: 0, healthyCount: 0, diseasedCount: 0,
          uncertainCount: 0, healthyPercent: 0, diseaseBreakdown: [], recent: []);
    }

    final now = DateTime.now();
    var scansToday = 0, healthyCount = 0, diseasedCount = 0, uncertainCount = 0;
    final diseaseCounts = <String, int>{};

    for (final s in scans) {
      final status = s['status'] as String? ?? 'UNCERTAIN';
      final ms = s['timestampMs'] as int?;
      if (ms != null) {
        final d = DateTime.fromMillisecondsSinceEpoch(ms);
        if (d.year == now.year && d.month == now.month && d.day == now.day) scansToday++;
      }
      if (status == 'HEALTHY') {
        healthyCount++;
      } else {
        if (status == 'CONFIRMED') diseasedCount++;
        if (status == 'UNCERTAIN') uncertainCount++;
        final name = s['disease'] as String? ?? 'Unknown';
        diseaseCounts[name] = (diseaseCounts[name] ?? 0) + 1;
      }
    }

    final diseasedTotal = diseasedCount + uncertainCount;
    final sortedDiseases = diseaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final breakdown = <_DiseaseRow>[];
    for (var i = 0; i < sortedDiseases.length && i < 4; i++) {
      final e = sortedDiseases[i];
      final pct = diseasedTotal == 0 ? 0.0 : e.value / diseasedTotal;
      breakdown.add(_DiseaseRow(e.key, pct, _diseaseColors[i % _diseaseColors.length]));
    }

    final recent = scans.take(4).map((dynamic s) {
      final status = s['status'] as String? ?? 'UNCERTAIN';
      final color = status == 'HEALTHY'
          ? AppColors.healthy
          : (status == 'CONFIRMED' ? AppColors.confirmed : AppColors.uncertain);
      final icon = status == 'HEALTHY'
          ? Icons.check_circle_outline_rounded
          : (status == 'CONFIRMED' ? Icons.warning_amber_rounded : Icons.help_outline_rounded);
      final confidence = (s['confidence'] as num? ?? 0).toDouble();
      return _AlertData(
        s['disease'] as String? ?? '',
        (s['tree'] as String?)?.isNotEmpty == true ? s['tree'] as String : 'Unlabelled scan',
        '${(confidence * 100).toInt()}%',
        status,
        s['date'] as String? ?? '',
        color,
        icon,
        diseaseKey: s['diseaseKey'] as String? ?? 'Gray_Leaf_Spot',
        confidenceValue: confidence,
        imageBase64: s['imageBase64'] as String?,
        plantationId: s['plantationId'] as String?,
        plantationName: s['plantationName'] as String?,
      );
    }).toList();

    return _HomeStats(
      total: scans.length,
      scansToday: scansToday,
      healthyCount: healthyCount,
      diseasedCount: diseasedCount,
      uncertainCount: uncertainCount,
      healthyPercent: ((healthyCount / scans.length) * 100).round(),
      diseaseBreakdown: breakdown,
      recent: recent,
    );
  }
}
