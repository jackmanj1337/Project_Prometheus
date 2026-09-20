---
Role: dated
Type: register
Status: RESOLVED — `ROS-1`, `ROS-2`, `ROS-5`, `ROS-6` ruled 2026-09-20; `ROS-3` and `ROS-4` ruled in principle and routed to their own rows
Last verified: 2026-09-20
Register: ROS-1..6
Tracker: ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Campaign Roster Composition — Owner Rulings

Research: [Roster Composition — Comparative Research](../design/roster_composition_comparative_research_2026-09-20.md)

Closes the design question registered by `ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20`: *how
does a pack author put specific units on a specific chapter?* The row deliberately
registered a decision rather than an implementation, and asked for it to be ruled before
anyone wrote code. Ruled by the owner 2026-09-20 off the comparative research.

**Process machinery:** this register adds no new mechanism. It is one document in an
existing class (`Type: register`) and introduces no check, hook, guard or tracker, so
`AGENTS.md` § *Process machinery (one-in-one-out)* has nothing to retire against it.

**Citation gate:** `ROS-*` lives in this register only. Under `check_docs.py` check 50 a
ratified ID must live in a GDD chapter before GDScript may cite it, so **code must not cite
`[ROS-n]` yet**. Whichever build lands `ROS-3` writes its ruling into its owning GDD chapter
in the same change, or states the principle in prose instead.

---

## 1. Preflight — measured 2026-09-20

Measured on `agent/integration` `c7577074` and on
`agent/from-integration/interaction-rule-contract` `bb241466` (the unmerged slice-7 branch
that carries the evidence suite).

| Check | Method | Result |
|---|---|---|
| Node deployment constraints exist | `CampaignNode.gd:41-46`, `DeploymentPlan.gd:85-106`, `PrepScreen.gd:88-219` | ✓ present — `required_units`, `excluded_units`, `deployment_cap`, all authored on the node |
| A later node can author a roster | `CampaignManager.resolve_launch_params:759-767` | ✗ refused by design — any node after the first is forced to `keep_current_roster` |
| A unit can join the army | `grep` for `player_roster` mutation outside tests | ✗ **no append anywhere**; only wholesale assign (`GameState.gd:535,538,560,600,1146`) |
| `recruited_flags` has a writer | `grep` across `scripts/` | ✗ serialized in `SaveData.gd:346,726`, written by nothing |
| The army may change size | `GameState._validate_restore_entry:1413` | ✗ the ledger validator rejects any entry whose roster count differs from the live roster |
| A standalone map has a ruleset | Route A of `test_interaction_acceptance_playthrough.gd` | ✗ `GameState.campaign_rules.interaction_profiles` is empty outside a campaign run |

The research (§1–§2) establishes the genre pattern these are measured against: in Fire
Emblem the campaign owns the army and the chapter constrains and adds; in Advance Wars there
is no army and the map owns its force outright. Neither series lets a mid-campaign chapter
replace the player's party.

---

## 2. The rulings

### `ROS-1` — An authored per-map roster is standalone-only. **RULED**

A `roster_policy` / `roster_source` on a map-registry entry seeds the party **only** when the
map is launched standalone, or as the first node of a campaign run. A campaign node after the
first never replaces the party, and `resolve_launch_params` keeps forcing
`keep_current_roster`. The candidate of a per-node `roster_policy` override is **rejected**.

*Reason.* No mainline Fire Emblem chapter swaps the army; the four games that replace one do
it at a structural boundary the player is shown (see `ROS-5`). The knob would let an author
silently reset levels, gold and inventory mid-run, which is the outcome the existing comment
at `CampaignManager.gd:759` already identifies and refuses.

*Consequence.* `map_900_hotseat_validation`, `map_950_promotion_validation` and
`map_006_hallowed` are correct as authored and need no change. They are trial maps, and
their rosters are what a trial map is entitled to carry.

### `ROS-2` — A chapter shapes its cast through node constraints, not a roster. **RULED**

The supported way for a pack author to put specific units on a specific chapter is the
`[CST-5]` node constraint set that already exists: `required_units` (force-deploy, slot
locked), `excluded_units` (ineligible this chapter), `deployment_cap`. No new authoring
vocabulary is added for this.

*Reason.* This is the genre's dominant shape by a wide margin, it is already built end to
end, and it is already authored on the node rather than the map — which is the correct
owner, because the same map used as a trial map carries no such constraint.

*Gap acknowledged.* Constraints can only select from units already in the army. Adding to
the army is `ROS-4`.

### `ROS-3` — A standalone map launch must carry a ruleset. **RULED IN PRINCIPLE — own row**

Activating a content pack shall put that pack's rules in scope for a map launched from its
registry, without requiring a campaign run to be started. Starting a campaign is a separate
act from having rules.

