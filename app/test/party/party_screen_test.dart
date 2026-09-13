import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guild_overseer/src/app/theme.dart';
import 'package:guild_overseer/src/features/battle/domain/party_formation.dart';
import 'package:guild_overseer/src/features/party/view/party_screen.dart';
import 'package:guild_overseer/src/features/party/view/widgets/unit_bench.dart';
import 'package:guild_overseer/src/features/party/view/widgets/unit_drag_source.dart';

/// The screen's job is that both ways of placing a unit end up at the same
/// formation, and that the formation is what the battle is handed.
void main() {
  const FormationSlot frontTop = (row: 0, column: 0);
  const FormationSlot backTop = (row: 0, column: 1);
  const FormationSlot backBottom = (row: 2, column: 1);

  const String bramm = 'Bramm Ironvow';
  const String fenn = 'Fenn Quill';

  /// The battle route, stubbed: the real one boots a Flame game, and what is
  /// under test here is what the party screen sends it.
  Widget app({
    PartyFormation? initialParty,
    TargetPlatform platform = TargetPlatform.android,
  }) =>
      MaterialApp.router(
        theme: buildAppTheme().copyWith(platform: platform),
        routerConfig: GoRouter(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  PartyScreen(initialParty: initialParty),
            ),
            GoRoute(
              path: '/battle',
              builder: (BuildContext context, GoRouterState state) => Scaffold(
                body: Text(
                  'dispatched '
                  '${PartyFormation.decode(
                    state.uri.queryParameters['party'],
                  ).encode()}',
                ),
              ),
            ),
          ],
        ),
      );

  Finder cell(FormationSlot slot) =>
      find.byKey(ValueKey<FormationSlot>(slot));

  Finder benched(String name) => find.descendant(
        of: find.byType(UnitBench),
        matching: find.text(name),
      );

  Finder standingIn(FormationSlot slot, String name) =>
      find.descendant(of: cell(slot), matching: find.text(name));

  /// Puts the screen up on a window wide enough for the bench to sit beside
  /// the board, so a drag between them is the drag a desktop player makes.
  Future<void> pumpScreen(
    WidgetTester tester, {
    PartyFormation? initialParty,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(initialParty: initialParty, platform: platform),
    );
    await tester.pumpAndSettle();
  }

  /// A touch drag: press, hold past the long press, carry, release.
  Future<void> longPressDrag(
    WidgetTester tester,
    Finder from,
    Finder to,
  ) async {
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(from));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('select and place', () {
    testWidgets('a tapped unit is placed by the next tapped slot',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      expect(find.textContaining('Carrying $bramm'), findsOneWidget);

      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      expect(standingIn(frontTop, bramm), findsOneWidget);
      expect(find.textContaining('Carrying'), findsNothing);
    });

    testWidgets('a placed unit is picked back up and moved by tapping',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();
      await tester.tap(cell(backBottom));
      await tester.pumpAndSettle();

      expect(standingIn(backBottom, bramm), findsOneWidget);
      expect(standingIn(frontTop, bramm), findsNothing);
    });

    testWidgets('the remove button takes a unit off the board',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove $bramm'));
      await tester.pumpAndSettle();

      expect(standingIn(frontTop, bramm), findsNothing);
      expect(find.text('0 of 6 slots filled'), findsOneWidget);
    });
  });

  group('drag and drop', () {
    testWidgets('a unit dragged from the bench lands in the slot',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await longPressDrag(tester, benched(bramm), cell(backTop));

      expect(standingIn(backTop, bramm), findsOneWidget);
    });

    testWidgets('dragging one unit onto another swaps them',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await longPressDrag(tester, benched(bramm), cell(frontTop));
      await longPressDrag(tester, benched(fenn), cell(backTop));
      await longPressDrag(tester, standingIn(backTop, fenn), cell(frontTop));

      expect(standingIn(frontTop, fenn), findsOneWidget);
      expect(standingIn(backTop, bramm), findsOneWidget);
    });

    testWidgets('a unit dragged back to the bench leaves the party',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await longPressDrag(tester, benched(bramm), cell(frontTop));
      await longPressDrag(
        tester,
        standingIn(frontTop, bramm),
        find.byType(UnitBench),
      );

      expect(standingIn(frontTop, bramm), findsNothing);
      expect(find.text('0 of 6 slots filled'), findsOneWidget);
    });

    testWidgets('a mouse drags without being asked to hold first',
        (WidgetTester tester) async {
      await pumpScreen(tester, platform: TargetPlatform.linux);

      expect(find.byType(LongPressDraggable<String>), findsNothing);
      expect(find.byType(UnitDragSource), findsWidgets);

      final Offset from = tester.getCenter(benched(bramm));
      await tester.dragFrom(from, tester.getCenter(cell(frontTop)) - from);
      await tester.pumpAndSettle();

      expect(standingIn(frontTop, bramm), findsOneWidget);
    });
  });

  group('dispatch', () {
    testWidgets('an empty party has nowhere to be sent',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      final FilledButton begin = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Begin battle'),
      );

      expect(begin.onPressed, isNull);
    });

    testWidgets('the composed party is what the battle is handed',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Begin battle'));
      await tester.pumpAndSettle();

      expect(find.text('dispatched ally_bramm:0:0'), findsOneWidget);
    });

    testWidgets('the default party is one button away',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Default party'));
      await tester.pumpAndSettle();

      expect(find.text('6 of 6 slots filled'), findsOneWidget);
      expect(standingIn(frontTop, bramm), findsOneWidget);
    });

    testWidgets('a link carrying a party opens on it',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        initialParty: PartyFormation.decode('ally_fenn:2:1'),
      );

      expect(standingIn(backBottom, fenn), findsOneWidget);
      expect(find.text('1 of 6 slots filled'), findsOneWidget);
    });
  });
}
