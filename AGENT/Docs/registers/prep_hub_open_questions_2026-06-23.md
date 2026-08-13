---
Type: register
Status: RESOLVED 2026-06-23
Last verified: 2026-06-23
Register: PHB-1..7
Resolved-in: 2026-06-23k
---

# Prep-as-Hub Firming (§3a keystone) — Player-Facing Design + Open Questions

> **2026-07-25 interaction follow-up:** the mechanical decisions here remain ratified.
> Comparative evidence and the complete responsive/player-facing option analysis are in
> [`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`](../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md)
> (`EPUX-01..07`).

> **Amended 2026-08-13 — `[PHB-5]` and `[PHB-7]` now have names in the two-primitive vocabulary.**
> The `RPD-1..18` walk
> ([`responsive_prep_deployment_open_questions_2026-08-12.md`](responsive_prep_deployment_open_questions_2026-08-12.md))
> ruled that **the deployment plan is a staged transaction whose commit point is Begin Battle** —
> which is `[PHB-5]`'s *free navigation, single commit* restated in the staged-transaction /
> snapshot vocabulary ruled the same day. **Suspend discards the stage**, which is `[PHB-7]`'s
> *no bespoke hub-suspend snapshot; re-entering prep re-derives*; campaign Retry is a snapshot
> restore through `MapLedger`. Neither ruling is changed — both are now expressed in the
> program-wide primitives, and `RPD-17`'s proposed third mechanism was rejected because these two
> already cover the case. **`RPD` cited none of this register**, and re-derived `[PHB-7]` from
> scratch; that is why this banner exists.

> **Amended 2026-07-27:** Explore is a subject-first Prep option over an open activity registry. Its
> effective activity list resolves campaign defaults → cadence changes → node add/remove/override
> patches. Prison is one Explore activity/conversation launcher. Capture does **not** fold into recruit;
> recruitment is only one authored custody outcome.

