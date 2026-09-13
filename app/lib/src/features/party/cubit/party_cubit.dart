import 'package:flutter_bloc/flutter_bloc.dart';

import '../../battle/domain/party_formation.dart';
import '../../battle/domain/party_skills.dart';
import 'party_state.dart';

/// Composing a party.
///
/// A Cubit rather than a Bloc: the battle Bloc has an event type because the
/// simulation already publishes one and the HUD is downstream of it, but
/// nothing here is downstream of anything. Every method is a gesture the player
/// just made.
///
/// Both ways of placing a unit land on the same two operations. A tap picks a
/// unit up ([tapUnit], [tapSlot]) and a second tap puts it down; a drag carries
/// the unit itself and arrives at [dropOnSlot]. Which one the player used stops
/// mattering here, which is why neither had to be built twice.
///
/// Choosing a unit's skills is the screen's other half and works the same way:
/// [chooseSkills] takes the rotation the player has just built and [resetSkills]
/// hands the unit back to the one it was authored with.
class PartyCubit extends Cubit<PartyState> {
  PartyCubit({PartyFormation? formation, PartySkills? skills})
      : super(PartyState(
          formation: formation ?? const PartyFormation.empty(),
          heldUnitId: null,
          skills: skills ?? const PartySkills.empty(),
        ));

  /// Picks [unitId] up, or puts it back down if it was already in hand.
  ///
  /// Tapping a unit that is already standing somewhere picks it up off the
  /// board rather than cloning it — the formation is left as it is until the
  /// unit is put down, so an abandoned move changes nothing.
  void tapUnit(String unitId) => emit(PartyState(
        formation: state.formation,
        heldUnitId: state.isHeld(unitId) ? null : unitId,
        skills: state.skills,
      ));

  /// Taps a formation cell: puts the held unit down there, or — with an empty
  /// hand — picks up whoever is standing in it.
  void tapSlot(FormationSlot slot) {
    final String? held = state.heldUnitId;
    if (held == null) {
      final String? standing = state.formation.at(slot);
      if (standing != null) {
        emit(PartyState(
          formation: state.formation,
          heldUnitId: standing,
          skills: state.skills,
        ));
      }
      return;
    }
    emit(PartyState(
      formation: state.formation.place(held, slot),
      heldUnitId: null,
      skills: state.skills,
    ));
  }

  /// A unit was dragged onto [slot], from the bench or from another cell.
  void dropOnSlot(String unitId, FormationSlot slot) => emit(PartyState(
        formation: state.formation.place(unitId, slot),
        heldUnitId: null,
        skills: state.skills,
      ));

  /// Takes [unitId] out of the formation, however it got there.
  void bench(String unitId) => emit(PartyState(
        formation: state.formation.remove(unitId),
        heldUnitId: state.isHeld(unitId) ? null : state.heldUnitId,
        skills: state.skills,
      ));

  /// Empties one cell, leaving the rest of the formation alone.
  void clearSlot(FormationSlot slot) => emit(PartyState(
        formation: state.formation.clearSlot(slot),
        heldUnitId: state.heldUnitId,
        skills: state.skills,
      ));

  /// Back to an empty board, with nothing in hand.
  ///
  /// Chosen skills survive, because clearing the board is how a player starts
  /// the placement over — losing every rotation they tuned along with it would
  /// make rearranging the party expensive.
  void clearAll() => emit(PartyState(
        formation: const PartyFormation.empty(),
        heldUnitId: null,
        skills: state.skills,
      ));

  /// Replaces the whole formation — the default party button, and anything
  /// else that hands the player a party rather than asking them to build one.
  void reset(PartyFormation formation) => emit(PartyState(
        formation: formation,
        heldUnitId: null,
        skills: state.skills,
      ));

  /// Gives [unitId] the rotation [skillIds], in priority order.
  ///
  /// The whole rotation at once rather than one add or remove at a time: what
  /// the picker knows is the list it is showing, and [PartySkills] is the one
  /// place the rules about that list — no duplicates, no more than the slots a
  /// unit has — are applied.
  void chooseSkills(String unitId, List<String> skillIds) => emit(PartyState(
        formation: state.formation,
        heldUnitId: state.heldUnitId,
        skills: state.skills.withUnit(unitId, skillIds),
      ));

  /// Hands [unitId] back the skills it was authored with.
  void resetSkills(String unitId) => emit(PartyState(
        formation: state.formation,
        heldUnitId: state.heldUnitId,
        skills: state.skills.clearUnit(unitId),
      ));
}
