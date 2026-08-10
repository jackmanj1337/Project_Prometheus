---
Type: register
Status: OPEN - agenda prepared 2026-08-10, owner session not yet held
Last verified: 2026-08-10
Register: UITH-1..8
Tracker: SESSION-UI-THEMING-ALIGNMENT-2026-08-10
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Pack-Authorable UI Theming — Alignment Register and Session Agenda

**Purpose.** `SESSION-UI-THEMING-ALIGNMENT-2026-08-10` blocks any theme rollout until
pack-authorable theming is aligned with the four in-flight UI redesigns, so the rollout
is not built twice. That row lists eight decisions to leave with, T1–T8. This document
turns them into `[UITH-1..8]`, one per T, each with the measured evidence and a
recommendation to react to.

**IDs map one-to-one:** `[UITH-1]` = T1, `[UITH-2]` = T2, and so on.

**Do not re-derive the interaction vocabulary.** `PLAN-UIUX-REUSE-PASS-2026-07-24`
already ran and the owner accepted `UI-ARCH-01..06`. Read
[architecture research](../design/ui_ux_architecture_research_and_questions_2026-07-24.md)
and [interaction vocabulary](../design/ui_ux_interaction_vocabulary_2026-07-24.md)
first. Note that the vocabulary explicitly defers "visual-theme tokens, asset registries,
and final art language" — **this register is where that deferral is picked up**, which is
why role naming (`[UITH-3]`) belongs in the vocabulary doc rather than here.

---

## The finding that reframes the whole session

The row was written as "align theming with the redesigns." Reading the code changes the
question. **There are already three systems writing the same properties, and they do not
know about each other.**

| # | Authority | What it writes | How |
|---|---|---|---|
| 1 | `ResponsiveLayout.DENSITY_TOKENS` | `row_height`, `row_gap`, `body_font`, `detail_row`, `min_target`, `gutter`, `header`, `footer` — logical px, one set per Menu Mode | scenes read `token()` and call `add_theme_*_override` per node |
| 2 | `MenuScale._scaled_theme()` | `default_font_size` + five container separations | assigns a **derived duplicate** of the scene's authored Theme |
| 3 | `manasoul_ui.tres` StyleBoxes | `content_margin_*` — 14 px panel, 12/7 button | baked into the paint resources themselves |

Three consequences, all read from source on 2026-08-10:

1. **`ResponsiveLayout.gd:80` already legislates the answer to `[UITH-1]`:** *"No scene may
   carry a hard-coded pixel value; it reads a token from here."* That rule is in code, on
   `agent/integration`, today — and systems 2 and 3 both violate it.

2. **One screen has already escaped by opting out, and no general rule replaced it.**
   `MainMenu.gd:69` implements `apply_menu_scale(_factor)` and *ignores the factor*,
   calling `_apply_responsive_tokens()` instead. Its own comment (`:81-83`) says responsive
   tokens are already in logical pixels and applying menu scale too "would multiply the two
   density authorities." That is the correct local call and an unsustainable global one:
   the next screen converted will face the same fork with no policy to point at.

3. **MenuScale discards authored constants rather than scaling them.**
   `_scaled_theme()` duplicates the authored base Theme (that part is the V030-BUG-01 fix and
   is correct), then overwrites the five entries in `_SCALED_CONSTANTS` with
   `roundi(engine_default * factor)` — where the base value is the **engine default**, not
   the authored theme's value. Any `BoxContainer/separation` a theme author sets is silently
   replaced. **This is the mechanism by which a pack-authored metric would be lost**, and it
   is `[UITH-4]`'s constraint made concrete.

### A live defect on the themed scenes, distinct from the known slider one

MenuScale scales `default_font_size` and container separations. It does **not** touch
StyleBox `content_margin_*`. So on the seven scenes importing `manasoul_ui.tres`, raising
Menu Scale grows the type while the panel's 14 px content margin and the button's 12/7
padding stay fixed. At 200% the text is double size inside unchanged 9-slice padding.

**This is a code-level reading, not a rendered measurement** — it needs one screenshot at
200% on a themed scene to confirm, which the existing album can produce. Flagged because
the 133-shot album passes 133/133 today and, like the `SettingsScreen` slider split, has no
check that could see it.

### Verified counts (2026-08-10)

`manasoul_ui.tres` is an `ext_resource` on **7 of 21** `scenes/ui/*.tscn` and defines
**four** types only — Button, OptionButton, Panel, PanelContainer. `SettingsScreen.tscn`
imports it and contains **8** `HSlider` nodes, so it renders engine-default grey sliders
inside ornate 9-slice panels today. Unthemed across `scenes/ui/`: **94** `Label`, **27**
`RichTextLabel`, **11** `ScrollContainer`, **8** `HSlider`, **7** `HSeparator`, **0**
`LineEdit`. `theme_type_variation` — Godot's mechanism for painting different boxes
differently — has **zero** uses in the repo.

---

## The register

### [UITH-1] — The metric/paint split — RECOMMENDATION, owner call owed

**Question (T1).** Do density tokens own all metrics, leaving the Theme to own only paint
(colors, styleboxes, icons, fonts)?

