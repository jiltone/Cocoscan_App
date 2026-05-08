import 'package:flutter/material.dart';
import '../services/backend_service.dart';
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
                      const Row(children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('or', style: AppTextStyles.caption),
                        ),
                        Expanded(child: Divider()),
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
                            const Text("Don't have an account? ", style: AppTextStyles.caption),
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

    try {
      final result = await BackendService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
      );

      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => MainShell(role: result['user']['role'] as String)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF81C784), // light green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
    showDialog(
      context: context,
      builder: (_) => const _RegistrationDialog(),
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

class _RegistrationDialog extends StatefulWidget {
  const _RegistrationDialog();

  @override
  State<_RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<_RegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _plantationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _role = 'Farmer';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _plantationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Create Account', style: AppTextStyles.heading3),
                  ],
                ),
                const SizedBox(height: 20),

                // Role selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: ['Farmer', 'Agricultural Officer'].map((role) {
                      final selected = _role == role;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _role = role),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: selected ? AppColors.primaryGradient : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(role,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600, fontSize: 12,
                              )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (v) => v != null && v.length >= 2
                      ? null : 'Name must be at least 2 characters',
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'john@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                  ),
                  validator: (v) => v != null && v.contains('@')
                      ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 12),

                // Plantation (for farmers)
                if (_role == 'Farmer') ...[
                  TextFormField(
                    controller: _plantationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Plantation Name (Optional)',
                      hintText: 'ABC Coconut Plantation',
                      prefixIcon: Icon(Icons.agriculture_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: '+94 77 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => v != null && v.length >= 6
                      ? null : 'Password must be at least 6 characters',
                ),
                const SizedBox(height: 12),

                // Confirm Password
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await BackendService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
        plantation: _plantationCtrl.text.trim().isEmpty ? null : _plantationCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => MainShell(role: result['user']['role'] as String)));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Account created successfully!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF66BB6A), // success green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF81C784), // light green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }
}
