import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/skill_effect.dart';
import '../../../../core/domain/target_selector.dart';
import '../../../battle/data/mock_roster.dart';
import '../../../battle/domain/party_skills.dart';
import '../../../battle/domain/skill.dart';
import '../../../battle/domain/unit_blueprint.dart';
import '../../../battle/view/battle_palette.dart';
import '../../cubit/party_cubit.dart';
import '../../cubit/party_state.dart';
import 'role_glyph.dart';

/// Opens the skill picker for [unit] over the party screen.
///
/// The cubit is handed across explicitly: a dialog is pushed above the screen
/// that provided it, so it would not otherwise be found.
Future<void> showSkillPicker(BuildContext context, UnitBlueprint unit) =>
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider<PartyCubit>.value(
        value: context.read<PartyCubit>(),
        child: SkillPicker(unit: unit),
      ),
    );

/// Choosing what one unit fights with.
///
/// Two lists, because a rotation is two decisions: which skills, which the
/// pool below answers, and in what order, which the rotation above answers —
/// the first ready skill fires, so the order is the unit's priorities written
/// down. Every gesture writes straight through to the cubit, like everything
/// else on this screen: there is no draft to commit and nothing to lose by
/// closing the dialog.
///
/// The pool is general — every unit may take anything in it. Skill trees will
/// narrow that down per class, at which point this screen asks the tree what
/// it may offer and the rest of it stays as it is.
class SkillPicker extends StatelessWidget {
  const SkillPicker({required this.unit, this.pool = kSkillPool, super.key});

  /// The unit as authored. What it is currently carrying comes from the cubit,
  /// so the dialog redraws as the player edits.
  final UnitBlueprint unit;

  final List<SkillDefinition> pool;

