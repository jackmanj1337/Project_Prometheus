---
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: SAC-1..12
Resolved-in: 2026-06-27d
---

# `shop` + `activate` Interactive Configs + On-Map Object Model — A5 — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). **Sixth A5 sub-item** (after `[DTH]`, `[DIF]`, `[AGT §6]`,
`[BEA]`, `[LDC]`). Owns the **on-map mechanic** for shops/levers/panel-triggers (the `[SHP-4b]`
battlefield-shop + generic `[VIL-2]` `activate`), firms the **`[PHB]` dual-surface contract**, and —
owner call 2026-06-27d — **fully designs the parked dynamic-shop dimensions** (`[SHP §4]`). Branch
`docs-reorg-2026-06-23`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## Substrate reality (most of this already exists)
- **`[DCH]` already built the shared pieces:** a unified **`map_objects`** model (`{type, id, tile,
  key_item_id, loot, locked}`, DCH-2) surfaced via the **already-reserved `activate` `TileActions` verb**
  (`scripts/shared/TileActions.gd`). Opened-state is per-map.
- **`[VIL-2]`** (RESOLVED) is the **player-initiated** trigger: a `TileActions`/action-menu entry gated
  like Seize/Escape → fires a MET interactive trigger carrying the target ref. `visit`/`talk`/`shop`/
  `activate` are its configs.
- **`[SHP-1..5]`** firmed the shop economics (resource-keyed cost/yield; `[SHP-4b]` battlefield
  destination = buy→accessing unit, overflow→convoy). **`[SHP §4]`** parked the dynamic dimensions.
- So this item = **assemble + unify**, plus the shopper subject + the dynamic-shop build.

---

## Unified on-map object model

## [SAC-1] One unified `map_objects` model — **RESOLVED**
`activate` **generalizes** `[DCH]`'s `map_objects`/activate-verb model. **Doors/chests** are specialized
object types; **levers/switches/shop/arena/panel-triggers** are author-defined ones — **all `map_objects`
with an `activate` behavior + F16 gate + F6 persist + the `[VIL-2]` player-initiated trigger**. No
parallel system (the `[DCH]` register's doors/chests become specializations — cross-ref added there).

## [SAC-2] Each `activate` instance carries its own author label — **RESOLVED (owner)**
**Owner:** every `activate` behavior on a map_object declares **its own label**, so a tile offering
**multiple** activatables (e.g. a square that is both a shop and a lever) surfaces **distinct,
unambiguous action-menu entries** rather than one generic "Activate". Generalizes the `TileActions`
label. A map_object may host several labeled `activate` behaviors.

## [SAC-10] Action economy = consumes the action (like Visit/Unlock), optional author `free` flag — **RESOLVED**
Activating a map_object **consumes the unit's action** by default (the `[VIL-2]`/Seize/Unlock standard),
with an **optional author `free` flag** for trivial interactions (a flip-and-keep-moving lever).

## [SAC-11] Gating + persistence — reuse — **RESOLVED**
An F16 `[REQ]` requirement gates the entry's availability (**hidden vs shown-disabled**, author's choice,
per `[VIL-6/7]`); **F6** flags persist fired/used/toggled state (`once` latch, `[MET-5]`, already
reserved). No new gating/persistence machinery.

---

## Panel-triggers (the `[PHB]` dual-surface contract)

## [SAC-3] A panel-trigger = a map_object whose `activate` opens a `[PHB]` panel — **RESOLVED**
shop/arena/convoy/etc. on-map = a `map_object` whose `activate` **opens the same `[PHB]` panel as prep**,
fed by the trigger's config (**one panel UI, two callers** — prep node *or* map trigger). Confirms the
`[PHB]` dual-surface note: a panel is defined once, surfaced two ways. (Deploy/Save/Begin-Battle stay
prep-only.)

## [SAC-4] Per-instance variation = inline on the map_object + optional named-ref — **RESOLVED**
The map_object carries the panel's per-instance variation **inline** (this shop's stock, this arena's
opponent table — matching `[DCH]`'s inline `{loot, key_item_id}`), with an **optional reference to a
named pack config** for reuse across tiles. Inline for one-offs, named-ref for shared.

---

## The shopper subject (owner refinement 2026-06-27d)

