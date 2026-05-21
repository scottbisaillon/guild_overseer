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
