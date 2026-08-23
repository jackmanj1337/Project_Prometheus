---
Role: dated
Type: plan
Status: Active — Stage C and the R1 review are complete; next prerequisite is the B3-REQ/F16 build before the cadence session
Last verified: 2026-08-19
Tracker: RESEARCH-SEQUENCING-2026-08-13-2026-08-13
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Research and Discussion Sequencing — 2026-08-13

A single ordered spine for everything still undecided: the four `OPEN` registers, the written and
unwritten question packets, and the twenty planning/discussion rows nobody has scheduled. It
supersedes the scheduling half of
[`open_questions_inventory_2026-08-06.md`](open_questions_inventory_2026-08-06.md), which predates
the eight owner walks of 2026-08-12/13, and re-times the
[`unbuilt_screen_research_agenda`](../registers/unbuilt_screen_research_agenda_2026-08-12.md)'s
recommended order against what those walks actually delivered.

---

## 1. The finding that reorders everything

**The queue that governs this work is substantially overtaken, and the overtaking is invisible from
inside it.** The unbuilt-screen agenda was authored 2026-08-12 and lists four cross-cutting questions
to answer "once, before any group". Three of the four were answered the next day, by packets walked
under a different name:

| Agenda item | State on 2026-08-13 | Discharged by |
|---|---|---|
| `[UBS-1]` engine-action feedback vocabulary | **Discharged** | `CFB-1..18` RESOLVED, `SKF-1..12` closed, `CAU-1..10` RESOLVED |
| `[UBS-2]` the transaction surface | **Discharged** | `TSV-1..24` RESOLVED (+ `SHC-1..8`, `CUR-1..7`) |
| `[UBS-3]` non-modal text entry | **Discharged 2026-08-14** | `S4` ruled it editor-only; residue folded into `CEUI` |
| `[UBS-4]` dialogue vs the control region | **Discharged** | Ruled at all three size classes in the `DRC` walks |
| `[UBS-5]` dialogue presentation | **Discharged** | `DLUX-1..16` ratified; `DRC-1..18` dialogue half |
| `[UBS-9]` in-game credits | **Design discharged** | `CRD-1..10` RESOLVED — the *build* is still an RC blocker |

All nine `UBS` items are now design-complete. The three sessions that survived this plan's first
disposition — `UBS-6` convoy/shop, `UBS-7` compendium and `UBS-8` campaign editor — were walked and
their albums approved by 2026-08-16. The stale state below is retained only where it explains why
the sessions were ordered as they were.

**The same drift is very likely present in the twenty unscheduled discussion rows, and at larger
scale.** `DISCUSS-COMBAT-ACTIONS-UX` has `CAU-1..10` resolved against it; `DISCUSS-SKILL-STATUS-
FEEDBACK` has `SKF-1..12`; `DISCUSS-DIALOGUE-UX` is already `completed`;
`DESIGN-PREP-HUB-STRUCTURE` was ratified in June as `PHB-1..7` and again in July under `EPUX`;
`DESIGN-ACTIVITY-EXIT-ROLLBACK` is `EPUX-06`/`EPUX-28`'s exit receipt; `ENGINE-PREDICATE-UNMET-REASON`
is `EPUX-07`'s unified reason contract delivered through `[DRC-11]`'s fifth surface; the cloud-sync
investigations were largely answered by the 2026-07-25 backup decisions. None of those rows record
any of it.

**So the first action is a disposition sweep, not a walk.** Ordering sessions that are already
answered would spend the entire schedule re-deriving ratified text — which is precisely the failure
`RPD-18` demonstrated when it re-derived `PHB-7` correctly, from scratch, without knowing `PHB-7`
existed.

---

## 2. The open surface, classified

### 2.1 Registers marked `OPEN`

