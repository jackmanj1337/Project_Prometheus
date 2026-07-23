---
Type: research handoff
Status: Planned — research only; NO implementation plans until these produce answers
Last verified: 2026-07-23
Owner inputs: AGENT/Campaign data questions.md (owner answers, 2026-07-23)
Tracker rows: RESEARCH-ECONOMY-OWNERSHIP-2026-07-23, RESEARCH-PACK-SAVE-OWNERSHIP-2026-07-23,
  RESEARCH-ENGINE-ZERO-CONTENT-2026-07-23, RESEARCH-RULE-PROFILE-CONTRACT-2026-07-23
---

# Campaign Data Ownership — Research Handoff

## Purpose and how to use this

This session aligned on the **goals** for the campaign rules / data-ownership /
economy cluster (Section C). The owner answered the goal-alignment questions in
`AGENT/Campaign data questions.md`. This handoff turns those answers into
**four research threads to execute next session**.

**Do not write implementation plans yet.** Each thread below ends in a research
deliverable (a findings doc / decision record). Implementation plans come *after*
those land and are reviewed. The whole point of this step is to avoid planning on
unknowns — three of these threads have a genuine "we don't know the shape yet"
core.

Order of the doc: locked decisions first (what is settled, do not relitigate),
then the open research per thread, then cross-cutting sequencing and guardrails.

---

## Thread R1 — Economy ownership model
**Tracker:** `RESEARCH-ECONOMY-OWNERSHIP-2026-07-23` · **Feature:** PP-FACTION-GOLD-ECONOMY
**Depth:** light-to-moderate · **Blocked on:** nothing

### Locked by owner
- **Purpose:** primarily for the eventual **hotseat/multiplayer** plan; a future
  AI may **spend** resources to purchase reinforcements. So design for genuine
  multi-owner *spending*, not just HUD display of another faction's gold.
- **Owner key:** broad **`owner_ref`** — `faction | shop | campaign | unit | arena`.
  Not a faction-only key. (This matches the existing indirection; see below.)
- **Multi-resource from day one:** exercise the system with **three resources —
  `gold`, `bonus_exp`, `training_points`.**
- **Migration:** don't over-invest yet; assume **blue/player inherits** the
  existing single `party_gold`. **All wallets participate in rewind.**

### Why the wallet is not keyed on faction (context for the researcher)
`ResourceLedger` already resolves wallets through `_resolve_wallet()` dispatching
on a `primitive_handler` (`party_gold_wallet`, `unit_gold_wallet`) into a generic
`{target, property}` record; `CostSpec` carries `resource_id` + `scope` and **no
faction field**. Ownership is already an indirection, not an identity. Faction is
mutable battlefield alignment (recruits, flips); resource ownership is a distinct,
more stable fact. Keying money on faction would teleport balances on every flip
and could not express non-faction owners (shop till, campaign treasury, arena
purse, escrow). The registry makes *faction one owner among many*.

### Research to do
1. **Consumer audit.** Enumerate every reader/writer of `party_gold` (grep found
   ~5 core runtime files: `GameState`, `ResourceLedger`, `CampaignManager`,
   `MapMenu`, `SaveData`, plus tests). For each, record what it assumes about
   "one party wallet" so the multi-wallet change has a known blast radius.
2. **Owner-ref model.** Define `owner_ref` shape and how a cost/transaction names
   its owner. Reuse `CostSpec.scope`/`subject_binding` where possible rather than
   adding a parallel field. How does an owner get created/destroyed (per-campaign
   treasury vs per-map shop vs per-unit)?
3. **Multi-resource shape.** Confirm the `primitive_handler`/record model
   generalises to `gold | bonus_exp | training_points` cleanly, or what it needs.
   Where do non-gold balances live (GameState property per resource, or a map)?
4. **OPEN QUESTION from owner — rewind charges into the wallet system?** Today
   `rewind_charges_per_map` is a `CampaignRules` field with its own accounting
   (`GameState.prune_history` / ledger). Investigate whether rewind charges are
   better modelled as a **`rewind_charges` resource owned by a wallet**, unifying
   the "spend a limited currency" pattern. Weigh: determinism (rewind must not
   itself be rewindable in a way that refunds its own cost), the existing
   `rewind_cost_mode` (`per_activation | full_history`), and save shape. This is a
   real design fork — produce a recommendation with reasoning, not a coin-flip.
5. **Rewind atomicity.** Owner was unsure what "wallets as one atomic unit" means:
   it means the ledger snapshot captures/restores **all** wallet balances together
   at each checkpoint, so Retry/Rewind never leaves wallets half-reverted. Confirm
   the ledger checkpoint already serialises `party_gold` and extend the same path.

