# Milestone 10: Visual feedback

## Goal

Two visible additions: a health bar above each unit that shrinks as the unit takes damage, and floating damage numbers that appear above the target on each hit, drift upward, fade out, and disappear.

## Scope

- A health bar (background + foreground fill) above each combatant.
- A consumer that reacts to damage events by spawning a short-lived text object at the target's location showing the damage amount.
- A short-lived "lifetime" mechanism: any object marked with a lifetime ticks down and is removed when expired.
- Behaviors for damage numbers: drift upward, fade alpha over the lifetime.

## Design Decisions

- **Health bars are children of the combatant.** They follow the unit automatically because of the parent-child spatial relationship. When the combatant is removed, the bar is cleaned up with it.
- **The health bar has two pieces: a fixed background and a shrinking fill.** Both anchored on the same edge (e.g., center-left) so the fill shrinks from the right toward the left as health drops, leaving the background's right side exposed.
- **Bar dimensions derive from the unit's own size.** Don't hardcode the bar's width separately from the combatant's width — derive from a single source. Editing the unit's sprite size automatically rescales the bar.
- **Health bar updates are reactive, not polled.** When a unit's health changes, an update routine resizes the fill. Frames where nothing changes do no work.
- **Damage numbers are top-level objects, not children of the target.** If they were children, the kill-shot number would disappear when the target dies (recursive cleanup). Top-level objects with their own lifetime escape this.
- **The lifetime mechanism is generic.** Anything that needs to "exist for N seconds and then disappear" uses the same mechanism: a timer ticks, a removal routine despawns at expiry. Damage numbers, future particle effects, future projectiles all reuse it.
- **Drift and fade are separate behaviors per concern.** Drift mutates position; fade mutates color alpha. Splitting them means future variations (different drift patterns, no fade, etc.) are configurable per object type.

## Observable Behavior

- Enter gameplay; watch a fight.
- Health bars sit above each unit and shrink visibly as damage lands.
- On each hit, a number appears at the target's position showing the damage dealt.
- The number drifts upward over about a second, fading to transparent, then disappears.
- Bars disappear cleanly when their unit dies (no leftover bars on the field).
- Damage numbers from the killing blow still appear and complete their animation even though the target is gone.

## Out of Scope

- Different colors per damage type, crit indicators, big number animations on heavy hits.
- Sound effects.
- Hit pause / screen shake.
- Critical hit indication, miss/dodge text.

## Verification

- Color coding: bar background and fill use clearly distinguishable colors (e.g., red background, green fill).
- The fill matches the unit's `current / max` health ratio at all times.
- A unit at half health shows a half-filled bar. A unit at 1 HP shows a sliver.
- Damage numbers never persist past their stated lifetime; the scene doesn't accumulate stale text objects.

## Porting notes

- **Health bars in Godot** are typically child `Control` or `Sprite2D` nodes positioned above the parent, updating a `size` or `scale` based on the health property.
- **Damage numbers in Godot** are `Label` or `RichTextLabel` nodes spawned at world position, with a `Tween` for the drift/fade. Or use a one-shot animation player. The lifetime can be a `Timer` that calls `queue_free()` on timeout.
- The "anchor on the left" detail for the fill is universal across engines — make sure the anchor/pivot of the fill graphic is on the side that should stay put when shrinking.
