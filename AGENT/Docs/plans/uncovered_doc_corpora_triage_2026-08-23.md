---
Role: dated
Type: plan
Status: Active - triage complete; both mining rows executed; the 61 catalogue-only documents remain undecided
Last verified: 2026-08-24
---

# Uncovered doc corpora — triage of `playtests`, `Code Reviews`, `design`

**Row:** `UNCOVERED-DOC-CORPORA-2026-08-23`. **Phase 5** of
[`unified_documentation_system_plan_2026-08-23.md`](unified_documentation_system_plan_2026-08-23.md).

Scoped as **triage, not a fourth purge**. This document is the answer to "what are these
three corpora and what should happen to each document", and it names the execution rows.
Under `AGENTS.md` § *Process machinery (one-in-one-out)*, §6 names what phase 5 retires.

Measured on `origin/agent/integration` at `ef63802f`, per §7 of the parent plan.

---

## 1. What the row's premise got wrong

The fourth consecutive row to be wrong about its own premise. Recorded here because the
corrections changed the conclusion, not just the numbers.

| Row's premise | Measured |
|---|---|
| `playtests` 147 files / 21,747 lines | **222 files (150 `.md`)** / 22,191 lines — 72 non-Markdown evidence files it never counted |
| `Code Reviews` 93 files / 21,084 lines | 93 files / **21,432** lines — close |
| `design` 81 files / 19,908 lines | **95 files (81 `.md`)** / 20,009 lines |
| 62,739 lines together | **63,632** Markdown lines; 74,708 counting all text |
| "all three are EVIDENCE except design, which is authority" | **Wrong.** §3.1 lists design docs under *dated* explicitly, and phase 1 already stamped `Role: dated` on all 81 of them |
| "declaring the kind is most of the triage" | **Already done.** All **324** `.md` files in all three corpora declare `Role: dated`; phase 1 covered them. Zero classification work remained |
| "expect `playtests` to be the most safely compressible" | **`Code Reviews` is**, by a wide margin — 11,946 deletable lines (56% of the corpus) against `playtests`' 8,996 (41%) |

The row's real work was never classification. It was **reachability**.

## 2. Method, and a correction to the parent plan's §7

A corpus document is **live** if a live root reaches it through any chain of citations.
Roots are what is maintained now: Prometheus code and tooling, documents declaring
`Role: topic`, `AGENT/WAITING_WORK.md`, and the container tracker's **non-completed**
rows. The frozen session-note tree and `AGENT/Docs/archive` are **not** roots — phase 4
deletes the notes outright, so a citation from one keeps nothing alive.

**§7's rule "match by full path, never by basename" does not hold for these corpora, and
following it understated the live set by half.** That rule was derived from `README.md`
matching 14 live files. These three corpora are date-stamped: `code_review_2026-06-19.md`
is globally unique, and tracker prose names a document *by filename, not by path*. Matching
paths only missed **81 tracker citations** and reported 261 dead documents where there are
129. The rule that survives is narrower:

> Match by basename **where the basename is unique in the tree and not a generic index
> name**. 29 of 324 files here fail that test and are matched by full path only.

Everything else in §7 held, and the transitivity warning earned its place twice below.

### 2.1 How to verify a finding is spent before deleting the document that holds it

**Written 2026-08-23 by `CITATION-GATE-DELETION-BLINDNESS-2026-08-23`, from what
`MINE-CODE-REVIEW-CORPUS-2026-08-23` actually did.** Reachability (§2 above) decides whether
a document may be deleted. This subsection decides whether its *contents* may be — it is the
"sample and move anything unique into its owning chapter first" half, and until now it had
no stated method. `MINE-PLAYTEST-CORPUS-2026-08-23` inherits it from here.

**The method that does not work: a keyword sweep of the tracker.** Order 8's first attempt
matched a review's subject words — `viewport`, `hud` — against `coordination/tasks.json` row
prose. It returned **190 hits and answered nothing.** A row mentioning "viewport" is not
evidence that a *particular* viewport defect was fixed; a row can name the subject and have
done the opposite, or nothing. Sweeping by keyword measures vocabulary overlap, not closure.

**The method that works, in order:**

1. **Extract the finding IDs.** Pull every bracketed ID out of the set being deleted, then
   subtract every ID that also appears somewhere outside it. What remains is the orphan set —
   the only findings whose sole record is a document about to disappear. Order 8: 38 IDs in
   the set, **14** orphaned.
2. **Verify each orphan against the CODE, at a named line.** Not against a tracker row, not
   against another document — the artifact the finding was about. "`V055-02` fixed:
   `FocusNavigator.gd:154` computes `content_top` exactly as the review prescribed" is
   evidence. "A row mentions focus navigation" is not. Four of four V055/V056 items were
   settled this way.
3. **For anything that is not a defect** — a request, a design preference, an open
   recommendation — **find the live row or chapter that OWNS it.** Consuming row, not
   matching row. If nothing owns it, it is not spent, and it is salvage.
4. **Carry the salvage into its owning topic document before deleting**, and re-verify it is
   still open at the moment you carry it. Order 8's entire real salvage was two of one
   review's ten findings (`MR-7`, `MR-10`), both re-checked against
   `tools/godot-analyzer-mcp` before being written into
   `AGENT/Review Procedures/00_Master_Review_Procedure.md` §10.

