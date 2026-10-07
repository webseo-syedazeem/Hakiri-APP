import 'package:flutter_test/flutter_test.dart';
import 'package:hakkiri_app/main.dart';
import 'package:hakkiri_app/screens/splash_screen.dart';

void main() {
  testWidgets('Hakkiri App launches and displays landing hero', (WidgetTester tester) async {
    await tester.pumpWidget(const HakkiriApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
  });
}