### Deliverable
A short decision record: `owner_ref` model, the three-resource layout, the
rewind-charges verdict, and the consumer-audit table. No code.

---

## Thread R2 — Pack owns the save (serialization + single source of truth)
**Tracker:** `RESEARCH-PACK-SAVE-OWNERSHIP-2026-07-23` · **Feature:** PP-STRATEGIC-DATA-OWNERSHIP (part 1)
**Depth:** heavy · **Blocked on:** nothing, but deeply linked to R3

### Locked by owner
- **Primary driver is NOT bloat/speed** (those are secondary concerns). It is
  **single source of truth for editing:** packs are meant to be easy to
  edit/fork/redesign, so an author must never have to change the same fact in
  two places for it to take effect.
- **The pack owns the save.** A save is **current state + mutations (deltas)**
  against pack-canonical data — pending research says delta-vs-self-contained.
- **Export modes wanted:** (a) a standalone save file (backup / cross-device),
  (b) the entire pack, (c) a **clean** pack with user save data stripped.
- **Version contract:** the pack **writes its version into the save** at creation;
  a future/newer pack checks whether it has **loading rules for that version or
  version group** and migrates forward. (Version-stamped, newer-pack-migrates.)

### Research to do
1. **Serialization map.** Document how pack content *and* save state serialise
   today (SaveData already has a `party.items`↔`convoy.entries` fallback; catalogue
   is `data/catalogue.json`; campaign envelope carries flags/vars/rules/roster/
   gold). Identify every place the same fact is currently stored in two locations —
   that duplication list is the actual problem statement.
2. **Delta vs self-contained.** Owner's lean is delta (pack canonical + save
   mutations), but flagged: "if significantly more complicated and doesn't gain
   much, reconsider." Produce the concrete trade: what a delta save must reference,
   what breaks if the pack is absent, and whether export-mode (a) (standalone save)
   forces a self-contained *snapshot* export even if the live save is a delta.
3. **Version/migration contract.** Define the version stamp (pack id + version +
   package-format version already exist in `manifest.json`) and the "loading rules
   for a version group" mechanism — where do migration rules live, in the newer
   pack? What is the failure mode when no rule matches?
4. **Export surfaces.** Specify the three export operations and what each includes/
   excludes (esp. "clean pack" = strip save data; "standalone save" = enough
   context to re-bind to its pack later).

### Deliverable
A findings doc: the duplication map (the real problem), a delta-vs-self-contained
recommendation with the cost, the version/migration contract, and the three export
modes. No code.

---

## Thread R3 — Engine ships zero content (data/formula boundary)
**Tracker:** `RESEARCH-ENGINE-ZERO-CONTENT-2026-07-23` · **Feature:** PP-STRATEGIC-DATA-OWNERSHIP (part 2)
**Depth:** heavy · **Priority:** owner says HARD v1 requirement, address SOON (scope only grows)

### Locked by owner
- **End state:** the engine **compiles with zero content** and is distributed with
  **one or more zip data packs** that authors and players pick and choose from. The
  base game becomes a pack.
- **Pack-ownable line is broad:** **live balance numbers AND, where possible,
  formulas** should be pack-owned, plus as much else as is reasonable.
- **Hard requirement**, not opportunistic cleanup. Do it soon.

### Research to do
1. **Baked-content inventory.** Enumerate everything currently shipped inside the
   engine tree (`data/`: classes, weapons, items, skills, terrain, maps, campaign
   graphs, rosters) and classify: cleanly pack-movable, engine-must-keep, or unclear.
2. **THE HARD ONE — data vs script boundary.** "Formulas where possible … without
   implementing a full sandboxed scripting environment." Research where the line is:
   which formulas can become **declarative data** the engine interprets (e.g. the
   existing `hit_formula: "two_roll"` selector, `CostSpec.formula_term`, the
   requirement/predicate register) vs. which genuinely need code. Catalogue the
   formula/behavior extension points that already exist (source-style combat model,
   `CampaignRules` selectors, ObjectiveCondition/ItemEffect registries that
   "dispatch without a closed id switch") — the answer is likely *named engine
   behaviors selected + parameterised by data*, not arbitrary author code. Draw the
   boundary explicitly and name what stays engine-side.
3. **Zero-content boot.** What must the engine do when it boots with no pack
   selected (empty `data/`)? Main-menu/pack-selection first-run flow, validation
   when a pack is missing a required family, the "base game as pack" packaging.
4. **Interaction with LEG-AUDIT-FE-NUMBERS.** Moving live numbers into packs is the
   same physical operation the licensing audit is eyeing (FE-derived numbers →
   Pack_FE). Coordinate so this isn't done twice or in conflict.

