# Session Note - 2026-08-17 — `R1` precedence diff

## Branch context

- Branch: `agent/integration` (documentation-only; the docs-guard refuses `AGENT/Docs/plans/**`
  on a feature branch, and this change touches both `plans/` and `check_docs.py`)
- Base branch: `agent/integration`
- Base SHA: `40337dbe`
- Coordination Work ID: `R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16`

## What was done

Picked up [`pre_r1_handoff_2026-08-17.md`](../Docs/plans/pre_r1_handoff_2026-08-17.md) §1 and ran
`R1`'s mandatory precedence diff — the seventh in the series, and the first to run **against the
corpus** rather than for a single walk. The re-derivation walk itself has **not** run; the diff
sets its order.

New document:
[`AGENT/Docs/design/r1_plan_corpus_precedence_diff_2026-08-17.md`](../Docs/design/r1_plan_corpus_precedence_diff_2026-08-17.md).

### The method finding, which is the session's headline

**A citation-driven precedence check is structurally blind to the failure `R1` exists to catch.**
It answers *"did something this plan cites move?"* when the question is *"does a ruling exist that
this plan should have absorbed?"* Those differ exactly when the ruling **post-dates the plan**,
because then the plan has no reason to name it — and **silence is indistinguishable from
currency**.

Run mechanically over `plans/` + `design/`, the check returns 42 documents and **misses all three
high-value instances**:

| Document | Cites | Actually governed by |
|---|---|---|
| `b4_prep_deployment_handoff_2026-07-14.md` | `CST-5`, `CST-6` | `PHB`, `RPD` — names neither |
| `unified_ui_programme_2026-08-12.md` | `UUI`, `UITH` only | + `RPD`, `L10N`, `CEUI`, `DSX`, `CMP` |
| `recent_research_implementation_portfolio_review_2026-07-27.md` | **nothing** | `EPUX`, `TSV`, `CUR`, `SHC`, `DSX`, `RPD` |

The third is the decision source for **21 open build rows** and cites no register token anywhere.

Underneath it: standing rule 4 keys on a `Decision source` header that **six of 109** plan documents
carry. `Last verified` is doing that job and cannot — it records when a file was *touched*, not what
it was *checked against*. Handed to `R3`, since it changes the header contract corpus-wide.

### Five ratified registers were not in `REGISTERS.md`

`gen_docs_index.py` runs its register-detection heuristic **only when `Type:` is absent**. An
explicit `Type: design` on a document full of rulings empties the `register` field and drops the
family from the catalog — silently, because nothing compares `REGISTERS.md` against documents that
*look* like registers. Same shape as the `Type:` defect check `[45]` closed yesterday, except the
value here is **valid, merely wrong**, so `[45]` cannot fire.

Filed: `EPUX-01..28`, `TER-1..10`, `PCM-1..7`.

**`EPUX` was the expensive one.** 28 rulings ratified 2026-07-26, cited 326 times across 22
documents, named in `S1`'s own resolved-corpus list — and its header read `Status: Draft - owner
review` with `Last verified: 2026-07-25`, *a day before the walk that ratified it*.

**Its invisibility had already cost a duplicated ruling.** `RPD` recorded that `EPUX`
*"never ruled"* disabled-entry focusability and ruled it again as `[RPD-15]` on 2026-08-13 —
eighteen days after `[EPUX-07]` ruled it identically ("disabled entries are focusable, not
activatable … Settles the question deferred from `EPUX-02` and `EPUX-04`"). The corpus now cites the
**later** one: `campaign_editor_ui_open_questions_2026-08-12.md:1093`. `RPD`'s author read the
*question* text, which still says "deferred", with no catalog entry to lead them to the rulings
section. Carried into `R3` with the duplicate already identified.

### `check_docs.py` `[46]`

The rule the `DLUX` remedy owed. `gen_docs_index.py`'s own comment records `DLUX` hitting this and
being fixed **by hand with an explicit `Register:` header** — a per-document remedy where `DoD#2`
required a check. `[46]` fails a document that cites one family ≥12 times in bracketed form, declares
a ratified `Status`, and appears in no catalog entry.

**It found `PCM-1..7` on its first run**, after `EPUX` and `TER` had already been filed by hand.

### The two build epics are four, and one slice exists twice

`R1` instance (e) says *"two open epics … with no ordering between them."* Both halves are wrong,
one safely and one not.

- **Nine** cross-epic edges already exist; the graph is **acyclic** and sorts into 12 clean layers.
- It is a **four**-epic graph — `DRC-V1`, `PREP-V1`, `LIB-V1`, `UIREC-V1`. `PREP-V1-S02` and
  `DRC-V1-S07` both wait on `UIREC-V1-S05`; `UIREC-V1-S06` waits on `LIB-V1-S02`.
