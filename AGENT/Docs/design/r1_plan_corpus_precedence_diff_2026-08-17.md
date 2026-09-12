---
Role: dated
Type: design
Status: Accepted — precedence diff; the `R1` walk RAN 2026-08-17/18 and its closeout is §9
Last verified: 2026-08-18
Tracker: R1-PLAN-CORPUS-COHESION-REVIEW-2026-08-16
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `R1` — Plan-Corpus Cohesion Review: Precedence Diff Before the Walk

Seventh `DOC-014` check in this series, after
[`skf_drc_precedence_diff_2026-08-13.md`](skf_drc_precedence_diff_2026-08-13.md),
[`drc_group_a_precedence_diff_2026-08-13.md`](drc_group_a_precedence_diff_2026-08-13.md),
[`drc_groups_bcde_precedence_diff_2026-08-13.md`](drc_groups_bcde_precedence_diff_2026-08-13.md),
[`rpd_precedence_diff_2026-08-13.md`](rpd_precedence_diff_2026-08-13.md),
[`nmte_precedence_diff_2026-08-14.md`](nmte_precedence_diff_2026-08-14.md) and
[`ceui_precedence_diff_2026-08-14.md`](ceui_precedence_diff_2026-08-14.md).

This is `R1` of
[`research_and_discussion_sequencing_2026-08-13.md`](../plans/research_and_discussion_sequencing_2026-08-13.md)
§4, and it differs from all six predecessors in direction. Those diffed **one register against the
corpus** before a walk ruled it. This one diffs **the corpus against every register**, because `R1`
re-derives plans rather than ruling questions. Standing rule 1 applies unchanged: the diff is written
before the walk, and it is allowed to change what the walk asks.

---

## Bottom line

**The method the schedule assumes does not work, and the reason is the finding.** A precedence check
driven by *what a plan cites* is structurally blind to the exact failure `R1` exists to catch: a plan
written **before** a register exists cannot cite it, so it scores clean. All three of the highest-value
instances are that shape. `b4_prep_deployment_handoff_2026-07-14.md` cites `CST-5` and `CST-6` and
nothing else; `unified_ui_programme_2026-08-12.md` cites only `UUI` and `UITH`;
`recent_research_implementation_portfolio_review_2026-07-27.md` — the decision source for **21 open
build rows** — cites **no register token at all**. Run mechanically, the citation diff returns 42
documents and misses every one of them.

**Five ratified decision families are not in `REGISTERS.md`,** the catalog an owner walk uses to find
what has been ruled. `EPUX-01..28` (28 rulings, ratified 2026-07-26), `TER-1..10` (2026-08-01) and
`PCM-1..7` (2026-08-01) are absent outright. The cause is mechanical and repeatable: an explicit `Type: design`
header **short-circuits** the register-detection heuristic in `gen_docs_index.py`, so the doc is
dropped from the catalog while every check stays green. This is the same shape as the `Type:` defect
that check `[45]` closed on 2026-08-17 — except the value here is *valid*, merely wrong, so `[45]`
does not fire. `EPUX`'s host document still reads `Status: Draft - owner review` and
`Last verified: 2026-07-25` — a date **before** the walk that ratified it.

**The prep/economy line has no implementation plan.** Instance (b) asks for "the prep/economy plan"
to be re-derived; there is no such document. Eight `PREP-V1` rows derive from eight numbered
paragraphs in §6 of a portfolio review last verified 2026-07-27. This is why instance (e) is hard:
one of the two epics has a re-derived plan and the other has a paragraph.

**Instance (e)'s premise is wrong in the safe direction and its risk is real in another.** "No
ordering between them" is false — there are **nine** cross-epic edges, the graph is acyclic, and it
topologically sorts into 12 clean layers. But it is a **four**-epic graph (`DRC-V1`, `PREP-V1`,
`LIB-V1`, `UIREC-V1`), not two. And the specific harm the plan predicted is present and provable:
of the four shared primitives, **three have their consumer scheduled at or before their producer**,
and `DRC-V1-S05` and `PREP-V1-S04` are **the same slice entered twice** — same title, same dependency
set, both `planned`, in two different epics.

---

## 1. Method, and why the obvious method fails

### 1.1 What was run

Every document under `AGENT/Docs/{plans,design}/` was parsed for `Last verified`, then scanned for
citations of any of the 75 filed registers. A register's ruling date was taken from its `Status` and
`Last verified` headers. A document was flagged when it cites a register whose ruling date is **later
than the document's own `Last verified`**.

That produced **42 documents**. The full table is §2.

### 1.2 The blind spot, stated precisely

The check answers *"did something this plan cites move after the plan was last touched?"* `R1`'s
actual question is *"does a ruling exist that this plan should have absorbed?"* Those differ whenever
the ruling **post-dates the plan's authorship**, because then the plan has no reason to name it and
silence is indistinguishable from currency.

Three verified instances, all of them load-bearing:

| Document | `Last verified` | Registers it cites | Registers that in fact govern it |
|---|---|---|---|
| `plans/b4_prep_deployment_handoff_2026-07-14.md` | 2026-07-14 | `CST-5`, `CST-6` — nothing else | `PHB-1..7`, `RPD-1..18` (ruled 2026-08-13) |
| `plans/unified_ui_programme_2026-08-12.md` | 2026-08-12 | `UUI-1..19`, `UITH-1..8` only | + `RPD`, `L10N` (both 2026-08-13), `CEUI` (08-14), `DSX` (08-15), `CMP` (08-16) |
| `plans/recent_research_implementation_portfolio_review_2026-07-27.md` | 2026-07-27 | **none** | `EPUX`, `TSV`, `CUR`, `SHC`, `DSX`, `RPD`, `L10N` |

All three score **clean** on the citation diff. The third is the decision source for
`PREP-V1-S01..S08`, `LIB-V1-S01..S07` and `UIREC-V1-S01..S06` — 21 open rows.

