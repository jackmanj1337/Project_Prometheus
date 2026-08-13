---
Type: design
Status: Proposed — precedence diff for the SKF and DRC owner walks
Last verified: 2026-08-13
Tracker: DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23, DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `SKF-1..12` and `DRC-1..33` — Precedence Diff Before the Owner Walks

## Purpose and method

The two packets scheduled next (`51ec4d52`) are `SKF-1..12` and `DRC-1..33`. Both owe a
mandatory precedence check before questions go to the owner, made a standing rule after the
`TSV` walk of 2026-08-13 found that packet had never been diffed against the ratified `EPUX`
set and lost every argument it made against ratified text.

This document is that check. Each packet question was read against the registers it claims to
inherit from, against every register resolved **after** the packet was written, and against
`EPUX-1..28`. Nothing here decides anything: it says which questions are already answered,
which are narrower than written, which argue against ratified text, and which claim an
inheritance that does not exist.

**Sources diffed.** `SKF` against `CFB-1..18`, `CAU-1..10`, `L10N-1..18`, `DLUX-4`, `EPUX`.
`DRC` against `DLUX-1..16`, `DLG-1..14`, `RCV-1..6`, `RCR-1..7`, `CAU-4`, `L10N-7..12`,
`EPUX-02/06/11/21/24/28`, and the `TSV` transaction outcome.

## Bottom line

| Packet | Written | Drop — already answered | Walk narrower | Argues against ratified text | Inheritance does not exist | Walk as written |
|---|---|---|---|---|---|---|
| `SKF-1..12` | 2026-08-08 | 1 | 3 | 3 | 2 | 2 |
| `DRC-1..18` (the half scheduled now) | 2026-07-27 | 8 | 3 | 3 | — | 2 |

`DRC-19..33` is the recruitment/capture half, which the agenda defers ("`DRC` recruitment/
capture when scoped"). It is largely untouched by `DLUX` but has four live `EPUX` findings,
recorded in §3.

**Three things are worse than a per-question disposition**, and they are the reason to read
this before the session rather than during it:

1. **`SKF`'s attribution questions inherit a decision that was never made.** `SKF-2` and
   `SKF-6` cite `[CFB-10]`/`[CFB-11]` as the attribution ruling. Neither item is about
   attribution. This is the `TSV` defect exactly — a citation nobody could check.
2. **`DRC` predates `DLUX-1..16` by thirteen days and only one of its 33 questions was
   reconciled.** `DLUX` answers eight `DRC` questions outright and contradicts two more.
   Meanwhile `DLG`, `RCV` and `RCR` all carry amendment banners pointing *at* `DRC` — the
   propagation ran in one direction only.
3. **`UBS-4` has no written question anywhere.** The agenda assigns it to this session
   ("the one cross-cutting question with NO existing row that owns it"), but it is absent
   from `DRC-1..33` and from `DLUX-1..16`. It must be drafted before the session. See §4.

---

## 1. `SKF-1..12`

| Item | Disposition | Against |
|---|---|---|
| `SKF-1` | **Conflict** | `CFB-11` |
| `SKF-2` | **Inheritance does not exist** | `CFB-10`/`CFB-11`, `CVR-4` |
| `SKF-3` | **Conflict** | `CFB-9`, `CFB-10` |
| `SKF-4` | Narrower | `CAU-5`, `CAU-9` |
| `SKF-5` | **Drop — answered** | `CFB-1` |
| `SKF-6` | Narrower — boundary only | `CFB-1`, `CFB-2` |
| `SKF-7` | Narrower | `CAU-8` |
| `SKF-8` | Walk, + new constraint | `L10N-12`, `CAU-8` |
| `SKF-9` | Walk as written | — |
| `SKF-10` | Walk as written | — |
| `SKF-11` | **Inheritance does not exist**, + new constraints | `CFB-18`, `L10N-7`, `CAU-10` |
| `SKF-12` | **Conflict**, + new constraint | `CFB-16`, `CFB-17`, `L10N-9` |

### 1.1 `SKF-5` is already decided — drop it

`[CFB-1]` is titled *"Failed activation-chance roll gets no feedback — **RESOLVED**"* and
rules **silence**, on the reasoning that a miss is genuinely "nothing happened." `SKF-5` asks
the same question and recommends the same answer. It is not an owner question.

The only residue is `SKF-5`'s carve-out — *"permit it only in a debug or explicitly verbose
diagnostic mode."* `CFB-1` does not mention one. That is a tooling question (does a diagnostic
feedback mode exist as a product concept at all), not a feedback-vocabulary question, and it
should not consume owner time inside this walk.

