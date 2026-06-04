# Milestone 2: Allies and enemies

## Goal

Four units appear in the gameplay scene: two allies on one side and two enemies on the other. They're visually distinguished by color. None of them move or behave.

## Scope

- Multiple units in the scene, each with a position.
- A way to identify which faction a unit belongs to (ally or enemy).
- A way to identify "this object is a combatant" as distinct from any other object that might exist (props, UI, scenery).
- Visual differentiation between factions (e.g., color).

## Design Decisions

- **Faction is data, not type.** A unit's faction is a property/value it carries, not a class it inherits from. This keeps the door open for additional factions later (neutral, hostile-to-all, temporary alliance) without restructuring.
- **"Is a combatant" is a separate concept from "what faction."** A unit's combatant status is a marker — anything in the scene that *fights* carries it. Some future objects (banners, buildings, drops) might carry a faction but not be combatants. Filtering on the combatant marker future-proofs anything that should only act on real combatants.
- **All units share the same data shape.** Position, faction, size, color — same fields across both sides. Variation between units is value-level, not structural.

## Observable Behavior

- The scene shows four units: two of one color clustered on the left, two of another color clustered on the right.
- Toggling the scene off and on cleanly cleans up and recreates all four.

## Out of Scope

- Movement, targeting, combat, health.
- Sprite art (still solid-color shapes).
- Selecting or interacting with individual units.
- Varying unit stats between members of the same faction.

## Verification

Each of the four units is identifiable by position and color. The data model supports introducing a third faction later by adding a value rather than a type.

## Porting notes

In engines with inheritance, the temptation is to make `Ally` and `Enemy` subclasses of `Combatant`. Resist this. Faction as a property is the correct shape regardless of engine — it survives the "third faction" test, the "temporary alliance" test, and the "what if a unit changes sides mid-fight" test. Subclassing fails all three.