### 1.3 The declared mechanism exists for 6% of the corpus

Standing rule 4 reads: *"A plan whose `Decision source` moved is re-derived before its build rows are
picked up."* **Six of 109 plan documents carry a `Decision source` line** — the five 2026-07-23
campaign-data-ownership plans and the `DRC` integrated plan. For the other 103 the rule has nothing to
test.

`Last verified` is doing the work instead, and it cannot: it is bumped by *any* edit, including a typo
fix or a status change, so it records **when the file was touched**, not **what it was checked
against**. `unified_ui_programme_2026-08-12.md` is the clean example — its date is honest and its
currency is not.

> **This is the corpus-level finding, and it should be fixed before the next plan is written.**
> A precedence check needs a declared decision source per plan. Recommendation in §7.3.

### 1.4 Consequence for the walk

The walk must be driven by **subject area**, not citation: for each plan gating open build work, ask
which registers govern its subject *regardless of whether it names them*. §4 does this for the five
named instances. The sequencing plan already warned that its enumeration is incomplete — the five are
headed "**Known** instances waiting" against 109 plan documents — and §1.2 shows the enumeration could
not have been complete, because the method that would extend it does not find this class at all.

---

## 2. The mechanical diff — 42 documents

Sorted by `Last verified`, newest first. "Moved" lists cited registers ruled after that date.

### 2.1 Gates open build work — the walk must dispose of these

| Document | `Last verified` | Moved | Open rows |
|---|---|---|---|
| `plans/dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md` | 2026-08-13 | `UBS` | 13 (`DRC-V1-S00..S11`) |
| `plans/doc_role_manifest_2026-06-29.md` | 2026-08-07 | `SHC`, `TSV`, `UBS`, `UUI` | 2 |
| `plans/open_questions_inventory_2026-08-06.md` | 2026-08-06 | `DRC` | 3 |
| `design/responsive_ui_redesign_2026-08-06.md` | 2026-08-06 | `L10N`, `UBS` | 5 |
| `design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md` | 2026-07-25 | `CAU`, `RPD`, `TSV`, `UBS` | 1 |
| `design/campaign_library_ux_decisions_2026-07-24.md` | 2026-07-24 | `CEUI` | 5 |
| `design/shop_transaction_wireframes_2026-08-12.md` | 2026-08-12 | `CUR`, `SHC`, `TSV` | 1 |
| `plans/band4_shop_economy_implementation_plan_2026-06-30.md` | 2026-06-30 | `SHP` | 1 |
| `plans/project_control_plane_2026-06-29.md` | 2026-07-28 | 9 registers incl. `CMP`, `DSX`, `CEUI` | 1 |

Add to this list, from §1.2, the three documents the diff **cannot** flag:
`b4_prep_deployment_handoff_2026-07-14.md`, `unified_ui_programme_2026-08-12.md`,
`recent_research_implementation_portfolio_review_2026-07-27.md`.

### 2.2 Research and diff documents — expected, not defects

Eleven documents are comparative-research packets or precedence diffs whose register moved *because
the walk they preceded ruled it*: `transaction_surface_comparative_research_2026-08-12.md`,
`responsive_prep_deployment_comparative_research_2026-08-12.md`,
`non_modal_text_entry_comparative_research_2026-08-12.md`, `localization_scope_2026-08-12.md`,
`credits_attribution_comparative_research_2026-08-12.md`,
`campaign_editor_ui_comparative_research_2026-08-12.md`,
`skill_status_feedback_research_2026-08-08.md`,
`dialogue_ux_comparative_research_and_questions_2026-08-09.md`, and the four prior precedence diffs.

**Disposition: confirmed unaffected.** A research packet is a record of the state before its walk;
its register moving afterwards is the intended outcome, not drift. They are correctly `Accepted`.

The recurring `UBS:2026-08-15` flag on nine documents is the same artifact — `UBS-1..9` is an
*agenda*, still `ACTIVE`, and its date advances every time a group closes. It is not a ruling that
plans must absorb.

### 2.3 June/July framing documents — one class disposition

Twenty-two documents last verified 2026-06-23 to 2026-07-13 cite registers ruled days or weeks later:
`feature_dependency_atlas_2026-06-23.md` (30 of 33 cited registers moved), `planning_backlog_2026-06-20.md`,
`player_facing_scope_map_2026-06-23.md`, `foundations_end_shapes_2026-06-23.md`,
`candidate_systems_2026-06-23.md`, `items_equipment_unified_model_2026-06-23.md`,
`ai_first_build_design_2026-06-22.md`, `f1_schema_source_inventory_2026-06-28.md` and others.

**Disposition: confirmed unaffected, as a class, with one exception.** These are `Active framing /
driver` and `planning input` documents whose function is to record the question landscape that
*produced* those registers. Re-deriving them would rewrite history rather than correct a plan, and
**none is the decision source for an open row** — verified against the tracker.

The exception is `band4_shop_economy_implementation_plan_2026-06-30.md`, which is an *implementation
plan* and is the decision source for `B4-SHOP-ECONOMY-2026-07-23`. It is listed in §2.1.

> **This class disposition is `R1` exercising the exit condition's "explicitly confirmed unaffected"
> branch.** It is recorded here so the next sweep does not re-derive the finding.

---

## 3. Four ratified registers are missing from the catalog

This was not in `R1`'s brief. It was found while building the register table in §1.1, and it
invalidates part of the schedule's own premises.

### 3.1 What is missing

