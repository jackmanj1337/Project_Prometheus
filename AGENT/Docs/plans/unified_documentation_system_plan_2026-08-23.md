---
Type: plan
Status: Planned — opens `UNIFIED-DOC-SYSTEM-2026-08-23`; Phase 0 is already built
Last verified: 2026-08-23
Tracker: UNIFIED-DOC-SYSTEM-2026-08-23
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Unified documentation system — consolidating references onto stable anchors

**What this plan is.** The owner ruled on 2026-08-23, when retiring the session-note
practice, that the references scattered across fourteen corpora should be consolidated
into one documentation system rather than left to be purged corpus by corpus. This is
that plan. It is deliberately **not** a fifth purge: it builds the one mechanism that
four separate tracker rows each turn out to need, and only then does deletion become a
measurement rather than a judgement call.

**Phase 0 is already built** — see §5. Phases 1–5 are not started.

---

## 1. The measured problem

Measured on `agent/integration` `03af8d50`, by walking the tree rather than reading
prior notes (three inherited premises did not survive that walk — see §7):

| | Files | Lines |
|---|---:|---:|
| Markdown, all of `Project_Prometheus` | 1,265 | 224,535 |
| Tracked GDScript, for scale | 335 | — |

That is **670 lines of prose per script file**, across fourteen directories. No agent
reads it end to end; every agent greps it. What a grep returns is as likely to be dated
evidence as current instruction, and **nothing in the file says which**.

Three failures recur, and they are one failure wearing three coats:

1. **Stale prose is indistinguishable from live prose.** `AGENT/WAITING_WORK.md`
   advertised PR #32 as awaiting a human merge for thirteen days after it had merged —
   in the handoff *and* in the tracker row, so "trust the tracker" had nothing to fall
   back on. That was the second such premise failure in two sessions.
2. **Moving a document silently breaks every inbound reference.** The archive move
   broke nine GDScript rationale comments and nobody noticed
   (`STALE-DOC-PATHS-IN-GDSCRIPT-2026-08-23`).
3. **A corpus labelled dead is not dead until reachability says so.** The registers were
   ranked "highest ratio of dead weight to risk" and carry **2,273 ruling-ID citations
   from 158 files**. The archive purge was scoped at 23,212 lines and delivered 1,526.

The common cause is structural, not editorial:

> **A reference is a file path, and authority is a convention rather than a property of
> the document.**

Paths break when documents move. Convention cannot be checked, so nothing can tell a
document that must be current from one that must never change.

## 2. Four rows need the same missing mechanism

This plan exists because these are not four problems:

| Row | What it is actually blocked on |
|---|---|
| `RETIRE-SESSION-NOTES-2026-08-23` | 444 of 596 notes are cited by nothing, but are undeletable while a citation is a path |
| `REGISTER-EXPIRY-ANCHORS-2026-08-23` | its own reference says it plainly: *"the work is the anchor mechanism, not the move"* |
| `STALE-DOC-PATHS-IN-GDSCRIPT-2026-08-23` | asks whether moving a document may silently break inbound references |
| `UNCOVERED-DOC-CORPORA-2026-08-23` | 62,739 more lines to triage, which will hit this same wall |

Build the anchor mechanism once and all four become tractable. Purge first and each one
re-derives the same lesson at its own cost.

## 3. Two properties every document gets

### 3.1 Authority or evidence

Every document is one of two kinds, declared in front matter and checkable:

- **Authority** — maintained, must be current, may be edited freely, may cite anything.
- **Evidence** — dated, frozen at publication, **never edited**, cited *by* authority and
  never citing forward. A correction to evidence is a new authority document saying so,
  not an edit to the record.

The split is already latent in the tree and falls out cleanly:

| Kind | Corpora | Files | Lines |
|---|---|---:|---:|
| **Authority** | GDD, `Docs/plans`, `Docs/registers`, `Docs/design`, `Docs/guides`, `Docs/governance`, `Docs/decisions`, `Review Procedures`, templates, `Docs` root | 358 | 116,127 |
| **Evidence** | `Session Notes`, `Docs/playtests`, `Docs/archive`, `Code Reviews` | 899 | 107,440 |

**48% of the corpus is evidence.** Today it is greppable, editable and citable exactly
like authority, which is why a thirteen-day-old falsehood and a current instruction read
the same. Declaring the kind is most of the fix: an evidence document that goes stale is
not a defect, it is the point; an authority document that goes stale is a defect and can
be checked for.

### 3.2 Every reference is an ID, not a path

The project already has stable IDs and already uses them heavily — task IDs, ruling IDs
(`[CEUI-S1]`), GDD section numbers. What it lacks is **resolution**: nothing maps an ID
to where its document currently lives, so citations fall back to paths.

- A generated `AGENT/Docs/ANCHORS.md` maps every stable ID → current path + heading.
- Moving a document regenerates one index instead of editing 158 files.
- A check rejects a **path** citation from an authority document into an evidence
  corpus. Paths *within* a corpus stay legal; it is the cross-corpus path that rots.

This is the mechanism `REGISTER-EXPIRY-ANCHORS` names as its prerequisite, and it is
what makes the notes and archive purges safe rather than hopeful.

## 4. Phases

Each phase names what it retires, per AGENTS.md § *Process machinery (one-in-one-out)*.