### 1.2 `SKF-1` reverses `CFB-11` in the case `CFB-11` was written for

`[CFB-11]` ruled callout scope explicitly and broadly: pair-up bonuses, the generic
`active_modifiers` bucket, ally auras (`on_combat_apply_modifiers`), equip-item modifiers and
`SkillData` triggers **all** get a callout — *"No 'is this a real skill' filtering."*

`SKF-1` recommends suppressing *"routine passive arithmetic unless it creates a discrete event
or crosses a tactically meaningful boundary."* Inside a combat exchange, an equip-item modifier
and an ally aura **are** routine passive arithmetic, and `CFB-11` already ruled they get
callouts. `SKF`'s own research doc states the conflicting rule plainly ("the event choreography
calls a passive out only when it creates a discrete event"), so this is not a wording slip.

**Reconciliation to propose:** `CFB-11`'s scope is Phase A/D of a combat exchange, as pinned by
`CFB-10`'s code-verified pipeline. Rescope `SKF-1` to passive contributions arising **outside**
that pipeline — movement/terrain arithmetic, prep-screen and forecast contributions, non-combat
resolutions — where `CFB-11` says nothing. The in-combat half of `SKF-1` should be struck, not
walked.

### 1.3 `SKF-3` reorders what `CFB-9` and `CFB-10` already ordered

`[CFB-9]` ruled that every skill/bonus activating for a strike shows above its holder's head
*"one at a time, **in activation order**."* `[CFB-10]` further pins Phase A and Phase D to
exactly one callout section each, dispatched attacker-then-defender, once per exchange.

`SKF-3` recommends that *"callouts use **resolved priority** with stable-id ties, never arrival
timing."* Activation order is the simulation's order; resolved priority is a presentation
reordering of it. `SKF-3`'s first clause ("simulation resolution order is the log order") is
consistent with `CFB-9`; the callout clause is not.

**Reconciliation to propose:** either `SKF-3` is a request to amend `CFB-9` — which the owner
may grant, but should be told they are doing — or "resolved priority" must be read as
tie-breaking *within* activation order, for genuinely simultaneous activations. Walk it as the
narrower second reading unless the owner wants `CFB-9` reopened.

### 1.4 `SKF-2` and `SKF-6` claim an attribution ruling that does not exist

`SKF`'s inherited-contract table asserts: *"Attribution — `[CFB-10]` and `[CFB-11]` name source,
cause, and actual resolved target."* Neither item says that. `CFB-10` is the resolution pipeline
plus start/end callout placement; `CFB-11` is callout scope. **No `CFB-n` item decides
attribution.**

The attribution contract is an **unnumbered section** of the `CFB` research doc
(`combat_feedback_vocabulary_research_2026-08-07.md:153`), and the redirect requirement it rests
on belongs to **`[CVR-4]`** (`cover_intercept_open_questions_2026-06-26.md`), which requires the
attacker's forecast to show the protector as the actual defender pre-commit — described in the
`CFB` research audit as *"designed but unbuilt,"* existing in *"exactly one data path today
… and zero rendered paths."*

**Consequence for the walk:** `SKF-2` and `SKF-6` are not specializations of a ruling. They are
the **first place attribution gets decided**, and whatever they rule becomes the binding
contract that `CVR-4`'s unbuilt forecast requirement must satisfy. They should be walked as
primary decisions with that weight, not waved through as inherited detail.

