---
Role: dated
Type: plan
Status: In progress — corrected in place on 2026-08-24 for the rejected v0.7.10 return
Last verified: 2026-08-24
Tracker: WINDOWS-PASS-READINESS-2026-08-20, DESIGN-OVERWORLD-CADENCE-2026-07-25, SMALL-SCREEN-UI-REDESIGN-2026-08-05, OVERWORLD-GRAPH-CANVAS-2026-08-20
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# v0.7.10 remediation and replacement-round handoff

This file replaces its obsolete v0.7.8 readiness instructions in place. Start the next
session here. The canonical return evidence is
[`../playtests/evidence/v0.7.10/`](../playtests/evidence/v0.7.10/); do not edit the files
under its `raw/` directory.

## Outcome and release rule

**v0.7.10 is rejected. Do not tag it, merge it to `agent/stable-release`, or promote it.**
The exact Windows candidate was `0.7.10` at `6aa89069`. Its free-roam schema and authored
pack adoption passed, but a cleared-node revisit can trap the player in Prep with no
usable action or exit. A replacement candidate needs both automated coverage and a new
Windows return.

Product fixes start from current `agent/integration`, land there, then move through
`agent/playtest-release` in the normal release flow. Do not build product fixes on this
docs branch or shortcut them into `agent/staging-area`.

## What passed — preserve it

- The free-roam ZIP imports without diagnostics and appears in New Game.
- New Game launches Chapter 1 Prep directly; Begin Battle launches the map.
- Completing Chapter 1 routes to the campaign map.
- Cleared, next, and gated nodes are visually distinguishable; the gated reason is the
  sentence `Clear Chapter 3 - The Commander first.` rather than an internal identifier.
- Keyboard and controller can navigate the map and launch a reached node.
- Returned logs show `campaign_started`, node launch/resume/restage, and a later Chapter 2
  restore/launch, with no Godot error or warning lines.
- A battle map renders without missing terrain.

Add regressions for these behaviours where the fixes touch their routes. Do not turn the
replacement checklist into a complete replay of already-settled unrelated surfaces.

## Required fixes

### 1. Release blocker: a cleared-node revisit has no way back

Reproduction: from the campaign map, select cleared Chapter 1. Prep renders `Cleared hub
revisited. This battle is not repeatable.`, validation disables `Begin Battle`, and no
Back/Return-to-Map action exists. The tester had to terminate the process. The next launch
restored at Chapter 2, which prevents data loss but does not make the dead end acceptable.

The intended contract is:

- a free-roam revisit may enter the cleared node's hub;
- a non-repeatable battle stays disabled;
- the hub always offers `Return to Campaign Map` when entered from that map;
- the first Prep screen of a linear campaign does not gain a misleading back route; and
- keyboard, controller, and the normal cancel action reach the same return path without
  double navigation.

Start with `scripts/ui/PrepScreen.gd`, its scene, `scripts/ui/OverworldScreen.gd`, and
`CampaignManager`'s revisit state. Add a real route-level regression to
`test_prep_screen.gd` or `test_overworld_screen.gd`; checking only that a button exists is
not enough. The test must enter a cleared one-shot node from Overworld, invoke the return
action, and prove progression and the current node were not rewound.

### 2. Campaign-map save and Settings access

The campaign map exposes only nodes and zoom. The tester could not perform the requested
save-on-map flow and specifically asked for Save and Settings there. Supply player-facing
access without inventing a second save codec or settings implementation:

- Save uses the existing campaign manual-save policy and slot limits.
- Continue after a full quit restores the campaign map and the same node availability.
- Settings opens the existing `SettingsScreen` and returns focus to the map.
- Cancel/back behaviour is unambiguous; it must not abandon the campaign accidentally.

Likely surfaces are `OverworldScreen.gd/.tscn`, the existing Prep save helper/policy,
`SaveManager`, and the scene router that owns Settings. Prefer extracting/reusing the
existing campaign-save operation over copying `PrepScreen._write_manual_save()`.

Tests must cover save success, save failure/slot exhaustion, map restore, Settings
open/close focus restoration, and one-event ownership for cancel/back.

### 3. Main-menu compact-width clipping

`raw/narrow.png` (173 px window) clips `Project Prometheus` and most of `New Game (No Data
Packs Installed)`. `raw/slightly less narrow.png` (282 px) fits the title but still clips
the New Game reason. The latter is the actionable supported-size failure even if 173 px is
below the intended 360 px design floor.

Before editing, reproduce this through the Playwright harness at the declared compact
floor and at 282, 360, 599, and 600 logical pixels. Record the computed viewport, size
class, density, label rectangles, and scroll width. Then fix the layout so:

- the application title is fully readable at the supported floor;
- the gated New Game explanation is fully discoverable (wrap, a second reason line, or an
  equivalent accessible presentation — do not silently truncate it);
