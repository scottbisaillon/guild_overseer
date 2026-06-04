# Milestone 1: One square on the screen

## Goal

When the gameplay scene loads, a single visible colored square appears at a specific position. It disappears when the scene exits. Nothing moves, nothing behaves.

## Scope

- A gameplay scene that the player can enter from a title or menu.
- A single visible object inside that scene with a known position.
- Automatic cleanup of that object when the scene unloads.

## Design Decisions

- **The scene has one logical root.** A single container object owns the scene's contents. Everything spawned for gameplay either lives under this root or carries a lifecycle marker tying it to the scene state.
- **Visible content is data, not code.** The square is parameterized by color, size, and position — values that should be easy to change without restructuring.
- **Lifecycle is explicit.** The square is cleaned up automatically when the scene exits, either through scene-level cleanup, parent-child relationship to the root, or an explicit despawn-on-exit marker. Whichever mechanism is used, it must be consistent across the project.

## Observable Behavior

- Launch the game, navigate to the gameplay screen.
- A single colored square is visible at the expected position (e.g., near screen center).
- Return to the main menu or close the scene — the square is gone (no leaking entities).

## Out of Scope

- Multiple objects.
- Categorization (ally vs enemy).
- Behavior, movement, input handling.
- Sprites, images, or animations — a solid color is enough.

## Verification

The scene transition is reversible: you can enter, exit, and re-enter without artifacts piling up or graphics persisting on the wrong screen.
