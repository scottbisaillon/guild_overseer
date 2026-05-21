# UI — Skill Editor

Per-member skill tree and rotation builder. Accessible from the member detail panel. Shows live RQS preview against the currently selected dungeon.

**Depends on:** [[../systems/skills]], [[../systems/rotation]], [[../systems/traits]]

---

## Components

- **Skill tree node graph** — drawn with `egui::Painter`: edges as lines, nodes as labelled clickable rectangles. Unlocked nodes highlighted; locked nodes dimmed with point requirement shown. Click to invest or refund.
- **Invest / Refund** — invest costs one Skill Point. Refund costs 15 Essence per point. Full respec requires Training Grounds Tier 2+ and costs 200 Essence.
- **Rotation builder** — 6 ordered slots for Active skills. Drag-to-reorder. Separate always-active section for Passive, Reactive, and Aura skills (these do not need to be slotted).
- **Live RQS preview** — recalculated every frame the editor is open. Score 0–100 with factor breakdown. Colour-coded bar from red (poor) to green (optimal).
- **Dungeon context toggle** — preview RQS against different dungeon types to compare how a rotation performs across content.
- **Trait conflict warnings** — known negative trait interactions with the current rotation flagged with plain-language explanation (e.g. "Speedrunner: truncates last skill in a 6-slot rotation").
- **Member tab switcher** — switch between party members without leaving the editor.

---

## Implementation Notes

### Bevy

RQS preview calls `evaluate_rotation()` — a pure function with no ECS dependencies — directly inside the egui render system each frame. Immediate-mode means this is recalculated on every draw, which is negligible cost for a small struct.

Invest and refund write events consumed by a system that modifies the member's skill tree component and deducts from `Res<Currencies>`. The Training Grounds tier check is a read against `Res<GuildHall>` — no special system needed.

### Flutter + Flame
A Flutter screen. The skill tree node graph is a `CustomPainter` — edges as `Path` objects, nodes as `Rect` shapes with `GestureDetector` overlays for tap handling. `InteractiveViewer` wraps the graph for pinch-zoom on mobile if the tree is large.

The rotation builder is a `ReorderableListView` for the 6 active skill slots — Flutter provides drag-to-reorder natively on both touch and mouse with correct accessibility support. The always-active passive section is a non-reorderable `ListView` below it.

RQS preview calls `rotation_evaluator()` inside `build()` — the function is pure Dart, fast enough to call on every rebuild. The result drives a `LinearProgressIndicator` and a factor breakdown below it. `BlocBuilder` triggers a rebuild on every slot change.
