---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: PHB-1..7
---

# Prep-as-Hub Firming (§3a keystone) — Player-Facing Design + Open Questions

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
- **Owner cross-cutting decisions already set** (scope map §3a): no free-roam/wander area;
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
- **Resolution:** _[OPEN]_

### [PHB-2] Panel availability default — opt-in vs opt-out  **[OPEN]**
- **A — Opt-in:** panels OFF by default; the node declares `prep_panels: [...]`. A node with none
  = today's deploy-only prep. Explicit; matches the mandate/default philosophy (authors opt in).
- **B — Opt-out:** all panels available unless the node excludes them.
- **Rec: A** — explicit per-node panel list; least surprising, and it is the clean §4a authoring hook.
- **Resolution:** _[OPEN]_

### [PHB-3] Gating axes — what scopes a panel's availability  **[OPEN]**
The owner phrased it "available at each node / location / time." "Time" has no substrate pre-overworld.
- **A — Node-only for v1:** each progression node declares its panels. Drop time/location as axes
  until the overworld + a calendar exist.
- **B — Node + a per-panel cadence flag** (`one_shot` / `restock_every_n_nodes`) — approximates
  "time" without a calendar (lands naturally with shop/economy).
- **C — Full node/location/time** with a calendar now.
- **Rec: A, with B's cadence flag added when shop/economy is firmed** — node scope is the only axis
  that exists today; cadence is a cheap, economy-driven add; a calendar (C) is overworld-era.
- **Resolution:** _[OPEN]_

### [PHB-4] Non-battle / pure-hub nodes — does every node attach a battle?  **[OPEN]**
- **A — Every node = exactly one map;** the hub rides the existing pre-battle prep. Keeps the firmed
  `node→map` graph (`[CST-3/6]`) unchanged; deploy/Save/Begin Battle always present.
- **B — Allow standalone hub nodes** (a town/intermission with no map/battle); the graph
  distinguishes battle-nodes from hub-nodes.
- **Rec: A for v1** — preserves the firmed graph and the "every node launches a battle" model; the
  hub panels are reachable from the same pre-battle prep. Revisit B with the overworld (it is a graph
  shape change, not a panel change).
- **Resolution:** _[OPEN]_

### [PHB-5] Hub flow & commit point  **[OPEN]**
- **A — Free navigation, single commit:** the hub is a stateful screen; the player opens/closes
  panels in any order and edits deployment until **Begin Battle** (the sole commit). Manual Save
  available throughout. Matches FE prep.
- **B — Linear wizard** (shop → convoy → deploy → begin).
- **Rec: A** — free navigation is the genre expectation and keeps Begin Battle as the one
  irreversible step; everything before it is revisable.
- **Resolution:** _[OPEN]_

### [PHB-6] Theme — cosmetic vs mechanical  **[OPEN]**
- **A — Cosmetic only:** `theme`/`location_label` = background art ref + label (+ optional music id);
  no mechanical effect. Art binding rides the content-art pipeline.
- **B — Theme carries mechanics** (e.g. a "shop town" implies discounts).
- **Rec: A** — keep theme presentational; mechanical effects belong to the panels themselves
  (shop prices, etc.), not the skin.
- **Resolution:** _[OPEN]_

### [PHB-7] Transaction persistence & suspend  **[OPEN]**
- **A — Immediate commit:** buy/sell/convoy-move/training mutate persistent party state
  (`party_gold`/`party_items`/roster) immediately, so they survive suspend/reload with **no bespoke
  hub-suspend snapshot** — re-entering prep on resume re-derives the hub from party state.
- **B — Transactional hub state** snapshotted into suspend.
- **Rec: A** — the hub holds no state the party doesn't already hold; immediate commit matches the
  firmed "resume = latest between-map → prep" behavior and avoids a new save surface.
- **Resolution:** _[OPEN]_

## 4. Notes
- This pass is **player-facing + schema-shape only**; the build rides §2 + the §4a authoring contract.
  DoD: the owning GDD chapter + `GDD_Feature_Index` row + roadmap status flip land **with the build**,
  not during firming (the §2 firming pattern).
- Downstream panels (convoy/shop/arena/training/recruit/skirmish) each get their **own** firming
  register; this one only fixes the **container** they plug into.
