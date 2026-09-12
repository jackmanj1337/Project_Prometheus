# Session Note - 2026-08-21

## Branch context

- Branch: `agent/from-integration/availability-surface-gate-guard`
- Base branch: `agent/integration`
- Base SHA: `995ab851b9d4afd13aa0b21aaac086bb6f9ccc5c`
- Coordination Work ID: `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20`

Checked `v078_waiting_work_handoff_2026-08-21.md` §1 first, as it demands: **the round
still has not returned.** `WINDOWS-PASS-READINESS-2026-08-20` is `in_progress` and the
owner confirmed it. So the preemption rule did not fire, and this session ran **item 4**,
the last entry in that handoff's order.

## What was done

### `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20` — built, not closeable

The row's design question was already settled in favour of the check over a shared
availability-list builder. Building it surfaced a second question the row did not
anticipate, and the answer determined the whole shape.

**The shell has no single carrier for a gate reason.** A check needs one thing to check
for; there were four:

| Screen | Where the reason went |
|---|---|
| `MainMenu`, `OverworldScreen` | `tooltip_text` on the button, mirrored to a status line |
| `PrepScreen` | `_validation.text` — a sibling label |
| `MapResultsScreen` | `_save_status_label.text` — a sibling label |
| `MapMenu`, `GameOverScreen`, `CampaignLibraryScreen`, `SettingsScreen`, `HudLayoutEditor` | nowhere |

Ruled on the evidence that produced instance six: **the carrier is `tooltip_text` on the
gated button itself**, and a sibling label does not satisfy the check. A label explains
the gate to someone who can see the whole screen; it is not announced when focus lands on
the disabled button, which is exactly how Continue and Load Game sat unexplained on the
first screen of the game for months. Two screens therefore count as defects despite
"having" a reason today, and that is deliberate rather than a false positive.

`scripts/ci/check_availability_reasons.py` pairs every `<recv>.disabled =` with a
`<recv>.tooltip_text =` in the same file, in `scripts/**/*.gd` and in `scenes/**/*.tscn`.
The scene half has **zero sites today** and is there so the scene file does not become the
way around the script rule. Wired into `pre-commit` and into both CI workflows next to the
`check_rng_usage.sh` step it is modelled on; the workflow edit was approved by the owner
in-session, as `.github/workflows/**` requires.

**All 32 existing sites were triaged, not baselined.** A central baseline file rots
unread; a marker at the site is in front of the next author to edit that line.

- **4 are not gates at all** and need no marker: `disabled = false` *enables* an entry.
  The checker skips those outright rather than making them carry a waiver, because
  requiring a marker on a reset is how a waiver vocabulary stops being read.
- **3 are waived at the site** with `# availability-allow:` — PrepScreen's two
  list-reorder arrows at the end of their travel, and GameOverScreen's Rewind, which the
  `.visible` line below it drops from the tree entirely, so it is never a *reachable*
  gated entry.
- **25 carry `# availability-todo: AVAILABILITY-REASON-REMEDIATION-2026-08-21`**, each
  with a one-line note of the reason that is owed. They pass, and they are **printed on
  every run** with a count, so the deferral cannot go quiet.

A marker is honoured on the assignment line **or the comment line directly above it** —
several of these assignments were already near the line-length cap before any comment.

**Twenty distinct gated entries across nine screens owe a reason.** That is the new row
`AVAILABILITY-REASON-REMEDIATION-2026-08-21`. Its first attempt at registration was
**rejected by the path-claim guard**: `scripts/ui` collided with three live rows. Narrowed
to seven specific files; `MapResultsScreen.gd` and `PrepScreen.gd` are in its scope but
are claimed by `DESIGN-OVERWORLD-CADENCE-2026-07-25`, which is `in_review` and is part of
what this round verifies, so they stay unclaimed until it closes.

**A second tracker gotcha, worth knowing before the next row is registered:
`agent-add-task.sh` creates rows as `in_progress`, not `planned`.** The remediation row
read as work already underway until it was corrected, which is the kind of error that
makes a queue lie about how much is in flight. Read the row back after registering it.

**The row cannot be closed**, exactly as the handoff predicted: its dependency
`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` is `in_review` and this round is its
verification. Status moved to `in_review`, not `completed`.

