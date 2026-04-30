import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — deep forest green
  static const Color primary      = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark  = Color(0xFF0A3D0A);
  static const Color primaryGlow  = Color(0xFF43A047);

  // Secondary palette — professional blue
  static const Color secondary      = Color(0xFF1565C0);
  static const Color secondaryLight = Color(0xFF1976D2);

  // Accent
  static const Color accent = Color(0xFF00BFA5);

  // Status colours
  static const Color confirmed = Color(0xFFD32F2F);
  static const Color uncertain = Color(0xFFF57C00);
  static const Color healthy   = Color(0xFF2E7D32);

  // Neutral
  static const Color surface        = Color(0xFFF4F8F4);
  static const Color cardBg         = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF1A2E1A);
  static const Color textSecondary  = Color(0xFF546554);
  static const Color divider        = Color(0xFFDDE8DD);
  static const Color darkBg         = Color(0xFF0D1A0D);
  static const Color darkCard       = Color(0xFF1A2E1A);
  static const Color darkSurface    = Color(0xFF111E11);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradientV = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A1A0A), Color(0xFF0D1A2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.8,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.6,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class AppDecorations {
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.07),
        blurRadius: 20, offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get gradientCard => BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.divider),
  );

  static BoxDecoration get darkCard => BoxDecoration(
    color: AppColors.darkCard,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 16, offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration glassMorphism({
    Color? color, double opacity = 0.15, double radius = 20}) => BoxDecoration(
    color: (color ?? Colors.white).withOpacity(opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: Colors.white.withOpacity(0.2), width: 1),
  );

  static BoxDecoration gradientBorder(Gradient gradient, {double radius = 18}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
      );
}

class AppShadows {
  static List<BoxShadow> get primary => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      blurRadius: 20, offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24, offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primaryGlow.withOpacity(0.3),
      blurRadius: 30, spreadRadius: 2, offset: Offset.zero,
    ),
  ];
}
