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

## Commits

Ownership is in `CLAIMS.tsv`. `d1fcb24d` carries the diff, the three register filings, check `[46]`,
the control-plane registration and the four debt corrections — one logical step, since the filings
are what the diff found and `[46]` is the rule they proved was missing.

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

**Run the `R1` walk**, in the order the diff's §8 sets:

1. **§6.2 — the duplicate Trade slice.** Smallest fix, largest avoided cost, unblocks the spine.
   `R1` recommends keeping `DRC-V1-S05` and closing `PREP-V1-S04` as superseded, plus the three
   missing primitive edges. Owner call, because it deletes a row from a scoped epic.
2. **§6.1 — write the prep/economy plan** (or amend the paragraphs in place). Everything in instance
   (e) is provisional until it exists. `R1` recommends writing it.
3. **§4.1 — `B4-PREP-MAP-DEPLOYMENT` against `RPD`.** Self-contained, and a v0.8.0 dependency.
4. **§4.3 — the unified UI programme**, after §6.3 answers.
5. **§6.3 / §6.4** — does localization get a build row before the conversions bake fixed extents
   (`LOCALIZATION-L10N-BUILD-2026-08-17`), and which document is the `TEXT` register (two documents
   claim overlapping ranges; `TEXT-1..3` are catalogued nowhere).

Instance (d) is **not** for this session's successor to edit — `responsive_ui_redesign_2026-08-06.md`
stays with `SMALL-SCREEN-UI-REDESIGN`, which owes the one correction `R1` would have made. Verify it
landed; do not make it.

Unchanged from the handoff and still queued behind this: Phase 0 (with the `ResponsiveLayout`
deadline that closes when the v0.8.0 release window opens), `S7`, and blocks C–F of the owner review.
`R2` is unaffected by anything here and can still follow.
