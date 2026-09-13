---
Role: dated
Type: design
Status: Accepted — precedence diff; the walk ran 2026-08-14 and re-scoped the packet
Last verified: 2026-08-14
Tracker: S3-NMTE-PRECEDENCE-DIFF-2026-08-14
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `NMTE-1..20` — Precedence Diff Before the Owner Walk

> **OUTCOME, 2026-08-14 — the walk ran and the scope answer re-scoped the packet.** Non-modal
> text entry is **editor-only** (`[NMTE-S1]`); game-UI discovery is the **closed candidate list**
> over pack content (`[NMTE-S3]`); the residue is walked with `CEUI` (`[NMTE-S4]`). Rulings and
> the per-question disposition are in the
> [register](../registers/non_modal_text_entry_open_questions_2026-08-12.md#owner-rulings--2026-08-14).
>
> **What this diff got right, and what that says about the method.** §7 put the scope question
> first *because* it was cheap and set the detail level for everything after it — and it turned
> out to end the walk. The three propagation debts and the six precedence closures still stand.
> **The modality collision in §3.1 was dissolved rather than arbitrated:** the diff correctly
> identified that `NMTE-3`/`9`/`12` collided with the ratified *"a text session is modal"*, and
> the owner removed the collision by removing the Compact consumer instead of choosing a side.
> A precedence diff that surfaces a collision is doing its job even when the answer is neither
> of the options it framed.

Fifth `DOC-014` check in this series, after
[`skf_drc_precedence_diff_2026-08-13.md`](skf_drc_precedence_diff_2026-08-13.md),
[`drc_group_a_precedence_diff_2026-08-13.md`](drc_group_a_precedence_diff_2026-08-13.md),
[`drc_groups_bcde_precedence_diff_2026-08-13.md`](drc_groups_bcde_precedence_diff_2026-08-13.md)
and [`rpd_precedence_diff_2026-08-13.md`](rpd_precedence_diff_2026-08-13.md). This is `S3` of
[`research_and_discussion_sequencing_2026-08-13.md`](../plans/research_and_discussion_sequencing_2026-08-13.md),
and `UBS-3` — the last live cross-cutting gate on the unbuilt-screen agenda.

**Sources diffed.** `TEXT-01..08`
([strategy packet](text_entry_strategy_research_and_questions_2026-07-26.md), ratified
2026-07-26, `TEXT-03`/`TEXT-06` revised by owner 2026-07-30), `TEXT-09..12a`
([naming and sanitization](text_entry_naming_and_sanitization_2026-07-26.md)), `TEXT-13..15`
([layout implementation](text_entry_layout_implementation_research_2026-07-26.md)), the
[Compact mobile text-entry design](text_entry_mobile_compact_2026-08-06.md) (ratified
2026-08-06, suppression **Implemented**), `EPUX-15` (owner ruling 2026-07-26), `UUI-11`
(2026-08-12), `L10N-1..18` (2026-08-13), `RPD-15` as promoted (2026-08-13), `CEUI`'s held-search
clause, and the **built code** — `project.godot:35`, `scripts/autoloads/TextEntryService.gd`,
`scripts/ui/text_entry/{TextEntryRegistry,TextEntryRequest,TextEntrySession,TextEntryOverlay}.gd`,
`scripts/ui/FileDialogInputGuard.gd`, `scripts/autoloads/SettingsManager.gd`,
`scripts/ui/SettingsScreen.gd`, `export_presets.cfg`.

## Bottom line

**`NMTE-1..20` cites zero ratified decisions.** Not one bracket id outside its own namespace
appears in the register or in its comparative research — no `TEXT`, no `EPUX`, no `UUI`, no
`L10N`. That is the same failure recorded for `RPD` on 2026-08-13, with one important
difference that changes the verdict: **`NMTE`'s research is very well grounded in the
code**. It read `TextEntryService`, `TextEntrySession`, `FileDialogInputGuard`, the modal
`TextEntryOverlay` and `ResponsiveLayout` accurately, and it knows about the Compact
OS-keyboard suppression in prose. What it did not read is the **decision corpus** — fifteen
ratified `TEXT` rulings across three documents, and the four registers ruled in the six days
either side of it.

The consequence is not that the packet is wrong. It is that **the packet asks eight questions
whose answers the project already owns, in the vocabulary of options A/B/C rather than of
amendment** — and, more seriously, that its central premise collides with a ruling made six
days before it was written.

**The collision.** The Compact design ratified 2026-08-06 says, of the in-game keyboard taking
over the control band: *"the controller is simply unavailable while typing, **which is
acceptable because a text session is modal**."* `NMTE` exists to design **non**-modal text
entry. Both can be true — the Compact ruling is arithmetic (240px of content at 360×640) and
landscape/Medium keeps the field visible in place — but nobody has said so, and `NMTE-3`,
`NMTE-9` and `NMTE-12` are all written as though modality were an open choice at every size
class. **Modality is size-class-conditional and Compact is already ruled modal.** That
reframing has to happen before the walk, or the walk will ratify a contradiction.

Disposition of the twenty: **three closed**, **six narrowed or reframed**, **three live
conflicts**, **two promoted**, six unaffected. Plus **three propagation debts**, one of which
is a live user-visible defect.

---

## 1. Closed by precedence — do not ask these

### 1.1 `NMTE-10` — backend selection was ratified three times and is built

`NMTE-10` asks which keyboard backend an inline filter should use and recommends "capability
and player preference". That is `TEXT-01` (**ratified B**: platform keyboard where one exists,
ours as fallback, ours built first), `TEXT-05` (**ratified B**: one setting, defaulting to
input-device detection, **touch and gamepad route to our native keyboard**, physical keyboard
does not), `TEXT-14a` (**ratified**: folded into that same setting rather than a second
control), and `TEXT-14` (**ratified**: the registry's unit is an **entry mode**, and `hardware`
is a first-class registered presenter, not the absence of one).

