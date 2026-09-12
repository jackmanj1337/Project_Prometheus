---
Role: dated
Type: design
Status: Accepted — precedence diff; the `CEUI` walk (S10/S11) has not yet run
Last verified: 2026-08-14
Tracker: S9-CEUI-PRECEDENCE-DIFF-2026-08-14-2026-08-14
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `CEUI-1..40` + the twelve re-scoped `NMTE` questions — Precedence Diff Before the Owner Walk

Sixth `DOC-014` check in this series, after
[`skf_drc_precedence_diff_2026-08-13.md`](skf_drc_precedence_diff_2026-08-13.md),
[`drc_group_a_precedence_diff_2026-08-13.md`](drc_group_a_precedence_diff_2026-08-13.md),
[`drc_groups_bcde_precedence_diff_2026-08-13.md`](drc_groups_bcde_precedence_diff_2026-08-13.md),
[`rpd_precedence_diff_2026-08-13.md`](rpd_precedence_diff_2026-08-13.md) and
[`nmte_precedence_diff_2026-08-14.md`](nmte_precedence_diff_2026-08-14.md). This is `S9` of
[`research_and_discussion_sequencing_2026-08-13.md`](../plans/research_and_discussion_sequencing_2026-08-13.md)
— the largest check in the programme, and the last one before `UBS-8`'s gate can lift.

**Sources diffed.** `CSA-1..37`
([register](../registers/campaign_sprite_authoring_open_questions_2026-07-30.md), complete
2026-07-31); the Campaign Library Branch K rulings
([decisions](campaign_library_ux_decisions_2026-07-24.md), 2026-07-25 — editor distribution,
`CL-ADV-01/02/03`); `ICO-1..6`; `EXT-1..6` and the `AGENTS.md` open-registry principle;
`EPUX-02/03/04/06/11/15/21/24/28`
([bundle](prep_economy_bundle_comparative_research_and_questions_2026-07-25.md), ratified
2026-07-26); `PHB-5/7`; the **two-primitive ruling** (2026-08-13); `UUI-1..19`
([register](../registers/unified_ui_decisions_2026-08-12.md), 2026-08-12); `TSV-1..24`,
`SHC-1..8`, `CUR-1..7` (2026-08-13); `L10N-1..18` (2026-08-13); `CRD-1..10` (2026-08-13);
`RPD-1..18` including `RPD-15` (2026-08-13); `DLUX-10..16` and `DRC-2/4/9/11/17`
(2026-08-09 / 2026-08-13); `TEXT-01..15`; `LEG-4`; and the **built code** —
`scripts/registries/*`, `scripts/save/{SavePolicy,AutosaveTriggerRegistry,MapLedger}.gd`,
`scripts/ui/`, `scripts/autoloads/TextEntryService.gd`, `CampaignPackRegistry.gd`.

## Bottom line

**`CEUI-1..40` cites two ratified ids in forty questions** — `CSA-11/17` on `CEUI-32` and
`CSA-30/31` on `CEUI-39` — and its comparative research cites three. Nothing else. No `UUI`, no
`EPUX`, no `ICO`, no `CL-ADV`, no `DLUX`, no `TSV`, no `L10N`, no `CRD`, no `TEXT`, and no
reference to the **two-primitive ruling**. It is not as bad as `RPD` (which cited nothing at
all), and unlike `RPD` it did read one register properly. But it is the *widest* miss in the
series, because the editor is downstream of more ratified surface than any other screen: it is
the only surface that touches assets, licensing, validation, localization, transactions,
persistence and distribution at once.

**Three things follow, and they are different in kind.**

1. **The packet is mostly not wrong — it is mostly late.** Its recommendation is "A" on
   thirty-eight of forty questions, and where a ratified decision exists, A is usually that
   decision restated as an option. Nine questions are wholly or largely answered already. The
   cost of walking them as written is not a bad ruling; it is a second ruling on a settled
   thing, which is the divergence `DOC-014` exists to prevent.

2. **Five collisions are real and each needs a side chosen.** The editor's minimum viewport is
   now specified three incompatible ways; the editor is ruled to ship to **web**, where a third
   of section B/F's questions assume a filesystem that does not exist; an editor Undo stack is a
   **third** persistence primitive beside the two ratified on 2026-08-13; `CEUI-15` cites "the
   shared transaction vocabulary" when two different ratified vocabularies answer to that name;
   and `CEUI-31`/`CEUI-22` contradict `DLUX-13`/`DLUX-11` on template propagation and on
   hand-edited JSON.

3. **Six questions the packet never asks decide more than most of the ones it does.** Chief
   among them: **does Menu Scale apply to the editor?** If it does, `[CEUI-5]`'s `1920×880`
   floor does not protect the layout at all, because Menu Scale multiplies the density tokens
   without changing the size class — a four-region editor at `2.0×` is an effective `960×440`
   and the minimum-size state never fires.

**One structural note about the twelve `NMTE` questions.** `[NMTE-S1]` moved them here on the
grounds that the editor is the only non-modal consumer. Diffing them against the editor's own
ratified context suggests most of them **collapse rather than transfer**: `TextEntryService`
exists to arbitrate an *on-screen keyboard*, and `[NMTE-S2]` removed the on-screen keyboard from
the editor. That is good news for the walk (it is a much smaller second half than `S11` was
scoped for) and bad news for a ratified decision — see §4.5.

---

