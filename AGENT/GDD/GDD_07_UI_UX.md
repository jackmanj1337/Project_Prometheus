---
Role: topic
Topic ID: GDD-07-UI-UX
Last verified: 2026-08-24
---

# GDD_07 — UI & UX

**Status:** Active cross-cutting UI/UX contract; input/cursor and screen/panel detail
are split into the companion GDD_07 contracts linked below.
**Last verified:** 2026-08-24
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This entry chapter owns UI principles, navigation/state relationships, feedback,
accessibility, and parity obligations. Input/cursor mechanics and individual surface
contracts live in the companions below. Platform and renderer targets remain in
`GDD_00 §Platform Targets` (`OPEN-8`, `OPEN-11`); settings persistence schema is code-owned by
`SettingsManager` and cross-system save ownership lives in `GDD_01`.

---

## Companion Contracts

- [Input And Cursor](GDD_07_Input_Cursor.md) — action bindings, active input mode,
  mouse/touch/gamepad behavior, repeat policy, tactical cursor, and threat display.
- [Screens And Panels](GDD_07_Screens_Panels.md) — menu, HUD, modal, settings, and
  result-surface contracts.

---

## Design Reference

Status: **Reference** (design principles)
Last verified: 2026-06-13

The UI is inspired by **classic 16-bit tactical RPG interfaces**. Key principles:

- Clean, minimal overlays that do not block map visibility unnecessarily
- All important numbers are always visible before the player commits to an action
- Panels appear and disappear quickly; no slow animations on menus
- Keyboard-primary input with full mouse support

---

## UI State Machine

Status: **Implemented**
Last verified: 2026-06-13

The HUD operates as a state machine. Only one primary panel is active at a time.
`MapCursor` manages state and shows/hides panels by calling methods on `HUD`.

```
HUD States:
  FREE          — UnitInfoPanel + TerrainInfoPanel + ObjectivePanel visible
  UNIT_SELECTED — same as FREE (movement overlay active)
  ACTION_MENU   — contextual ActionMenu visible
  TARGETING     — target cycling active; AttackPreview may be visible
  STAFF_TARGET  — target cycling active for healing staff use
  ITEM_MENU     — ItemMenu visible
  WEAPON_MENU   — WeaponMenu visible
  MAP_MENU      — MapMenu visible (pauses cursor)
  DETAILS       — UnitDetailsScreen visible
  LEVEL_UP      — LevelUpScreen visible (cursor locked)
  PROMOTION     — PromotionScreen visible
  RECLASS       — ReclassScreen visible
  RESULTS       — MapResultsScreen for victory; GameOverScreen for defeat
  LOCKED        — cursor input suspended during animation or controller handoff
```

---

## Visual Feedback Summary

Status: **Split** — state/HP/level-up feedback **Implemented**; combat hit/miss/crit/death FX **Planned** (with the combat-animation system)
Last verified: 2026-06-13

| Event | Visual Feedback |
|---|---|
| Unit selected | Blue movement tiles appear; a dedicated selection ring is planned |
| Unit moved | Blue/red tiles update for new position |
| Unit acted (DONE) | Unit sprite darkened/greyed |
| New player phase | All unit sprites return to normal color |
| Attack hits | [PLACEHOLDER] brief flash on target sprite |
| Attack misses | [PLACEHOLDER] "Miss" text above target |
| Critical hit | [PLACEHOLDER] brighter flash; different sound |
| Unit dies | [PLACEHOLDER] death animation; unit fades out |
| Unit healed | [PLACEHOLDER] green flash; HP bar updates |
| Level up | Gold flash on unit sprite; LevelUpScreen shown |
| Weapon breaks | [PLACEHOLDER] weapon removed from inventory notification |

---

## UI Theming

Status: **Split** — `[UITH-1]`–`[UITH-5]` **Ruled** (by `UUI`, 2026-08-12); `[UITH-6]` first
half **Implemented**, second half **Held** for UIREC; `[UITH-7]` and `[UITH-8]` **Ruled**
(2026-08-23). No owner call is outstanding on this subject.
Last verified: 2026-08-23

