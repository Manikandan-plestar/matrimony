import 'package:flutter_test/flutter_test.dart';
import 'package:matrimony_app/main.dart';

void main() {
  testWidgets('MatrimonyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MatrimonyApp());
    expect(find.text('Vows & Souls'), findsOneWidget);
  });
}
