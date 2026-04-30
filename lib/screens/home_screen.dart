import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import 'drone_report_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  final void Function(int)? onTabChange;
  const HomeScreen({super.key, required this.role, this.onTabChange});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Recent alerts mock data
  final List<_AlertData> _alerts = [
    _AlertData('Leaf Spot', 'Tree #A-14', '92%', 'CONFIRMED',
        '2 hours ago', AppColors.confirmed, Icons.warning_amber_rounded),
    _AlertData('Lethal Yellowing', 'Tree #B-07', '71%', 'UNCERTAIN',
        '5 hours ago', AppColors.uncertain, Icons.help_outline_rounded),
    _AlertData('Healthy', 'Tree #C-22', '96%', 'HEALTHY',
        'Yesterday', AppColors.healthy, Icons.check_circle_outline_rounded),
    _AlertData('Bud Rot', 'Tree #D-03', '88%', 'CONFIRMED',
        '2 days ago', AppColors.confirmed, Icons.warning_amber_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
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
                                      const Text('Kasun Perera', style: TextStyle(
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
                                    child: const Icon(Icons.person_rounded,
                                        color: Colors.white, size: 30),
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
                      _StatCard(label: 'Scans Today', value: '12',
                          icon: Icons.camera_alt_rounded, color: AppColors.primary,
                          trend: '+3'),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Diseases Found', value: '3',
                          icon: Icons.warning_amber_rounded, color: AppColors.confirmed,
                          trend: '+1'),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Tree Health', value: '87%',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.healthy, trend: '+2%'),
                    ]),
                    const SizedBox(height: 24),

                    // ── Health Banner ─────────────────────────────
                    _HealthBanner(),
                    const SizedBox(height: 24),

                    // ── Quick Actions ─────────────────────────────
                    _SectionHeader(title: 'Quick Actions', onSeeAll: null),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ActionCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'Scan Leaf',
                          subtitle: 'Take a photo',
                          color: AppColors.primary,
                          onTap: () => widget.onTabChange?.call(1),
                        ),
                        _ActionCard(
                          icon: Icons.airplanemode_active_rounded,
                          label: 'Drone Report',
                          subtitle: 'Upload footage',
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
                    _DiseaseOverviewCard(),
                    const SizedBox(height: 24),

                    // ── Recent Alerts ─────────────────────────────
                    _SectionHeader(title: 'Recent Alerts',
                        onSeeAll: () => widget.onTabChange?.call(3)),
                    const SizedBox(height: 12),
                    ..._alerts.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AlertCard(data: a,
                        onTap: () {},
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
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.healthy.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(trend, style: const TextStyle(
                    color: AppColors.healthy, fontSize: 9, fontWeight: FontWeight.w700)),
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
  @override
  Widget build(BuildContext context) => Container(
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
              Text('Plantation Health Report',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text('245 trees monitored this week',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.87,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              Text('87% healthy — 13% need attention',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('87%', style: TextStyle(
            color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
          Text('Healthy', style: TextStyle(
              color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ]),
      ],
    ),
  );
}

class _DiseaseOverviewCard extends StatelessWidget {
  final _diseases = const [
    _DiseaseRow('Leaf Spot', 0.42, AppColors.confirmed),
    _DiseaseRow('Lethal Yellowing', 0.28, AppColors.uncertain),
    _DiseaseRow('Bud Rot', 0.18, Color(0xFF7B1FA2)),
    _DiseaseRow('Stem Bleeding', 0.12, AppColors.secondary),
  ];

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
              child: const Text('This Month',
                  style: TextStyle(color: AppColors.primary,
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._diseases.map((d) => Padding(
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
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
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
  const _AlertData(this.disease, this.tree, this.confidence,
      this.status, this.time, this.statusColor, this.icon);
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
