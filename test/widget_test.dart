import 'package:flutter_test/flutter_test.dart';
import 'package:hakkiri_app/main.dart';

void main() {
  testWidgets('Hakkiri App launches and displays landing hero', (WidgetTester tester) async {
    await tester.pumpWidget(const HakkiriApp());
    await tester.pumpAndSettle();

    expect(find.text('hakkiri'), findsOneWidget);
    expect(find.text('Start your assessment'), findsOneWidget);
  });
}
