# Unified UI Programme — consolidated plan — 2026-08-12

Status: Active. **Supersedes
[`responsive_ui_programme_2026-08-06.md`](responsive_ui_programme_2026-08-06.md)**, which
sequenced four workstreams; this plan sequences eight. That document stays for its record of
what was done between 2026-08-06 and 2026-08-12.

Last verified: 2026-08-12

Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)

**Why this exists.** The 2026-08-06 programme consolidated the responsive redesign, the size-class
seam, mobile text entry and the mobile-web controller. Four more workstreams have since
accumulated that each touch the same scenes and none of which that plan covers: pack-authorable
UI theming, the shared record-screen UI epic, the unratified display-layers discussion, and the
campaign editor UI. A deep search on 2026-08-12 found **54 open UI-impacting tracker rows**
against **23 built UI scenes**. This is the single sequencing view for all of it.

**This plan owns the ORDER.** Decisions belong to
[`unified_ui_decisions_2026-08-12.md`](../registers/unified_ui_decisions_2026-08-12.md)
(`UUI-1..19`) and to the design docs named beside each item. Where they disagree about
sequence, this file is right; where they disagree about why, they are.

**Wireframe album (proof set):**
<https://claude.ai/code/artifact/34929585-0ec2-4e96-9040-b084ce5e7fe1>

---

## The sources

| Source | Owns |
|---|---|
| [`unified_ui_decisions_2026-08-12.md`](../registers/unified_ui_decisions_2026-08-12.md) | `UUI-1..19` — the ratified answers this plan sequences |
| [`responsive_ui_redesign_2026-08-06.md`](../design/responsive_ui_redesign_2026-08-06.md) | Size classes, the 360×640 floor, density tokens, per-screen conversion |
| [`text_entry_mobile_compact_2026-08-06.md`](../design/text_entry_mobile_compact_2026-08-06.md) | The keyboard/controller handover and the keyboard layout |
| [`mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md`](mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md) | The control region: dead-space rule, landscape rectangle, the 26% defect |
| [`ui_theming_alignment_open_questions_2026-08-10.md`](../registers/ui_theming_alignment_open_questions_2026-08-10.md) | `UITH-1..8` — superseded in part by `UUI-8..10`, `UUI-13..14` |
| [`unbuilt_screen_research_agenda_2026-08-12.md`](../registers/unbuilt_screen_research_agenda_2026-08-12.md) | The questions the unbuilt screens need answered before they can be drawn |
| [`ui_ux_interaction_vocabulary_2026-07-24.md`](../design/ui_ux_interaction_vocabulary_2026-07-24.md) | Naming authority; gains the `UUI-13` role list |

---

## Done

| | Row | Landed |
|---|---|---|
| 1 | `IMPL-VIEWPORT-ANCHORING-2026-07-31` | Closed as superseded 2026-08-06. Its 1280×720 floor retired; its `content_scale_factor` work survives and is the foundation everything rests on. |
| 2 | `SIZE-CLASS-SEAM-2026-08-06` | `ResponsiveLayout` autoload on `agent/integration`: three classes, debounced republish, 24px hysteresis, both token sets. |
| 3 | `SUPPRESS-WEB-OS-KEYBOARD-2026-08-06` | `experimentalVK:false` in `export_presets.cfg`, guarded by `test_web_export_preset.gd`. |
| 4 | Mobile controller Slices 1, 2, 4 and the Slice 3 game-view editor | Built and browser-verified; tip `06a22b92`, held. |
| 5 | `V080-RESPONSIVE-MAIN-MENU-2026-08-08` | Built at `1b3acd81`, 133 suites green, held for the v0.8.0 window. |
| 6 | **The decision walk** | `UUI-1..19` ratified 2026-08-12. Closes the landscape rectangle, the 26% band, the theming register's live half, and the Menu Scale authority conflict. |

---

## The two things everything else is queued behind

**One Windows session with a phone and a pad.** `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`
is display-gated on it. Until it closes, the Settings conversion cannot be *validated*, the
text-entry vocabulary change cannot land, and the display-gated visual evidence stays
uncollected.

> **Claim correction, measured 2026-08-12.** This paragraph originally said that row claims
> `SettingsManager.gd`, `SettingsScreen.gd` and `SettingsScreen.tscn` — repeating an
> assertion in [`responsive_ui_programme_2026-08-06.md`](responsive_ui_programme_2026-08-06.md)
> and [`open_questions_inventory_2026-08-06.md`](open_questions_inventory_2026-08-06.md).
> **The tracker does not support it.** `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`'s
> `claimed_paths` is `scripts/ui/text_entry` only. Swept against every open row:
> `SettingsScreen.gd`, `SettingsScreen.tscn`, `ResponsiveLayout.gd`, `MenuScale.gd`,
> `manasoul_ui.tres` and `DisplayConfirmDialog.gd` are **all unclaimed**. The one real path
> claim is `SettingsManager.gd`, held by `V070-RETURN-FIXES-2026-08-07` (`in_review`).
>
> So the gate is narrower than three documents claim. **Menu Mode and information density
> becoming persisted settings, and flipping the 1280×720 design-floor constant, wait on
> `SettingsManager.gd`** — not on the Windows return. `UUI-18` waits on neither. Verify a
> claim against `coordination/tasks.json` before treating it as a blocker; prose drifts and
> the tracker is the machine-readable authority.

