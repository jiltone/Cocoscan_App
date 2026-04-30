import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, required this.role});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn      = false;
  bool _autoSyncOn      = true;
  bool _locationOn      = true;
  String _language      = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: _editProfile,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Stack(
                  children: [
                    Positioned(top: -30, right: -30,
                      child: Container(width: 160, height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)))),
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 90, height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: Colors.white, size: 50),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2)),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Kasun Perera', style: TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('kasun@cocoscan.lk',
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3))),
                              child: Text(widget.role, style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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

          // ── Body ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Stats row
                  Row(children: [
                    _StatBubble('47', 'Total Scans', AppColors.primary),
                    const SizedBox(width: 10),
                    _StatBubble('12', 'Diseases\nFound', AppColors.confirmed),
                    const SizedBox(width: 10),
                    _StatBubble('35', 'Healthy\nTrees', AppColors.healthy),
                    const SizedBox(width: 10),
                    _StatBubble('4.8', 'Report\nScore', const Color(0xFF4527A0)),
                  ]),
                  const SizedBox(height: 24),

                  // Account section
                  _SectionTitle('Account'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Full Name',
                      value: 'Kasun Perera',
                      onTap: _editProfile,
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'kasun@cocoscan.lk',
                      onTap: _editProfile,
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: '+94 77 123 4567',
                      onTap: _editProfile,
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.location_city_rounded,
                      label: 'Plantation',
                      value: 'Kurunegala, Sri Lanka',
                      onTap: _editProfile,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Preferences
                  _SectionTitle('Preferences'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _SwitchTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      value: _notificationsOn,
                      color: AppColors.primary,
                      onChanged: (v) => setState(() => _notificationsOn = v),
                    ),
                    _Divider(),
                    _SwitchTile(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      value: _darkModeOn,
                      color: const Color(0xFF4527A0),
                      onChanged: (v) => setState(() => _darkModeOn = v),
                    ),
                    _Divider(),
                    _SwitchTile(
                      icon: Icons.sync_rounded,
                      label: 'Auto-sync Data',
                      value: _autoSyncOn,
                      color: AppColors.secondary,
                      onChanged: (v) => setState(() => _autoSyncOn = v),
                    ),
                    _Divider(),
                    _SwitchTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location Tracking',
                      value: _locationOn,
                      color: AppColors.confirmed,
                      onChanged: (v) => setState(() => _locationOn = v),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // App settings
                  _SectionTitle('App'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _NavigationTile(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      value: _language,
                      onTap: _changeLanguage,
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.storage_rounded,
                      label: 'Storage Used',
                      value: '245 MB',
                      onTap: () {},
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.info_outline_rounded,
                      label: 'App Version',
                      value: 'v2.0.0',
                      onTap: _showAbout,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Support
                  _SectionTitle('Support'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _NavigationTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & FAQ',
                      onTap: () {},
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.feedback_outlined,
                      label: 'Send Feedback',
                      onTap: _sendFeedback,
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () {},
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.confirmed,
                        side: const BorderSide(color: AppColors.confirmed),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('CocoScan v2.0.0 · Made with ❤️ in Sri Lanka',
                        style: AppTextStyles.caption),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile coming soon!')));
  }

  void _changeLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Language', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ...['English', 'Sinhala', 'Tamil'].map((lang) => ListTile(
              title: Text(lang),
              leading: Radio<String>(
                value: lang, groupValue: _language,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() => _language = v!);
                  Navigator.pop(context);
                },
              ),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'CocoScan',
      applicationVersion: 'v2.0.0',
      applicationLegalese: '© 2026 CocoScan · Sri Lanka',
      children: [
        const SizedBox(height: 12),
        const Text('AI-powered coconut disease detection for Sri Lankan farmers.',
            style: AppTextStyles.body),
      ],
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback form opening...')));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out', style: AppTextStyles.heading3),
        content: const Text('Are you sure you want to sign out?',
            style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.confirmed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary, letterSpacing: 1.2));
}

class _StatBubble extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBubble(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card,
      child: Column(children: [
        Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: AppDecorations.card,
    child: Column(children: children),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 0, indent: 56);
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.label,
      this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primary, size: 18),
    ),
    title: Text(label, style: AppTextStyles.caption),
    subtitle: value != null ? Text(value!, style: const TextStyle(
        fontSize: 14, color: AppColors.textPrimary,
        fontWeight: FontWeight.w600)) : null,
    trailing: const Icon(Icons.arrow_forward_ios_rounded,
        size: 14, color: AppColors.textSecondary),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.label,
      required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    ),
    title: Text(label, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    trailing: Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: color,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _NavigationTile({required this.icon, required this.label,
      this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primary, size: 18),
    ),
    title: Text(label, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      if (value != null) ...[
        Text(value!, style: AppTextStyles.caption),
        const SizedBox(width: 6),
      ],
      const Icon(Icons.arrow_forward_ios_rounded,
          size: 13, color: AppColors.textSecondary),
    ]),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