## 1. Closed by precedence — do not ask these

### 1.1 `CEUI-32` — where the asset manager lives was ruled on 2026-07-30

`[CSA-11]` **RESOLVED, owner, option A**: "the tool lives inside our campaign editor, not the
general Godot editor", with the pure `RefCounted` core underneath kept headless-testable, and
`IMP-EDITOR-PLUGIN-2026-07-20` **superseded and retired** (the tracker row is `completed`).
`CEUI-32`'s option A is that ruling restated; option B (separate executable) is the
already-rejected `EditorPlugin` shape wearing different clothes.

**Do not ask.** Record `CEUI-32 = CSA-11` in the register and move on. The genuinely open part is
not *where* but *how much room it gets* — see `CEUI-35` in §2.

### 1.2 `CEUI-6` — the editor/library relationship was ruled on 2026-07-25, in more detail than the question has

Branch K of the campaign-library walk ruled all of this:

- **Full integration in v1, gated at RUNTIME not build time.** The editor ships in *all* presets
  — Steam, Deck, **web** included — because "can I edit here?" is a runtime property.
- **The editor entry is visible everywhere by default**, with a dismissible non-blocking warning
  and a Settings row a player may use to hide it or auto-hide it.
- **Installed packs are immutable.** Editing installed content is
  **unpack-to-editable-working-copy → re-export**, unchanged from Branch B.
- **`CL-ADV-01`:** unpacked loose-folder development packs load **only under developer mode**,
  are **marked as a dev source**, and **never activate in a normal player session**.
- **`CL-ADV-03`:** id+version collisions are **blocked** on the import path too; dev/locally
  modified packs are **badged**; no "unsigned" language anywhere.

`CEUI-6`'s option A is the ratified model, and its "Open source draft action only where one
exists" is superseded by the working-copy model, which is stronger. **Do not ask; cite.**

### 1.3 `CEUI-39` — the onboarding *choice* is ruled; only one residue survives

Three `CSA` rulings, all 2026-07-30/31, already compose into option A:

| Ruling | Content |
|---|---|
| `CSA-30` | Fork-first authoring — complete copy plus per-hop licence history. "Nobody starts from scratch." |
| `CSA-31(f)` | **No hints.** Schemas ship blank; first-time authors **fork a public pack**. |
| `CSA-33(a)` | An empty library offers **import only**; the editor is reached separately. |
| `LEG-4` | "Public packs" means `Campaign_Pack_0`. `Campaign_Pack_FE` is internal-only and **must never be offered in-product as a fork target** — which `CEUI-39` already knows. |

**The residue worth ten minutes:** `CSA-31(f)` ruled *no hints*, and `CEUI-39`'s option A proposes
*a guided walkthrough* (identity → map → node → roster → validate → fixture → provenance →
export). Those are not obviously the same thing — a guided task list over a forked pack is not a
content hint — but they are close enough that the walk should say which, once, rather than let a
build slice decide. See also §4.3: the register assumes an answer to the content-palette question
that was never recorded.

### 1.4 `CEUI-2` — the option set is closed even though the question reads open

Option C ("hand-coded fixed categories") is the closed-enum smell that `AGENTS.md` bans by name
and `EXT-1..6` ratified against. `CSA-17(a)` already ruled the specific case: **one registry**
serving the catalogue, the resolver groups and the manager UI, rather than "three lists that
drift". Option B (raw pack folders) additionally leaks a storage layout that `ICO` treats as an
engine detail.

**Ask only the residue:** the "advanced *Show file*" affordance the recommendation adds — which
has no meaning in the web build (§3.2) — and whether non-asset content families are enumerated
from the same registry as asset kinds, which they must be for the same reason.

---

## 2. Narrowed or reframed — ask the residue, not the question as written

### 2.1 `CEUI-7`, and every question written for a collapsing layout

`[CEUI-5]` (ruled 2026-08-14) removes the compact-desktop mode entirely. `CEUI-7`'s
recommendation still ends "collapsing labels to icons with accessible names **at the floor**" —
there is no such floor behaviour any more. But do not simply delete the clause: `[L10N-7]` raised
the required text-extent budget to **1.4× proven against a pseudolocale at every durable
viewport**, so a header of seven labelled actions still has a real width problem in a translated
build, at the *only* viewport the editor has. Ask the label/icon question on `L10N-7` grounds,
not on floor grounds.

### 2.2 `CEUI-9` and `CEUI-11` — the schema-generated form and the typed picker are half-built decisions

`[DLUX-12]` (2026-08-09) ruled the authority boundary for the dialogue editor: **typed shared-
Requirement selectors and registered game-action forms generated from the owning registry's
schema**, no arbitrary script, no anonymous globals, no raw mutation expressions. `DRC-6` confirms
it. That is `CEUI-9` option A, already ruled for one content family; the question is whether it
generalizes (it must, by `EXT`) and what the bulk-edit table view is allowed to touch.