| Family | Rulings | Ratified | Host document | `Type:` | `Status:` | In `REGISTERS.md`? |
|---|---|---|---|---|---|---|
| `EPUX-01..28` | 27 owner rulings | 2026-07-26 | `design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md` | `design` | **`Draft - owner review`** | **No** |
| `TER-1..10` | ratified in-doc | 2026-08-01 | `design/terrain_authoring_decisions_2026-08-01.md` | `design` | `Ratified — owner decisions 2026-08-01` | **No** |
| `TEXT-1..15` | 15 | 2026-07-26 | `design/text_entry_layout_implementation_research_2026-07-26.md` | `design` | **`Draft - owner review`** | **No** — the catalog lists only `TEXT-4..15`, from a different document |
| `PCM-1..7` | 7 | 2026-08-01 | `design/position_change_model_decisions_2026-08-01.md` | `design` | `Ratified — owner decisions 2026-08-01` | **No** |
| `DLUX-1..16` | 16 | 2026-08-09 | `design/dialogue_ux_comparative_research_and_questions_2026-08-09.md` | `design` | `Accepted` | Yes — it carries an explicit `Register:` header |

`PCM` was **not** found by hand. It was found by check `[46]` (§7.2) on its first run, after `EPUX`
and `TER` had already been filed — which is the argument for the check rather than for a fourth
manual fix.

`EPUX` is the costly one. It is cited **326 times across 22 documents**, it is named in `S1`'s
resolved-corpus list in the sequencing plan, and the `DRC` integrated plan consumes four of its
primitives **by name**. Its own document says it is a draft awaiting owner review, and carries a
`Last verified` date one day *before* the walk that ratified it.

### 3.2 The mechanism, and why nothing caught it

`gen_docs_index.py` selects the catalog with `d.type == "register" or d.register` (line 203). The
`register` field is populated at line 195 as
`declared_register or (register if dtype == "register" else "")`.

The body heuristic `_heuristic_type` — which classifies a document as a register when it contains
three or more bracketed `[XXX-n]` citations — **only runs when `Type:` is absent** (line 173–176).
So an explicit `Type: design` suppresses detection, empties `register`, and drops the document from
`REGISTERS.md`. No check compares the catalog against documents that *look* like registers, so
`check_docs.py` stays green.

The code comments already record `DLUX` hitting this and being fixed by hand:

> *"An EXPLICIT `Register:` header is catalogued whatever the doc's type: rulings sometimes live in a
> `design` doc (DLUX-1..16 did)."*

**A per-document remedy was applied where a rule was needed.** `DoD#2` requires a ratified mechanical
rule to land its check in the same change; the `DLUX` fix landed the remedy without the check, and
`EPUX` and `TER` then went unfound for 22 and 16 days.

### 3.3 What it invalidates

- **Standing rule 3** — *"read the register's status, not the row's"* — cannot be applied to `EPUX`.
  Its status says `Draft`.
- **`S1`'s disposition sweep** ran "against the resolved corpus (… `EPUX` …)". The schedule treats
  `EPUX` as resolved while its document denies it.
- **`RPD`'s outstanding propagation debts** (§5.1) are owed *into* `EPUX` — by a walk that cannot find
  `EPUX` in the catalog it consults.
- **It has already cost a duplicated ruling.** `RPD` recorded that `EPUX` *"never ruled"* disabled-entry
  focusability and ruled it again as `[RPD-15]`; `[EPUX-07]` had ruled it identically eighteen days
  earlier, and the corpus now cites `RPD` as the source. Full chain in §5.1.

### 3.4 Fix

Mechanical and unambiguous; §7.1 applies it. `TEXT` is **not** mechanical — see §6.4.

---

## 4. The five named instances, re-derived

### 4.1 Instance (a) — `B4-PREP-MAP-DEPLOYMENT` against `RPD`

**Confirmed, and worse than stated.** `b4_prep_deployment_handoff_2026-07-14.md` cites `CST-5` and
`CST-6` only. It names **neither `PHB` nor `RPD`** — not the register that governs the prep hub, nor
the one that ruled deployment. The tracker row's `reference` field carries the `RPD` rulings in prose;
the design document it points to does not.

`RPD-1..18` (2026-08-13) rules Map Preview is a canvas, deployment is select-then-select committing on
the second selection with **no confirm step**, the quick card is registry-projected, and the deployment
plan is a staged transaction. The handoff predates all of it by a month.

**Compounding:** `RPD`'s own outstanding list (`responsive_prep_deployment_open_questions_2026-08-12.md:274-276`)
records that *"`PHB` and the `EPUX` prep-hub section owe banners pointing here"* and warns that
*"without banners the next prep packet re-derives `PHB-5`/`PHB-7` a third time."* Those banners are
still unpaid, and one of the two debtors is the register that is invisible in the catalog (§3).

**Disposition: re-derive.** Not confirmable as unaffected.

### 4.2 Instance (b) — there is no prep/economy plan

**The premise is false.** No implementation plan exists for the prep/economy line. What exists:

- `design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md` — the `EPUX` register
  (mis-filed, §3), holding 28 rulings.
- §6 of `plans/recent_research_implementation_portfolio_review_2026-07-27.md` — eight numbered
  paragraphs, `Last verified: 2026-07-27`, which map one-to-one onto `PREP-V1-S01..S08`.

There is nothing between the rulings and the eight tracker rows. The `DRC` line, by contrast, has a
1000-line integrated plan that was re-derived against its register on 2026-08-13.

The eight paragraphs are **not** current. §6 item 1 specifies "top-level Prep with Explore, Manage
Roster, **Map Preview**, and authored advance actions" — `RPD-1..18` has since ruled what Map Preview
*is*. Item 5 specifies "owner-ref wallets" — `CUR-1..7` (2026-08-13) has since ruled multi-currency.
Items 4, 5 and 7 all invoke selection flows that `[DSX-S9]` (2026-08-15) has since ruled into a single
dependent-choice layer. None of it is cited, because the document cites nothing.

**Disposition: this is authoring, not re-derivation, and it is the largest single item `R1` uncovers.**
Scoping question for the owner in §6.1.

### 4.3 Instance (c) — the unified UI programme against `RPD`, `L10N`, `UUI`

