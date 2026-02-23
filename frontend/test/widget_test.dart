// frontend/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:baterpoint/main.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BaterpointApp());
    expect(find.text('Login to Baterpoint'), findsOneWidget);
  });
}