**Do not assume the corpus-level claim covers the document in front of you.** §2's finding
that these reviews' conclusions "became tracker rows, and the rows are the record" could
**not be verified by ID** for the two reviews holding the `V055`/`V056` findings: **no tracker
row cites a `V055-` or `V056-` ID at all.** The blanket claim is a prior, not a proof.

**Cross-check non-markdown roots, including the ones no grep for a filename can find.**
Reachability above walks *citations*, and a citation is a name someone wrote down. A root
that **constructs** a path at run time writes no name. Both mining rows hit this: order 9's
first correction (`ai_suspend_boundary_evidence_matrix_2026-07-16.md`, named literally in
`governance/implemented_track_evidence.json`) was findable by grepping the filename; its
second (`playtest_checklist_v0.7.9.md` and `playtest_build_v0.7.9.md`) was not, because
`scripts/tests/test_release_metadata.gd:98` and `scripts/ci/check_release_source_branch.py:40`
build those paths from the export preset's `application/product_version`. **Grep the corpus
*directory* out of every `.py`/`.gd`/`.sh`/`.json`/`.yaml` in the tree, not the filenames** —
that is the search that finds a format string. Doing so costs one command and has now saved
three files across two rows.

**After deleting, sweep the tree by grep.** Do not rely on the gates to tell you what broke:
that is how a dead pointer in `scripts/resources/MapData.gd` survived order 8 with every
check green. Check `[1]` now catches this class — a named document that exists nowhere is a
failure — but it matches document-shaped basenames only, and check `[50]` still cannot see a
citation written without its `.md` extension (`EXTENSIONLESS-DATED-CITATIONS-2026-08-23`).
Grep is the backstop, and the deletion is the moment to run it.

## 3. Result

| Corpus | Files | Lines | Keep — live | Keep — catalogue-only | Mine and delete |
|---|---:|---:|---:|---:|---:|
| `AGENT/Docs/playtests` | 150 | 22,191 | 41 / 7,100 | 29 / 6,095 | **80 / 8,996** |
| `AGENT/Code Reviews` | 93 | 21,432 | 15 / 4,211 | 29 / 5,275 | **49 / 11,946** |
| `AGENT/Docs/design` | 81 | 20,009 | 78 / 19,577 | 3 / 432 | **0 / 0** |
| **Total** | **324** | **63,632** | 134 / 30,888 | 61 / 11,802 | **129 / 20,942** |

Per-document dispositions are in §7.

> **The `Mine and delete` column is superseded for both mined corpora.** `Code Reviews`
> delivered 49 / 11,946 in full (2026-08-23). `playtests` delivered **64 / 8,149** against a
> scoped 80 / 8,996 — three separate corrections, all of them reachability, none of them
> content. See the 2026-08-24 correction below and §7. The `Keep` columns are unchanged.

### `design` is a KEEP, and it is the only clean answer of the three

**Zero deletable documents.** 78 of 81 are reachable from a live root without either
catalogue below; the remaining 3 (432 lines) depend on one. This is not an artifact — the
design corpus is the rationale substrate the ratified registers cite, and 14 of its
documents are named by a non-completed tracker row directly.

"Keep, with a reason written down" was ruled to survive per-document only, never
per-corpus. `design` earns it 81 times over, which is the same outcome by a legitimate
route.

### Two hand-maintained catalogues are a citation floor

The parent plan's §7 says to exclude generated indexes before counting, because
`AGENT/Docs/INDEX.md` cites everything and sets a floor of one. **Two hand-written
documents do the same thing and no rule excluded them:**