| Register | Real state |
|---|---|
| `NMTE-1..20` | **Walked 2026-08-14 (`S4`) and re-scoped to the editor.** Six questions closed, three narrowed, twelve moved into the `CEUI` walk. Gates nothing outside `UBS-8`. |
| `CEUI-1..40` | Authored, unwalked — **and now the owner of the twelve surviving `NMTE` questions.** Search is answered here, not inherited. |
| `UBS-1..9` | An agenda, not a question set. Five items discharged (§1); needs re-issuing, not walking. |
| `MRD-1..8` | `MRD-1..7` answered. `MRD-8` alone is live and **blocked** on `PER-PERCEPTION-MASKING-2026-07-20`, a system that does not exist. Park it. |

### 2.2 Packets not yet authored

| Packet | Blocked on | Authorable |
|---|---|---|
| Convoy/shop (`UBS-6`) | `TSV` — **resolved** | **DONE 2026-08-18.** `DSX-1..29` had already widened and answered the shell half; the `CVS-1..10` residue walk finished capacity, stock and restock semantics. Album approved 2026-08-16. |
| Compendium (`UBS-7`) | ~~`NMTE`~~ — **nothing** | **DONE 2026-08-15.** `CMP-1..22` resolved; album approved 2026-08-16. |
| `CEUI` search residue | ~~`NMTE`~~ — **nothing** | **Now**, as part of the `CEUI` walk itself (`S11`). |

### 2.3 Discussion rows never scheduled — 20, pending disposition

Suspected-discharged, to be confirmed row by row in Session 1: `DISCUSS-COMBAT-ACTIONS-UX`,
`DISCUSS-SKILL-STATUS-FEEDBACK`, `DESIGN-PREP-HUB-STRUCTURE`, `DESIGN-ACTIVITY-EXIT-ROLLBACK`,
`ENGINE-PREDICATE-UNMET-REASON`, `ENGINE-ITEM-HELD-PREDICATE`, `INVESTIGATE-CLOUD-SYNC-THIRD-PARTY`,
`INVESTIGATE-FIRST-PARTY-SYNC-SERVER`, `DISCUSS-PVP-MODE-UX` (design resolved as `PVP-1..8`; only
build sequencing remains).

Probably genuinely live: `DISCUSS-SUPPORT-UX`, `DISCUSS-DIFFICULTY-DEATH-UX` (`in_progress`),
`DESIGN-OVERWORLD-CADENCE`, `DISCUSS-AVATAR-MYUNIT-UX`, `DISCUSS-MINIGAMES-SEAM-UX`,
`BACKLOG-FULL-LIBRARY-BACKUP`, `BACKLOG-RUNSAVE-SEARCH-ARCHIVE`,
`BACKLOG-BRANDED-EXTENSIONS-OS-ASSOCIATION`, `IMPL-ASYNC-PROGRESS-CANCEL`,
`DECIDE-EDITOR-CONTENT-PALETTE` (folds into `CEUI`), `DESIGN-CAMPAIGN-EDITOR-UX` (folds into `CEUI`).

### 2.4 Meta and review rows

`SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13` (`in_progress`) — three scoping models are already in
use and no register owns the question. `OPTIMIZATION-PASS-RATIFIED-DECISIONS-2026-08-13`
(`in_progress`) — the `DOC-014` corollary, owner-scheduled for "after all these plans".
`SESSION-UI-THEMING-ALIGNMENT-2026-08-10` — largely superseded by `UUI-8..10`, `UUI-13..14`.

---

## 3. The constraints that actually bind

Everything else is preference. These are real edges:

1. ~~`NMTE` → compendium packet, `CEUI` search, `DESIGN-TEXT-ENTRY-SERVICE`.~~ **Cut 2026-08-14.**
   The edge was real but the ruling removed both ends of it: the compendium takes the closed
   candidate list and inherits nothing, and `CEUI` no longer waits on a separate text-entry
   authority because it *is* the authority now. The "one text-entry authority or the program grows
   two" concern still holds — it is satisfied by the built `TextEntryService` for modal game entry
   and by `CEUI` for the editor's non-modal case, which are different surfaces, not two answers to
   one question.
