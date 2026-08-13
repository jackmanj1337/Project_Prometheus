---
Type: register
Status: OPEN — DRC-1..18 fully walked 2026-08-13; Group A (DRC-19..24) walk in progress, activation ownership ruled; DRC-25..33 pending
Last verified: 2026-08-13
Register: DRC-1..33
Tracker: DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23
---

# Dialogue, Recruitment, and Capture — Research and Implementation-Planning Questions

**Purpose:** identify every owner decision needed before writing an implementation plan for
dialogue, recruitment, and prisoner capture. This is a research and questions packet, not an
implementation plan. Here, **dialogue** includes map conversations, supports, base/camp scenes,
cutscenes, and choices; **capture** means taking a unit the player does not control into custody;
**recruitment** means changing a unit's controlling faction, temporarily or permanently.

## Executive finding

The existing design has a strong reusable center: an event runner invokes a conversation by stable
ID; a conversation is an addressable sequence of lines, choices, labels, and registered commands;
requirements and consequences use shared predicates/actions; presentation is separate from game
state. Keep that center.

Three earlier assumptions must be reopened because they conflict with the definitions above:

1. `[RCR-1]` makes recruitment a player-faction flip **and** permanent roster insertion. That cannot
   express a guest controlled for three turns, a charmed enemy, a story loan, or a unit who changes
   sides but does not join the campaign roster.
2. `[RCR-5]` says a captured enemy's roster end-state is recruitable. Custody and allegiance are
   independent outcomes; release, exchange, ransom, interrogation, trial, escape, and execution must
   not require a recruitment state.
3. `Unit.team` is currently expected to stand for diplomatic faction, controller, AI behavior, turn
   ownership, and roster membership. Those often coincide, but temporary recruitment and custody
   make the differences observable.

**Provisional architectural recommendation:** one conversation runner and one shared event
command/predicate vocabulary, with multiple authored **conversation profiles** (map talk, support,
story scene, base scene) and swappable presenters. Separately model unit identity, affiliation,
controller, roster membership, and custody. Treat recruit and capture as registered state-transition
actions that can be invoked by dialogue or by any other event; neither should be embedded in the
dialogue interpreter.

**Owner direction, 2026-07-27:** provisionally accept all `[DRC-1..33]` recommendations. They remain
OPEN until the seven identified deep-review topics are walked individually and their interactions are
reconciled. Rename the old `symmetric` Talk term to **`bidirectional`**: either unit may initiate;
this is independent of which human or AI participant owns a conversation choice.

## Precedence walk, 2026-08-13 — read this before walking the rest

This packet was written 2026-07-27, **thirteen days before `DLUX-1..16` was ratified**, and only
`DRC-15` was ever reconciled against it. The mandatory precedence check is recorded in
[`skf_drc_precedence_diff_2026-08-13.md`](../design/skf_drc_precedence_diff_2026-08-13.md);
`DLUX` answers eight questions here outright and contradicts two more, while `DLG`, `RCV` and
`RCR` all carry amendment banners pointing *at* this packet — the propagation ran one way only.

**Drop from the walk — already answered.** `DRC-3` (`DLUX-11`, canonical diffable JSON, hand-edited
JSON first-class); `DRC-5` (`DLUX-12`, conversation-local ephemeral variables, no anonymous
globals); `DRC-6` (`DLUX-12`+`DLUX-10`, typed forms generated from the owning action registry's
schema, cues declare `required|optional`); `DRC-8` (`DLUX-7`, identical authoritative path, stages
every action, stops at unresolved choices — **plus a constraint `DRC-8` never considered: skip is
universally available including first viewing and campaign content may not disable it**);
`DRC-10` (`DLUX-14` + `L10N-8/9/10`); `DRC-15` (already banner-ed); `DRC-16` (`DLUX-11`, ordered
outline editor); `DRC-18` (`DLUX-13`, authoring-time template expansion only, fresh stable IDs, no
runtime call stack — **and more permissive than `DRC-18`'s own recommendation, which would have
banned prose templates**).

**Walk narrower.** `DRC-2` — `DLUX-11` rules the editor, not whether runtime data carries node
identity; note `DRC-9`'s atomic v1 removed the resume-boundary argument that motivated nodes.
`DRC-4` — `DLUX-14` requires stable IDs and forbids positional keys but does not say who generates
them. `DRC-17` — `DLUX-10/12/14/15` already deliver most of option B; residue is reachability,
unsafe cycles, duplicate consequences, recruit/capture target compatibility, and whether option C
fixtures are mandatory. **All three were walked in the second sitting below.**

### Owner rulings, 2026-08-13

- **`[DRC-11]` — RESOLVED. The tactical map is a fifth `EPUX-02` surface.** Map Talk/recruit/
  capture eligibility uses the same two-value vocabulary and the same visible-disabled default as
  every other availability surface, with the shared Requirement system owning eligibility,
  disclosure result and reason data (`DLUX-9`). The proposed `secret | hinted | explicit` policy is
  **rejected**: `hinted` becomes authored *content* riding `EPUX-07`'s unified localized reason,
  not a third disclosure state. `EPUX-02` predates this packet and its uniformity clause binds.
- **`[DRC-14]` — REFRAMED, pending `CAU-4` tag additions.** Confirmation authority was settled
  first, because `[CAU-4]` and `[EPUX-06]` were already in direct conflict independently of this
  packet: `CAU-4`'s `Minimal` preset let a player strip an authored confirmation, which `EPUX-06`
  forbids as raise-only and `[TSV-21]` re-affirmed five days after `CAU-4` was ruled. **Ruling:
  split by origin.** An author's confirmation predicate on a specific action is a floor no player
  setting can lower; `CAU-4`'s presets govern the **engine-derived tag set** only. `DRC-14` then
  collapses to *which tags do irreversible unit-state transitions emit* — recruitment, custody and
  execution tags do not exist in `CAU-4`'s registry yet and must be added.
- **`[DRC-13]` — RESOLVED. One interaction-policy registry, validated presets.** Talk, recruit and
  capture ship presets in the **same** open registry `[DRC-30]` already ruled for Trade. The v1
  Talk preset is `end_activation`, so v1 behavior is exactly `DRC-13`'s option A — expressed as
  data rather than a hardcoded rule. Resolves the internal contradiction where this packet deferred
  the action-economy seam while `DRC-30` presupposed it.
- **Profiles — AMENDED to `[DLUX-3]`.** The deep-review addendum's list is wrong. V1 profiles are
  `story`, `map_talk`, `support`, `bark`. **`prison_visit` is dropped** — `DLUX-3` ruled Prison does
  not gain a profile merely for containing dialogue. A prison conversation invokes `story` and keeps
  attempt limits, cooldowns, visitor eligibility and time cost in its Explore activity and dialogue
  actions, exactly as `[DRC-31]` already specifies. `story_scene`→`story`, `battle_bark`→`bark`.
- **Transaction ownership — RESOLVED. Two primitives, and `[DRC-33]`'s reuse sentence is wrong.**
  `DRC-33` had map-end borrowing primitives *from* the dialogue runner; `DLUX` §7.3 rules the
  general action journal owns atomicity. Examining it found **four** ratified staging/rollback
  mechanisms — `MapLedger`, `EPUX-24`'s transaction core, `EPUX-06`'s activity snapshot, and the
  journal — differing only in *policy* (retention, charging, who may trigger) while sharing every
  *hard* part (overlay reads, commit ordering, RNG determinism, save participation). **Ruling: two
  named primitives.** A **staged transaction** (overlay + commit/discard) is consumed by the
  dialogue journal, the map-end pipeline, `EPUX-24`'s core and Trade; a **snapshot**
  (capture + restore, including the RNG stream) is consumed by `MapLedger` and `EPUX-06`'s receipt,
  with retention/charging/trigger policy layered on top. This reopens none of the four rulings, and
  it defines the nesting this packet never addressed: a conversation **stages** inside an activity
  that is **snapshot**. Prefer staging; snapshot only to undo something already committed.
- **`UBS-4` — RESOLVED for Compact.** A conversation occupies the **canvas region only and never
  the control band**, with per-profile defaults: `story` takes the full canvas, `map_talk` takes a
  lower canvas band so the relevant board stays visible. This honors the never-overlap-the-canvas
  rule and avoids controller show/hide thrash mid-conversation — the republish-during-gesture defect
  class the existing suites structurally cannot catch. **In gamepad mode** the pad reaches history,
  pause, skip, advance, and **scrolls a line within its line object** (which is also the answer to
  `[L10N-7]`'s 1.4× extent for dialogue: a line that fits in English and overflows in German scrolls
  rather than clipping). **Authors are strongly warned** to break long sections into smaller
  advanceable ones; where a wall of text genuinely is the right answer, the sanctioned form is a
  larger popup notification window. The author warning rides `[DLUX-10]`'s structured author-time
  warning contract. *Extended to Medium and Expanded in the second walk below; the `[DLUX-16]`
  direction metadata was ruled there too.*

### Owner rulings, 2026-08-13 (second walk — the remaining five, plus the drafting items)

- **`[DRC-2]` — RESOLVED. Flat ordered entries with stable line IDs; no runtime node objects.**
  A conversation is a flat ordered sequence of entries, each carrying the stable line ID
  `[DLUX-14]` already requires. Jumps, labels and requirements target a line ID directly. There is
  no second addressable level to author, validate or migrate, and `[DLUX-11]`'s demand-gated graph
  view remains what it was ruled to be — a projection over this same canonical data. `DRC-2`'s own
  argument for node identity was nodes-as-resume-boundaries, which `[DRC-9]`'s atomic v1 removed.
- **`[DRC-4]` — RESOLVED. Tool-generated stable ID plus an optional author alias.** The editor mints
  a stable opaque ID at creation; the author may attach a readable alias, and the alias is what
  jumps, exports and localization keys use. The validator enforces alias uniqueness within the pack.
  IDs survive reordering and prose rewrites (satisfying `[DLUX-14]`'s ban on positional or prose
  keys) while diffs stay readable, which is why `[DLUX-11]` chose diffable JSON in the first place.
  Hand-authored JSON — first-class input per `DLUX-11` — supplies both fields directly.
