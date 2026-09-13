# Guild Overseer — Flutter + Flame

Scaffold for the Guild Overseer client, plus a playable mockup of the battle
scenario the active dungeon is built on.

Design docs live in [`../docs`](../docs). The Flutter + Flame notes at the end of
each system document describe the architecture this scaffold follows.

## Toolchain

| | |
|---|---|
| Flutter | 3.47.4 (stable) |
| Dart | 3.13.3 |
| Flame | 1.38.2 |
| State | `flutter_bloc` 9.1.1 |
| Routing | `go_router` 18.0.1 |

Platforms generated: Android, iOS, Linux, macOS, Windows, web.

```bash
flutter pub get
flutter run                        # any connected device
flutter test                       # unit + widget tests
flutter analyze                    # lints
dart run tool/simulate_battle.dart # the same fight, headless, in the terminal
dart run tool/record_fight.dart    # re-record the golden fight transcript
```

## The battle mockup

Open the app and press **Open battle mockup** (or navigate to `/battle`).

Six party members stand in a 3x2 grid on the left, six dungeon inhabitants in
the mirrored grid on the right. Column 0 is the front line for both sides.
Nobody moves: every unit holds its slot, picks a target across the centre line,
and fires its rotation until one side is gone.

What the mockup demonstrates:

- **Formations.** Both sides share one grid shape, mirrored, so "front line" and
  "back line" mean the same thing on either side of the arena.
- **Targeting priorities.** Nearest, weakest, frontline, backline, and
  healer-first are all in play — the Hexweaver hunts the party healer across the
  arena while the ghouls chew on whoever is closest. Target lines can be toggled
  on to see every decision at once.
- **Rotations on a global cooldown.** Every unit acts on a one second beat. It
  fires the first skill in its list that is off cooldown and has something to
  hit; the basic attack fills the gaps. A heal with nobody wounded is skipped
  rather than wasted.
- **Skill shapes.** Single-target, column AoE (Cleave), and healing, delivered
  as melee lunges, projectiles or beams.
- **Death and resolution.** Units drop out, their killers re-target, and the
  fight ends when one side is wiped.
- **Transport controls.** Pause, 0.5x–4x speed, and restart. The simulation is
  seeded, so a restart replays the same fight exactly.

### Deliberately not in the mockup

Movement and steering, threat tables and aggro break, QTEs, traits, buffs and
debuffs, damage types or armour, finisher sequences, art. Units are coloured
squares. Skills are authored in Dart rather than loaded from data. Nothing here
is balanced; the numbers exist to make the rhythm visible.

## Layout

```
lib/
  main.dart
  src/
    app/                         shell: MaterialApp, router, theme
    core/
      domain/                    vocabulary shared across features
                                 (faction, role, target priority, snapshots)
        stat.dart                the stats anything is allowed to change
        stat_modifier.dart       one change, and what granted it
        stat_block.dart          the pipeline gear and buffs both feed
      events/game_event.dart     the sealed GameEvent hierarchy — one bus
    features/
      home/view/                 landing screen
      battle/
        domain/                  the fight, as pure Dart
          arena_layout.dart      where formation slots sit
          skill.dart             skill definitions and live cooldowns
          combatant.dart         a unit that fights
          targeting.dart         who to hit
          rotation.dart          what to fire
          battle_simulation.dart the tick loop and the event stream
        data/mock_roster.dart    the twelve units of the mockup
        game/                    Flame: renders the fight, owns no rules
        bloc/                    GameEvent stream -> HUD state
        view/                    Flutter HUD over the GameWidget
tool/simulate_battle.dart        headless runner
tool/record_fight.dart           re-records the golden transcript
test/core/                       the stat modifier pipeline
test/battle/                     targeting, rotation and simulation tests
test/battle/goldens/             the recorded fight the tests compare against
```

### How the layers fit

`BattleSimulation` holds the rules and has no dependency on Flame or Flutter —
it is driven by `update(dt)` and publishes everything it decides to a broadcast
`Stream<GameEvent>`. `BattleGame` (Flame) calls that `update` from the engine
loop and reacts to the events by spawning lunges, projectiles and floating
numbers. `BattleBloc` consumes the same stream to build HUD state, and is the
only thing that reaches back into the simulation, when the player pauses or
restarts.

That split is what lets `tool/simulate_battle.dart` and the tests run the exact
fight the game renders, with no engine attached.

Continuous state (health, cooldowns) arrives on a 10 Hz `BattleSampled` event
rather than per frame; discrete facts (damage, deaths, re-targeting) arrive as
they happen and become combat log lines.

### The golden fight

`test/battle/golden_fight_test.dart` runs the mock roster to the end and
compares every decision the simulation published against a recorded transcript
in `test/battle/goldens/`. It is the net that makes refactoring safe: change how
the code is organised and the transcript should not move, so any diff is either
a bug you just introduced or a change you meant to make.

```bash
flutter test test/battle/golden_fight_test.dart
```

When a change is *meant* to alter the fight, re-record it and read the diff
before committing — the diff is the review:

```bash
dart run tool/record_fight.dart
git diff test/battle/goldens/
```

The transcript is plain text rather than a hash so that a failure says which
beat of the fight moved, not merely that something did. It holds because the
fight is a pure function of its roster and its seed: the same roster resolves
identically twice in a row, after a restart, at any frame rate, and at any speed
setting. Those four properties are themselves tested alongside the golden — if
one breaks, the golden stops being evidence of anything, so it is worth knowing
first.

One caveat: the guarantee is a Dart VM one. `flutter test` runs on the VM, which
is where `dart:math`'s seeded `Random` is stable. Run the suite compiled to
JavaScript (`--platform chrome`) and the golden may legitimately differ.

## Deployment

`.github/workflows/pages.yml` builds the web client and publishes it to GitHub
Pages. Pages is set to deploy from GitHub Actions.

Pushes to `main` build and deploy. Pushes to `impl/flutter` build, analyze and
test, then stop: the `github-pages` environment only accepts deployments from
the default branch, so the deploy job is gated on `main` rather than attempting
a publish that GitHub will reject. To publish from another branch, add it under
Settings -> Environments -> github-pages -> Deployment branches, and relax that
gate.

Two details make a project page work, both handled by the workflow:

- **`--base-href /guild_overseer/`** — a project page is served from a
  subdirectory, and without this every asset request goes to the domain root and
  the page comes up blank.
- **`404.html`** — Pages serves it for any path it has no file for, so copying
  `index.html` over it means a refresh on `/battle` boots the app on that route.
  This is what `usePathUrlStrategy()` in `main.dart` needs in order to use real
  paths instead of `/#/battle`.

The build also passes `--no-web-resources-cdn`, which bundles CanvasKit with the
site instead of fetching it from `gstatic.com` at runtime. Drop that flag to use
Google's CDN and shave a few MB off the deploy.

To reproduce a deploy build locally:

```bash
flutter build web --release --base-href /guild_overseer/ --no-web-resources-cdn
cp build/web/index.html build/web/404.html
```

Serving `build/web` at the domain root will 404 on its assets — it expects to
live under `/guild_overseer/`. For a plain local run, build without `--base-href`.

## Next steps

The natural follow-ons, in the order the design docs suggest:

1. Move skill and unit definitions into JSON assets behind a `DataRepository`.
2. Give the simulation a threat table so enemies pick targets by aggro rather
   than by distance alone.
3. Add movement, so units close on their targets instead of standing in a grid.
4. Layer QTEs over the fight as Flutter widgets positioned from world space.
