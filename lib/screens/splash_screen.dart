import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.7, curve: Curves.easeOut)));
    _slideY = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  void _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            seen ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Background circles
            Positioned(
              top: -80, right: -60,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100, left: -80,
              child: Container(
                width: 340, height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 200, left: -40,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Center content
            Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30, offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.eco_rounded, size: 58, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App name
                    Opacity(
                      opacity: _fade.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideY.value),
                        child: Column(
                          children: [
                            const Text(
                              'CocoScan',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Coconut Disease Detection System',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.75),
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom loader
            Positioned(
              bottom: 60,
              left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Opacity(
                  opacity: _fade.value,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.7),
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Powered by AI',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