`SKF-3` carries the same defect in milder form: it cites *"`CFB-14..18` animation-selection
decisions"* when only `CFB-18` is about animation selection (`CFB-14` is the cinematic-renderer
seam, `CFB-15` detail tiers, `CFB-16` gating, `CFB-17` asset-presence declaration).

### 1.5 `SKF-11` and `SKF-12` invent "animation role" and attribute it to `CFB-18`

`SKF-11` cites *"`CFB-18` semantic animation roles"*; `SKF-12` requires authors to supply an
"animation role." `[CFB-18]` ruled two mechanisms — property/texture swap on a shared rig, and
priority-ordered clip lookup keyed on `cause_id`, weapon/method and crit status. **There is no
"semantic animation role" concept in `CFB-18`.**

This matters beyond bookkeeping. `CFB-18` also records that no rig exists — *"no
`AnimationPlayer`/`AnimationTree`/`AnimatedSprite2D` exists in the codebase today"* — and that
`CFB-18` is now a **prerequisite** for `[CSA-8]`. So "animation role" is new vocabulary being
introduced ahead of the rig it would attach to. Walk it as a proposal, and say so.

### 1.6 `SKF-12` reverses `CFB-16`'s silence unless the author/runtime split is stated

`[CFB-17]` ruled that author capability declaration **is** asset presence — *"No redundant
boolean flag to keep in sync with the actual assets."* `[CFB-16]` ruled that a missing asset
falls back to `Simple` **silently**, *"no one-time notice,"* explicitly to avoid nagging the
player about an authoring gap that is not theirs to fix.

`SKF-12` requires that *"engine defaults must be visible validator warnings, not silent generic
English strings."* As written this reads as reversing `CFB-16`.

**Reconciliation to propose:** the two are compatible if the split is stated — `CFB-16`'s
silence is **runtime, player-facing**; `SKF-12`'s warning is **author-time, validator-facing**.
`SKF-12` should say that. Separately, per `CFB-17`, "presentation priority" and "animation role"
must not become the redundant hand-maintained flags `CFB-17` banned; derive them from authored
asset presence wherever that is possible.

`[CAU-5]` supplies the matching runtime rule for the failure case and should be cited:
*"A missing or broken preview handler is a repair error that disables the action; it is not
presented as uncertainty."* Missing feedback metadata must likewise not degrade into fake
uncertainty.

### 1.7 `CAU` already answers part of `SKF-4` and `SKF-7`

- **`SKF-4`** asks whether passives appear in "inspectable forecast/result breakdowns."
  `[CAU-5]` already ruled the forecast is emitted by a **registered preview handler** at the
  strongest truthful detail level (`exact`/`distribution`/`bounded`/`qualitative`), and
  `[CAU-9]` ruled costs appear beside the source or method that incurs them with explicit
  before→after values. The breakdown surface exists and has an owner. Re-scope `SKF-4` to *what
  the preview handler must include*, not *whether a breakdown exists*.
- **`SKF-7`** asks what belongs in full status detail. `[CAU-8]` already ruled reuse of the
  status/condition badge system *"with its source, effects, and expiration in the character
  sheet."* `SKF-7`'s genuinely open content is narrower: stacks/intensity, the removal rule, and
  the "never infer permanent from a blank duration" rule.
- **`SKF-8`** should reuse `CAU-8`'s ratified cycling convention (cycle individual records via
  participant controls; *"counts summarize but never replace the individual list"*) rather than
  defining a second cycling behavior for the field marker.
- **`SKF-11`**'s no-focus-change requirement is already in-project precedent: `[CAU-10]` ruled
  *"forecast cycling updates without stealing that focus."* Cite it alongside the W3C source.

### 1.8 Constraints ratified after `SKF` was written

`SKF` was written 2026-08-08. `L10N-1..18` was ruled 2026-08-13 and binds it.

- **`L10N-8`** — full messages with named parameters and plural categories; **UI sentence
  construction from concatenated fragments is prohibited**. `SKF`'s grammar table is already
  parameterized, so it survives, but `SKF-2`'s "minimum attribution" must be expressed as *one
  message per outcome*, not three fields a presenter assembles. A negation naming both the
  attempted and blocking cause is therefore a distinct message id, not an appended clause.
