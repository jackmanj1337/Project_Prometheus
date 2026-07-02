# Feature Band Plans Audit — Bands 1-6 (2026-07-02)

**Scope:** code-review-style audit of the upcoming feature-band implementation
plans requested by the owner. Documents reviewed:

- [`band1_determinism_save_implementation_plan_2026-06-30.md`](../Docs/plans/band1_determinism_save_implementation_plan_2026-06-30.md)
- [`band2_shared_runtime_contracts_implementation_plan_2026-06-30.md`](../Docs/plans/band2_shared_runtime_contracts_implementation_plan_2026-06-30.md)
- [`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](../Docs/plans/band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
- The four Band 4 plans (`B4-IEQ`, `B4-CONVOY`, `B4-MAP-OBJECTS`,
  `B4-SHOP-ECONOMY`) and the Band 3/4 handoffs.
- The Band 5/6 rows of
  [`project_control_plane_2026-06-29.md`](../Docs/plans/project_control_plane_2026-06-29.md)
  (no Band 5/6 plans exist — see C1).

Code-grounding claims were spot-checked against the working tree
(`project.godot` autoload order, the three raw-RNG sites, `TurnManager`
commit points, `GameState.party_items`/`party_gold`, `StatBreakdown.gd`,
`check_docs.py` check 21). All verified accurate except where noted below.

Severity: **High** = will mislead or block an implementer / genuine design gap;
**Medium** = ambiguity that forces the implementer to guess; **Low** = polish.

## Executive Summary

The Band 1-4 plans are in strong shape: slices are small, ordered, and carry
tests/F1/DoD#2 obligations consistently, and nearly every code touchpoint claim
checked out. The audit found **no ordering errors** in any bootstrap sequence.
The real issues are: (C1) Bands 5-6 have no plans or handoff while Band 7
already does; (C2) the Band 4 plan set is incomplete against its own handoff;
one stale-field reference that Band 1 itself will invalidate (2-1); one
phantom-API wording in Band 1 Slice 0 (1-1); and two genuine design gaps —
shop sell-price source (4S-1) and item instance identity (4I-1).

## Cross-Cutting Findings

### C1 (High) — Bands 5 and 6 have no implementation plans or handoff

Every Band 5 row (`B5-CONDITIONS`, `B5-SKILLS-EFFECTS`, `B5-LOADOUT-CAPS`,
`B5-SOURCE-STYLE`, `B5-DURATION-LIFECYCLE`, `B5-ACTION-GRANT`,
`B5-SECONDARY-MOVEMENT`, `B5-AI-COMPOSITION`, `B5-AI-MIN-SCORER`,
`B5-UTILITY-STAVES`) and most Band 6 rows read "needs implementation plan" /
"needs plan" in the control plane, and there is no
`band5_implementation_plan_handoff` in the pattern that successfully seeded the
Band 3 and Band 4 plans. Meanwhile Band 7 forging already has a full plan
(`band7_forging_implementation_plan_2026-07-01.md`) that itself **depends on an
unwritten Band 5 decision** ("brave/multi-hit … depends on Band 5 Q5"). Since
v1 = Band 5+6 completion, the planning frontier has a hole exactly where v1
ends. Recommendation: write a Band 5 handoff next (same shape as the Band 3/4
handoffs: rows to cover, bootstrap order, decisions not to reopen, owner
questions), before or alongside any further Band 7+ planning. Note the known
gate while drafting: the `B5-SKILLS-EFFECTS` "required v1 effect ids" split is
blocked on the demo-campaign content pick, so the handoff should carry that as
an explicit owner question rather than silently stalling.

### C2 (High) — Band 4 plan set is incomplete against its own handoff

Handoff decision `D1` names **five** distinct plans: `B4-IEQ`,
`B4-MAP-OBJECTS`, `B4-CONVOY`, `B4-SHOP-ECONOMY`, and "a thin
`B4-CAMPAIGN-LOOP` integration plan". The first four exist; the campaign-loop
integration plan does not, and its control-plane row still says "needs
vertical-slice plan". The seven smaller consumers (`B4-PXP`, `B4-DIALOGUE-V1`,
`B4-DCH`, `B4-VILLAGE`, `B4-RECRUIT-BASIC`, `B4-DIFFICULTY-DEATHMODE`,
`B4-PREP-DEPLOYMENT`) "may be grouped pragmatically", but no grouping decision
is recorded anywhere, so nothing owns them. Recommendation: record the grouping
(suggest three: PXP+dialogue prerequisites; DCH+village+recruit map-content
consumers; difficulty/deathmode+prep-deployment campaign wrappers) and write
the thin campaign-loop plan, since `D2` makes it the band's proof artifact.

### C3 (Medium) — Band 4 plans lack the closing sections Bands 2/3 have

Band 1 ends with "Definition Of Done"; Bands 2 and 3 end with "Implementation
Commit Order" + "Verification Checklist". The four Band 4 plans have per-slice
obligations but no closing commit-order or verification-checklist section, so
the run-after-every-slice commands (`run_tests.sh`, `check_docs.py`,
`git diff --check`) are stated nowhere in them. Add the standard closing
sections (or one line delegating to the Band 2/3 checklist).

### C4 (Low) — "Verified 2026-06-30" code grounding predates the v0.2.3/v0.2.4 repair commits

The display-repair work (`fd0f5f4`, `3741999`) landed after every plan's
grounding pass. Risk is low because each plan's Slice 0 preflight re-runs the
greps, and this audit re-verified the central claims — but treat Slice 0 as
mandatory, not optional, when implementation starts, and bump `Last verified`
then.

## Band 1 — Determinism And Save

### 1-1 (High) — Slice 0 describes `get_action_start_tile` as an existing "official API"; it does not exist

Slice 0 says "Use the official combat event-record API before editing combat:
`TurnManager.get_action_start_tile(unit)` supplies the pre-move tile…" —
present tense, as if callable today. Verified: no such function exists in
`TurnManager.gd` (only `record_move_start` exists). Slice 1b correctly says
"**Add** combat event-record plumbing". An implementer reading Slice 0 first
will hunt for an API that isn't there. Reword Slice 0 to "use the agreed API
shape, added in Slice 1b" or move the paragraph into 1b.

### 1-2 (Medium) — Slice 1d raw-RNG guard: the exemption mechanism is unnamed, but the codebase already has one

The guard spec says lines are exempt if they have "an explicit allowed
presentation/test exemption" — mechanism unspecified. The four raw gameplay
RNG sites already carry a tag convention:
`# rng-allow: pre-M9a (RNG-1)` (`CombatResolver.gd:450,457`, `Unit.gd:1113`,
`SkillHandler.gd:189`). Name `# rng-allow:` as the exemption tag in the plan
(and note that the *pre-M9a* tags must be **removed** by Slices 1b/1c, so the
guard's job is to reject untagged raw RNG and stale pre-M9a tags alike).
Otherwise the implementer invents a second convention beside the existing one.

### 1-3 (Medium) — T-numbering references an external test matrix and skips T2/T6 silently

Slices 1b/1d cite T1, T3, T4, T5, T7 from the RNG design doc's test matrix
without restating it or linking the matrix section. T2 and T6 never appear in
the plan. State explicitly where T2/T6 land (a later slice? follow-on
`B1-SUSPEND`? intentionally dropped?) so "all matrix tests covered" is
checkable at the end of the run.

### 1-4 (Low) — `f1_save_schema_manifest_2026-07-XX.md` placeholder is referenced from two slices

Slices 3 and 5 both point at the placeholder filename. Fine as a
to-be-created marker, but add a note that both references (and the `B1-F1`
row) must be updated in the commit that creates the real file, or the plan's
links rot immediately.

### 1-5 (Low) — "Confirm the exact Godot version accepts the signed decimal mixer constants" has no failure branch

If the confirmation fails, what changes — the constants, or the design doc?
One sentence ("if rejected, re-express as hex literals per the RNG design
appendix" or similar) removes the dead end.

## Band 2 — Shared Runtime Contracts

### 2-1 (High) — Slice 5 reads `GameState.permadeath_enabled`, which Band 1 Slice 6 deletes

Death lifecycle step 4 says "Set incapacitation according to existing
`GameState.permadeath_enabled`." Band 1 Slice 6 (`[CST-4]`, an explicit
decision-not-to-reopen) hard-migrates all rule call sites to
`gs.campaign_rules.*` and **deletes the loose fields** — and Band 1 lands
before Band 2. As written, Band 2 Slice 5 targets a field that will no longer
exist. Change to `gs.campaign_rules.permadeath_enabled` (or "the post-CST-4
rules owner").

### 2-2 (Medium) — Slice 4 declares seven occupancy policies but tests four

`require_empty`, `nearest_free`, `delay`, `skip` are exercised by the test
list; `swap`, `overlap_hidden`, and `object_unit` are declared with no test
and no Band 2 consumer (`swap` waits on displacement/carry, `overlap_hidden`
on FOW/perception, `object_unit` on `B4-MAP-OBJECTS` Slice 7). Say which of
the three are *implemented and tested now* versus *registered ids that fail
with "not implemented"* — the latter is the cheaper, YAGNI-consistent read,
but the plan currently implies all seven are built.

### 2-3 (Medium) — Slice 6 API naming: `project(ctx)` vs `project_combat()`

Step 3 defines the entry point `ProjectionService.project(ctx)`; step 6
switches `AttackPreview` to `ProjectionService.project_combat()`. If
`project_combat()` is a typed convenience wrapper over `project(ctx)`, say so;
otherwise pick one name.

### 2-4 (Low) — `DeathContext` has no object back-reference, but map-objects Slice 7 routes object-unit breaks through it

Band 4 map objects serializes object-unit HP/broken state as *object* state
via `B2-DEATH-LIFECYCLE`. `DeathContext`'s field list (subject, source domain,
source id, …) has no object-id back-reference for the *dying* subject. Either
reserve an optional `object_ref` field in the Band 2 context now, or note in
the map-objects plan that it extends the context — currently neither plan owns
the seam.

## Band 3 — Core Authoring Foundations

### 3-1 (Medium) — `visited_trail` is used but never defined or linked

Slice 5's only persisted state (the `chance` latch) "rides
`visited_trail`/flag store; no new top-level save field". `visited_trail`
appears nowhere else in the Band 1-4 plans; it comes from the F1 source
inventory / campaign-save design. Since it is the single save-bearing detail
of the entire REQ slice, link it (e.g. to the
[`f1_schema_source_inventory_2026-06-28.md`](../Docs/plans/f1_schema_source_inventory_2026-06-28.md)
row) so the implementer can find its owner, shape, and F1 row.

### 3-2 (Medium) — "number-domain booleans output canonical `1.0/0`" reads as a division

In a bullet otherwise about `div`/`on_zero` policy, `1.0/0` is genuinely
parseable as "one point zero divided by zero". It means "canonical `1.0` or
`0.0`" (i.e. fixed-point 1000 or 0). Rewrite as "output canonical `1.0` or
`0.0`" and state which fixed-point integers those are.

### 3-3 (Low) — Slice 3 `B3-TEXT`: registering every text key as a registry family may not scale

"Register text ids as a registry family so keys validate at load" — if that
means one `RegistryEntry` resource per key, a campaign with thousands of lines
pays a per-key resource cost. If it means the *family* is registered and keys
validate against loaded tables, say that. One sentence resolves it.

### 3-4 (Low) — Calendar advance on defeat/retry is unspecified

Slice 11 advances `campaign_day` "on node completion (post-combat for `battle`
nodes)" and latches against suspend/reload double-count. Not stated: a map
that is *failed* and retried, or Retry-rewound mid-map — does the day advance
only on victory? (Presumably yes: completion = victory. One word — "on node
**victory**" — removes the ambiguity.)

## Band 4 — Items And Equipment (`B4-IEQ`)

### 4I-1 (High) — Modifier sources need `item:<entry-instance-id>:<stat>`, but nothing creates an instance id

Slice 5 step 3 keys `until_unequipped` modifiers by *entry instance id*.
`InventoryEntry` has no instance-id field today; the plan's F1 row list
(Slice 0) doesn't reserve one; no slice adds one. Two identical Iron Swords
must not share a modifier source key, so this is load-bearing. Either: add an
`instance_id` field in Slice 2 (with F1 row, snapshot deep-copy coverage, and
save-codec round-trip), or define the source key from something that exists
(owning unit + slot index is fragile across sorts/transfers — the explicit id
is safer, especially since convoy transfers must preserve identity).

### 4I-2 (Medium) — ItemDef id parity with legacy ids is implied, never stated

Slices 3/4 convert weapon/item resources to `ItemDef`s and Slice 7 removes
`weapon_id`/`item_id` "after save migration and fixtures prove `def_id`
round-trips". The whole migration is mechanical only if **`ItemDef.id` equals
the legacy weapon/item id for every migrated resource**. Make that an explicit
invariant with a validation check (a migrated def whose id differs from its
source id fails), since old saves and `MapData.reward_items` carry legacy ids.

### 4I-3 (Low) — "safe default rank" in the PXP adapter is undefined

Slice 6: before `B4-PXP`, the adapter "returns the safe default rank". Name it
(lowest rank / rank 0 / "the rank that gates nothing") so fixtures agree.

## Band 4 — Convoy (`B4-CONVOY`)

### 4C-1 (Low) — `give_item_to_unit_or_convoy()` has no stated owner

Slice 2 adds "a single helper" with both `GameState.gd` and
`ConvoyService.gd` in files-to-touch; the shop plan calls it as
`ConvoyService.give_item_to_unit_or_convoy()`. Name `ConvoyService` as the
owner in the convoy plan so the two plans agree.

Otherwise clean: store migration, capacity/overflow, transfer, selector
extraction (Q11), and death-hook slices are consistent with the shop and
map-object plans, and the `party_items` retirement path is well-guarded.

## Band 4 — Map Objects (`B4-MAP-OBJECTS`)

### 4M-1 (Medium) — `shown_disabled` silently degrades to hidden; say where that is documented

Slice 3 keeps `shown_disabled` actions hidden until ActionMenu grows a
disabled-row state, and says to "document the deferred UI state" — but not
where. This is author-visible semantics (an author choosing `shown_disabled`
gets `hidden` behavior), so name the home: the `SAC` register row and/or
`GDD_07`, plus a control-plane note so it isn't forgotten when `B6-INPUT`/UI
polish lands.

Otherwise clean: the component/registry shape, passability, quarantine, and
consumer-fixture slices line up with the contract doc and the Band 2 services.
(See 2-4 for the DeathContext seam.)

## Band 4 — Shop Economy (`B4-SHOP-ECONOMY`)

### 4S-1 (High) — Sell price source for items not in the shop's stock list is undefined

`sell_yields` lives on `ShopStockEntry`, but the sell view lists the
**shopper's inventory** — arbitrary items that may appear in no stock entry of
this shop. Nothing in the plan (or the resolved decisions) says where their
sell yield comes from. Options: (a) a default yield derived from `ItemDef`
value data (e.g. an author-set campaign-rules percentage of cost — but the
"not a single gold int plus sell percentage" decision cuts against a hardcoded
percentage); (b) only items matching a stock entry are sellable (harsh, but
authorable per shop); (c) an optional `sell_yields` on `ItemDef` itself with
stock-entry override. This is an owner design decision, not a drafting fix —
recommend adding it to the `SHP` register and resolving before Slice 2, since
`quote_sell`/`commit_sell` can't be written without it.

### 4S-2 (Low) — Slice 8's "cost is only the gold buy amount projection" hints at the 4S-1 answer without giving it

If `ItemDef.cost` is a projection of resource-keyed price data, then the
resource-keyed *source* of both buy and sell defaults should be named in
Slice 1's data shape, not discovered in the cleanup slice.

## What Was Checked And Found Sound

- Bootstrap orders in all plans match the dependency claims (TCV→REQ,
  TEXT→REQ display, CAMPAIGN-RULES→ROLL-RESOLVER, IEQ/MAP-OBJECTS first in
  Band 4, registry-before-everything).
- No plan adds saved state without naming an F1 row; no plan introduces a
  closed enum for a growing vocabulary; every slice carries DoD#2 obligations.
- Autoload-order claims match `project.godot` and `check_docs.py` check 21
  already encodes the RngService/RegistryManager ordering (skip-until-exists).
- Raw-RNG site list (CombatResolver, Unit, SkillHandler), the Retry snapshot
  owner methods, `party_items`/`party_gold`/`max_inventory` touchpoints,
  `TileActions` placeholder claims, and `StatBreakdown.gd` all verified.
- The two resolved Band 1 review questions and the four resolved Band 3 owner
  questions are consistently reflected in the plan bodies.

## Resolutions (2026-07-02, owner)

- **4S-1 RESOLVED** as `[SHP-6]` in
  [`shop_economy_open_questions_2026-06-23.md`](../Docs/registers/shop_economy_open_questions_2026-06-23.md):
  sell price = campaign-default author-set `REQ-16` formula (default 50% of
  value × percent durability remaining), plus a per-shop incoming-price
  modifier symmetric with the outgoing buy modifiers; stock-entry
  `sell_yields` = per-entry override. Wired into the shop plan Slices 1/2/5/8.
- **C2 RESOLVED**: the thin
  [`band4_campaign_loop_implementation_plan_2026-07-02.md`](../Docs/plans/band4_campaign_loop_implementation_plan_2026-07-02.md)
  is written (finalizing the `D2` minimum loop); the seven remaining tracks are
  owned by three grouped plans per handoff decision `D5` (enablers /
  map content / campaign wrappers), drafted at the existing
  Band-1-3-accepted trigger. 4S-2 is covered by the Slice 8 edit.

## Suggested Order Of Fixes

1. **Owner decisions needed:** 4S-1 (sell-price source — blocks shop Slice 2),
   C2 grouping (who owns the seven unplanned Band 4 consumers).
2. **Plan edits, high:** 1-1, 2-1, 4I-1 (these will actively mislead an
   implementer).
3. **Plan edits, medium:** 1-2, 1-3, 2-2, 2-3, 3-1, 3-2, 4I-2, 4M-1.
4. **New docs:** Band 5 handoff (C1), thin `B4-CAMPAIGN-LOOP` plan (C2),
   Band 4 closing checklists (C3).
5. **Low polish** (1-4, 1-5, 2-4, 3-3, 3-4, 4I-3, 4C-1, 4S-2) can ride the
   same edits opportunistically.
