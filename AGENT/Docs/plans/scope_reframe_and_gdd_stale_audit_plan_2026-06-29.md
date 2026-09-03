---
Role: dated
Type: plan
Status: Active - planning input
Last verified: 2026-06-29
---

# Next-Session Plan — Scope Reframe + GDD Stale-Assumption Audit

**Started:** 2026-06-29. Created at the end of a documentation-structure walkthrough.

**Purpose.** Two coupled jobs for the next session:

1. **Reframe the project scope/purpose** (below) and ratify it as the lens the
   GDD is read against.
2. **Audit `AGENT/GDD/`** for old assumptions and historical decisions that the
   recent updates (doc reorg `2026-06-23`, Project Control Plane `2026-06-29`,
   and this scope reframe) should have removed or replaced.

This plan does **not** itself change the GDD. It defines the order of work, the
decision artifacts to create first, and a per-chapter checklist.

---

## 1. The new scope statement (to ratify)

Proposed wording to land in `GDD_00_Overview.md` and a dated decision record:

- **Primary goal — learning & portfolio.** This is first and foremost a
  learning project and a portfolio display piece. Decisions optimize for
  demonstrable engineering quality, readable architecture, and a showable
  result — not for shipping a commercial title.
- **Secondary goal — a flexible tactical-RPG builder.** A toolset that lets
  users build and share their own campaigns with custom assets and custom
  rules. This is the product direction the design serves once the learning/
  portfolio bar is met.
- **Power-user access with a security boundary.** The true full-access path is
  the source itself: the project ships its source code for public inspection
  (likely **MIT + Commons Clause**), so anyone who wants unlimited control forks
  the repo and changes whatever they want. In-app/internal authoring support is
  therefore deliberately bounded and **will not exceed a sandboxed-scripting
  ceiling**. The *initial* target is **data-only authoring** (assets + rule
  config the engine reads; no executable scripts run from a shared campaign),
  chosen to shorten the path to a showable, complete-looking project. Sandboxed
  scripting is a later expansion, not a launch requirement.

**Showable target.** The portfolio showpiece is a playable **web demo build**,
scoped **slice-first**: a polished, complete-looking playable mission/campaign
slice first, then a demonstration that it was authored with the builder. It
should become a tracked Control Plane row (see §7).

These three goals replace any prior framing that treated the project primarily
as a single authored game or a commercial release. **Owner-approved
2026-06-29** — wording ratified as drafted (see §6).

> Note: this reframe is consistent with two directions already on record — the
> self-contained per-campaign content pack model (campaign content reframe
> `2026-06-23`) and the open-registry author-extensibility principle (`[EXT]`,
> `AGENT.md`). The audit should treat those as supporting, not conflicting.

## 2. Ratify first, then audit

Authority order is set by **DOC-001** (`GDD_00_Overview.md`): the numbered GDD
is the design contract, but ratified dated decisions outrank it. So a scope
change of this size must be ratified as a decision *before* the chapters are
edited, or the edits have no authority source.

Pre-audit steps, in order:

1. Write a dated decision record in `AGENT/Docs/decisions/` capturing the §1
   scope statement, the rationale, and what prior framing it supersedes. Add it
   to `decisions/decision_index.md`.
2. Update `GDD_00_Overview.md` scope/overview section to the new framing
   (status label, not the banned words `current`/`complete`/`canonical`).
3. Decide whether DOC-001's authority text itself needs any wording change, or
   only the scope/overview prose. Default expectation: scope prose only.

## 3. The audit pass — what counts as "stale"

For every file below, hunt for these categories of stale content:

- **Superseded directions** still written as live (e.g. base+overlay campaign
  content, any commercial-release framing, any "single authored game" scoping).
- **Historical decisions** not marked `Historical`/`Superseded` with a pointer
  to the replacement, per the doc lifecycle markers.