- **`L10N-7`** — 1.4× pseudolocalized extent, longest-token testing, values truncate after
  labels. `SKF-11` fixes *"the same badge, text, ordering, and **dwell budget**."* A 1.4× longer
  localized cause name inside an unchanged dwell budget is a failure mode `SKF` never
  considered, and `[CFB-13]` already makes the time budget a shared resource across categories.
  **New question to add:** does dwell scale with rendered text length, or does source copy get
  shortened to fit a fixed dwell? `L10N-7` pushes toward shortening the copy.
- **`L10N-12`** — mirroring covers reading/navigation structure only; **the tactical map
  explicitly does not mirror**; components need explicit direction metadata and a component that
  fails to declare it *"must default to the safe case rather than silently mirroring a map."*
  Both `SKF` channels are map-anchored — the above-head callout (`CFB-9`) and the corner status
  marker (`CFB-6`). `SKF-8` and `SKF-11` must declare direction explicitly. `SKF` declares none.
- **`L10N-9`** — registry IDs are never translated; display keys are separate fields.
  `SKF-12`'s required author fields should name the split (`status_id` vs `display_name_key`).
- **`L10N-10`** — user-authored names render verbatim. `SKF-2`'s `{source_name}`/`{target_name}`
  may be user-authored via the avatar/`MCH` path; a verbatim token inside a localized message is
  permitted, but it forbids grammatical inflection of that token.

### 1.9 `DLUX-4` draws `SKF`'s outer boundary, and `SKF` has never seen it

`[DLUX-4]` (2026-08-09) rules by name over `SKF`'s entire subject matter:

> Non-blocking mechanical feedback — **including skill activation, critical, immunity, status,
> and resolution callouts** — belongs exclusively to the existing combat-notification system and
> must not be duplicated in dialogue.

This is not a conflict; it is a boundary in `SKF`'s favour, and it should be recorded in the
register. One combat event may independently emit a mechanical notification **and** invoke an
authored narrative bark; neither channel proxies for the other, and only the bark enters
dialogue history.

---

## 2. `DRC-1..18` — the presentation half scheduled now

| Item | Disposition | Against |
|---|---|---|
| `DRC-1` | Amend the profile list | `DLUX-3` |
| `DRC-2` | Narrower | `DLUX-11` |
| `DRC-3` | **Drop — answered** | `DLUX-11` |
| `DRC-4` | Narrower | `DLUX-14` |
| `DRC-5` | **Drop — answered** | `DLUX-12` |
| `DRC-6` | **Drop — answered** | `DLUX-10`, `DLUX-12` |
| `DRC-7` | Amend journal ownership | `DLUX` §7.3, `DLUX-12` |
| `DRC-8` | **Drop — answered** | `DLUX-7` |
| `DRC-9` | Walk as ruled | — |
| `DRC-10` | **Drop — answered** | `DLUX-14`, `L10N-8/9/10` |
| `DRC-11` | **Conflict** | `EPUX-02`, `DLUX-9` |
| `DRC-12` | Walk as written | — |
| `DRC-13` | **Conflict — internal** | `DRC-30` |
| `DRC-14` | **Conflict — three-way** | `EPUX-06`, `TSV-21`, `CAU-4` |
| `DRC-15` | Already superseded | `DLUX-5` |
| `DRC-16` | **Drop — answered** | `DLUX-11` |
| `DRC-17` | Narrower | `DLUX-10/12/14/15` |
| `DRC-18` | **Drop — answered** | `DLUX-13` |

### 2.1 The eight `DLUX` answers

Each of these was `DRC`'s own recommendation, now ratified — walking them again spends owner
time re-deciding settled text.

- **`DRC-3`** (source format) → **`DLUX-11`**: canonical diffable JSON export, hand-edited JSON
  first-class input to the same validator. `DRC-3` recommended B.
- **`DRC-5`** (where dialogue state lives) → **`DLUX-12`**: the editor exposes
  "conversation-local branching/ephemeral variables" and *not* "anonymous global variables."
  `DRC-5` recommended C.