`CEUI-11`'s typed picker is a **duplicate-mechanism risk**, the shape this project has now caught
five times. `[TSV-10]` ruled a **shared selector contract** with stable instance IDs, and
`[TSV-24]` ruled focus restoration across recomposition; `[EPUX-04]` made list/detail/focus/
selection shared shell primitives keyed by an opaque stable record id. None of it exists in code
yet (`TSV`'s ruled set names it as unbuilt). The editor picker should **be** that selector, not a
second one — and if the editor's needs are what finally force the selector to be built, that is a
sequencing fact worth recording, not a reason to build a private one.

### 2.3 `CEUI-10` — "inherited values" must not quietly revive the overlay model

`[ICO-1..6]` reversed the base+overlay model: one pack is active, completely self-contained, no
runtime inheritance, no merge engine. So "defaults/inherited values" in the editor can only mean
**schema defaults** and **template instances** (`CEUI-31`) — never cross-pack or cross-document
inheritance. The question is fine; the vocabulary needs pinning before someone implements
`CEUI-10`'s "origin link" as a pointer into another pack.

### 2.4 `CEUI-17`, `CEUI-18`, `CEUI-19` — the validator's placement, severity model and gates are already ruled in three places

- **Placement — ruled.** `CL-ADV-02`: the player runtime shows only the plain validation summary
  plus exportable report; the **deep author validator is an editor surface**. `[DLUX-15]` adds
  that preview **reuses production validators** rather than maintaining a second interpretation.
- **Severity and gate — ruled twice, in the same shape.** `[CRD-9]`: draft packs **warn**;
  release-complete or public export **fails** when a recorded obligation lacks its notice.
  `[L10N-14]`: a pack declares a completeness level per locale, missing keys are reported, and
  release-complete packs warn or fail according to that declared status — explicitly "mirrors
  `[CRD-9]`'s draft-warns / release-fails severity model". `[DRC-17]` names four checks that
  **block pack activation and export**. `class_schema_trial_v1` already carries a "severe,
  non-suppressing" severity that "never changes resolution".
- **Therefore `CEUI-19` must not invent a taxonomy — it must reconcile four.** And note the gate
  vocabulary does not match: the ratified pairs are *draft / release-complete* and
  *activation / export*, while `CEUI-19` asks about *test / export*. **Activation is the missing
  third gate**, and in the editor a Test launch *is* an activation (§4.4).

`CEUI-18`'s issue presentation should inherit the shell's availability vocabulary rather than
invent an issue-state one: `EPUX-02`'s absent-hides / gated-shows-disabled-with-reason, and
`[RPD-15]`'s **focusable but not activatable**, ruled at the shell on 2026-08-13 and inherited by
all five surfaces.

### 2.5 `CEUI-33`, `CEUI-34`, `CEUI-35`, `CEUI-36` — the asset questions are a layout problem, not a decision problem

`DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31` was opened precisely to design the UI for a **known** tool
list. The list is ruled: import plus arbitrary two-point rect slicing (`CSA-7`), rotate/mirror
(`CSA-3`), palette extractor reporting **per-colour frequency** with tunable near-miss detection
(`CSA-21`, `CSA-31 a2`), colour sampler, swap editor with **duplicate-input warning** (`CSA-20`),
full-RGBA from→to entries (`CSA-20`), keyed (faction, state) swap lookup with editor-derived state
variants (`CSA-22`), max 32 / recommended 16 swaps (`CSA-24`), slot binding table (`CSA-16a`),
licence/source entry including the origin note and its **PII warning** (`CSA-34b`), and
**export-time bake** that does not stamp provenance (`CSA-25`, `CSA-32`).

So `CEUI-35`'s A/B/C is the wrong shape: the tools are ruled, the question is disclosure and
density. `CEUI-33`'s import transaction is a staged transaction over `CSA-6`'s **required** rights
recording (an importer is never a licence-laundering step, `LEG-4`). `CEUI-34` is the *batch*
residue of an already-structured record — and it must not weaken `[CSA-13]`/`[CRD-6]`, where
required attribution is a **non-suppressible channel**. `CEUI-36`'s usage index is free:
`[CSA-12]` ruled art assets get full reference-model entries with `used_by` relations, and
`[CSA-16]` ruled "when, where and how used" is authored data.

### 2.6 `CEUI-25`, `CEUI-26`, `CEUI-27`, `CEUI-29` — dialogue already ruled the authoring and preview shapes

| Question | Ratified constraint it must consume |
|---|---|
| `CEUI-25` triggers/objectives as "cards/graph" | `[DLUX-11]`: **ordered outline editor** is the authoring surface; a node graph is a **demand-gated alternate projection over the same canonical data and stable IDs**, never a second source format. `[DRC-2]`: flat ordered entries, stable line IDs, no runtime node objects. The predicate/action half is `TCV-4`/`REQ`/`EXT` registries — already forced. |
| `CEUI-26` test entry points | `[DLUX-15]`: preview covers **actual presenters at every responsive size class**, forces Requirement outcomes for branch coverage, and **never commits campaign state, spends resources, fires authoritative triggers or creates MapLedger/Rewind history**. |
| `CEUI-27` "what is an editor fixture" | The term already exists: **disposable fixture state** (`[DLUX-15]`), and `[DRC-17]` ruled authored fixtures **supported, not mandatory** — making them mandatory would gate the fork-a-public-pack onboarding behind writing tests. Do not mint a second fixture concept. |
| `CEUI-29` "structured receipt" | `[TSV-20]` already owns the word **receipt** for a committed player-facing transaction record. An editor test report is a different artifact; either reuse the vocabulary deliberately or rename it, but do not create a second meaning silently. `CEUI-28`'s "seed" likewise rides the ratified determinism model (`EXT-4` per-output-path determinism, Package A RNG), not a new one. |

### 2.7 `CEUI-37` and `CEUI-38` — recovery and release are assembly, with one collision each

`CEUI-38` is largely ruled parts: `CL-ADV-03`'s **author version-bump note** (a non-blocking
suggestion at edit time, because versioning is manual with no migration engine and identity is
id+version), `[CRD-9]`'s export failure on missing notices, `[CSA-25]`'s export-time bake,
`[L10N-14]`'s release-complete status, the content-addressed backup format's size/SHA-256/snapshot
record, and `IMPL-ZERO-CONTENT-EXPORT-GATE`. Residue: the diff view and the semantic-bump
*recommendation*.