- **`DRC-V1-S05` and `PREP-V1-S04` are the same slice entered twice** — same title ("Trade and
  designated-provider Convoy"), *identical* dependency set, both `planned`, two epics.
- Of the four shared `EPUX` primitives, **only `[EPUX-06]` has a correct producer→consumer edge**.
  `[EPUX-11]`'s consumer `DRC-V1-S09` sorts a **full layer before** its producer `PREP-V1-S03`, and
  both Trade rows sit in the same layer as `PREP-V1-S05`, which builds the `[EPUX-24]` core they
  commit over.

This is the sequencing plan's own prediction — *"Do this here or the first Trade slice builds
`[EPUX-24]`'s core a second time"* — visible in the dependency graph rather than inferred.

### Instance (b)'s premise is false

**There is no prep/economy implementation plan.** The eight `PREP-V1` rows descend from eight
numbered paragraphs in §6 of a portfolio review last verified 2026-07-27, three weeks behind
`RPD`/`CUR`/`TSV`/`DSX`. The `DRC` line has a full integrated plan re-derived against its register;
this line has paragraphs. That is *why* the shared primitives have no assigned owner. Now
`PREP-ECONOMY-IMPLEMENTATION-PLAN-2026-08-17`.

### Correction debts — all four discharged, two with corrections

- **`[RCR-4]` → `[REQ]`**: paid; `REQ` cites it in five places. Only `RPD`'s outstanding-list entry
  was stale. Struck. Its *item 1* was withdrawn outright (the `EPUX-07` chain above), and its item 2
  (`PHB`/`EPUX` owe `RPD` banners) is genuinely unpaid and is instance (a)'s mechanism.
- **`GDD_10:508`** — *"Design floor ratified at 1280×720."* **Correcting the handoff**, which calls
  this "a copy-across, not a judgement": it is not. `GDD_07:128-132` records that `1280.0 / 720.0` is
  **still hard-coded on purpose** until the screen conversions land. A bare copy-across would state a
  floor the engine does not implement and read as a defect report against working code. The new text
  carries the deferral clause.
- **`UI-ARCH-02`** — located and bannered. Both halves moved: **three** size classes, not two
  compositions, and the "not a hard-coded device name" qualifier no longer holds.
- **`DRC-1..33` marked OPEN** in `open_questions_inventory:98` — corrected. It was assigned to `S1`,
  which is marked complete and never made it.

---

## Second half — instance (a), then all four owner calls

### `R1` instance (a): `B4-PREP-MAP-DEPLOYMENT` re-derived against `RPD`

Fifteen corrections folded in, and the plan now declares a `Decision source` header — practising
§7.3's recommendation on the one plan being touched.

**The headline is that Slices 2 and 3 are already BUILT, against the design this supersedes.**
`PrepScreen.gd` is 338 lines, `PrepScreen.tscn` exists, `launch_current_node` (`CampaignManager.gd:296`)
routes to it, manual save works. Both the plan and the tracker implied they were outstanding. So the
row is a **migration of working code**, and four concrete conformance gaps fall out:

- `build_plan()` (`:221-227`) assigns tiles by **selection order** — the roster-order inference the
  2026-07-14 plan set out to *replace*, relocated into the screen rather than removed. The ratified
  model is authored numbered start positions, auto-fill in roster order, then **swap**.
- `_on_unit_toggled` (`:200`) is the per-unit deploy toggle; *who* belongs to Manage Roster and
  *where* to Map Preview (`[RPD-6]`, closed by precedence against `EPUX`).
- `_refresh_validation` (`:239-242`) sets `_begin_button.disabled`; `[EPUX-07]`/`[RPD-15]` require
  focusable-but-not-activatable.
- `_validation.text = errors[0]` is one shared reason string where `[RPD-10]` wants a per-entry unmet
  reason through `REQ`.

**The sharpest find is not in prep at all.** `ModalScreen._is_focus_disabled()` (`:327-328`) returns
true for any disabled `BaseButton`, and both `_first_focusable` and `_collect_focusable_controls` use
it to **exclude those controls from focus traversal** — so a gated entry's reason is reachable only by
pointer. That is the inaccessibility `[EPUX-07]` and `[RPD-15]` ruled against, **implemented backwards,
shell-wide across all five availability surfaces.** Spun out as
`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` rather than fixed in prep, because per-adapter drift is
exactly what those rulings exist to prevent.

Both remaining `RPD` debts turned out **already paid** — only the ledger lines were stale — and the
`EPUX` annotation correction got sharper with git evidence: commit `6068e18b` wrote *"neither ever
ruled it"* **into the document containing the ruling**, which was present in the 2026-07-29 revision
200 lines below. So the cause is **document structure** (questions first, rulings ~500 lines later, no
cross-link from a deferral to its resolution), with catalog invisibility as the aggravator. Check
`[41]` cannot catch it: the deferral target *did* rule, somewhere the deferral never names.

### The four owner calls — all answered, three applied

| § | Ruling | State |
|---|---|---|
| 6.2 | Keep `DRC-V1-S05`; close `PREP-V1-S04` | **Applied** |
| 6.1 | Write a standalone prep/economy plan | Tracked, not yet written |
| 6.3 | Localization lands **before** the conversions | **Applied** |
| 6.4 | Investigate and propose | **Resolved and applied** |

**The spine now sorts correctly.** With `PREP-V1-S04` closed and two edges added, `DRC-V1-S09` moves
L7 → L9 (behind the `PREP-V1-S03` that builds the `[EPUX-11]` tray it consumes) and Trade moves
L9 → L10 (behind the `PREP-V1-S05` that builds the `[EPUX-24]` core it commits over). All four shared
primitives are ordered; still acyclic at 12 layers. That is `R1`'s exit condition (e).

**§6.4 was not a choice between the two candidates — neither was the register.** One is a *companion*
correcting `[TEXT-02]`; the other mentions exactly two IDs. The register is a **third** document,
`text_entry_strategy_research_and_questions_2026-07-26.md`, which carries the `[TEXT-nn]` headings and
ratifies each ID. **Which exposes a second `gen_docs_index.py` defect**, distinct from the one `[46]`
catches: `_dominant_register` builds its range from `min..max` of whatever IDs appear, so two scattered
mentions became `TEXT-4..15` — a catalog entry asserting twelve decisions the document does not
contain. `[46]` finds registers that are **hidden**; this one **fabricates** them. Recommended check
left to `R3`, because the fix may be to stop inferring ranges from bodies at all.

### Tooling and housekeeping

- **`track.py update` gained `--depends-on`, `--blockers` and `--phase`** — the handoff's §6 gap, hit
  immediately when three dependency edges needed adding. Validation lives in `apply_update`, so a bad
  edit fails before it is written and pushed; a dependency naming a nonexistent row is the shape worth
  catching, because nothing downstream dereferences it and the row simply **looks unblocked**.
- **`design-previews/` is gitignored**, closing handoff §6's other item. Not deleted: `[RPD-5]` says in
  terms *"preserve the eight-viewport proof set"*, and these three PNGs are that proof set — the
  evidence its own ruling rests on. Where it permanently lives is
  `DESIGN-PREVIEW-EVIDENCE-HOME-2026-08-17`, which records the two competing precedents rather than
  guessing between them.

## Commits

Ownership is in `CLAIMS.tsv`. `d1fcb24d` carries the diff, the three register filings, check `[46]`,
the control-plane registration and the four debt corrections — one logical step, since the filings
are what the diff found and `[46]` is the rule they proved was missing. `4762ab3b` is instance (a).
`97cdad40` applies the owner rulings and files `TEXT`. In the container repo, `2c4b8b7` is the
`track.py` flags and `f8c7b6b` the gitignore.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, 46 checks. Failed twice first, usefully: once on
  active-doc ownership (fixed by registering the diff in the control plane) and once on `[46]`
  finding `PCM`.
- `bash run_tests.sh` — **PASS: all suites green**. Receipt
  `audit/check-receipts/Project_Prometheus-full.json`, tree `01ca950d`, exit 0.
- `python3 AGENT/Docs/gen_docs_index.py` then grepped `REGISTERS.md` for `EPUX`/`TER-1` and
  `INDEX.md` for the new file — per the standing gotcha, the index was checked rather than the PASS
  trusted.
- `python3 coordination/check_tasks.py` — **OK: 432 tasks valid, no conflicts.**

## Next

`R1`'s §8 order is now three-fifths done: §6.2, §6.4 and §4.1 are complete, §6.1 and §6.3 are ruled.
What remains, in order:

1. **Write the prep/economy implementation plan** (`PREP-ECONOMY-IMPLEMENTATION-PLAN-2026-08-17`),
   re-derived against `EPUX`, `TSV`, `CUR`, `SHC`, `DSX` and `RPD`. A session of its own. Until it
   exists `PREP-V1-S01..S08` have no design source and the spine, though now correctly ordered, is
   inferred rather than derived.
2. **§4.3 — re-derive the unified UI programme** against `RPD`, `L10N`, `CEUI`, `DSX` and `CMP`. It
   cites only `UUI` and `UITH`. `L10N` is the sharpest, and §6.3's ruling now sequences it first.
3. **§4.4 — verify instance (d)**: `responsive_ui_redesign_2026-08-06.md` stays with
   `SMALL-SCREEN-UI-REDESIGN`, which owes the one correction. Confirm it landed; do **not** make it.
4. Then `R1` closes and `R2` (UI corpus and album release review) can run.

Unchanged and still queued behind `R1`: Phase 0 — whose `ResponsiveLayout` context-scoping deadline
closes when the v0.8.0 release window opens — `S7`, and blocks C–F of the owner review.

Instance (d) is **not** for this session's successor to edit — `responsive_ui_redesign_2026-08-06.md`
stays with `SMALL-SCREEN-UI-REDESIGN`, which owes the one correction `R1` would have made. Verify it
landed; do not make it.

Unchanged from the handoff and still queued behind this: Phase 0 (with the `ResponsiveLayout`
deadline that closes when the v0.8.0 release window opens), `S7`, and blocks C–F of the owner review.
`R2` is unaffected by anything here and can still follow.