- buttons and ornaments do not overlap; and
- the compact fix does not regress medium/expanded layouts.

Primary surfaces: `MainMenu.gd/.tscn`, `ResponsiveLayout.gd`, and
`test_main_menu_responsive.gd`. The current code scales font and panel tokens but does not
make a long button label fit. Add assertions on rendered/minimum widths and the complete
reason, not only size-class token values.

### 4. Menu Density is not exposed in Settings

The tester could not find **Menu Density** in either v0.7.9 or v0.7.10 and explicitly
asked that this be checked with Playwright before another manual request. Honor that:

1. Use Playwright to enumerate the visible Settings labels and controls.
2. Trace `ResponsiveLayout.density_changed` and its persisted authority.
3. Add a player-facing density selector only if the setting is meant to be player-owned;
   otherwise correct the product vocabulary and replacement checklist so it does not ask
   for a nonexistent control.

Do not add a decorative selector with no runtime effect. A real control must persist,
apply live to the Main Menu, survive restart, and have an automated caller/test.

Likely surfaces: `SettingsManager.gd`, `SettingsScreen.gd/.tscn`,
`ResponsiveLayout.gd`, and their focused tests.

### 5. Slider tracks/endcaps and focused state are not visually legible

`raw/settings.png` shows the gem thumbs, but the horizontal trough/fill and endcaps are
effectively invisible at native 3840×2160. The theme already assigns
`SB_slider_track`, `SB_slider_fill`, and gem states in `assets/themes/manasoul_ui.tres`, so
first determine whether this is bad contrast/scale, a nine-patch margin problem, or the
wrong theme resource at runtime. Do not replace the art blindly.

Use Playwright screenshots and computed theme/resource inspection before changing it.
Verify normal, hover, keyboard/controller focus, disabled, minimum, midpoint, and maximum
states at compact and expanded sizes. Add the strongest feasible automated structural
test, but keep a native Windows visual check as the exit gate because pixel visibility is
the reported defect.

### 6. Overworld presentation follow-through

The screenshots also confirm the existing `OVERWORLD-GRAPH-CANVAS-2026-08-20` finding:
the authored graph is rendered as a centered vertical button list, and fullscreen leaves
most of the display empty while making the content very small. Do not fold a full graph
canvas rewrite into the release-blocking navigation patch unless it is already ready and
reviewed. At minimum, make the list remain readable and usable at native fullscreen; keep
the graph-canvas row as the owner of the larger pan/zoom/edge presentation.

The revisited Prep screenshot also dumps a long raw rules dictionary into the primary
player surface. Treat that as Prep redesign work unless a small presentation-only change
can safely replace it with authored/player-facing summaries. Do not expose raw JSON-like
data as the final fix.

## Recommended execution order

1. Refresh `agent/integration`; confirm the v0.7.10 schema commit is already present or
   merge the accepted release-line adopter forward before cutting any fix branch.
2. Fix the cleared-node return route first. It is the release blocker and defines the
   navigation ownership needed by map Settings.
3. Add campaign-map Save and Settings using existing services.
4. Run the Playwright compact-menu and Settings investigations before editing those
   surfaces, as the tester requested.
5. Fix compact clipping, the Menu Density disposition, and slider visibility in small
   reviewable commits. Keep claims aligned with the existing responsive-UI rows.
6. Run focused tests after each slice, then the full configured suite on the exact merged
   `agent/integration` tree.
7. Merge the verified product changes through the release line, bump to the next patch
   version, and cut a new Windows bundle. Do not overwrite the v0.7.10 artifacts.

## Replacement Windows checklist

The next packet must ask the tester to:

1. Verify BUILD STAMP and checksum from a clean extraction.
2. Import the same authored free-roam pack and reach the campaign map.
3. Revisit cleared Chapter 1, activate `Return to Campaign Map` by keyboard and controller,
   and confirm progression is unchanged.
4. Save on the campaign map, quit fully, relaunch, Continue, and confirm the same map/node
   state returns.
5. Open Settings from the map, change one harmless setting, return, and confirm map focus.
6. Resize to the declared supported compact floor and capture the full Main Menu.
7. Record the exact Menu Density disposition and capture all slider states at native
   resolution.
8. Launch the next reached battle and return the complete Godot log directory.

Acceptance requires the checklist, requested screenshots, complete logs, no navigation or
save errors, and no new internal identifiers. Only then may the replacement candidate be
tagged and promoted.

## Session completion

Update the cited tracker rows in place. A code foundation does not close on tests alone;
the release-blocking navigation and map-save work remain `in_review` until the replacement
Windows return exercises them. Do not write a session note. Record commits and reasoning
in tracker references, and leave the next action in `AGENT/WAITING_WORK.md` through the
tracker generator.
