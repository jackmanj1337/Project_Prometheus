# Session Note - 2026-08-14 (S11 — the CEUI walk closes)

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `76bb703903c75ddc282e3b9d5414f6a03ccf1d2c` (session start tip)
- Coordination Work ID: `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`

## What was done

`S11`, the second half of the `CEUI` owner walk, ran to completion. **`CEUI-1..40` are all
resolved, the twelve `NMTE` residues are closed, and the nine `EW` wireframe findings are ruled** —
thirty new rulings, `[CEUI-S21]`–`[CEUI-S50]`, bringing the walk to fifty. `UBS-8` lifts; the
`UUI-15` album hold now waits only on `UBS-6` and `UBS-7`.

The walk followed the `S9` diff's §7 order: the two Section A leftovers, then Section C, then
Sections D–F, then the `NMTE` residue, then the `EW` findings.

**Where the owner went against the recommendation, and it mattered:**

- **`CEUI-6`** — recommended "nothing editor-related in the library"; ruled **an *Edit a copy*
  action**, which **amends `[CEUI-S13]`'s main-menu-only entry point**. The amendment is safe and
  the reason is in code, not in prose: `CampaignLibraryScreen` exists only as a child of `MainMenu`
  and `NewGameScreen`, so both entry points are still pre-campaign contexts and `[CEUI-S13]`'s real
  content — the **precondition**, no active campaign, no deactivation, no confirmation — survives
  intact. What may never be added is a pause-menu or in-run entry.
- **`CEUI-39`** — recommended a dismissible guided task list on the reading that `CSA-31(f)`'s "no
  hints" governs content rather than process; ruled **no built-in guidance in v1**, with the task
  list kept explicitly as a post-v1 idea rather than rejected.

**The rulings that will be hardest to reconstruct later:**

- **`[CEUI-S27]`** — the editor does not invent a severity taxonomy; it adopts `[CRD-9]` +
  `[L10N-14]` + `[DRC-17]` as **two severities and three gates**, and names the missing third gate:
  **a Test launch IS an activation** of the working copy. Checked against code — **there is no
  severity model in the engine at all**; validators return flat error-string arrays with two ad-hoc
  warning channels. This is a change to the validators, not editor presentation.
- **`[CEUI-S35]`** resolves `CEUI-31` to **its own rejected option B**: `[DLUX-13]`'s
  authoring-time template expansion generalizes off dialogue, so *template* means one thing across
  content families and the live-propagation machinery does not exist. Twelve reused encounters is
  twelve edits, accepted.
- **`[CEUI-S36]`** answers the import transaction the *opposite* way from the packet's strict
  reading: an import **commits with rights unknown** and `[CEUI-S27]`'s gates enforce them. The
  draft-warns / release-fails model already protects publication, and the strict reading would have
  created a staged-but-uncommitted import that has to survive sessions.
- **`[CEUI-S43]`** — the diff's §4.5 was right that this is load-bearing. Editor filters are plain
  fields, so `TextEntryService`'s ratified "one owner of printable input" is **restated** as covering
  modal naming and path entry. Its zero production callers are a *not-yet-consumed* state, not an
  abandoned architecture, and the service is not retired.
- **`[CEUI-S39]`** is a **confirmation**, not a decision: `[CEUI-S8]` had already built the id-rename
  interaction on `CEUI-36`'s answer while the register still said `[OPEN]`. Ruling anything else
  would have retroactively broken it — the fourth time this walk found a ruling operating outside
  the document that governs it.

