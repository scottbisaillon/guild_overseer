import 'package:equatable/equatable.dart';

import '../../battle/domain/party_formation.dart';

/// Everything the party screen renders.
///
/// Two fields, because composing a party is two questions: who is going, which
/// [formation] answers, and what the player is in the middle of doing, which
/// [heldUnitId] answers. Drag and drop needs only the first — a drag carries
/// its own unit from start to finish. Select-and-place needs the second: a
/// tapped unit is held, in hand and waiting for somewhere to stand.
class PartyState extends Equatable {
  const PartyState({required this.formation, required this.heldUnitId});

  const PartyState.initial()
      : formation = const PartyFormation.empty(),
        heldUnitId = null;

  /// Who is standing where.
  final PartyFormation formation;

  /// The unit picked up by tapping and not yet put down, if any. Null whenever
  /// the player is not mid-gesture, which is most of the time.
  final String? heldUnitId;

  /// A party of nobody is not a fight, so dispatch waits for at least one.
  bool get canDispatch => formation.isNotEmpty;

  int get placedCount => formation.size;

  bool isHeld(String unitId) => heldUnitId == unitId;

  bool isPlaced(String unitId) => formation.contains(unitId);

  @override
  List<Object?> get props => <Object?>[formation, heldUnitId];
}