| # | Phase | Retires |
|---|---|---|
| **0** | **Retire the session-note practice; freeze the corpus; move the ledger out** — **DONE**, see §5 | nine mechanisms, none added |
| 1 | Declare the boundary: `Type:` taxonomy gains `authority` / `evidence`; every evidence corpus gets a frozen README and a `Status: Frozen`; the staleness rule binds authority only | the per-corpus ad-hoc freshness conventions, and `audit_cadence`'s implicit "all docs age alike" premise |
| 2 | Build `ANCHORS.md` and the resolver check | the bespoke path-repair work in `STALE-DOC-PATHS-IN-GDSCRIPT`, which this closes outright |
| 3 | Migrate references onto anchors: 121 live note citations, 34 from the archive, 64 tracker rows | nothing new; this is the payment for phase 4 |
| 4 | Purge by measurement: the 444 unreachable notes (29,425 lines) and the 23 archive files held behind them | the frozen notes corpus shrinks to its cited core |
| 5 | Apply §3 to `playtests`, `Code Reviews`, `design` — 62,739 lines (`UNCOVERED-DOC-CORPORA`) | to be named when that row is scoped; under one-in-one-out "keep, with a reason written down" is a legitimate answer |

**Phases 1 and 2 are the whole plan.** 3–5 are consequences that become mechanical once
an ID resolves.

## 5. Phase 0, as built (2026-08-23)

On `agent/from-integration/retire-session-notes` (Prometheus) and `agent/staging-area`
(container). Owner-ruled: retire the practice, freeze the corpus, plan the consolidation
separately — **do not purge yet**.

- **596 notes and `INDEX.md` are frozen**, not deleted. 121 are cited by live documents,
  tracker rows and GDScript comments. `AGENT/Session Notes/README.md` records the freeze.
- **The ledger left the notes tree**: `AGENT/Session Notes/CLAIMS.tsv` →
  `AGENT/Ledger/CLAIMS.tsv`, with `COMMIT_CLAIMS_BASE`. It is machine-read commit
  ownership and was never a note. `check_session_commit_claims.py` reads the legacy path
  too — in the working tree *and* the canonical ref — so branches cut before the move
  keep passing; three regression tests pin that, and the constant carries the command
  that proves when the fallback can go.
- **Nine mechanisms retired, none added**: the note-index gate and its test, its calls in
  `pre-push` and `session_closeout.sh`, `check_docs.py` check `[43]`, `TEMPLATE.md`, the
  in-note prose-claim scan, `scripts/agent-session-note.py`, its integration test,
  `audit_notes` + the `notes` subcommand of `tools/history_audit.py`, and the
  note-writing half of `agent-close-task.sh`.
- **`DEFAULT_SHARED_APPEND_PATHS` now exempts both ledger paths.** Missing this would
  have let a row claim the moved ledger and serialize the whole project against itself —
  the exact defect that list exists to stop, reintroduced by the move that fixed its cause.

**Why the practice could be retired at all:** it had already lapsed. The newest note is
`2026-08-22-04-30-18Z`; the four sessions after it wrote none, on any branch, and lost
nothing. And the replacement was measured, not assumed —
`SESSION-INDEX-ORDERING-2026-08-22`'s tracker `reference` is a **strict superset** of the
141-line note covering the same work, and additionally carries the cross-repo branch SHAs
the note never recorded.

## 6. What this plan does not do

- It does **not** move the registers into the GDD. That is `REGISTER-EXPIRY-ANCHORS`, and
  it stays demoted until the anchor mechanism exists.
- It does **not** delete anything in phases 0–3.
- It does **not** restructure the GDD.
- It does **not** build a documents store or database. `DOCS_STORE_DECISIONS.md` already
  ruled the mainline-docs model: knowledge rides a perpetual docs line, fenced off code
  branches by `hooks/docs-guard.sh`. This plan works inside that ruling.

## 7. Method notes for whoever picks this up

Every one of these cost a false start:

- **Measure on `origin/agent/integration`, never on a checkout.** `repo/Project_Prometheus`
  is parked on a release branch and gives wrong counts for every corpus. Use
  `git ls-tree -r $REF` and `git cat-file -p "$REF:$f"`.
- **Exclude generated indexes before any count means anything.** `AGENT/Docs/INDEX.md`
  cites 48 notes on its own and sets a citation floor of one on everything.
- **Match by full path, never by basename.** `README.md` matched 14 live files and
  briefly implicated `check_docs.py` as an archive dependent — false.
- **Compute reachability transitively.** A leaf-by-leaf pass deletes files whose only
  referrers are other files in the same corpus. For the notes: 142 externally-cited roots
  expand to 152 reachable, leaving 444 genuinely unreferenced.
- **Binary weight is not clone weight.** 105.7 MB of the archive's 106.7 MB is binary
  evidence, and deleting it frees nothing because history retains the bytes.

## 8. Open owner calls

1. **Where does `ANCHORS.md` live?** Registers and notes are `Project_Prometheus`; the
   tracker is the container. A single index spanning both crosses a repo boundary that
   nothing else in the docs system crosses.
2. **Purge or keep the 444 unreachable notes?** Deliberately deferred out of phase 0. The
   answer changes phase 4 from "delete 29,425 lines" to "leave them frozen forever", and
   under one-in-one-out the second is defensible if written down.
3. **May an evidence document ever be corrected in place**, or only superseded by an
   authority document that says what was wrong? §3.1 assumes the second; it is the
   stricter reading and it is what makes "frozen" checkable.
