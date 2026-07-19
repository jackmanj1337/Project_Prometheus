---
Type: plan
Status: Planned - playtest-waiting implementation handoff
Last verified: 2026-07-19
---

# Playtest-Waiting Work Queue Handoff - 2026-07-19

Supersedes [`playtest_waiting_work_queue_handoff_2026-07-16.md`](../archive/plans/playtest_waiting_work_queue_handoff_2026-07-16.md),
which named the wrong outstanding return (v0.4.1), pointed at a retired branch, and
listed the owner walkthrough as pending.

## Goal

**Land Slice A of the AI scorer — `CombatResolver.project_exchange()` — as a
side-effect-free ordered exchange projection that changes no AI behavior, so that
the moment v0.5.2 evidence returns the AI track is unblocked rather than beginning.**

Success is a merged-ready branch where `project_exchange()` exists with tests,
`preview_combat()` is untouched, every shipped AI decision is byte-identical, and
nothing player-visible has moved. If Slice A completes early, drain the secondary
queue below in order.

Slice A is chosen because it is the one prerequisite that every later AI slice needs,
it is pure engine plumbing with no gameplay decisions left open, and it touches a
file the outstanding v0.5.1 fixes do not — so it cannot collide with the merge that
is already queued.

## State as of 2026-07-19

- **Outstanding return:** v0.5.2 Windows verification. Watch `AGENT/Incoming/v0.5.2/`.
  `AGENT/Incoming/v0.5.1/` is a *closed* return — root-caused in
  `AGENT/Code Reviews/playtest_v0.5.1_root_cause_review_2026-07-18.md`, fixed in
  `8b77c9d`, evidence archived under `AGENT/Docs/archive/evidence/`.
- **AI owner decisions are settled** (2026-07-19). Answers and rationale live in
  [`weapon_attack_scorer_preimplementation_decisions_2026-07-16.md`](weapon_attack_scorer_preimplementation_decisions_2026-07-16.md).
  Ratified scope is joint `(tile, target, source)` with exact bounded kill
  probability and threat/exposure scoring — larger than one slice, so that document
  now sequences the work as Slice A / B / C.
- **The v0.5.1 fixes are not on `agent/integration`.** `8b77c9d` sits only on
  `agent/playtest-release-v0.5-fixes` and merges before v0.6. Plan around it.

## Preemption rule

At session start, and before each new logical commit, check `AGENT/Incoming/v0.5.2/`.
If the return has arrived, stop at the current green commit and triage it — the
completed checklist, original log, platform/input details, and screenshots — before
resuming this queue. Do not mix returned-result repairs into an unfinished feature
commit.

Before writing any new analysis of a return, **search for existing analysis first**
(`AGENT/Code Reviews/`, `AGENT/Docs/playtests/`, and the branch that cut the build).
A v0.5.1 triage document was written and discarded on 2026-07-19 because a deeper
root-cause review already existed.

## Branch plan

Lifecycle refs are unchanged: `agent/stable-release` is stable, `agent/integration`
is the normal feature base, `agent/playtest-release` isolates release hardening, and
`agent/coordination` owns the registry. Agents never merge.

| Work | Branch from | Branch name | Merge target |
|---|---|---|---|
| AI Slice A / B / C | see decision tree below | `agent/from-integration/<slug>` | `agent/integration` |
| `B3-CAMPAIGN-RULES` | `agent/integration` | `agent/from-integration/<slug>` | `agent/integration` |
| `B3-PHB` | `agent/integration` | `agent/from-integration/<slug>` | `agent/integration` |
| Headless hardening | `agent/integration` | `agent/from-integration/<slug>` | `agent/integration` |
| **v0.5.2 return repairs** | `agent/playtest-release-v0.5-fixes` | `agent/from-playtest-release-v0.5-fixes/<slug>` | `agent/playtest-release-v0.5-fixes` |
| Container/workflow tooling | Container `main` | `agent/from-main/<slug>` | Container `main` |

**Returned-evidence repairs never land on `agent/integration`.** They belong on the
v0.5 fixes line so the release branch stays the single source of the shipped fix set,
exactly as the v0.5.1 repairs did.