- **`[DRC-9]` — RESOLVED as previously ruled; now expressed as a staged transaction.** The
  2026-07-27 owner ruling stands **unchanged**. What changes is that it needs no mechanism of its
  own: under the two-primitive ruling above, a conversation **is** a staged transaction, so a save
  discards the stage and only committed state was ever serializable. No staged consequence can leak
  into a save **by construction** rather than by rule. The save UI still explains, before confirming,
  that an in-progress conversation restarts from its beginning on load. **`[DLG-11]` is superseded**
  — its promise that every completed line is automatically suspend-safe is no longer true — and is
  banner-ed accordingly. Post-v1 option C may still add committed mid-conversation checkpoints.
- **`[DRC-12]` — RESOLVED. Option C: an authored interaction descriptor, directed-adjacent template.**
  The descriptor carries direction (`directed` | `bidirectional`), a range predicate, allowed phases,
  and which side may initiate. It ships as presets in the **same** open interaction-policy registry
  `[DRC-13]` ruled — not a second registry — with directed-adjacent as the shipped default. Classic
  adjacency, long-range/radio, base scenes and enemy-initiated talks are then authored content rather
  than engine edits. Note the term is `bidirectional`; the July rename is now enforced by
  `check_docs.py` check [31].
- **`[DRC-17]` — RESOLVED. The residue blocks; authored fixtures are supported, not mandatory.**
  `[DLUX-10/12/14/15]` already deliver most of option B. The four remaining checks — unreachable
  entries, unsafe cycles, duplicate consequences, and recruit/capture target incompatibility — all
  **block** pack activation and export. Option C's authored fixtures stay **supported**, available to
  campaign test suites and editor preview under `[DLUX-15]`'s shared-validator rule, but are never
  required to ship a pack: making them mandatory would gate the fork-a-public-pack onboarding model
  (`CSA`) behind writing tests, which is the wrong barrier for the low-code author it targets.
- **`UBS-4`, non-Compact — RESOLVED. One rule at every size class, with a proportional band.**
  Medium (600–1023) and Expanded (≥1024) keep the Compact rule exactly: dialogue occupies the canvas
  region and **never** the control band. `story` takes the full canvas; `map_talk` takes a lower
  canvas band whose height shrinks proportionally as the class grows, because more board is already
  visible. One presenter and one set of per-profile defaults, so `[DLUX-15]`'s preview-at-every-size-
  class obligation stays cheap. Rejected: moving `map_talk` into a side rail above Compact — the
  tactical map is a canvas, not a list+detail screen, so the pane model would have to be extended to
  it and dialogue would become three presenters to build and regression-test.
- **`[DLUX-16]` stage direction under `[L10N-12]` — RESOLVED. The flip belongs to the stage; the box
  follows reading direction.** The portrait stage declares **non-mirroring**: its named slots and the
  idempotent `left|right` facing state are **screen-absolute**, so the facing flip stays a pure art
  flip with nothing to compose against, and an RTL locale preserves the composition the author built.
  The dialogue box justifies to the locale's reading direction and renders the line as a single
  inline run — `Speaker: words words words more words.` **The speaker name is the head of that
  paragraph, not a separately positioned name plate**, so it inherits the paragraph's justification
  and needs no direction metadata of its own. This resolves `L10N-12`'s obligation by *removing* a
  component rather than annotating one. **Derived constraint, per `[L10N-8]`:** that form must be a
  single localizable template (one message id taking `{speaker}` and `{line}`), never `name + ": " +
  text` assembled in GDScript — otherwise a locale cannot change the separator or the order.
  `[L10N-10]` still applies to `{speaker}`: a user-authored name renders verbatim and is not
  grammatically inflected.
- **`[CAU-4]` tag additions (closing `[DRC-14]`) — RESOLVED. Three tags.** `recruitment` (allegiance
  or controller change), `custody_change` (capture, release, transfer), and `execution` (permanent
  unit removal) join `relocation` and `inventory_mutation` in `CAU-4`'s **engine-derived** tag
  registry. Three distinct reversibility profiles, so a player may set `Always` on execution while
  leaving recruitment at `Recommended`. Custody stays independent of allegiance — conflating them is
  precisely what this packet's executive finding opened `[RCR-5]` to reject. **Consequence of the
  split-by-origin ruling, stated deliberately:** `Minimal` still strips all three, and a campaign that
  needs execution always confirmed authors a confirmation predicate on the action, which is a floor
  no player preset can lower. `DRC-14` is now closed.

## `DRC-19..33` — scope for the next session (set 2026-08-13)

The recruitment/capture half, scoped as the agenda's "`DRC` recruitment/capture when scoped"
required. Fifteen questions in five groups, ordered so each group's output feeds the next.

| Group | Items | What it settles |
|---|---|---|
| **A — the state-model spine** | `DRC-19..24` | The five dimensions replacing overloaded `Unit.team`; what a recruitment transition specifies; required durations; when a newly controlled unit becomes actionable; what data survives a control change; when permanent roster insertion happens. |
| **B — authoring and sources** | `DRC-25`, `DRC-26` | How recruitment requirements are authored, and which sources may recruit. |
| **C — capture and custody** | `DRC-27..29`, `DRC-31`, `DRC-32` | Capture-entry mechanics, physical eligibility, on-map custody representation, during/after-map disposition, escape and rescue. |
| **D — the captive's inventory** | `DRC-30` | Trade. Carries the most live precedence findings of any single item. |
| **E — observation** | `DRC-33` | How objectives, AI, save/rewind and versioning observe these transitions. |

**Group A first and alone if time is short.** It is the spine: `DRC-20..24` are all specializations
of whichever dimensional model `DRC-19` settles, and the executive finding already reopened
`[RCR-1]` and `[RCR-5]` against it. Groups C and D both consume A's custody dimension.

### Precedence work owed before the walk

Mandatory per `DOC-014`, and this half owes more of it than the first did, because five registers
carry amendment banners pointing *at* this packet while the reverse direction was never checked.

- **Group A** against `[RCR-1..7]` and `[RCV-1..6]` — both were reopened by this packet's executive
  finding and both carry `DRC` banners; confirm the banners still say what A concludes.
- **`DRC-29`** against `[DRC-11]`'s new fifth-surface ruling and `[EPUX-02]`'s two-value disclosure
  vocabulary. On-map custody presentation is an availability surface and must not invent a third
  vocabulary — the argument `DRC-11` already lost.