*Reason.* In both series a trial, arena or skirmish map runs the game's full combat rules;
switching a combat rule off because the player is not in a campaign has no precedent
anywhere. The engine models rules as campaign-scoped (`CampaignRules` + node
`rule_overrides`), so a standalone launch currently has no ruleset at all — which is why the
slice-7 relationship cannot fire on Route A.

*Scope note.* This is not specific to the acceptance pack. It binds any pack shipping a
trial, skirmish or validation map, and it is the half of the route gap that actually blocks
content today.

*Not authorised here.* The ruling states the requirement; the build is its own row, and
that row must decide where a pack-level default ruleset lives and how a campaign's rules
shadow it.

### `ROS-4` — The army may grow: a node may add a unit. **RULED IN PRINCIPLE — own row**

A campaign node shall be able to add a unit to the party — as a permanent join or as a
chapter-scoped guest that leaves afterwards. This is the missing primitive, and the
"map-scoped reinforcement list" candidate on the row is subsumed by it.

*Reason.* Joining is the single most common roster event in the genre and the engine cannot
express it at all. Building the guest case alone would ship the exception before the rule.

*Known cost, and why this is its own row.* The army is currently fixed-size for the whole
run and two mechanisms depend on that: `_validate_restore_entry` rejects a ledger entry whose
roster count differs from the live roster, and permadeath marks `is_incapacitated` rather
than removing. `SaveData.recruited_flags` is already serialized with no writer and is the
natural home for join state. This is save-ledger work, not an append.

*Not authorised here.* No schema is ruled by this entry.

### `ROS-5` — Wholesale army replacement is a campaign boundary, not a node knob. **RULED**

Where a pack genuinely wants a different army — the FE4 generational handover, FE10's
rotating Parts, FE7's Lyn mode, FE8's route split — it models that as a campaign-structural
boundary the player is shown, not as a property of a chapter. Until such a boundary is
designed, the supported expression is a separate campaign document.

*Reason.* The distinction is the whole reason `ROS-1` is safe to rule. The series does
replace armies; it never does so invisibly, and it never does so as a per-chapter setting.

*Deferred.* No boundary construct is designed or authorised here. Raise a row if a pack
needs one.

### `ROS-6` — The slice-7 acceptance pack is fixed by authoring, not by engine work. **RULED**

The acceptance content is repaired with no engine change: seed `m006_hallowed_bearer` in the
campaign's **first** node roster, where an authored policy *is* honoured, and pin it onto
chapter 6 with `required_units`. `m006_plain_axeman` rides along the same way as the A/B
control.

*Reason.* This is also the genre-canonical authoring — the unit joins early and the player
brings them — and it is available today under `ROS-1` and `ROS-2` without waiting on `ROS-3`
or `ROS-4`.

*Caveat to carry.* Under `ROS-2` the two units are then ordinary party members and will
level, take damage and carry gold between chapters like any other. A bench whose two halves
must stay stat-identical should assert that identity at the point of measurement rather than
assume it, or hold the comparison inside a single chapter.

*Interaction with `ROS-3`.* Once `ROS-3` lands, the standalone Route A becomes available for
the same content and is the better home for a measurement bench. `ROS-6` is the authoring
that unblocks the pack now; it is not an argument against `ROS-3`.

---

## 3. Successor rows

| Row | Rules | Shape |
|---|---|---|
| `STANDALONE-MAP-RULESET-2026-09-20` | `ROS-3` | Build. Where a pack-level ruleset lives, how a campaign shadows it, and Route A proven by the existing acceptance suite. |
| `ROSTER-JOIN-2026-09-20` | `ROS-4` | Design-then-build. Join and guest semantics, the ledger's fixed-count assumption, `recruited_flags` as the save shape. |

`ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20` closes against this register. `ROS-6` is the
authoring action that belongs to `AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10`.

---

## 4. Pointers

- Research: [`roster_composition_comparative_research_2026-09-20.md`](../design/roster_composition_comparative_research_2026-09-20.md)
- Deployment constraints: `[CST-5]` in
  [`campaign_save_open_decisions_2026-06-21.md`](campaign_save_open_decisions_2026-06-21.md)
- Node composition: `[CNC-1..10]` in
  [`campaign_node_composition_open_questions_2026-07-03.md`](campaign_node_composition_open_questions_2026-07-03.md)
- Launch seam: `scripts/autoloads/CampaignManager.gd` (`resolve_launch_params`,
  `_apply_roster_policy`); policies in `scripts/autoloads/GameState.gd` and
  `scripts/autoloads/DataManager.gd:32`
- Evidence: `scripts/tests/test_interaction_acceptance_playthrough.gd` on
  `agent/from-integration/interaction-rule-contract` `bb241466`
- Related open defect, not part of this register: autosave fails on every chapter commit
  when a pack is activated from a directory rather than the installed library.