It is also built, and matches the ruling line for line:

```gdscript
# TextEntryRegistry.gd
func resolve(requested: StringName, last_device: StringName) -> StringName:
    if requested != &"auto":
        return requested if has_backend(requested) else &"hardware"
    if last_device in [&"gamepad", &"touch"] and has_backend(&"grid"):
        return &"grid"
    return &"hardware"
```

`SettingsManager.text_entry_mode` persists the three-way override; `TextEntryService._ready()`
registers `hardware` and `grid` into one shared registry.

**Do not ask.** And note the ruling is *stronger* than `NMTE-10`'s recommendation: the packet
leaves native "for explicitly supported future exports", but 2026-08-06 hardened `TEXT-04` to
*"there is no platform keyboard coming, so the seam is not 'not yet', it is **not planned**."*

### 1.2 `NMTE-16` — free text as the only discovery path is already a ratified rule with a check

`NMTE-16` recommends "search is acceleration, never reachability". `TEXT-06`, **revised by
owner 2026-07-30**, is that sentence as a rule: *"V1 may require text entry for naming and for
file/path entry. Other features still use bounded selection, filters, or generated ids unless
separately approved."* It carries a **DoD#2 obligation** — the rule's check landed with the
rule — so this is enforced, not merely written.

`EPUX-15` (**owner ruling 2026-07-26**) is the worked example: *"C, filters only — **no
free-text search in v1**… so every stock surface behaves identically on every input method
rather than degrading on controller."*

**Do not ask.** Record `NMTE-16` as confirmed-by-precedence, citing `TEXT-06`.

### 1.3 `NMTE-4` — the ownership-handoff mechanism is built, with the recommended default

`NMTE-4` asks what happens when another field requests ownership and recommends "end the old
request using its declared handoff policy, defaulting inline filters to keep their value and
modal transactions to cancel/restore". `TextEntryRequest` already carries

```gdscript
enum DismissalPolicy { KEEP_EDITED, RESTORE_INITIAL }
var dismissal_policy: DismissalPolicy = DismissalPolicy.KEEP_EDITED
```