- **`DRC-6`** (presentation vs gameplay commands) → **`DLUX-12`** + **`DLUX-10`**: typed
  requirement selectors and registered game-action forms, each generated from the owning action
  registry's schema; presentation cues declare `required|optional`. `DRC-6` recommended C.
- **`DRC-8`** (skip) → **`DLUX-7`**: skip traverses the identical authoritative path, evaluates
  every requirement, stages every action, stops at unresolved choices, cannot alter outcomes.
  `DRC-8` recommended A — **and `DLUX-7` adds a constraint `DRC-8` never considered: skip is
  universally available including first viewing, and campaign content may not disable it.**
- **`DRC-10`** (localization/VO) → **`DLUX-14`** plus `L10N-8/9/10`: stable line IDs, readable
  source text, typed tokens resolved through owning systems, deterministic export keyed by line
  ID. `DRC-10` recommended C. Residue: VO/cue references, which `DLUX` §9 puts outside V1.
- **`DRC-15`** (history/replay) → already carries its `DLUX-5` supersession banner. No action.
- **`DRC-16`** (minimum authoring tool) → **`DLUX-11`**: ordered outline editor with focused
  validated forms; the graph view is demand-gated behind a named evidence bar. `DRC-16`
  recommended B.
- **`DRC-18`** (reusable fragments) → **`DLUX-13`**: authoring-time template/copy expansion
  only, fresh stable IDs, no inheritance, no runtime call stack in V1. Note `DLUX-13` is **more
  permissive** than `DRC-18`'s recommendation C, which wanted "only reusable event actions/
  templates, not prose fragments"; `DLUX-13` permits prose templates at authoring time. `DLUX`
  is later and wins.

### 2.2 Three that narrow rather than close

- **`DRC-2`** (flat entries vs named nodes vs graph). `DLUX-11` rules the *editor* and
  constrains any future graph to *"an alternate projection … over the same canonical
  conversation data and stable IDs — not a second source format, separate runtime, or
  graph-owned state machine."* It does not decide whether the **runtime** data carries node
  identity. Worth flagging: `DRC-2`'s recommendation B leaned on nodes as *resume boundaries*,
  and `DRC-9`'s v1 atomic ruling removes mid-conversation resume entirely — so the main argument
  for node identity no longer applies in V1.
- **`DRC-4`** (entry/node IDs). `DLUX-14` requires stable line IDs and forbids keying by array
  position or prose. It does not decide `DRC-4`'s actual question — author-written vs
  tool-generated vs generated-plus-alias. Genuinely open, narrowed to "who generates them."
- **`DRC-17`** (what validation blocks activation). `DLUX-10` (required assets fail pack
  validation), `DLUX-12` (typed forms), `DLUX-14` (validator rejects unknown token types,
  missing role bindings, invalid entity references) and `DLUX-15` (preview reuses production
  validators) already deliver most of option B. Residue: graph reachability, unsafe cycles,
  duplicate consequences, recruit/capture target compatibility, and whether option C's authored
  fixtures are mandatory or merely supported.

### 2.3 `DRC-11` argues against ratified text — the `TSV-8` shape exactly

`DRC-11` proposes a three-value authored disclosure policy — `secret | hinted | explicit` —
"with `explicit` as the accessibility-friendly default." Two rulings already own this ground,
and **one of them predates `DRC`**:

- **`EPUX-02`** (ratified 2026-07-25/26, *before* `DRC` was written): *"absent hides, gated
  shows disabled-with-reason; **uniform across all four availability surfaces**; per-entry
  author-set gate presentation defaulting to visible-disabled."*
- **`DLUX-9`** (2026-08-09): *"author-selectable `shown_disabled|hidden` per option, with
  `shown_disabled` as the default … `hidden` is reserved for authored secrets or undiscovered
  branches, not used as the general failure presentation. … Requirement owns eligibility,
  disclosure result, and reason data."*

So the vocabulary is two-valued, owned by the shared Requirement system, defaulting to
shown-disabled. `DRC-11`'s third value has no owner, and its parallel "authored disclosure
policy" is precisely the second vocabulary `EPUX-02`'s uniformity clause exists to prevent.
This is the argument `TSV-8` lost.

