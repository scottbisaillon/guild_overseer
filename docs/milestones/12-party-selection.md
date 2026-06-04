# Milestone 12: Party selection screen

## Goal

A new screen between Title and Gameplay where the player browses a list of available "members" (loaded from a data file) and selects up to four to form their party. The selection is saved to a singleton that persists into Gameplay, where the chosen members are spawned as the player's allies. Enemies stay hardcoded.

## Scope

- A new screen state (`Selection`) inserted between Loading and Gameplay.
- A members data file (`members.ron` or similar) with each member's stats and a list of skill IDs.
- A loader and singleton for the members manifest (same pattern as the skills manifest).
- A singleton (`PartySelection`) that holds the chosen member IDs; populated on the selection screen, read by Gameplay.
- A simple, text-based UI on the selection screen: list of available members, each toggleable; a "Selected: N / 4" counter; a Start button.
- A member-materialization function (`spawn_member`) that takes a member's data plus the skills manifest and spawns the full combatant — skills as children, stats applied — at a given position and faction.
- Updated gameplay spawn logic that reads the party selection, spawns the chosen members as allies, and spawns a fixed enemy set on the opposing side.

## Design Decisions

- **Members are templates, not unique instances.** A member's data is the recipe; spawning produces fresh runtime objects. Two units can both be "Warrior" if the same ID appears twice in a party — they're distinct combatants instantiated from the same template.
- **Members are implicitly allies in this slice.** The data file doesn't carry a faction field; the spawn code assigns `Faction::Ally` to all selected members. If enemies later come from a manifest too, faction either becomes part of the data or is decided by the spawning context (encounter, level).
- **Each member references skills by ID.** A member entry lists skill IDs from the skills manifest. The materialization function looks each up and instantiates them as the member's owned skills. This is the same pattern as `spawn_level` referencing skills directly, just one indirection deeper.
- **The selection is a singleton, not a per-entity state.** A simple `PartySelection` object holding `Vec<String>` (or fixed-size array of optional IDs) is the cleanest way to carry data across a screen transition. Avoid per-entity carry — there are no entities yet at selection time.
- **The selection screen UI uses immediate-mode widgets.** The list of available members is dynamic (driven by the manifest), the selected count updates live, and the Start button enables/disables based on selection state. Immediate-mode (e.g., egui) handles this with less ceremony than retained-mode UI. The selection screen is one update function.
- **Members are listed in the manifest as a map keyed by ID**, identical to skills. Order doesn't matter; references are by ID.
- **The Start button transitions to Gameplay unconditionally** once at least one member is selected. Stricter rules (e.g., "exactly four required") are polish for later.

## Observable Behavior

- Launch the game.
- Main menu shows Play. Click it.
- Loading screen appears briefly, then the Selection screen.
- The Selection screen shows a list of member names. Clicking toggles each one's selected state.
- A counter reads "Selected: N / 4" and updates as the player toggles.
- A Start button transitions to Gameplay when clicked.
- Gameplay spawns the selected members on the ally side and a fixed enemy roster on the enemy side. The fight resolves as in earlier milestones, but the ally composition depends on the player's choices.

## Out of Scope

- Stat display / preview of each member's stats and skills before selecting.
- Hover effects, animations, sound on click.
- Visual sprites for members in the selection screen (still text-based).
- Validating that referenced skill IDs exist in the skills manifest (a startup check is filed for later).
- Saving/loading the party across game sessions.
- Enemy variety from data — enemies are still hardcoded in this slice.

## Verification

- Editing `members.ron` to add a new member entry makes the new member appear in the selection list on next launch.
- Choosing different parties results in visibly different fights (different stat balances, different skill rotations).
- The selection state is correctly preserved across the Selection → Gameplay transition.

## Porting notes

- **Screen states in Godot** are typically separate scenes managed by an autoload `SceneManager` or by direct `change_scene_to_file()` calls.
- **Singletons that cross scenes** are autoload nodes (e.g., `PartySelection` autoload with a Vec/Array property). Persistent across scene changes by design.
- **Immediate-mode UI** isn't native to Godot; the equivalent is `Control` nodes (`ItemList`, `Button`) with signal-driven updates. The pattern shifts slightly (signals + retained widgets vs. one-function rebuild) but the data flow is the same: manifest in, selection out.
- **The materialization function for members** is the same pattern as the skill factory — one function, one place, all data-to-runtime translation. Even in node-based engines, encapsulating this into a single "build me a combatant from this data" function pays off as content variety grows.
