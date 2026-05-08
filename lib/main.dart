import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/localization_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Localization
  await LocalizationService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const CocoScanApp());
}

class CocoScanApp extends StatelessWidget {
  const CocoScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'CocoScan',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return const IconThemeData(color: AppColors.textSecondary, size: 22);
          }),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary.withOpacity(0.15),
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.darkCard,
          contentTextStyle: const TextStyle(fontSize: 13),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: EdgeInsets.zero,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 24,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.darkSurface,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: AppColors.darkBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkCard,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.darkCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.darkCard,
            indicatorColor: AppColors.primary.withOpacity(0.2),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.primary, size: 24);
              }
              return const IconThemeData(color: Colors.white54, size: 22);
            }),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            elevation: 12,
            shadowColor: Colors.black.withOpacity(0.3),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.darkSurface,
            selectedColor: AppColors.primary.withOpacity(0.25),
            labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.darkCard,
            contentTextStyle: const TextStyle(fontSize: 13, color: Colors.white),
          ),
          dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
          cardTheme: CardThemeData(
            color: AppColors.darkCard,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.zero,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppColors.darkCard,
            elevation: 24,
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          ),
        ),
        home: const SplashScreen(),
      );
    });
  }
}