2. `TSV` → convoy/shop packet. Satisfied; the packet may be authored now.
3. Convoy → shop. Items need a home before they can be bought.
4. All `UBS` gates → the wireframe album. `UUI-15` holds every unbuilt screen out of the album until
   its session runs, so the album is released by the *last* of them, not the first.
5. A resolved register → any plan that derives from it. This is the `DRC` plan shape and it is
   structural, not incidental: **a plan whose `Decision source` moved must be re-derived before its
   build rows are picked up.**
6. `PER-PERCEPTION-MASKING` → `MRD-8`. Unbuildable; park.

---

## 4. The ordered schedule

Sessions are `S`, review breaks are `R`. Anything marked ⇄ can run in parallel with a build line,
because it touches no code.

### Stage A — disposition, before any new question is asked

**`S1` — Disposition sweep of the twenty unscheduled rows.** ⇄
Run one precedence check across the whole set at once, against the resolved corpus (`UUI`, `CFB`,
`CAU`, `SKF`, `DLUX`, `DRC`, `TSV`, `L10N`, `CRD`, `SHC`, `CUR`, `EPUX`, `PHB`, `RPD`, `REQ`, `PVP`,
`ICO`). Classify every row **closed by precedence / narrowed to residue / genuinely live**, and write
the disposition into the row itself so the finding cannot be lost again.
*Exit:* no row in `1-planning-discussion` lacks a disposition. Expect the schedule below to shrink.

**`S2` — Re-issue the unbuilt-screen agenda. DONE 2026-08-13.** ⇄
Mark `UBS-1`, `UBS-2`, `UBS-4`, `UBS-5` and `UBS-9`'s design half discharged, naming what discharged
each. Restate the live remainder and shrink `UUI-15`'s hold list to the screens that are actually
still held.
*Exit:* the agenda's "recommended order" matches reality; the album's release condition is stated in
terms of what remains.

### `R1` — Plan-corpus cohesion review

The generalized form of the `DRC` plan re-derivation, run once across the corpus rather than
one plan at a time. **Known instances waiting:**

- `B4-PREP-MAP-DEPLOYMENT-2026-07-22` cites a decision source predating `RPD-1..18` — Map Preview as
  canvas, the no-confirm swap, the registry-projected quick card, the staged-transaction deployment
  plan are all rulings it must absorb.
- The **prep/economy plan** against `TSV`, `EPUX-24`/`EPUX-21`/`EPUX-11`/`EPUX-06` and the
  two-primitive ruling — and against the DRC plan, which now consumes four of its primitives by name.
- The **unified UI programme** against `RPD`, `L10N` and the `UUI` register it sequences.
- The **responsive redesign** against `L10N`'s 1.4× text extent and declared-direction bindings.
- **The merged build order across `DRC-V1-S00..S11` and `PREP-V1-S01..S08`** — two open epics sharing
  four primitives with no ordering between them. Do this here or the first Trade slice builds
  `EPUX-24`'s core a second time.

*Exit:* every plan whose decision source moved is either re-derived or explicitly confirmed
unaffected, and the two build epics have one dependency-ordered spine.

### Stage B — the last vocabulary packet

**`S3` — `NMTE` precedence diff, written before the walk.** ⇄
Four checks in two days, four that changed the questions before the owner saw them, one that found
its predecessor partly wrong. `NMTE` was authored 2026-08-12 and has never been checked against
`TEXT-01..15`, `TEXT-06`'s free-text rule, `DESIGN-TEXT-ENTRY-SERVICE`'s autoload decision, `UUI-11`'s
keyboard token exception, or `L10N`'s IME implications.

**`S4` — `NMTE-1..20` owner walk. RAN 2026-08-14, and re-scoped the packet instead of resolving
it.** The walk took the diff's §7 order, which puts the scope question first — and the scope
answer removed most of the packet:

- **Non-modal text entry is editor-only** (`[NMTE-S1]`). It stays out of the core gameplay
  loops; the editor may state that a mouse, physical keyboard and large screen are strongly
  recommended (`[NMTE-S2]`).
- **Game-UI discovery is the closed candidate list over pack content** (`[NMTE-S3]`), per the
  2026-08-06 enumerable-vocabulary ruling. `TEXT-15`'s revisit trigger does **not** fire.
- **The residue is walked with `CEUI`, not before it** (`[NMTE-S4]`) — see `S11`.
- `[CEUI-5]` was ruled in the same session: a **`1920×880` maximized-browser floor**, making the
  editor Expanded-only with one responsive state.

*Exit as achieved:* six `NMTE` questions closed outright, three narrowed, twelve moved to `S11`.
**The modality collision the precedence diff found is dissolved, not arbitrated** — the Compact
ruling *"a text session is modal"* stands unamended because its only challenger no longer exists
at Compact. Rulings and the disposition table live in the `NMTE` register.

### Stage C — the dependent packets ~~in dependency order~~, now unordered

**COMPLETE 2026-08-18.** The editor arc closed 2026-08-14, the compendium walk closed 2026-08-15,
and the distribution-surface walk plus `CVS-1..10` residue closed the convoy/shop arc by 2026-08-18.
All three albums were approved by 2026-08-16, so `UUI-15` no longer holds any screen group.

**Re-ordered 2026-08-14.** `S4` cut the only edge inside this stage, so `S5`/`S6` (convoy/shop),
`S7`/`S8` (compendium) and `S9`–`S11` (editor) have **no ordering between them** and may run in any
order or in parallel.

> **`S9`, `S10` AND `S11` ALL COMPLETE 2026-08-14.** The precedence diff is
> [`ceui_precedence_diff_2026-08-14.md`](../design/ceui_precedence_diff_2026-08-14.md); the walk is
> the `## Owner rulings` section of
> [`campaign_editor_ui_open_questions_2026-08-12.md`](../registers/campaign_editor_ui_open_questions_2026-08-12.md).
> **`CEUI-1..40` are resolved, the twelve `NMTE` residues are closed, and `EW-1..9` are ruled** —
> fifty rulings, `[CEUI-S1]`–`[CEUI-S50]`, taken across three sittings in one day.
>
> **`UBS-8` lifts — and as of 2026-08-15 it is through the gate.** `[DSX-S29]` briefly made this
> provisional by ruling that a `UBS` gate turns on its album being **approved** rather than on its
> walk closing; the owner approved the editor album the same day, so `UBS-8` is the **first gate
> released under the stricter standard**. `R2` waits on approvals, not on walks.
> The `UUI-15` album hold is discharged. `UBS-6` and `UBS-7` both received album approval on
> 2026-08-16; the later `CVS` residue walk changed service/data semantics but did not re-close an
> already released album gate.
>
> **`S12` inherits four items from the editor walk** — the editor scale/display settings group
> (`[CEUI-S1]`), the author profile (`[CEUI-S10]`), the Advanced-mode toggle (`[CEUI-S29]`) and
> `NMTE-20`'s filter-text persistence, the last of them bounded by `[CEUI-S48]`: filter text is
> never written to disk, whatever `S12` decides about scope.


**`S5`/`S6` — DONE 2026-08-18.** `DSX-1..29` was the widened shared-surface walk; `CVS-1..10`
then closed the true convoy/shop residue over capacity, stock, restocking and selling. See
`convoy_shop_open_questions_2026-08-18.md` and its precedence diff.