- **`DRC-30`** against `[EPUX-11]` (**pending-items tray**, by name — its "campaign's normal safe
  destination/failure policy" *is* that tray), `[EPUX-21]` (shared quantity primitive), `[EPUX-24]`
  (shared transaction core) and the `TSV` outcome. `TSV` settled *no cart, no staging, no holds, no
  per-receipt undo, no partial commits; re-quote every commit* — so `DRC-30`'s multi-swap session is
  consistent **only if each swap is its own committed transaction**, which it implies but never
  states. Trade must consume the shared core, not become a third implementation beside shop and
  convoy; that is what `UBS-2` exists for.
- **`DRC-31`/`DRC-32`** against `[EPUX-06]`/`[EPUX-28]`. Largely **answered already** by the
  two-primitive ruling above — a prison conversation *stages* inside an activity that is *snapshot* —
  so what remains is narrow: whether a completed conversation's commit stays reversible through the
  exit receipt, and whether an open conversation counts as "a gated activity open" under `EPUX-06`'s
  at-most-one rule. `EPUX-06`'s warning against RNG-bearing activities lands here if a campaign makes
  prison recruitment random.
- **`DRC-33`** against `DLUX` §7.3 — the inverted reuse sentence is **already amended** above; verify
  nothing else in the item still borrows primitives *from* the dialogue runner.
- **All groups** against `[DRC-13]`'s interaction-policy registry and the confirmation split-by-origin
  ruling, which now supplies `recruitment`, `custody_change` and `execution` tags that did not exist
  when this packet was written.

### The consequence that outranks the walk itself

`plans/dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md` is marked **Needs
revision**, and **twelve build slices plus their epic derive from it** — `DRC-V1-S00..S11` and
`EPIC-DIALOGUE-CUSTODY-V1`, every one pointing at that plan by name and slice number. Today's
`DRC-2/4/9/12/17` rulings change it, and `DRC-19..33` will change it further.

**So the order is: walk `DRC-19..33` first, re-derive the plan second.** Re-deriving before the walk
means doing it twice. Until the re-derivation lands, those thirteen rows describe a design that no
longer holds and must not be picked up for build.

## Owner rulings, 2026-08-13 (third walk — Group A, the state-model spine)

Preceded by the mandatory `DOC-014` check recorded in
[`design/drc_group_a_precedence_diff_2026-08-13.md`](../design/drc_group_a_precedence_diff_2026-08-13.md),
whose headline correction is that the earlier diff's *"`RCR`/`RCV` reopening is already
propagated"* holds only at the **register banner** level: `RCR-2`, `RCR-3`, `RCR-4` and `RCR-7`
carry no banner, and `RCV-4` still names `[RCR-1]`'s superseded faction flip as the contract its
`recruit` action calls.

- **Activation policy ownership — RESOLVED. Split by subject; two seams, one subject each.**
  `[DRC-13]`'s open interaction-policy registry owns the **actor's** cost of performing an
  interaction, which is what it already says and all it now says. The typed recruitment transition
  owns the **target's** arrival activation, as a field renamed from `DRC-20`'s ambiguous
  `activation_policy` to **`target_activation`**. The two can never contradict each other because
  they describe **different units**: the recruiter's spent action and the recruit's arrival state
  are not the same unit's turn.

  **The constraint that decided it** is `[RCV-4]`'s trigger-agnostic ruling — the `recruit` action
  is runnable from `talk`, village `Visit`, `turn_reached` or `flag`, so "an ally joins on turn 5"
  is a recruitment with **no actor and no interaction at all**. A target-activation policy living
  only on the interaction registry is unreachable in that case, which is what rules out folding
  both into one registry. A transition, by contrast, always exists even when an actor does not.

  **Absorbs a fourth location.** `[DRC-21]`'s already-ruled *"expiry never grants a bonus action"*
  was a target-activation rule living in neither seam; it is now simply the expiry transition's
  `target_activation` value. Rejected: a transition owning both (it partly reverses `[DRC-13]`,
  and plain Talk and Trade have no transition to hang a cost on, so the registry must exist
  anyway); and a universal preserve-always engine rule (it forecloses `DRC-22` option C outright,
  even as an opt-in).

  **Consequences to carry:** `DRC-20`'s field list is amended to `{target_affiliation,
  target_controller, roster_policy, duration, expiration_outcome, target_activation}`; `DRC-22`
  is now a question about that field's default and permitted values, not about where the answer
  lives; and `[DRC-13]`'s registry scope is confirmed actor-only, needing no amendment.

- **`[DRC-20]` — RESOLVED. Option B, amended: a sparse patch over all five dimensions.** The
  transition is `{target_affiliation?, target_tactical_side?, target_controller?,
  target_roster_status?, target_custody_status?, duration, expiration_outcome, target_activation}`,
  where **an unset dimension means unchanged**. One transition type therefore serves recruitment,
  defection, capture, release and expiry: `charm` sets `target_controller` alone, a capture sets
  `target_custody_status` alone, `permanent_join` sets affiliation, side and roster together.

  **Option A was foreclosed before the walk** — `[DRC-21]`'s ruled `map_end` duration with a
  mandatory expiry outcome is unrepresentable in a single-arity faction flip, which is also why
  `[RCV-4]`'s `recruit(unit)` contract cannot stand (see §1 of the Group A precedence diff).
  **Option C was foreclosed by `[DRC-17]`**, ruled the previous sitting: recruit/capture target
  incompatibility is a **blocking** validation, and an arbitrary action list gives the validator
  nothing typed to check.

  **The amendment matters more than the option choice.** `DRC-20`'s written field list covers only
  three of the five ruled dimensions — it matches `DRC-19`'s *pre-ruling* option B, which had four
  and no `tactical_side_id`; the owner ruling added that fifth dimension the same day and the field
  list was never updated. Since `tactical_side_id` owns turn group, hostility lookup, targeting and
  objective presence, a transition that cannot set it leaves a recruited enemy **in the enemy turn
  group**. Rejected: deriving `tactical_side` from `affiliation`, which collapses the exact
  distinction `[DRC-19]` drew — an allied-AI unit shares the player's side but not their
  affiliation, and a charmed enemy keeps its affiliation while changing only controller and side.
  Also rejected: splitting recruitment and custody into two transition types; dimensional
  independence (the executive finding that reopened `[RCR-5]`) is preserved by sparseness and does
  not require separate mechanisms.

  **Presets remain the author-facing interface**, per `[DRC-19]`'s ruling that routine authors
  choose validated presets rather than editing dimensions: `permanent_join`, `map_guest`,
  `turn_control`, `defect_to_third_faction`, and the custody presets Group C will name.

- **`[DRC-22]` — RESOLVED. `preserve` is the default; `refresh` is permitted and warned.**
  `target_activation` takes `preserve | end | refresh`, defaulting to **`preserve`** — a newly
  controlled unit keeps whatever activation state it had, so one that has already acted stays done.
  `refresh` remains authorable but emits a `[DLUX-10]` structured author-time warning naming the
  double-turn risk; it does **not** block. This is `DRC-22`'s own recommendation — option B as the
  default with option C as an explicit opt-in under warning-level validation — and it keeps the
  classic behaviour where a recruited unit that has not yet acted may act at once.

  **One offered position does not exist.** `preserve` already permits an unacted unit to act, so
  `refresh` differs from `preserve` **only** for a unit that has already acted — which is precisely
  the double-turn case. Any scheme that permits `refresh` but suppresses it when the unit has acted
  this round is therefore `preserve` with extra machinery, not a middle position. The choice is
  binary: allow the exploit as a warned authored decision, or remove the value.

  **Fixed by prior ruling:** `[DRC-21]`'s *"expiry never grants a bonus action"* pins the `map_end`
  expiry transition to `preserve` whatever an author writes elsewhere. Rejected: removing `refresh`
  entirely (it forecloses deliberate designs such as a rescued ally who rallies and acts), and
  moving the default onto the presets (a hand-authored transition outside a preset would then have
  no fallback).

- **`[DRC-23]` — RESOLVED. The transition patches the five dimensions and nothing else; everything
  else is preserved.** HP, progression, statuses, inventory, relationships, history, identity **and
  role-authored behaviour data** all survive a transition untouched. `[DRC-21]`'s preservation
  guarantee becomes an enforced boundary rather than a description, and the transition stays one
  small thing: it changes *which side a unit is on and who controls it*, nothing more.

  **Option B was foreclosed by `[DRC-19]`**, which requires stable unit identity across every
  transition — despawning and re-instantiating a roster template cannot provide it. Option C's
  mechanism is simply `[DRC-20]`'s sparse patch, so what this ruling settles is the *allowed-fields*
  half option C left open: the allowed fields are the dimensions themselves.

  **Behaviour changes are ordinary effects, commonly bundled with recruitment.** `DRC-19` gives
  `tactical_side_id` the default AI coalition, but the `[AIP]` profile and any scripted orders are
  separate authored data, and changing them is an **effect** authored alongside the transition —
  the same route already ruled for stat consequences. This keeps **one** mechanism for "recruitment
  also changes X" instead of an in-transition allow-list for behaviour and the effect system for
  everything else. Since `[DRC-19]` makes **presets** the author-facing interface, the shipped
  recruitment presets bundle the behaviour effect, so an author choosing `permanent_join` or
  `map_guest` still authors one thing.

  **Consequence, stated deliberately:** a hand-built bare transition that bundles no behaviour
  effect leaves the old profile and orders running — a `map_guest` under an AI controller will
  execute orders written for the enemy. That is the correct outcome of a small transition plus
  explicit effects, and the presets are what keep it off the common path.

  **Rejected: an open patch over any field.** A transition able to set HP or level would make
  recruitment an arbitrary stat-editing path duplicating the effect system and undercutting
  `DRC-21`.

- **Transition ownership (amends `[RCR-3]`) — RESOLVED. One unit-state service owns both reads and
  writes.** The authoritative service `[DRC-19]` already requires for resolving controller and
  hostility also owns **transition application**: `apply(transition)` is the only path that mutates
  the five dimensions. The roster becomes a **consumer** that reacts to `roster_status` changes
  rather than the thing that drives them.

  This unwinds `[RCR-3]`'s inversion — it gave the roster a `recruit()`/`capture()` API writing four
  dimensions the roster does not own, the same inverted-dependency shape amended in `[DRC-33]` the
  previous sitting. It also gives one place to hang the three things every transition owes:
  `[DRC-17]`'s blocking validation, the `[CAU-4]` `recruitment`/`custody_change` tags, and
  participation in the staged transaction. Rejected: callers writing dimensions directly, which
  spreads all three obligations across every call site. **`RCR-3`'s hand-off contract survives
  re-expressed, not discarded** — MET still supplies the trigger and the action; what changes is
  which service the action calls.

- **`[RCR-2]`'s `recruited:<id>` flag — RESOLVED. Retire it; branch on unit state through `[REQ]`.**
  The auto-set `F6` flag is dropped. Story branching asks a **`[REQ-13(b)]` runtime unit-state
  predicate** about `roster_status` or recruitment history directly — an already-ruled,
  author-extensible family built as consumers need it, so this adds no mechanism.

  **The setter question disappears rather than being answered.** `[DRC-21]`'s `map_end` guest is a
  recruitment that produces no membership, a case `RCR-2` never anticipated, and every answer to
  "does a guest set the flag" was defensible — the sign that the flag was duplicating state the
  dimensions already hold. Retiring it also removes the leak hazard: a flag written outside
  `[DRC-9]`'s staged transaction would have reintroduced exactly what `DRC-9` closed by
  construction. `RCR-2`'s underlying distinction is preserved, because `roster_status` and
  recruitment history are separately queryable.

## Research synthesis

### Player perspective

- Classic Fire Emblem recruitment often makes positioning and character knowledge part of the map
  puzzle: a specific actor uses Talk on a specific adjacent unit. That produces memorable stories,
  but opaque eligibility can push players toward external guides. The FEBuilder event editor exposes
  Talk Conditions as a distinct chapter-event category with initiator, target, event, and completion
  flag, accurately reflecting that model ([FEBuilder event-editor FAQ](https://feuniverse.us/t/ultraxblades-febuilder-help-faq/19565?page=2)).
- *Thracia 776* makes capture a risky tactical/economic action tied to carrying and inventory
  seizure. Nintendo's own description highlights both capturing enemies to take items and carrying
  allies as new strategic commands ([Nintendo, Thracia 776](https://www.nintendo.com/jp/titles/50010000041662.html)).
  This supports the existing plan's reuse of the carry substrate, but not its assumption that custody
  ends in recruitment.
- *Fates* instead makes capture feed a between-map prison/persuasion loop. The important comparison
  is not which version to copy, but that “defeat non-lethally,” “hold prisoner,” and “persuade into
  the army” are separate player decisions. The distinction is summarized by the series reference's
  [Capture](https://fireemblem.fandom.com/wiki/Capture) and
  [Prison](https://fireemblem.fandom.com/wiki/Prison) articles.
- *Three Houses* shows a different recruitment experience: visible out-of-battle requests evaluate
  character-specific stat/skill requirements, with relationship progress lowering the barrier
  ([official recruitment guide](https://www.fireemblemawakening.com/three-houses/assets/media/Recruitment_Guide.pdf)).
  Recruitment therefore needs a trigger-agnostic requirement/action contract, as the existing plan
  proposes, rather than being synonymous with Talk.
- Support conversations are not just ordinary map Talk entries: their availability, chronology,
  archive/replay behavior, and relationship rewards differ. They can still share the same runner and
  presenter interfaces.

### Low-code author perspective

- FEBuilder's category-specific forms make common work discoverable: Turn, Talk, Map Object, and
  Always conditions each expose relevant fields, then point to an event and completion flag. Its
  weakness is the underlying ROM vocabulary and flag management; the visual layer reduces but does
  not remove state-coupling errors.
- Event Assembler offers full control through macros and event code. Its standard library includes
  character-event and allegiance-change helpers, demonstrating a productive compiled-command seam,
  but also the learning and maintenance burden of a large low-level opcode vocabulary
  ([EA standard library](https://github.com/StanHash/EAStandardLibrary/blob/master/EAstdlib.event)).
- SRPG Studio exposes Talk events and unit-affiliation commands directly. Its map tooling allows a
  player character to be placed as an enemy for recruitment, while affiliation changes preserve the
  identity ([SRPG Studio mapping reference](https://srpg-studio.fandom.com/wiki/Mapping)). A later
  release explicitly distinguished an enemy changed to player affiliation as a **guest** unit,
  evidence that control and durable roster membership need separate concepts
  ([SRPG Studio 1.302 notes](https://steamdb.info/patchnotes/15804916/)).
- RPG Maker MZ's ordered event-command list is approachable and expressive: Show Text, Show Choices,
  switches, variables, conditional branches, labels, jumps, common events, party changes, and plugin
  commands share one list ([official command reference](https://rpgmakerofficial.com/product/MZ_help-en/01_10.html)).
  Its event pages make triggers and conditions visible, and selected events can be tested directly
  ([official map-event reference](https://rpgmakerofficial.com/product/MZ_help-en/01_09_03.html)).
  The tradeoff is that free composition can duplicate logic and hide state in numbered switches.
- The best fit for Prometheus is therefore a hybrid: focused templates/forms for common Talk,
  support, recruit, and capture flows, all compiling to one validated, diffable data model.

### Full game-development perspective

- Yarn Spinner separates scripts, a runner, variable storage, localized line providers, presenters,
  and registered command handlers ([runner architecture](https://docs.yarnspinner.dev/components/dialogue-runner)).
  Its author language provides nodes, lines, options, jumps, variables, flow control, commands, and
  functions ([scripting fundamentals](https://yarnspinner.dev/docs/yarn/02-fundamentals/)). This is
  strong evidence for separating narrative traversal from presentation and game commands.
- Yarn also recommends a single source of truth rather than mirroring variables between narrative
  and game code, and its documented resume support is node-based rather than arbitrary-line-based
  ([Yarn FAQ](https://yarnspinner.dev/docs/faq/)). Prometheus needs stronger stable entry IDs if it
  keeps the existing between-line suspend requirement.
- Dialogic demonstrates the accessibility of a block-based Godot timeline editor with variables and
  built-in events ([Dialogic documentation](https://docs.dialogic.pro/)). It is a useful UX
  reference, not necessarily a dependency: Prometheus has campaign-pack loading, deterministic save,
  open registries, and tactical state constraints that a general VN plugin does not own.
- Godot custom Resources provide typed properties, Inspector editing, recursive serialization, and
  version-control-friendly `.tres`, and can later receive a custom `EditorPlugin`
  ([Godot Resource documentation](https://docs.godotengine.org/en/3.3/getting_started/step_by_step/resources.html)).
  Campaign packs already use canonical JSON, however, so the runtime format and the editor's internal
  model do not have to be identical as long as compilation is deterministic and lossless.

## Comparison with existing Prometheus plans and implementation

| Concern | Existing decision or implementation | Research pressure | Provisional disposition |
|---|---|---|---|
| Dialogue presentation | `[DLG-1]`: one scene-plus-log overlay | Supports, map barks, and story scenes want different layouts, but Yarn separates runner and presenters | Keep one runner; use profile-selected presenters/layouts rather than one compulsory visual composition |
| Dialogue data | `[DLG-2]`: flat addressable `line/choice/command/label` list | RPG Maker and Event Assembler validate ordered command lists; Yarn validates readable nodes and jumps | Keep compiled addressable entries; decide whether authors write node/script form or raw entries |
| Commands | `[DLG-2]`: scene ops and MET actions both called commands | External tools benefit from one list, but game effects must be validated and transactional | Split presentation commands from registered game actions in schema/permissions even if one runner dispatches both |
| State | `[DLG-5]`: choices set F6 flags or jump | Yarn warns against mirrored state; RPG Maker's arbitrary numbered variables become hard to audit | Shared campaign/map facts are authoritative; dialogue-local variables are ephemeral unless explicitly exported |
| Authoring | `[DLG-8]`: plain data now, dedicated editor later | FEBuilder/RPG Maker show immediate value from templates, field pickers, validation, and event tests | Define compiler/schema/validator first; ship a focused form/list editor before a full node graph |
| Talk | `[RCV-2]`: unit-targeted interactive trigger, directed or bidirectional | Matches FEBuilder/SRPG Studio and classic FE | Keep; add discoverability, range, enemy initiation, and failure-policy decisions |
| Recruitment | `[RCR-1]`: faction flip plus permanent roster member | SRPG Studio guests and the requested temporary-control definition invalidate the coupling | Replace with an explicit transition spec over affiliation, controller, duration, and roster policy |
| Capture | `[RCR-5]`: non-lethal sleep then carry; captured unit becomes recruitable | Thracia supports carry/equipment interaction; Fates supports custody/persuasion separation | Keep optional carry path; make custody a first-class outcome independent of recruitability |
| Runtime implementation | No dialogue, recruit, Talk, custody, prison, or relationship runtime found on this branch; `Unit.team`/`FactionData` are the existing allegiance substrate | Clean slate permits separating concepts before save compatibility hardens | Resolve DRC questions before implementation; do not add one-off booleans or dialogue-only state transitions |

## Owner questions

Each question is implementation-plan blocking unless marked “later-tooling.” Recommendations are
provisional and may change when answers interact.

### A. Shared architecture and vocabulary

#### [DRC-1] Is dialogue one system or several?

- **A — One runner and one fixed full-screen presentation.** Pro: smallest number of code paths;
  every scene supports the same effects. Con: battle barks, supports, and long cutscenes inherit UI
  and authoring complexity they may not need.
- **B — Separate systems per use case.** Pro: each surface stays simple. Con: branching, localization,
  save/resume, logs, and commands are duplicated and drift.
- **C — One runner/data contract, multiple presentation and authoring profiles.** Pro: shared logic
  with purpose-fit UX; matches Yarn's runner/presenter split. Con: requires a clear profile contract
  and compatibility tests.

**Recommendation:** C. Treat “map talk,” “support,” “story,” “base,” and “bark” as profiles/templates,
not separate interpreters.

#### [DRC-2] What is a conversation's author-facing structure? — **RESOLVED 2026-08-13**

- **A — One flat entry list.** Pro: matches the current plan, runtime cursor, RPG Maker, and simple
  diffs. Con: long branches become difficult to navigate.
- **B — Named nodes containing ordered entries and explicit jumps.** Pro: readable chunks, reuse,
  graph visualization, and manageable branching. Con: adds node identity and call-stack semantics.
- **C — Arbitrary graph.** Pro: strongest visualization. Con: poor text diffs, complicated cycles,
  resume, localization, and validation.

**Recommendation:** B, compiled to stable flat instructions if the runtime benefits. Nodes should be
organization/resume boundaries, not scene-owned mutable objects.

#### [DRC-3] What is the source format shipped by campaign packs?

- **A — Typed Godot `.tres` Resources.** Pro: built-in Inspector and typed references. Con: awkward
  bulk writing, external tooling, pack conversion, and merge review.
- **B — Canonical JSON.** Pro: matches Tier-2 campaign packs, portable, easy to validate and diff.
  Con: verbose for prose and weak without an editor/schema.
- **C — A readable dialogue DSL compiled to canonical JSON.** Pro: best writer experience plus safe
  runtime data. Con: compiler, source maps, and two artifact forms must be maintained.

**Recommendation:** B for the first slice, with a lossless editor and an optional C front end later.
Do not require authors to edit `.tres` arrays for large conversations.

#### [DRC-4] How are entries and nodes identified? — **RESOLVED 2026-08-13**

- **A — Array indexes.** Pro: minimal data. Con: inserting a line invalidates saves, references, VO,
  localization, and test snapshots.
- **B — Author-written stable IDs.** Pro: durable references and readable diagnostics. Con: naming
  burden and collision risk.
- **C — Tool-generated stable IDs plus optional human aliases.** Pro: durable and low effort. Con:
  hand authors need a supported generation/check workflow.

**Recommendation:** C. IDs must be unique within a pack-qualified conversation namespace and never
derived from text or current position.

#### [DRC-5] Where may dialogue state live?

- **A — Only shared requirement facts/flags/variables.** Pro: one source of truth and easy saves.
  Con: temporary counters and local branch state pollute global namespaces.
- **B — Dialogue owns all narrative variables.** Pro: self-contained writing. Con: gameplay and
  dialogue state diverge and cross-system conditions become opaque.
- **C — Ephemeral conversation locals plus explicit reads/writes through registered shared-fact
  actions.** Pro: clear ownership and composability. Con: authors must distinguish local from durable.

**Recommendation:** C. A local is discarded at completion unless an explicit action commits a shared
fact.

#### [DRC-6] How are presentation commands separated from gameplay effects?

- **A — One unrestricted command registry.** Pro: simple and extensible. Con: skip, preview, resume,
  and validation cannot safely distinguish cosmetic from stateful commands.
- **B — Closed hardcoded command enum.** Pro: easy audit. Con: violates the project's open-registry
  rule and forces engine edits for content growth.
- **C — Two open registries with declared metadata:** presentation cue versus game action, including
  parameter schema, skip behavior, replay behavior, authority, and reversibility. Pro: extensible and
  auditable. Con: more registry contract work.

**Recommendation:** C.

#### [DRC-7] When do stateful dialogue actions commit?

- **A — Immediately as encountered.** Pro: intuitive scripting. Con: cancel, skip, crash, suspend,
  and rewind can duplicate partial consequences.
- **B — Buffer every effect until conversation end.** Pro: atomic. Con: later lines cannot naturally
  observe earlier effects and long scenes hide reward timing.
- **C — Explicit transaction boundaries: atomic conversation by default, with author-declared commit
  points for long/interactive scenes.** Pro: deterministic and flexible. Con: more author concepts.

**Recommendation:** A narrow v1 should use B; reserve C in the schema and runner after its rewind and
save semantics are specified.

**Owner ruling, 2026-07-27 — v1 accepted; post-v1 direction reserved:** v1 conversations are wholly
atomic. Choices, shared-fact writes, recruitment/custody transitions, inventory transfers, and every
other game action are journaled/staged and become authoritative together only when the conversation
completes successfully. Later entries evaluate against authoritative state plus the staged overlay.
Skip traverses the identical journal path and stops at unresolved choices. Failure or abandonment
discards the whole journal.

Fully flesh out transaction segments with explicit safe commit checkpoints (Option C) after v1. The
low-code tool will eventually present those as safe-save points rather than exposing transaction
internals to routine authors.

#### [DRC-8] What may skip/fast-forward do?

- **A — Skip presentation only; execute every game action in order.** Pro: state is invariant. Con:
  costly effects or choice-dependent waits require metadata.
- **B — Jump to the end state.** Pro: fastest. Con: requires a trustworthy projection of arbitrary
  commands and can miss intermediate conditions.
- **C — Authors mark commands skippable.** Pro: flexible. Con: easy to author a state-divergent skip.

**Recommendation:** A. Skip must stop at unresolved choices and must not alter outcomes.

#### [DRC-9] What is the save/resume boundary? — **RESOLVED 2026-08-13**

- **A — Conversations are atomic and cannot be saved mid-run.** Pro: smallest first build. Con: poor
  experience for long story scenes.
- **B — Save after any stable entry using conversation/node/entry IDs plus traversed choices.** Pro:
  fulfills `[DLG-11]`. Con: scene reconstruction and version migration are substantial.
- **C — Save only at explicit checkpoints/nodes.** Pro: authors control safe reconstruction; less
  state. Con: save availability may be uneven.

**Recommendation:** A for v1, C as the long-term contract. Explicit checkpoints can usually be every
completed line while allowing authors/tools to exclude unsafe spans.

**Owner ruling, 2026-07-27 — v1 save behavior:** the player may issue Save at any time, including
during an atomic conversation, but the save records only the most recent committed game checkpoint.
It does not serialize the in-progress conversation cursor, visited trail, presentation state, or
uncommitted action journal. Loading relaunches from that committed checkpoint, so the atomic
conversation starts again from its beginning. The save UI must explain this before confirming a save
during dialogue. No staged consequence may leak into the save.

Post-v1 Option C may add committed mid-conversation checkpoints. Loading then relaunches from the
most recent such checkpoint, never from an uncommitted line boundary. This supersedes the older
`[DLG-11]` promise that every completed line is automatically suspend-safe; that register must be
amended when this decision set is reconciled.

#### [DRC-10] How is text localized and connected to voice/portraits?

- **A — Inline source text.** Pro: excellent writing flow. Con: unstable localization identity and
  difficult VO tracking.
- **B — External text keys only, as currently planned.** Pro: stable localization. Con: low-code
  authors cannot read the conversation without resolving another file.
- **C — Stable line ID plus source-language text in the authoring view; export localized tables and
  optional VO/cue references keyed by line ID.** Pro: readable and durable. Con: compiler/editor work.

**Recommendation:** C; canonical pack JSON may store either source text or a table reference, but the
validator must produce a single stable line catalogue.

### B. Player and low-code-author experience

#### [DRC-11] How visible is Talk/recruit/capture eligibility to players? — **RESOLVED 2026-08-13**

- **A — Hidden unless currently actionable.** Pro: classic discovery and secrets. Con: guide
  dependence and accidental kills.
- **B — Always expose candidates, valid actors, and unmet requirements.** Pro: informed strategy.
  Con: spoilers and reduced discovery.
- **C — Authored disclosure policy (`secret`, `hinted`, `explicit`) using the existing hidden versus
  shown-disabled requirement vocabulary.** Pro: campaign-specific tone. Con: authors must write hints.

**Recommendation:** C, with `explicit` as the accessibility-friendly default and map/intel UI able to
show known Talk pairs.

#### [DRC-12] From what range and direction can Talk occur? — **RESOLVED 2026-08-13**

- **A — Adjacent and directed actor-to-target.** Pro: classic spatial puzzle. Con: repetitive and can
  force fragile positioning.
- **B — Bidirectional adjacency.** Pro: fewer soft failures. Con: target-turn initiation needs rules.
- **C — Authored interaction descriptor: directed/bidirectional, range predicate, allowed phases, and
  whether either side may initiate.** Pro: supports classic, radio, base, and enemy-initiated talks.
  Con: more validation.

**Recommendation:** C with a directed-adjacent template.

#### [DRC-13] What happens to the acting unit after a successful Talk/recruit/capture interaction? — **RESOLVED 2026-08-13**

- **A — Action ends.** Pro: predictable FE convention. Con: harsh for informational Talk.
- **B — Action remains available.** Pro: friendly. Con: movement/attack exploits after side changes.
- **C — Authored action-cost policy selected from validated templates (`end_activation`,
  `consume_minor_action`, `free_once`).** Pro: flexible and explicit. Con: depends on the future
  action-economy seam.

**Recommendation:** A for v1; reserve C rather than a boolean.

#### [DRC-14] How should choices communicate mechanical consequences? — **REFRAMED 2026-08-13**

- **A — Narrative labels only.** Pro: immersion. Con: irreversible recruitment/custody outcomes may
  surprise players.
- **B — Always show exact effects.** Pro: informed consent. Con: spoilers and UI noise.
- **C — Author supplies optional consequence preview and confirmation severity; accessibility can
  force previews for irreversible outcomes.** Pro: adaptable. Con: extra authoring fields.

**Recommendation:** C. Release, execute, dismiss, or permanently recruit should default to confirm.

#### [DRC-15] What dialogue history and replay surfaces exist?

**Superseded for V1 by `[DLUX-5]` (2026-08-09):** dialogue and combat public records interleave in
the one chapter-scoped log/`MapLedger` Rewind menu. Only retained affordable ledger checkpoints are
restore targets; a Rewind truncates the abandoned future. A cross-chapter conversation archive is a
separate later campaign-library feature, so Option C below is retained as historical research rather
than the V1 contract.

- **A — Current-scene backlog only.** Pro: matches `[DLG-1]`, small scope. Con: supports/story cannot
  be revisited later.
- **B — Global archive of every conversation.** Pro: player-friendly. Con: spoilers, branch variants,
  dynamic names, and state-dependent lines complicate replay.
- **C — Current backlog for all; author-tagged archive entries for supports/story, storing viewed
  route/variant metadata.** Pro: purpose-fit. Con: needs archive policy and replay-safe commands.

**Recommendation:** C; archive replay must suppress gameplay actions.

#### [DRC-16] What is the minimum authoring tool?

- **A — Hand-authored JSON plus schema errors.** Pro: cheapest foundation. Con: inaccessible to many
  campaign authors and poor for asset/ID discovery.
- **B — Godot list/form editor with typed entry insertion, pickers, validation, preview, duplicate,
  and templates.** Pro: captures most RPG Maker/FEBuilder value without graph complexity. Con: editor
  plugin maintenance.
- **C — Full node graph/timeline first.** Pro: rich scene visualization. Con: delays runtime and can
  obscure diffs.

**Recommendation:** B. “Map recruit talk,” “support rank scene,” and “capture outcome” wizards should
emit ordinary validated data, never special runtime objects.

#### [DRC-17] What validation must block pack activation/export? — **RESOLVED 2026-08-13**

- **A — Syntax and referenced-file existence only.** Pro: easy. Con: broken jumps, impossible choices,
  duplicate consequences, and invalid unit transitions ship.
- **B — Full static validation:** IDs, graph reachability, missing/empty option sets, requirement and
  action schemas, asset/text references, transaction/skip metadata, unsafe cycles, resume points, and
  recruit/capture target compatibility. Pro: safe low-code authoring. Con: some dynamic conditions
  remain unknowable.
- **C — B plus bounded simulation/test cases authored as fixtures.** Pro: catches state-dependent
  failures. Con: higher tool cost.

**Recommendation:** B is mandatory; C should be supported for campaign test suites and editor preview.

#### [DRC-18] How are reusable fragments handled?

- **A — Copy/paste entries.** Pro: simple. Con: dialogue and consequences drift.
- **B — Callable conversation nodes/fragments with parameters and an explicit return.** Pro: reusable
  greetings, tutorials, custody menus. Con: call stack/resume and localization context grow complex.
- **C — Only reusable event actions/templates, not prose fragments.** Pro: simpler narrative flow.
  Con: authors still duplicate common prose.

**Recommendation:** C for v1; add B only with typed parameters and recursion rejection.

### C. Recruitment state and transitions

#### [DRC-19] What concepts replace the overloaded `Unit.team` assumption?

- **A — Keep one faction/team field.** Pro: minimal code change. Con: temporary control, guests,
  charm, prisoners, roster membership, and diplomacy become boolean exceptions.
- **B — Separate `affiliation_id`, `controller_id`, `roster_status`, and `custody_status`; derive
  hostility and turn participation through registries.** Pro: accurately models the requested scope.
  Con: migration touches AI, objectives, turn order, UI, save, and targeting.
- **C — Keep affiliation, add a generic stack of unit-state overrides.** Pro: flexible effects. Con:
  opaque precedence and difficult save/debug behavior.

**Recommendation:** B. Temporary magical control may be an override/effect, but its resolved
controller must still be queryable through one authoritative service.

**Owner ruling, 2026-07-27 — provisionally accepted after deep review:** adopt five independent
dimensions: `affiliation_id`, `tactical_side_id`, `controller_id`, typed `roster_status`, and typed
`custody_status`. Tactical side owns encounter alignment, hostility lookup, objective presence, turn
group, targeting, threat display, and default AI coalition; controller owns only who supplies
decisions. Affiliation remains the durable political/organizational identity. Routine authors choose
validated transition presets rather than editing all five fields. Preserve stable unit identity
across every transition.

Minimum scenario matrix the implementation plan must cover: normal roster unit, allied-AI unit,
player-controlled map guest, temporarily controlled/charmed enemy, permanent recruit, third-faction
defection, carried/held enemy prisoner, released prisoner, player-roster member captured by an enemy,
and a unit controlled by a second local/remote human.

#### [DRC-20] What does a recruitment transition specify?

- **A — Target faction only.** Pro: concise. Con: silently implies permanence and roster policy.
- **B — A typed transition `{target_affiliation, target_controller, roster_policy, duration,
  expiration_outcome, activation_policy}`.** Pro: explicit and validates temporary recruitment.
  Con: more author fields.
- **C — Arbitrary action list.** Pro: maximum flexibility. Con: authors can create internally
  inconsistent combinations.

**Recommendation:** B, exposed through templates such as `permanent_join`, `map_guest`,
`turn_control`, and `defect_to_third_faction`.

#### [DRC-21] Which recruitment durations are required for v1?

- **A — Permanent player roster only.** Pro: smallest compatible slice. Con: does not fulfill the
  agreed recruitment definition.
- **B — Permanent plus until-map-end guest.** Pro: covers the most useful temporary case. Con: not
  turn-limited charm or scripted return.
- **C — Registry/predicate expiration supporting permanent, map end, N activations/rounds, fact
  change, conversation outcome, or explicit release.** Pro: complete. Con: complex lifecycle hooks.

**Recommendation:** B in the first implementation, with C-shaped serialized data and explicit
unsupported duration rejection.

**Owner ruling, 2026-07-27 — v1 accepted:** v1 supports `permanent` and `map_end` recruitment
durations. Every `map_end` transition requires an explicit expiry outcome: transition the named
dimensions to an authored destination or remove the unit from the map/campaign flow. Preserve stable
identity and all unpatched runtime state, including HP, progression, statuses, inventory,
relationships, history, and activation state. Expiry never grants a bonus action.

Disposition precedence is: death/permanent removal suppresses ordinary expiry; custody remains
authoritative and retains the intended post-release destination; a later permanent recruitment
supersedes temporary expiry; otherwise apply the authored outcome. All transitions and expiry data
ride the normal save/Rewind ledger. Defer generic `restore_prior`, nested duration stacks,
round/activation/fact-based durations, and invalid-restoration fallbacks until the broader temporary
control/effect design; reserve an authored expiry-policy model for that later work.

#### [DRC-22] When does a newly controlled on-map unit become actionable?

- **A — Immediately, regardless of prior activation.** Pro: satisfying. Con: double turns.
- **B — Preserve activation state; if already acted, remain done.** Pro: deterministic and hard to
  exploit. Con: a recruited enemy may do nothing until next round.
- **C — Transition authors select refresh/preserve/end, with UI preview.** Pro: flexible. Con:
  balance exploits and added author burden.

**Recommendation:** B by default; allow C only as an explicit registered action with warning-level
validation.

#### [DRC-23] What unit data survives control/faction changes?

- **A — Preserve the same runtime unit object, HP/status/inventory/growth/history/AI profile.** Pro:
  stable identity and intuitive continuity. Con: hostile-only AI/orders and inventory ownership need
  reconciliation.
- **B — Despawn and instantiate a roster template.** Pro: clean player-ready data. Con: loses battle
  state and risks duplication; SRPG tools historically require awkward copying when identity cannot
  cross affiliation.
- **C — Preserve identity/state, then apply an authored transition patch with validated allowed
  fields.** Pro: continuity plus controlled changes. Con: patch schema.

**Recommendation:** C; default patch is empty except controller/affiliation/roster fields.

#### [DRC-24] When and how does permanent roster insertion occur?

- **A — Immediately on the map.** Pro: save/state is straightforward and unit details work at once.
  Con: roster capacity, convoy, duplicate identity, and later betrayal need answers.
- **B — Mark pending and commit at map results.** Pro: transactional campaign state. Con: permadeath,
  retreat, suspend, and mid-map deployment consumers see an ambiguous guest.
- **C — Immediate membership in a typed `pending_member` status; results finalize or disposition
  rules resolve it.** Pro: explicit and reversible. Con: adds a roster state.

**Recommendation:** C if roster limits or map-failure rollback exist; otherwise A with ledger-backed
rollback. Decide alongside save/rewind semantics.

**Owner ruling, 2026-07-27 — v1 accepted:** a successful `permanent` recruitment assigns full
`roster_status = member` when the atomic conversation/action journal commits. Do not implement
`pending_member` in v1. The same stable runtime unit becomes the roster member; duplicate identity
and destination/capacity policy validate before commit. Prefer `join_and_bench` when deployment—not
total roster size—is the actual limit.

Survival/results-dependent joins use `guest` followed by a separate permanent transition when the
authored requirement passes. A permanently recruited unit that dies later in the same map remains a
recruited roster member with the normal campaign death/injury disposition; recruitment history is
not erased. Save includes committed membership, while Retry/Rewind restore it through the existing
map ledger. Retreat follows the campaign's ordinary progress-retention rule. Convoy, deployment,
support gain, trading, prep access, and other capabilities remain separately requirement-gated rather
than being implicit consequences of membership.

#### [DRC-25] How are recruitment requirements authored?

- **A — Fields on the recruitable unit.** Pro: easy discovery. Con: cannot express map/route/pair-
  specific circumstances without bloating unit data.
- **B — Only on triggers/events, as `[RCR-4]` proposes.** Pro: composable shared predicates. Con:
  author tools may not show all ways a unit can join.
- **C — Unit supplies identity/default hints; transition opportunities own authoritative predicates,
  outcome, disclosure, and eligible actor/target selectors.** Pro: clean split and strong author UX.
  Con: cross-reference validation needed.

**Recommendation:** C, retaining the intent of `[RCR-4]` while removing a potentially misleading
`recruitable` truth flag.

#### [DRC-26] Which sources may recruit?

- **A — Talk only.** Pro: focused. Con: excludes automatic joins, villages, choices, support/stat
  checks, purchases, charm, and scripted defections.
- **B — Any registered event action can invoke the same transition.** Pro: matches `[RCV-4]` and
  Three Houses-like recruitment. Con: requires context validation.
- **C — Each source gets a bespoke recruit path.** Pro: tailored UI. Con: duplicated state logic.

**Recommendation:** B. Source-specific templates should compile to the same transition action.

### D. Capture and prisoner lifecycle

#### [DRC-27] Which capture-entry mechanics are in scope?

- **A — Existing planned path only: non-lethal would-be kill applies sleep, then carry off-map.** Pro:
  reuses Source/Style and carry. Con: two-step, may make capture eligibility unclear, and conflates
  incapacitation with custody.
- **B — Thracia-like Capture combat command that resolves directly into carried custody with combat
  penalties.** Pro: clear tactical choice and risk. Con: new combat forecast/action behavior.
- **C — Registered capture methods: non-lethal/carry, direct capture attack, surrender, dialogue,
  objective/script.** Pro: author flexibility and clean outcome. Con: broader initial build.

**Recommendation:** C-shaped data, with A as the first method and a first-class `take_custody` action
so dialogue/surrender do not fake sleep.

#### [DRC-28] What determines physical capture eligibility?

- **A — Fixed size/build comparison.** Pro: legible Thracia-style rule. Con: excludes magic,
  restraints, surrender, and story capture.
- **B — Status only (incapacitated/surrendered).** Pro: simple. Con: any unit can carry any target.
- **C — Registered requirement predicate per capture method, with shared selectors for status,
  relation, size/carry capacity, immunity/tags, equipment, HP, and actor traits.** Pro: open and
  authorable. Con: UI must explain failures.

**Recommendation:** C with a standard `incapacitated_and_carryable` profile.

#### [DRC-29] What is the on-map custody representation?

- **A — Captive becomes cargo on a carrier; one identity remains in map state.** Pro: tactical rescue,
  escape, and carrier penalties; aligns with carry. Con: requires carried-unit targeting and save.
- **B — Captive is removed immediately into a map prisoner list.** Pro: simpler board state. Con:
  loses escort risk and recovery play.
- **C — Capture method selects `carried`, `restrained_on_tile`, or `removed_to_custody`, each backed
  by one custody record.** Pro: broad scenarios. Con: more states and objective hooks.

**Recommendation:** A for combat capture; allow B for scripted surrender. Reserve C's shared custody
record so the two paths converge.

#### [DRC-30] What happens to a captive's inventory?

- **A — Immediate automatic transfer to captor/convoy.** Pro: clear reward. Con: capacity, ownership,
  escape, release, and ethics become awkward.
- **B — Inventory remains with captive until an explicit search/confiscate action.** Pro: meaningful
  custody choice and reversible release. Con: more UI/actions.
- **C — Authored custody policy (`retain`, `trade_while_carried`, `confiscate_to`, `drop`) with
  capacity/overflow handling.** Pro: supports Thracia and story prisoners. Con: complexity.

**Recommendation:** B as default, C as the contract. Confiscation must be ledgered and release must
not silently duplicate or delete items.

**Owner ruling, 2026-07-27 — simplified v1 accepted:** a captive retains its ordinary inventory and
item-instance ownership. Do not build confiscation, escrow, automatic restoration, a custody locker,
or a separate prisoner-inventory UI in v1. Instead, the interaction resolver treats an on-map captive
held by the acting unit's side as an eligible **target** for the existing Trade interaction, as though
both units had the same controller for Trade permission only. Do not actually mutate the captive's
`controller_id`, tactical side, or custody state.

V1 Trade is the normal two-way transaction unless later narrowed: the player may take from or give
items to the captive, subject to existing inventory capacity and protected/bound-item rules. The
captive cannot initiate Trade while custody suppresses its activation. Every transfer uses the
ordinary item-instance ledger and therefore saves/Rewinds normally. Release, escape, rescue, or
recruitment carries whatever inventory the captive currently holds; items previously traded away stay
with their real current holders, with no duplication or automatic restitution. UI must warn before
releasing or exchanging a captive who still holds player-controlled items.

**Owner ruling, 2026-07-27 — bring ordinary Trade into v1:** implement an FE7-style on-map Trade
interaction rather than a captive-only inventory panel. An acting unit may select an adjacent map
unit or a captive, Rescue passenger, or Pair Up support unit occupying the actor's space or an
adjacent space, subject to the applicable control/custody permission. After choosing the two
participants, the player selects an item or empty slot in one inventory and swaps it with an item or
empty slot in the other inventory. Item-instance ownership changes only when the swap transaction
commits; an empty-slot swap is the ordinary move operation, not a separate transfer path. Capacity,
bound/key-item restrictions and their authored forced-effect fallbacks, ledger recording, Save, and
Rewind all use the same general Trade service. A custody-suppressed captive may be selected as the
other participant but cannot initiate Trade.

V1 also follows FE7's partial-action precedent. A Trade session may perform multiple slot swaps with
its selected partner. The first committed swap marks the actor as having traded, commits the actor's
current destination, prevents ordinary movement cancellation/relocation, and prevents initiating a
second Trade session during that activation; the actor may still choose a permitted concluding
action. Entering the Trade screen and leaving without a committed swap applies no Trade cost or
movement lock. Any Canto/move-again behavior after Trade is decided by the ordinary registered
post-action-movement policy and remaining movement, not by a Trade-only exception. Receiving items
does not consume the other participant's activation.

Keep the following as author-tunable policy fields after v1, backed by an open interaction-policy
registry rather than branches embedded in the Trade UI: target range/metric, allowed relation and
occupant roles, whether a successful session ends or partially consumes activation, repeat-session
limit, post-action movement policy, and designated-convoy provider range/tags. Ship one validated
`fe7_trade` preset for v1; do not expose unsupported combinations until their action-state and AI
behavior are implemented and validated.

Trade target discovery should reuse a shared spatial-target query extracted from `GridManager`'s
existing attack/staff ring and target-filter pattern. The current staff path is the closest reusable
selection/overlay seam, but its heal-specific equipped-weapon, missing-HP, and alliance filters must
not become Trade rules. The current aura implementation supplies only a private Manhattan helper and
unimplemented effect stubs, so Trade should not depend on `SkillHandler`. A generic geometry query
can later serve staff, aura, Trade, Talk, Rescue, and other registered interactions, with each caller
composing its own requirements and virtual occupants (Pair Up, Rescue, custody).

#### [DRC-31] What can happen to a captive during and after a map?

- **A — Hold until map end, then automatically become recruitable.** Pro: matches the old plan.
  Con: violates custody/recruit separation and erases player agency.
- **B — Campaign-authored automatic disposition at map end: release, transfer, escape, remain held,
  or scripted outcome.** Pro: story control. Con: limited player agency.
- **C — A custody roster with authored available actions and requirements: hold, move, release,
  exchange, ransom, interrogate, persuade/recruit, trial, or other registered outcomes.** Pro: full
  player/author expressiveness. Con: substantial prep/base UI and sensitive-content policy.

**Recommendation:** B for the first slice, with a minimal custody record; C is the expansion target.
Recruitment is one possible registered outcome, never the automatic definition of capture.

**Owner ruling, 2026-07-27 — v1 prison loop accepted:** resolve map completion in this order:

1. Run the map's ordinary authored end-of-map events while captive units and custody contexts remain
   addressable. Those events may recruit, release, transfer, remove, or otherwise settle any captive
   through normal registered actions.
2. After the event runner completes successfully, sweep only residual captives. Transfer every
   eligible non-bound, non-protected/key equipment item instance from each residual captive to the
   party convoy through the ordinary ledger. Bound and protected/key equipment stays attached to the
   prisoner. No item is copied or deleted; convoy overflow must use the campaign's normal safe
   destination/failure policy.
3. Move each residual captive's full stable unit state and remaining inventory into the campaign
   custody roster.
4. Expose those records through a minimal **Prison** tab under the between-map **Explore** menu.

The Prison tab is a visitor/conversation launcher, not a separate persuasion simulation. The player
selects an eligible roster visitor, then a prisoner or an authored guard interaction. Dialogue context
binds `visitor`, `prisoner`, `guard`, and `custody_owner` roles. Shared requirements decide which
conversations are hidden, shown-disabled, or available; ordinary dialogue actions/facts handle
recruitment, release, custody transfer, relationship changes, costs, attempt limits, cooldowns, and
story outcomes. A guard may be a stable unit or named-speaker/stage role as authored. Explore's
existing activity/time policy—not the prison panel—decides whether a visit consumes time.

Prisoners retain stable unit IDs and participate in the ordinary relationship graph before, during,
and after custody. Dialogue requirements may inspect those relationships, and explicit authored
actions may change their points/ranks; recruitment, release, or custody transfer preserves the same
record. Imprisonment grants no automatic adjacency, deployment, cadence, or end-turn relationship
growth. A Prison visit changes a relationship only when its authored conversation/action says so.
Do not create a parallel prisoner persuasion score; campaigns that want persuasion progression build
it from relationships, facts/resources, or another registered system.

The panel must show custody identity, remaining bound/protected items, known conversation
availability, and the selected visitor; it does not hardcode Recruit, Persuade, Interrogate, Execute,
or other universal outcome buttons. Rich facilities, passive timers, generic persuasion math,
ransom economies, and systemic escape remain later options.

**Owner clarification, 2026-07-27 — Explore activity model:** Explore is a Prep Hub option, not a
separate walkable base mode. It lets the player select either a deployable unit or a non-deployable
camp follower and send that visitor through one of the current campaign node's registered
activities. The activity vocabulary is an open registry. A campaign supplies campaign-wide default
activities; cadence processing may modify those defaults; each campaign node may add, remove, or
override activity definitions for that node. Prison visits are ordinary registered Explore
activities and therefore inherit the same visitor eligibility, availability, requirement, cost,
cadence, and node-override machinery rather than creating a parallel prison scheduler.

#### [DRC-32] Can prisoners escape or be rescued, and who controls them?

- **A — No agency while captive.** Pro: simple. Con: escort/custody lacks counterplay.
- **B — Deterministic authored events only.** Pro: story-friendly and testable. Con: not systemic.
- **C — Custody security and escape/rescue predicates drive events; a captive has no normal turn
  controller until released, but remains targetable by defined interactions.** Pro: systemic and
  data-driven. Con: AI/objective complexity.

**Recommendation:** B initially; design the custody record and signals so C does not require changing
identity or save format.

**Owner ruling, 2026-07-27 — carrier loss, escape, and map-end custody:** when a captor/carrier falls,
release the captive onto the carrier's occupied location as part of the fall/displacement resolution;
the released unit may remain asleep or retain any other independently applied condition. If the unit
then escapes, resolve its disposition through the author's selected escape-cause displacement rule.

At map end, do not apply one universal residual-captive outcome. After ordinary end-of-map events,
the author selects the treatment of still-captive units per relevant relation in the aggression
matrix. This may release, transfer, retain, remove, or otherwise settle a captive. Required-survival
evaluation occurs after these outcomes: an authored prisoner disposition may count as that unit's
death and may consequently turn an apparent victory into defeat.

**Owner clarification, 2026-07-27 — disposition lookup fallback:** an authored disposition rule may
select another relevant five-dimensional field or shared predicate when the scenario requires it.
If no more-specific rule resolves, fall back to the ordered relationship from the current custody
owner's `affiliation_id` to the captive's `affiliation_id` in the aggression matrix. The relationship
is directional; transferring custody before this phase changes the owner side of the lookup. A
node/unit-specific authored rule may override the campaign-wide relation result. Missing relations
must resolve through a declared campaign fallback and produce validation diagnostics rather than
silently guessing from tactical color, controller, or temporary recruitment.

#### [DRC-33] How do objectives, AI, save/rewind, and versioning observe these transitions?

- **A — Each system listens for faction change/death/capture separately.** Pro: local changes. Con:
  missed cases and order-dependent bugs.
- **B — One authoritative unit-transition service emits a structured before/after record and applies
  it transactionally; objectives, turn order, AI, UI, roster, dialogue facts, ledger, and saves consume
  the same result.** Pro: deterministic, testable, and compatible with `[VIL-8]` hostile-presence
  objectives. Con: central service design work.
- **C — Recompute everything from the unit each frame.** Pro: fewer signals. Con: cannot explain cause,
  disposition, history, or rollback.

**Recommendation:** B. The record should include cause, actor, target, old/new affiliation,
controller, roster/custody/activation states, inventory transactions, duration/expiry, and emitted
facts. Pack schema versions must reject or migrate unsupported transition/action versions before
activation.

**Owner ruling, 2026-07-27 — objective milestone vocabulary:** objective and event requirements must
distinguish at least these registered milestones rather than treating `captured` as a loose flag:

- `incapacitate`: satisfy either by a would-be kill or by an authored registered condition. It may be
  combined with `do_not_kill` to require the condition-only route.
- `capture`: establish custody through a registered capture method.
- `extract`: deliver or remove a captive through an authored extraction route.

Each milestone is independently observable, may be required without the later milestones, and must
carry structured cause/actor/target data for objective re-evaluation and authored follow-up events.

**Owner ruling, 2026-07-27 — extraction lifecycle trigger:** emit `extract` whenever a unit currently
in captured custody is removed from tactical-map participation without dying. V1 recognizes at least
these causes:

- the captor/carrier escapes while carrying the captive;
- map-end resolution removes a still-captured unit from the tactical map;
- the carrier confirms a special turn-ending Extract action while eligible on an authored Escape or
  Extraction tile.

The structured result records the cause, carrier/custody owner, captive, source tile/zone, and initial
off-map destination/disposition. A later map-end disposition may still release, transfer, retain, or
kill that extracted prisoner; extraction records successful live removal from the tactical map, not a
guarantee of later survival or recruitment. Death/removal as death never emits `extract`.

`extract` may be a required component, bonus condition, prerequisite for a compound victory rule, or
the sole victory condition **when the map provides at least one valid Escape or Extraction location
capable of producing the required extraction**. Content validation rejects a sole-extract victory if
no compatible authored location/action route exists or if its target selectors make every route
unsatisfiable.

Keep two distinct tile actions. **Escape while carrying** removes both carrier and captive, emitting
Escape for the carrier and Extract for the captive. **Extract captive** removes only the captive,
leaves the carrier on the tile, frees its carry slot, emits Extract for the captive, and ends the
carrier's activation. The zone/activity definition declares which actions it offers; neither action
is inferred merely from a tile's label.

**Owner ruling, 2026-07-27 — extraction objective membership:** extraction requirements use the
shared event-filter/selector structure and may name units, match registered predicates/tags, require a
fixed count, require every member of a set, or use another registered quantifier. The default target
set is snapshotted when the map begins, so later reinforcements or state changes do not silently
increase the requirement. Dynamic membership is an explicit author option and must be disclosed in
the objective UI; validation must distinguish an intentionally empty dynamic set from an
unsatisfiable snapshot objective.

**Owner ruling, 2026-07-27 — milestone versus current-state defaults:** the standard Incapacitate and
Capture objective templates are dynamic state requirements, not latched achievements.

- Incapacitate is satisfied while the target is dead or currently has a registered qualifying
  incapacitating condition. Removing/recovering from that condition revokes satisfaction; combining
  it with `do_not_kill` excludes the death route.
- Capture is satisfied only while the target is currently in matching custody. Release, rescue,
  escape, or custody transfer outside the required selector revokes satisfaction.
- Extract remains a latched structured milestone because it records completed live removal from
  tactical-map participation.

The transition/event history may still expose explicit `has_been_incapacitated` and
`has_been_captured` predicates for authored stories, bonuses, or compound rules, but low-code
Incapacitate and Capture objectives default to current state. Objective UI must distinguish ongoing
state requirements from completed milestones.

**Owner ruling, 2026-07-27 — objective reevaluation timing:** reevaluate dynamic victory and defeat
requirements after each atomic action, combat exchange, conversation, multi-target effect, or event
chain commits; never interrupt the resolving operation between its internal steps or targets. If the
new state qualifies for map completion, enter the atomic map-end pipeline. End-map events and captive
dispositions may change the staged state, after which final victory/defeat evaluation determines the
published result. Simultaneous victory and defeat use the map's authored precedence policy.

**Owner ruling, 2026-07-27 — key-item restriction contract:** a key/protected item designation must
state both (1) which player operations are forbidden and (2) the authored fallback/disposition when
an engine-authorized effect nevertheless performs that operation. The UI explains the player-facing
restriction; registered actions use the explicit fallback instead of silently failing, duplicating,
or destroying the item. This contract applies when a key item remains attached to a prisoner as well
as when it is held by an ordinary unit or the convoy.

**Owner ruling, 2026-07-27 — prisoner-held key-item default, pending author testing:** track key-item
availability on three independent axes: `present`, `requirement_accessible`, and `player_usable`. A
key item retained by a prisoner defaults to present and available to requirements/objectives/dialogue,
but unavailable for ordinary player use. Authors may override each axis or require a particular
availability level in a predicate—for example, an objective may require `player_usable` rather than
mere campaign possession. Validate this default with campaign-author testing before treating it as a
long-term preset; the policy must prevent both silent key-item loss and accidental use through the
Prison screen.

**Owner ruling, 2026-07-27 — atomic map-end resolution:** v1 treats the entire map-end resolution as
one transaction: provisional victory, authored end-map events, relation-specific captive
dispositions, residual-prisoner processing, final victory/defeat re-evaluation, and result commit.
Every phase may observe the staged overlay produced by earlier phases, but no phase becomes
authoritative independently. Failure, abandonment, or loading a save discards the complete staged
resolution and relaunches it from the preceding committed checkpoint. In particular, the game must
not publish victory before a prisoner disposition that can violate required survival has resolved.

Represent these as named pipeline phases from the start and reserve phase-boundary commits as the
post-v1 upgrade when demand or available implementation time justifies them. Review and reuse the
dialogue runner's action journal, staged-state overlay, validation, and commit/rollback primitives
where their contracts fit. The map-end orchestrator remains a broader workflow that may invoke
atomic conversations; it must not disguise all map-end processing as dialogue or couple transaction
correctness to a presenter.

## Cross-question decisions required before an implementation plan

The answers should be resolved in this order because later choices depend on earlier ones:

1. `[DRC-19..21]` — unit state dimensions and recruitment transition contract.
2. `[DRC-27..33]` — custody record, entry methods, outcomes, and authoritative transition service.
3. `[DRC-1..10]` — dialogue runner, data, state, effects, transaction, and resume boundaries.
4. `[DRC-11..18]` — player disclosure and minimum authoring/validation tools.
5. `[DRC-22..26]` — activation, preservation, roster commit, requirements, and recruitment sources.

An implementation plan should not be written by merely accepting every recommendation. It should
record the owner's selected option for every `[DRC]` item, reconcile dependencies between selections,
then divide delivery into independently testable slices. At minimum, tests must cover stable identity,
temporary-control expiry, already-acted conversion, third-faction hostility, capture/release inventory
round trips, map-end custody, objective re-evaluation, suspend and Rewind, skip equivalence, dialogue
branch resume, invalid pack rejection, and replay with stateful commands suppressed.

## Post-v1 feature option: `free_text_dialogue`

`free_text_dialogue` is a parked, optional input provider for the dialogue decision seam. A human
types a natural-language response; a small local resolver maps it to **one currently available,
authored choice ID**. The model never writes dialogue branches, constructs actions, changes facts, or
executes commands. The normal dialogue runner validates and commits the selected authored option.

### Required seam

- Dialogue requests decisions from an abstract participant-owned provider; v1 implements only the
  ordinary choice-menu provider.
- Later providers may include hotseat, remote, AI, and `free_text_intent` without changing authored
  choice execution.
- Each request supplies the conversation/node/entry IDs, decision-owner role, localized prompt,
  currently available options, and explicitly approved context.
- Each result supplies an available `option_id`, confidence, input method, resolver identity/version,
  and optionally the original player text subject to privacy policy.
- `decision_owner` is role-based (`initiator`, `target`, `speaker_controller`, `all`, etc.), never a
  hardcoded player number. Talk directionality and choice ownership remain separate concepts.

### Authored intent metadata and low-code tooling

Each inferable option may define a plain-language intent summary, positive examples, negative or
confusable examples, keywords, supported locales, minimum confidence, and whether confirmation is
mandatory. The low-code editor provides a test box that shows ranked option matches and warns when
examples collide. Campaign fixtures pair sample player text with the expected authored option so a
resolver/model update cannot silently change narrative outcomes.

Prefer the smallest sufficient resolver: rules/keywords, then local sentence embeddings, then a
small classifier or reranker. A tiny generative LLM is only a later fallback; constrained semantic
classification is smaller, faster, easier to test, and cannot invent an unauthored option.

### Player safety and fallback

- High confidence may preselect the interpretation; medium confidence presents the top candidates;
  low confidence or no match falls back to the normal authored list.
- The interpreted option and original response are shown before commit. Irreversible or sensitive
  outcomes always require confirmation regardless of confidence.
- Accessibility and campaign policy may disable inference entirely. Manual selection always remains
  available.
- Prompt-injection-like text has no authority: the provider's only legal outcome is an available
  authored option ID or `no_match`.

### Determinism, save, replay, privacy, and multiplayer

- Persist the committed authored option, input method, and resolver version. Never rerun inference on
  load or replay; Rewind returns to the unresolved choice.
- Raw player text is optional private data, not required for deterministic state. A campaign must opt
  in before placing it in a visible log or save.
- In remote play the authoritative instance validates the option and, when classification affects
  fairness, performs the classification. Other participants receive the authored result unless the
  conversation explicitly shares the raw response.
- Resolver/model files, licenses, supported platforms, resource budgets, and version compatibility
  are product/tooling concerns outside campaign logic. Web and low-resource targets may expose only
  the normal menu provider.

### Scope boundary

This option is deliberately post-v1. V1 only needs the abstract decision-provider seam and ordinary
menu implementation. `free_text_dialogue` depends on the stable dialogue runner, choice intent
metadata/fixtures, localization policy, save/replay result contract, and—if used remotely—the later
authoritative multiplayer input layer. It must never become a required path for completing a campaign.

## Deep-review addendum: dialogue profile boundary

**Owner ruling, 2026-07-27 — accepted:** conversation profiles own **presentation plus interaction
policy**, never hidden gameplay mechanics. An open profile entry may define presenter/layout,
required and optional participant roles, allowed invocation contexts, pacing/input defaults,
history/archive/replay policy, completion/return behavior, decision-owner defaults, stateful-action
permissions, and—after v1—transaction-policy defaults. Conversations or their invoking events must
still explicitly author every fact write, relationship change, item/resource transfer, recruitment,
custody transition, death/disposition, or other gameplay effect.

Begin with `story_scene`, `map_talk`, `support`, `prison_visit`, and `battle_bark`. Replay always
suppresses stateful actions. Acting-unit cost, support-rank gates/rewards, Explore time cost, prison
attempt limits, and other subsystem mechanics remain with their owning interactions/actions rather
than the profile. Profiles provide validated defaults and hard constraints; conversations may
override safe presentation defaults but may not silently bypass constraints.

Keep profiles distinct from authoring templates. `recruitable_enemy_talk` and
`attempt_prison_recruitment` are low-code templates that emit ordinary interactions, requirements,
conversations, and actions using `map_talk` or `prison_visit`; they are not runtime profile types or
special dialogue interpreters. Campaign packs may register compatible profiles without adding an
engine switch.
