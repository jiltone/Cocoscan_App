import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  final List<_OnboardPage> _pages = [
    const _OnboardPage(
      icon: Icons.eco_rounded,
      title: 'Early Disease\nDetection',
      subtitle: 'Detect coconut leaf diseases early using advanced AI — before they spread and damage your harvest.',
      gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      bgColor: Color(0xFF1B5E20),
    ),
    const _OnboardPage(
      icon: Icons.airplanemode_active_rounded,
      title: 'Drone\nInspection',
      subtitle: 'Fly a drone over your plantation and let the system automatically analyse every tree from above.',
      gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      bgColor: Color(0xFF1565C0),
    ),
    const _OnboardPage(
      icon: Icons.psychology_rounded,
      title: 'Explainable\nAI (XAI)',
      subtitle: 'See exactly which part of the leaf triggered the diagnosis — fully transparent, fully trustworthy.',
      gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00BFA5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      bgColor: Color(0xFF00695C),
    ),
    const _OnboardPage(
      icon: Icons.healing_rounded,
      title: 'Smart Treatment\nGuide',
      subtitle: 'Get instant, disease-specific treatment recommendations your farmers can act on immediately.',
      gradient: LinearGradient(
          colors: [Color(0xFF4527A0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      bgColor: Color(0xFF4527A0),
    ),
    const _OnboardPage(
      icon: Icons.bar_chart_rounded,
      title: 'Analytics &\nInsights',
      subtitle: 'Track disease trends, monitor plantation health, and export detailed PDF reports for your records.',
      gradient: LinearGradient(
          colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      bgColor: Color(0xFFBF360C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: page.bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page count
                    Text(
                      '${_currentPage + 1}/${_pages.length}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    // Skip
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text('Skip',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ],
                ),
              ),

              // Main page content
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, i) => _buildPage(_pages[i], i == _currentPage),
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    const SizedBox(height: 32),

                    // Action button row
                    Row(
                      children: [
                        if (_currentPage > 0) ...[
                          GestureDetector(
                            onTap: () => _controller.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut),
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: GestureDetector(
                            onTap: _currentPage < _pages.length - 1
                                ? () => _controller.nextPage(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOut)
                                : _goToLogin,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 16, offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                                  style: TextStyle(
                                    color: page.bgColor,
                                    fontSize: 16, fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardPage page, bool active) {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (_, child) => Opacity(
        opacity: active ? _fadeAnim.value : 1.0,
        child: Transform.translate(
          offset: Offset(0, active ? _slideAnim.value : 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 112, height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(page.icon, size: 60, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Title
            Text(
              page.title,
              style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -1.0, height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Subtitle
            Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.78),
                height: 1.65,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}

class _OnboardPage {
  final IconData icon;
  final String title, subtitle;
  final LinearGradient gradient;
  final Color bgColor;
  const _OnboardPage({
    required this.icon, required this.title, required this.subtitle,
    required this.gradient, required this.bgColor,
  });
}