### Which base does AI work start from?

`agent/from-integration/ai-scorer-decisions` carries the ratified decisions and is
`in_review`, awaiting human merge.

- **If it has merged to `agent/integration`:** branch Slice A from `agent/integration`.
- **If it has not:** branch Slice A from `agent/from-integration/ai-scorer-decisions`
  and set the merge target to `agent/integration`. Note the stacked base in the
  tracker `base_branch`/`base_sha` so the review order is obvious.

Do not copy the decisions document onto a second branch to avoid stacking; two
divergent copies of a ratified decision record is worse than a stacked branch.

### Merge-conflict surface to avoid

`8b77c9d` is unmerged and will land on `agent/integration` before v0.6. Waiting work
that edits these files will conflict with that merge:

```
scenes/ui/MainMenu.tscn                             scripts/core/GameMap.gd
scripts/autoloads/CampaignManager.gd                scripts/core/TurnManager.gd
scripts/autoloads/DataManager.gd                    scripts/resources/CampaignTier2RuntimeAdapter.gd
scripts/autoloads/SettingsManager.gd                scripts/resources/CampaignTier2Validators.gd
scripts/ui/MapResultsScreen.gd                      scripts/ui/NewGameScreen.gd
```

Consequences for this queue:

- **Slice A is clear.** It touches `scripts/core/CombatResolver.gd`, which is not in
  that set.
- **`B3-CAMPAIGN-RULES` is the highest-risk item.** It is expected to touch
  `CampaignManager.gd` and the Tier-2 adapters/validators, all of which `8b77c9d`
  rewrote. Prefer taking it *after* the v0.5 fixes merge, or keep the change confined
  to `scripts/resources/CampaignRules.gd` and the save envelope.
- **`B3-PHB` and headless hardening are clear** as long as they stay in new files and
  fixtures.

## Ordered queue

### 1. AI Slice A — ordered exchange projection *(the goal)*

Add `CombatResolver.project_exchange()` beside `preview_combat()`, reusing
`_build_combat_context` / `_collect_combat_modifiers` / snapshot-restore. It must:

- model first-strike effects, follow-ups, multi-strikes, weapon breakage, and death
  stopping later strikes — the ordering `preview_combat()`'s flat aggregate cannot
  express;
- leave `preview_combat()` byte-identical, so shipped UI cannot regress;
- carry a style slot for **both** combatants with the defender's pinned null, per
  `[STY-8]`, so counter styles retrofit cheaply later;
- take proc handling as a **parameter** (`exclude` default vs `expected_value`)
  rather than inheriting the hardcoded `preview = true` skip in
  `SkillHandler.apply_trigger()`;
- expose a deterministic cache keyed `(attacker, defender, source,
  attacker_terrain_bucket)` — deliberately excluding the tile, since the exchange
  outcome does not depend on which reachable tile the attack is launched from.

Exit evidence: purity/determinism tests, extreme-value bounds, no HP/durability/
inventory/skill-counter/RNG mutation during projection, and unchanged
`shipped_compatibility` decisions. **No AI behavior changes in this slice** — if any
shipped AI decision moves, the slice is wrong.

### 2. `B3-PHB`

Build the open prep activity/panel registry after re-reading the resolved prep-hub
decisions (`PHB-1..7` are settled: flat opt-in node panels, node-scoped availability,
battle nodes first, free navigation with one commit, cosmetic theme, immediate party
transactions). Validate activity descriptors, resolve panel factories through a
registry, carry results only through existing Action/Effect and campaign-state seams,
and land one inert fixture. Convoy, shop, training, arena, and recruitment stay
separate tracks.

Promoted above `B3-CAMPAIGN-RULES` because it is conflict-free against the pending
v0.5 merge.

### 3. Headless hardening

No gameplay decisions required: malformed/legacy save and package fixtures,
transactional write-failure injection, ledger/suspend determinism comparisons,
mutable-runtime serializer ownership audit, ObjectDB test-fixture cleanup, and UI
harness measurement. **Do not visually tune any v0.5.2 surface while its screenshots
are outstanding.**

