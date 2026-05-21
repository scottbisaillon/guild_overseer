# UI — Guild Hall

The main hub screen. Top-down tile view with wandering member sprites and clickable facility tiles. All management navigation begins here.

**Depends on:** [[../systems/members]], [[../systems/economy]], [[../systems/reputation]]

---

## Components

- **Navigation bar** — tab switching between Guild Hall, Dungeons, Tavern, Armory. Currency display reading from live state.
- **Tile map** — `bevy_ecs_tilemap` top-down floor. Facility tiles with distinct tile IDs. Member sprites wander on the grid. Notification badges on facilities when attention is required.
- **Member roster panel** — sidebar list: role, level, morale bar, fatigue indicator, status. Click to open member detail.
- **Member detail** — full stats, traits, gear slots, entry point to [[skill-editor|Skill Editor]].
- **Events feed** — scrolling log of recent guild events (run completions, morale alerts, level-ups, drama events). Fixed-size ring buffer, last 20 entries.
- **Status bar** — guild rep progress, active member count, runs in progress, average morale, loot awaiting distribution.
- **Notification badges** — sprite overlay entities spawned when actionable items exist (loot awaiting, tavern refreshed, drama event pending).

---

## Implementation Notes

### Bevy

Hub management screens are rendered with `bevy_egui`. Panels (`SidePanel`, `TopBottomPanel`) contain the roster and events feed. The tile map is a separate Bevy rendering layer beneath the egui overlay.

Notification badges are sprite entities added and removed by a system reading `Res<GuildHall>` and `Res<GuildStash>` for pending actions — no manual badge tracking.

### Flutter + Flame
The guild hall hub is a Flutter screen. `NavigationBar` or `NavigationRail` handles tab switching (adapts between mobile and tablet automatically). Currency display is a `Consumer` widget watching `EconomyCubit`.

The tile map is a `CustomPainter` or a grid of `Container` widgets for the vertical slice — no Flame involvement. Facility tap targets are `InkWell` wrappers. Member wandering sprites can be `AnimatedPositioned` widgets or small `SpriteWidget` instances from Flame embedded via `GameWidget` if animated sprites are needed.

The events feed is an `AnimatedList` consuming entries from `GuildCubit` state as they arrive — entries slide in automatically. Member roster uses `ListView.builder` with `BlocBuilder` scoped per tile.