`CEUI-37` collides twice — with the two-primitive ruling (§3.3) and with the web target (§3.2),
where `[CSA-36]` already ruled the answer to volatile storage: extra durability warnings, and
**the warning *is* the export affordance**, not a pointer to a menu. Note also that the game side
already has `SavePolicy` (slot classes, `between_map`/`mid_map`/`any`, `builder_warnings()`) and
`AutosaveTriggerRegistry` in code; an editor autosave model must be *distinguishable* from those,
not a second dialect of them.

### 2.8 `CEUI-40` — narrowed on four sides at once

- **Controller clause:** `[NMTE-S2]` ruled controller is **not a design driver** for the editor.
  The register already flags that option A's "full keyboard/**controller** focus" must not pass
  unexamined. Keyboard reachability is unaffected — that is an accessibility obligation.
- **Focus behaviour:** `[RPD-15]` ruled disabled entries **focusable but not activatable** at the
  shell. The editor inherits it or explicitly declares itself a sixth surface (§4.4).
- **Roles and non-colour channels:** `[UUI-13]`'s semantic role vocabulary is the naming
  authority; `[CSA-27]` already ruled the non-colour channel for faction identity (author-owned
  palettes plus an engine faction **glyph**), which is the precedent for "non-colour issue/dirty
  states".
- **Text:** `[L10N-7]` 1.4×, `[L10N-11/12]` explicit direction metadata with semantic spatial
  content opting out — which is exactly what a **map canvas** does.

And one clause needs promoting rather than answering: **reduced motion** (§4.6).

### 2.9 The twelve `NMTE` questions — most collapse rather than transfer

`TextEntryService` exists to own *printable input* where an on-screen keyboard must be arbitrated.
`[NMTE-S2]` gave the editor a physical keyboard and `[NMTE-S1]` removed every game consumer, so
for the editor the following are no longer design questions but ordinary desktop focus semantics:
`NMTE-2` (entering edit on navigation), `NMTE-7`/`NMTE-8` (Enter/Escape — the two-stage escape is
already built), `NMTE-14` (now the keyboard path back to the field, not a controller problem).

Genuinely live, and worth the walk's time:

| Id | What is actually being asked, after re-scoping |
|---|---|
| `NMTE-1` | Does an editor filter go through `TextEntryService` at all, or is it a plain `LineEdit`? **This is the load-bearing one** — see §4.5. |
| `NMTE-5` | When filtering consumes text: per-keystroke, debounced, or on submit — over an author's pack, which may be large. |
| `NMTE-6` | **IME.** More important, not less: a physical-keyboard-first surface is where platform IME actually appears, and `[L10N-1]`'s localization-*ready* ruling makes option C ("declare IME unsupported") inconsistent with a decision taken the day after the packet was written. |
| `NMTE-13` | Narrowed to **crossing `[CEUI-5]`'s floor mid-edit** — what happens to an in-progress edit when the minimum-size state takes over. This is now a `CEUI-5` residue, not a size-class question. |
| `NMTE-15` | Focused result removed by filtering — decide on `[TSV-24]`'s focus-restoration precedent rather than fresh. |
| `NMTE-18` | Unicode/length contract. The caps are built (`max_characters`, `max_utf8_bytes`); a **query over author-supplied content names** is a new destination class, and the charset coupling that is correct for a file-path box is wrong here. |
| `NMTE-19` | Logging/retention of filter text. No telemetry exists anywhere in the project; the nearest precedent is `[CSA-34b]`'s PII warning on author-entered origin notes. |
| `NMTE-20` | How long filter text persists — which is a **settings-scope** question and belongs with `S12`, not decided ad hoc here. |

---

## 3. Live conflicts — real, and each needs the ruling named

### 3.1 The editor's minimum viewport is now specified three incompatible ways

| Source | Threshold | Mechanism |
|---|---|---|
| Branch K, `campaign_library_ux_decisions_2026-07-24.md` (ratified 2026-07-25) | window below **1920×1080**, **OR** input mode is not keyboard+mouse | **Non-blocking, dismissible warning** on editor entry — "open anyway" |
| Branch K settings declutter row (same ruling) | an author-chosen resolution / non-kbm input mode | **auto-hides the editor entry point**, reversible in Settings |
| `[CEUI-5]` (ratified 2026-08-14) | **1920×880** | **Hard minimum-size state**; "it does not degrade into a compromised layout" |
| `[NMTE-S2]` (ratified 2026-08-14) | — | a **stated recommendation** to the author: mouse, physical keyboard, large screen |

`[CEUI-5]` was ruled without reference to Branch K, and the two are not merely different numbers
— they are **warn-and-continue** versus **block-and-explain** for the same condition. Between
`880` and `1080` of height the ratified answers are "warn, then let them in" and "let them in
silently"; below `880` they are "warn, then let them in" and "refuse". The input-mode axis exists
in one and not the other.

