---
Role: dated
---

# Responsive UI Programme — consolidated plan — 2026-08-06

> **Superseded for sequencing (2026-08-12)** by
> [`unified_ui_programme_2026-08-12.md`](unified_ui_programme_2026-08-12.md), which covers
> eight workstreams rather than four. This document is retained for its record of what was
> done between 2026-08-06 and 2026-08-12, and for the reasoning behind each step it owns.

Status: Active. One ordered plan for the work that used to be spread across the responsive
redesign, the size-class seam, mobile text entry, the mobile-web controller and the
viewport-anchoring row that is now closed.

Last verified: 2026-08-06

**Why this exists.** Five tracker rows and three design docs were each correct on their own
and collectively unreadable — the ordering lived in prose on individual rows, and the same
blocker (one claim on `SettingsManager.gd`) was recorded three different ways. This is the
sequencing view. It owns no decisions; each one belongs to the design doc named beside it.

**This plan owns the ORDER.** The design docs own the decisions and the reasons. Where they
disagree about sequence, this file is right; where they disagree about why, they are.

## The sources

| Source | Owns |
|---|---|
| [`responsive_ui_redesign_2026-08-06.md`](../design/responsive_ui_redesign_2026-08-06.md) | Size classes, the 360×640 floor, density tokens, per-screen conversion |
| [`text_entry_mobile_compact_2026-08-06.md`](../design/text_entry_mobile_compact_2026-08-06.md) | The keyboard/controller handover and the keyboard layout |
| [`mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md`](mobile_web_viewport_and_virtual_controller_implementation_plan_2026-08-04.md) | The control region: the dead-space rule, the landscape rectangle, the 26% defect |
| [`v0.7.0_playtest_visual_bundle_handoff_2026-08-05.md`](v0.7.0_playtest_visual_bundle_handoff_2026-08-05.md) | The one Windows session everything display-gated is queued behind |

## Done

| | Row | Landed |
|---|---|---|
| 1 | `IMPL-VIEWPORT-ANCHORING-2026-07-31` closed as superseded | Its 1280×720 floor is retired; removed from the display-gated list, visual pass cancelled. Its `content_scale_factor` work survives and is the foundation everything else rests on. |
| 2 | `SIZE-CLASS-SEAM-2026-08-06` | `ResponsiveLayout` autoload: three classes from logical viewport width, debounced republish, 24px hysteresis, publish-only-on-real-change, both density token sets. `UnitDetailsScreen` off its hard-coded 900. Suite green at 130. |

## The critical path, and why it is one session long

**The scarce resource is not engineering time — it is one Windows session with a phone and
a pad.** `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` is display-gated on that session and
claims `SettingsManager.gd`, `SettingsScreen.gd` and `SettingsScreen.tscn`. Until it closes:

- the **Settings screen conversion** cannot start;
- **Menu Mode and information density cannot become persisted settings** — `ResponsiveLayout`
  holds them in memory precisely because that file is claimed;
- and the text-entry **Settings vocabulary change** (dropping `system`) cannot land either.

Three separate pieces of this programme are queued behind one return. That is worth knowing
before planning around any of them individually.

## Order of work

### Now — unblocked, no dependencies

1. ~~Verify the web virtual keyboard.~~ **Done 2026-08-06** — it was live, not latent. The
   export shipped `experimentalVK:true`, so the platform keyboard raised over the grid
   keyboard on every touch device. Fixed in `export_presets.cfg` with a guard suite
   (`SUPPRESS-WEB-OS-KEYBOARD-2026-08-06`).
2. **Screen conversions, one branch each, cheapest first:** Main Menu → Campaign Library →
   New Game → Roster → Unit sheet and More Info → Prep hub. Each carries its own headless
   coverage and a Playwright capture at Compact before it queues for a visual pass.
3. ~~Answer the text-entry sub-decisions.~~ **All ratified 2026-08-06**: layered 7-column
   alphabetical keyboard; Compact-only echo strip; drop `system`. Plus the landscape split
   keyboard and its shrink-the-view fallback. Only the `system` removal is blocked. The
   keyboard itself is now fully specified and buildable — see the design doc.

### Next — ordered behind something specific

4. **The landscape game-view rectangle**, in `MOBILE-WEB-CONTROLLER-2026-08-04`. The
   dead-space rule says the control region is whatever the game view leaves over, so
   landscape's full-bleed `{x:0, y:0, w:1.0, h:1.0}` default leaves nowhere for controls —
   and nowhere for the split keyboard. 4:3 is the widest rectangle that still fits a split
   keyboard, which argues for it as the default. Blocks the landscape keyboard entirely.
5. **The 26% map band**, in `MOBILE-WEB-CONTROLLER-2026-08-04`. Must land *before* the
   conversions reach the map HUD: a 26% band cannot show the 12×14 tiles the map layouts are
   drawn against. It is controller-layout data, so it belongs to that row — a redesign row
   editing it is the claim overlap this programme was split to avoid.
6. **The keyboard itself.** Replaces the control region during a session; needs the region
   handover in the controller service, so it is sequenced with (4) and (5).
7. **Map HUD conversion** — last, after (5).

### Blocked on the Windows return

8. **Settings screen conversion**, and with it the persisted Menu Mode and information
   density, and dropping `system` from the text-entry vocabulary.

## Verification burden

Information density ships in v1, so each screen is 3 size classes × 2 menu modes ×
3 densities = **18 states**, about 198 across eleven screens. Conversion branches must carry
headless coverage and a Compact capture before queueing for the visual pass, or the scarce
session is spent finding things a test could have caught.

## Known debt this plan does not clear

- **`GDD_10_Roadmap.md` still records the retired floor.** The `UI-VIEWPORT-ASPECT` row reads
  "Design floor ratified at 1280×720". `GDD_07_UI_UX.md` carries the superseding statement,
  but the roadmap line needs a one-line edit and that file is claimed by
  `IMPL-ZERO-CONTENT-FAMILIES`. It is a one-line fix whenever that claim clears.
- **The retired floor is still live in code, and it is the cause of the 2.7px portrait type.**
  `SettingsManager.fit_content_scale_factor_for_size` hard-codes `1280.0 / 720.0`. On a
  1179×2556 phone that snaps to 0.5 → a 2358×5112 logical viewport → 2.7 CSS px body text.
  Against the ratified 360×640 floor the same phone resolves to 3.0 → 393×852 → Compact at
  16 CSS px. **Do not flip it early:** before the screen conversions land it would make
  portrait large and broken rather than small and unclipped. It also cannot be flipped yet —
  `SettingsManager.gd` is claimed by `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`. Flip it
  with, or immediately after, the conversions.
- **The touch density tokens do not survive the keyboard intact** (gap 8→4, gutter 16→8).
  That has to be a named exception or a compact token variant, not a local override.
- **v0.7.0 may slip.** The owner accepted this when the redesign widened. The bundle waits
  rather than shipping an unusable portrait build.