| Catalogue | Lines | What it is | What already replaced it |
|---|---:|---|---|
| `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | 970 | a "draft tracker" of all active work | `coordination/tasks.json`, since 2026-07 |
| `AGENT/Docs/plans/doc_role_manifest_2026-06-29.md` | 176 | a map of which document family owns what | phase 1's `Role:` front matter, enforced by `check_docs.py`, since 2026-08-23 |

Between them they are the sole live referrer of **61 documents / 11,802 lines** — 72 of
the 150 documents reached at depth ≥ 2. Both are inventories: they cite by enumeration,
not by dependency, so a citation from either says only "this file existed on 2026-06-29".

**Both are superseded by mechanisms that already shipped.** They are what phase 5 retires.

### The transitivity trap fired twice

Counting the catalogues, `design` reads 81/81 live and `playtests` 70/150. Suppressing
them, `design` reads 78/81 and `playtests` 41/150. The design conclusion is stable under
both; the playtest one is not. **A conclusion that survives suppressing the hubs is a
finding; one that does not is an artifact of the hub.** Intra-corpus hubs did the same
thing at a smaller scale — 31 of `playtests`' and 18 of `Code Reviews`' depth-≥2 documents
are reached only through another document in their own corpus, which is exactly the
leaf-by-leaf failure the archive purge was caught by.

## 4. What is actually deletable, and why it is safe

The 129 mine-and-delete documents are dominated by two families that **age out by
construction**:

- **43 pre-`v0.4` code reviews** (`code_review_2026-05-*`, `code_review_2026-06-*`) — 
  point-in-time scans of code that has since been rewritten. The six largest are 3,136
  lines between them.
- **Pre-`v0.6` playtest checklists and triage plans** — a returned checklist for a build
  nobody can run again, whose every actionable line became a tracker row that has since
  closed.

Neither family is cited by any code, any topic document, any non-completed tracker row, or
any register. Their findings reached the project through rows, and the rows are the record.

**This is still a mining job, not a `git rm`.** Phase 3's discipline applies: sample before
deleting, and move anything unique into its owning GDD chapter first. The archive purge was
scoped at 23,212 lines and delivered 1,526 for precisely this reason — expect the same
ratio here and treat 20,942 as the ceiling, not the estimate.

**Deleting these frees no clone space.** History retains the bytes; the win is that a
reader looking for the current answer stops finding six superseded ones first. Same finding
as the archive purge and the archive-ref conversion.

## 5. Execution rows

Triage does not delete anything. Three rows carry the work:

1. ~~`RETIRE-CONTROL-PLANE-CATALOGUES-2026-08-23` — retire the two catalogues in §3, which
   is phase 5's one-in-one-out payment. Do this **first**: until it lands, 61 documents
   read as live that are not.~~ **Superseded 2026-08-23 — see the Correction below §6.**
   The recommendation inverted: the Control Plane is live and the **role manifest** was the
   superseded catalogue. The row executed as the manifest's retirement and is closed. The
   two mining rows below never depended on it.
2. `MINE-CODE-REVIEW-CORPUS-2026-08-23` — the 49 documents / 11,946 lines in `Code
   Reviews`. Largest single win, and the most self-contained.
3. `MINE-PLAYTEST-CORPUS-2026-08-23` — the 80 documents / 8,996 lines in `playtests`.

`design` gets no row. It is a keep.

## 6. What phase 5 retires

Per one-in-one-out, and this is the answer §5 of the parent plan left as "to be named when
scoped":

- **`project_control_plane_2026-06-29.md`** — the pre-tracker control plane. `tasks.json`
  has been the authority since 2026-07 and `check_tasks.py` enforces it; the catalogue has
  been a parallel unenforced copy for seven weeks.
- **`doc_role_manifest_2026-06-29.md`** — the hand-maintained role map. Phase 1 moved roles
  into each document's own front matter and `check_docs.py` gates them, which is the same
  move the ledger made out of the notes tree in phase 0.

Two mechanisms retired, none added. The triage adds no check: the reachability measurement
here is a one-off, and the standing enforcement is the cross-corpus citation boundary phase
2 already shipped.

### Both catalogues are load-bearing today — the retirement is gated by check `[30]`

Found by writing this document: `check_docs.py` check `[30]` (`active-doc-ownership`)
**hard-codes both catalogues** as the ownership authority for every active document under
`AGENT/Docs/plans` and `AGENT/Docs/design`. A new plan fails the docs gate until it is
listed in the Control Plane, the Feature Index, or the role manifest's *Active Source
Ownership Map*. This document failed on its first run and is registered in the manifest for
exactly that reason — the entry it adds is an instance of the mechanism it proposes to
retire.

**So the citation floor in §3 is not neglect. It is enforcement.** These two files are cited
by 61 documents because a gate requires it, which also explains why a 970-line "draft
tracker" survived seven weeks past the tracker that replaced it.

**And the reason the Control Plane exists at all is a repo boundary:**
`coordination/tasks.json` lives in `Project_Prometheus_Container`, and `check_docs.py` runs
inside `Project_Prometheus`, so the check *cannot* see the tracker. The in-repo catalogue is
the shadow copy that gap forced.

Retiring the catalogues therefore requires answering what check `[30]` becomes. That is a
design call, not a deletion, and `RETIRE-CONTROL-PLANE-CATALOGUES-2026-08-23` carries it:

- **(a) Retire check `[30]` outright.** Work status is owned by `tasks.json` and enforced by
  `check_tasks.py`; document roles are owned by front matter and enforced by check `[48]`.
  Both of the manifest's jobs already have live owners, which is the strongest argument —
  and it is the same shape as phase 0 moving the ledger out of the notes tree.
- **(b) Repoint check `[30]` at the tracker.** Needs `check_docs.py` to read across the repo
  boundary, which nothing here does today and which the pack-check `GIT_DIR` trap on
  2026-08-23 shows is easy to get wrong.
- **(c) Keep the manifest, retire only the Control Plane.** The smaller win: 970 of the
  1,146 catalogue lines and 54 of the 72 floor citations, with no check change at all,
  since the manifest's ownership map is already `[30]`'s fallback path.

~~**(c) is the recommendation**~~ — **withdrawn 2026-08-23 before execution; see the
Correction section immediately below.** (c) rested on the Control Plane being superseded,
which measurement disproved: it is a live 129-Track-ID registry with 2,707 citations and
two CI gates, and (c) would have cost 99 documents their ownership registration. The owner
inverted the recommendation and phase 5 retired the role manifest instead. (a) and (b) are
untouched by this and still need the owner.

---

## Correction — 2026-08-23, on executing §6

**§6's recommendation (c) was wrong, and the owner inverted it.** Measured before
execution, per the standing rule that a row's own premise is the unreliable source. The
Control Plane is **not** superseded; the **role manifest** was, and it is what phase 5
actually retired. What follows is what the measurement found; §3 and §6 below are left
as written, because the numbers in them are correct — it is the disposition drawn from
them that was wrong.

1. **The Control Plane is live, not a seven-week-stale draft tracker.** It carried
   `Last verified: 2026-08-21` — two days before this triage — and the current v0.7.0
   and v0.8 narrative. Decisively, it is the **definition site of a 129-Track-ID
   namespace with 2,707 citations across 199 live files**, and **62 of those Track IDs
   are cited by `coordination/tasks.json` itself**. It and the tracker are orthogonal
   axes — tracks are the roadmap, tasks are session work — so the tracker never replaced
   it. This is the same shape as the register expiry, which was ranked first as dead
   weight and demoted to fourth once its 2,273 citations were counted.
2. **"No check change at all" was false, and understated the blast radius.** Deleting
   the Control Plane would have required deleting check `[20]` (its ~90-line schema
   validator) and half of check `[30]` — and it would have broken **a second CI gate this
   triage never found**, `scripts/ci/check_evidence_matrices.py`, which parses the
   Control Plane's rows directly to gate multi-slice Implemented tracks.
3. **The cost side of (c) was never measured.** **99 active plan/design documents** (70
   plans, 29 design) have the Control Plane as their *only* ownership registration under
   check `[30]`. Retiring it fails the docs gate for all 99 unless each is re-homed into
   the manifest — so (c)'s net effect would have been to **grow** the hand-maintained
   exception list from 65 to 164 entries while deleting the tracker that fed it. A
   further 155 live files link to the Control Plane by path.
4. **The mining rows were never blocked by this one.** §7 defines mine-and-delete as
   unreachable *even counting* the catalogues, so the 49 and 80 file sets stand whatever
   happens here. The 29 + 29 catalogue-only documents are an **enlargement** if a
   catalogue is retired, not a prerequisite. The dependency edges recorded on
   `MINE-CODE-REVIEW-CORPUS-2026-08-23` and `MINE-PLAYTEST-CORPUS-2026-08-23` pointed the
   wrong way; both are discharged by this row completing, and each row's `reference` now
   records that they were never prerequisites.
5. **One document must come off §7's mine list.**
   `AGENT/Docs/playtests/ai_suspend_boundary_evidence_matrix_2026-07-16.md` is one of only
   two entries in `AGENT/Docs/governance/implemented_track_evidence.json` and is CI-gated
   by `check_evidence_matrices.py`. **§2's reachability method only walked markdown
   citations**, so it could not see a non-markdown root. That is a method gap of the same
   family as §2's basename correction, and it is the one this triage did not catch.
   (Seven `evidence/*/README.md` files also matched a non-markdown grep; all seven are the
   generic-basename false positive §2 warns about, verified false.)

### What phase 5 actually retired

**The doc role manifest** (`AGENT/Docs/plans/`, deleted 2026-08-23 at `86931d3b`) — 177
lines, 13 live inbound citers against the Control Plane's 155. Its content was
dispositioned rather than deleted:

| Manifest section | Disposition |
|---|---|
| Role Rules, Role Vocabulary | Moved to [`../governance/documentation_lifecycle_2026-06-13.md`](../governance/documentation_lifecycle_2026-06-13.md) § *Document role vocabulary* — its governance home. |
| Ownership Exceptions, Active Source Ownership Map (65 entries) | Moved into [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md) § *Active Source Ownership Map*, which is the text check `[30]` already reads. |
| Named Documents (22 rows) | Deleted — superseded by `Role:` front matter (check `[48]`) and the Feature Index. |
| Enforcement Hooks (3 rows) | Deleted — it restated `check_docs.py`, and DoD#2 makes the check the durable enforcement. |

Check `[30]` lost its manifest-parsing half (`_ROLE_MANIFEST`,
`_role_manifest_owner_paths`, `_OWNERSHIP_MAP_HEADING`) and now reads the Control Plane
and Feature Index only. **Enforcement improved rather than degraded:** the ownership map
now sits inside the document whose local markdown links check `[20]` validates, so its 65
entries are link-checked for the first time.

*One-in-one-out: one mechanism retired (the hand-maintained parallel role catalogue and
its half of a check), none added.*

## Correction — 2026-08-24, on executing order 9

`MINE-PLAYTEST-CORPUS-2026-08-23` executed. **64 files / 8,149 lines deleted**; the corpus
went 150 → 86 markdown files. Scoped at 80 / 8,996 and delivered 64 / 8,149 — the
"ceiling, not estimate" caveat held for a third corpus. What the premise got wrong, and what
the method found.

### Reachability held, with one further correction of the same shape

Re-measured at `agent/integration` before deleting, transitively, from live roots only
(code and tooling, `Role: topic` documents, `AGENT/WAITING_WORK.md`, non-completed tracker
rows), with the session-note tree and `AGENT/Docs/archive` excluded as roots and the two
enumerating hubs — `AGENT/Docs/INDEX.md` and **this document's own §7 appendix** —
suppressed. **All 79 files read as having zero live referrers.** §7 must be suppressed like a
generated index: an appendix that names a delete set makes every member of it reachable,
which is the hub artifact §3 warns about wearing the triage's own clothes.

**Two files came off the list as version-parameterised roots** — the second instance of the
non-markdown-root gap, and the first that no filename grep could have found. See §2.1, where
the method is now written down.

**Then the mandatory post-deletion grep sweep found two live references the citation walk had
missed, and unpicking them took thirteen more files out of scope.** This is the strongest
argument yet for §2.1's closing rule: the sweep is not a formality, it is the only check that
catches what the walk cannot see.

*The first miss — relative paths to an ambiguous basename.* §2's rule matches an ambiguous
basename **by full path only**, but documents cite their neighbours by *relative* path:
`playtest_v0.7.0_windows_return_2026-08-07.md:12` names its own evidence as
`evidence/v0.7.0/returned_checklist.md`, and `project_control_plane_2026-06-29.md:1010` links
`../playtests/evidence/v0.6.0/README.md`. Neither is a full repo path, so neither matched.
**Resolve every path-shaped token against the citing file's own directory before matching.**

*The second miss — an evidence packet is referenced by DIRECTORY, and its files are found by
opening it.* That makes `evidence/**` structurally unreachable by any citation walk, and it is
where both of §2's blind spots concentrate: nine of the twelve markdown files there are named
`README.md` or `PLAYTEST_CHECKLIST.md`, which §2 excludes from basename matching as generic,
and which nothing then links to by full path. The dispositions this produced were not
self-consistent — it deleted the v0.7.0 packet's completed checklist while keeping its sibling
decision sheet, and deleted three packets' READMEs while keeping the raw logs they index.

**`AGENT/Docs/playtests/evidence/**` is therefore OUT OF SCOPE for this row** — all 12 files
(687 lines) restored, along with `playtest_v0.7.7_owner_return_2026-08-12.md` (47 lines), whose
only inbound link is from `evidence/v0.7.7/README.md` and which is the named acceptance record
for the stable v0.7 release. The subtree needs a **directory-level** disposition rule that this
triage never wrote, and it holds the only copy of what testers actually returned (`Incoming/`
is gitignored). That is a new decision, not one this row could take.

### The generic-basename trap fired twice more (instances four and five)

A tracker sweep by basename reported three *open* rows citing delete-set files. All three
were false:

| Apparent citation | What the row actually names |
|---|---|
| `playtest_checklist_v0.5.4.md` (`B4-PREP-MAP-DEPLOYMENT-2026-07-22`) | `AGENT/v0.5.4/playtest_checklist_v0.5.4.md` — a **different tree**, outside this corpus |
| `evidence/v0.7.0/returned_checklist.md` (two planned rows) | `evidence/v0.6.0/returned_checklist.md` — a **keep**, same basename |
| `evidence/v0.7.7/README.md`, `.../raw/PLAYTEST_CHECKLIST.md` (four open rows) | the generic basenames §2 already excludes |

### Mining: 13 orphaned finding IDs, and no salvage at all

131 distinct ID-shaped tokens in the final 64-file set; **18 orphaned** against everything outside it, of
which five (`B1-B2`, `E1-E3`, `Q1-Q3`, `V030-GP`, `V030-INP`) are ranges and family
prefixes, not IDs. The real 13:

- **Nine are routing-bucket labels, not findings.** `V030-DSP-02`, `V030-GP-04`,
  `V030-REB-01`, `V030-RNG-01`, `V031-INP-01`, `V031-REG-01`, `V031-SUS-01` are rows in the
  v0.3.0/v0.3.1 triage kits' *routing tables* — categories a return could be sorted into.
  They are orphaned precisely because nothing was ever routed to them. The sibling buckets
  that *were* used (`V030-DSP-01`, `V030-REG-01`, `V030-LOG-01`, …) are not orphans.
- **`V025-07` is a PASS** and `V025-10` a NOT-RUN validation gap whose only actionable line
  was a process request: make returning `godot.log` a top-of-handbook item. **Spent** —
  `playtest_checklist_v0.7.9.md:16,65` requires the BUILD STAMP launch and the complete log
  directory.
- **`V054-RC-01`, `-RC-02`, `-RC-04`, `V054-FR-03` are real defects, and all four are
  fixed.** Verified against the code, per §2.1 step 2, because — for the second time — **no
  tracker row cites any of these IDs**:
  - `V054-RC-01` (single-step/cycling on Results and Defeat): suppression sits in `_input`,
    not `_unhandled_input` — `scripts/ui/PrepScreen.gd:43`, `scripts/ui/GameOverScreen.gd:184`.
  - `V054-RC-02` (Rewind unreachable after reopen): `FocusNavigator._capture_ui_active()`
    exists and gates navigation — `scripts/shared/FocusNavigator.gd:36,53,67`.
  - `V054-RC-04` (top-edge HUD phase marker unreachable under the toolbar strip):
    `scripts/ui/HudLayoutEditor.gd:117-119` — *"The visual band must not make a top-edge HUD
    panel unreachable"*, `strip.mouse_filter = MOUSE_FILTER_IGNORE`.
  - `V054-FR-03` (campaign-authored victory actions): shipped by `B4-RESULT-ACTIONS-2026-07-22`
    (`completed`), which names checklist §A6 as its acceptance evidence.
  - The **consuming row** for the family is `V053-PLAYTEST-TRIAGE-2026-07-22` (`completed`):
    *"its root-cause review confirmed RC-01..RC-04 fixed."*
- **Four deferral markers, all owned:** Issue 7 per-faction economy →
  `PP-FACTION-GOLD-ECONOMY`; loss-on-enemy-seize → `PP-ENEMY-SEIZE-DEFEND`; the strategic
  data-ownership pass → `PP-STRATEGIC-DATA-OWNERSHIP`; Pair Up Issue 9 approach B →
  `PP-PAIRUP-OFFMAP-RUNTIME`.
- **One stated retention reason, discharged.** `v0.7.0_display_gated_tasks.md` said it was
  *"kept for the deferred mobile rows' wording"*; its successor
  `v0.7.0_windows_round_display_gated_tasks.md:67-74` carries all three rows under
  *"Deferred to the mobile pass — not cancelled"*. Nothing unique remained.

**Total salvage: zero lines.** Order 8 carried two findings into a topic document; order 9
carried none, and that is a finding about the corpus rather than about the method — a
returned checklist for a build nobody can run is a *record of a conversation*, and its
conclusions had already been written down as rows.

### Not deleted, and still to be decided

Three groups, none of which this row could take:

1. **The 29 catalogue-only playtest documents** (6,095 lines) in the next section. They
   became reachable-by-inventory only, and the Control Plane — the catalogue that reaches
   them — was **kept** (§*Correction — 2026-08-23*).
2. **`AGENT/Docs/playtests/evidence/**`** — 12 markdown files, 687 lines, plus the raw logs
   and screenshots the triage never counted. It needs a directory-level rule; see above.
3. **30 stale document paths in `coordination/tasks.json`**, all in `completed` rows'
   `reference` and `playtest_ref` prose. They are historical narration and no gate reads
   them: check `[1]` scans the Prometheus doc tree only, and it cannot cross the repo
   boundary — the mirror image of the blindness `TASK-ID-CITATION-GATE-2026-08-24` measured
   in the other direction. Mass-editing 30 closed rows is the `TRACKER-DIVERGENCE` shape and
   was deliberately not done. **Left for the owner as a scoped decision**, with the paths
   recorded on this row.

### A note on where the salvage discipline actually bit

Nothing in §2.1 steps 1–4 changed a single line of the tree. **Every correction this row
made came from reachability**, and specifically from the post-deletion grep sweep that
§2.1 mandates as a backstop. If a future mining row has to cut one step, cut the ID
orphaning before the sweep — not the other way round.

## 7. Per-document dispositions

Documents not listed here are **keep — live**: reached from a live root without either
catalogue. Line counts follow each path.

#### `AGENT/Docs/playtests` — Mine and delete — 64 files / 8,149 lines deleted 2026-08-24

Corrected three times: 80/8,996 → 79/8,970 (2026-08-23) → **64 / 8,149 deleted** (2026-08-24).
Every correction is reachability; none is content. Two files are struck below as
version-parameterised roots, and **the whole `evidence/` subtree plus the v0.7.7 acceptance
record came out of scope** — see the 2026-08-24 correction above §7 for why.

- ~~`ai_suspend_boundary_evidence_matrix_2026-07-16.md` — 26~~ **KEEP (corrected 2026-08-23):** it is one of two entries in `../governance/implemented_track_evidence.json` and is CI-gated by `scripts/ci/check_evidence_matrices.py`. Deleting it fails that gate. Mine-and-delete for `playtests` is therefore **79 files / 8,970 lines**.
- `evidence/v0.6.0/README.md` — 22
- `evidence/v0.7.0/README.md` — 55
- `evidence/v0.7.0/returned_checklist.md` — 293
- `evidence/v0.7.1/README.md` — 9
- `evidence/v0.7.1/raw/PLAYTEST_CHECKLIST.md` — 89
- `evidence/v0.7.3/README.md` — 9
- `evidence/v0.7.3/raw/PLAYTEST_CHECKLIST.md` — 80
- `evidence/v0.7.5/README.md` — 10
- `evidence/v0.7.5/raw/PLAYTEST_CHECKLIST.md` — 52
- `evidence/v0.7.6/README.md` — 10
- `evidence/v0.7.7/README.md` — 11
- `evidence/v0.7.7/raw/PLAYTEST_CHECKLIST.md` — 47
- `playtest_build_v0.2.4.md` — 84
- `playtest_build_v0.2.5.md` — 74
- `playtest_build_v0.2.9.md` — 97
- `playtest_build_v0.3.4.md` — 42
- `playtest_build_v0.3.5.md` — 44
- `playtest_build_v0.3.6.md` — 46
- `playtest_build_v0.4.0_campaign_followup.md` — 29
- `playtest_build_v0.4.0_campaign_test.md` — 32
- `playtest_build_v0.4.1.md` — 37
- `playtest_build_v0.4.2.md` — 37
- `playtest_build_v0.5.0.md` — 29
- `playtest_build_v0.5.1.md` — 33
- `playtest_build_v0.5.2.md` — 38
- `playtest_build_v0.5.4.md` — 53
- `playtest_build_v0.5.5.md` — 60
- `playtest_build_v0.5.6.md` — 40
- `playtest_build_v0.5.7.md` — 45
- `playtest_build_v0.5.8.md` — 41
- `playtest_build_v0.6.0.md` — 48
- `playtest_build_v0.6.0_return_fixes.md` — 34
- `playtest_build_v0.6.1.md` — 43
- `playtest_build_v0.7.0.md` — 83
- `playtest_build_v0.7.6.md` — 29
- `playtest_build_v0.7.7.md` — 31
- ~~`playtest_build_v0.7.9.md` — 22~~ **KEEP (corrected 2026-08-24):** `scripts/ci/check_release_source_branch.py:40` builds `AGENT/Docs/playtests/playtest_build_v{version}.md` the same way and exits with `release-source: missing build record`. It is the *current* release version, so this pair goes live and dead with each version bump.
- `playtest_checklist_display_accessibility_2026-06-15.md` — 220
- `playtest_checklist_v0.2.4.md` — 395
- `playtest_checklist_v0.2.5.md` — 437
- `playtest_checklist_v0.2.5_returned_2026-07-04.md` — 449
- `playtest_checklist_v0.2.9.md` — 215
- `playtest_checklist_v0.3.4.md` — 94
- `playtest_checklist_v0.3.4_returned_2026-07-14.md` — 95
- `playtest_checklist_v0.3.5.md` — 77
- `playtest_checklist_v0.3.6.md` — 75
- `playtest_checklist_v0.4.0_fix_rerun.md` — 42
- `playtest_checklist_v0.4.1.md` — 172
- `playtest_checklist_v0.4.2.md` — 183
- `playtest_checklist_v0.5.0.md` — 243
- `playtest_checklist_v0.5.1.md` — 309
- `playtest_checklist_v0.5.2_returned_2026-07-21.md` — 159
- `playtest_checklist_v0.5.3_returned_2026-07-21.md` — 247
- `playtest_checklist_v0.5.4.md` — 349
- `playtest_checklist_v0.5.5.md` — 294
- `playtest_checklist_v0.5.5_returned_2026-07-24.md` — 293
- `playtest_checklist_v0.5.6.md` — 90
- `playtest_checklist_v0.5.7.md` — 88
- `playtest_checklist_v0.6.0.md` — 174
- `playtest_checklist_v0.6.0_return_fixes.md` — 82
- `playtest_checklist_v0.7.6.md` — 60
- `playtest_checklist_v0.7.7.md` — 47
- ~~`playtest_checklist_v0.7.9.md` — 65~~ **KEEP (corrected 2026-08-24):** `scripts/tests/test_release_metadata.gd:98` builds `res://AGENT/Docs/playtests/playtest_checklist_v%s.md` from the export preset's `application/product_version` and FAILs if it is missing. It is the *current* release version, so this pair goes live and dead with each version bump.
- `playtest_v0.2.5_results_triage_plan_2026-07-04.md` — 386
- `playtest_v0.3.0_return_triage_kit_2026-07-08.md` — 166
- `playtest_v0.3.1_return_triage_kit_2026-07-12.md` — 144
- `playtest_v0.3.4_results_triage_plan_2026-07-14.md` — 56
- `playtest_v0.5.2_results_triage_plan_2026-07-21.md` — 405
- `playtest_v0.7.7_owner_return_2026-08-12.md` — 47
- `v0.4.0_d12eb33_log_checklist_intake_handoff_2026-07-15.md` — 66
- `v0.5.2_fix_implementation_plan_2026-07-21.md` — 307
- `v0.5.6 playtest results/playtest_checklist_v0.5.6.md` — 104
- `v0.7.0_display_gated_tasks.md` — 55
- `v0.7.0_onboarding_windows.md` — 94
- `v0.7.0_windows_round_onboarding.md` — 110
- `v0.7.1_waiting_work_handoff_2026-08-08.md` — 87
- `v0.7.1_waiting_work_implementation_handoff_2026-08-08.md` — 63
- `v0.7.1_waiting_work_next_handoff_2026-08-08.md` — 40
- `v0.7.1_waiting_work_session_handoff_2026-08-08.md` — 48

#### `AGENT/Docs/playtests` — Keep — reached only by the two catalogues (29 files, 6095 lines)

- `campaign_save_post_audit_followup_evidence_matrix_2026-07-15.md` — 46
- `playtest_build_v0.2.6.md` — 95
- `playtest_build_v0.2.7.md` — 98
- `playtest_build_v0.2.8.md` — 105
- `playtest_build_v0.3.0.d.md` — 86
- `playtest_build_v0.5.3.md` — 60
- `playtest_checklist_v0.2.3_returned_2026-07-01.md` — 565
- `playtest_checklist_v0.2.6.md` — 304
- `playtest_checklist_v0.2.6_returned_2026-07-04.md` — 327
- `playtest_checklist_v0.2.7.md` — 302
- `playtest_checklist_v0.2.7_returned_2026-07-05.md` — 311
- `playtest_checklist_v0.2.8.md` — 277
- `playtest_checklist_v0.2.8_returned_2026-07-07.md` — 277
- `playtest_checklist_v0.3.0.d.md` — 278
- `playtest_checklist_v0.3.0.d_returned_2026-07-10.md` — 297
- `playtest_checklist_v0.3.5_returned_2026-07-14.md` — 33
- `playtest_checklist_v0.3.6_returned_2026-07-14.md` — 43
- `playtest_checklist_v0.4.0_returned_2026-07-15.md` — 160
- `playtest_checklist_v0.5.2.md` — 246
- `playtest_checklist_v0.5.3.md` — 243
- `playtest_v0.2.3_results_triage_plan_2026-07-01.md` — 577
- `playtest_v0.2.6_results_triage_plan_2026-07-04.md` — 208
- `playtest_v0.2.7_results_triage_plan_2026-07-05.md` — 189
- `playtest_v0.2.8_results_triage_plan_2026-07-07.md` — 196
- `playtest_v0.3.0.d_results_triage_plan_2026-07-10.md` — 180
- `playtest_v0.3.5_results_triage_plan_2026-07-14.md` — 56
- `playtest_v0.4.0_results_triage_plan_2026-07-16.md` — 85
- `playtest_v0.5.3_results_triage_review_2026-07-22.md` — 365
- `v0.7.0_windows_round_display_gated_tasks.md` — 86

#### `AGENT/Code Reviews` — Mine and delete (49 files, 11946 lines) — all 49 deleted 2026-08-23

Executed by `MINE-CODE-REVIEW-CORPUS-2026-08-23` at `3872252c`. The inventory below
names files that no longer exist; that is what it is for.

- `band5_plans_review_2026-07-03.md` — 195
- `code_review_2026-05-11.md` — 411
- `code_review_2026-05-12.md` — 457
- `code_review_2026-05-13.md` — 635
- `code_review_2026-05-13c.md` — 527
- `code_review_2026-05-16.md` — 325
- `code_review_2026-05-16b.md` — 366
- `code_review_2026-05-16c.md` — 377
- `code_review_2026-05-16d.md` — 410
- `code_review_2026-05-17.md` — 214
- `code_review_2026-05-18.md` — 463
- `code_review_2026-05-19.md` — 180
- `code_review_2026-05-19b.md` — 479
- `code_review_2026-05-19c.md` — 249
- `code_review_2026-05-20.md` — 396
- `code_review_2026-05-21.md` — 217
- `code_review_2026-05-21b.md` — 98
- `code_review_2026-05-24.md` — 96
- `code_review_2026-05-27.md` — 195
- `code_review_2026-06-09.md` — 311
- `code_review_2026-06-10.md` — 575
- `code_review_2026-06-13.md` — 158
- `code_review_2026-06-14.md` — 172
- `code_review_2026-06-14b.md` — 275
- `code_review_2026-06-17.md` — 89
- `code_review_checkpoint_2026-08-09.md` — 139
- `code_review_prep_2026-07-07.md` — 81
- `code_review_v0.3.0_release_delta_prep_2026-07-07.md` — 147
- `fe_implementation_readiness_audit_2026-07-28.md` — 97
- `full_project_audit_multisession_handoff_2026-08-09.md` — 266
- `full_review_baseline_2026-08-09.md` — 150
- `full_review_rollup_2026-06-14.md` — 138
- `full_review_rollup_2026-07-05.md` — 109
- `playtest_v0.2.5_triage_review_2026-07-04.md` — 273
- `playtest_v0.3.1_triage_review_2026-07-12.md` — 238
- `playtest_v0.5.4_root_cause_review_2026-07-22.md` — 339
- `playtest_v0.5.5_root_cause_review_2026-07-24.md` — 228
- `playtest_v0.5.6_root_cause_review_2026-07-25.md` — 278
- `procedure_meta_review_2026-06-14.md` — 139
- `v030_full_scan/00_scope.md` — 104
- `v030_full_scan/01_save_persistence.md` — 165
- `v030_full_scan/02_determinism.md` — 144
- `v030_full_scan/03_input_model.md` — 166
- `v030_full_scan/04_input_display.md` — 153
- `v030_full_scan/05_map_turn_core.md` — 158
- `v030_full_scan/06_ui_misc.md` — 147
- `v030_full_scan/_TRACKER.md` — 136
- `v030_full_scan/code_review_v0.3.0_full_scan_2026-07-08.md` — 238
- `v071_remediation_handoff_2026-08-09.md` — 43

#### `AGENT/Code Reviews` — Keep — reached only by the two catalogues (29 files, 5275 lines)

- `code_review_2026-05-15.md` — 527
- `code_review_2026-06-19.md` — 132
- `code_review_2026-07-05.md` — 102
- `code_review_2026-07-07.md` — 103
- `code_review_2026-07-15.md` — 136
- `code_review_2026-08-09.md` — 188
- `code_review_v0.3.0_release_delta_2026-07-07.md` — 278
- `data_assets_review_2026-06-14.md` — 225
- `data_assets_review_2026-07-05.md` — 61
- `data_assets_review_2026-07-15.md` — 127
- `data_assets_review_2026-08-09.md` — 152
- `full_review_rollup_2026-07-15.md` — 159
- `full_review_rollup_2026-08-09.md` — 184
- `gdd_extensibility_uncertainty_review_2026-06-29.md` — 70
- `integration_consolidation_wave2_intake_review_2026-07-29.md` — 82
- `integration_feature_branch_consolidation_closeout_2026-07-29.md` — 59
- `playtest_v0.2.6_triage_review_2026-07-04.md` — 179
- `playtest_v0.2.7_triage_review_2026-07-05.md` — 233
- `playtest_v0.2.8_triage_review_2026-07-07.md` — 156
- `playtest_v0.3.0.d_triage_review_2026-07-10.md` — 178
- `playtest_v0.4.0_triage_review_2026-07-16.md` — 278
- `playtest_v0.4.1_triage_review_2026-07-16.md` — 54
- `process_history_review_2026-06-14.md` — 253
- `process_history_review_2026-07-05.md` — 98
- `process_history_review_2026-07-15.md` — 216
- `process_history_review_2026-08-09.md` — 172
- `process_history_tooling_review_2026-07-17.md` — 301
- `v0.3.0_fix_pass_review_2026-07-09.md` — 194
- `v0.4.0_band2_contracts_review_2026-07-13.md` — 378

#### `AGENT/Docs/design` — Keep — reached only by the two catalogues (3 files, 432 lines)

- `combat_actions_ux_research_2026-08-08.md` — 102
- `pixel_art_resolution_options_2026-07-12.md` — 161
- `tile_size_native_res_rescale_assessment_2026-07-12.md` — 169