This section owns **pack-authorable UI theming**: what a campaign pack may repaint, which
system owns which property, and how a rollout across the unthemed scenes is sequenced. It
absorbs the `UITH-1..8` register, which was prepared 2026-08-10 as the agenda for
`SESSION-UI-THEMING-ALIGNMENT-2026-08-10` and never landed on the docs line. The register
file is retired; this section is its single home. Every measurement below was **re-taken
2026-08-23** — five of the register's 2026-08-10 figures had changed and are corrected here.

### The finding that frames the subject

**Three systems write the same properties and do not know about each other.**

| Authority | What it writes | How |
|---|---|---|
| `ResponsiveLayout.DENSITY_TOKENS` (`:139`) | `row_height`, `row_gap`, `body_font`, `detail_row`, `min_target`, `gutter`, `header`, `footer` — logical px, one set per Menu Mode | scenes read `token()` and call `add_theme_*_override` per node |
| `MenuScale._scaled_theme()` (`scripts/ui/MenuScale.gd`) | `default_font_size` plus the five `_SCALED_CONSTANTS` container separations (`:52`) | assigns a derived duplicate of the scene's authored Theme |
| `assets/themes/manasoul_ui.tres` StyleBoxes | `content_margin_*` — 14.0 on the panel (`:42`), 12.0/7.0 on the button (`:53`) | baked into the paint resources themselves |

`ResponsiveLayout.gd:133` already legislates the answer — *"No scene may carry a hard-coded
pixel value; it reads a token from here"* — and authorities 2 and 3 both violate it today.

Two consequences are load-bearing and still live:

- **`MenuScale` discards authored constants rather than scaling them.** `_scaled_theme()`
  duplicates the authored base Theme (correct — that duplication is the `V030-BUG-01` fix),
  then overwrites the five `_SCALED_CONSTANTS` entries with `roundi(engine_default * factor)`,
  where the base is the **engine default and not the authored theme's value**. Any
  `BoxContainer/separation` a theme author sets is silently replaced. This is the concrete
  mechanism by which a pack-authored metric would be lost.
- **One screen has already escaped by opting out, and no general rule replaced it.**
  `MainMenu.gd:75` implements `apply_menu_scale(_factor)` and ignores the factor, calling
  `_apply_responsive_tokens()` instead; its comment says applying menu scale as well "would
  multiply the two density authorities." That is the correct local call and an unsustainable
  global one — the next screen converted faces the same fork with no policy to point at.

**A live defect distinct from the slider one — CONFIRMED IN A BROWSER 2026-08-23.**
`MenuScale` scales `default_font_size` and container separations but does **not** touch
StyleBox `content_margin_*`, so on the themed scenes raising Menu Scale grows the type while
the panel's authored padding stays fixed. This was a code-level reading until it was driven:
`SettingsScreen` at `1280×800`, Menu Scale `1.0` against `2.0`, on a web export of this
commit.

| Measured at 1280×800 | Menu Scale 1.0 | Menu Scale 2.0 |
|---|---|---|
| Panel interior x-span | `266..1014` (749px) | `266..1014` (749px) — **unchanged** |
| First label's left edge | `x=274` | `x=274` — **unchanged**, 8px inset either way |
| Label cap height | 12px | 24px — **exactly 2×** |

So the type doubles inside padding that does not move: the ornate frame keeps its authored
inset while the text it wraps grows to fill it. The 133-shot album passes today and **has no
check that could see this**, because nothing compares an inset against the type it surrounds.
Reproduce with `scripts/playwright-drive.sh --repo Project_Prometheus --screen settings
--viewport 1280x800 --menu-scale 2.0` from the container repo.

### Measured coverage (re-taken 2026-08-23)

`manasoul_ui.tres` is an `ext_resource` on **7 of 22** `scenes/ui/*.tscn` and now defines
**six** types — Button, **HSlider**, OptionButton, Panel, PanelContainer, **ScrollBar**.
Unthemed across `scenes/ui/`: **97** `Label`, **27** `RichTextLabel`, **12**
`ScrollContainer`, **7** `HSeparator`, **0** `LineEdit`. `theme_type_variation` still has
**zero uses outside documentation**, so `[UUI-13]`'s adoption remains greenfield.

