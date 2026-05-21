# UI — Tavern

Recruit pool display. Available before and after guild founding. Pre-guild: the shared public pool. Post-guild: the guild's private pool (if Tavern facility built), with the shared pool still accessible.

**Depends on:** [[../systems/members]], [[../systems/traits]], [[../systems/reputation]], [[../systems/economy]]

---

## Components

- **Pool list** — each recruit shows name, class, level, trait badges (colour-coded by type: green positive / red negative / amber neutral), rarity indicator, and Gold hire cost.
- **Rare combo highlight** — recruits with two or more synergistic traits flagged with a distinct visual treatment.
- **Recruit detail** — selected recruit shows full stat breakdown, trait interaction preview against the current party, synergy/conflict warnings.
- **Refresh timer** — countdown to next pool refresh. Shared pool: fixed timer. Guild Tavern: can be accelerated with Crystals.
- **Hire button** — deducts Gold, adds member to roster, removes from pool.

---

## Implementation Notes

### Bevy

The pool is a `Res<TavernPool>` resource holding generated recruit data. A timer in that resource is decremented by `Res<Time>` each frame, regenerating the pool on expiry. The hire action writes a `HireRecruit` event consumed by the member spawning system and the currency deduction system.

Trait interaction previews are computed inline in the egui render system by calling the same conflict evaluation logic used by the [[party-composer|Party Composer]] — no separate system or caching needed.

### Flutter + Flame
A Flutter screen with a `GridView.builder` of recruit cards. Each card is a stateless widget reading from `RecruitmentCubit` state.

Trait interaction preview calls `TraitEngine.evaluateParty()` inline in the card build method — pure Dart, no async needed. Hire action calls `ref.read(guildCubit.notifier).hireRecruit(recruit)`, which updates state and triggers a widget rebuild automatically via `BlocBuilder`.

The refresh timer is a `StreamProvider` that ticks every second, updating the countdown display. `nextRefreshAt` persists in Hive across sessions.
