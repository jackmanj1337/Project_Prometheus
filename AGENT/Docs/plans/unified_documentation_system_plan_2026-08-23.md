---
Role: dated
Type: plan
Status: In implementation — phases 0–2 built on `agent/from-integration/unified-doc-system-phases-1-2`
Last verified: 2026-08-23
Tracker: UNIFIED-DOC-SYSTEM-2026-08-23
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Unified documentation system — a topic-sorted destination for a dated corpus

**What this plan is.** When the owner retired the session-note practice on 2026-08-23,
they ruled that the references scattered across fourteen corpora should be consolidated
into one documentation system rather than purged corpus by corpus, and then set the
destination: **the note files will eventually be deleted, with any useful information
moved into a topic-sorted docs system.** This is that plan.

It is deliberately **not** a fifth purge. It builds the one mechanism four separate
tracker rows each turn out to need, and only then does deletion become a consequence
rather than a judgement call.

**Phases 0–2 are built** (§5). Phases 3–5 are deliberately not started.

---

## 1. The measured problem

Measured on `agent/integration` `03af8d50`, by walking the tree rather than reading
prior notes — three inherited premises did not survive that walk (§7).

| | Files | Lines |
|---|---:|---:|
| Markdown, all of `Project_Prometheus` | 1,265 | 224,535 |
| …of which the **topic spine** (numbered GDD chapters + Feature Index) | 16 | **7,553** |
| Tracked GDScript, for scale | 335 | — |

**The topic spine is 3.4% of the corpus.** The other 96.6% is sorted by *when it was
written* — by session, by walk, by review, by return — and a reader wanting to know what
is true about a subject must find every dated document that ever touched it and work out
which one still holds.

Three failures recur, and they are one failure wearing three coats:

1. **Stale prose is indistinguishable from live prose.** `AGENT/WAITING_WORK.md`
   advertised PR #32 as awaiting a human merge for thirteen days after it had merged — in
   the handoff *and* in the tracker row, so "trust the tracker" had nothing to fall back
   on. Second such premise failure in two sessions.
2. **Moving a document silently breaks every inbound reference.** The archive move broke
   nine GDScript rationale comments and nobody noticed
   (`STALE-DOC-PATHS-IN-GDSCRIPT-2026-08-23`).
3. **A corpus labelled dead is not dead until reachability says so.** The registers were
   ranked "highest ratio of dead weight to risk" and carry **2,273 ruling-ID citations
   from 158 files**. The archive purge was scoped at 23,212 lines and delivered 1,526.

The common cause is structural, not editorial:

> **Documents are sorted by date, references are file paths, and being current is a
> convention rather than a property anything can check.**

## 2. Four rows need the same missing mechanism

| Row | What it is actually blocked on |
|---|---|
| `RETIRE-SESSION-NOTES-2026-08-23` | 444 of 596 notes are cited by nothing, and none can be deleted while a citation is a path |
| `REGISTER-EXPIRY-ANCHORS-2026-08-23` | its own reference says it: *"the work is the anchor mechanism, not the move"* — and its original intent, expiring registers **into GDD chapters**, is exactly this plan's migration |
| `STALE-DOC-PATHS-IN-GDSCRIPT-2026-08-23` | asks whether moving a document may silently break inbound references |
| `UNCOVERED-DOC-CORPORA-2026-08-23` | 62,739 more lines to triage, which hit the same wall |

Build the mechanism once and all four become tractable. Purge first and each re-derives
the same lesson at its own cost.

## 3. The destination

### 3.1 Topic-sorted, and it already half-exists

The project already has a topic spine and already enforces its anchors — this plan
extends a working mechanism rather than inventing one, which is also what
`AGENTS.md` § *Process machinery (one-in-one-out)* asks for.

- **`AGENT/GDD/GDD_00..GDD_08`** are twelve chapters sorted by subject — Architecture,
  Data Contracts, Runtime Contracts, Core Mechanics, Units/Classes, Weapons/Items,
  Skills, Maps/Objectives, Input/Cursor, Screens/Panels, UI/UX, Enemy AI.
- **`GDD_Feature_Index.md`** maps feature → owning chapter **section fragment**, and
  `check_docs.py` already enforces that every feature row links to a *reachable* GDD
  heading. That is an ID resolving to a location, gated, today.

What is missing is coverage, not concept: **ruling IDs do not resolve through it.** The
2,273 `[CEUI-S1]`-style citations from 158 files reach a register by path. Extending the
existing enforced anchor mechanism from feature rows to ruling IDs is the whole of §3.3.

**Every document is one of two kinds**, declared in front matter:

- **Topic** — sorted by subject, maintained current, the place a reader looks. The GDD
  chapters, guides, governance, `Review Procedures`.
- **Dated** — sorted by when it was written: session notes, plans, registers, design
  docs, playtests, code reviews, the archive. These are **inputs**. The long-term
  direction is that their useful content migrates to a topic document and the file goes.

### 3.2 A correction is an edit, not another document — RULED 2026-08-23

The owner ruled that **a document may be corrected in place**, including a dated one.
This is the anti-accumulation half of the plan and it matters more than it first looks.

Every corpus here grew append-only for the same reason: being wrong produced *another
dated document* saying so. Notes appended per session, registers per walk, plans per
re-derivation — and corrections appended as new dated files rather than fixing the old
one. Correcting in place removes the last of those, and it is the discipline a topic
document requires by definition: a topic document is only useful if it is edited when
the truth changes.

The record is not lost. **Git is the history mechanism**; a second dated file was never
serving that purpose, it was only making the corpus bigger and the current answer harder
to find. What a correction owes is a note of *what changed and when* in the document
itself, not a new file.

### 3.3 Every cross-corpus reference resolves through an ID

- Extend the Feature-Index anchor mechanism to cover **ruling IDs** and **topic IDs**, so
  a generated index maps every stable ID → its current chapter + heading.
- Moving or deleting a document then regenerates one index instead of editing 158 files.
- A check rejects a **path** citation across corpora, the way feature rows are already
  checked for reachable fragments. Paths *within* one document's own corpus stay legal.

This is the prerequisite `REGISTER-EXPIRY-ANCHORS` names, and it is what makes deleting
the notes safe rather than hopeful.

## 4. What migration actually costs — measured

The mining job is far smaller than the corpus size suggests. Of 596 notes:

| | Notes |
|---|---:|
| Cited by a **topic** source or by **code** — must be absorbed before deletion | **38** |
| Cited only by other **dated** documents (plans, design, playtests, reviews) | 45 |
| Cited only by the already-dead archive | 12 |
| Cited by nothing at all, transitively | **444** |

**The hard core is 38 notes, not 596 and not 121.** The 45 second-order ones resolve by
cascade: when the dated document that cites a note is itself migrated, the citation goes
with it. The 444 need no reading at all.

And what a note contains is largely already elsewhere. Checked, not assumed:
`SESSION-INDEX-ORDERING-2026-08-22`'s tracker `reference` is a **strict superset** of its
141-line note, and additionally carries cross-repo branch SHAs the note never recorded.
**Sample before budgeting phase 3** — if that generalises, mining is mostly confirmation.

**The counterweight, stated honestly:** the topic spine is *thin*. Twelve chapters, 6,727
lines, averaging 560 each. Absorbing even a fraction of 216,982 lines of dated prose will
grow them past the point where they were split once already — `B0-GDD-CONSOLIDATION` split
`GDD_01` at 1,907 lines and `GDD_07` at 1,218. **Phase 1 must set a chapter growth and
splitting discipline**, or this plan recreates the oversized-chapter problem it inherits.

## 5. Phases

Each names what it retires, per `AGENTS.md` § *Process machinery (one-in-one-out)*.

| # | Phase | Retires |
|---|---|---|
| **0** | **Retire the session-note practice; freeze the corpus; move the ledger out** — **DONE**, §6 | nine mechanisms, none added |
| 1 | **BUILT 2026-08-23:** declare `topic` / `dated` in live-document front matter; land the correction-in-place rule; require a recorded cohesion/split review above 1,200 lines | the per-corpus ad-hoc freshness conventions, and the correction-by-new-dated-document habit |
| 2 | **BUILT 2026-08-23:** extend the Feature-Index generator to topic/ruling IDs; reject topic→dated Markdown links and dated-document paths in GDScript rationale comments | the bespoke path-repair in `STALE-DOC-PATHS-IN-GDSCRIPT`, which this closes outright |
| 3 | Mine the **38** topic-cited notes into their owning chapters; sample first to confirm how little is unique | nothing new — this is the payment for phase 4 |
| 4 | **Delete the note files.** 596 files / 42,918 lines, once every ID resolves | the frozen `AGENT/Session Notes/` tree, entirely |
| 5 | Apply §3 to `playtests`, `Code Reviews`, `design` — 62,739 lines (`UNCOVERED-DOC-CORPORA`) | to be named when scoped; "keep, with a reason written down" stays a legitimate answer |

**Phases 1–2 are the whole plan.** 3–5 are consequences that become mechanical once an ID
resolves.

### Phase 1–2 implementation note (2026-08-23)

