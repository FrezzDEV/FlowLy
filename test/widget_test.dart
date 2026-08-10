import 'package:flutter_test/flutter_test.dart';
import 'package:flowly/main.dart';
import 'package:flowly/services/player_service.dart';
import 'package:flowly/services/theme_service.dart';

void main() {
  testWidgets('FlowLy launches', (tester) async {
    final player = PlayerService();
    final themes = ThemeService();

    await tester.pumpWidget(FlowLyApp(player: player, themes: themes));
    await tester.pump();

    expect(find.text('FlowLy'), findsOneWidget);
    expect(find.text('Недавно прослушано'), findsOneWidget);

    await player.dispose();
  });
}