  @override
  Widget build(BuildContext context) {
    final PartyCubit cubit = context.read<PartyCubit>();

    return BlocBuilder<PartyCubit, PartyState>(
      builder: (BuildContext context, PartyState state) {
        final List<String> chosen = _chosenIds(state.skills);
        final bool full = chosen.length >= kChosenSkillSlots;

        return AlertDialog(
          backgroundColor: BattlePalette.panel,
          title: _title(state),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _sectionHeader(
                    'ROTATION',
                    '${chosen.length}/$kChosenSkillSlots',
                  ),
                  const _Hint('Fires top to bottom: the first ready skill '
                      'wins, so the heaviest hitter belongs at the top.'),
                  if (chosen.isEmpty)
                    const _Hint('Nothing chosen — this unit will only ever '
                        'use its basic attack.'),
                  for (int index = 0; index < chosen.length; index++)
                    if (poolSkill(chosen[index]) case final SkillDefinition s)
                      _RotationRow(
                        position: index + 1,
                        skill: s,
                        onUp: index == 0
                            ? null
                            : () => cubit.chooseSkills(
                                  unit.id,
                                  _moved(chosen, index, index - 1),
                                ),
                        onDown: index == chosen.length - 1
                            ? null
                            : () => cubit.chooseSkills(
                                  unit.id,
                                  _moved(chosen, index, index + 1),
                                ),
                        onRemove: () => cubit.chooseSkills(
                          unit.id,
                          _without(chosen, s.id),
                        ),
                      ),
                  for (final SkillDefinition basic in unit.basicSkills)
                    _BasicRow(skill: basic),
                  const SizedBox(height: 12),
                  _sectionHeader('SKILL POOL', '${pool.length} available'),
                  const _Hint('One pool for every unit, for now. Skill trees '
                      'will decide what a unit may learn.'),
                  for (final SkillDefinition skill in pool)
                    _PoolRow(
                      skill: skill,
                      taken: chosen.contains(skill.id),
                      // A full rotation still lets a taken skill be tapped —
                      // that is how it comes back out.
                      onTap: chosen.contains(skill.id)
                          ? () => cubit.chooseSkills(
                                unit.id,
                                _without(chosen, skill.id),
                              )
                          : full
                              ? null
                              : () => cubit.chooseSkills(
                                    unit.id,
                                    <String>[...chosen, skill.id],
                                  ),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: state.isCustomised(unit.id)
                  ? () => cubit.resetSkills(unit.id)
                  : null,
              child: const Text('Reset to default'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  /// What the unit is carrying: the player's choice, or the skills it was
  /// authored with until they make one.
  List<String> _chosenIds(PartySkills skills) =>
      skills.forUnit(unit.id) ??
      <String>[
        for (final SkillDefinition skill in unit.chosenSkills) skill.id,
      ];

  Widget _title(PartyState state) => Row(
        children: <Widget>[
          RoleGlyph(role: unit.role),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  unit.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BattlePalette.textPrimary,
                  ),
                ),
                Text(
                  state.isCustomised(unit.id)
                      ? '${unit.role.label}  ·  customised'
                      : unit.role.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BattlePalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _sectionHeader(String label, String trailing) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: BattlePalette.textPrimary,
                ),
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                color: BattlePalette.textMuted,
              ),
            ),
          ],
        ),
      );

  /// [ids] with the entry at [from] moved to [to].
  static List<String> _moved(List<String> ids, int from, int to) {
    final List<String> next = List<String>.of(ids);
    next.insert(to, next.removeAt(from));
    return next;
  }

  static List<String> _without(List<String> ids, String id) =>
      <String>[for (final String each in ids) if (each != id) each];
}

/// One skill the unit is taking, at the priority the player put it at.
class _RotationRow extends StatelessWidget {
  const _RotationRow({
    required this.position,
    required this.skill,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int position;
  final SkillDefinition skill;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border.all(color: BattlePalette.gridLine),
            color: BattlePalette.background,
          ),
          child: Row(
            children: <Widget>[
              Text(
                '$position',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BattlePalette.ally,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _SkillText(skill: skill)),
              _IconAction(
                icon: Icons.arrow_upward,
                tooltip: 'Move ${skill.name} up',
                onPressed: onUp,
              ),
              _IconAction(
                icon: Icons.arrow_downward,
                tooltip: 'Move ${skill.name} down',
                onPressed: onDown,
              ),
              _IconAction(
                icon: Icons.close,
                tooltip: 'Drop ${skill.name}',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      );
}

/// The basic attack, which is the unit's own and not on offer.
class _BasicRow extends StatelessWidget {
  const _BasicRow({required this.skill});

  final SkillDefinition skill;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
        child: Opacity(
          opacity: 0.65,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              border: Border.all(color: BattlePalette.gridLine),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: BattlePalette.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(child: _SkillText(skill: skill)),
                const Text(
                  'BASIC · ALWAYS LAST',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1,
                    color: BattlePalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// One skill on offer. Tapping takes it, or gives it back.
class _PoolRow extends StatelessWidget {
  const _PoolRow({
    required this.skill,
    required this.taken,
    required this.onTap,
  });

  final SkillDefinition skill;
  final bool taken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Semantics(
          button: true,
          selected: taken,
          child: InkWell(
            onTap: onTap,
            child: Opacity(
              opacity: onTap == null ? 0.4 : 1,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: taken
                      ? BattlePalette.ally.withValues(alpha: 0.12)
                      : BattlePalette.background,
                  border: Border.all(
                    color:
                        taken ? BattlePalette.ally : BattlePalette.gridLine,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      taken ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 14,
                      color: taken
                          ? BattlePalette.ally
                          : BattlePalette.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _SkillText(skill: skill)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

/// A skill's name over what it does, so the pool can be read rather than
/// remembered.
class _SkillText extends StatelessWidget {
  const _SkillText({required this.skill});

  final SkillDefinition skill;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            skill.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BattlePalette.textPrimary,
            ),
          ),
          Text(
            skillBlurb(skill),
            maxLines: 2,
            style: const TextStyle(
              fontSize: 10,
              color: BattlePalette.textMuted,
            ),
          ),
        ],
      );
}

/// A line of instruction or warning under a section header.
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: BattlePalette.textMuted,
          ),
        ),
      );
}

/// A compact, cramped icon button — three of them fit on one rotation row.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 14,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: BattlePalette.textMuted),
      );
}

/// What a skill does, in one line, read off the skill itself.
///
/// Derived rather than authored, so a skill never carries a description that
/// has drifted from what it actually does — and so a skill added to the pool
/// is readable in the picker without anybody writing prose for it.
String skillBlurb(SkillDefinition skill) {
  final String what = <String>[
    for (final EffectSpec spec in skill.effects) _phrase(spec),
  ].join(' + ');
  return '$what  ·  ${_seconds(skill.cooldown)}s cooldown';
}

String _phrase(EffectSpec spec) => switch (spec.effect) {
      final DamageEffect e =>
        '${_coefficient(e.coefficient)} damage to ${_who(spec.selector)}',
      final HealEffect e =>
        '${_coefficient(e.coefficient)} healing to ${_who(spec.selector)}',
      final ApplyStatusEffect e =>
        '${e.status.name} on ${_who(spec.selector)}',
      final RemoveStatusEffect _ => 'cleanses ${_who(spec.selector)}',
    };

/// Who an effect lands on, in the words the party screen already uses.
String _who(TargetSelector selector) {
  if (selector.side == TargetSide.allies) {
    if (selector.shape == TargetShape.anchorOnly) {
      return 'self';
    }
    return selector.takesEveryone ? 'the party' : 'an ally';
  }
  return switch (selector.shape) {
    TargetShape.sameColumn => "the target's rank",
    TargetShape.sameRow => "the target's row",
    TargetShape.all => 'the enemy side',
    TargetShape.anchorOnly => 'the target',
  };
}

String _coefficient(double value) =>
    '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}x';

String _seconds(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
