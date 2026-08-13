---
Type: design
Status: Accepted — precedence diff; the `RPD-1..18` owner walk has not started
Last verified: 2026-08-13
Tracker: RESPONSIVE-PREP-DEPLOYMENT-RESEARCH-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `RPD-1..18` — Precedence Diff Before the Owner Walk

Fourth `DOC-014` check in this series, after
[`skf_drc_precedence_diff_2026-08-13.md`](skf_drc_precedence_diff_2026-08-13.md),
[`drc_group_a_precedence_diff_2026-08-13.md`](drc_group_a_precedence_diff_2026-08-13.md) and
[`drc_groups_bcde_precedence_diff_2026-08-13.md`](drc_groups_bcde_precedence_diff_2026-08-13.md).
The three before it all changed the questions before the owner saw them, and one found its
predecessor partly wrong.

**Sources diffed.** `PHB-1..7` (prep hub, resolved 2026-06-23), `EPUX-01..28` and the
owner-ratified *"Prep hub structure, convoy, and shops"* section (2026-07-25/26), `UUI-1..19`
(2026-08-12), `L10N-1..18`, `TSV-1..24` and `CRD-1..10` (2026-08-13), `UBS-4` as ruled for Compact
and extended to Medium/Expanded (2026-08-13), `DRC-11`'s fifth-surface ruling, `DRC-19..24`'s
five-dimension unit-state model, `CAU-4` as amended, `REQ-1..16`, and the built code —
`scripts/autoloads/ResponsiveLayout.gd`, `scripts/shared/DeploymentPlan.gd`,
`scripts/ui/PrepScreen.gd`.

## Bottom line

**`RPD-1..18` cites zero ratified decisions.** Not one bracket id appears in either the register or
its comparative research — no `EPUX`, no `PHB`, no `UUI`, no `L10N`. This is a harder version of
the `TSV` failure recorded on 2026-08-13: `TSV` argued against ratified text three times and lost
all three, but it at least engaged with the corpus. `RPD` was written as though the prep surface
had never been designed, when in fact **the prep hub was resolved in June (`PHB-1..7`) and its
structure was ratified in July (`EPUX`, the whole *"Prep hub structure"* section)**, and both
answer questions this packet re-asks.

Nothing outside `RPD` cites `RPD`, so no propagation has run in either direction. The packet is
also one of the six that lived only on the unmerged
`agent/from-integration/responsive-prep-deployment-research` branch — already recorded as a
structural finding on the agenda row.

Disposition of the eighteen: **three closed**, **eight narrowed or reframed**, **five live
conflicts**, **two promoted** (they can close questions older registers explicitly deferred).

---

## 1. Closed by precedence — do not ask these

### 1.1 `RPD-6` — "does Manage Roster own *who* and Map Preview own *where*" was ratified in July

`EPUX`'s ratified prep-hub section says it in those words. *Manage Roster* — "on a battle node it
also holds **deployment selection** (which units deploy)". *Map Preview* — "place deployed units …
This is the *where* half of deployment; Manage Roster is the *who*." `RPD-6`'s recommendation is a
verbatim restatement of a decision that is fourteen months of project time old at this point and
already has a built seam: `scripts/shared/DeploymentPlan.gd` exists and is exercised by
`test_deployment_plan.gd`, which is `RPD-6`'s "both editing one live `DeploymentPlan`" half.

**Do not ask.** Record it as confirmed-by-precedence.

### 1.2 `RPD-18` — both halves are already ruled, by two different registers

`RPD-18` asks what deployment state survives leaving prep, saving, resizing or changing input mode.
It is two questions and both are answered:

- **Save/leave.** `[PHB-7]` (**RESOLVED → A**, owner 2026-06-23k): transactions commit immediately
  to persistent party state; **no bespoke hub-suspend snapshot**; re-entering prep **re-derives**
  the hub from party state. `RPD-18`'s recommendation — "a between-map campaign save does not
  persist the plan; returning later authors it again from the current campaign state" — is `PHB-7`
  re-derived from scratch, correctly, without knowing `PHB-7` exists.
- **Resize/input/theme.** `[EPUX-03]` (**RULED 2026-07-26**): one presentation controller, wide and
  narrow compositions chosen by *measured content width, never a platform name*, with **selected
  record and focused region preserved across the transition** — and explicitly including the case
  where 200% Menu Scale forces the narrow composition at a nominally wide viewport. `UUI-8` then
  made Menu Scale multiply the density tokens, so that path is live, not hypothetical.

**Do not ask.** Note in the register that `RPD-18` is `PHB-7` + `EPUX-03`.

### 1.3 `RPD-13`'s presentation half — `EPUX` already ruled pre-battle scouting

