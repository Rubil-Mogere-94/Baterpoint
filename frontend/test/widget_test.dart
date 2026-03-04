// frontend/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:baterpoint/providers/theme_provider.dart';
import 'package:baterpoint/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Login screen shown correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
