---
Role: dated
---

# Playtester Build Manifest - v0.2.6

> **Status:** exported 2026-07-04. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.6`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.6_debug.exe`
- Source commit: `75b3379`
- Baked build stamp (`build_info.json`): version `0.2.6`, commit `75b3379`,
  built_at `2026-07-04T05:39:13Z`
- Exported: `2026-07-04`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101295520` bytes
- SHA-256: `90a673e1e08b5bf8b5793d61fd45e2c40ff5db4d77479550015ec85a4fb4e401`

The artifact is intentionally ignored by Git. v0.2.6 ships as **three files**: the
executable, the self-contained marker `._sc_` (must sit beside the exe — it makes the
game write its save + `logs/godot.log` next to itself), and the single self-contained
handbook `AGENT/Docs/playtests/playtest_checklist_v0.2.6.md`.

## Why v0.2.6

v0.2.6 is the **fix build** for the problems reported on the v0.2.5 return (triaged as
`V025-01..10`). The owner walked the triage review Q1-Q14 and the whole fix pass was
implemented and tested. `VAL-V023-DISPLAY` remains **Pending validation** — the
handbook's Part I passes on a real Windows screen are still required to flip it.

## What changed since v0.2.5

Each maps to a Part I / Part II check in the handbook.

- **Menu Scale slider (`V025-01`, §1.1):** applies on drag **release** (no mid-drag
  flicker); Settings horizontal scroll disabled + panel widened (no horizontal scrollbar
  at high scale).
- **Character sheet (`V025-02`, §1.2):** long rows wrap (no horizontal scrollbar);
  Back button shrink-centered; stats More Info reordered to numbers-over-prose at full
  height.
- **Contextual menu jitter (`V025-03`, §1.3):** placement offset capped at one unzoomed
  tile + side stickiness, so the menu hugs the unit at high zoom.
- **Combat forecast re-anchor (`V025-04c`, §1.4):** the visible AttackPreview re-anchors
  on zoom via the same hook the context menus use.
- **Level-up & promotion (`V025-05`, §1.5):** first-show level-up panel no longer renders
  narrow (autowrap dropped + deferred sizing); **left-click dismisses** the level-up
  (handled in `_gui_input` on the STOP root); promotion picker fits + scrolls at 2.0×
  (re-apply scale after rebuild + ScrollContainer).
- **Windowed size readout (`V025-06`, §1.6):** Settings shows the applied window size
  next to Resolution; the clamp (desktop visible around a windowed 4K request) is
  documented as working-as-designed in `display_and_settings_guide.md`.
- **Terrain click paging (`V025-08`, §1.7):** the three terrain More-Info RichTextLabels
  set to `mouse_filter=IGNORE`, so clicks reach the page-cycler.
- **Map 950 content (`V025-05e`, Part II):** 5th skill on `M950_Hero_SkillCap` (now at
  the skill cap) + extra weapons on the hero and Lvl19 merc; **10 grind units** for
  repeated level-ups / stat-cap testing.
- **Logging (this build):** self-contained mode ships a `._sc_` marker so `godot.log`
  lands next to the exe; every launch stamps `=== BUILD STAMP ===` (version, commit,
  built_at, per-launch `started_at`, resolved paths) as the first lines of the log.

## Deferred / not in this build

- **Author-extensible forecast rows (`V025-04a`, Q5)** and the **green effectiveness
  presentation (`V025-04b`, Q6)** are recorded requirements for the Band 5 generalized
  forecast — NOT built here (no builds before that schema lock). The v0.2.4 `■ Neutral`
  effectiveness row is unchanged.
- **Promotion-picker master/detail redesign** and the **paged character sheet** go to the
  `UI-INSPECTION` pass. The **terrain single-page redesign** goes to `B4-MAP-OBJECTS` /
  `[SAC]`.

## Known limitations carried into this build

- **This build IS the validation vehicle.** Every repair above is visual/input and was
  verified with headless structural / event-routing tests; `VAL-V023-DISPLAY` flips only
  after the handbook's Part I passes on a real Windows screen (ideally incl. 1440p/4K).
- **Input-routing fixes need a live pass.** Headless GUI picking differs from desktop, so
  the level-up left-click dismissal (§1.5) and terrain click paging (§1.7) were proven by
  structural invariant tests, not by a real desktop click — confirm them live.
- **Self-contained log location needs one live confirmation.** The build stamp is proven;
  the OS-level redirect of `user://` next to the exe should be eyeballed once on Windows
  (§3.2) — confirm `logs/godot.log` appears in the game folder with the BUILD STAMP.

## Verification

- Full source suite: PASS (49 suites green; pre-commit hook gates it).
- check_docs: PASS (21/21).
- Release-metadata test (`test_release_metadata.gd`): PASS — preset name/path/product
  version, Main Menu label, checklist presence, and setup guide all agree at `v0.2.6`.
- Export: PASS — Windows debug `.exe` built headless; `res://build_info.json` confirmed
  packed; SHA-256 + size recorded above.
- All visual/input checks remain in `playtest_checklist_v0.2.6.md` and need a human pass
  on real Windows (Part I is the v0.2.3/v0.2.5 display closeout gate).
