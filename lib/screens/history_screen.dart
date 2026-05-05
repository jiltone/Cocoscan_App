import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import 'prediction_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'All';
  String _search = '';
  bool _loading = true;
  late TabController _tab;

  List<_ScanItem> _allScans = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadScans();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadScans() async {
    setState(() => _loading = true);
    try {
      final scans = await BackendService.getScans();
      setState(() {
        _allScans = scans.map((dynamic item) {
          return _ScanItem(
            item['disease'] as String,
            item['tree'] as String,
            (item['confidence'] as num).toDouble(),
            item['status'] as String,
            item['date'] as String,
            _statusColorFor(item['status'] as String),
            item['sector'] as String,
          );
        }).toList();
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _statusColorFor(String status) {
    if (status == 'CONFIRMED') return AppColors.confirmed;
    if (status == 'UNCERTAIN') return AppColors.uncertain;
    return AppColors.healthy;
  }

  List<_ScanItem> get _filtered {
    var list = _allScans;
    if (_filter == 'Confirmed') list = list.where((s) => s.status == 'CONFIRMED').toList();
    if (_filter == 'Uncertain') list = list.where((s) => s.status == 'UNCERTAIN').toList();
    if (_filter == 'Healthy')   list = list.where((s) => s.status == 'HEALTHY').toList();
    if (_search.isNotEmpty) {
      list = list.where((s) => s.disease.toLowerCase().contains(_search.toLowerCase())
          || s.tree.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Scan History'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'List View'),
            Tab(text: 'Timeline'),
            Tab(text: 'Map'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search scans...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 10),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Confirmed', 'Uncertain', 'Healthy'].map((f) {
                      final sel = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel ? AppColors.primary : AppColors.divider),
                            ),
                            child: Text(f, style: TextStyle(
                              color: sel ? Colors.white : AppColors.textSecondary,
                              fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Tab view
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // List view
                if (_loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ))
                else if (_filtered.isEmpty)
                  _EmptyState()
                else
                  ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ScanCard(
                      item: _filtered[i],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const PredictionResultScreen())),
                    ),
                  ),

                // Timeline
                _TimelineView(scans: _filtered),

                // Map placeholder
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.map_rounded,
                            color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('Map View', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      const Text('GPS plantation map\ncoming in next update',
                          style: AppTextStyles.body, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final _ScanItem item;
  final VoidCallback onTap;
  const _ScanCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card,
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: item.statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            item.status == 'HEALTHY'
                ? Icons.check_circle_outline_rounded
                : item.status == 'CONFIRMED'
                ? Icons.warning_amber_rounded
                : Icons.help_outline_rounded,
            color: item.statusColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(item.disease, style: AppTextStyles.heading3.copyWith(fontSize: 14)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(item.status, style: TextStyle(
                  color: item.statusColor, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 3),
            Text('${item.tree}  ·  ${item.sector}',
                style: AppTextStyles.caption),
            Text(item.date, style: AppTextStyles.caption),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${(item.confidence * 100).toInt()}%', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: item.statusColor)),
          const SizedBox(height: 4),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppColors.textSecondary),
        ]),
      ]),
    ),
  );
}

class _TimelineView extends StatelessWidget {
  final List<_ScanItem> scans;
  const _TimelineView({required this.scans});

  @override
  Widget build(BuildContext context) => ListView.builder(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(16),
    itemCount: scans.length,
    itemBuilder: (_, i) {
      final s = scans[i];
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: s.statusColor, shape: BoxShape.circle),
                child: Icon(
                  s.status == 'HEALTHY'
                      ? Icons.check_rounded
                      : s.status == 'CONFIRMED'
                      ? Icons.warning_rounded
                      : Icons.help_rounded,
                  color: Colors.white, size: 18),
              ),
              if (i < scans.length - 1)
                Expanded(child: Container(
                  width: 2, color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(vertical: 4))),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: i < scans.length - 1 ? 16 : 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppDecorations.card,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.disease,
                        style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${s.tree}  ·  ${s.sector}',
                        style: AppTextStyles.caption),
                    Text(s.date, style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Text('Confidence: ', style: AppTextStyles.caption),
                      Text('${(s.confidence * 100).toInt()}%', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: s.statusColor)),
                    ]),
                  ]),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history_rounded, size: 64, color: AppColors.divider),
      SizedBox(height: 16),
      Text('No scans found', style: AppTextStyles.heading3),
      SizedBox(height: 8),
      Text('Try adjusting your filters',
          style: AppTextStyles.body, textAlign: TextAlign.center),
    ]),
  );
}

class _ScanItem {
  final String disease, tree, status, date, sector;
  final double confidence;
  final Color statusColor;
  const _ScanItem(this.disease, this.tree, this.confidence, this.status,
      this.date, this.statusColor, this.sector);
}