`EPUX`'s *"Shops and stock"* section ratifies on-map event presentation keyed by reason, and names
the case directly: "**Preview** (viewed from Map Preview pre-battle) → the same view, framed as
scouting." `DRC-11` then ruled the tactical map a **fifth `EPUX-02` availability surface** with the
same two-value vocabulary. So "reuse map inspection vocabulary" is not a recommendation to ratify;
it is the ratified answer.

**Residue survives and is real** — see §2.5.

---

## 2. Narrowed or reframed — ask the residue, not the question as written

### 2.1 `RPD-1`, `RPD-2`, `RPD-3` rest on a premise the hub structure already settled

`RPD-1` asks whether the map is "the persistent primary surface at every size class", and `RPD-2`
and `RPD-3` then design the adjacent controls that premise implies — three bottom-sheet pages in
Compact, a persistent drawer in Medium tablet.

The ratified structure does not have a persistent map. `[EPUX-01]` (**RULED**: A, two layers) makes
the node interior a **flat activity list**; *Map Preview* is **one of six top-level entries**
alongside Explore, Manage Roster, Save, Move to Next Primary Story Chapter and Start Battle. The
player is not in a map-first screen that grows controls — they are in a hub that they enter Map
Preview *from*.

`[EPUX-03]` goes further and names this panel specifically: Map Preview is listed as one of the
four **full-width escape-hatch** panels, where "the shell presents it **alone**, dropping the
companion pane; the parent level stays reachable by back/breadcrumb". So at every size class wide
enough to have two panes, Map Preview is already ruled to take the whole width by itself.

**The surviving question is a good one and should be asked in its place:** *inside* that full-width
panel, what does the map surface look like per size class — and that question is §3.1.

### 2.2 `RPD-7` and `RPD-8` — the placement model is ruled; only the gesture is open

`EPUX` ratified the whole placement flow: "the author **numbers start positions**; the engine
**auto-fills them from the deployment roster in order**; the player may **swap**. Placement is
never a mandatory chore."

So `RPD-8`'s "how are two occupied starting tiles swapped" is not asking whether Swap exists — Swap
is the ratified primitive — and `RPD-7`'s substitution flow starts from an auto-filled board, not
an empty one. Both narrow to **input-family ergonomics over a ruled model**, which is worth asking
because `UUI-2`'s two landscape control columns and the gamepad path from `UBS-4` both constrain it.

`RPD-7`'s "touch may drag only as an optional shortcut, never as the sole accessible route" is
consistent with everything ratified and can be confirmed rather than debated.

### 2.3 `RPD-9` — auto-fill changes what an empty slot means

Under `EPUX`'s auto-fill-in-order ruling, an empty start position occurs only when the deployment
roster is shorter than the authored slot list. That is a much narrower situation than "the player
left slots empty", and it makes `RPD-9`'s recommendation (neutral, do not imply the player is
wrong) nearly automatic. Ask only the exact-count case, which is a campaign-authored rule and
therefore a **predicate with an unmet reason** under `EPUX-02`, not a bespoke warning.

### 2.4 `RPD-11` — the panel registry already owns the split

`RPD-11` proposes Loadout / Skills / Details / Swap in the quick card with deep configuration
behind Manage Roster. `EPUX` ratified Manage Roster as "an **open registry of roster-config
panels**; only panels the campaign actually uses appear (no hardcoded FE-feature enum)". The
architecture principle in `AGENTS.md` §218 then forbids the quick card from being a hardcoded
four-entry enum for the same reason.

**Reframe:** not "which four actions", but *"is the quick card a registry projection filtered by a
`quick` flag, or a separately authored short list?"* — the closed-enum smell, which this project
has ruled against repeatedly.

### 2.5 `RPD-13`'s residue — mode return, not vocabulary

What `EPUX` and `DRC-11` do not answer is `RPD-13`'s own best sentence: a clear return to placement
mode so inspection never accidentally moves a unit. That is a live input-mode question and should
be asked.

### 2.6 `RPD-14` is a deferral, not a question

"Research before committing" puts nothing to the owner. There is also directly applicable ratified
precedent the packet does not cite: `EPUX`'s **subject memory** rule — remembered *firmly within a
prep visit*, *best-effort across visits*, falling back when the remembered subject died or left —
is the same invalidation problem `RPD-14` says needs research, already solved once with a
tiered-confidence answer.

**Either drop `RPD-14` from the walk or ask the sharp version:** does the subject-memory tiering
generalize to whole deployment plans?

---

## 3. The live conflicts — these must be settled, and two of them gate the rest

### 3.1 `RPD-4` versus `[EPUX-03]`'s pane budget: three panes are ruled out

`RPD-4` recommends Expanded use "roster / map / selected-unit panes **simultaneously**".