> **Historical scheduling decision (2026-08-14): `S5`+`S6` COMBINED.** Convoy and shop are one
> session covering **both** surfaces: author the packet, precedence-check it, and walk it in the same
> sitting, as `S9`/`S10`/`S11` did for the editor. **Convoy-first survives as the packet's internal
> section order** — items need a home before they can be bought — not as a session boundary. The
> `UBS-6` "must settle" list is the agenda. This does not change `S7`/`S8`, which remain independent
> and may still run in either order relative to it.
**`S7`/`S8` — DONE 2026-08-15.** `CMP-1..22` resolved the compendium; its album was approved
2026-08-16.
**`S9` — `CEUI` precedence diff.** ⇄ Forty questions, the largest packet in the program, authored
before six registers were resolved. Budget for it properly.
**`S10` — `CEUI` walk, part 1** (non-search). **DONE 2026-08-14** — `[CEUI-S1]`–`[CEUI-S20]`.
**`S11` — `CEUI` walk, part 2** — **DONE 2026-08-14**, `[CEUI-S21]`–`[CEUI-S50]`, closing the
register, the `NMTE` residue and the `EW` wireframe findings together — — **now carries the twelve surviving `NMTE` questions themselves**,
re-scoped as editor questions (`[NMTE-S4]`), not merely a search residue left over from a settled
contract. `NMTE-14`, `NMTE-13` and `NMTE-6` are narrowed by the editor's input and size
assumptions and must not be walked as written. Plus `DECIDE-EDITOR-CONTENT-PALETTE` and the `CSA`
editor surfaces (`CSA-11`, `CSA-17`, `CSA-18`) that `DISCUSS-CAMPAIGN-EDITOR-UI` gates.
*Exit:* achieved. Every `UBS` gate is lifted.

### `R2` — UI corpus and album release review

**COMPLETE 2026-08-16.** `[DSX-S29]` made album approval the gate. Editor cleared it on
2026-08-15; convoy/shop and compendium cleared it on 2026-08-16.

With the last gate lifted, `UUI-15` releases the wireframe album. Before drawing: check every album
sheet against the rulings made since it was drawn, and check the five `EPUX-02` availability surfaces
render one vocabulary — absent hides, gated shows disabled with a reason, disabled entries focusable
but not activatable. That last one was ruled at the shell in `RPD-15` and inherited everywhere, so
it is the cheapest thing in the program to get wrong twice.

### Stage D — the residue

**`S12` — `SETTINGS-PERSISTENCE-SCOPE-REVIEW`.** Three scoping models are live (`CFB-12` per
campaign, `CAU-4` global with override, `CFB-15` per seat) and no register owns the question. Decide
campaign / pack / device / seat for every settings-page entry, and where a new setting inherits its
default. Runs late because more settings arrive from Stages B–C.
**`S13` — Whatever survived `S1`.** `DESIGN-OVERWORLD-CADENCE` is now split by
[`cadence_and_predicate_prerequisites_handoff_2026-08-18.md`](cadence_and_predicate_prerequisites_handoff_2026-08-18.md):
build `B3-REQ-F16-BUILD-2026-08-18-2026-08-19` first, then run the cadence specification and
overworld-surface session. Reversing that order would create a second campaign predicate evaluator.
Support UX, difficulty/death residue and the demand-gated backup/archive trio remain later residue.
**`S14` — The two feasibility calls** — `DISCUSS-AVATAR-MYUNIT-UX` and `DISCUSS-MINIGAMES-SEAM-UX`.
These are in/out scope decisions, not layout sessions; the near-term ask on the minigame seam is only
"do not architecturally block it".

### `R3` — The `DOC-014` optimization pass

`OPTIMIZATION-PASS-RATIFIED-DECISIONS-2026-08-13`, owner-scheduled for after the plans are complete —
which is here. Looks for **bespoke structures that should be standardized and repeated mechanisms
that should be one**. It is not a re-litigation: `DOC-014` keeps reopening-from-ignorance banned and
the precedence check mandatory, and the discriminator is that you may only reopen what you have
demonstrably read.

