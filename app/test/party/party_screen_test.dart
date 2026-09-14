import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guild_overseer/src/app/theme.dart';
import 'package:guild_overseer/src/features/battle/domain/party_formation.dart';
import 'package:guild_overseer/src/features/battle/domain/party_skills.dart';
import 'package:guild_overseer/src/features/party/view/party_screen.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/party/view/widgets/skill_picker.dart';
import 'package:guild_overseer/src/features/party/view/widgets/skill_reach_glyph.dart';
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
    PartySkills? initialSkills,
    TargetPlatform platform = TargetPlatform.android,
  }) =>
      MaterialApp.router(
        theme: buildAppTheme().copyWith(platform: platform),
        routerConfig: GoRouter(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  PartyScreen(
                initialParty: initialParty,
                initialSkills: initialSkills,
              ),
            ),
            GoRoute(
              path: '/battle',
              // Both halves of what was dispatched, read back off the link:
              // who went, and what they took with them.
              builder: (BuildContext context, GoRouterState state) => Scaffold(
                body: Text(
                  'dispatched '
                  '${PartyFormation.decode(
                    state.uri.queryParameters['party'],
                  ).encode()}'
                  ' with '
                  '${PartySkills.decode(
                    state.uri.queryParameters['skills'],
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
    PartySkills? initialSkills,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(
        initialParty: initialParty,
        initialSkills: initialSkills,
        platform: platform,
      ),
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

      expect(find.text('dispatched ally_bramm:0:0 with '), findsOneWidget);
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

  /// The other half of composing a party: what each unit brings. The picker
  /// writes through to the same cubit the board does, so what it changes shows
  /// up on the card and travels in the dispatch link.
  group('choosing skills', () {
    Finder inPicker(Finder finder) =>
        find.descendant(of: find.byType(SkillPicker), matching: finder);

    Future<void> openPicker(WidgetTester tester, String unitName) async {
      await tester.tap(find.byTooltip('Skills for $unitName').first);
      await tester.pumpAndSettle();
    }

    /// The pool is longer than the dialog, so anything low in it has to be
    /// scrolled to before it can be tapped — as a player would.
    Future<void> tapInPicker(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> dispatch(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Begin battle'));
      await tester.pumpAndSettle();
    }

    testWidgets('the picker shows what a unit brings and what it may take',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await openPicker(tester, bramm);

      expect(find.text('ROTATION'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget, reason: 'as authored');
      // The basic attack is in the rotation and not in the pool: it is the
      // unit's own, and not the player's to trade away.
      expect(inPicker(find.text('Strike')), findsOneWidget);
      expect(inPicker(find.text('Rally')), findsOneWidget);
    });

    testWidgets('every skill in the picker shows where it lands',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await openPicker(tester, bramm);

      // Bramm's two skills, his basic attack, and every skill on offer.
      expect(
        find.byType(SkillReachGlyph),
        findsNWidgets(3 + kSkillPool.length),
      );
      // Cleave takes a rank: three cells of the enemy formation, and the
      // glyph is fed that by the same resolver the fight uses.
      expect(
        tester
            .widgetList<SkillReachGlyph>(find.byType(SkillReachGlyph))
            .where((SkillReachGlyph glyph) => glyph.reach.enemies.length == 3),
        isNotEmpty,
      );
    });

    testWidgets('a skill taken from the pool joins the rotation',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await openPicker(tester, bramm);
      await tapInPicker(tester, inPicker(find.text('Mend')).first);
      await tapInPicker(tester, find.widgetWithText(FilledButton, 'Done'));
      await dispatch(tester);

      expect(
        find.text(
          'dispatched ally_bramm:0:0 with ally_bramm:fortify.shield_slam.mend',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a rotation only holds what it holds',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await openPicker(tester, bramm);
      await tapInPicker(tester, inPicker(find.text('Mend')).first);
      expect(find.text('3/3'), findsOneWidget);

      await tapInPicker(tester, inPicker(find.text('Rally')).first);

      expect(find.text('3/3'), findsOneWidget);
      expect(inPicker(find.text('Rally')), findsOneWidget, reason: 'unchosen');
    });

    testWidgets('a dropped skill leaves the rotation',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await openPicker(tester, bramm);
      await tapInPicker(tester, find.byTooltip('Drop Fortify'));
      await tapInPicker(tester, find.widgetWithText(FilledButton, 'Done'));
      await dispatch(tester);

      expect(
        find.text('dispatched ally_bramm:0:0 with ally_bramm:shield_slam'),
        findsOneWidget,
      );
    });

    testWidgets('the rotation is reordered into priority order',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await openPicker(tester, bramm);
      await tapInPicker(tester, find.byTooltip('Move Shield Slam up'));
      await tapInPicker(tester, find.widgetWithText(FilledButton, 'Done'));
      await dispatch(tester);

      expect(
        find.text(
          'dispatched ally_bramm:0:0 with ally_bramm:shield_slam.fortify',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a reset unit travels with no skills of its own',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();

      await openPicker(tester, bramm);
      await tapInPicker(tester, inPicker(find.text('Mend')).first);
      await tapInPicker(
        tester,
        find.widgetWithText(TextButton, 'Reset to default'),
      );
      await tapInPicker(tester, find.widgetWithText(FilledButton, 'Done'));
      await dispatch(tester);

      expect(
        find.text('dispatched ally_bramm:0:0 with '),
        findsOneWidget,
        reason: 'a unit fighting as authored adds nothing to the link',
      );
    });

    testWidgets('only the units that are going carry their skills along',
        (WidgetTester tester) async {
      await pumpScreen(tester);

      await openPicker(tester, fenn);
      await tapInPicker(tester, inPicker(find.text('Mend')).first);
      await tapInPicker(tester, find.widgetWithText(FilledButton, 'Done'));

      await tester.tap(benched(bramm));
      await tester.pumpAndSettle();
      await tester.tap(cell(frontTop));
      await tester.pumpAndSettle();
      await dispatch(tester);

      expect(find.text('dispatched ally_bramm:0:0 with '), findsOneWidget);
    });

    testWidgets('a link carrying skills opens on them',
        (WidgetTester tester) async {
      await pumpScreen(
        tester,
        initialParty: PartyFormation.decode('ally_bramm:0:0'),
        initialSkills: PartySkills.decode('ally_bramm:mend.cleave'),
      );

      await openPicker(tester, bramm);

      expect(find.text('2/3'), findsOneWidget);
      expect(find.textContaining('customised'), findsOneWidget);
      expect(inPicker(find.text('Fortify')), findsOneWidget, reason: 'pool');
    });
  });
}
