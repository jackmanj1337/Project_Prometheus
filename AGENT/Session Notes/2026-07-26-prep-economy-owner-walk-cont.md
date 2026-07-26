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

**EPUX-03 ratified — wide/narrow composition.** Option **C**, confirming accepted
`UI-ARCH-02`: one presentation controller/state model, wide list/detail and narrow
sequential compositions selected by **measured content width** (never a platform or device
name), selection and focus preserved across the transition. 200% Menu Scale can force narrow
at a nominally wide viewport, so narrow is not a "mobile-only" path.

Added a **pane-budget contract**, which the original single-list framing had no reason to
consider: the ratified structure creates a chain up to five levels deep (node menu → Explore
→ subject picker → activity list → activity panel).

- **Default: at most two panes, pairing adjacent levels** — subject | activity-list, then
  activity-list | panel. Never three: a third pane collapses at 200% Menu Scale and steals
  width from the terminal panel, which needs it most.
- **Full-width escape hatch** (owner addition): a panel may declare it wants the whole
  available width, and the shell presents it alone, dropping the companion pane; the parent
  level stays reachable by back/breadcrumb. For content-dense panels — shop grids, forge
  before/after, Map Preview, the global item-first bulk view.
- Declared by the **panel type in the registry** (a property of its content shape), not a
  per-campaign authoring knob — campaign authors do not make layout decisions.
- A **preference, not an override**: meaningful only when there is room for two panes at
  all; moot in the narrow composition. Taking or releasing full width preserves selection
  and focus like any wide↔narrow transition.

**EPUX-04 ratified — shared screen shell.** Option **C**, confirming accepted `UI-ARCH-01`:
shared presentation primitives keyed by an opaque stable record id, domain managers keeping
ownership of records and mutations, queries/actions as callbacks and action descriptors. No
campaign schema in the shared layer, no hardcoded activity enum. (Option B is the closed
type-switch this repo treats as a smell.)

**Availability gating promoted to a shell primitive.** The EPUX-02 ruling requires one
gating rule across all four surfaces; that is only enforceable if the shell implements it.
So the shell owns predicate evaluation, the hidden-vs-disabled decision, the disabled visual
treatment, and unmet-reason placement — adapters supply only the predicate, its player-facing
reason string, and the per-entry gate presentation. Four adapters therefore cannot drift into
four disabled treatments, and EPUX-02 is testable in one place. This also makes the deferred
focusability question a shell-level decision.

**Correction to the register's own status section.** EPUX-28 was briefly mis-read as ruled.
It is **not** — it has a recommendation (C) only. The false positive came from regex-splitting
the doc on `### [EPUX-nn]`: EPUX-28 is the last question, so its body runs into the following
`## Node traversal and cadence model (owner-ratified 2026-07-25)` heading. The "Decision
status" section is the authority; trust it over a grep.

## Commits claimed

- `8988c31073a9714273b11e6f215d401659f6720a` — Ratify EPUX-02: absent hides, gated disables, per-entry secret gates
- `c5aac36727992a0a6552b33a3bd79997a7ca181e` — Ratify EPUX-03/04: pane-budget contract + gating as a shell primitive

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

Resume the walk at **EPUX-06/07** (confirmation policy; transaction result and failure
feedback). They pair naturally — both are about what happens around a commit — and they
also carry the deferred **focusability** question, which EPUX-04 just established is a
shell-level decision rather than a per-panel one.

Open after this session: EPUX-06, 07, 09, 10, 12, 13, 15, 17, 19..28 — **18 questions**.
The shell block (EPUX-01..05) is fully closed. EPUX-19..27 (Training-Hall benefit
presentation plus the forging cluster) is the largest remaining group and several of those
merely confirm an existing register, so they are candidates for a batch pass.