## [SAC-5] Every shop session assumes a **shopper** — **RESOLVED**
A shop always has a **shopper** (a specific unit doing the shopping):
- **On-map:** the **activating/visiting unit** (the `[SHP-4b]` accessing unit).
- **Prep:** a unit the player **selects first**, before the shop panel opens.
The shopper is the **F16 context subject** (REQ-3-style, like dialogue's `speaker`) that the dynamic
dimensions (SAC-7/8/9) resolve against — this is what makes "who is shopping" pricing/stock work. One
shopper per session; re-select to change.

## [SAC-6] Destination unification = buy→shopper, overflow→convoy (all shops) — **RESOLVED**
Because **prep now has a selected shopper too**, the `[SHP-4b]` rule becomes the **single destination
rule for all shops**: **buy→shopper, overflow→convoy** — collapsing `[SHP-4]`'s prep-vs-battlefield
branch. *(An author may still route a prep shop's purchases straight to convoy for bulk buying — an
optional per-shop override.)* Updates `[SHP-4]`.

---

## Dynamic-shop dimensions — **full design + build now (owner)**

## [SAC-7] Dynamic pricing = per-entry `requirement → modifier` over the shopper — **RESOLVED**
The resource-keyed cost/yield (`[SHP-1]`) gains an **optional per-entry `price_requirement → modifier`**,
the modifier a **`[REQ-16]` arithmetic value-term over the shopper subject** — e.g. *better prices for a
high-Charm shopper* = `price = base × f(shopper.charm)` (the REQ-16 "scale a magnitude by a derived
number" worked example). Author-optional; default = flat base price.

## [SAC-8] Conditional stock = per-entry F16 gate over the shopper — **RESOLVED**
Each stock entry carries an **optional F16 gate over the shopper** (a trait, a *membership-card* item, an
`[F6]` flag), reusing the **hidden vs shown-disabled** model from `[VIL-6/7]` + `[DLG-14]` — member-only
stock, secret shops, flag-revealed wares. Author picks hidden or shown-disabled per entry. No new gating
machinery.

## [SAC-9] Dialogue integration = `shop` as a `[DLG]` command — **RESOLVED**
A shop can be **entered via / wrapped in a `[DLG]` conversation** (shopkeeper banter, haggling): `shop`
is a **dialogue `command`**, and a conversation may launch the `[VIL-2]` `shop`/`activate` trigger.
Reuses the F15 entry model + F16 branch gating; **the shopper carries into the DLG context** as a subject.
No shop-specific conversation code.

---

## [SAC-12] Save / F1 — **forward to Phase B (F1 lock)**
Per-map **map_object opened/used/toggled state** is already reserved (`[DCH]` opened-state + `[MET-5]`
`map_events_fired`). **No new per-unit save.** Shop stock/labels/variation/dynamic configs = **campaign
content/authoring**, not save. The **shopper is a session-scoped selection**, not persisted.

---

---

## Forward (INVESTIGATE, not part of the resolved SAC scope) — scene-backed activities / mini-game module seam
**Owner 2026-06-28: don't architecturally block arbitrary mini-games** (blackjack/roulette · a
flappy-bird/pac-man/galaga clone · memory-match · mazes · QTEs · sliding-block / logic-gate puzzles …)
inside prep panels or on-map activities. These are **arbitrary interactive code**, NOT data configs over
the tactical engine — so they need a *module* seam, not more config. **Almost certainly post-v1**, but the
seam is cheap to reserve. **Three disciplines to bake into the `[SAC]`/`[PHB]` build:**
1. **Scene-backed activities, not a closed type-switch.** Treat every panel/activity as **"launch a scene,
   take a result"** — the built-in shop/arena panels are the engine's own scenes; a mini-game is the same
   path with an authored scene. (Same closed-enum lesson as `[TCV-4]` objectives / `[AIP]` profiles.)
2. **A generic result→effect bridge.** A mini-game is a **black box** launched with a **context**
   (player unit/shopper · param dict · stakes · `[TCV]` vars) that returns a **typed result**
   `{outcome, score, payload}`; the host maps it to **existing effects** (gold/EXP/items/flag/`[TCV]`
   var/`[MET]` action/objective). The engine never needs to know what the game *is*.
3. **Open activity registry** — a pack declares "activity X = scene Y"; not a hardcoded list.
4. **Launch surfaces are plural.** The shared primitive is `launch_activity`: prep buttons, on-map
   `activate` triggers, dialogue `command`s, and `[MET]` story/map-event actions all call the same
   registry entry with caller-specific context. Do not make minigames prep-only or shop-only.
**Local-only** (presentation layer; no determinism/lockstep burden — online D6 precedent), **atomic save**
(like the arena), host validates **reward bounds** (no-anti-cheat, D18). **The one hard, deferred
decision = code trust:** loading a mini-game = loading arbitrary `.gd`/`.tscn` from a pack, which crosses
the content-pack "**raw-load art only**" boundary (`[ICO-5]`). First-party/future-dev games = trivial
(res://); **modder packs with code** = a real security boundary → future call between
first-party-whitelist / restricted-sandbox / accept-with-warning. Composes `[EXT]` (the seam is "engine
provides the launch+result primitive; packs provide the scene") + the campaign-content-pack model.
Mirror-pinned: scope-map #23. Research note:
[`design/minigame_scripting_runtime_research_2026-06-28.md`](../design/minigame_scripting_runtime_research_2026-06-28.md).

## Cross-refs
- **`[VIL-2]`** (trigger substrate) · **`[DCH]`** (the `map_objects` model + specialized door/chest types)
  · **`[SHP-1/4/4b/§4]`** (economics, destination, dynamic dims) · **`[PHB]`** (panels + dual-surface) ·
  **`[REQ-16]`/REQ-3** (dynamic pricing + the shopper subject) · **`[VIL-6/7]`/`[DLG-14]`** (gating model)
  · **`[DLG]`/F15** (dialogue-wrapped shops) · **`[MET]`** (action vocabulary) · **F6** (persistence).
- **`[BEA]`** arena/bonus-EXP panels are placeable on-map by the same SAC-3/4 mechanism.