and `TextEntryService.begin()` ends any active session before starting the new generation,
honouring that policy. The mechanism, the two policy values and the recommended default all
exist.

**Do not ask the question.** The only live decision is **which policy value a filter request
declares** — one line in the eventual filter request, not an architecture choice.

---

## 2. Narrowed or reframed — ask the residue, not the question as written

### 2.1 `NMTE-1` — options B and C are dead; the service is an autoload

`NMTE-1` offers "extend the shared service / build a separate `SearchInputService` / let every
screen own a `LineEdit`". The shared service is registered at `project.godot:35`, owns one
generation, one session, one registry and two registered presenters. `TEXT-14` ratified the
registry as **required on day one**. B and C are not available options; choosing either would
be a reversal, not a choice.

**Ask instead:** what shape the non-modal presentation policy takes on the existing service —
which is what the research itself concluded ("the smallest compatible extension is a non-modal
presenter policy on the existing service, not a second search-input singleton").

### 2.2 `NMTE-11` — there is no native keyboard to have a height

`NMTE-11` asks how native keyboard height should affect layout. **The project has deliberately
no native keyboard.** `export_presets.cfg:110` sets `html/experimental_virtual_keyboard=false`;
`scripts/tests/test_web_export_preset.gd` guards it against the Godot export dialog silently
reverting it; and `grep virtual_keyboard scripts/` returns only that test's comments. The 2026-08-06
ruling is explicit that this is a product decision, not a gap.

The ratified answer for *our* keyboard is far more specific than any of `NMTE-11`'s three
options: it **takes over the control band** in Compact (nothing covered, nothing floats); in
landscape it occupies the two **dead columns**, split A–M / N–Z; and when the dead space is
narrower than the 4:3 boundary, **the game view shrinks for the duration of the session**.

**This is `NMTE-11`'s cleanest "assumption that has since moved."** The question descends from a
note on `IMPL-REFERENCE-COMPENDIUM` added **2026-07-31** — *"OS-keyboard lifecycle (show/hide +
height, so the results list resizes — NO virtual_keyboard handling exists anywhere in
`scripts/` today)"* — written six days before the ruling that removed the mechanism it asks
about.

**Ask instead:** the **available-content-rect signal** — the one genuinely new thing in
`NMTE-11`'s option B. `ResponsiveLayout` publishes size class; a band-occupying keyboard changes
usable height without changing size class, and nothing publishes that today.

### 2.3 `NMTE-18` — the caps are built and the taxonomy exists; a query is a new destination class

Three parts, three different states:

- **Caps: built.** `TextEntryRequest` has both `max_characters := 64` and
  `max_utf8_bytes := 255`. `NMTE-18`'s "explicit character and UTF-8 byte safety caps" is a
  description of the code.
- **Unicode: ruled.** `TEXT-09` (**ratified B**) settled that *the validator accepts Unicode
  letters/marks/digits while the keyboard ships ASCII* — deliberately different, because
  clipboard paste and hand-written pack JSON bypass the keyboard. NFC normalization is ruled in
  the same section.
- **The framing is wrong, and usefully so.** The naming packet's organising principle is
  **"classify by destination, not by field"**, with Class A display text, Class B filenames,
  Class C import/export paths and Class D text crossing to another player. **A filter query is
  none of them** — it is never stored, never becomes a filename, never leaves the machine.

**Ask instead:** *"add Class E — ephemeral query text, and state its rules"*, not *"pick a
Unicode contract"*. One flagged conflict for that discussion: Class A ruled length capped **in
characters, not bytes**, while the built request carries both; the likely reconciliation is
characters as the authored cap and bytes as the safety cap, but it should be said out loud.

### 2.4 `NMTE-17` — the validation-message contract is already ruled; the announcement half is not

The 2026-08-06 design ratified the field echo strip (Compact only, because the field can scroll
out of view behind its own keyboard) and with it a contract in those words: **"the strip where
one exists, the field's own row otherwise."** `NMTE-17`'s inline-text half is that ruling.