**Confirmed.** `unified_ui_programme_2026-08-12.md` (`Last verified: 2026-08-12`) cites `UUI-1..19` and
`UITH-1..8` and nothing else. Five registers governing screens it sequences have been ruled since:
`RPD` and `L10N` (2026-08-13), `CEUI` (08-14), `DSX` (08-15), `CMP` (08-16).

`L10N` is the sharpest: `[L10N]`'s 1.4× text-extent allowance and declared-direction requirement bind
**every responsive component**, and the programme sequences eight workstreams of responsive components
without naming it.

**Boundary, and it holds.** The programme is a *plan*; `unified_ui_decisions_2026-08-12.md` is its
*register*. `R1` re-derives the plan. It was deliberately not given the register — under `DOC-014` a
ratified register is amended only through its owning row, naming the decision, quoting what it ruled,
and stating the reason that outranks it. Nothing found here requires amending `UUI` itself.

**Disposition: re-derive the plan. The register is untouched.**

### 4.4 Instance (d) — the responsive redesign against `L10N`

**Confirmed by the mechanical diff** (`design/responsive_ui_redesign_2026-08-06.md`, `L10N:2026-08-13`)
— this instance is the one case where the citation method works, because the redesign does name
`L10N`.

Note the claim is held by `SMALL-SCREEN-UI-REDESIGN-2026-08-05`, which owes and will make the one
correction `R1` would have made. `R1` does not edit it. Verify at the walk that the correction landed;
do not make it here.

**Disposition: confirm at the walk, do not edit.**

### 4.5 Instance (e) — the merged build order

#### The premise, corrected

*"Two open epics … with no ordering between them"* is **false**, and it is **four** epics, not two.

Nine cross-epic dependency edges already exist:

```
DRC-V1-S05  <- PREP-V1-S03        PREP-V1-S04 <- DRC-V1-S04
DRC-V1-S07  <- UIREC-V1-S05       PREP-V1-S08 <- DRC-V1-S10
DRC-V1-S10  <- PREP-V1-S06        UIREC-V1-S06 <- LIB-V1-S02
LIB-V1-S01  <- UIREC-V1-S02       PREP-V1-S02 <- UIREC-V1-S05
LIB-V1-S02  <- UIREC-V1-S05
```

The graph over all 33 slices plus their 15 external dependencies is **acyclic** and sorts into 12
layers. `LIB-V1` and `UIREC-V1` are entangled with both named epics — `PREP-V1-S02` and `DRC-V1-S07`
both wait on `UIREC-V1-S05`, and `UIREC-V1-S06` waits on `LIB-V1-S02`. Any spine that orders only two
of the four is wrong.

#### The risk, confirmed

The plan's warning was *"Do this here or the first Trade slice builds `[EPUX-24]`'s core a second
time."* That is not hypothetical. Of the four shared primitives the `DRC` plan consumes by name — and
which its own §"Decision-source gate" states are **"owned by the prep/economy line"** — only one has a
correct producer→consumer edge:

| Primitive | Built by | Consumed by | Edge? | Layers |
|---|---|---|---|---|
| `[EPUX-24]` transaction core | `PREP-V1-S05` | `DRC-V1-S05` (Trade) | **No** | both L9 |
| `[EPUX-21]` quantity primitive | `PREP-V1-S05` | `DRC-V1-S05` (Trade) | **No** | both L9 |
| `[EPUX-11]` pending-items tray | `PREP-V1-S03` | `DRC-V1-S09` (map-end overflow) | **No** | consumer **L7**, producer **L8** |
| `[EPUX-06]` activity snapshot | `PREP-V1-S06` | `DRC-V1-S10` (Explore/Prison) | Yes | L10 → L11 |

`[EPUX-11]` is the concrete one: the consumer is scheduled **a full layer before its producer**.
`[EPUX-24]`/`[EPUX-21]` are the predicted one: Trade sits in the same layer as the slice that builds
the core it commits over, with nothing ordering them.

#### The duplicate

| | `DRC-V1-S05` | `PREP-V1-S04` |
|---|---|---|
| Title | Dialogue/custody Slice 5: **Trade and designated-provider Convoy** | Prep/economy Slice 4: on-map **Trade and designated-provider Convoy** |
| Dependencies | `DRC-V1-S04`, `PREP-V1-S03` | `PREP-V1-S03`, `DRC-V1-S04` |
| Status | `planned` | `planned` |

**Same scope, identical dependency set, two epics, both open.** The portfolio review's §6 item 4 says
Trade is delivered "through the DRC integrated plan", so the intent was `DRC-V1-S05` — but
`PREP-V1-S04` was registered anyway and nothing records that it is the same work.

**Disposition: this is the instance to run first.** It is the only one whose fix is a small set of
tracker edits rather than a document rewrite, and it is the one that costs a rebuild if missed.
Proposal in §6.2 — it needs an owner call on which row survives.

---

## 5. The four correction debts

### 5.1 `[RCR-4]` → `[REQ]` banner — **paid, but the ledger is stale**

The watchlist says the debt was paid 2026-08-13 and asks whether another register carries the same
one. Verified: `REQ`'s register cites `[RCR-4]` at five places including the foundation-F16 consumer
list, so **`REQ`'s side is paid**.

What is stale is the *record*: `responsive_prep_deployment_open_questions_2026-08-12.md:276` still
lists *"`[RCR-4]` still owes `[REQ]` a banner"* as outstanding. Correct that line.

**The other two items on that list are new findings, and the first is not what it says it is.**

