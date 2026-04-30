import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'prediction_result_screen.dart';

class DroneReportScreen extends StatefulWidget {
  const DroneReportScreen({super.key});
  @override
  State<DroneReportScreen> createState() => _DroneReportScreenState();
}

class _DroneReportScreenState extends State<DroneReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _processing = false;

  final _trees = [
    _TreeData('A-01', 'Healthy',         'HEALTHY',      96, const Color(0xFF2E7D32)),
    _TreeData('A-02', 'Leaf Spot',        'CONFIRMED',    92, const Color(0xFFD32F2F)),
    _TreeData('A-03', 'Lethal Yellowing', 'CONFIRMED',    88, const Color(0xFFD32F2F)),
    _TreeData('A-04', 'Healthy',          'HEALTHY',      94, const Color(0xFF2E7D32)),
    _TreeData('A-05', 'Bud Rot',          'UNCERTAIN',    74, const Color(0xFFF57C00)),
    _TreeData('A-06', 'Healthy',          'HEALTHY',      97, const Color(0xFF2E7D32)),
    _TreeData('A-07', 'Leaf Spot',        'CONFIRMED',    89, const Color(0xFFD32F2F)),
    _TreeData('A-08', 'Healthy',          'HEALTHY',      91, const Color(0xFF2E7D32)),
    _TreeData('A-09', 'Stem Bleeding',    'UNCERTAIN',    68, const Color(0xFFF57C00)),
    _TreeData('A-10', 'Healthy',          'HEALTHY',      95, const Color(0xFF2E7D32)),
    _TreeData('A-11', 'Healthy',          'HEALTHY',      98, const Color(0xFF2E7D32)),
    _TreeData('A-12', 'Leaf Spot',        'CONFIRMED',    91, const Color(0xFFD32F2F)),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmed  = _trees.where((t) => t.status == 'CONFIRMED').length;
    final uncertain  = _trees.where((t) => t.status == 'UNCERTAIN').length;
    final healthy    = _trees.where((t) => t.status == 'HEALTHY').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Drone Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Map View'),
            Tab(text: 'Tree List'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Upload bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('plantation_flight_01.mp4', style: AppTextStyles.body.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _processing ? null : _processVideo,
                  icon: _processing
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(_processing ? 'Analysing...' : 'Analyse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Tab 1 — Map view
                _buildMapView(),

                // Tab 2 — Tree list
                _buildTreeList(),

                // Tab 3 — Summary
                _buildSummary(confirmed, uncertain, healthy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    // Grid representing the plantation
    final cols = 4;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plantation Map — Kurunegala Block A', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text('12 trees scanned  ·  Tap a tree for details', style: AppTextStyles.body),
          const SizedBox(height: 14),

          // Legend
          Row(
            children: [
              _MapLegend(color: const Color(0xFF2E7D32), label: 'Healthy'),
              const SizedBox(width: 12),
              _MapLegend(color: const Color(0xFFD32F2F), label: 'Diseased'),
              const SizedBox(width: 12),
              _MapLegend(color: const Color(0xFFF57C00), label: 'Uncertain'),
            ],
          ),
          const SizedBox(height: 16),

          // Tree grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _trees.length,
              itemBuilder: (_, i) {
                final t = _trees[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PredictionResultScreen())),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.color.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.park_rounded, color: t.color, size: 28),
                        const SizedBox(height: 4),
                        Text(t.id, style: TextStyle(
                          color: t.color, fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('${t.confidence}%', style: TextStyle(
                          color: t.color, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _trees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = _trees[i];
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PredictionResultScreen())),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.card,
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.park_rounded, color: t.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tree #${t.id}', style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                      Text(t.disease, style: AppTextStyles.body),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.status, style: TextStyle(
                        color: t.color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text('${t.confidence}%', style: TextStyle(
                      color: t.color, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(int confirmed, int uncertain, int healthy) {
    final total = _trees.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(children: [
            _SummaryCard(label: 'Total Trees', value: '$total', icon: Icons.park_rounded,
                color: AppColors.primary),
            const SizedBox(width: 10),
            _SummaryCard(label: 'Diseased', value: '$confirmed', icon: Icons.warning_rounded,
                color: const Color(0xFFD32F2F)),
            const SizedBox(width: 10),
            _SummaryCard(label: 'Healthy', value: '$healthy', icon: Icons.check_circle_rounded,
                color: const Color(0xFF2E7D32)),
          ]),
          const SizedBox(height: 20),

          // Disease breakdown
          Text('Disease Breakdown', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          _DiseaseRow(disease: 'Leaf Spot',         count: 3, total: total, color: const Color(0xFFD32F2F)),
          const SizedBox(height: 8),
          _DiseaseRow(disease: 'Lethal Yellowing',  count: 1, total: total, color: const Color(0xFFE65100)),
          const SizedBox(height: 8),
          _DiseaseRow(disease: 'Stem Bleeding',     count: 1, total: total, color: const Color(0xFFF57C00)),
          const SizedBox(height: 8),
          _DiseaseRow(disease: 'Healthy',           count: healthy, total: total, color: const Color(0xFF2E7D32)),
          const SizedBox(height: 24),

          // Urgent action
          Text('Urgent Actions Required', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _UrgentRow(tree: 'Tree A-03', action: 'Lethal Yellowing — Remove immediately'),
                const Divider(height: 16),
                _UrgentRow(tree: 'Tree A-02', action: 'Leaf Spot — Apply fungicide within 24hrs'),
                const Divider(height: 16),
                _UrgentRow(tree: 'Tree A-07', action: 'Leaf Spot — Apply fungicide within 24hrs'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Download Full PDF Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processVideo() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _processing = false);
  }
}

class _TreeData {
  final String id, disease, status;
  final int confidence;
  final Color color;
  const _TreeData(this.id, this.disease, this.status, this.confidence, this.color);
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _DiseaseRow extends StatelessWidget {
  final String disease;
  final int count, total;
  final Color color;
  const _DiseaseRow({required this.disease, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = count / total;
    return Row(children: [
      SizedBox(width: 130, child: Text(disease, style: AppTextStyles.body.copyWith(fontSize: 13))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct, minHeight: 8,
          backgroundColor: AppColors.divider,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      )),
      const SizedBox(width: 8),
      Text('$count', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
    ]);
  }
}

class _UrgentRow extends StatelessWidget {
  final String tree, action;
  const _UrgentRow({required this.tree, required this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.warning_rounded, color: Color(0xFFD32F2F), size: 16),
    const SizedBox(width: 8),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tree, style: AppTextStyles.heading3.copyWith(fontSize: 13, color: const Color(0xFFD32F2F))),
        Text(action, style: AppTextStyles.body.copyWith(fontSize: 12)),
      ],
    )),
  ]);
}
