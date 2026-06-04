# Milestone 3: Debug inspection

## Goal

On a key press, the game prints a snapshot of every combatant's state to the developer console.

## Scope

- A trigger (key press) that fires while in the gameplay scene.
- A routine that walks every combatant and emits a line per unit describing it (name, faction, current state).
- Output goes to the developer console or log, not in-game UI.

## Design Decisions

- **Inspection runs only on demand.** Continuous logging would spam the console and obscure other output. A discrete keypress (e.g., `L`) is the trigger.
- **Inspection is scoped to the gameplay scene.** Pressing the key on the title screen should do nothing — the inspection logic is gated on being in the gameplay state.
- **Output is human-readable.** Each line should be readable at a glance, with name and faction explicit. As more state is added (target, health, cooldown), it joins the same line or one additional line per unit.
- **The inspection routine reads only — no side effects.** It should never mutate game state. This makes it safe to bind to any key without worrying about accidentally changing things.

## Observable Behavior

- Enter gameplay; press `L`.
- The console prints one line per combatant, including a name and faction.
- Press `L` again later; the output reflects the *current* state (positions, factions, anything else added later).

## Out of Scope

- Visual debug overlays (text rendered in-world).
- An in-game inspector or HUD.
- Changing state via the debug interface.
- Different keys for different views.

## Verification

After future milestones add new state (target, in-range flag, health), this same key reveals the new state without code changes to the keybinding itself. The inspection routine is the lens through which you'll diagnose the next several milestones.

## Porting notes

Most engines have built-in debug print/logging. The trigger and gating are the only design decisions; the routine itself is trivial. In Godot, an `_input` handler that checks for the key and walks all combatant nodes is the natural shape.
