import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'camera_screen.dart';
import 'drone_report_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../services/firebase_service.dart';

class MainShell extends StatefulWidget {
  final String role;
  const MainShell({super.key, this.role = 'Farmer'});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final profile = await FirebaseService.getProfile();
      if (mounted) setState(() => _userName = profile['name'] ?? '');
    } catch (_) {}
  }

  List<Widget> get _pages => [
    HomeScreen(role: widget.role, userName: _userName, onTabChange: _changeTab),
    CameraScreen(onBack: () => _changeTab(0)),
    const DroneReportScreen(),
    const HistoryScreen(),
    ProfileScreen(role: widget.role),
  ];

  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt_rounded),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.airplanemode_active_outlined),
                selectedIcon: Icon(Icons.airplanemode_active_rounded),
                label: 'Drone',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