The pass already has a proven yield. The two-primitive ruling found **four** ratified staging
mechanisms differing only in policy. The duplicate-state shape was found **four times in one day**
(`RCR-2`'s flag, `DRC-29`'s custody, `DRC-33`'s embedded transfers, `DRC-25`'s rejected option).
`RPD-10` was a sixth availability vocabulary. Assume there are more.

**Candidates to take into `R3`:** `ARCH-ONE-PRIMITIVE-LIST-2026-08-01` (converge the five effect
dispatch paths — already a row, already this shape); the selector implementations across shop,
convoy, forge and Trade; the several "reason string" display paths; `REFACTOR-DATAMANAGER-DECOMP`.

**Added 2026-08-15 by the `DSX` walk — the select-then-select gesture.** `[DSX-S9]` rules a
dependent-choice layer consumed by Trade, the forge, cap-full replacement (skills, techniques,
battalions, loadout) and convoy transfer into a full holder. Its gesture — select-then-select,
committing on the second selection, no confirm where the action is reversible — was **already
ratified** for deployment placement in the prep-hub section's 2026-08-13 amendment. The layer must
*absorb* that ruling rather than become a second implementation of it. This is the pass's own shape
found before the build rather than during it, so it enters `R3` as a named candidate with its
duplicate already identified.

---

## 5. Standing rules this schedule assumes

1. **A precedence diff is written before every walk, not after.** Mandatory per `DOC-014`. Four for
   four so far.
2. **Propagation happens in the session that creates it.** One-directional propagation is what made
   the `DRC` walks necessary; the re-derivation paid its four debts rather than deferring them.
3. **`completed` on a research row means the research finished, not that anything was ruled.** Hit
   three times. Read the register's status, not the row's.
4. **A plan whose `Decision source` moved is re-derived before its build rows are picked up.**
5. **Ratified is not frozen** — but reopening requires having read the thing you are reopening.

---

## 6. Assumption-drift watchlist

Specific things this schedule expects to find stale. Check them at the break named, not on discovery:

| Item | Suspected drift | Checked at |
|---|---|---|
| `open_questions_inventory_2026-08-06` §6 | Lists `DRC-1..33` as OPEN; it is RESOLVED | `S1` |
| The `RPD` session note's "seven `UBS` packets need authoring" | Overcounted — `UBS-2` and `UBS-9`'s design are discharged | `S2` |
| `RPD-4`/`RPD-5` question text | Invented an FHD breakpoint the engine has no notion of | `S2` |
| `[RCR-4]` → `[REQ]` banner | **Paid 2026-08-13**; verify no other register carries the same debt | `R1` |
| `GDD_10_Roadmap` `UI-VIEWPORT-ASPECT` | Still records the retired 1280×720 floor | `R1` |
| `ui_ux_architecture_research_and_questions_2026-07-24` | Still states a superseded position | `R1` |
| No localization row exists anywhere in the tracker | `L10N-1..18` is resolved with no build row | `R1` |
| `LEG-1..5` RESOLVED but the gate was never cleared | `LEG-2` remedy and `LEG-4` asset audit outstanding | `R2` |

---

## 7. Not in this order

- **Release-gated work** — the zero-content blocker gates, `FREEZE-WEB-DISTRIBUTION`, the `LEG` asset
  audit, and the `CRD` credits **build** (a hard blocker at the first public RC, unlike its design,
  which is done). These are timed by the release calendar, not by this queue.
- **Build lines** — `DRC-V1`, `PREP-V1`, the responsive conversions. `R1` gives them their order;
  after that they proceed independently, and every ⇄ session above can run alongside them.
- **`MRD-8`** — blocked on a system that does not exist.
- **Deliberately deferred** — `SYS-HEX-GRID-TOPOLOGY`, `SYS-LAGUZ-SHIFTING`, `B7-ARENA` and the rest
  of the `5-backlog` systems. They need this treatment eventually; nothing waits on them.