**What survives and is worth the owner's time.** `DRC-11`'s scope is genuinely wider than a
dialogue choice — it covers Talk/recruit/capture eligibility **on the tactical map**, whereas
`EPUX-02`'s four surfaces are Explore/prep surfaces. The honest question is therefore: *is
map-action availability a fifth surface under the same uniform rule?* Additionally, a `hinted`
presentation is compatible if it is authored **content** (a hint string) rather than a third
disclosure state — `EPUX-07`'s unified reason contract already carries a localized reason it
could ride.

### 2.4 `DRC-14` sits on top of a conflict that already exists between `CAU-4` and `EPUX-06`

This one is not `DRC`'s fault, and it should be surfaced regardless of what `DRC-14` decides.

- **`EPUX-06`** (ratified 2026-07-26): confirmation is **authored on the action** plus
  declarative threshold rules, both as predicates; *"player/author strictness is
  **raise-only**."*
- **`TSV-21`** boundary clarification (2026-08-13): *"'raise-only' governs the per-action
  confirmation prompt, which stays author-controlled and **cannot be weakened by a player**."*
- **`CAU-4`** (2026-08-08): *"every additional confirmation step is controlled by **player game
  rules** … Provide **`Minimal` (no extra confirmation)**, `Recommended`, `Always`, and per-tag
  `Custom` presets. These are global player settings with an optional campaign/run override."*

`CAU-4`'s `Minimal` preset lets a player remove an authored confirmation. That is the weakening
`EPUX-06` forbids and `TSV-21` re-affirmed five days after `CAU-4` was ruled. **`CAU-4` and
`EPUX-06` are in direct conflict today, independently of `DRC`.**

`DRC-14` then proposes a third model — author-supplied "confirmation severity" plus
accessibility-forced previews.

**Recommendation:** do not walk `DRC-14` as a fresh question. Put the `CAU-4`/`EPUX-06` conflict
to the owner first. Once that is settled, `DRC-14` collapses to a much smaller question — *which
confirmation tag(s) do irreversible unit-state transitions emit?* — which is an addition to
`CAU-4`'s open tag registry (`relocation` and `inventory_mutation` exist; recruitment, custody
and execution do not).

### 2.5 `DRC`'s profile list contradicts `DLUX-3`

`DRC`'s deep-review addendum (2026-07-27) rules: *"Begin with `story_scene`, `map_talk`,
`support`, `prison_visit`, and `battle_bark`."*

`DLUX-3` (2026-08-09) approves `story`, `map_talk`, `support`, `bark` — and rules explicitly:

> Villages, recruitment, **Prison**, tutorials, and later features **do not gain profiles merely
> because they contain dialogue**: they invoke the closest existing profile and keep their domain
> policy in their owning system.

Direct contradiction on `prison_visit`, plus two renames (`story_scene`→`story`,
`battle_bark`→`bark`). `DLUX` is later and its reasoning is explicit.

The good news: **`DRC-31`'s own text already agrees with `DLUX-3`** — *"Explore's existing
activity/time policy—not the prison panel—decides whether a visit consumes time"* — so only the
addendum's profile list is wrong, not the Prison design. `DRC-1`'s recommendation body also names
a `base` profile, which `DLUX-3` ruled *"initially reuses `story`."*

### 2.6 `DRC-7`/`DRC-33` invert the action-journal dependency

`DRC-33`'s map-end ruling says: *"Review and reuse **the dialogue runner's** action journal,
staged-state overlay, validation, and commit/rollback primitives where their contracts fit."*

`DLUX` §7.3 rules the opposite direction: *"A conversation can contain game-action requests, but
**it is not a transaction engine. The general action journal owns atomicity and overlay
reads**."* `DLUX-12` reinforces it — each form *"emits a typed request; **the owning service**
validates, previews, stages/commits, reports structured failure, logs, and participates in
save/Rewind."*