**Decide in the walk, and write the write-back:** which mechanism governs below `1920×880`; what
happens in the `880`–`1080` band; whether the input-mode axis still produces a warning now that
`[NMTE-S2]` has made kbm a stated assumption; and whether the Settings declutter row's threshold
follows the floor. Branch K is the older document and `[CEUI-5]` is later, so `[CEUI-5]` wins on
`DOC-014` grounds *if the walk says so explicitly* — but the input-mode axis and the declutter row
have no successor and would be silently dropped.

### 3.2 The editor ships to web, and nine questions assume a desktop filesystem

Ratified, and unambiguous: Branch K ships the editor in **all** presets including web, with the
download-size cost explicitly weighed and accepted; `[ICO-5/6]` put packs in `user://`; and
`[CSA-36]` ruled that on web `user://` is browser storage that "a cache clear, private session, or
storage-pressure eviction can wipe without warning" — so the durability warnings get built.
`[CEUI-5]`'s own floor is expressed in **browser chrome** terms, which is the strongest evidence
that web is the design target and not an afterthought.

Against that, these questions assume a filesystem and a second application:

| Question | The desktop assumption |
|---|---|
| `CEUI-16` | detect **per-file external disk edits**, offer Reload / Keep mine / merge |
| `CEUI-22` | "read-only structured view plus **Open externally**" |
| `CEUI-33` | "**stage files**, preview classification/duplicates" — and option C, "filesystem-only import" |
| `CEUI-37` | crash-recovery snapshots in durable storage |
| `CEUI-38` | atomic export recording size and SHA-256 — to *where*, in a browser? |
| `CEUI-2` | the advanced "Show file" action |

Branch K's own rationale cuts against a platform carve-out: "can I edit here?" is a **runtime
property, not a platform**. So the walk needs one of two rulings, and should not leave it implicit:
either these are **capability-gated affordances** that are absent on web (and the editor states
so), or the web editor is a **declared lesser environment** — which contradicts the reason
integration was chosen. Note that a web author can still round-trip through the ruled
**export/import** path, so "no external editing" is a real answer, not a dead end.

### 3.3 `CEUI-13`/`CEUI-14` propose a third persistence primitive, five weeks after four were collapsed into two

The **two-primitive ruling** (2026-08-13) named exactly two mechanisms — a **staged transaction**
(overlay + commit/discard) and a **snapshot** (capture + restore, including the RNG stream) — with
the standing rule *"prefer staging; snapshot only to undo something already committed."* It was
produced by finding **four** ratified staging mechanisms that differed only in policy. Since then
`RPD-17` was rejected for proposing a third, `DRC-33` for the same shape, and the duplicate-state
shape has been caught four times in a single day.

An editor **Undo history** — an ordered, chronological, individually reversible sequence
(`CEUI-13` A, `CEUI-14` A) — is a genuinely different mechanism from both. Nothing in the repo
implements it (`grep undo_stack scripts/` is empty), so this is greenfield in code as well as in
design.

**The walk must argue this rather than assume it either way.** The honest case *for* a third
primitive is that the ratified two govern **runtime campaign state**, where the player must never
retroactively rewrite history, whereas authoring is a domain where exactly that is the point. The
case *against* is that `CEUI-13` A's own description ("coalesced typing, one paint stroke, one
import, one batch") is a **chain of staged transactions**, `CEUI-13`'s "backed by snapshots for
recovery" is the snapshot primitive by name, and `CEUI-15`'s "preview then atomic commit" is a
staged transaction verbatim. If the answer is "a third primitive", say so and name it, so `R3`
does not have to rediscover it.

### 3.4 `CEUI-15` cites "the shared transaction vocabulary" — and two different ratified vocabularies answer to that name

`CEUI-15`'s recommendation says to "consume the shared transaction vocabulary rather than
inventing editor-only semantics". Two candidates exist:

- **`TSV-1..24`** (2026-08-13), whose ruled consequence #1 reads: *"The transaction model is small.
  No cart, no staging, no holds, no per-receipt undo, no partial commits, no expiry windows. One
  quote, one atomic commit, one snapshot per activity."* That is an **economy** model. Taken
  literally it forbids most of what `CEUI-15` wants.
- **The two-primitive ruling**, which *does* name a staged transaction with an overlay and a
  commit/discard boundary — the thing `CEUI-15` actually describes.

They are not in conflict with each other, but a build slice reading `CEUI-15` will pick whichever
it finds first. **Name the target explicitly in the ruling.**

### 3.5 `CEUI-31` contradicts `[DLUX-13]`, and `CEUI-22` contradicts `[DLUX-11]`

- **`CEUI-31`** recommends **explicit template instances with visible overrides**, where
  propagation produces a reviewable transaction — i.e. a live link from template to instance.
  `[DLUX-13]` ruled the opposite for conversations: **authoring-time template expansion only**,
  fresh stable IDs, **no runtime call stack**, permissive on prose templates. Expansion-at-author-
  time is copy-on-create — `CEUI-31`'s rejected option B. At minimum, dialogue is carved out; at
  most, `CEUI-31` is answered against its recommendation. Decide whether "template" means one
  thing across content families or two.
