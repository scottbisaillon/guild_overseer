import 'package:flutter_test/flutter_test.dart';
import 'package:guild_overseer/src/core/domain/presentation.dart';
import 'package:guild_overseer/src/features/battle/data/mock_roster.dart';
import 'package:guild_overseer/src/features/battle/domain/combatant.dart';
import 'package:guild_overseer/src/features/battle/domain/skill.dart';

/// Content validation: every visual the mockup asks for is one the renderer
/// knows how to draw.
///
/// This is the cheap half of "fail loudly at load". The registry itself asserts
/// that it registers exactly [Cue.all]; this asserts that content only ever
/// names ids from the same set. Between them a mistyped cue cannot reach a
/// player, and neither check needs the renderer to be running.
void main() {
  test('every cue the roster names is one the renderer declares', () {
    final Set<String> named = <String>{};
    for (final Combatant unit in buildMockRoster()) {
      for (final SkillSlot slot in unit.rotation) {
        named.addAll(slot.definition.presentation.cueIds);
      }
    }

    expect(named, isNotEmpty, reason: 'the roster should ask for some visuals');
    expect(named.difference(Cue.all), isEmpty);
  });

  test('statuses declare how they read', () {
    expect(bleeding.presentation.impact, Cue.debuffMark);
    expect(bleeding.presentation.color, CueColor.debuff);
    expect(fortified.presentation.impact, Cue.buffMark);
    expect(fortified.presentation.color, CueColor.buff);

    for (final String id in <String>[
      ...bleeding.presentation.cueIds,
      ...fortified.presentation.cueIds,
    ]) {
      expect(Cue.all, contains(id));
    }
  });

  test('a heal reads as a heal, whatever it travels as', () {
    expect(mend.presentation.color, CueColor.heal);
    expect(darkMend.presentation.color, CueColor.heal);
    expect(shieldSlam.presentation.color, CueColor.source);
  });

  test('a spec with nothing authored names no cues', () {
    expect(PresentationSpec.none.cueIds, isEmpty);
  });
}
