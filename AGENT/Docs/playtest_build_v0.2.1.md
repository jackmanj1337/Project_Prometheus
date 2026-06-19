# Playtester Build Manifest - v0.2.1

> **Status:** export pending — the binary fields below are placeholders to be
> filled when the Windows `.exe` is exported. The release metadata
> (`export_presets.cfg`, Main Menu `VersionLabel`, `environment_setup.md`) is
> already at `v0.2.1`; only the artifact + hash remain.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.1_debug.exe`
- Source commit: `<FILL AT EXPORT>`
- Exported: `<FILL AT EXPORT>`
- Godot: `4.6.stable.official.89cea1439`
- Size: `<FILL AT EXPORT>` bytes
- SHA-256: `<FILL AT EXPORT>`

The artifact is intentionally ignored by Git. v0.2.1 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtest_checklist_v0.2.1.md`.

## Why v0.2.1 (patch bump)

v0.2.1 is primarily the fix round for the v0.2.0 playtest return (camera/zoom,
state/objective/HUD bugs) plus the menu/HUD scale split and a wave of small
character-sheet / More Info clarity features. It corrects and clarifies what
v0.2.0 already shipped rather than adding a new system, so it is a patch bump.

## What's in this build (since v0.2.0)

Bug fixes from the v0.2.0 return (triage plan `playtest_v0.2.0_triage_plan_2026-06-19.md`):

- **V020-01** high-zoom camera jitter + over-max zoom no-op.
- **V020-02** Settings Map Zoom slider now applies live.
- **V020-03** combat forecast no longer overlaps the defender under zoom.
- **V020-04** repeated F9 hotseat toggling no longer refreshes spent units.
- **V020-05** Seize objective text now uses one-based tile coordinates.
- **V020-06** HUD layout reset no longer misplaces expanded Terrain More Info.
- **V020-16** menu scale split from HUD layout scale; menus stay centered at every scale.

Character-sheet & More Info clarity:

- **V020-07** `Int` row relabelled `Internal Lv`.
- **V020-08** Pair Up bonus duration reads `this combat` (was a bare `—`).
- **V020-09** on-map HUD names the support partner (`Support: <name>`).
- **V020-15** CON and LoS added to the character sheet (uncapped → cap `—`).
- **V020-11** class summary section (display name, tier, traits, weapon families, skills).
- **V020-10** weapon stat block in More Info + cursor-key / d-pad selector with a `▶`
  row highlight.

Editor + validation:

- **V020-12** HUD layout editor affordances: red/yellow panel outlines, `Scale Panel`
  buttons, scaled sample text.
- **V020-14** Map 950 fixed roster carries a validation-only `debuff_tonic` (negative
  stat_buff) so testers can confirm lowered stats render red.

Handbook-only: **V020-13** Borderless vs Fullscreen explanation (in the v0.2.1 handbook).

## Verification

- Full source suite: PASS (green at the source commit; pre-commit hook gates it).
- Export / artifact hash: **pending** — fill the Artifact section after the Windows export.
- All visual/input checks remain in `playtest_checklist_v0.2.1.md` and need a human pass
  on real Windows.