### Deliverable
A findings doc: the baked-content inventory + classification, an explicit
**data-vs-script boundary** with the list of what stays engine-side, and the
zero-content boot/packaging outline. No code. Flag this as the thread most likely
to reshape the roadmap.

---

## Thread R4 — Rule-profile contract
**Tracker:** `RESEARCH-RULE-PROFILE-CONTRACT-2026-07-23` · **Feature:** B3-CAMPAIGN-RULES
**Depth:** light (mechanism already built) · **Blocked on:** nothing

### What a "profile" is (owner asked for a clearer explanation)
A **rule profile** is a **named, reusable bundle of `CampaignRules` default
values** — e.g. "Standard", "Ironman", "Casual" — that an author drops into a
campaign as its *starting defaults* instead of hand-setting every field. It is an
**authoring-time convenience and a shareable preset**, nothing more. It does not
add a runtime layer: it simply **populates the "campaign default" layer** that the
already-built resolver reads (mandate → node override → mid-map override → **default**).
Which of those defaults an author then **locks** (mandate) is a separate, existing
choice. The runtime mechanism (`B6-PER-MAP-OVERRIDES`, `get_effective_campaign_rule`,
`apply_rule_flip`) is **already implemented** — this thread is only the authoring/
data contract on top.

### Locked by owner
- Profile = a **collection of recommended defaults** an author drops in, as a
  **pointer or a copy-paste**, living in documentation or the campaign-editor GUI.
- It is the **source of the campaign-default layer** (confirmed).
- Packs **author their own** profile docs; authoring may be **copy-pasting** from
  built-in / GUI / separately-distributed preset docs.
- **First slice:** **reuse existing `CampaignRules` fields** (profile = a `.tres`/
  JSON of those fields) unless there's a concrete reason to expand.

### Research to do
1. **Format.** Confirm profile = serialised `CampaignRules` field set. Pointer vs
   copy-paste: does a campaign *reference* a named profile (indirection, updates
   propagate) or *inline a copy* (self-contained, drift allowed)? Owner is open —
   recommend, noting this interacts with R2's single-source-of-truth goal (a pointer
   is more single-source; a copy is more forkable).
2. **Where presets live.** Built-in engine presets, editor GUI, or a distributed
   doc — and how "drop in" works in each. Given R3 (engine zero-content), built-in
   presets may themselves need to ship as pack data.
3. **Seam check.** Verify a profile only feeds the campaign-default layer and never
   short-circuits mandates or the override layers.

### Deliverable
A short decision record: the profile format, pointer-vs-copy verdict, where presets
live, and the first-slice scope. No code.

---

## Cross-cutting sequencing and guardrails

- **R2 and R3 are one thrust.** "Pack owns the save" + "engine ships zero content" +
  "single source of truth" are the same idea — *the campaign pack is the unit of
  data ownership*. Research them together; they will likely share one design doc even
  if the tracker keeps two rows. R3 is the hard v1 requirement and should lead.
- **R4 is small and independent** — the runtime already exists; it can proceed on its
  own timeline. But its pointer-vs-copy choice should be made *consistent* with R2's
  single-source-of-truth conclusion.
- **R1 is independent** and the most self-contained; it can be researched first as a
  quick win, but note its rewind-charges question touches `CampaignRules`, which R4
  also touches — coordinate if both move at once.
- **Guardrails:** (1) no sandboxed scripting environment — the data/script boundary
  is "named engine behaviors parameterised by data", not author code; (2) do not
  write implementation plans in this next session — produce the four findings docs
  first; (3) mind the `8b77c9d` `CampaignManager` rewrite in the R1/R4 conflict
  surface when it comes time to branch.

## Deliverables checklist for next session
- [ ] R1 decision record (economy owner_ref + 3 resources + rewind-charges verdict + consumer audit)
- [ ] R2 findings (duplication map + delta-vs-self-contained + version/migration + export modes)
- [ ] R3 findings (baked-content inventory + data-vs-script boundary + zero-content boot)
- [ ] R4 decision record (profile format + pointer-vs-copy + preset home + first-slice scope)
- [ ] Update the four tracker rows to `in_progress`/`completed` as each lands

## Sources
- Owner answers: `AGENT/Campaign data questions.md`
- Boundary already ratified: `AGENT/Docs/plans/campaign_pack_engine_boundary_plan_2026-07-15.md`
- Rule mechanism (built): `AGENT/GDD/GDD_01_Runtime_Contracts.md` §Mutable rule layers; `scripts/resources/CampaignRules.gd`
- Economy spine: `scripts/autoloads/ResourceLedger.gd`, `scripts/resources/CostSpec.gd`