**Recommendation: yes, with the correction that StyleBox content margins are metrics
wearing paint's clothing, and must be *derived*, not authored.**

A `StyleBoxTexture` carries both the 9-slice art (paint) and `content_margin_*` (metric,
because it sets the padding every child lays out against). A clean split is therefore not
achievable by assigning whole resources to one system: the theme assembler must **compute**
`content_margin_*` from the density tokens at assembly time and write them into the
StyleBox, rather than let an author hand-set 14.0 as `manasoul_ui.tres` does today.
`texture_margin_*` stays with the art — it describes how the bitmap slices, not how content
sits.

**Then retire the duplication.** With metrics owned by tokens, MenuScale's
`_SCALED_CONSTANTS` and `default_font_size` scaling become a second authority for values
the tokens already carry. Either MenuScale's factor becomes an input to the token
computation (one authority, two inputs), or MenuScale keeps typography and tokens keep
layout — but the current state, where both write and one silently overwrites, cannot
survive a pack that authors metrics.

**Do not decide here:** whether Menu Scale remains a separate player preference at all.
That is a player-facing question and belongs with the responsive redesign, not this session.

### [UITH-2] — Where roles attach: UIREC components or bespoke scenes — RECOMMENDATION

**Question (T2).** Does theming ride `EPIC-SHARED-RECORD-UI-V1`'s component library, or
precede it? This decides sequencing for everything else.

**Recommendation: theming rides UIREC for the record screens, and precedes it for the
chrome that UIREC will never own.**

The split is not a compromise; the two sets have different lifetimes. UIREC-V1-S03/S04
replace the *structure* of the record screens (Load, New Game, Campaign Library, Promotion,
Reclass, Unit Details), and `SMALL-SCREEN-UI-REDESIGN-2026-08-05` reflows the same set —
theming those scenes now is work thrown away twice. But HUD, PhaseBanner,
RuleFlipNotification, GameOver, MapResults and the dialogs are **not** record screens, are
not in UIREC's scope, and can be themed on today's structure without collision.

The practical consequence for the session: `[UITH-6]`'s coverage gap splits along the same
line, and the answer to "when can a rollout start" is *now, for the non-record chrome*.

### [UITH-3] — The role list is a versioned API — RECOMMENDATION, hardened by 2026-08-10

**Question (T3).** The published role list is a versioned API — authors cannot invent roles
because they cannot edit `scenes/ui/`, and a rename breaks every pack. Name roles
semantically (frame, dialog, tooltip, hud, danger), never visually.

**This is no longer a preference — it became structural on 2026-08-10.** The owner decided
that day, on `DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31`, that the editor generates flat
RGBA panels for a new pack and that **pre-selected UI element combinations are distributed
separately**. A separately distributed combination is a theme pack with third-party
consumers on their own release cadence: a role rename breaks packs the build has never
seen and cannot migrate. So the role list must ride `format_version` /
`builder_content_version` with a real compatibility story, not merely "be named carefully."

**Mechanism recommendation:** `theme_type_variation`, which has zero current uses and is
exactly Godot's supported way to paint the same Control class differently by role. Adopting
it is what makes a role list expressible at all.

**Recommendation on home:** the role names belong in
[ui_ux_interaction_vocabulary_2026-07-24.md](../design/ui_ux_interaction_vocabulary_2026-07-24.md),
which is the project's naming authority and which explicitly deferred exactly this.

### [UITH-4] — What a pack may author: paint only, or metrics too — RECOMMENDATION

**Question (T4).** May a pack author the four metric-changing items — border content
margins, font, scrollbar width, slider grabber size?

**Recommendation: paint only in v1, with font as the single deliberate exception.**

- **Content margins — no.** Per `[UITH-1]` they are derived from tokens. A pack that sets
  them fights the density system, and `MenuScale._scaled_theme()` would silently discard the
  value anyway for the five container constants.
- **Font — yes.** `AssetResolver.gd` already ships a pack-scoped `raw_font` loader with path
  safety (`_safe_relative_path` rejects absolute, `res://`, `user://` and `..`), and
  `manasoul_ui.tres` already carries a font with an in-file comment inviting the swap. The
  capability exists; withholding it would be a deliberate removal. Metrics stay derived: the
  pack supplies the face, the tokens supply the size.
- **Scrollbar width and slider grabber size — no, on a safety argument.** Grabber art sets
  the touch target, and `ResponsiveLayout` publishes `min_target: 44.0` for touch mode
  (Material 48dp / Apple HIG 44pt). A pack shipping a 20 px grabber would produce an
  unhittable control on a phone — the same failure class as the mobile controller's
  off-screen/overlap rule, which is already an enforced finding in the harness. If this is
  ever opened up, it needs a validator asserting the rendered target against `min_target`,
  and that validator should be the precondition, not a follow-up.

### [UITH-5] — Editor reuse — RECOMMENDATION

**Question (T5).** Same Theme and roles for the campaign editor, and its relation to the CSA
palette-swap and asset-manager surfaces (CSA-11, CSA-17, CSA-18)?