Its announcement half is a different animal — see §4.2.

### 2.5 `NMTE-15` — option A is already excluded by the availability vocabulary

`RPD-15`, **RESOLVED and PROMOTED 2026-08-13**, made the shell-wide vocabulary explicit across
all five `EPUX-02` availability surfaces: absent hides, gated shows disabled with a reason, and
**disabled entries are focusable but not activatable**. A result removed by a filter is
*absent*, not *gated* — so it hides, and `NMTE-15`'s option A ("leave focus on a hidden/removed
node") is already ruled out.

**Ask instead:** only the recovery rule — nearest surviving result by stable source order versus
first result — which the vocabulary genuinely does not cover.

### 2.6 `NMTE-7` / `NMTE-8` — the two-stage escape is built; only the result-focus half is new

`TextEntrySession` carries `handle_physical_escape()`, `physical_escape_consumed` and
`semantic_transition_count`, and `cancel()` honours `dismissal_policy`. The "first Cancel
restores and leaves edit mode, a second Cancel may leave the screen" shape is the built
behaviour and descends from the 2026-07-30 addendum's item 4.

**Ask instead:** what Enter does with a *result list* — turning typing into navigation, and the
empty-result rule. That part has no precedent anywhere in the corpus.

---

## 3. Live conflicts — real, and each needs the ruling named

### 3.1 The modality collision — `NMTE-3`, `NMTE-9`, `NMTE-12`

Stated in the bottom line and repeated here because it is the walk's first decision. The
2026-08-06 ruling that **a text session is modal** is scoped to Compact and rests on
arithmetic — at 360×640 the keyboard needs the same 288px the control band occupies, so the
controller is unavailable while typing. `NMTE-12`'s recommendation B ("results remain visible
and inspectable") is **not achievable in Compact** without amending that ruling, because in
Compact there is no screen left for results while the keyboard is up.

In Medium/Expanded the landscape split puts the keyboard in the dead columns and *"the field
being named stays on screen for the whole session"* — so non-modal is available there at no
cost.

**Ask it as:** *is non-modal filtering a Medium/Expanded capability with Compact degrading to
the ratified modal session, or does Compact's ruling get amended?* Both are defensible; what is
not defensible is answering `NMTE-3`/`NMTE-9`/`NMTE-12` without noticing the question.

### 3.2 `TEXT-15`'s revisit trigger has arguably fired — `NMTE-5`, `NMTE-6`

`TEXT-15` ratified "no prediction now, reserve a `candidate_select` action", with an explicit
condition attached: *"**If `[EPUX-15]`'s free-text search is ever restored**, that is the
trigger to revisit; if it never is, nothing was spent."* The keypad presenter's "do not build"
rests on the same condition. So does part of `TEXT-02`'s reasoning.

Whether `NMTE` **is** that restoration is a real discriminator, not a technicality: `TEXT-06`
permits *filters*, and a live filter over a bounded list is not `EPUX-15`'s cut free-text
search. But nobody has ruled which one the compendium field is.

And there is a ratified alternative sitting right beside it. The 2026-08-06 design's section
*"Where a lexicon genuinely applies"* rules that **the active campaign pack is an enumerable
vocabulary** — unit, class and item names are all known, one pack is active at a time — and
that *"for any field that names one of those, a filtered candidate list beats a keyboard
outright"*, explicitly distinguishing this from `TEXT-15`'s banned free-text prediction.

**Ask:** is the compendium's discovery mechanism a text filter at all, or the ratified closed
candidate list over pack content? That question precedes every debounce and IME decision in
`NMTE-5`/`NMTE-6`.

### 3.3 `L10N-1..18` was ruled the day *after* the packet — `NMTE-6`, `NMTE-13`, `NMTE-18`

The packet is dated 2026-08-12; `L10N` was ruled 2026-08-13. Four rulings bind here and none
could have been seen:

- **`L10N-1` (B)** — localization-*ready* architecture, English the only guaranteed language.
  This bounds `NMTE-6`: IME support is architectural readiness, not a shipping locale. That is
  the same shape `L10N-11` ruled for RTL, and it makes `NMTE-6`'s option C ("declare IME
  unsupported in v1") inconsistent with a ruling made a day later.
- **`L10N-11` (B) / `L10N-12` (B)** — RTL-ready mirroring and **mandatory bidi tests** with no
  shipping RTL locale, and **every component declares explicit direction metadata**, defaulting
  to the non-mirroring case. A filter field and a results list are components. This is a build
  obligation on whatever `NMTE` specifies, not an option.
- **`L10N-7` (B)** — layouts prove against a **1.4× pseudolocale**, not 1.3×. The keyboard is
  the worst case for this: `UUI-11`'s `dense` column already trades whitespace to fit seven
  44px columns into 360px, so there is no slack left to absorb expansion in the key grid.

Nothing here contradicts `NMTE`; it constrains it. **Record the constraints in the register
before the walk** so they are not rediscovered as "findings" during it.

---

## 4. Promoted — questions the packet does not ask, and should

### 4.1 Which surfaces get a non-modal filter in v1 at all?

`NMTE` designs a contract and names its consumers as the reference compendium and the campaign
editor. Their actual states:

| Consumer | State |
|---|---|
| `EPUX-15` shop/stock search | **Cut from v1** by owner ruling 2026-07-26 |
| `IMPL-REFERENCE-COMPENDIUM` | phase **`5-backlog`** |
| `CEUI-1..40` editor search | **HELD**, packet unwalked, search explicitly deferred to `NMTE` |

So every named consumer is backlogged, cut, or unwalked. **This is not an argument against
walking `NMTE`** — the seam is cheap now and expensive to retrofit, which is exactly `TEXT-14`'s
ratified reasoning for building the registry before a second layout existed. But it changes how
much of `NMTE-11`, `NMTE-12` and `NMTE-13` is worth deciding in detail today, and the owner
should rule the scope question first: **is this a contract we ratify now and build when a
consumer arrives, or a build?**

### 4.2 `NMTE-17` would create the project's first screen-reader announcement contract

`NMTE-17`'s option B cites "the non-modal status-message model" as though it were established.
**It is not.** There is no ratified announcement, live-region or screen-reader vocabulary
anywhere in the corpus; the single mention of a screen reader in any register is `RPD-15`'s
clause that a disabled entry must be reachable *"by keyboard, controller and screen reader
rather than hover-only"*.

Answering `NMTE-17` as written means inventing a shell-wide accessibility model inside a
text-entry walk — the exact shape `RPD-15` was **promoted out of prep** for, because it belonged
at the shell. **Recommend splitting it:** rule the inline-text half here (it is already ruled,
§2.4), and spin the announcement contract out as its own shell-level row.

---

## 5. Propagation debts found — pay these, do not defer them

### 5.1 A live defect: Settings still offers a backend that does not exist

The 2026-08-06 ruling #3 was explicit: *"**Settings vocabulary: drop `system`.** Leaves
Automatic / On-screen keyboard / Physical keyboard… **Keep the registry constant; drop only the
Settings row**, so it is cheap to reinstate."*

The registry constant was correctly kept (`SettingsManager.gd:104`). **The Settings row was
never dropped.** `scripts/ui/SettingsScreen.gd:127` still offers:

```gdscript
"values": ["auto", "grid", "hardware", "system"],
"labels": ["Auto", "On-screen Grid", "Hardware Keyboard", "System Keyboard"],
```

Traced through the built path, selecting **"System Keyboard"** does this: `_configured_mode()`
returns `system` → `TextEntryRegistry.resolve()` finds no `system` backend and degrades to
`hardware` → `TextEntryOverlay.gd:62` sets `_presenter.visible = mode == &"grid"`, hiding the
key grid. On a touch device — where the OS keyboard is suppressed at export level and there is
no physical keyboard — the player gets **a text field with no keys and no way to type**.