1. `:270-272` claims *"`[EPUX-02]` and `[EPUX-04]` need the `[RPD-15]` write-back. Both currently
   defer focusability to `EPUX-06/07`, **which never ruled it**."*

   **That is false, and the consequence is a ruling made twice.** `[EPUX-07]` ruled it on
   **2026-07-26** — *"disabled entries are focusable, not activatable … Settles the question deferred
   from `EPUX-02` and `EPUX-04`"* (`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md:386-390`,
   restated at `:1067-1069`). That is **eighteen days before `RPD` was authored**, and it is the same
   rule `[RPD-15]` then ruled independently on 2026-08-13.

   The corpus has since adopted the **second** one as the source: `campaign_editor_ui_open_questions_2026-08-12.md:1093`
   cites *"`[RPD-15]`'s **focusable but not activatable**"* — attributing to `RPD` a rule `EPUX`
   ruled first.

   **Cause — sharper than catalog invisibility, and confirmed by history.** The `RPD` walk did not
   merely fail to *find* `EPUX`; it **edited the very document containing the ruling**. Commit
   `6068e18b` ("Propagate the `RPD` rulings back into `EPUX` and `PHB`", 2026-08-13) wrote *"neither
   ever ruled it"* into `EPUX-02` and `EPUX-04` — while the 2026-07-26 owner ruling sat ~200 lines
   below in the same file, present since the 2026-07-29 revision (`55ef43ff`).

   So the mechanism is **document structure**, with catalog invisibility as the aggravator: `EPUX`
   puts its *questions* first and its *rulings* ~500 lines later, with no cross-link from a deferral
   to its resolution. A reader who lands on `EPUX-02`'s question paragraph sees "deferred to
   `EPUX-06/07`" and has nothing telling them to scroll. Being absent from `REGISTERS.md` removed the
   other route in — a catalog entry reading `RESOLVED` would have contradicted the paragraph.

   **Both annotations are corrected as of 2026-08-17**, and the deferral paragraphs now point at
   `[EPUX-07]` directly. *"A ruling that resolves a deferral must be linked from the deferral"* is a
   candidate rule for `R3`, and it is mechanically checkable — `check_docs.py` already has
   `check_dangling_deferral_targets` (`[41]`), which looks for deferrals whose target never ruled;
   it did not fire here because the target *did* rule, in a place the deferral never names.

   **This is an `R3` candidate found by `R1`**, with its duplicate already identified: the shape `R3`
   looks for is "repeated mechanisms that should be one", and here the same rule exists twice under
   two IDs. Do not silently drop either — `[RPD-15]` is cited downstream. Record the precedence.

2. `:273-275` — *"`PHB` and the `EPUX` prep-hub section owe banners pointing here."* Genuinely unpaid,
   and it is instance (a)'s mechanism (§4.1).

Both are blocked behind §3: they are propagation *into* a register that no walk can find. Item 1
shows the cost is not theoretical — it has already been paid once.

### 5.2 `GDD_10`'s retired viewport floor — **confirmed, and it is not a copy-across**

`AGENT/GDD/GDD_10_Roadmap.md:508` still reads *"Design floor ratified at 1280×720."* The ratified
floor is **360×640** (`unified_ui_decisions_2026-08-12.md:36`,
`responsive_ui_redesign_2026-08-06.md:137`).

**Correcting the handoff:** it calls this *"a copy-across, not a judgement."* It is not, quite.
`GDD_07_UI_UX.md:128-132` records that `1280.0 / 720.0` is **still hard-coded** in
`fit_content_scale_factor_for_size` and is *"deliberately **not** flipped yet: doing so before the
screen conversions would make portrait large and broken instead of small and unclipped."* A bare
copy-across would state a floor the engine does not implement and read as a defect report against
working code. The corrected text must carry the deliberate-deferral clause.

### 5.3 `ui_ux_architecture_research_and_questions_2026-07-24` — **confirmed, and located**

The superseded position is `UI-ARCH-02` (`:236-249`): *"one presentation controller/state model with
**two** small layout compositions selected by available content width"*, with the threshold left as
*"a measured content-width rule … not a hard-coded device name."*

Superseded by the size-class model: **three** classes (Compact `< 600`, Medium, Expanded `≥ 1024`)
against a 360×640 floor, with named classes and fixed width breakpoints. Both halves of `UI-ARCH-02`
moved — the count and the "not a named class" qualifier.

### 5.4 `L10N-1..18` resolved with no build row — **confirmed**

`LOCALIZATION-I18N-SCOPE-2026-08-12` is `completed`; per standing rule 3 that means the *research*
finished. `L10N-1..18` is `RESOLVED` (2026-08-13). No implementation row exists anywhere in the
tracker — verified across all 430 rows.

This is not only a missing row. `[L10N]`'s 1.4× text extent and declared-direction requirement bind
every responsive component (§4.3), so the responsive conversions will either implement it without a
row or bake in a violation. **Owner call in §6.3.**

---

## 6. What the walk must ask

> **ALL FOUR ANSWERED BY THE OWNER, 2026-08-17.** Each ruling is recorded under its section.
> §6.2 and §6.3 are **applied**; §6.4 is **resolved and applied**; §6.1 is ruled and is now
> `PREP-ECONOMY-IMPLEMENTATION-PLAN-2026-08-17`.

### 6.1 The prep/economy plan — write it, or promote the paragraphs?

Instance (b) has no document to re-derive (§4.2). Two routes:

- **Write a prep/economy integrated plan**, as the `DRC` line has, re-derived against `EPUX`, `TSV`,
  `CUR`, `SHC`, `DSX` and `RPD`. This is a session of its own, and it is what makes instance (e)'s
  spine reliable rather than inferred.
- **Amend §6 of the portfolio review in place** — cheaper, but leaves the decision source for 21 open
  rows inside a document whose other six sections cover unrelated systems.

**Recommendation: write the plan.** The eight paragraphs are three weeks behind four registers, the
line owns all four shared primitives, and §4.5 shows the cost of leaving their assignment implicit.