### 4. `B3-CAMPAIGN-RULES`

Data-driven rule profiles over the existing `CampaignRules`, save envelope, and
registry foundation, with `locked|start|mid_run` tunables. Preserve the shipped
default profile exactly. Cover profile validation, override precedence, mandated
rules, between-map and mid-map round trips, old-save defaults, package identity, and
New Game selection. Difficulty UI and death-mode content stay with
`B4-DIFFICULTY-DEATHMODE`.

Deferred to fourth **only** because of the merge-conflict surface above, not because
it is less ready. If the v0.5 fixes merge first, promote it to second.

### 5. Remaining dependency-valid queue

One bounded unit at a time, in control-plane order: `B4-ENCOUNTER-MODEL` split
completion; `B3-MOVEMENT-VULN-REGISTRY`; `B3-RESOURCE-POOLS`; `UI-INSPECTION` /
`VAL-V021-12` headless-safe increments; suspend/save hardening and
`VAL-FIXTURE-GAPS`; `B3-STAT-REGISTRY` only with a complete migration plan;
TCV/REQ/text/dialogue reconciliation; compatible content authoring.

Do not skip a recorded dependency because its target has partial code. Update stale
row text when evidence proves a dependency is already satisfied.

## Shared delivery rules

1. Re-read the track's control-plane row, GDD owner, decision/register source, and
   the latest relevant session note.
2. Register the branch in `coordination/tasks.json` before implementation. If
   `agent-start-task.sh` cannot run, register manually and say so in the task
   `reference` — an unregistered branch is a coordination gap, not a shortcut.
3. Derive a requirement/evidence matrix before claiming a multi-part track.
4. Keep author-facing extension points as open registries or predicates.
5. If behavior changes, update the owning GDD and roadmap status in the same commit;
   if the save shape changes, update the F1 manifest and migration tests.
6. Add focused deterministic tests before or with production code.
7. Commit one logical green increment, then re-check for returned evidence.
8. Run `check_docs.py`, the RNG guard, pinned style/lint, focused suites, and the
   full suite before a track-level handoff.

## Explicitly parked

Do not start release/merge/upload work, replace a playtest build, remove debug aids,
or begin remote play, public builder, hex topology, advanced AI search, Laguz, the
full Awakening supplement, or dependency-skipping convoy/shop/object features during
this waiting stream. Do not implement AI Slice B or C until Slice A is merged.

## Next-session starting point

The next session's task list is the `1-waiting-work` queue, worked in `order`. It is
authored in the workspace `AGENT/WAITING_WORK.md` (one level above `repo/`) and in
`coordination/tasks.json`; this document carries the *rationale* for the ordering,
not a second copy of the list.

**The first queued task is in the Container repo, not this one** —
`WAITING-WORK-GENERATE-QUEUE-2026-07-19`, generating that queue table from the
tracker so it stops being hand-maintained. The first task here is
`AI-SLICE-A-PROJECT-EXCHANGE-2026-07-19`.

Starting steps for the Slice A task specifically:

1. Check `AGENT/Incoming/v0.5.2/`. If the return has arrived, triage it instead —
   on a branch off `agent/playtest-release-v0.5-fixes`.
2. Confirm the worktree is clean. If `agent-start-task.sh` refuses, check whether the
   Container fix `agent/from-main/check-worktree-tooling` has merged; on a fresh
   container `agent-commit.sh` still needs `--bypass-check` until it does.
3. Determine whether `agent/from-integration/ai-scorer-decisions` has merged, and
   pick the Slice A base accordingly.
4. Re-read the ratified decisions, especially the Slice A bullet list in the
   rewritten implementation sequence.
5. Write the Slice A requirement/evidence matrix before production code.
6. Implement `project_exchange()` with focused tests, run the gates, and commit one
   green increment.
7. Update the task's `status` in `coordination/tasks.json` and regenerate
   `ACTIVE_WORK.md` in the same change — a queue nobody updates is worse than none.
