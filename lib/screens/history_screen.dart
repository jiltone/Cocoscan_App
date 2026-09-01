import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_history_provider.dart';
import '../theme/app_theme.dart';
import 'prediction_result_screen.dart';

IconData _statusIcon(String status) => status == 'HEALTHY'
    ? Icons.check_circle_outline_rounded
    : status == 'CONFIRMED'
        ? Icons.warning_amber_rounded
        : Icons.help_outline_rounded;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'All';
  String _search = '';
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    // MainShell keeps every tab mounted via IndexedStack, so this only runs
    // once at app startup — ScanHistoryProvider.prepend() (called by
    // PredictionResultScreen's Save to History button) is what keeps this
    // screen in sync afterwards, not another initState() call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanHistoryProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Color _statusColorFor(String status) {
    if (status == 'CONFIRMED') return AppColors.confirmed;
    if (status == 'UNCERTAIN') return AppColors.uncertain;
    return AppColors.healthy;
  }

  List<_ScanItem> _filteredFrom(List<dynamic> allScans) {
    var list = allScans.map((dynamic item) {
      return _ScanItem(
        diseaseKey: item['diseaseKey'] as String? ?? 'Gray_Leaf_Spot',
        disease: item['disease'] as String,
        tree: item['tree'] as String,
        confidence: (item['confidence'] as num).toDouble(),
        status: item['status'] as String,
        date: item['date'] as String,
        statusColor: _statusColorFor(item['status'] as String),
        sector: item['sector'] as String,
        imageBase64: item['imageBase64'] as String?,
        probabilities: (item['probabilities'] as Map?)?.cast<String, double>(),
        plantationId: item['plantationId'] as String?,
        plantationName: item['plantationName'] as String?,
      );
    }).toList();
    if (_filter == 'Confirmed') list = list.where((s) => s.status == 'CONFIRMED').toList();
    if (_filter == 'Uncertain') list = list.where((s) => s.status == 'UNCERTAIN').toList();
    if (_filter == 'Healthy')   list = list.where((s) => s.status == 'HEALTHY').toList();
    if (_filter == 'Plantation') list = list.where((s) => s.plantationId != null).toList();
    if (_search.isNotEmpty) {
      list = list.where((s) => s.disease.toLowerCase().contains(_search.toLowerCase())
          || s.tree.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  void _openScan(BuildContext context, _ScanItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionResultScreen(
          diseaseKey: item.diseaseKey,
          confidence: item.confidence,
          status: item.status,
          probabilities: item.probabilities,
          imageBase64: item.imageBase64,
          plantationId: item.plantationId,
          plantationName: item.plantationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<ScanHistoryProvider>();
    final loading = historyProvider.isLoading && !historyProvider.isLoaded;
    final filtered = _filteredFrom(historyProvider.scans);

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
                    children: ['All', 'Confirmed', 'Uncertain', 'Healthy', 'Plantation'].map((f) {
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
                if (loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ))
                else if (filtered.isEmpty)
                  RefreshIndicator(
                    onRefresh: () => context.read<ScanHistoryProvider>().refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_EmptyState()],
                    ),
                  )
                else
                  RefreshIndicator(
                    onRefresh: () => context.read<ScanHistoryProvider>().refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ScanCard(
                        item: filtered[i],
                        onTap: () => _openScan(context, filtered[i]),
                      ),
                    ),
                  ),

                // Timeline
                _TimelineView(scans: filtered),

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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: item.statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: item.imageBase64 != null
              ? Image.memory(base64Decode(item.imageBase64!), fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(_statusIcon(item.status), color: item.statusColor, size: 24))
              : Icon(_statusIcon(item.status), color: item.statusColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(item.disease, style: AppTextStyles.heading3.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
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
            if (item.isPlantation) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.park_rounded, size: 10, color: AppColors.secondary),
                  const SizedBox(width: 3),
                  Text(item.plantationName ?? 'Plantation', style: const TextStyle(
                      color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
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
                    if (s.isPlantation) ...[
                      const SizedBox(height: 6),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.park_rounded, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(s.plantationName ?? 'Plantation', style: const TextStyle(
                            color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ],
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
  final String diseaseKey, disease, tree, status, date, sector;
  final double confidence;
  final Color statusColor;
  final String? imageBase64;
  final Map<String, double>? probabilities;
  final String? plantationId;
  final String? plantationName;
  const _ScanItem({
    required this.diseaseKey,
    required this.disease,
    required this.tree,
    required this.confidence,
    required this.status,
    required this.date,
    required this.statusColor,
    required this.sector,
    this.imageBase64,
    this.probabilities,
    this.plantationId,
    this.plantationName,
  });

  bool get isPlantation => plantationId != null;
}
