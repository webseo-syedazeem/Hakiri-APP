import 'package:flutter_test/flutter_test.dart';
import 'package:hakkiri_app/main.dart';

void main() {
  testWidgets('Hakkiri App launches and displays landing hero', (WidgetTester tester) async {
    await tester.pumpWidget(const HakkiriApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Start your assessment'), findsOneWidget);
  });
}
