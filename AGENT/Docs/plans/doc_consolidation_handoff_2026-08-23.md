---
Role: dated
Type: handoff
Status: Active
Last verified: 2026-08-23
Tracker: CITATION-GATE-DELETION-BLINDNESS-2026-08-23
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Next-session handoff — three doc-consolidation orders left, two of them unblocked

**This document adds no open work.** Every item below is a tracker row that already exists,
and the rows carry the measurements. This is ordering and context only — read it to decide
what to pick up, then work from the row. If you find yourself wanting to record something
new here, put it on the row instead; a handoff that becomes a second registry is the exact
failure `TRACKER-DIVERGENCE` cost four sessions to unwind.

## Where the queue stands

Orders 1, 2, 3, 4, 6, 8 and 10 are **closed**. Three remain:

| Order | Row | State |
|---:|---|---|
| **5** | `EXTENSIONLESS-DATED-CITATIONS-2026-08-23` | **Blocked, and narrower than it looks** |
| **7** | `GDD-CAMPAIGN-EDITOR-CHAPTER-2026-08-23` | **Unblocked** — 87 rulings with no topic destination |
| **9** | `MINE-PLAYTEST-CORPUS-2026-08-23` | **Unblocked** — 79 files / 8,970 lines |

Two rows opened this session sit outside the numbered queue:
`IS-HISTORICAL-UNDER-MATCHED-2026-08-23` (small, self-contained) and
`SESSION-UI-THEMING-ALIGNMENT-2026-08-10`, which shrank to two owner calls.

## Recommended order: 9, then 7

**Order 9 first.** It is the largest remaining win, it is fully unblocked, and — unlike when
it was written — **the method it needs now exists**. §2.1 of
[`uncovered_doc_corpora_triage_2026-08-23.md`](uncovered_doc_corpora_triage_2026-08-23.md)
was written this session from what order 8 actually did, so order 9 inherits it instead of
rediscovering it. Read that section before touching a file.

**Order 7 second.** It is unblocked but it is authoring work, not mining, and it partly
overlaps the GDD work order 9 will already have you doing.

**Order 5 last, and only if its blocker has cleared.** Do not start it hoping to find a way
through — the blocker is real and is about inventing IDs.

## What each row needs, and the traps

### Order 9 — mine the playtest corpus

- **79 files / 8,970 lines, not 80 / 8,996.** `playtests/ai_suspend_boundary_evidence_matrix_2026-07-16.md`
  is CI-gated by `implemented_track_evidence.json` and is out of scope. The triage's
  reachability sweep **only walked Markdown**, so it is blind to non-Markdown roots — check
  `.py`/`.json`/`.gd`/`.sh`/`.yaml` before deleting anything, the way order 8 did.
- **Treat 8,970 as a ceiling, not a target.** The archive purge was scoped at 23,212 lines
  and delivered 1,526. Order 8 delivered its full 11,946 only because those were whole
  superseded documents rather than a connected graph.
- **Deleting frees no clone space.** History retains the bytes. The win is that a reader
  stops finding six superseded answers before the current one.
- **Sweep by grep after deleting.** Check `[1]` now catches a named document that exists
  nowhere — including the dated shape without its `.md` — but grep is still the backstop,
  and the deletion is the moment to run it.

### Order 7 — the campaign editor GDD chapter

- 87 rulings currently resolve to nothing. This is the same shape as the UITH absorption
  done this session: the pattern to copy is `GDD_07_UI_UX.md` § *UI Theming*.
- **Re-measure anything you carry in.** Absorbing UITH found five stale figures in a
  thirteen-day-old register, one of which **inverted a conclusion**. Importing a dated
  document's measurements into a living one unchecked is how a GDD chapter starts lying.

### Order 5 — extensionless citations

- The **existence half is already done** inside check `[1]`, and one of its five instances
  turned out to be a dead pointer rather than a form problem. **Three remain**, all with live
  targets, all purely check `[50]` form questions.
- Its blocker is unchanged: two of the three cite documents with **no stable ID**, and
  landing the `[50]` extension would gate the repo on citations that cannot be written
  correctly. Inventing IDs is exactly what `[50]`'s resolution half exists to prevent.
- The ID work it waits on is the same GDD-chapter work as order 7 and
  `REGISTER-EXPIRY-ANCHORS`. **If order 7 gives the campaign editor a chapter, check whether
  the mouse-only cursor design and the OS-keyboard suppression ruling can get homes in the
  same pass** — that is the cheapest route to unblocking this row.

## Two owner calls waiting — BOTH RULED 2026-08-23

Both were put to the owner and answered. **Both recommendations were void on arrival**, each
for the same reason: the fact the recommendation rested on had changed since it was written.
That is failure shape 1 below, for the seventh consecutive row — and this time it fired on a
*recommendation* rather than a row's premise, so the shape is broader than the list says.

1. **`[UITH-7]`** — a theme-provenance field on `WebTestBridge`. The recommendation was to fold
   it into `BRIDGE-SNAPSHOT-STALENESS-2026-08-10`'s version bump. **That row completed
   2026-08-11**; both halves of the handshake sit at `2` and `bridge.mjs:104` tests strict
   equality, so the free ride no longer exists. **Ruled: build it on its own contract bump**,
   `VERSION` and `SUPPORTED_VERSION` 2→3 in one cross-repo landing. Row
   `BRIDGE-THEME-PROVENANCE-2026-08-23-2026-08-23` (`planned`; the doubled date is what
   `agent-add-task.sh` produces when the slug already carries one).
2. **`[UITH-8]`** — sequencing against the v0.8.0 hold. The recommendation was to treat the
   V080 branch as evidence and merge it unchanged later. **It merged on 2026-08-20
   (`14d192d4`), and not unchanged** — a `MainMenu.gd` conflict was resolved. The sequencing
   question is moot; the residue was the Menu Scale opt-out precedent. **Ruled: density tokens
   are the single density authority** — a token-consuming screen ignores the Menu Scale factor,
   `MainMenu.gd:75` is the precedent rather than an exception, and `apply_menu_scale` is a
   legacy path retired screen by screen.

Both now stand as rulings in `GDD_07_UI_UX.md` § *UI Theming*. Nothing on this subject is open,
so `SESSION-UI-THEMING-ALIGNMENT-2026-08-10` no longer blocks a theming rollout.

## Failure shapes this queue keeps producing

Check these first, in this order, before trusting any row's premise.

1. **The row is wrong about its own premise.** Six consecutive rows now. Order 6's
   recommendation was measured false and inverted; order 8's blocker did not exist; order 5
   misdiagnosed one of its own five instances. **Measure before planning.**
2. **A generic basename match.** Three costumes so far: bare filenames (107 hits, ~15 real),
   session-note dates (71 hits, ~5 real), and `GDD_07` in prose (1,230 hits, 0 real). The safe
   pattern always requires a word prefix before the date.
3. **A discharged debt that was not discharged.** A banner on a heading does not discharge a
   claim made in the body — found this session on `UI-TOOL-01`, six days after it was marked
   paid.
4. **A gate that is silent for the wrong reason.** Check `[50]` said nothing about `[UITH-6]`
   in GDScript *because the register was missing*, which is precisely when a citation most
   needs checking.

## Reproducible facts worth not re-deriving

- The mining verification method is triage §2.1. A tracker keyword sweep is **not** evidence:
  190 hits, nothing answered.
- Driving the web export: the harness is in the **container** repo, it cannot target a linked
  worktree, and `--allow-stale` makes the observation describe the wrong build.
- A screenshot album cannot catch a defect that is a **relation** between two measurements.
  The 133-shot album passes while the Menu Scale padding defect ships.