- **`CEUI-22`** recommends a **read-only** structured JSON view. `[DLUX-11]` ruled that
  **"supported hand-edited JSON remains a first-class input to the same validator"**, and
  `[DRC-4]` relies on it ("hand-authored JSON — first-class input per `DLUX-11` — supplies both
  fields directly"). Read-only-plus-open-externally is compatible with that *on desktop* and
  incompatible *on web* (§3.2), where there is nothing to open it in. So `CEUI-22` and §3.2 must
  be answered together, and "no embedded JSON editor, ever" would quietly retire a ratified
  first-class input path for web authors.

---

## 4. Promoted — questions the packet does not ask, and should

### 4.1 Does Menu Scale apply to the editor? — ask this before `CEUI-1`

`[UUI-8]` made Menu Scale a **player slider (7 levels, 0.5–2.0) that multiplies the density
tokens** — row height, font, gutter, header/footer and derived content margins together — and its
accepted consequence is that it **does not change the size class**, because the class derives from
`backing ÷ content_scale_factor`, which Menu Scale never touches. `[UUI-14]`/`[UUI-16]` place the
editor inside **application chrome**, alongside the Main Menu and Campaign Library, which Menu
Scale unambiguously does affect. `[UUI-18]` lists `menu_scale_index` as a `reachability_risk`
setting for exactly this reason.

**Consequence if the answer is yes:** at `2.0×` on a `1920×880` window the editor has the
effective density of a `960×440` viewport, `[CEUI-5]`'s minimum-size state **never fires** (the
floor is measured in physical pixels), and `CEUI-1`'s four simultaneous regions are in precisely
the failure case `[EPUX-03]` cited when it ruled *"never three panes: a third collapses at 200%
Menu Scale"*. This one answer decides whether `CEUI-1`–`CEUI-4` can be drawn as recommended.

**Related, and cheaper:** `[EPUX-03]`'s pane budget is scoped to the Explore chain, but `RPD-4` was
rejected against it **outside** that chain on 2026-08-13, so it is already being read as
shell-wide. Say explicitly whether the editor is exempt and why (a `1920`-wide floor and a
different content shape is a good reason — but it has to be a reason, not an omission).

### 4.2 Where does an author author localization? Four ratified obligations have no editor surface

`[L10N-3]` each pack ships its own locale catalogues (forced by `ICO`); `[L10N-14]` a pack
**declares a completeness level per locale** and missing keys are reported; `[L10N-15]` explicit
**locale-to-asset mapping** in the pack catalogue, using `CSA` semantic asset groups; `[L10N-17]`
versioned **context, character limits and screenshots stored beside the message IDs**, with
spreadsheets as an export and never the authority; `[L10N-2]` stable semantic message IDs with
English as fallback text, never identity.

Every one of those is authored work, and `CEUI-1..40` mentions localization **zero times**.
`CEUI-8`'s workspace list — Content, Maps, Graph, Assets, Test, Release — has no slot for it, and
`[L10N-16]`'s mandatory **pseudolocale captures at all durable viewports** is arguably a `CEUI-26`
test entry point. Add the question; do not let the first localization surface be designed by
whoever implements `L10N`.

### 4.3 The content palette was closed without a ruling, and the research assumes the answer

`DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31` is `status: completed`, `decision_required: true`,
`phase: decision-required`, closed `2026-08-10` — and **`grep -ri "content palette" AGENT/Docs/`
returns nothing**. Its four options (no palette / bundled / downloadable first-party pack /
web-only) appear only in the tracker row. Meanwhile:

- the `CEUI` comparative research states, as an *inherited* decision, "there are no dependencies,
  cross-pack id collisions, load-order controls, or **built-in content palette**";
- `[ICO-1]`'s ratified resolution text still says default content ships with the builder as a
  **copy-from palette**, restated in `campaign_save_expectations_and_foundations_2026-06-23.md`;
- `FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31`, the row that would edit those two lines, is
  still `planned` — and its own trigger warns that running it would "silently answer" this
  question.

This is the `TSV-1..9` provenance shape again: a document citing a ruling that exists on no
branch. **Rule it in this walk** (option A is the likely answer, since it coheres with
`CSA-31(f)`/`CSA-33(a)`), record it in a document, and unblock the doc edit.

### 4.4 Which pack is active while the editor is open, and what does Test activate?

Ratified and in tension: one pack is active at a time and is completely self-contained (`ICO`);
installed packs are immutable and editing means unpack-to-working-copy (`CL-ADV-01`); loose-folder
dev packs load **only under developer mode** and **never activate in a normal player session**
(`CL-ADV-01`); skin resolution follows `active_package_identity` and quit-to-shell deactivates
(`CSA-28(f)/(g)`); and `[DRC-17]`'s checks block **activation** as well as export.

`CEUI-26`'s Test launch has to activate *something*. Nothing rules whether that is the working
copy as a dev source, whether entering the editor deactivates a campaign the player has in
progress, or what happens to an existing save that depends on the pack being edited. The
`CampaignPackRegistry` today scans only `user://campaign_packs/<id>/<version>/` and rejects a
manifest disagreeing with its directory — so the loose-folder path is genuinely net-new, exactly
as `CL-ADV-01` says.

Adjacent and cheap: **is the editor a sixth `EPUX-02` availability surface, or does it inherit the
shell's vocabulary?** `RPD-10` was rejected for proposing a sixth *vocabulary*; the editor should
inherit, but `[EPUX-04]` puts gating in the **game** shell and the editor is chrome, so the
inheritance path needs one sentence.