**Recommendation: same roles, and the editor is the *first* consumer, not the second.**

The 2026-08-10 palette decision makes the editor the thing that generates a pack's starting
art, so it must already speak the role vocabulary in order to generate one panel per role.
That inverts the assumed order: the role list is an editor input before it is a rollout
input. It also gives `[UITH-3]` a free consistency check — if the editor cannot enumerate
the roles well enough to generate a flat panel for each, the role list is underspecified.

**Open sub-question for the session:** does the editor's own chrome use the *active pack's*
theme (authors see their work in situ, but a broken pack theme makes the editor unusable) or
a fixed editor theme with the pack theme confined to a preview surface? Recommend the latter
— a pack must not be able to break the tool that edits it.

### [UITH-6] — Scheduling the coverage gap — RECOMMENDATION

**Question (T6).** Schedule sliders, scrollbars, Label/RichTextLabel and the dialogs into
whichever vehicle wins `[UITH-2]`.

**Recommendation: split by `[UITH-2]`'s line and fix the live defect immediately.**

The `SettingsScreen` slider split is a *present* defect on a scene players see, not a
rollout item: 8 `HSlider` nodes rendering engine-default grey inside 9-slice panels. Adding
`HSlider` and `ScrollBar` to `manasoul_ui.tres` is a bounded change to one resource that
does not depend on `[UITH-2]`, `[UITH-3]` or UIREC, and it makes the largest visible
difference for the least thrown-away work.

`Label` (94) and `RichTextLabel` (27) are the opposite case: they are everywhere, they are
what UIREC's components will own, and theming them per-scene now is precisely the rollout
this session exists to prevent. Hold them for the component library.

### [UITH-7] — The CV coupling and the theme-provenance field — DECIDED IN PART

**Question (T7).** The diagnostic repaint proposed for `EXP-CV-SCREENSHOT-CHECKS-2026-08-10`
depends on the role list, so J4 occlusion and J6 within-case diffing stay reports and are
not gated until it exists. A theme-provenance field on `WebTestBridge` would have flagged
the 7-of-21 split exactly.

**Status: the reports-not-gates half stands and needs no owner time.** The provenance field
is the live part.

**Recommendation: fold theme provenance into `BRIDGE-SNAPSHOT-STALENESS-2026-08-10`'s
version bump.** Unlike the rest of T7 it does **not** depend on the role list — it reports
which theme resource is in effect for a control, which is knowable today. That row was
already widened on 2026-08-10 to carry the staleness fields, the `set_process(false)` fix,
and (per the same day's OCR decision) per-control text plus a truncation signal, and it must
bump the version-locked `VERSION`/`SUPPORTED_VERSION` handshake against
`tools/playwright/lib/bridge.mjs` in lockstep. A fourth field costs one line there and a
second cross-repo bump later.

It is the only proposed check that would catch the 7-of-21 split, and it would have caught
it on the day the theme landed.

### [UITH-8] — Sequencing against the v0.8.0 hold — RECOMMENDATION

**Question (T8).** How does this sequence against `V080-RESPONSIVE-MAIN-MENU-2026-08-08`,
held out of `agent/integration` until the v0.8.0 line opens?

**Recommendation: treat the V080 branch as evidence now and merge it unchanged later.**

Its two commits (tip `1b3acd81`, work in `f7a48f27`) touch five files and add no new class —
the tracker's description of "a `ResponsiveLayout` class plus density tokens" on that branch
is inaccurate: `ResponsiveLayout.gd` is an **autoload already on `agent/integration`**, and
the V080 branch only *consumes* it from `MainMenu.gd`. So there is no held-back
infrastructure blocking this session, and nothing here needs the v0.8.0 line to open.

What the branch does contribute is the precedent in finding 2 above — the first screen to
opt out of MenuScale. Decide `[UITH-1]` knowing that `MainMenu.gd` will need revisiting
under whatever rule wins, and that this is a small, contained edit rather than a reason to
delay.

---

## What this session must not do

- Re-derive `UI-ARCH-01..06` or the interaction vocabulary. Both are accepted.
- Ratify art direction. `manasoul_ui.tres` is a *draft* built from a CC0 kit, and the
  licensing/pack questions belong to the CSA register.
- Start any rollout across the 14 unthemed scenes before `[UITH-2]` is answered — that is
  the specific waste the blocking row exists to prevent.

## Corrections this pass made to existing documents

- `docs/web-visual-verification-plan-2026-08-10.md` (container repo) asserted the bridge
  publishes a `Label`'s text; it does not. Corrected there.
- The tracker's description of the V080 branch contents is wrong — see `[UITH-8]`.
- [ui_ux_architecture_research_and_questions_2026-07-24.md](../design/ui_ux_architecture_research_and_questions_2026-07-24.md)
  states under `UI-TOOL-01` that the bridge "must compile only into a dedicated test export
  … and stay absent from production exports." **That was superseded on 2026-08-10**, when the
  owner decided the bridge ships in public web builds, gated and read-only. Flagged rather
  than edited here: that doc is an accepted record of a 2026-07-24 decision, and the session
  should choose whether to annotate it in place or leave the supersession to the tracker.
