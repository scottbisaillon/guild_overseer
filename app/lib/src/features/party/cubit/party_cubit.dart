import 'package:flutter_bloc/flutter_bloc.dart';

import '../../battle/domain/party_formation.dart';
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
class PartyCubit extends Cubit<PartyState> {
  PartyCubit({PartyFormation? formation})
      : super(PartyState(
          formation: formation ?? const PartyFormation.empty(),
          heldUnitId: null,
        ));

  /// Picks [unitId] up, or puts it back down if it was already in hand.
  ///
  /// Tapping a unit that is already standing somewhere picks it up off the
  /// board rather than cloning it — the formation is left as it is until the
  /// unit is put down, so an abandoned move changes nothing.
  void tapUnit(String unitId) => emit(PartyState(
        formation: state.formation,
        heldUnitId: state.isHeld(unitId) ? null : unitId,
      ));

  /// Taps a formation cell: puts the held unit down there, or — with an empty
  /// hand — picks up whoever is standing in it.
  void tapSlot(FormationSlot slot) {
    final String? held = state.heldUnitId;
    if (held == null) {
      final String? standing = state.formation.at(slot);
      if (standing != null) {
        emit(PartyState(formation: state.formation, heldUnitId: standing));
      }
      return;
    }
    emit(PartyState(
      formation: state.formation.place(held, slot),
      heldUnitId: null,
    ));
  }

  /// A unit was dragged onto [slot], from the bench or from another cell.
  void dropOnSlot(String unitId, FormationSlot slot) => emit(PartyState(
        formation: state.formation.place(unitId, slot),
        heldUnitId: null,
      ));

  /// Takes [unitId] out of the formation, however it got there.
  void bench(String unitId) => emit(PartyState(
        formation: state.formation.remove(unitId),
        heldUnitId: state.isHeld(unitId) ? null : state.heldUnitId,
      ));

  /// Empties one cell, leaving the rest of the formation alone.
  void clearSlot(FormationSlot slot) => emit(PartyState(
        formation: state.formation.clearSlot(slot),
        heldUnitId: state.heldUnitId,
      ));

  /// Back to an empty board, with nothing in hand.
  void clearAll() => emit(const PartyState.initial());

  /// Replaces the whole formation — the default party button, and anything
  /// else that hands the player a party rather than asking them to build one.
  void reset(PartyFormation formation) =>
      emit(PartyState(formation: formation, heldUnitId: null));
}