### 4.5 If the editor does not use `TextEntryService`, nothing does

`TextEntryService` is a built autoload (`project.godot:35`) with a session/request/result split,
`dismissal_policy`, `private_value`, and `max_characters`/`max_utf8_bytes`. Its tracker row
records that it has **zero production callers** — only tests. `[NMTE-S1]` then removed every
planned game-side non-modal consumer, and `[NMTE-S2]` removed the on-screen keyboard from the
editor, which was the service's whole reason to arbitrate.

So `NMTE-1`, re-scoped, is not a small question. If the editor's filter is a plain `LineEdit`,
then the ratified **"one owner of printable input"** has no consumer anywhere in the program, and
that ruling should be restated (as covering *modal* naming and path entry, which is real and
built) rather than left looking like an unadopted architecture. If instead the editor routes
through the service, say what the service *does* for a physical-keyboard field — focus/dismissal
policy and the length/charset contract are plausible answers, an on-screen keyboard is not.

### 4.6 `CEUI-40` would create the project's first reduced-motion contract

`grep -ri "reduced motion" AGENT/Docs/` hits only the wireframe albums, the `CEUI` research and
the `NMTE` research — no ratified decision, no settings row, no register. Yet the game has
`combat_animations` and `movement_speed` settings and a whole combat-feedback vocabulary
(`CFB-1..18`) that is all motion.

This is the same shape as `NMTE-17`'s screen-reader announcement contract, which the 2026-08-14
walk **withdrew** rather than promoted, on the grounds that the project does not need a shell-wide
contract yet. Decide the same way here, deliberately: either the editor's reduced-motion clause is
**editor-local** (previews do not animate), or it is a shell-wide accessibility contract — in
which case it belongs to the game's motion surfaces first and not to an editor register.

---

## 5. Propagation debts found — pay these, do not defer them

1. **The `CEUI` research misstates a ratified decision.** It says the editor is "hidden behind the
   existing runtime/developer gate". Branch K ruled the editor entry **visible everywhere by
   default**, with an optional player-set hide; developer mode gates **loose-folder dev packs** and
   the **deep validator**, not the editor. Fix the research header before the walk quotes it.
2. **`DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31` is `completed` with no recorded ruling** (§4.3).
   Either record the decision or reopen the row; it currently blocks
   `FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31` while looking closed.
3. **`DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`'s row text is stale.** It still says the packet is
   "READY except for its search-specific rows, which wait on `NMTE-1..20`". `[NMTE-S4]` folded
   those questions *into* this walk on 2026-08-14; nothing waits.
4. **`[CEUI-5]` owes Branch K a write-back** once §3.1 is resolved — the `1920×1080` warning
   threshold, the OR gate's input-mode axis, and the settings declutter row all point at a number
   that is no longer the floor.
5. **Already paid, recorded so it is not re-reported:** `responsive_ui_redesign_2026-08-06.md`
   now carries `1.4×` with the `[L10N-7]` provenance. The debt the `NMTE` diff logged at §5.3 is
   closed.

---

## 6. Disposition of the fifty-two

