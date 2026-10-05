import 'package:flutter_test/flutter_test.dart';
import 'package:hakkiri_app/main.dart';

void main() {
  testWidgets('Hakkiri App launches and displays landing hero', (WidgetTester tester) async {
    await tester.pumpWidget(const HakkiriApp());
    await tester.pumpAndSettle();

    expect(find.text('HAKKIRI'), findsOneWidget);
    expect(find.text('Take 2-Minute Diagnostic Assessment →'), findsOneWidget);
  });
}