**Two structural patterns the walk applied repeatedly**, worth naming because they decided several
questions at once: *derive, don't enumerate* (`[CEUI-S21]` tree categories, `[CEUI-S30]` map layers,
`[CEUI-S31]` tool sets — all from declared metadata, so a new content family or authored collection
costs no editor edit), and *one surface per job* (`[CEUI-S23]` the bulk table is the only multi-edit
path, `[CEUI-S32]` the outline is canonical and every graph a projection).

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`, NOT here.

Four commits. `f92a4fae` recorded `[CEUI-S21]`–`[CEUI-S32]` (Section A leftovers, Section C, the
first Section D rulings); the second closes the walk with `[CEUI-S33]`–`[CEUI-S50]` and propagates
the closure — the `NMTE` register closed with a disposition table, `UBS-8` closed, the sequencing
plan's editor arc marked complete, and the wireframe set's *what this does not draw* list released
with a note that interiors are a **new drawing pass**, not a revision. `bf80e872` scheduled the
combined convoy+shop session, and `acd07114` carries the completeness sweep below.

## Completeness sweep, after the walk was called closed

Asked to confirm nothing was left unanswered, I swept every ruling for sentences that **deferred**
something rather than trusting the status labels. The register was already consistent — 40/40
questions marked `[RESOLVED]`, `[CEUI-S1]`–`[CEUI-S50]` present with no gaps or duplicates, all
twenty `NMTE` questions dispositioned, `EW-1..10` ruled — **and it was still wrong to call it
closed:**

- **Two sub-questions were genuinely open.** `[CEUI-S12]` had marked `[L10N-16]`'s pseudolocale
  capture ownership *"Not ruled here"* and nothing picked it up; `[CEUI-S9]` call 4 demanded a
  sentence about the `EPUX-02` inheritance path that was never written. Ruled the same day as
  `[CEUI-S51]` (Localization owns the capture; both export destinations ship in v1, answering call
  4's *"build both or say which is deferred"*) and `[CEUI-S52]` (availability is a property of the
  **component**, not the hosting surface, so the editor inherits by construction).
- **Four passages were stale**, describing residues that later rulings in the same document had
  already closed. Each now carries a forward pointer.
- **The `NMTE` register had no per-question status at all**, so a reader landing mid-file saw an
  open-looking question with its answer three hundred lines away. All twenty headings now carry a
  disposition marker.

**The lesson, and it generalises:** this walk caught the ruling-outside-its-document shape four
times in *other* documents (`[CEUI-S7]`, `CEUI-32`, `TSV-1..9`, `CEUI-36`) and then produced it once
itself. **A ruling that defers a sentence must be swept before a register is called closed** —
status labels record what was decided, not what was left dangling inside a decision.

**Two tracker gaps the same sweep found**, both the invisibility failure `AGENTS.md` names:

1. The six pieces of build work the walk forces, plus `[CSA-28(f)]`'s unbuilt
   `deactivate_campaign_package()` caller, lived only in the reference of
   `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31` — **a completed row**. New row
   `EDITOR-BUILD-PREREQUISITES-2026-08-14` (`0-unblock`) owns them.
2. `SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13` did not record the four entries the walk sends it;
   appended, with `[CEUI-S48]` recorded as a **bound** on what that row may decide.

Also registered: `BACKLOG-EDITOR-ONBOARDING-TASK-LIST-2026-08-14` (`5-backlog`, owner decision), and
the next session set to the **combined convoy+shop sitting** (`S5`+`S6` as one).

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks.
- `python3 AGENT/Docs/gen_docs_index.py` — INDEX.md / REGISTERS.md regenerated and committed in the
  same change.
- `python3 scripts/ci/check_session_commit_claims.py --fix` — 808 commits audited, PASS.
- Pre-commit ran analyzer tests (12), scene integrity (23 scripts), evidence matrices, and
  `check_gdscript_style` (321 files) — all green; Godot suite skipped as docs-only.

## Next

**The COMBINED convoy+shop sitting (`S5`+`S6` as one), set by the owner 2026-08-14** — author the
packet over the resolved `TSV`/`SHC`/`CUR` contract, precedence-check it, and walk it in one go, as
this arc did. Convoy-first is the packet's internal section order, not a session boundary, so the
shared calls are taken once with both consumers present. `S7`/`S8` (compendium, `UBS-7`) stay
independent; `R2`'s album release waits on both. Neither inherits anything from the editor.

Owed elsewhere, recorded not done: **`S12` inherits four items** — the editor scale/display settings
group (`[CEUI-S1]`), the author profile (`[CEUI-S10]`), the Advanced-mode toggle (`[CEUI-S29]`) and
`NMTE-20`'s filter-text persistence, bounded by `[CEUI-S48]`'s never-to-disk rule. **`[CEUI-S7]`'s
propagation debt is still open**: `FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31` must rewrite its two
target lines to describe generation.

**Build work this walk newly forces** (belongs on the editor's estimate, not discovered later): the
`[TSV-10]`/`[EPUX-04]` shared selector, the tree/layer descriptor, a two-severity validation model
with three gates, the quick-fix registration seam, `[CSA-28(f)]`'s unbuilt
`deactivate_campaign_package()` caller, and the editor `DENSITY_TOKENS` column with the album's
values and `min_target = 24`.
