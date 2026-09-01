import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/plantation.dart';
import '../providers/plantation_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'plantation_boundary_screen.dart';
import 'plantation_detail_screen.dart';

/// Plantation Mapper list screen (report Section 4.2.4, Figure 4.5).
/// Only an Agricultural Officer can register a plantation and mark its
/// boundary; farmers see (read-only) the plantations an officer has
/// assigned them to.
class PlantationMapperScreen extends StatefulWidget {
  final String role;
  const PlantationMapperScreen({super.key, required this.role});
  @override
  State<PlantationMapperScreen> createState() => _PlantationMapperScreenState();
}

class _PlantationMapperScreenState extends State<PlantationMapperScreen> {
  bool get _isOfficer => widget.role == 'Agricultural Officer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = await FirebaseService.getCurrentUserId();
      if (uid == null || !mounted) return;
      context.read<PlantationProvider>().load(uid: uid, role: widget.role);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantationProvider>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Plantation Mapper'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: !provider.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : provider.plantations.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.plantations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _plantationCard(context, provider.plantations[index]),
                ),
      floatingActionButton: _isOfficer
          ? FloatingActionButton.extended(
              heroTag: 'plantation_add_fab',
              onPressed: () => _startAddPlantationFlow(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
              label: const Text('Add Plantation', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.park_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _isOfficer ? 'No plantations registered yet' : 'No plantations assigned yet',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 6),
            Text(
              _isOfficer
                  ? 'Tap "Add Plantation" to register one and mark its boundary.'
                  : 'Your Agricultural Officer hasn\'t assigned you to a plantation yet.',
              textAlign: TextAlign.center, style: AppTextStyles.body,
            ),
          ]),
        ),
      );

  Widget _plantationCard(BuildContext context, Plantation plantation) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlantationDetailScreen(plantationId: plantation.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card,
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plantation.name, style: AppTextStyles.heading3),
                  const SizedBox(height: 2),
                  Text(
                    '${plantation.boundaryPoints.length}-point boundary · '
                    '${DateFormat('d MMM yyyy').format(plantation.createdAt)}',
                    style: AppTextStyles.caption,
                  ),
                  if (!_isOfficer && plantation.officerName.isNotEmpty)
                    Text('Officer: ${plantation.officerName}', style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _startAddPlantationFlow(BuildContext context) async {
    final name = await _promptForName(context);
    if (name == null || name.isEmpty || !context.mounted) return;

    final boundary = await Navigator.push<List<BoundaryPoint>>(
      context,
      MaterialPageRoute(builder: (_) => const PlantationBoundaryScreen()),
    );
    if (boundary == null || !context.mounted) return; // cancelled before saving

    try {
      final profile = await FirebaseService.getProfile();
      final plantation = await context.read<PlantationProvider>().createPlantation(
            officerId: profile['id'] as String,
            officerName: profile['name'] as String? ?? '',
            name: name,
            boundary: boundary,
          );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlantationDetailScreen(plantationId: plantation.id)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create plantation: $e')),
      );
    }
  }

  Future<String?> _promptForName(BuildContext context) {
    final nameController = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Register Plantation', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            const Text(
              'Give this plantation a name, then mark its boundary on the map.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Waligama',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(sheetContext, nameController.text.trim()),
                child: const Text('Next: Mark Boundary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
