# UI — Loot Distribution

Post-run screen. Presents loot generated during the run and handles assignment to member gear slots.

**Depends on:** [[../systems/loot]], [[../systems/traits]], [[../systems/members]]

---

## Components

- **Run summary** — clear/wipe result, XP earned, item count, drama events that fired, reputation gained.
- **Loot list** — all items in the run stash. Rarity colour-coded. Goblin-claimed items flagged distinctly.
- **Goblin claim dialog** — appears for each Goblin-claimed item. Allow / Override. Override assigns to the best-fit member for the item's class type.
- **Member assignment** — select an item, select a member, confirm. Shows the member's current gear slot state for comparison.
- **Auto-Loot rules toggle** — enables/disables pre-set priority rules configured per member.
- **Disenchant** — available per item. Converts to Essence immediately.

---

## Implementation Notes

### Bevy

The loot list reads from `Res<GuildStash>`. Assignment writes a `LootAssigned` event. Goblin claim resolution writes `GoblinClaimResolved`. All downstream effects (gear slot updates, morale changes, Essence gain) are handled by systems reading these events — the UI only fires events and reads current state.

### Flutter + Flame
A Flutter screen. `Draggable<ItemInstance>` on item cards and `DragTarget` on member gear slot widgets — Flutter's built-in drag-and-drop handles assignment with no custom gesture logic.

Goblin claim dialogs are `showDialog()` calls triggered by `BlocListener` watching `GameBloc` for `GoblinClaimed` state changes. Resolution buttons dispatch `GoblinClaimResolvedEvent` back to `GameBloc`.

The run summary at the top reads from `RunSummary` in `GuildCubit` state populated after the run ends.