> **OWNER RULING 2026-08-17: write the standalone plan.** Tracked as
> `PREP-ECONOMY-IMPLEMENTATION-PLAN-2026-08-17`, re-derived against `EPUX`, `TSV`, `CUR`, `SHC`,
> `DSX` and `RPD`. Until it exists, `PREP-V1-S01..S08` have no design source and the merged spine
> in §4.5 is inferred rather than derived.

### 6.2 The duplicate Trade slice — which row survives?

`DRC-V1-S05` and `PREP-V1-S04` are the same work (§4.5). The portfolio review's own text delivers
Trade "through the DRC integrated plan", which argues for keeping `DRC-V1-S05` and closing
`PREP-V1-S04` as superseded. But `PREP-V1-S08` depends on `DRC-V1-S10` rather than on `PREP-V1-S04`,
so nothing downstream breaks either way.

**Recommendation: keep `DRC-V1-S05`, close `PREP-V1-S04` as superseded by it,** and add the three
missing primitive edges (§4.5). Owner call because it deletes a row from a scoped epic.

> **OWNER RULING 2026-08-17: keep `DRC-V1-S05`. APPLIED.** `PREP-V1-S04` is closed (recorded
> `completed` + phase `done`, since the vocabulary has no `superseded`) with the reason on the row.
> Nothing depended on it. Both missing edges added: `DRC-V1-S05 → PREP-V1-S05` (the `[EPUX-24]`
> core and `[EPUX-21]` quantity primitive it commits over) and `DRC-V1-S09 → PREP-V1-S03` (the
> `[EPUX-11]` pending-items tray). **The spine re-sorts correctly:** `DRC-V1-S09` moves L7 → L9,
> now behind its producer at L8; Trade moves L9 → L10, now behind the core at L9. Still acyclic,
> 12 layers. `[EPUX-06]`'s edge was already right, so all four primitives are now ordered.

### 6.3 Does localization get a build row, and when?

`L10N-1..18` is ruled and unbuilt (§5.4). The question is not *whether* — the register settled that —
but whether the row lands **before** the responsive conversions bake fixed extents, which is what its
own research row was created to prevent.

> **OWNER RULING 2026-08-17: before the conversions. APPLIED.**
> `LOCALIZATION-L10N-BUILD-2026-08-17` is now a dependency of
> `V080-RESPONSIVE-SCREEN-CONVERSIONS-2026-08-11`. The interaction is live, not theoretical:
> `[RPD-12]` already reasons about the 1.4× allowance against a Compact row budget `[UUI]`
> recorded as *"optimistic by half a row"* **before** 1.4× was applied.

### 6.4 `TEXT-01..15` — RESOLVED 2026-08-17, and neither candidate was the register

**Asked, investigated, answered.** The register is a **third** document:
`design/text_entry_strategy_research_and_questions_2026-07-26.md`. It carries the `### [TEXT-nn]`
question headings and a *Decision status* section ratifying each ID — *"The walk ran 2026-07-26 and
is **COMPLETE — TEXT-01..TEXT-15 are all ratified**, across this packet and its two companions."*
Filed as `Register: TEXT-01..15`.

Neither candidate was:

- `text_entry_layout_implementation_research_2026-07-26.md` is titled *"Keyboard Layouts —
  Implementation Research and **a Correction to `[TEXT-02]`**"*. It is a **companion** that corrects
  one decision and carries the `[TEXT-03]` revision, not the register. Same for
  `text_entry_naming_and_sanitization_2026-07-26.md`.
- `text_entry_mobile_compact_2026-08-06.md` mentions exactly **two** IDs, `TEXT-04` and `TEXT-15`.

**Which exposes a second `gen_docs_index.py` defect, distinct from §3.2.** `_dominant_register`
builds its range as `f"{prefix}-{min(nums)}..{max(nums)}"` over whatever IDs appear in the body. Two
scattered mentions therefore became **`TEXT-4..15`** — a catalog entry asserting twelve decisions the
document does not contain, pointing readers at the wrong file, and dropping the zero-padding the IDs
actually use. §3.2 hides a real register; this **fabricates** one.