So `DRC` has the map-end orchestrator borrowing primitives *from* dialogue, where `DLUX` makes
the journal a general service that dialogue merely uses. This is the inverted-dependency
anti-pattern already catalogued in this project. `DRC-33`'s very next sentence gets it right
(*"must not disguise all map-end processing as dialogue or couple transaction correctness to a
presenter"*) — it is the reuse sentence that inverts. Amend the sentence; the substance is fine.

### 2.7 `DRC-13` and `DRC-30` carry two different action-economy models

`DRC-13` recommends **A for v1** — a successful Talk/recruit/capture ends the acting unit's
activation — while reserving a template set (`end_activation`, `consume_minor_action`,
`free_once`) for later, and calls the action-economy seam "future."

`DRC-30`'s Trade ruling, in the same packet, then specifies a considerably richer partial-action
model: the first committed swap marks the actor as having traded, commits its destination,
prevents movement cancellation and a second Trade session, still permits a concluding action,
and defers Canto to *"the ordinary registered post-action-movement policy."*

So the packet both defers the action-economy seam and presupposes it. Reconcile before the walk:
`DRC-13`'s reserved template set should be the one `DRC-30` already implies.

---

## 3. `DRC-19..33` — the deferred recruitment/capture half

`DLUX` barely touches these; the live findings are against `EPUX` and `TSV`, and they should
travel with the row when it is scoped.

1. **Nested rollback is unaddressed (`DRC-7`/`DRC-9`/`DRC-31`).** `DRC-31` rules Prison visits
   are *"ordinary registered Explore activities."* `EPUX-06` ratified *"an optional author-chosen
   exit review receipt with rollback to an activity-entry snapshot,"* with *"exactly one snapshot
   … kept and discarded on acceptance, which bounds cost and implies **at most one gated activity
   open at a time**"*; `EPUX-28` ratified that *"the exit review receipt is the undo window —
   permanent means permanent after acceptance."*
   A prison conversation is therefore an atomic journal (`DRC-7`) nested inside an activity-entry
   snapshot that has its own review-and-rollback window. `DRC` never says which wins, whether a
   completed conversation's commit remains reversible through the receipt, or whether an open
   conversation counts as "a gated activity open." **This is a new owner question, not a conflict
   `DRC` loses.** `EPUX-06`'s warning that *"authors are warned off RNG-bearing activities"* also
   lands here if a campaign makes prison recruitment random.
2. **Trade should consume the shared transaction core, not become a third one.** `EPUX-24`
   ratified *"a shared atomic transaction core, thin panels"*; `EPUX-11` ratified *"overflow to
   convoy; full-cap terminal handling: fail-before-commit for buys, **pending-items tray** for
   unavoidable acquisitions"*; `EPUX-21` generalized a shared quantity primitive. `DRC-30` and
   `DRC-33` both defer to *"the campaign's normal safe destination/failure policy"* — that policy
   is `EPUX-11`'s pending-items tray, by name. Cite it, so Trade does not become a third
   transaction implementation beside shop and convoy. This is exactly the "shop, convoy and forge
   are ONE transaction surface" finding `UBS-2` exists for.
3. **Check `DRC-30`'s multi-swap session against the `TSV` outcome.** `TSV` settled *no cart, no
   staging, no holds, no per-receipt undo, no partial commits; re-quote every commit.* A Trade
   session performing multiple slot swaps is consistent with that **only if each swap is its own
   committed transaction**. `DRC-30` implies this but does not say it.
4. **`RCR-1`/`RCR-5` reopening is already propagated.** Both registers carry their `DRC`
   amendment banners, as does `RCV`, as does `DLG` (twice — `DRC-7..9` and `DLUX-1..16`). No
   action needed; noted so the walk does not redo it.

---

## 4. `UBS-4` is unwritten and this session owns it

The agenda schedules "`DRC` presentation + `UBS-4`" together and describes `UBS-4` as *"WHERE
DIALOGUE SITS RELATIVE TO THE CONTROL REGION — the one cross-cutting question with NO existing
row that owns it, and in Compact it decides whether a dialogue box eats the map, the control
band, or neither."*

**It is not written anywhere.** `DRC-1..33` contains no responsive, size-class, viewport, or
control-region content at all. `DLUX-1` sets a compact presentation floor (speaker name, text,
optional portrait, choices, history, control hints) and `DLUX-2` defers layout to *"profile
policy and responsive context"* — but neither decides the region. `DLUX-15` only requires preview
*"at every responsive size class,"* which presumes the answer exists.

A question needs drafting before the session, against the ratified size-class and menu-density
model (`UUI-1..17`) and the measured 360×640 floor. At minimum it must decide:

- which region the compact presenter occupies at each size class;
- whether the mobile controller's free canvas rect — which lives in the active combination's
  viewport — is suppressed, overlaid, or reflowed for the duration of a conversation;
- whether `map_talk` differs from `story` here, given that `map_talk` needs the map legible and
  `story` does not.

**A second unwritten interaction, same family.** `DLUX-16`'s V1 cue floor includes simple
horizontal move between named stage slots, an idempotent left/right facing flip, and explicit
layer control. `L10N-12`, ruled four days later, requires components to declare direction
metadata and to default to non-mirroring when they do not. The portrait stage is precisely the
ambiguous case — left/right slots read as reading-order, but "characters face one another" is
semantic. `DLUX-16` declares nothing. Decide it before the stage is built.

---

## 5. Corrections owed to other documents

Independent of what the owner rules, these are propagation failures found while diffing.

1. **The `symmetric` → `bidirectional` rename was never applied.** `DRC`'s owner direction
   (2026-07-27) ordered it. The old term survives in `RCV-3` — the authoritative definition —
   at `recruit_conversation_dialogue_open_questions_2026-06-25.md:94`; in
   `plans/dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md:315`; in
   `plans/feature_dependency_atlas_2026-06-23.md:248`; **and inside `DRC` itself** at lines 131,
   304 and 305. The packet that ordered the rename never applied it to its own option text.
2. **An accepted implementation plan derives from an open register and has never seen `DLUX`.**
   `plans/dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md` reads
   `Status: Accepted — implementation plan`, `Last verified: 2026-08-09`, `Decision source:` the
   still-`OPEN` `DRC` register. It contains **zero** references to `DLUX` despite being
   re-verified on the day `DLUX-1..16` was ratified — and `DLUX` answers eight of its decision
   source's questions and contradicts two. The owner should know that changing a `DRC` answer now
   invalidates parts of an already-accepted plan.
3. **`SKF`'s inherited-contract table needs three citation fixes** — the `CFB-10`/`CFB-11`
   attribution claim (§1.4), the `CFB-14..18` animation-selection claim (§1.4), and the `CFB-18`
   "semantic animation roles" claim (§1.5).
4. **`DLUX-1..16` has no row in `REGISTERS.md`.** It is a `Type: design` doc carrying sixteen
   ratified decisions, so the registers catalog — the retrieval path for *"which `[XXX-n]` are
   open or resolved"* — does not list it. `DRC` is catalogued; `DLUX`, which supersedes parts of
   `DRC`, is not. That is a direct contributor to this diff being owed at all.

---

## 6. Suggested session order

1. **Fix the citations first** (§1.4, §1.5) — `SKF-2`/`SKF-6` change weight once the owner knows
   attribution has never been decided.
2. **Walk `SKF`**, minus `SKF-5`, with `SKF-1`/`SKF-3` framed as amendment requests against
   `CFB-11`/`CFB-9` rather than open questions, and the `L10N-7/9/12` constraints folded in.
3. **Settle `CAU-4` vs `EPUX-06`** (§2.4) before touching `DRC-14`. It is a small ruling that
   unblocks a question in each packet.
4. **Walk `DRC-1..18`**, minus the eight answered, with `DRC-11` reframed as the fifth-surface
   question (§2.3) and `DRC-1`/`DRC-7`/`DRC-13` handled as amendments (§2.5–2.7).
5. **Draft `UBS-4`** (§4). It is the only genuinely unwritten thing on the session's agenda, and
   it gates the responsive dialogue build.
6. **Defer `DRC-19..33`** with §3 attached.