**Started:** 2026-06-23k
**Status:** Planning draft — register OPEN. The **keystone** of the v1 player-facing worklist:
convoy, shop, arena, training hall, recruit, and skirmish all plug into the hub as author-gated
**option panels**, so the hub's structure must firm before any of them.
**Source:** `player_facing_scope_map_2026-06-23.md` §3a/§4 (owner, 2026-06-23h: "NO wander-around
area — the prep screen IS the parameterized between-chapter hub").
**Revises:** the firmed prep branch **C4** (`campaign_save_player_facing_firming_2026-06-21.md`,
resolved "empty for MVP") — C4 now becomes "author-gated option panels." **Does NOT re-open** the
firmed prep core (C1–C3: deploy/bench/placement/Save/Begin Battle, `[CST-5]`).
**Feeds:** the §4a–4e designer-authoring contract (`campaign_save_expectations_and_foundations_2026-06-23.md`)
— "which prep panels does this node expose" is one of its authoring decisions.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (firmed inputs — do not re-litigate)
- **Prep exists, always, between every map** (C1). MVP contents = deploy/bench + placement +
  manual Save + Begin Battle. [CST-5] put `required_units`/`excluded_units`/`deployment_cap` on
  `CampaignData`; `player_start_tiles` stay on `MapData`.
- **Everything is a campaign** (`[CST-6]`): every map auto-wraps as a 1-node campaign; the
  progression graph is linear-degenerate now, overworld-ready later.
- **Owner cross-cutting decisions already set** (scope map §3a): no free-roam/wander area; <!-- retired-vocabulary: historical-quotation -->
  skirmish is a prep option (not free-roam); capture folds into recruit.
- **Save/resume firmed:** Continue/Load resolve to "latest between-map → prep"; suspend is the
  in-battle mechanism, not a hub concern.

## 2. What this pass produces
A player-facing spec for the hub (what the player sees/does) + the `CampaignData` schema additions
for author-gated panels — the checklist the §4a authoring contract then formalizes.

## 3. Open questions register

### [PHB-1] Hub structure — flat panel list vs named locations  **[OPEN]**
How is "the hub" presented and modeled?
- **A — Flat:** one prep screen; the node declares which option-panel buttons appear (convoy,
  shop, …). Simplest; smallest schema.
- **B — Named locations:** author defines named sub-locations per node (Town / Castle / Camp),
  each exposing a panel subset; player navigates location→location. Richer, FE-town-like; more schema.
- **C — Hybrid:** flat panel list now **+** a cosmetic `theme`/`location_label` field; structured
  navigable locations deferred until the overworld exists.
- **Rec: C** — a flat panel list is enough for the linear-degenerate graph and reuses the firmed
  prep screen; a cosmetic theme/label gives author flavor without a navigation subsystem. Promote
  to B with the overworld.
- **Resolution:** **[RESOLVED → C]** (owner 2026-06-23k) — flat panel list **+** a cosmetic
  `theme`/`location_label` per node; navigable named locations deferred to the overworld era.

### [PHB-2] Panel availability default — opt-in vs opt-out  **[OPEN]**
- **A — Opt-in:** panels OFF by default; the node declares `prep_panels: [...]`. A node with none
  = today's deploy-only prep. Explicit; matches the mandate/default philosophy (authors opt in).
- **B — Opt-out:** all panels available unless the node excludes them.
- **Rec: A** — explicit per-node panel list; least surprising, and it is the clean §4a authoring hook.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — panels opt-in; node declares
  `prep_panels: [...]`; empty ⇒ today's deploy-only prep.

> **Forward — panels are dual-surface (prep + on-map), owner 2026-06-27d.** The same option panels a node
> exposes in prep should also be **placeable on-map by map creators** as `[VIL-2]` interactive-trigger
> instances, with **per-instance variations** (a specific shop's stock, a specific arena's opponents).
> **Most non-deploy panels** qualify — shop · convoy · arena (`[BEA]`) · bonus-EXP (`[BEA]`) ·
> training-hall (#19) · recruit; **deploy/Save/Begin-Battle are the prep-only exceptions**. So a panel is
> defined once and surfaced two ways (prep button **or** map trigger). The on-map shop (`[SHP-4b]`) is the
> first instance; the **A5 `shop`/`activate` walk firms the shared panel↔trigger contract** (which panels
> are placeable, the per-instance variation schema, and how a triggered panel reuses the prep-panel UI) —
> **RESOLVED `[SAC-1..12]`** (the unified `map_objects`/`activate` model + the shopper subject).

> **Candidate future panels (INVESTIGATE — owner 2026-06-27d, "look into").** Beyond the firmed set
> (convoy/shop/arena/training-hall/recruit/skirmish), consider **side-content minigames** as additional
> prep-panel activities (hence also on-map-placeable via the `[SAC]` dual-surface): a **casino** (gold
> gambling — rides the gold ledger), **fishing**, a **multi-battle garden** (reuses `[BEA]` arena combat),
> etc. None designed/scheduled — a feasibility dive per minigame decides in/out. **Launch note:** future
> activities must not be prep-only; the shared `launch_activity` primitive should also be callable from
> on-map activations, dialogue commands, and `[MET]` story/map-event actions. Mirror-pinned in the scope
> map's INVESTIGATE list (#23) and researched in
> [`design/minigame_scripting_runtime_research_2026-06-28.md`](../design/minigame_scripting_runtime_research_2026-06-28.md).

### [PHB-3] Gating axes — what scopes a panel's availability  **[OPEN]**
The owner phrased it "available at each node / location / time." "Time" has no substrate pre-overworld.
- **A — Node-only for v1:** each progression node declares its panels. Drop time/location as axes
  until the overworld + a calendar exist.
- **B — Node + a per-panel cadence flag** (`one_shot` / `restock_every_n_nodes`) — approximates
  "time" without a calendar (lands naturally with shop/economy).
- **C — Full node/location/time** with a calendar now.
- **Rec: A, with B's cadence flag added when shop/economy is firmed** — node scope is the only axis
  that exists today; cadence is a cheap, economy-driven add; a calendar (C) is overworld-era.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — node-scoped panels only in v1; per-panel
  `one_shot`/restock cadence added with the shop/economy firming; calendar deferred to the overworld.

### [PHB-4] Non-battle / pure-hub nodes — does every node attach a battle?  **[OPEN]**
- **A — Every node = exactly one map;** the hub rides the existing pre-battle prep. Keeps the firmed
  `node→map` graph (`[CST-3/6]`) unchanged; deploy/Save/Begin Battle always present.
- **B — Allow standalone hub nodes** (a town/intermission with no map/battle); the graph
  distinguishes battle-nodes from hub-nodes.
- **Rec: A for v1** — preserves the firmed graph and the "every node launches a battle" model; the
  hub panels are reachable from the same pre-battle prep. Revisit B with the overworld (it is a graph
  shape change, not a panel change).
- **Resolution:** **[RESOLVED → B-schema / A-scope]** (owner 2026-06-23k) — **model node type as a
  first-class, author-switchable field NOW** (a node is freely re-typed between **battle** [has
  `map_id` + prep + Begin Battle] and **hub** [prep/panels only, advances via "Continue" instead of
  Begin Battle], and a battle node's `map_id` is freely re-pointed). **Build battle-nodes first
  ("start small")**; a pure **hub** node is the **near-term** next increment, **not** overworld-gated.
  Net: add `node_type` (battle|hub) to the progression-graph node; the firmed `node→map` is the
  `battle` case. Begin Battle becomes "the commit action" generically (launch map, or advance node).

### [PHB-5] Hub flow & commit point  **[OPEN]**
- **A — Free navigation, single commit:** the hub is a stateful screen; the player opens/closes
  panels in any order and edits deployment until **Begin Battle** (the sole commit). Manual Save
  available throughout. Matches FE prep.
- **B — Linear wizard** (shop → convoy → deploy → begin).
- **Rec: A** — free navigation is the genre expectation and keeps Begin Battle as the one
  irreversible step; everything before it is revisable.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — free navigation; the single commit is the
  node-advance action (Begin Battle on a `battle` node, Continue on a `hub` node per [PHB-4]); manual
  Save available throughout.

### [PHB-6] Theme — cosmetic vs mechanical  **[OPEN]**
- **A — Cosmetic only:** `theme`/`location_label` = background art ref + label (+ optional music id);
  no mechanical effect. Art binding rides the content-art pipeline.
- **B — Theme carries mechanics** (e.g. a "shop town" implies discounts).
- **Rec: A** — keep theme presentational; mechanical effects belong to the panels themselves
  (shop prices, etc.), not the skin.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — `theme`/`location_label` is cosmetic
  (background art ref + label + optional music id); no mechanical effect.

### [PHB-7] Transaction persistence & suspend  **[OPEN]**
- **A — Immediate commit:** buy/sell/convoy-move/training mutate persistent party state
  (`party_gold`/`party_items`/roster) immediately, so they survive suspend/reload with **no bespoke
  hub-suspend snapshot** — re-entering prep on resume re-derives the hub from party state.
- **B — Transactional hub state** snapshotted into suspend.
- **Rec: A** — the hub holds no state the party doesn't already hold; immediate commit matches the
  firmed "resume = latest between-map → prep" behavior and avoids a new save surface.
- **Resolution:** **[RESOLVED → A]** (owner 2026-06-23k) — transactions commit immediately to
  persistent party state; no bespoke hub-suspend snapshot; re-entering prep re-derives the hub.

## 4. Notes
- This pass is **player-facing + schema-shape only**; the build rides §2 + the §4a authoring contract.
  DoD: the owning GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**,
  not during firming (the §2 firming pattern).
- Downstream panels (convoy/shop/arena/training/recruit/skirmish) each get their **own** firming
  register; this one only fixes the **container** they plug into.

---

# Resolution Log
(newest first)

- **2026-06-23k — Detail batch (PHB-3/6/7) — register COMPLETE.** [PHB-3] **A** node-scoped panels
  now; cadence (`one_shot`/restock) added with shop/economy; calendar = overworld-era. [PHB-6] **A**
  theme is cosmetic (bg art + label + music id). [PHB-7] **A** transactions commit immediately to
  party state; no hub-suspend snapshot.
- **2026-06-23k — Structural batch (PHB-1/2/4/5).** [PHB-1] **C** flat list + cosmetic theme.
  [PHB-2] **A** opt-in per-node `prep_panels`. [PHB-4] **B-schema / A-scope** (owner) — `node_type`
  (battle|hub) is a first-class author-switchable field now; build battle-nodes first, pure hub nodes
  are the near-term next increment (not overworld-gated); Begin Battle generalizes to a node-advance
  commit. [PHB-5] **A** free navigation, single commit. **Schema impact:** progression-graph node gains
  `node_type` + `prep_panels: [...]` + `theme`/`location_label`. PHB-3/6/7 pending.