**The v0.7.x acceptance gate.** `V07X-ACCEPTANCE-GATE-2026-08-11` is the single machine-readable
boundary for every v0.8-held branch. Nothing in phase 1 below merges to `agent/integration`
before it closes.

---

## Order of work

### Phase 0 — unblocked now, no dependencies

1. **`SettingsScreen` slider and scrollbar paint.** Eight `HSlider` nodes render
   engine-default grey inside ornate 9-slice panels on a screen players see today. Adding
   `HSlider` and `ScrollBar` to `manasoul_ui.tres` is a bounded change to one resource that
   depends on nothing else here. Largest visible difference for the least thrown-away work.
   *(This is `[UITH-6]`'s first half; the `Label`/`RichTextLabel` half is held for UIREC.)*
2. **Publish the role list** into
   [`ui_ux_interaction_vocabulary_2026-07-24.md`](../design/ui_ux_interaction_vocabulary_2026-07-24.md)
   and add the `theme_type_variation` adoption note. `UUI-13`. Blocks nothing and unblocks
   the editor's palette generation, the theme assembler, and every later conversion.
3. **The `dense` token column** in `ResponsiveLayout.DENSITY_TOKENS`. `UUI-11`. Pure
   addition; the keyboard is its first consumer but nothing breaks without one.
4. **Fix the Compact row-budget discrepancy** in
   `responsive_ui_redesign_2026-08-06.md` — the doc spends header 56 / footer 56, the tokens
   publish 72 / 64, and the real budget is 3.9 rows not 4.3. One-line correction.

### Phase 1 — the v0.8.0 integration window

Owned by `V080-RELEASE-WINDOW-2026-08-11`. Opens on acceptance.

5. **Merge the three held branches** onto the accepted base, resolving drift *by behavior,
   not commit identity*. All three carry real drift: responsive Main Menu collides with the
   v0.7.6 `MainMenu.gd`/`.tscn` changes (3 conflicting regions, 125 commits behind);
   palette swap overlaps `DataManager`, `CampaignTier2Validators`, `ContentSession`;
   feature-coverage overlaps `PackManifest.gd`. Take Main Menu first, while the v0.7.6
   changes are freshest.
6. **Close the two outstanding visual gates** — the Main Menu human pass and the palette-swap
   Windows Compatibility-renderer evidence — in the same session as the v0.7.6 return.

### Phase 2 — the theme assembler

Nothing below this line can be built twice cheaply, so it goes before the conversions.

7. **Retire `MenuScale._scaled_theme()`.** `UUI-8`. Menu Scale becomes a multiplier on the
   density tokens and stops writing Themes. `MainMenu.gd:69`'s local opt-out becomes the
   general rule. This is the change that stops authored constants being silently discarded.
8. **Derive `content_margin_*` at theme-assembly time.** `UUI-9`. Ships with a guard that a
   StyleBox in a shipped theme carries no hand-set content margin.
9. **The pack theme contract.** `UUI-10`, `UUI-14`, `UUI-16`. Manifest gains a look/theme
   block; the chrome/in-campaign boundary is enforced in code, not by convention; Settings
   resolves its theme from whether a pack is active.
10. **Ship the built-in themes** — plain light, plain dark, fantasy parchment, pixelated
    retro sci-fi — and publish the same assets through the Pack 0 repo. **Licensing
    precondition:** they must carry terms permitting authors to copy them into their own
    packs, per `UUI-14`. Cross-check LEG-4 and the CSA clauses *before* publishing.

### Phase 3 — screen conversions, one branch each

Owned by `V080-RESPONSIVE-SCREEN-CONVERSIONS-2026-08-11`. Order is durable:

> Campaign Library → New Game → Roster → Unit Details + More Info → Prep Hub → **Settings**
> → map HUD **last**

Every conversion must: be correct on first show without a synthetic resize; carry headless
coverage plus a Playwright capture at Compact; preserve focus, scroll and any open More Info
target across a live class change; and account for notches, punch-outs and rounded-corner
safe areas per `UUI-6`.

11. **Record screens adopt the UIREC composition** rather than being made responsive in
    place. `UUI-4`. `UIREC-V1-S03` (wide/narrow adapters) and `S04` (list, detail, action
    components) are built *as* the Campaign Library conversion, not after it.
12. **Settings** is the largest single conversion and carries five things at once:
    the persisted Menu Mode and information density; the text-entry vocabulary cleanup
    (drop `system`, keep the registry constant); the dual-theme resolution from `UUI-16`;
    **section paging with a scrolling tab strip** (`UUI-19`); and the **reachability-risk
    confirm-or-revert** rework (`UUI-18`). Blocked on the Windows return.

    `UUI-18` is separable from the rest and is the piece most worth landing early — it is a
    schema property plus a dialog that already exists and already works, and **both files it
    touches (`SettingsScreen.gd`, `DisplayConfirmDialog.gd`) are unclaimed**, so it is not
    gated on the Windows return at all. Two cautions.
    First, the dialog must be **exempt from the setting it is confirming**, or Viewport
    Scale 4.0 makes its own escape hatch unreadable. Second, `SettingsScreen._ready()`
    currently uses `confirm: true` to *also* decide which rows to hide where
    `is_display_config_supported()` is false; those two concerns share one flag today and
    must be separated, because a reachability-risk row is not automatically
    display-dependent.
13. **Flip the retired floor.** `SettingsManager.fit_content_scale_factor_for_size` still
    hard-codes `1280.0 / 720.0`. That is what makes a 1179×2556 phone snap to 0.5 and render
    2.7 CSS px type. **Do not flip it early** — before the conversions land it makes portrait
    large and broken rather than small and unclipped. Flip it with, or immediately after,
    the conversions.

### Phase 4 — the control region and text entry

14. **Landscape rectangle preset list, 4:3 default.** `UUI-1`, `UUI-2`. Blocks the landscape
    keyboard entirely.
15. **The 26% band → 55%, player-adjustable.** `UUI-3`. Must land *before* the conversions
    reach the map HUD.
16. **Text entry slices** `TEXT-V1-S01..S05` on the `dense` tokens from Phase 0. The portrait
    7-column layered keyboard and the landscape split keyboard are two reflows of one design.
17. **Map HUD conversion**, last, with the `UUI-7` fraction storage and all three V070-08
    consequences in the same change.

### Phase 5 — held for their own sessions

18. **The unbuilt screens.** Shop, convoy, reference compendium, credits, dialogue and the
    campaign editor. `UUI-15` holds them until their research sessions run — agenda in
    [`unbuilt_screen_research_agenda_2026-08-12.md`](../registers/unbuilt_screen_research_agenda_2026-08-12.md).

---

## What this plan closes

| Was open as | Now |
|---|---|
| `DISCUSS-RESPONSIVE-DISPLAY-LAYERS-2026-08-02` — modal bounds, safe areas, HUD anchors | `UUI-5`, `UUI-6`, `UUI-7`. Menu-scale accessibility floor and supported scale test points remain open. |
| `SESSION-UI-THEMING-ALIGNMENT-2026-08-10` — `UITH-1..8` | `UITH-1/3/4/5` answered by `UUI-9/13/10/14`; `UITH-2` answered by `UUI-4`; `UITH-6` split across Phase 0 and Phase 3; `UITH-7` unchanged (reports not gates); `UITH-8` resolved — the V080 branch holds no infrastructure. |
| The landscape rectangle question on `MOBILE-WEB-CONTROLLER-2026-08-04` | `UUI-1`, `UUI-2`. |
| The keyboard token exception | `UUI-11`. |
| Confirm-or-revert reaching only `window_mode` and `resolution` | `UUI-18` — keyed on reachability risk instead, which catches `control_style = off` on a touch-only device. |
| Settings' 25-row Compact scroll | `UUI-19` — six pages, tabs on wide screens. Settings leaves UIREC and becomes a tabbed pager. |
| Menu Scale's future, deferred by `[UITH-1]` to "the responsive redesign" | `UUI-8`. |

## Verification burden

Information density ships in v1, so each screen is 3 size classes × 2 menu modes × 3
densities = **18 states**. Against 23 built screens that is 414 states, and the six album
viewports are the durable capture points within them.

The Windows visual pass is the scarce resource, so per-screen conversion branches must carry
their own headless coverage and a Compact capture **before** queueing for it — or the scarce
session gets spent finding things a test could have caught.

## Known debt this plan does not clear

- **`GDD_10_Roadmap.md` still records the retired 1280×720 floor** under `UI-VIEWPORT-ASPECT`.
  `GDD_07_UI_UX.md` carries the superseding statement. One-line edit whenever
  `IMPL-ZERO-CONTENT-FAMILIES`' claim on that file clears.
- **`ui_ux_architecture_research_and_questions_2026-07-24.md`** still states under
  `UI-TOOL-01` that the bridge "must stay absent from production exports", superseded
  2026-08-10 by the ship decision. That doc is an accepted record of a 2026-07-24 decision;
  annotating it in place is a judgement call nobody has made.
- **No localization or i18n row exists anywhere in the tracker.** Fonts are pack-swappable and
  every layout must survive ~1.3× text extent — which is the constraint a translation
  imposes — but nothing owns it and no size-class decision was taken with it in mind.
- **`MOBILE-WEB-CONTROLLER-2026-08-04` is substantial but `in_progress`**, and is not
  merge-ready as a whole. Slice 4's global opacity/scale, combination save/rename/delete,
  Slice 5 themes/haptics and Slice 6 album/matrix all remain.
