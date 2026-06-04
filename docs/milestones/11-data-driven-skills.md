# Milestone 11: Data-driven skills

## Goal

Skill definitions live in a single data file (RON, JSON, or whatever the engine supports). At startup the file is loaded into memory and indexed by skill ID. Combatants reference skills by ID; a factory function materializes the runtime skill objects from the data. Editing a skill's damage in the file changes balance without touching code.

## Scope

- A skill data type matching the runtime skill's parameters: id, name, damage, cooldown.
- A single data file (e.g., `assets/skills.ron`) containing every skill keyed by ID.
- A loader that reads the file at startup and exposes its contents as a queryable singleton.
- A factory function that takes a skill data record and constructs the runtime skill (the same components/properties that were previously hardcoded).
- The scene-spawning code now looks up skills by ID and calls the factory; no skill values appear inline in the spawn code.

## Design Decisions

- **One file, not one file per skill.** Easier to author, easier to scan, easier to version-control. Splitting into per-skill files is reserved for when the manifest grows beyond a few dozen entries or when mods need to drop individual files.
- **Keyed by ID, not ordered list.** A map/dictionary at the top level lets the spawn code reference skills by name (`"basic_attack"`) instead of position. Order doesn't matter.
- **Loading is gated by a loading screen.** Gameplay doesn't start until the manifest is fully loaded. This is the same pattern used for any required asset (textures, audio).
- **Materialization is a single function.** One place — the skill factory — knows how a data record becomes runtime components. If the data shape changes (rename `base_damage` to `damage`), only the factory changes; consumers don't notice.
- **The data shape doesn't need to mirror the runtime shape exactly.** The data can carry author-friendly names; the factory translates. A field like `cooldown_seconds` in the data becomes a `Timer` with appropriate duration in the runtime.
- **Missing IDs fail loudly.** If the spawn code references a skill ID that doesn't exist in the manifest, crash with a clear message at the point of lookup. Silently spawning nothing makes content bugs hard to find.

## Observable Behavior

- The game behaves identically to before — same skills, same damage, same rotations.
- Editing `damage: 1.0` to `damage: 5.0` in the data file and restarting the game produces noticeably faster fights.
- Adding a new skill to the file (with a new ID) makes it available for assignment. (Actual assignment happens elsewhere; for now, picking it up requires modifying the spawn code.)

## Out of Scope

- Hot reload during play (though if the engine supports it for assets, you may get this for free).
- Validation tools that check all referenced skill IDs exist before runtime.
- Authoring UI / skill editor.
- Skill effects beyond damage (still just a damage number).

## Verification

- Comment out a skill in the data file and observe: the game loads (with a working subset), then crashes loudly when spawn code tries to reference the missing ID.
- The spawn code contains no literal skill values (damage amounts, cooldowns). All numbers come from the file.

## Porting notes

- **In Godot**, skills are typically authored as `Resource`-deriving scripts. A single resource file (`.tres` or `.gd`) can hold an array or dictionary of nested resources. Loading is via `load("res://data/skills.tres")` or `ResourceLoader`. The asset system handles caching and lifecycle.
- **In Unity**, the equivalent is `ScriptableObject` for each skill, optionally indexed by a singleton catalog. The pattern is the same: author data once, load once, reference by ID at spawn time.
- The key architectural property — **a single materialization function that converts data to runtime objects** — is engine-agnostic. Avoid scattering the "build a skill" logic across multiple call sites.