### One policy call worth recording: this landed as product, not infrastructure

A guard plus a hook plus two CI steps is textbook infrastructure and would normally go
**direct to `agent/staging-area`**. It did not, and the reason is structural rather than a
judgement call: the guard is **red without the markers**, and the markers are comments in
nine product files. Splitting the change would land a check on staging that immediately
fails against staging's own copy of those screens. AGENTS.md covers this exactly — *"If it
cannot be split, treat it as product"* — so the whole change went to `agent/integration`
and reaches staging by the release line.

The cost is real and should not be silent: **until the release line carries it, the
`pre-commit` on `agent/staging-area` does not run this guard.** That is the mirror image of
the gap `check_shared_infrastructure_sync.py` exists to prevent, and that check does not
fire in this direction — it fails a *staging push* that strands executed infrastructure,
not an integration merge that has not reached staging yet.

## Commits

Ownership is in `CLAIMS.tsv`.

`fe27bd12` adds the checker, its unit tests, the hook and CI wiring, and the 28 markers.
It is one commit and not three on purpose: a rule and its enforcement that land separately
leave the tree red in between. Merged to `agent/integration` at `757050c0`.

`0e1212cb` then corrects the guard's own output, found by running it on the real tree
after the merge rather than only through its fixtures: it printed `1 gated entrie(s)`,
and its PASS line claimed *every gated entry carries a reason* directly beneath a count of
25 that do not. Cosmetic, but a guard whose whole job is to teach a rule should not read
as contradicting itself.

`5b39a0e5` is this note; `7d3fb685` is its ledger claim.

## Gates

- `bash run_tests.sh` — **PASS**, checked past the exit code per the recorded harness
  trap: **0** `SCRIPT ERROR` lines, **144** results lines, **0** reporting a non-zero
  failure count.
- `python3 scripts/ci/test_check_availability_reasons.py` — **12 tests, OK**. Every case
  asserted in **both directions**, per the lesson from the pack-freshness check: a guard
  verified only green is how that one briefly reported SKIPPED against a workspace that
  had both packs cloned.
- `python3 scripts/ci/check_availability_reasons.py` — PASS, 25 deferred.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 335 files.
- `python3 AGENT/Docs/check_docs.py` — PASS (46 checks).
- Both workflow files re-parsed with `yaml.safe_load` after editing — 11 steps each, the
  new step present. Editing YAML by string substitution and *not* re-parsing it is how a
  workflow breaks silently.
- **Post-merge probe on the real tree**, not only the fixtures: a throwaway
  `scripts/ui/probe/ProbeScreen.gd` with one unmarked gate produced
  `FAIL: 1 gated entry with no reason on the entry`, naming the file, the line and the
  rule; removed afterwards, tree clean. Asserted on the printed FAIL line rather than an
  exit code, because the recorded `&& echo` trap makes an exit code after a pipe the
  *pipe's* status — the run that produced this evidence printed `PROBE_EXIT=0` for a
  check that had correctly failed.

## Next

**The handoff's order is now fully spent.** Every item is `completed` except item 4, which
is `in_review` and can only be closed by the round.

When the round returns, triage preempts everything at the next green commit; repairs go on
`agent/playtest-release-v0.7.8`, and at acceptance `v0.7.8` is tagged at **`b14d4943`**,
the commit baked into the BUILD STAMP, not the branch tip.

Work that exists and is not blocked on the round:

1. `AVAILABILITY-REASON-REMEDIATION-2026-08-21` — 20 gated entries, 7 screens claimable
   now. Needs player-facing wording and `TextDB` keys, so it is an owner-facing job rather
   than a mechanical one.
2. `PREDICATE-PARAM-VALIDATION-2026-08-21` — still blocked on `UNMET-REASON-TEXT-TABLE`.

**Three tracker decisions remain open for the owner**, unchanged from the previous
session and still blocking nothing: re-status `TEXT-V1-S01..S04` as built; the
`B4-IEQ-ITEMS-EQUIPMENT` → `PREP-V1-S02` edge; and whether `PREP-V1-S01` adopts
`PrepActivityRegistry` or `B3-PHB-REGISTRY` shipped the wrong shape — **settle that one
before `S01` starts**, or `S01` builds activity resolution twice.
