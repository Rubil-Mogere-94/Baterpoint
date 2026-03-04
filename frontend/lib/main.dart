// frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/environment_config.dart';
import 'constants/ui_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentConfig.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const BaterpointApp(),
    ),
  );
}

class BaterpointApp extends StatelessWidget {
  const BaterpointApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Modern Vibrant Color Palette
    const primaryColor = Color(0xFF6366F1); // Indigo 500
    const secondaryColor = Color(0xFFEC4899); // Pink 500
    const tertiaryColor = Color(0xFF14B8A6); // Teal 500
    const surfaceLight = Color(0xFFF8FAFC); // Slate 50
    const textDark = Color(0xFF0F172A); // Slate 900
    const textMuted = Color(0xFF64748B); // Slate 500

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return MaterialApp(
      title: 'Baterpoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: surfaceLight,
          onSurface: textDark,
          outline: const Color(0xFFE2E8F0),
        ),
        scaffoldBackgroundColor: surfaceLight,
        textTheme: baseTextTheme.copyWith(
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: -1.5,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: textDark,
            letterSpacing: -1.0,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            color: const Color(0xFF334155),
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            color: textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: surfaceLight,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: textDark,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
          iconTheme: const IconThemeData(color: textDark, size: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
            textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: AppRadius.roundedLG,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.roundedLG,
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.roundedLG,
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.w600),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedXL,
            side: const BorderSide(color: Color(0xFFF1F5F9)),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8),
          brightness: Brightness.dark,
          primary: const Color(0xFF818CF8),
          secondary: const Color(0xFFEC4899),
          tertiary: const Color(0xFF2DD4BF),
          surface: const Color(0xFF0F172A),
          background: const Color(0xFF020617),
        ),
        scaffoldBackgroundColor: const Color(0xFF020617),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: const Color(0xFF020617),
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedXL,
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          color: const Color(0xFF0F172A),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      ),
    );
  }
}
