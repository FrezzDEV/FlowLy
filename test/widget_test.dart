import 'package:flutter_test/flutter_test.dart';
import 'package:flowly/main.dart';

void main() {
  testWidgets('FlowLy launches', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    expect(find.text('FlowLy'), findsOneWidget);
    expect(find.text('Недавно прослушано'), findsOneWidget);
  });
}