- **Status drift** — sections whose status label no longer matches reality or
  the Control Plane row (DoD#1 pairing).
- **Scope assumptions that contradict the §1 reframe** — places that assume the
  goal is a finished game rather than a learning artifact + builder toolset.
- **Power-user / security gaps** — places that hardcode a closed vocabulary
  where the open-registry principle (`[EXT]`) now applies, or that grant/deny
  access without naming the security boundary.
- **Retired vocabulary** — terms the vocabulary manifest
  (`project_vocabulary_manifest_2026-06-29.md`) marks as retired aliases.

For each finding, record: file + section, the stale claim, the category above,
and the proposed replacement (or "needs owner decision").

## 4. Per-file checklist

| File | Audit focus |
|---|---|
| `GDD_00_Overview.md` | Lands the new scope (§1). Verify DOC-001 order, indices, platform targets, release definition still describe a learning/portfolio + builder project. |
| `GDD_01_Architecture.md` | Builder/extensibility framing; open-registry vs closed-enum seams; where the power-user security boundary lives (load/sandbox/trust). |
| `GDD_02_Core_Mechanics.md` | Rules assumed fixed that should be author-tunable per campaign; any single-game assumptions. |
| `GDD_03_Units_Classes.md` | Author-defined vs engine-fixed content; stat-model openness (`[STM]`). |
| `GDD_04_Weapons_Items.md` | Same — content authored in packs vs hardcoded. |
| `GDD_05_Skills.md` | Effect/skill vocabulary as registry vs enum. |
| `GDD_06_Maps_Objectives.md` | Objective conditions as predicates/registry (`[TCV-4]`); map events authored, not hardcoded. |
| `GDD_07_UI_UX.md` | Prep/activity panels as registry (`[SAC]`); builder/authoring UI surface. |
| `GDD_08_Enemy_AI.md` | AI profiles as data/registry (`[AIP]`), not a closed match. |
| `GDD_10_Roadmap.md` | Build-order narrative still serves learning-first then builder; remove any commercial-milestone language; Track ID links intact. |
| `GDD_Feature_Index.md` | Status summaries match Control Plane rows; no superseded features listed as live. |
| `GDD_Adoption_Matrix.md` | Corpus adoption framed as reference feeding a builder, not as the authored game's content. |

## 5. Known suspects to verify (not yet confirmed against the files)

Candidates flagged from memory/recent reframes — **verify in-file before acting**:

- Base+overlay campaign content language anywhere (superseded by self-contained
  per-campaign packs, `2026-06-23`).
- Any closed `enum`+`match` design described as the extension point where the
  open-registry principle now applies.
- Art-pipeline / licensing assumptions tied to a single shipped game rather than
  user-supplied campaign assets.
- Platform-target prose that assumes a commercial launch rather than a portfolio
  web/demo build.

## 6. Owner decisions (resolved 2026-06-29)

These were answered by the owner and are ratified inputs for the decision record
in §2:

- **Scope wording — approved as drafted.** The three-part statement in §1 stands:
  learning/portfolio primary, builder secondary, bounded power-user access.
- **Showable target — playable web demo build.** "Portfolio display" commits to
  a playable browser build as the showpiece; add it as a tracked Control Plane
  row next session.
- **Security boundary — data-only first, sandboxed-scripting ceiling, fork for
  full access.** The public source release (likely MIT + Commons Clause) is the
  unlimited-access path. Internal support will never exceed sandboxed scripting;
  the initial milestone is data-only authoring to reach a complete-looking
  project sooner. (Consistent with the existing art-pipeline licensing
  direction.)
- **Roadmap impact — framing only.** The reframe does **not** re-sequence the
  ratified Band 1->8 build order or reopen prior v1-scope decisions. The audit
  removes/replaces stale assumptions and updates framing; it must **not** propose
  reordering Control Plane rows. This keeps the audit bounded.
- **Web demo scope — slice-first, then builder.** The demo leads with a polished
  playable slice (the game + engineering quality), then shows it was authored
  with the builder. Two-part; scope the Control Plane row accordingly.

## 7. Definition of done for the session

- Dated decision record written and indexed (`decisions/`, `decision_index.md`).
- `GDD_00` scope updated; any GDD chapter behavior change paired with its
  `GDD_10` / Control Plane row in the same commit (**DoD#1**).
- Any new mechanical rule (e.g. a banned term) backed by a `check_docs.py`
  check in the same change (**DoD#2**).
- `python3 AGENT/Docs/gen_docs_index.py` run; `INDEX.md` + `REGISTERS.md`
  committed in the same change (check 18).
- `check_docs.py` passing.
- Session note written and added to `AGENT/Session Notes/INDEX.md`.

## 8. Suggested order of operations

1. Confirm §1 wording with owner (§6).
2. Write + index the decision record.
3. Update `GDD_00` scope.
4. Walk `GDD_01`→`GDD_08`, then `GDD_10`, Feature Index, Adoption Matrix —
   logging findings per §3 as you go, fixing the unambiguous ones inline.
5. Park anything needing an owner call as an open question, not a silent edit.
6. Regenerate indices, run `check_docs.py`, write the session note, commit.