`[EPUX-03]`'s ruling: "**Never three panes**: a third collapses at 200% Menu Scale and steals width
from the terminal panel, which is the content that needs it most." Default is at most two, pairing
adjacent levels.

This is a direct contradiction of ratified text, and the reason given is not stylistic — it is the
Menu Scale collapse that `UUI-8` has since made more load-bearing, not less.

It is compounded by `UBS-4`, ruled **yesterday**, which rejected moving `map_talk` into a side rail
above Compact with this reasoning: "**the tactical map is a canvas, not a list+detail screen, so
the pane model would have to be extended to it**, and dialogue would become three presenters to
build and regression-test." `RPD-4` proposes exactly that extension, for the same kind of surface,
one day later.

**The question to put to the owner is the one underneath both:** *is Map Preview a **canvas** —
governed by `UBS-4`'s rule that surfaces occupy the canvas region and never the control band — or a
**list+detail screen** governed by the `EPUX-03` pane model?* Everything in `RPD-1..5` follows from
that single answer, and it is the only question in the packet that cannot be derived.

### 3.2 `RPD-5`'s FHD/4K framing introduces a breakpoint the size-class model does not have

`ResponsiveLayout.gd` defines **three** classes and derives them from logical width alone.
`UUI-1..19`'s album table calls 1280×720 "**Expanded 16:9 — the legacy authoring size, now the
largest class**". `RPD`'s own research is careful and correct here (it labels 1920×1080 "Expanded
FHD" and 3840×2160 "Expanded 4K"), but the **question text is not**: `RPD-4` says Mission and
Readiness are "expanded into their own regions **at FHD**", which is a second breakpoint *inside*
Expanded.

Not a contradiction — new machinery. Ask it as such: **does Expanded need an internal breakpoint,
or does a bounded workspace plus breathing room (`RPD-5`'s own recommendation) make one
unnecessary?** The second answer costs nothing and is consistent with `UUI`; the first adds a
concept every future responsive component inherits.

### 3.3 `RPD-10` proposes a sixth availability vocabulary — the `TSV-8` shape, a third time

`RPD-10` wants a "separate status glyph + text vocabulary" for required, excluded, dead and
otherwise unavailable units.

`[EPUX-02]` ruled **one** two-state rule — *absent* → hidden, *gated* → shown disabled **with a
reason** — and made it **uniform across all four availability surfaces**, one of which is the
Manage Roster panel registry where deployment selection lives. `[EPUX-04]` then put evaluation, the
hidden-vs-disabled decision, the disabled treatment and the reason placement **in the shell**, so
that "four adapters cannot drift into four different disabled treatments". `DRC-11` added the
tactical map as a **fifth** surface yesterday and *rejected* a richer three-value vocabulary
(`secret|hinted|explicit`) to do it.

`TSV-8` lost this same argument on 2026-08-13. `DRC-11` lost it later the same day.

**What genuinely survives, and it is not an availability question at all:** *dead* and *excluded*
are **unit state**, and `DRC-19..24` ruled five unit-state dimensions with a single unit-state
service owning every write. So the real question is whether deploy-eligibility is a `REQ` predicate
returning an `EPUX-02` unmet reason — free, uniform, already built — or whether the roster needs
status distinctions the predicate cannot express. Note `[RCR-4]` owes `REQ` a banner (recorded as a
Group A debt), and it is **`REQ`'s display path that supplies the reason string** this depends on.

### 3.4 `RPD-15` is already the ratified default — but it can close a question deferred twice

"Is Begin Battle always visible, even when invalid?" `EPUX-02`'s per-entry default is
`visible-disabled-with-reason`; `EPUX-04` puts the reason in the shell. `RPD-15`'s recommendation
is the ratified default, restated.

**What is new is its second clause: "keep it focusable."** That question has been explicitly open
since July and deferred twice in writing. `EPUX-02`: "*Derived, not ruled* — whether disabled
entries stay keyboard/controller-focusable so the reason is reachable by screen reader rather than
hover-only. Recommend focusable-but-not-activatable; **not settled here**." `EPUX-04` repeats it
and calls it "a **shell-level** decision too … deferred to `EPUX-06/07` and the accessibility
pass". Neither `EPUX-06` nor `EPUX-07` ruled it.

**Promote `RPD-15` to that question.** It is a shell-wide accessibility ruling affecting five
surfaces, not a prep question, and this is the first row in a position to close it.

### 3.5 `RPD-17` invents a third persistence mechanism where two were named yesterday

`RPD-17` recommends that "a suspend payload must be cleared through an explicit safe transition or
prep must be skipped — never allow a plan that spawn ignores."

Three ratified pieces already determine this:

1. `[PHB-5]` (**RESOLVED → A**): free navigation, **Begin Battle is the sole commit**; everything
   before it is revisable; manual Save available throughout.
2. `[PHB-7]` (**RESOLVED → A**): no bespoke hub-suspend snapshot; re-entering prep re-derives.
3. The **two-primitive ruling** (2026-08-13): a **staged transaction** (overlay + commit/discard)
   and a **snapshot** (capture + restore including the RNG stream), and *"prefer staging; snapshot
   only to undo something already committed."*

Put together, the deployment plan **is a staged transaction whose commit point is Begin Battle** —
which is `PHB-5` restated in the vocabulary ruled yesterday. Suspend then discards the stage
(`PHB-7`), and campaign Retry is a **snapshot** restore through `MapLedger`, which is what
`MapLedger` was already ruled to consume.

**Ask only the residue:** is that identification correct, and does bare-map Retry (which `RPD-17`
says stays direct) skip prep entirely or re-enter it with an empty stage? The "explicit safe
transition" mechanism `RPD-17` proposes should not be built — it is a third primitive beside two
that already cover the case, the same shape §3.1 of the Groups B–E diff caught in `DRC-33`.

### 3.6 `RPD-16` — "required unit" wants to be a flag, and that shape was retired yesterday

`RPD-16` asks what happens when a **required** unit is permanently dead. `RPD-10` lists *required*
as a status to display, which implies required-ness is a property carried on the unit.

`DRC-25` ruled the opposite shape for the closely related case: the recruitment transition
attaches to the **opportunity**, with **no `recruitable` truth flag on the unit**. `DRC-19..24`
retired `[RCR-2]`'s auto-set `recruited:<id>` flag for the same reason — it duplicated state the
dimensions already held. This is the duplicate-state shape that appeared **three times in one day**
on 2026-08-13 and is recorded as that session's real pattern.

A required unit is a property of **the mission**, expressed as a `REQ` predicate over the roster —
not a badge on the unit. `RPD-16`'s substance (author-time validation where possible, a specific
runtime contradiction, an author-selected fallback or block, never a silent drop) is sound and
mostly survives; but ask it in the predicate framing, and note that its author-time half rides
`[DLUX-10]`'s structured author-time warning contract, which already exists and should not be
reinvented.