*Corrections against the register's 2026-08-10 figures: four types became six and the
`HSlider`/`ScrollBar` gap is closed (`[UITH-6]` first half shipped); 21 scenes became 22;
Label 94 → 97; ScrollContainer 11 → 12; `MenuScale` lives at `scripts/ui/MenuScale.gd`,
not an autoload, and `ResponsiveLayout`'s token rule moved from `:80` to `:133`.*

### The rulings

- **Density tokens own metrics; the Theme owns paint (`[UITH-1]`).** Content margins are
  metrics wearing paint's clothing: a `StyleBoxTexture` carries both the 9-slice art and
  `content_margin_*`, which sets the padding every child lays out against. A clean split is
  therefore not achievable by assigning whole resources to one system — the theme assembler
  **computes** `content_margin_*` from the density tokens at assembly time and writes them
  into the StyleBox. `texture_margin_*` stays with the art: it describes how the bitmap
  slices, not how content sits. Ruled as `[UUI-9]`. **The duplication this implies must
  still be retired** — with metrics owned by tokens, `MenuScale`'s `_SCALED_CONSTANTS` and
  `default_font_size` scaling become a second authority for values the tokens already carry.
  Whether Menu Scale survives as a separate player preference is a player-facing question
  owned by the responsive redesign, not by this section.
- **Theming rides UIREC for the record screens and precedes it for everything else
  (`[UITH-2]`).** The two sets have different lifetimes: `UIREC-V1-S03/S04` replace the
  *structure* of Load, New Game, Campaign Library, Promotion, Reclass and Unit Details, and
  the small-screen redesign reflows the same set, so theming those now is work thrown away
  twice. HUD, PhaseBanner, RuleFlipNotification, GameOver, MapResults and the dialogs are not
  record screens, are not in UIREC's scope, and can be themed on today's structure without
  collision. Ruled as `[UUI-4]`.
- **The published role list is a versioned API (`[UITH-3]`).** Roles are named semantically —
  `frame`, `header`, `footer`, `list_row`, `detail_pane`, `action`, `danger`, `tooltip`,
  `hud`, `dialog`, `slider` — never visually. Authors cannot invent roles because they cannot
  edit `scenes/ui/`, and themes are distributed separately on their own cadence, so a rename
  breaks packs the build has never seen and cannot migrate; the list rides `format_version` /
  `builder_content_version` with a real compatibility story. The mechanism is
  `theme_type_variation`. Ruled as `[UUI-13]`, which also assigns the role
  **names** to the project's interaction-vocabulary authority rather than to this section.
- **A pack may author paint and the font face, nothing else (`[UITH-4]`).** Content margins
  are derived, so a pack that sets them fights the density system and `MenuScale` would
  discard the value anyway. Font **face** is the deliberate exception — `AssetResolver.gd`
  already ships a pack-scoped `raw_font` loader with path safety, and `manasoul_ui.tres`
  already carries a font with an in-file comment inviting the swap, so withholding it would
  be a deliberate removal; the pack supplies the face and the tokens supply the size.
  Scrollbar width and slider grabber size stay engine-owned **on a safety argument**: grabber
  art sets the touch target and `ResponsiveLayout` publishes `min_target: 44.0` for touch
  mode, so a pack shipping a 20px grabber would produce an unhittable control on a phone. If
  that is ever opened up, a validator asserting the **rendered** target against `min_target`
  is the precondition, not a follow-up. Ruled as `[UUI-10]`.
- **The editor is themed with the application chrome, not separately (`[UITH-5]`).** The
  campaign editor shares its theme with the Main Menu, pack management and Campaign Library;
  the player or author picks that theme. **This supersedes the register's original
  recommendation** of a fixed editor theme plus a pack-theme preview surface: the "a pack must
  not be able to break the tool that edits it" risk is handled by scope rather than by a
  fallback, because a pack simply cannot paint the editor. Ruled as `[UUI-14]`. What survives
  from the register is the sequencing observation — the editor generates a pack's starting
  art, so it must speak the role vocabulary first, which makes the role list an **editor
  input before it is a rollout input** and gives `[UITH-3]` a free consistency check.
