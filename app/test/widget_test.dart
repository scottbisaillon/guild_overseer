import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/app/app.dart';

void main() {
  testWidgets('app boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GuildOverseerApp());
    await tester.pumpAndSettle();

    expect(find.text('GUILD OVERSEER'), findsOneWidget);
    expect(find.text('Compose a party'), findsOneWidget);
    expect(find.text('Open battle mockup'), findsOneWidget);
  });
}
