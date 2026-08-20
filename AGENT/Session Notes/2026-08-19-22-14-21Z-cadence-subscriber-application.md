# Session Notes — 2026-08-19-22-14-21Z-cadence-subscriber-application (Cadence Subscriber Application)

## What was done

The bounded remainder the previous session handed off: applying fired cadence triggers to the four
subscriber families. What was missing was not the wiring but the **binding format** — a subscription
recorded only a trigger id, so nothing said what a fired trigger selects.

- **Payload-carrying bindings.** A subscription entry is now a bare trigger id (`value = true`) or
  `{trigger, value}`. Authored order is the precedence contract, as node order already is: the last
  satisfied binding wins, so an author appends an override instead of rewriting earlier entries.
  `CampaignData` rejects a binding naming an undeclared trigger, a malformed entry, and a
  non-array subscriber at load.
- **Active vs fired.** Evaluation answers two different questions, and conflating them is what a
  single `fired` list was hiding. A standing selection (battle target, activity set, activity
  variant) reads what is **active** — an `after` counter past threshold, a met or latched predicate.
  An `every` interval is an **event** at a boundary and is never a standing selection, so it can no
  longer be subscribed to as one.
- **The tick is the stock seam.** `[CVS-S6]` puts the restock cadence reference on the stock
  **entity**, not the node, so stock could not use node subscriptions at all. Evaluation keeps a
  durable per-trigger tick counting *edges*; an entity stores the tick it last acted on and compares.
  That needs no drain protocol, lets many entities share one trigger, and cannot lose a tick to a
  reload the way an unread event queue would.
- **Counters actually tick.** `increment_cadence_counter` had no production caller, so the whole
  engine was inert. `chapters_elapsed` and `chapter_reached.<node_id>` advance on a committed clear
  — *before* the successor is prepared, and a stale pre-tick preparation is discarded when the
  selection moved — and `deployments_total` advances once per launched visit.
- **`battle_target` applied**, at launch resolution, so all three launch routes (linear advance,
  overworld entry, revisit) swap the battle from one place. A satisfied binding replaces the
  authored pair wholesale; a half-inherited binding would launch a map nobody authored.

## Factual Git state

- Branch: `agent/from-integration/overworld-cadence-spec`
- HEAD: `0d1e5eaa4363772ec20369f8bcd76d32377b2cdf`
- Task merge base: `1c39521c7cecbd72c1ff2da34c9d8069abee56e0`

## Commits

- `0d1e5eaa` Apply fired cadence triggers to node subscribers

## Checks

- `bash run_tests.sh`: required non-Godot checks green, 146 Godot suites green (run twice — once
  before the commit, once by `agent-commit.sh` against the exact staged tree).
- Focused: `test_campaign_cadence` 19 passed, `test_campaign_manager` 50 passed,
  `test_campaign_data` 21 passed.
- `python3 AGENT/Docs/check_docs.py`: all 46 checks pass.
- `bash scripts/ci/check_gdscript_style.sh`: PASS, 337 files.

## Decisions and context

Three judgement calls, none of them re-derived design:

1. **`chapter_reached` is a prefixed counter id, not a third trigger family.** `[EPUX]` names it a
   counter; modelling it as `chapter_reached.<node_id>` with `mode: after, threshold: 1` keeps the
   family registry at two entries and needs no engine edit per milestone.
2. **A retry is not a deployment.** The ratified revisit rule says a battle launched from a revisited
   hub *is* a real deployment event, but nothing rules on a replay. Counting one would let a player
   farm any `deployments_total` cadence by losing on purpose, which is exactly the accidental-farm
   hazard the re-entry defaults exist to prevent. A deployment is claimed once per launched visit;
   retry and suspend resume re-enter the same launched node without passing a launch entry point.
3. **Three of the four families have no consumer in the engine.** Activity set, activity variant and
   stock belong to prep/economy slices that are all `planned`; only `battle_target` has a consumer
   today. Rather than invent three payload schemas that the slices building them would have to
   honour, payloads are **opaque** to the engine and each family interprets its own. `battle_target`
   is the deliberate exception and is validated at parse time, because the campaign layer consumes it.

The preflight in `cadence_and_predicate_prerequisites_handoff_2026-08-18.md` §"Preflight verdict" is
**stale and was not edited** (it is the handoff's own record of what it found): it says `B3-TCV` is
not implemented, but `scripts/autoloads/CampaignVars.gd` (`da46a332`) and the whole of `B3-REQ`
(`87084353`, `9b7996f3` — `scripts/req/`, `RequirementSystem`) landed on `agent/integration` before
the overworld session. Session B ran; the order the handoff asked for was followed.

## Next session

Two things, neither of them this branch's:

1. `hours_played` is the one ratified counter with **no producer** — it needs the mockable clock
   seam `[EPUX]` defers real-time cadence behind, which is `A1` specification work, not this build.
2. Predicate-family triggers evaluate against `RequirementSystem` with a context carrying only
   campaign flags and vars. Widening that context (cleared nodes, roster facts) is what
   `roster_power >= X` and `unit_in_roster(X)` — `[EPUX]`'s own worked examples — will need.

Otherwise `DESIGN-OVERWORLD-CADENCE-2026-07-25`'s build half is complete and `PREP-V1-S01` is
unblocked on the cadence axis.
