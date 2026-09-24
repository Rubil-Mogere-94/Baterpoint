import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'services/app_config_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Baterpoint',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: kBackgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            brightness: Brightness.light,
            primary: kPrimaryColor,
            secondary: kSecondaryColor,
            surface: kSurfaceColor,
            error: kErrorColor,
            outline: kBorderColor,
          ),
          textTheme: textTheme.copyWith(
            displayLarge: textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: kTextColor,
              letterSpacing: -0.5,
            ),
            displayMedium: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
            headlineLarge: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
            headlineMedium: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
            titleLarge: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
            titleMedium: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: kTextColor,
            ),
            bodyLarge: textTheme.bodyLarge?.copyWith(
              color: kTextColor,
              height: 1.5,
            ),
            bodyMedium: textTheme.bodyMedium?.copyWith(
              color: kTextLightColor,
              height: 1.5,
            ),
            labelLarge: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
            iconTheme: const IconThemeData(color: kTextColor),
            actionsIconTheme: const IconThemeData(color: kTextColor),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              side: const BorderSide(color: kPrimaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kSurfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kErrorColor),
            ),
            labelStyle: const TextStyle(color: kTextLightColor),
            hintStyle: const TextStyle(color: kTextLightColor),
          ),
          cardTheme: CardThemeData(
            color: kSurfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: kBorderColor),
            ),
            margin: const EdgeInsets.all(0),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: kSurfaceColor,
            selectedColor: kPrimaryColor.withValues(alpha: 0.12),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kTextColor,
            ),
            secondaryLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: kBorderColor),
            ),
            side: const BorderSide(color: kBorderColor),
          ),
          dividerTheme: const DividerThemeData(
            color: kDividerColor,
            thickness: 1,
            space: 1,
          ),
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kTextColor,
            ),
            subtitleTextStyle: TextStyle(
              fontSize: 14,
              color: kTextLightColor,
            ),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthScreen(),
      ),
    );
  }
}