- **The coverage gap is scheduled along `[UITH-2]`'s line (`[UITH-6]`).** Sliders and
  scrollbars were a *present* defect on a scene players see — eight `HSlider` nodes rendering
  engine-default grey inside authored 9-slice panels — not a rollout item, and adding
  `HSlider` and `ScrollBar` to `manasoul_ui.tres` depended on neither `[UITH-2]`, `[UITH-3]`
  nor UIREC. **That half is built.** `Label` (97) and `RichTextLabel` (27) are the opposite
  case: they are everywhere, they are what UIREC's components will own, and theming them
  per-scene now is precisely the rollout this subject exists to prevent — **held for the
  component library.** The verification obligation this carries is in
  [Accessibility & Input Parity](#accessibility--input-parity): a themed control asserts it is
  not holding `ThemeDB`'s default, because a silent fallback and a styling opinion look
  identical.

- **A theme-provenance field on `WebTestBridge`, on its own contract bump (`[UITH-7]`).** The
  half of this that needs no owner time already stands: the diagnostic repaint proposed for the
  CV screenshot checks depends on the role list, so occlusion and within-case diffing stay
  **reports, not gates**, until that list exists. The live part — a provenance field reporting
  which theme resource is in effect for a control — does **not** depend on the role list and is
  knowable today. **The register's recommendation to fold it into
  `BRIDGE-SNAPSHOT-STALENESS-2026-08-10`'s version bump is void:** that row completed
  2026-08-11 and the bump is spent. `WebTestBridge.gd:13` and the container repo's
  `tools/playwright/lib/bridge.mjs:31` both sit at `2`, and `bridge.mjs:104` tests **strict
  equality**, so a one-sided bump does not degrade — the harness reports the bridge
  unsupported. Ruled 2026-08-23: build it as its own change, bumping `VERSION` and
  `SUPPORTED_VERSION` 2→3 in a single cross-repo landing, tracked as
  `BRIDGE-THEME-PROVENANCE-2026-08-23`. It remains the only proposed check
  that would have caught the 7-of-22 theme split on the day the theme landed, and the 133-shot
  album cannot substitute for it — the album passes today against the `content_margin_*` defect
  measured above.
- **Density tokens are the single density authority; a token-consuming screen ignores Menu
  Scale (`[UITH-8]`).** **The sequencing question this ID was opened for is moot.**
  `V080-RESPONSIVE-MAIN-MENU-2026-08-08` merged into `agent/integration` on 2026-08-20
  (`14d192d4`) for the v0.7.8 Windows build — and not unchanged, since a conflict was resolved
  in `scripts/ui/MainMenu.gd` where the branch predated `CampaignPackRegistry`. What survived
  was the opt-out precedent, and that is what is now ruled. Ten UI scripts implement
  `apply_menu_scale`; exactly one — `MainMenu.gd:75` — ignores the factor and calls
  `_apply_responsive_tokens()` instead, on the argument that applying both "would multiply the
  two density authorities". **That local call is now the general rule:** a screen that reads
  `ResponsiveLayout` tokens does not also apply the Menu Scale factor, and `apply_menu_scale`
  becomes a legacy path each of the remaining nine screens sheds as it converts, retired with
  the last unconverted screen. This settles the *authority* half that `[UITH-1]` left dangling.
  It does **not** decide whether Menu Scale survives as a player-facing preference — that stays
  with the responsive redesign — but if it does survive, it survives as an **input the theme
  assembler folds into token computation**, never as a second writer.

### What a theming rollout must not do

- Start across the unthemed scenes before `[UITH-2]`'s record/chrome line is respected —
  that is the "built twice" failure the whole subject exists to prevent.
- Theme `Label` or `RichTextLabel` per scene ahead of the component library.
- Let a pack set any value the density tokens own.
- **Treat `manasoul_ui.tres` as ratified art direction.** It is a *draft* assembled from a
  CC0 kit; the licensing and pack-distribution questions it raises belong to the campaign
  art register (`CSA`), not here. Painting more controls with it is not a decision that the
  look is final.
- Introduce a second writer of density metrics alongside the tokens — including reviving
  `MenuScale`'s `_SCALED_CONSTANTS` path on a converted screen (`[UITH-8]`).
- Re-derive `UI-ARCH-01..06` or the interaction vocabulary. Both are accepted.

---

## Accessibility & Input Parity

Status: **Split** — input parity, rebinds, pacing, menu scaling, HUD layout, display
controls, safe-area seams, and the viewport **expand** model + `content_scale_factor`
UI-scale setting are **Implemented** (the expand/anchoring migration is Pending owner visual
validation — see the display/scaling obligation below); combat-animation feedback remains
**Planned**
Last verified: 2026-08-04

The UI must expose the same gameplay capabilities across keyboard/mouse, gamepad,
touch-facing interaction, and non-blue hotseat controllers. Device-specific mechanics
and the fixed mode vocabularies are binding in
[GDD_07 — Input And Cursor](GDD_07_Input_Cursor.md); individual settings and
inspection surfaces are binding in
[GDD_07 — Screens And Panels](GDD_07_Screens_Panels.md).

Cross-cutting obligations:

- All information needed to commit combat is visible through forecast, unit details,
  terrain information, and More Info; no input method gets exclusive gameplay data.
- Movement speed, phase-banner pacing, level-up presentation, menu scale, HUD layout,
  terrain dim (`[MRD-5]`), display mode/resolution, and map zoom remain independently
  configurable where their owning surface says they are implemented.
- Menu/modal scaling renders fonts and layout metrics at the selected size and clamps
  content to the usable viewport. The structural `UI-VIEWPORT-ASPECT` migration has landed
  (`IMPL-VIEWPORT-ANCHORING`, Implemented 2026-08-01, Pending owner visual validation): the
  renderer runs the **expand** model (`content_scale_aspect=EXPAND`, `content_scale_size=(0,0)`)
  with a persisted `content_scale_factor` UI-scale setting whose first-launch default lands on
  the identity diagonal so existing players see no change. **A mobile browser defaults
  differently, and deliberately:** the identity diagonal is derived from the screen and
  calibrated for a desktop monitor at desk distance, which on a phone canvas selects the
  smallest factor available. There the default is instead the largest 0.5 step that still
  fits the 1280×720 design floor inside the actual canvas, snapped **down** so rounding
  can never push the viewport below the floor and clip authored layouts. The player
  adjusts it through the
  **Viewport Scale** slider in Settings › Display (a lower factor reveals more map tiles). Menu
  scale is now reconciled with —
  not stacked on — the global factor, and menu/HUD centring is anchor-based (the imperative
  `MenuScale._recenter()` path is retired).
  **Stale against the new floor (noted 2026-08-06):** the 1280×720 here is the *retired*
  floor, hard-coded as `1280.0 / 720.0` in `fit_content_scale_factor_for_size`. On a
  1179×2556 phone it snaps to **0.5**, giving a 2358×5112 logical viewport and body type
  at 2.7 CSS px — the measured portrait defect. Against the ratified 360×640 floor the same
  phone resolves to **3.0** and 393×852, which is Compact at 16 CSS px. It is deliberately
  **not** flipped yet: doing so before the screen conversions would make portrait large and
  broken instead of small and unclipped. Sequenced in `responsive_ui_programme_2026-08-06.md`.
- Centered temporary windows use safe-centered frames capped at 90% of the usable
  viewport. The cap is a ceiling, never a target: a window occupies its authored size
  when that fits, and only the excess is trimmed. A scene may state that size either as
  a `custom_minimum_size` or as an anchor span plus offsets — both are read as the
  preference, and a window with neither sizes to its content. Bounded scroll owners keep
  content reachable when menu scale, viewport scale, or padding leaves less room.
  Legacy top-left-authored frames are normalized to the same center-anchor contract.
- HUD custom layouts persist as versioned panel-to-safe-viewport attachment pairs.
  Both endpoints use the eight corners/edge midpoints, retain a logical-pixel offset
  and independent scale, reflow after viewport/content changes, and clamp the full
  scaled panel inside the safe rectangle. The editor exposes both attachments and an
  explicit nearest-pair action; dragging changes only the offset.
- **Display/scaling design floor:** **Superseded 2026-08-06** by the responsive redesign
  (owner decision). The floor was **1280×720** (desktop/web) with the mobile-portrait case
  deferred; it is now **360×640**, and mobile is no longer deferred. The obligation is
  unchanged in kind — every screen, panel, and beat must be playable at the fewest tiles the
  floor shows, and a bigger display revealing more is a comfort bonus that can never break a
  mechanic — but it now binds at the smaller size. Prior rationale and measured tile counts:
  `viewport_expand_more_tiles_scoping_2026-07-11.md`
  §0.1. Replacement:
  `responsive_ui_redesign_2026-08-06.md`.
- **Size class:** **Implemented 2026-08-06, Pending native validation.** Screens respond to a
  class derived from the logical viewport — `backing size ÷ content_scale_factor`, which the
  player owns — rather than being authored at one size and centred in whatever they are given.
  **Compact** below 600 logical px, **Medium** 600–1023, **Expanded** 1024 and above; today's
  1280×720 layouts survive as the largest class. `ResponsiveLayout` (autoload) publishes
  `size_class_changed` and carries the density token sets that Menu Mode selects between, plus
  the information-density token (Full / Standard / Minimal).
  **The class is live, not read once at startup:** the player can drag the window to an
  arbitrary size and can change Viewport Scale from the Settings screen while looking at it, so
  a screen can change class while open. Recomputation is debounced so a live window drag
  republishes once when it settles rather than once per frame, boundaries carry a 24 logical-px
  hysteresis so a window parked on one cannot oscillate, and the signal is emitted only on a
  real change — a screen that receives nothing cannot lose the player's selection, scroll
  position, or open More Info target. Unit Details now stacks its two panes below Expanded,
  replacing the hard-coded 900 px threshold that was the ad-hoc size class this generalises;
  that moves the 900–1023 band from side-by-side to stacked, which is the direction that cannot
  overflow the panel. Screens convert one per branch afterwards.
- **Menu Mode selects a density token column — four columns, one assembler, no exception
  lists.** Menu Mode began as a function of the **input device** (touch and controller are
  different densities because density follows the device, not a look-and-feel preference), and
  two rulings widened it to the **surface class**. `[UUI-11]` added **`dense`**: seven keyboard
  columns at 44 px with the authored touch tokens are 388 px and overflow the 360 floor, so
  rather than a local override or a named exception the ruling added a column in which keys
  still meet 44 pt and only the whitespace between them shrinks. It serves any surface that is
  wall-to-wall equal-weight targets, whatever is pointing at it. `[CEUI-S1]` added
  **`editor`**, because the campaign editor is a different *kind* of surface — heavy text
  entry, dense dropdowns, and a game session running inside it — and **the player's Menu Scale
  does not reach it**: the editor carries its own scale through the same assembler rather than
  becoming a second scaling system. `[CEUI-S50]` adopted the six editor-only tokens
  (`workspace_bar`, `tab_height`, `tree_width`, `inspector_width`, `form_measure`,
  `split_threshold`) that describe editor furniture with no game analogue; every column must
  define the eight shared tokens, so a column cannot half-land. The editor column's
  `min_target` is **24, not 44** — raising it would halve what the densest surfaces can show,
  and keyboard reachability is `[CEUI-S17]`'s obligation, which target size does not affect.
  An editor scale knob has no hard lower bound; below `DPR × scale = 1.0` it triggers
  `[UUI-18]`'s confirm-or-revert, which `[CEUI-S1]` inherits unchanged.
- **`row_height` is a floor, not a height (`[DSX-S22]`), and the extent budget is 1.4×
  (`[L10N-7]`).** Rows grow when their content does — a name plus a sub-line measures 35 px
  against the 28 px controller token, a 25% overrun *before* translation. The enforced
  text-expansion budget is **pseudolocalized 1.4× plus longest-token testing**, not the ~1.3×
  average that earlier responsive work assumed: 1.3× is a real-world mean, and means are not
  what clips — short labels have no slack and compound nouns routinely exceed it. Values
  truncate **after** labels, never before them. A layout that treats a density token as a
  fixed height clips in the language it was not authored in.
- **The size class is per surface, not per application (`[CEUI-S3]` call 1).** The campaign
  editor hosts the full runtime playing the pack being edited, inside the editor window, so
  the editor chrome sits at editor density while the game view derives its own class from its
  `SubViewport`. One global `size_class` cannot express that. The mechanism is the autoload
  itself: the instance is the root context and measures the window as before, an embedded
  session calls `create_context(sub_viewport)` for another instance bound to that viewport
  with its own class, tokens and signals, and consumers ask `context_for(self)`. **Resolution
  is by viewport, deliberately** — a screen asks which surface it renders into, never which
  mode the application is in; an is-embedded flag would have to be threaded through every
  screen and would be wrong the first time a surface is hosted somewhere new. The seam never
  returns null, so no consumer keeps the hard-coded fallback it exists to delete.
- **The editor's viewport floor is measured in effective pixels (`[CEUI-S2]`).** The editor's
  `1920×880` floor is evaluated against **window ÷ editor scale**, not raw window pixels —
  the same shape as this chapter's `backing size ÷ content_scale_factor`. An author on
  1366×768 who scales the editor down clears the floor and gets a working, if small, editor;
  below that an explanatory minimum-size state appears and **names the scale knob as the fix**.
  This supersedes the earlier dismissible below-1920×1080 warning. The input-mode half of that
  gate survives: an author whose input is not keyboard+mouse is warned, keyed off keyboard and
  mouse being present rather than off touch being absent.

- **Every themed control is painted, and a silent fallback is a bug (`[UITH-6]`).** A
  control left resolving Godot's default theme inside an authored 9-slice panel reads as a
  styling opinion rather than as a defect, which is how eight Settings sliders shipped
  engine-default grey. The failure mode the obligation guards is therefore not "the theme
  looks wrong" — headless cannot judge that — it is **the theme entry that silently falls
  back**: a mistyped type name, a wrong item name, or a texture that failed to load all
  produce the same default. Comparing a resolved stylebox against `ThemeDB`'s default object
  is what tells the two apart, so a themed control asserts it is *not* holding the default.

- HUD edge clamping reads the shared safe-area provider. Desktop resolves zero
  in-canvas insets. **A mobile browser now feeds real ones**: the PWA shell publishes
  `env(safe-area-inset-*)` in CSS pixels together with the canvas rectangle, and the
  provider converts both to viewport units before any panel sees them — window pixels
  per CSS pixel is measured from that rectangle rather than taken from
  `devicePixelRatio`, and the result is divided by `content_scale_factor` because
  consumers subtract insets from the post-scale viewport. Degenerate readings (a
  pre-layout canvas, a zero window, a non-numeric inset) resolve to zero rather than a
  guess. No panel call site changed, as this seam promised.
- At the accessibility stress case (1280×800, 2× content scale, 2× menu scale), New
  Game owns an outer vertical scroll region, Unit Details stacks its content and
  information regions, and Results collapses its report/actions flow vertically. The
  containing frame remains centered and inside 90% of the safe viewport; content
  scrolls before the selected type scale is reduced.
- Local Web UI inspection uses the production Web export plus an explicitly opted-in,
  read-only state bridge (`test_bridge=1`). Playwright still sends real pointer and
  keyboard input through the canvas; the bridge only reports the active screen, focus,
  post-transform control rectangles, scale settings, and text-entry state. Ordinary Web
  URLs expose no bridge. This is deterministic layout evidence, not a substitute for the
  native Windows/GPU visual pass.
- Display configuration follows `GDD_00` and the display/settings guide. Tactical
  camera zoom follows `GDD_06 §Tactical Camera`; this chapter owns only the settings
  and prompt surfaces.
- Documentation vocabulary guards (`DOC-011`) read the two companion contracts:
  input modes/bindings from Input And Cursor and character-sheet duration labels from
  Screens And Panels.
- `OPEN-11`'s delivered expand policy and remaining native validation are owned by
  `GDD_00 §Platform Targets`. The hidden
  `combat_animations` setting remains planned until a combat-animation system consumes
  it.

Code anchors: `scripts/autoloads/SettingsManager.gd`,
`scripts/autoloads/InputModeManager.gd`, `scripts/core/MapCursor.gd`, and
`scripts/core/HotseatController.gd`. Validation anchors:
`scripts/tests/test_settings_manager.gd`, `test_settings_screen.gd`,
`test_input_mode_manager.gd`, and the relevant UI scene tests.

---
