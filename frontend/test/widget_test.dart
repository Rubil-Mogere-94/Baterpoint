// frontend/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:baterpoint/main.dart';
import 'package:baterpoint/providers/auth_provider.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const BaterpointApp(),
      ),
    );
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
