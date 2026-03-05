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
import 'constants/theme.dart';

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

    return MaterialApp(
      title: 'Baterpoint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // We can define darkTheme in AppTheme later if needed
      // darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainScreen();
          } else if (auth.hasSeenOnboarding) {
            return const LoginScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      ),
    );
  }
}