| Id | Disposition |
|---|---|
| `CEUI-1` | **Live, but gated on §4.1.** Ask Menu Scale first; then the pane budget's scope (`EPUX-03`). |
| `CEUI-2` | **Closed on the option set** (`EXT`, `CSA-17(a)`). Residue: "Show file" on web; non-asset families. |
| `CEUI-3` | **Live.** No precedent. Back/forward should consume `TSV-24` focus restoration. |
| `CEUI-4` | **Live.** If layouts persist, the *scope* of that persistence defers to `S12`. |
| `CEUI-5` | **Resolved 2026-08-14** — but see §3.1; the ruling has an unreconciled predecessor. |
| `CEUI-6` | **Closed by precedence** — Branch K + `CL-ADV-01/03`. |
| `CEUI-7` | **Narrowed.** Floor-collapse clause is moot; re-ask on `[L10N-7]` 1.4× grounds. |
| `CEUI-8` | **Narrowed.** Ask the workspace *list* (localization is missing, §4.2), not the axis. |
| `CEUI-9` | **Narrowed** by `[DLUX-12]`/`DRC-6`: ask whether it generalizes and what bulk tables may touch. |
| `CEUI-10` | **Narrowed.** "Inherited" = schema defaults + template instances only (`ICO`). |
| `CEUI-11` | **Narrowed.** Must be `[TSV-10]`'s shared selector, not a second picker. |
| `CEUI-12` | **Live.** Genuinely new. |
| `CEUI-13` | **Live conflict** — §3.3, the third primitive. |
| `CEUI-14` | **Live conflict** — §3.3. |
| `CEUI-15` | **Narrowed + ambiguous citation** — §3.4; name which vocabulary. |
| `CEUI-16` | **Live conflict** — §3.2; meaningless on web as written. |
| `CEUI-17` | **Narrowed.** Placement ruled (`CL-ADV-02`, `[DLUX-15]`); the schedule is open. |
| `CEUI-18` | **Narrowed.** Inherit `EPUX-02` + `[RPD-15]` rather than invent issue-state presentation. |
| `CEUI-19` | **Largely closed** by `[CRD-9]` + `[L10N-14]` + `[DRC-17]`; reconcile, add the activation gate. |
| `CEUI-20` | **Narrowed.** The "registered beside validator rules" half is forced by `EXT`; DoD#2 applies. |
| `CEUI-21` | **Narrowed** by `CL-ADV-02/03`; Advanced disclosure must never hide required attribution (`CSA-13`). |
| `CEUI-22` | **Live conflict** — §3.5 vs `[DLUX-11]`, compounded by §3.2. |
| `CEUI-23` | **Live.** |
| `CEUI-24` | **Live.** |
| `CEUI-25` | **Narrowed** by `[DLUX-11]`/`[DRC-2]`: outline authoritative, graph a projection. |
| `CEUI-26` | **Narrowed** by `[DLUX-15]`; blocked on §4.4 (what does Test activate?). |
| `CEUI-27` | **Narrowed.** "Disposable fixture" already exists; `[DRC-17]` supported-not-mandatory. |
| `CEUI-28` | **Live.** Seed rides the ratified determinism model, not a new one. |
| `CEUI-29` | **Narrowed.** Do not overload "receipt" (`[TSV-20]`); preview creates no ledger history. |
| `CEUI-30` | **Live.** |
| `CEUI-31` | **Live conflict** — §3.5 vs `[DLUX-13]`. |
| `CEUI-32` | **Closed by precedence** — `[CSA-11]`. |
| `CEUI-33` | **Narrowed** by `CSA-6`/`CSA-32`/`LEG-4`; the staging shape is §3.3's; web path is §3.2's. |
| `CEUI-34` | **Narrowed** to the batch residue of `CSA-34`'s structure; `CSA-13`/`CRD-6` bind. |
| `CEUI-35` | **Reframed.** The tool list is ruled; ask disclosure and density. |
| `CEUI-36` | **Narrowed.** Usage index is free from `[CSA-12]`/`[CSA-16]`; rule only the policy. |
| `CEUI-37` | **Narrowed + two conflicts** — §3.2 (web durability, `[CSA-36]`) and §3.3. |
| `CEUI-38` | **Narrowed.** Mostly assembly of ruled parts; residue is the diff view and bump recommendation. |
| `CEUI-39` | **Closed on the choice** (`CSA-30`/`31(f)`/`33(a)`, `LEG-4`); residue = guided task list vs "no hints", plus §4.3. |
| `CEUI-40` | **Narrowed on four sides** (§2.8); reduced motion promoted to §4.6. |
| `NMTE-1` | **Live and load-bearing** — §4.5. |
| `NMTE-2` | **Collapsed** to ordinary desktop focus semantics. |
| `NMTE-5` | **Live**, editor-scoped. |
| `NMTE-6` | **Live, and more important** after `[L10N-1]`; option C is inconsistent with it. |
| `NMTE-7` | **Collapsed** — two-stage escape is built; only result-focus survives. |
| `NMTE-8` | **Collapsed** — as `NMTE-7`. |
| `NMTE-13` | **Narrowed** to crossing the `[CEUI-5]` floor mid-edit. |
| `NMTE-14` | **Narrowed** to the keyboard path back to the field. |
| `NMTE-15` | **Narrowed** onto `[TSV-24]`'s precedent. |
| `NMTE-18` | **Narrowed** to the author-supplied-names destination class. |
| `NMTE-19` | **Live.** No telemetry exists; `CSA-34b` is the nearest precedent. |
| `NMTE-20` | **Deferred to `S12`** (settings persistence scope). |

**Totals:** 4 closed by precedence, 21 narrowed or reframed, 6 live conflicts, 12 genuinely live
as written, 4 collapsed `NMTE`, 1 deferred, 1 already resolved, plus 6 promoted questions that are
not in either register.

---

## 7. Recommended walk order

Two questions decide the shape of everything else and are cheap to answer. Take them first, out of
register order:

1. **§4.1 — does Menu Scale apply to the editor?** One sentence, and it decides whether `CEUI-1`
   can be four regions.
2. **§3.1 — which floor mechanism governs?** One sentence, and it retires or reinstates a ratified
   warning that three other decisions point at.

Then, in this order:

3. **§3.2 — the web target.** Resolving it collectively answers `CEUI-16`, `CEUI-22`, `CEUI-33`,
   `CEUI-37`, `CEUI-38` and `CEUI-2`'s residue; walking them individually will produce six
   inconsistent platform stances.
4. **§3.3 — is editor Undo a third primitive?** Then `CEUI-13`, `CEUI-14`, `CEUI-15`, `CEUI-31`
   follow in minutes instead of being re-argued each time.
5. **§4.3 and §4.4** — the content palette, and what Test activates. Both are prerequisites for
   `CEUI-26`–`CEUI-29` and `CEUI-39`.
6. **Section A shell questions** (`CEUI-1`, `3`, `4`, `7`, `8`) with §4.2's localization workspace
   folded into `CEUI-8`.
7. **Sections B–D residues**, most of which are now short.
8. **Section E** as a layout exercise over the ruled `CSA` tool list.
9. **Section F**, with `CEUI-40` narrowed per §2.8 and reduced motion decided per §4.6.
10. **The `NMTE` twelve last** — four collapse, one defers to `S12`, and the rest are small once
    the editor's composition exists to hang them on. `NMTE-1` (§4.5) is the exception and could be
    taken earlier if the owner wants the `TextEntryService` question settled in the same breath as
    the text-entry row's staleness.

**Exit condition unchanged:** when this walk closes, `UBS-8` lifts, and with `UBS-6`/`UBS-7` the
`UUI-15` album hold is fully released.