This is one line of content plus a test. It is the strongest argument in this document for why
precedence diffs run before walks: a ratified decision went unpropagated for eight days and
became a reachable dead end.

### 5.2 `NMTE`'s own tracker row is stale in two ways

`DESIGN-TEXT-ENTRY-SERVICE-2026-07-31` is what the register names in its `Tracker:` header, and
a slice author starting from it would be misled twice:

- Its **title** says *"decided (autoload), **deliberately not built yet**"*. It is built and
  registered at `project.godot:35`, with session, registry, request/result split, two
  presenters, dismissal policy and privacy flag.
- Its **stated problem** — *"`FileDialogInputGuard._resolved_text_entry_mode()` constructs a
  fresh `TextEntryRegistry` and re-registers both presenters on EVERY `focus_entered`"* — no
  longer exists. That function is gone; the guard now only remembers and restores caller focus,
  and `TextEntryService._ready()` registers both presenters into one shared registry.

**Amend the row** in the same session that walks the register.

### 5.3 The 1.3× figure in the responsive redesign

`responsive_ui_redesign_2026-08-06.md` still carries `~1.3×` where `L10N-7` ruled 1.4×. `L10N`
already recorded this edit as owed; it is named here because the keyboard is the tightest
consumer of that budget and will be the first surface to fail it.

---

## 6. Disposition of the twenty

| Id | Disposition | Governing precedent |
|---|---|---|
| `NMTE-1` | Narrowed — B/C dead | Built autoload; `TEXT-14` |
| `NMTE-2` | **Live, unaffected** | — |
| `NMTE-3` | Reframed — modality is size-class-conditional | 2026-08-06 Compact ruling |
| `NMTE-4` | **Closed** — mechanism + default built | `dismissal_policy` |
| `NMTE-5` | Live, but gated by §3.2 | `TEXT-15` revisit trigger |
| `NMTE-6` | Narrowed by `L10N-1`/`L10N-11` | ruled the day after |
| `NMTE-7` | Narrowed — result-focus half is new | 2026-07-30 addendum |
| `NMTE-8` | Narrowed — two-stage escape built | `TextEntrySession` |
| `NMTE-9` | Reframed — see §3.1; option A is what is built | `_withdraw_if_focus_left` |
| `NMTE-10` | **Closed** | `TEXT-01`/`TEXT-05`/`TEXT-14`/`TEXT-14a` |
| `NMTE-11` | Narrowed to the content-rect signal | 2026-08-06; export preset |
| `NMTE-12` | **Live conflict** | 2026-08-06 "a text session is modal" |
| `NMTE-13` | Live; constrained by `L10N-12` | direction metadata |
| `NMTE-14` | **Live, unaffected** | — |
| `NMTE-15` | Narrowed to the recovery rule | `RPD-15` / `EPUX-02` |
| `NMTE-16` | **Closed** | `TEXT-06` (revised), `EPUX-15` |
| `NMTE-17` | Split — inline ruled, announcements promoted | 2026-08-06; §4.2 |
| `NMTE-18` | Reframed — add Class E | `TEXT-09`; naming §5 taxonomy |
| `NMTE-19` | **Live, unaffected** (`private_value` exists) | — |
| `NMTE-20` | **Live, unaffected** | — |

---

## 7. Recommended walk order

1. **The scope question first** (§4.1). It is cheap, and it sets how much detail the rest
   deserves.
2. **The modality question second** (§3.1). Every arbitration and lifetime answer depends on it.
3. **Then `NMTE-2`, `NMTE-14`, `NMTE-19`, `NMTE-20`** — genuinely open, no precedent, quick.
4. **Then the narrowed residues** — the content-rect signal, Class E, the recovery rule, the
   Enter-to-results rule.
5. **Do not walk** `NMTE-4`, `NMTE-10`, `NMTE-16`. Record them as confirmed by precedence.
6. **Spin out** `NMTE-17`'s announcement half as a shell-level row rather than answering it here.

The three propagation debts in §5 are paid in the same session that walks the register, per the
standing rule that propagation happens where it is created.
