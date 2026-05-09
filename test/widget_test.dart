import 'package:flutter_test/flutter_test.dart';
import 'package:campuscan/main.dart';

void main() {
  testWidgets('CampuScan app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CampuScanApp());
    expect(find.text('CampuScan'), findsOneWidget);
  });
}