**Recommended check** (not built here — it belongs with §7.3's header work in `R3`): a catalogued
range must be *dense*, i.e. a document claiming `X-a..b` should contain most IDs in `[a, b]`. Two of
twelve would fail. Left for `R3` because the threshold is a judgement call and the fix may be to stop
inferring ranges from bodies at all.

---

## 7. What `R1` fixes without asking

### 7.1 File the missing registers

Set `Type: register` and an explicit `Register:` header on the `EPUX` and `TER` host documents, and
correct `EPUX`'s status from `Draft - owner review` to its ratified state with the 2026-07-26 date.
Regenerate `INDEX.md` and `REGISTERS.md`. This changes no ruling — it makes 38 existing rulings
findable.

### 7.2 Add the check that `DoD#2` owed

`check_docs.py` gains a check: a document containing three or more bracketed `[XXX-n]` citations of a
single family, where that family appears in no catalogued register, **fails** by name. That is the
`DLUX` remedy generalized into the rule it should have been (§3.2).

### 7.3 Give plans a declarable decision source

§1.3 — the standing rule the schedule relies on is testable for 6 of 109 plans. Recommend a
`Decision source:` header on implementation plans, and a check that a plan gating open build rows
declares one. **Flagged, not built here:** it changes the header contract for the whole corpus, which
is `R3`'s remit rather than a side effect of `R1`.

### 7.4 Pay the correction debts

§5.1's stale line in `RPD`, §5.2's `GDD_10` text with its deferral clause, and §5.3's `UI-ARCH-02`
supersession banner.

---

## 8. Order for the walk

1. **§6.2 — the duplicate Trade slice.** Smallest fix, largest avoided cost, and it unblocks the spine.
2. **§6.1 — the prep/economy plan.** Everything in instance (e) is provisional until this exists.
3. **§4.1 — `B4-PREP-MAP-DEPLOYMENT` against `RPD`.** Self-contained, and it is a v0.8.0 dependency.
4. **§4.3 — the unified UI programme.** Broadest, and it wants `L10N`'s answer from §6.3 first.
5. **§6.3, §6.4** — the two remaining owner calls.

`R2` (UI corpus and album release review) is unaffected by anything here and can still follow.

---

## 9. Walk closeout — 2026-08-18

The walk ran across three sessions: §6.2/§6.4/§4.1 and the owner calls on 2026-08-17, §6.1 (the
prep/economy plan) the same night, and §4.3/§4.4 plus this closeout on 2026-08-18.

### 9.1 The five named instances

| Instance | Disposition | Where |
|---|---|---|
| (a) `B4-PREP-MAP-DEPLOYMENT` vs `RPD` | **Re-derived** 2026-08-17, 15 corrections; scope widened 2026-08-18 to build the `[DSX-S4..S9]` layer | [`b4_prep_deployment_handoff_2026-07-14.md`](../plans/b4_prep_deployment_handoff_2026-07-14.md) |
| (b) the prep/economy plan | **Authored** 2026-08-17 — the premise was false, there was no plan to re-derive | [`prep_economy_implementation_plan.md`](../plans/prep_economy_implementation_plan.md) |
| (c) the unified UI programme | **Re-derived** 2026-08-18, 16 corrections; three ordering changes and two stale gates | [`unified_ui_programme_2026-08-12.md`](../plans/unified_ui_programme_2026-08-12.md) |
| (d) the responsive redesign vs `L10N` | **Confirmed, not edited.** The owed `~1.3×` → **1.4×** correction *has landed* (lines 212–219), with the declared-direction clause beside it. Its **other** owed edit — the Compact row budget, 4.3 vs 3.9 — has **not**, and stays with `SMALL-SCREEN-UI-REDESIGN-2026-08-05` | §4.4 |
| (e) the merged build order | **Fixed** 2026-08-17: duplicate closed, two edges added, all shared primitives producer-before-consumer, acyclic at 12 layers | §4.5 |

### 9.2 §2.1's nine documents — dispositions

| Document | Disposition |
|---|---|
| `dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md` | **Confirmed unaffected.** Re-derived 2026-08-13 against the RESOLVED `DRC-1..33`; the only later flag is `UBS`, which §2.2 rules an agenda artifact. Its Trade slice acquired `[DSX-S9]` through the tracker edge added 2026-08-17, not through the plan text. |
| The doc role manifest (deleted 2026-08-23) | **Corrected.** `UUI-1..17` → `UUI-1..19`; the UI-programme row now records the re-derivation and the narrowed boundary. |
| `open_questions_inventory_2026-08-06.md` | **Confirmed superseded in substance, dated not rewritten.** Banner records what closed in each section; re-deriving a snapshot rewrites history. |
| `responsive_ui_redesign_2026-08-06.md` | Instance (d) — see above. |
| `prep_economy_bundle_comparative_research_and_questions_2026-07-25.md` | **Out of scope as a plan.** It is the `EPUX-1..28` register, re-filed by `R1` on 2026-08-17; a register is amended through its owning row under `DOC-014`, not by a plan-corpus review. |
| `campaign_library_ux_decisions_2026-07-24.md` | **Body current, header stale.** `[CEUI-S2]`'s amendment is present in place (Branch K's resolution axis superseded, input-mode axis and declutter row surviving). The front-matter `Status` still reads *"Branches A–I resolved with the owner; J–K pending"* while its own §K records K resolved 2026-07-25. Reported to `DISCUSS-CAMPAIGN-LIBRARY-UX-2026-07-23`, which claims the file. |
| `shop_transaction_wireframes_2026-08-12.md` | **Confirmed current.** Its `Status` already carries `[DSX-S25]`'s 2026-08-15 acceptance as the family skeleton. |
| `band4_shop_economy_implementation_plan_2026-06-30.md` | **Superseded in substance — and it is a new owner call.** See §9.3. |
| `project_control_plane_2026-06-29.md` | **Confirmed current by construction.** It is the registration index; every document this walk produced was registered in it as it landed. |

### 9.3 The new owner call — the Band-4 ↔ `PREP-V1` boundary

**This is instance (e)'s defect a second time, in a place §4.5 did not look**, because §4.5 checked
the four `EPUX` primitives across the epic graph and this pair is not connected to it at all.

`B4-SHOP-ECONOMY-2026-07-23` and `PREP-V1-S05` both build the shop, from two plans seven weeks
apart, **with no dependency edge in either direction**:

| `band4_shop_economy_implementation_plan_2026-06-30.md` (`Last verified: 2026-06-30`) | Ratified since |
|---|---|
| §Scope 5 — "a rough keyboard+mouse-first `B3-PHB` shop panel using the shared selector/detail-pane abstraction" | The panel is an **adapter on the distribution shell** (`[DSX-S1..S3]`, `PREP-V1-S02`), with the `SHC-1..8` chrome and a landscape predicate |
| §Non-Goals — "**Stock is author-defined and infinite**; do not build limited stock/restocking" | `PREP-V1-S05` builds **stock as a first-class named entity with cadence-driven restock** |
| §Scope 2 — quoting and committing **through `ResourceLedger`** | `ResourceLedger` is a **wallet, not the transaction core** `[TSV-3]` needs; the prep/economy plan **deletes `ResourceLedger.reserve()`** |
| §Decisions Not To Reopen — "V1 populates **gold only**" | `CUR-1..7` — multi-currency, header button, holdings popup |
| §Scope 3 — dynamic pricing over the shopper subject | Survives, refined by `[EPUX-17]`'s final-price-in-list / formula-in-detail split |
| §Scope 7 — on-map shop trigger through `B4-MAP-OBJECTS` | Survives, and is **the part `PREP-V1-S05` does not build** — `[DSX-S16]`/`[DSX-S17]` make it the same adapter with a context-declared verb set |