### 3.7 `RPD-2`, `RPD-10` and `RPD-12` all owe `L10N` a 1.4× check

`L10N-7` binds every responsive component to a **1.4× text extent**, and `L10N-8` requires
composed strings be single localizable templates. `RPD-10`'s glyph **plus text** vocabulary,
`RPD-12`'s always-visible mission facts and `RPD-2`'s three bottom-sheet pages are all fixed-extent
proposals drawn before that rule bound them.

`UUI-1..19` recorded, in its own findings, that **"the published Compact row budget is optimistic
by half a row"** — before adding 1.4×. `RPD-12`'s "objective, defeat condition and exceptional
deployment constraint remain visible without opening Mission" is three text rows in the class with
the least room, and should be asked with that budget on the table rather than as a content
preference.

---

## 4. Suggested walk order

1. **§3.1 first and alone if time is short.** Canvas or pane model for Map Preview. `RPD-1`,
   `RPD-2`, `RPD-3`, `RPD-4` and `RPD-5` are all specializations of it, and it is the only question
   in the packet whose answer cannot be derived from ratified text.
2. **§3.3 and §3.4 together** — they are one shell-level availability/accessibility ruling and both
   reach beyond prep.
3. **§3.5 and §3.6** — the two duplicate-mechanism/duplicate-state catches.
4. **§3.2, then §3.7** — the Expanded breakpoint, then the row budget it interacts with.
5. **§2 residues** in register order: `RPD-7`/`RPD-8` gesture, `RPD-9` exact-count, `RPD-11`
   registry-or-list, `RPD-13` mode return, `RPD-14` if it is kept at all.
6. **Record §1's three as closed by precedence.** `RPD-6`, `RPD-18`, and `RPD-13`'s presentation
   half.

## 5. Debts this check records

- **`RPD` cites nothing and nothing cites `RPD`.** When the walk closes, `PHB` and the `EPUX`
  prep-hub section need banners pointing at the outcome, or the next packet will re-derive the same
  answers a third time.
- **`EPUX-02`/`EPUX-04`'s focusability deferral has been open since July** and was routed to
  `EPUX-06/07`, which never ruled it. Whatever §3.4 decides must be written back into both.
- **`[RCR-4]` still owes `REQ` a banner** — carried from the Group A check, and §3.3 depends on
  `REQ`'s display path.
- **The comparative research is sound; the register is what drifted.** The eight-viewport proof set
  correctly labels FHD and 4K as *Expanded*; only the question text invents a boundary. Preserve
  the research when amending.
