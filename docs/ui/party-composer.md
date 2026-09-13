# UI — Party Composer

Builds the party for a dungeon run. Shows live trait conflicts, composition score, and per-member RQS. Dispatch creates the active run and routes to idle or active dungeon based on player character presence.

**Depends on:** [[../systems/members]], [[../systems/traits]], [[../systems/rotation]], [[../systems/dungeon]]

---

## Components

- **Dungeon selector** — list of available dungeons with tier, requirements, and estimated difficulty.
- **Party slots** — up to 6 slots. Assign by clicking roster members. Player character slot is always present and cannot be removed.
- **Trait conflict warnings** — live evaluation on every roster change. Both members in a conflicting pair are highlighted — not just one.
- **Composition score** — Tank / Heal / DPS / Support balance shown as proportional bars. Missing required roles highlighted in red.
- **RQS per member** — rotation quality score for each assigned member against the selected dungeon. Updates live.
- **Roster panel** — available members with role, level, morale. Filterable by role. In-party and resting members shown as unavailable.
- **Dispatch button** — validates requirements, shows stacking penalties for violations, confirms dispatch.

---

## Implementation Notes

### Bevy

Conflict evaluation and RQS preview both call pure functions (`evaluate_conflicts`, `evaluate_rotation`) directly inside the egui render system each frame — immediate-mode means no separate subscription or caching is needed for UI that updates continuously.

The dispatch action writes a `DispatchParty` event. The dispatch system reads it, creates `Res<ActiveRun>`, and sets `AppState` — `AppState::ActiveDungeon` if the `PlayerCharacter` entity is in the party, `AppState::IdleDungeon` if not.

### Flutter + Flame
A Flutter screen. `LongPressDraggable` and `DragTarget` handle party slot assignment — Flutter's built-in drag-and-drop, works on both touch and mouse without extra libraries.

Trait conflict evaluation and RQS preview both call pure Dart functions inline during `build()` — `BlocBuilder` rebuilds the screen on every party change, which is the right trigger. No separate subscription or state needed.

Dispatch writes a `DispatchPartyEvent` to `GameBloc`. The Bloc validates requirements, creates `ActiveRun` in state, and `go_router` navigates to `/dungeon/idle` or `/dungeon/active` based on whether `PlayerCharacter` is in the party.

---

## Built so far

A first slice exists at `/party`, ahead of the systems the rest of this screen
depends on. It picks from a hard-coded list of eleven units and places them in
the six formation slots — the same grid the fight is resolved on, drawn with
the front line on the right, as the arena draws it.

- **Placing** — tap a unit and tap a slot, or drag it across. Both land on
  `PartyFormation`, which keeps one unit per slot and one slot per unit, so a
  drop onto an occupied cell swaps rather than overwrites.
- **Dispatch** — encodes the formation into `/battle?party=…`, so a composed
  party is a link that survives a reload. `buildRoster` stands it up as
  combatants; a party that names nobody it recognises falls back to the
  authored one.

Not built yet: dungeon selection, trait conflicts, composition score, RQS, and
skill selection. Skills are whatever the unit was authored with — when skill
selection lands it belongs on this screen, on the unit being placed.
