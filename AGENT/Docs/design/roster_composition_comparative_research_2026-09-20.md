---
Role: dated
Type: design
Status: Research complete; rulings taken in `registers/campaign_roster_composition_2026-09-20.md`
Last verified: 2026-09-20
Tracker: ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Roster Composition — Comparative Research (Fire Emblem, Advance Wars)

## Purpose

`ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20` registered a design question rather than a
defect: *how does a pack author put specific units on a specific chapter?* It listed three
candidate answers and asked for a ruling before anyone wrote code.

This document answers that question from the two series the project takes its player-facing
shape from, then measures the engine against what they do. The rulings it feeds are in
[`campaign_roster_composition_2026-09-20.md`](../registers/campaign_roster_composition_2026-09-20.md)
(`ROS-1..6`).

The short form: **the pattern is consistent enough across both series to settle the
question, and it settles it against the candidate the row listed first.** It also shows the
row was asking one question that is really two, and that one of the two is a capability the
engine does not have at all.

---

## 1. Fire Emblem — the campaign owns the army; the chapter constrains and adds

Across the mainline series the player's army is persistent, carried between chapters, and
**never replaced by a chapter**. Every "this chapter fields specific units" case is one of
four player-facing shapes.

| # | Shape | How it reads to the player | Where it appears |
|---|---|---|---|
| 1 | **Constrain** | The prep screen shows the whole army. Some slots are pre-filled and cannot be removed; some units are greyed out; the deployment count is capped. | The dominant case. A lord is force-deployed in essentially every game; most story chapters cap deployment; paralogues and side chapters routinely force a subset. |
| 2 | **Add (join)** | A unit *joins the army* — at chapter start, by a Talk/recruit action mid-chapter, or on chapter clear — and is there from then on. | Every recruitment in the series. FE7's Matthew and Serra arrive at a chapter boundary; enemy/NPC recruits convert mid-map and stay. |
| 3 | **Guest** | A unit fights alongside you for one chapter, carrying gear you did not give it, and is gone afterwards (sometimes returning later as a permanent join). | FE7 Ch.19xx; FE8 Ch.5x's Orson; Thracia's assorted temporary allies. |
| 4 | **Substitute** | This chapter fields a *different named cast*. Your army is set aside for its duration and resumes intact at the next chapter. | FE8 Ch.5x "Unbroken Heart" (Ephraim, Forde, Kyle while Eirika's army waits); Thracia's Leif-alone escape chapters; FE9's Ike-only prologue. |

Wholesale army *replacement* does exist in the series — FE4's generational handover, FE10's
four rotating armies by Part (with Part 4's three groups assigned by the player from one
pool), FE7's Lyn mode feeding into Eliwood's, FE8's route split. In every case it is a
**signposted campaign-structural boundary**, presented to the player as "this is a different
army now". It is never a per-chapter knob, and the player is never surprised by it.

### 1.1 The standalone/trial case

The series' standalone modes are the closest analogue to launching a map outside a campaign,
and they divide the same way:

- **Skirmish-style** (FE8's Tower of Valni and Creature Campaign, Awakening/Fates skirmishes)
  draws the persistent army from a cleared save.
- **Arena/trial-style** (the link arenas and trial maps of the GBA era) fields a cast the
  *map* decides — preset stat blocks, or the player's own units picked under a point cap —
  with no relationship to a campaign in progress.

**The load-bearing observation is what these modes do not change: the rules.** A trial map
still runs the weapon triangle, effectiveness, terrain and every other combat rule the
campaign runs. No game in the series switches a combat rule off because the player is not in
a campaign. The ruleset belongs to the game and its content; the *army* is what standalone
play varies.

---

## 2. Advance Wars — there is no army

The contrast is total and it is instructive.

- Units are **built per map from funds** via captured production properties. Nothing carries
  between missions; every mission starts from the force the map itself authored plus whatever
  the player can afford during it.
- Campaign maps ship **pre-placed starting units authored in the map file**. The map owns its
  force outright.
- What persists across the campaign is the **CO** — the commander, its power meter and the
  unlocked roster of COs — not any unit.
- War Room and Versus maps are standalone and use the same authored per-map force, with no
  carry-over in either direction.
- Veterancy (Days of Ruin's unit ranks) is **within a map only**.

So Advance Wars is the pure "the map owns the force" model. It is exactly the model the
project's standalone map-registry route already implements, and it is the reason that route
is not a mistake and should not be removed.

---

## 3. The engine, measured against the pattern

Measured on `agent/integration` at `c7577074` and on
`agent/from-integration/interaction-rule-contract` at `bb241466`.

| Genre shape | Engine support | Evidence |
|---|---|---|
| **Constrain** | **Fully built, and already at the node.** | `CampaignNode.required_units` / `excluded_units` / `deployment_cap` (`scripts/resources/CampaignNode.gd:41-46`), validated in `CampaignData.parse`, enforced in `DeploymentPlan.gd:85-106` and surfaced in `PrepScreen.gd:88-219`. This is `[CST-5]`, resolved 2026-06-21. |
| **Add (join)** | **Absent entirely.** | `player_roster` is only ever wholesale-assigned or cleared — there is no append anywhere outside tests (`GameState.gd:535,538,560,600,1146`). `SaveData.recruited_flags` exists as a serialized field with **no writer**. No campaign-layer call adds a unit. |
| **Guest** | Absent — a special case of the above. | — |
| **Substitute** | Absent, and the one thing `resolve_launch_params` deliberately refuses. | `CampaignManager.gd:759-767`: any node after the first is forced to `keep_current_roster`, with a comment giving the correct genre reason (levels and gold would reset). |
| **Map owns the force** (AW) | **Built.** | Map-registry `roster_policy` / `roster_source`, `DataManager.gd:1539-1633`, policies `default_roster` / `fixed_test_roster` / `keep_current_roster`. |

### 3.1 The army cannot change size

This is stronger than "joining is unimplemented". The roster is **fixed at node 1 for the
whole run**, and two mechanisms depend on that:

- `GameState._validate_restore_entry` (`GameState.gd:1413`) rejects a ledger entry whose
  `party.roster` count differs from the live `player_roster` size. A joining unit would
  invalidate every ledger entry recorded before it joined.
- Permadeath *marks* rather than removes — `DeathLifecycle` sets `is_incapacitated`, and
  `CampaignManager._full_heal_roster` walks the same fixed array every launch.

So the shape is deliberate and load-bearing, not an oversight. Growing the army is a real
piece of work touching the save ledger, not a one-line append.

### 3.2 What the acceptance content actually wanted

`roster__roster_map_006_hallowed.json` in the FE pack is **not an authored chapter cast**.
It is a two-unit A/B bench: `m006_hallowed_bearer` and `m006_plain_axeman`, identical in
every stat, differing only in the weapon in slot one. That is a trial map in the §1.1 sense,
not a chapter.

Which relocates the problem. Route A — launching `map_006_hallowed` from its own map-registry
row — is the route this content wants. Route A's defect is that `GameState.campaign_rules`
is empty outside a campaign run, so the pack's own authored relationships do not apply. In
series terms that is **a trial map with the weapon triangle switched off**, which no game in
either series does.

The engine models rules as campaign-scoped by design (`CampaignRules`, with per-node
`rule_overrides`), so a map launched outside a campaign has no ruleset at all. That is the
hole, and it is not specific to this pack: it hits any pack shipping a trial, skirmish or
validation map. `map_900_hotseat_validation` and `map_950_promotion_validation` are reachable
only by the same route.

---

## 4. What the pattern rules on the row's three candidates

**Candidate 1 — a per-node `roster_policy` the campaign node may author. Rejected.**
No mainline Fire Emblem chapter swaps the army, and the four games that replace an army do it
at a structural boundary the player is shown. Giving a node this knob would let an author
silently reset levels, gold and inventory mid-run — the precise outcome the comment at
`CampaignManager.gd:759` already identifies and refuses. It also answers a question the
series answers with constraints, which the engine already has.

**Candidate 3 — authored per-map rosters are standalone-only. Accepted.**
This is both series' answer: Advance Wars' map-owns-the-force and Fire Emblem's trial maps.
`map_900` and `map_950` are already correct under it and need no change.

**Candidate 2 — a map-scoped guest/reinforcement list merged into the carried party.
Right in spirit, too small as stated.** The genre primitive underneath the guest is
*joining*, and §3 measures that the engine has none. Scoping this to "guests merge for one
map" would build the exception before the rule, and would still leave the series' single most
common roster event — a unit joins and stays — unrepresentable.

**A fourth answer the row did not list, and the one the acceptance content needs:** a
standalone map launch should carry the ruleset of the pack whose content it uses. See §3.2.

---

## 5. Pointers

- Row: `ROUTE-GAP-ACCEPTANCE-CONTENT-2026-09-20`, depends on
  `AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10`.
- Rulings: [`campaign_roster_composition_2026-09-20.md`](../registers/campaign_roster_composition_2026-09-20.md) (`ROS-1..6`).
- Deployment constraints: `[CST-5]` in
  [`campaign_save_open_decisions_2026-06-21.md`](../registers/campaign_save_open_decisions_2026-06-21.md).
- Node composition: `[CNC-1..10]` in
  [`campaign_node_composition_open_questions_2026-07-03.md`](../registers/campaign_node_composition_open_questions_2026-07-03.md).
- Evidence suite: `scripts/tests/test_interaction_acceptance_playthrough.gd` on
  `agent/from-integration/interaction-rule-contract` — its "route gap A", "route gap B" and
  "route gap B, on the board" checks are the measurement §3.2 rests on.