- Every live maintained document now declares `Role: topic` or `Role: dated` in front
  matter. Frozen archives and the retired session-note tree are classified by their
  containing corpus and were not rewritten.
- Every top-level GDD document declares a stable `Topic ID`. The existing docs generator
  now also rewrites the bounded stable-ID section in `GDD_Feature_Index.md`: topic IDs map
  to their document, while ruling IDs cited in the GDD map to exact current headings and
  list their dated evidence source.
- `check_docs.py` enforces roles, a 1,200-line split-review threshold, generator freshness,
  and the cross-corpus citation boundary. The threshold is a review trigger, not an
  automatic line-count split: split by a cohesive domain when one exists; otherwise record
  `Split review:` in front matter with the reason the chapter remains whole.
- The generated index lives in Prometheus, extending the existing Feature Index as the plan
  recommended. No parallel `ANCHORS.md` mechanism was created.

## 6. Phase 0, as built (2026-08-23)

Prometheus `agent/from-integration/retire-session-notes` (`a4c8e5a5`, `a4a46b57`);
container `agent/staging-area` (`a47a2af`, `c7f99e8`).

- **596 notes and `INDEX.md` frozen**, not deleted, pending phases 3–4.
- **The ledger left the notes tree**: `AGENT/Session Notes/CLAIMS.tsv` →
  `AGENT/Ledger/CLAIMS.tsv`, with `COMMIT_CLAIMS_BASE`. It is machine-read commit
  ownership and was never a note. `check_session_commit_claims.py` reads the legacy path
  too — working tree *and* canonical ref — so branches cut before the move keep passing;
  three regression tests pin it, and `LEGACY_LEDGER_PATH` carries the command that proves
  when the fallback can go.
- **Nine mechanisms retired, none added:** the note-index gate and its test, its `pre-push`
  and `session_closeout.sh` callers, `check_docs.py` check `[43]`, `TEMPLATE.md`, the
  in-note prose-claim scan, `scripts/agent-session-note.py`, its integration test,
  `audit_notes` + `history_audit.py notes`, and the note-writing half of
  `agent-close-task.sh`.
- **`DEFAULT_SHARED_APPEND_PATHS` exempts both ledger paths.** Missing this would let a row
  claim the moved ledger and serialize the whole project against itself — the defect that
  list exists to stop, reintroduced by the move that fixed its cause.

**Why the practice could be retired at all:** it had already lapsed. The newest note is
`2026-08-22-04-30-18Z`; the four sessions after it wrote none, on any branch, and lost
nothing.

## 7. Method notes for whoever picks this up

Each of these cost a false start:

- **Measure on `origin/agent/integration`, never on a checkout.** `repo/Project_Prometheus`
  is parked on a release branch and gives wrong counts for every corpus. Use
  `git ls-tree -r $REF` and `git cat-file -p "$REF:$f"`.
- **Exclude generated indexes before any count means anything.** `AGENT/Docs/INDEX.md`
  cites 48 notes on its own and sets a citation floor of one on everything.
- **Match by full path, never by basename.** `README.md` matched 14 live files and briefly
  implicated `check_docs.py` as an archive dependent — false.
- **Compute reachability transitively.** A leaf-by-leaf pass deletes files whose only
  referrers are other files in the same corpus.
- **Separate topic citers from dated citers.** It is the difference between an absorb-set
  of 38 and one of 121.
- **Binary weight is not clone weight.** 105.7 MB of the archive's 106.7 MB is binary
  evidence, and deleting it frees nothing because history retains the bytes.

## 8. Owner calls

**RULED 2026-08-23 — do not re-litigate:**

- **A document may be corrected in place, dated ones included.** §3.2. Corrections are
  edits; git is the history mechanism.
- **The note files are eventually deleted**, with useful information moved into the
  topic-sorted system. §5 phases 3–4. This replaced the earlier open question of whether
  to purge only the 444 unreachable notes: the target is all 596.

**Still open:**

1. **Where does the generated ID index live?** Registers and notes are `Project_Prometheus`;
   the tracker is the container. Recommendation: **Prometheus**, extending
   `GDD_Feature_Index.md`'s already-enforced anchor check, since every ID it must resolve
   already lives in that repo.
2. **Does topic-sorting extend past the notes** to `playtests`, `Code Reviews` and
   `design` (62,739 lines), or do those stay dated? Phase 5 assumes the first; the ruling
   so far names only the notes.
3. **What is the chapter growth-and-split discipline** (§4)? Twelve chapters at 560 lines
   average cannot absorb the migration unchanged, and the project has already split
   oversized chapters once.
