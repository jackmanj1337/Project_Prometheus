# Session Note - 2026-07-26 (prep/economy owner walk, continued)

Continues [2026-07-25-prep-economy-owner-walk.md](2026-07-25-prep-economy-owner-walk.md).
Register: `AGENT/Docs/design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`.

## What was done

**Session setup.** Restored both working branches for the continued walk:

- `Project_Prometheus` → `agent/from-integration/campaign-data-research` (was already
  checked out; clean and synced at `6dc7ca0` before this session's commit).
- Container repo → switched from `main` to
  `agent/from-staging-area/campaign-research-findings-tracker`, which holds the walk's
  tracker rows. Confirmed that branch is content-strictly-ahead of `main` (main's only
  extra commit, the PR #18 merge `34732d9`, is content-identical to its second parent
  `bf69c4e`, which the branch already contains) — so no merge was needed in either
  direction.

**Contamination reverted.** Four tracked files in `Project_Prometheus` carried uncommitted
edits rewriting `godot-prometheus-env` → `pydev-env` and `GODOT_ENV_ROOT` → `PYDEV_ENV_ROOT`
— leakage from the pydev-env fork's rename sweep (see the pydev-env workspace branch on the
container repo). Wrong for this repo; restored. Affected: `AGENTS.md`,
`AGENT/Code Reviews/process_history_tooling_review_2026-07-17.md`,
`AGENT/Docs/archive/handoffs/handoff_container_tooling_goal_2026-07-17.md`,
`AGENT/Docs/playtests/playtest_checklist_v0.5.2_returned_2026-07-21.md`.

**EPUX-02 ratified — availability presentation.** Option **B**, extended in two ways the
original single-flat-list framing did not anticipate:

1. **Two-state rule.** *Absent* (the campaign never authored the entry) → **hidden**.
   *Gated* (authored, predicate currently false) → **shown disabled with a reason**.
   This generalizes what the ratified prep-hub section already said for the absent half
   ("non-battle nodes hide the battle-only entries"; "only panels the campaign actually
   uses appear") and supplies the gated half.
2. **Uniform across all four availability surfaces** the ratified structure created: the
   top-level node menu, the Explore subject picker, the Explore per-subject activity list,
   and the Manage Roster panel registry. No surface-specific exceptions.
3. **Gate presentation is a per-entry authoring property** — `visible-disabled-with-reason`
   (default) or `hidden-until-met`. Same predicate; only the presentation of an *unmet*
   predicate differs. Rationale: plain B cannot express "authored, gated, and **secret**",
   which is a real authorial intent — a story-locked shop whose disabled label would spoil
   a deliberate reveal. The default preserves B's discoverability.

**Implication recorded for implementation:** the open predicate registry must expose a
player-facing **unmet-reason string**, not just a boolean. A predicate that cannot explain
itself can only be authored `hidden-until-met`. Also noted that `hidden-until-met` must not
become the lazy default in authoring templates.

**Flagged derived-not-ruled:** whether disabled entries stay keyboard/controller-focusable
so the reason is screen-reader reachable rather than hover-only. Recommended
focusable-but-not-activatable; deferred to EPUX-04/06/07 and the accessibility pass.

**Correction to the register's own status section.** EPUX-28 was briefly mis-read as ruled.
It is **not** — it has a recommendation (C) only. The false positive came from regex-splitting
the doc on `### [EPUX-nn]`: EPUX-28 is the last question, so its body runs into the following
`## Node traversal and cadence model (owner-ratified 2026-07-25)` heading. The "Decision
status" section is the authority; trust it over a grep.

## Commits claimed

- `8988c31073a9714273b11e6f215d401659f6720a` — Ratify EPUX-02: absent hides, gated disables, per-entry secret gates

## Gates

- `scripts/agent-commit.sh` pre-commit (docs-only path): analyzer tool tests 12 passed;
  scene-integrity 22 scene-attached scripts PASS; session-claims PASS (136 commits audited);
  evidence-matrices PASS; gdformat/gdlint 238 files unchanged, no problems. Godot suite
  skipped as docs-only.
- `scripts/agent-push.sh --repo Project_Prometheus` full suite: **all suites green**.
  Receipt: `audit/check-receipts/Project_Prometheus-full.json` (tree `4ca9391b60de`, exit 0).
- First push attempt was correctly rejected by the session-claims gate (`8988c31` claimed
  0 times); this note is the claim.
- `AGENT/Docs/gen_docs_index.py` re-run — no index changes (doc header unchanged).

## Next

Resume the walk at **EPUX-03** (wide/narrow composition). Open after this session:
EPUX-03, 04, 06, 07, 09, 10, 12, 13, 15, 17, 19..28 — **20 questions**. EPUX-03/04 are the
remaining shell questions and pair naturally; 19..27 (Training-Hall benefit presentation and
the forging cluster) are the largest remaining block and several are batch-confirmable.
