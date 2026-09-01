import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/backend_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_utils.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String role;
  final void Function(String? avatarUrl)? onProfileUpdated;
  const ProfileScreen({super.key, required this.role, this.onProfileUpdated});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn      = false;
  bool _autoSyncOn      = true;
  bool _locationOn      = true;
  String _language      = 'English';
  bool _loading         = true;
  String _name          = 'Kasun Perera';
  String _email         = 'kasun@cocoscan.lk';
  String _phone         = '+94 77 123 4567';
  String _plantation    = 'Kurunegala, Sri Lanka';
  String? _avatarUrl;
  Uint8List? _avatarBytes;
  Map<String, dynamic> _stats = {
    'totalScans': 47,
    'diseasesFound': 12,
    'healthyTrees': 35,
    'reportScore': 4.8,
  };

  @override
  void initState() {
    super.initState();
    _language = LocalizationService.getCurrentLanguage();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await BackendService.getProfile();
      if (!mounted) return;
      setState(() {
        _name = profile['name'] as String;
        _email = profile['email'] as String;
        _phone = profile['phone'] as String;
        _plantation = profile['plantation'] as String;
        _avatarUrl = profile['avatar'] as String?;
        _stats = profile['stats'] as Map<String, dynamic>;
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

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
            title: Row(children: [
              Expanded(child: Text(LocalizationService.get('myProfile'))),
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: ClipOval(
                  child: _buildAvatarImage(width: 36, height: 36),
                ),
              ),
            ]),
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
                            GestureDetector(
                              onTap: _pickAvatarImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: ClipOval(
                                      child: _buildAvatarImage(width: 90, height: 90),
                                    ),
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
                            ),
                            const SizedBox(height: 12),
                            Text(_name, style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(_email,
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
                    _StatBubble(_stats['totalScans'].toString(), 'Total Scans', AppColors.primary),
                    const SizedBox(width: 10),
                    _StatBubble(_stats['diseasesFound'].toString(), 'Diseases\nFound', AppColors.confirmed),
                    const SizedBox(width: 10),
                    _StatBubble(_stats['healthyTrees'].toString(), 'Healthy\nTrees', AppColors.healthy),
                    const SizedBox(width: 10),
                    _StatBubble(_stats['reportScore'].toString(), 'Report\nScore', const Color(0xFF4527A0)),
                  ]),
                  const SizedBox(height: 24),

                  // Account section
                  const _SectionTitle('Account'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Full Name',
                      value: _name,
                      onTap: _editProfile,
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _email,
                      onTap: _editProfile,
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _phone,
                      onTap: _editProfile,
                    ),
                    _Divider(),
                    _ProfileTile(
                      icon: Icons.location_city_rounded,
                      label: 'Plantation',
                      value: _plantation,
                      onTap: _editProfile,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Preferences
                  const _SectionTitle('Preferences'),
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
                      onChanged: (v) => setState(() {
                        _darkModeOn = v;
                        appThemeMode.value = v ? ThemeMode.dark : ThemeMode.light;
                      }),
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
                  const _SectionTitle('App'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _NavigationTile(
                      icon: Icons.language_rounded,
                      label: LocalizationService.get('language'),
                      value: _language,
                      onTap: _changeLanguage,
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.storage_rounded,
                      label: LocalizationService.get('storageUsed'),
                      value: '245 MB',
                      onTap: _showStorage,
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.info_outline_rounded,
                      label: LocalizationService.get('appVersion'),
                      value: 'v1.0.0',
                      onTap: _showAbout,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Support
                  const _SectionTitle('Support'),
                  const SizedBox(height: 10),
                  _SettingsCard(children: [
                    _NavigationTile(
                      icon: Icons.help_outline_rounded,
                      label: LocalizationService.get('help'),
                      onTap: _showHelp,
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
                      onTap: () => _showPolicy(
                        'Privacy Policy',
                        'We collect only the data needed to improve disease detection and keep it safe.',
                      ),
                    ),
                    _Divider(),
                    _NavigationTile(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () => _showPolicy(
                        'Terms of Service',
                        'By using CocoScan you agree to our terms of service for responsible and safe usage.',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(LocalizationService.get('logout')),
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
                  const Center(
                    child: Text('CocoScan v1.0.0',
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
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final plantationCtrl = TextEditingController(text: _plantation);
    var saving = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile', style: AppTextStyles.heading3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: plantationCtrl,
                      decoration: const InputDecoration(labelText: 'Plantation'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final newName = nameCtrl.text.trim();
                          final newEmail = emailCtrl.text.trim();
                          final newPhone = phoneCtrl.text.trim();
                          final newPlantation = plantationCtrl.text.trim();

                          if (newName.isEmpty || newEmail.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.lightGreen.withOpacity(0.9),
                                content: const Text(
                                  'Name and email are required.',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            await BackendService.updateProfile(
                              name: newName,
                              email: newEmail,
                              phone: newPhone,
                              plantation: newPlantation,
                            );
                            if (!mounted) return;
                            setState(() {
                              _name = newName;
                              _email = newEmail;
                              _phone = newPhone;
                              _plantation = newPlantation;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.lightGreen.withOpacity(0.9),
                                content: const Text(
                                  'Profile updated successfully.',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.lightGreen.withOpacity(0.9),
                                content: Text(
                                  'Could not save profile: $error',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
            Text(LocalizationService.get('selectLanguage'), style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ...LocalizationService.getAvailableLanguages().map((lang) => ListTile(
              title: Text(lang),
              leading: Radio<String>(
                value: lang, groupValue: _language,
                activeColor: AppColors.primary,
                onChanged: (v) async {
                  await LocalizationService.setLanguage(v!);
                  if (!mounted) return;
                  setState(() => _language = v);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to $v'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  void _showStorage() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Storage Used', style: AppTextStyles.heading3),
        content: const Text('You are using 245 MB of storage. Clear cache or old scans to free up space.',
            style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & FAQ', style: AppTextStyles.heading3),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with CocoScan?', style: AppTextStyles.body),
            SizedBox(height: 12),
            Text('- Edit your details via the profile edit button.', style: AppTextStyles.caption),
            SizedBox(height: 6),
            Text('- Use the switches to manage notifications, dark mode, and auto-sync.', style: AppTextStyles.caption),
            SizedBox(height: 6),
            Text('- Contact support if scans or login fail.', style: AppTextStyles.caption),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPolicy(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: AppTextStyles.heading3),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _pickAvatarImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (result == null || !mounted) return;
    final bytes = await result.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarUrl = null;
    });

    try {
      final uploadedUrl = await BackendService.uploadProfileAvatar(avatarBytes: bytes);
      if (!mounted) return;
      setState(() {
        _avatarUrl = uploadedUrl;
        _avatarBytes = null;
      });
      widget.onProfileUpdated?.call(uploadedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.lightGreen.withOpacity(0.9),
          content: const Text('Profile image uploaded successfully.', style: TextStyle(color: Colors.black)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.lightGreen.withOpacity(0.9),
          content: Text('Failed to upload profile image: $error', style: const TextStyle(color: Colors.black)),
        ),
      );
    }
  }

  Widget _buildAvatarImage({required double width, required double height}) {
    if (_avatarBytes != null) {
      return Image.memory(_avatarBytes!, width: width, height: height, fit: BoxFit.cover);
    }
    final provider = avatarImageProvider(_avatarUrl);
    if (provider != null) {
      return Image(image: provider, width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarPlaceholder());
    }
    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() => Container(
    alignment: Alignment.center,
    color: Colors.white24,
    child: const Icon(Icons.person_rounded, color: Colors.white, size: 50),
  );

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'CocoScan',
      applicationVersion: 'v1.0.0',
      applicationLegalese: '© 2026 CocoScan · Sri Lanka',
      children: [
        const SizedBox(height: 12),
        const Text('AI-powered coconut disease detection for Sri Lankan farmers.',
            style: AppTextStyles.body),
      ],
    );
  }

  void _sendFeedback() {
    final feedbackCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send Feedback', style: AppTextStyles.heading3),
        content: TextField(
          controller: feedbackCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe your issue or suggestion...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final feedback = feedbackCtrl.text.trim();
              if (feedback.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.lightGreen.withOpacity(0.9),
                    content: const Text(
                      'Please enter feedback before sending.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.lightGreen.withOpacity(0.9),
                  content: const Text(
                    'Thank you! Your feedback was sent.',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out', style: AppTextStyles.heading3),
        content: const Text('Are you sure you want to sign out?',
            style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.confirmed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BackendService.logout();
      } catch (error) {
        // Even if logout fails, we still want to go back to login
        debugPrint('Logout error: $error');
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
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