`B4-CONVOY-2026-07-23` is the same shape but less dangerous: `PREP-V1-S03` **does** depend on it, so
there is an order — but its plan's §Scope 5–6 ("a rough `B3-PHB` convoy panel", "the shared thin
selector/detail-pane abstraction that the shop plan also consumes") describe the distribution shell
that `[DSX-S1]` has since ruled and homed elsewhere, so the two rows' boundary is undrawn rather
than absent.

**The call:** what survives in each Band-4 row, and does its 2026-06-30 plan get a superseded
banner? **`R1`'s recommendation** — the Band-4 rows keep the **service and data** layer they
already own (convoy store, `ConvoyService`, price/stock schema, the on-map trigger), the panel and
selector items are **struck** from both plans because `[DSX-S1]` homes that shell at
`PREP-V1-S02`, and each 2026-06-30 plan gets the same superseded-in-part banner the portfolio
review's §6 received.

#### Ruled and applied, 2026-08-18

**Owner approved the recommendation and added one clause: the restocking store is the eventual
goal.** That is stronger than a preference, and checking it changed the disposition of the
schema.

**`[EPUX-16]` had already ruled it, and the Band-4 plan predates the ruling.** Option **C, pulled
forward and generalized** (owner, 2026-07-25): because `[EPUX-01]`'s revisitable overworld nodes
require a defined second-visit behaviour, *"shop nodes persist stock and restock on an
author-defined cadence, defaulting to infinite/non-scarce so simple campaigns stay simple."*
**Infinite is the default value of an author-set quantity, not a shipping stage.** The 2026-06-30
plan said the opposite twice — *"do not build limited stock/restocking quantities in the first v1
shop pass"* and *"do not add saved shop stock unless persistent stock/restock is pulled into
scope"* — and its `ShopStockEntry` has **no quantity field at all**. That is the concrete way to
fail the owner's clause: not by deciding against restocking, but by shipping a schema with nowhere
to put a count, which turns the end state into a retrofit. Both non-goals are retired, the field
is added as **schema** (default `unlimited` sentinel, plus a restock cadence reference), and the
two `F1 obligations: no saved stock state` lines are corrected.

**One thing the recommendation got wrong, caught while wiring the edges.** It said the Band-4 rows
keep *"the on-map trigger"*. Keeping the whole of it would have created a **cycle**: the on-map
*presentation* is a distribution-surface adapter (`[DSX-S16]`/`[DSX-S17]` — canvas region only,
context-declared verb set), so it needs the shell `PREP-V1-S05` builds, while `PREP-V1-S05` needs
the price and stock data `B4-SHOP-ECONOMY` supplies. Split instead: the **`shop` tile-action
declaration** stays in Band 4; the **presentation** goes to `PREP-V1-S06`, which already builds
map placement as a general property of *any* Explore activity — so the shop was never the right
owner of it.

The seam that makes this clean is that **cadence is one trigger engine built at `PREP-V1-S01`,
with stock as one subscriber of four**. Schema in Band 4, entity and behaviour in `PREP-V1-S05`,
engine underneath both.

**Applied:** both plans carry superseded-in-part banners with a moves-out table; `PREP-V1-S05`
gains `B4-SHOP-ECONOMY-2026-07-23` as a dependency. **Verified over the whole 435-row graph
after the edit — acyclic, and every producer-before-consumer edge holds:** `B4-SHOP-ECONOMY`
sorts twelve layers ahead of `PREP-V1-S05`, and `PREP-V1-S01`'s cadence engine ahead of the stock
entity that subscribes to it.

### 9.4 The `gen_docs_index.py` fabrication defect, reproduced live

§6.4 recorded that `_dominant_register` builds a range from `min..max` of the IDs in a body and
recommended the fix to `R3`. Re-deriving the unified UI programme **triggered it**: the new `[RPD-n]`
citations crossed the heuristic's three-mention threshold, `_heuristic_type` typed the *plan* as a
register, and `REGISTERS.md` gained a fabricated **`RPD-1..8`** row pointing at a document that
makes no `RPD` rulings — a second, wrong entry for a family already catalogued correctly.

Stopped at the document by giving it a `Type: plan` fence. **The general fix belongs to `R3` and is
now narrower than "stop inferring ranges":** `_heuristic_type` should never infer `register` for a
document under `plans/`, because citing registers is what a plan does. Note the cost profile —
`[46]` catches a register that is *hidden*, which is silent; this one is *loud* and still went
unnoticed until a re-derivation happened to cross a threshold.

**It fired a second time in the same session, and that instance is older than this walk.** Dating
`open_questions_inventory_2026-08-06.md` (§9.2) added `[UUI-n]` citations and produced a fabricated
`UUI-1..15` row — for a family already catalogued correctly at `UUI-1..19`. But that document was
**already** in `REGISTERS.md` before this walk touched it, as a register with an em-dash range,
because `_heuristic_type` matches the substring `open_questions` **in the filename**. An *inventory
of* open questions is not a register of decisions. Both the fabricated row and the original wrong
row are gone now that the file declares `Type: plan`.

So the defect has three live instances, all found by one re-derivation: the filename match, the
three-mention threshold, and the `min..max` range. The common cause is that **type and register are
inferred from a document's surface when the document does not declare them** — which argues for
`R3` making the declaration mandatory for anything under `plans/` rather than improving the
guesswork.

### 9.5 `R1`'s exit condition

> *Every plan whose decision source moved is either re-derived or explicitly confirmed unaffected,
> and the two build epics have one dependency-ordered spine.*

**Met.** Three plans re-derived, one authored, one confirmed-not-edited, thirty-three confirmed
unaffected as classes (§2.2, §2.3) and nine dispositioned individually (§9.2). The spine sorts
producer-before-consumer across four epics, acyclic, 12 layers. One item is carried forward rather
than closed — the §9.3 owner call — and it is a tracker row, not a note in a plan.
