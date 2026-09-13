import 'package:equatable/equatable.dart';

import '../../battle/domain/party_formation.dart';
import '../../battle/domain/party_skills.dart';

/// Everything the party screen renders.
///
/// Three fields, because composing a party is three questions: who is going,
/// which [formation] answers; what they bring, which [skills] answers; and
/// what the player is in the middle of doing, which [heldUnitId] answers. Drag
/// and drop needs only the first — a drag carries its own unit from start to
/// finish. Select-and-place needs the last: a tapped unit is held, in hand and
/// waiting for somewhere to stand.
class PartyState extends Equatable {
  const PartyState({
    required this.formation,
    required this.heldUnitId,
    this.skills = const PartySkills.empty(),
  });

  const PartyState.initial()
      : formation = const PartyFormation.empty(),
        heldUnitId = null,
        skills = const PartySkills.empty();

  /// Who is standing where.
  final PartyFormation formation;

  /// What each unit is taking with it. A unit with no entry fights with the
  /// skills it was authored with, so an untouched screen is the authored
  /// roster rather than a board of blank units.
  final PartySkills skills;

  /// The unit picked up by tapping and not yet put down, if any. Null whenever
  /// the player is not mid-gesture, which is most of the time.
  final String? heldUnitId;

  /// A party of nobody is not a fight, so dispatch waits for at least one.
  bool get canDispatch => formation.isNotEmpty;

  int get placedCount => formation.size;

  bool isHeld(String unitId) => heldUnitId == unitId;

  bool isPlaced(String unitId) => formation.contains(unitId);

  bool isCustomised(String unitId) => skills.hasChoiceFor(unitId);

  /// The skills the party is actually taking: what the player chose for the
  /// units that are going, and nothing about the ones that are not.
  PartySkills get dispatchedSkills =>
      skills.retaining(formation.placements.values);

  @override
  List<Object?> get props => <Object?>[formation, heldUnitId, skills];
}
