import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;
  bool _loading    = false;
  String _role     = 'Farmer';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: Stack(
                children: [
                  // Background deco circles
                  Positioned(top: -40, right: -30,
                    child: Container(width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06)))),
                  Positioned(bottom: -20, left: -50,
                    child: Container(width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04)))),

                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.eco_rounded, size: 44, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          const Text('CocoScan', 
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 45, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Coconut Disease Detection System',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75),
                                letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Form ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome Back', style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      const Text('Sign in to your CocoScan account',
                          style: AppTextStyles.body),
                      const SizedBox(height: 28),

                      // ── Role selector ──────────────────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: AppDecorations.gradientCard,
                        child: Row(
                          children: ['Farmer', 'Agricultural Officer'].map((role) {
                            final selected = _role == role;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _role = role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    gradient: selected ? AppColors.primaryGradient : null,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selected ? AppShadows.primary : null,
                                  ),
                                  child: Text(role,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700, fontSize: 12.5,
                                    )),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Email ──────────────────────────────────
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'farmer@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v != null && v.contains('@')
                            ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),

                      // ── Password ───────────────────────────────
                      _buildField(
                        controller: _passCtrl,
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        validator: (v) => v != null && v.length >= 6
                            ? null : 'Minimum 6 characters',
                        suffix: IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot Password?',
                              style: TextStyle(color: AppColors.secondary, fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Sign-in button ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.primary,
                          ),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : Text('Sign In as $_role',
                                    style: AppTextStyles.button.copyWith(
                                        color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Divider ────────────────────────────────
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('or', style: AppTextStyles.caption),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 20),

                      // ── Demo accounts ──────────────────────────
                      Row(children: [
                        Expanded(child: _QuickLoginBtn(
                          label: 'Demo Farmer',
                          icon: Icons.person_rounded,
                          onTap: () {
                            _emailCtrl.text = 'farmer@cocoscan.lk';
                            _passCtrl.text = 'demo123';
                            setState(() => _role = 'Farmer');
                          },
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickLoginBtn(
                          label: 'Demo Officer',
                          icon: Icons.badge_rounded,
                          onTap: () {
                            _emailCtrl.text = 'officer@cocoscan.lk';
                            _passCtrl.text = 'demo123';
                            setState(() => _role = 'Agricultural Officer');
                          },
                        )),
                      ]),
                      const SizedBox(height: 28),

                      // Register link
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Don't have an account? ", style: AppTextStyles.caption),
                            GestureDetector(
                              onTap: _register,
                              child: const Text('Register Now',
                                style: TextStyle(color: AppColors.primary,
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffix,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => MainShell(role: _role)));
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password', style: AppTextStyles.heading3),
        content: const Text(
          'Enter your email and we\'ll send you a password reset link.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context),
              child: const Text('Send Link')),
        ],
      ),
    );
  }

  void _register() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration coming soon!')),
    );
  }
}

class _QuickLoginBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLoginBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}
