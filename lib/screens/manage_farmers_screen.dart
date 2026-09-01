import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plantation.dart';
import '../providers/plantation_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

/// Officer-only screen: assign/remove farmers on a plantation. Only the
/// officer who created the plantation can reach this (see the AppBar action
/// gate in plantation_detail_screen.dart).
class ManageFarmersScreen extends StatefulWidget {
  final String plantationId;
  const ManageFarmersScreen({super.key, required this.plantationId});

  @override
  State<ManageFarmersScreen> createState() => _ManageFarmersScreenState();
}

class _ManageFarmersScreenState extends State<ManageFarmersScreen> {
  List<Map<String, dynamic>>? _allFarmers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    try {
      final farmers = await FirebaseService.getFarmers();
      if (!mounted) return;
      setState(() => _allFarmers = farmers);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load farmers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantation = context.watch<PlantationProvider>().byId(widget.plantationId);
    if (plantation == null) {
      return const Scaffold(body: Center(child: Text('Plantation not found')));
    }
    final memberUids = plantation.members.map((m) => m.uid).toSet();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Farmers · ${plantation.name}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : _allFarmers == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Assigned (${plantation.members.length})', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    if (plantation.members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No farmers assigned yet.', style: AppTextStyles.body),
                      )
                    else
                      ...plantation.members.map((m) => _farmerTile(
                            m.name.isNotEmpty ? m.name : m.email,
                            m.email,
                            assigned: true,
                            onToggle: () => context
                                .read<PlantationProvider>()
                                .removeFarmer(widget.plantationId, m.uid),
                          )),
                    const SizedBox(height: 24),
                    Text('All Farmers', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    if (_allFarmers!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No registered farmer accounts yet.', style: AppTextStyles.body),
                      )
                    else
                      ..._allFarmers!.where((f) => !memberUids.contains(f['uid'])).map((f) => _farmerTile(
                            (f['name'] as String).isNotEmpty ? f['name'] as String : f['email'] as String,
                            f['email'] as String,
                            assigned: false,
                            onToggle: () => context.read<PlantationProvider>().addFarmer(
                                  widget.plantationId,
                                  PlantationMember(
                                    uid: f['uid'] as String,
                                    name: f['name'] as String,
                                    email: f['email'] as String,
                                  ),
                                ),
                          )),
                  ],
                ),
    );
  }

  Widget _farmerTile(String name, String email, {required bool assigned, required VoidCallback onToggle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.heading3.copyWith(fontSize: 14)),
                Text(email, style: AppTextStyles.caption),
              ],
            ),
          ),
          assigned
              ? OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.confirmed,
                    side: const BorderSide(color: AppColors.confirmed),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onToggle,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}
