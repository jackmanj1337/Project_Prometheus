---
Role: dated
---

# v0.7.0 Verification Checklist

> **This is the superset, and it is not what shipped on 2026-08-06.** The round was
> re-cut Windows-only — see
> [`playtest_checklist_v0.7.0_windows_round.md`](playtest_checklist_v0.7.0_windows_round.md),
> which is a subset of this file. Sections 4 (Web and PWA) and 5 (Mobile device) below
> are **deferred to a later mobile pass** and are still owned here.

This bundle exists to test the **mobile/web controller and PWA path, responsive UI,
browser transfer, and the self-contained campaign-pack architecture**. Fog of war is
deliberately not part of it — it computes but does not draw, and no item below asks
about it.

**The sections are stable across releases.** Windows, Controller, Web/PWA, Mobile
device, Campaign-pack lifecycle, Save recovery, and Return requirements appear in every
checklist from v0.7.0 onward, whether or not that release changed them, so an item
cannot disappear by being forgotten.

**Unreported is not passed.** v0.6.1 shipped to testers and no return was ever
recorded — there is no `AGENT/Docs/playtests/evidence/v0.6.1/` — so everything the
v0.6.1 checklist asked for is still unproven and is repeated below rather than assumed.

**Every item carries why it is here.** This checklist is a **superset** of v0.6.1's,
not its successor: nothing is dropped for having been asked before. Each item is
marked:

| Marker | Meaning | How much attention it needs |
|---|---|---|
| `[NEW]` | first appears in v0.7.0 | full attention — nobody has ever run it |
| `[UNPROVEN]` | shipped in v0.6.1 and never reported back | full attention — it has never been answered, only asked |
| `[REGRESSION]` | closed on real returned evidence (v0.6.0's log bundle, analysed in [`v060_carryforward_log_inspection_2026-08-02.md`](v060_carryforward_log_inspection_2026-08-02.md)) | quick confirmation that it still holds |

If you are short of time, do `[NEW]` and `[UNPROVEN]` first. Do not skip a
`[REGRESSION]` silently — mark it unrun.

---

## 1. Build identity

**Do this first and stop if it fails.** The first v0.6.1 bundle shipped two executables
whose startup BUILD STAMP read `version=0.6.0` while every filename and document said
v0.6.1. A result recorded against a mis-stamped build cannot be attributed to a commit
and has to be thrown away. The exporter now bakes and re-verifies the stamp, so this
check is confirming that fix as much as the build.

- [ ] [UNPROVEN] Every executable matches `SHA256SUMS.txt` (`sha256sum -c SHA256SUMS.txt`).
- [ ] [NEW] Startup log BUILD STAMP reads **`version=0.7.0 commit=<frozen candidate>`** in
  EVERY executable, and matches `BUILD_INFO.json`. Main Menu shows `v0.7.0`.
- [ ] [UNPROVEN] The debug executable shows the DEBUG MODE banner and the release executable does
  not. Same source commit, exported `--export-debug` and `--export-release`.
- [ ] [NEW] The bundle contains this checklist, the labeled Playwright responsive album with
  its `report.json`, and the manifest naming each artifact's size and SHA-256.

## 2. Windows

Nothing in this section was reported back for v0.6.1.

- [ ] [UNPROVEN] Review centered menus at 1280×720, 1280×800, 1365×768, 1920×1080, 2560×1440 and
  3840×2160. 1280×720 is the design floor: no layout may require more.
- [ ] [UNPROVEN] At 2× menu/content scale, New Game scrolls; Unit Details stacks its regions;
  Results stacks report/actions; no centered frame leaves the safe viewport.
- [ ] [UNPROVEN] **Windows are no bigger than they need to be.** Load Game and Campaign Library
  should be modest centered dialogs, NOT near-fullscreen panels. This is the change most
  likely to look wrong, and the automated containment checks cannot see it — an
  over-large window is still inside the viewport.
- [ ] [UNPROVEN] Non-zero safe-area padding; HUD panels attach and clamp.
- [ ] [UNPROVEN] Contextual action, attack-preview, weapon, item and map menus stay anchored to
  gameplay rather than being forced to screen center.
- [ ] [NEW] **Viewport anchoring:** changing the Viewport Scale setting re-anchors the map and
  HUD without clipping or drift, and the setting survives a restart.
- [ ] [NEW] **Terrain variants:** tiles introduced by the active pack paint at the correct
  size with correct atlas regions, and visually distinct variants of one terrain still
  behave identically (same movement cost, same defence). Tile sizing and atlas regions
  are exactly what a headless run cannot check.
- [ ] [UNPROVEN] Complete a representative map without a crash or stuck modal.

## 3. Controller

- [ ] [UNPROVEN] Repeat keyboard, mouse and controller navigation across every menu.
- [ ] [UNPROVEN] Repeat controller attacks, level-ups, end-turn confirmation and menu transitions.
  Attach the structured `TRANSITION` log if a lockout recurs. **Use the debug
  executable:** tracing is debug-only; the release build retains records in memory and
  writes them only when the watchdog fires.
- [ ] [UNPROVEN] One list item per press — no run-on movement in dropdowns (the v0.5.6
  successor-dropdown failure).
- [ ] [NEW] **While a real pad is in hand:** does joypad button 1 do anything odd on
  accept/back? `[input]` binds `confirm=joy(1,0)` and `cancel=joy(2,1)`
  (`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`). Unanswered in v0.6.0 and
  unreported in v0.6.1.
- [ ] [REGRESSION] Hot-plug: connect, disconnect and reconnect the pad mid-session; prompts switch
  keyboard↔controller each time. (Telemetry itself PASSED on v0.6.0 evidence — this is
  a regression check on the prompts, not a re-collection.)

## 4. Web and PWA

Served over **HTTPS** — a plain-HTTP page rendering is not evidence that installation,
service workers, offline launch or durable storage work.

- [ ] [UNPROVEN] The page loads and reaches the Main Menu; the tab title reads *Project Prometheus*
  (not the old FE name).
- [ ] [UNPROVEN] The service worker registers on first load and controls the second load.
- [ ] [UNPROVEN] **Offline relaunch:** kill the network, reload — the game still boots.
- [ ] [UNPROVEN] Installing to the home screen / desktop uses the Project Prometheus icon, not the
  Godot robot.
- [ ] [UNPROVEN] Text entry works: on-screen keyboard appears for a save name, Escape/Back closes
  the field once (not twice), and the typed value is kept.
- [ ] [UNPROVEN] File import/export reaches the real device filesystem — a campaign pack and a save
  can be exported out of and imported back into the browser build.

## 5. Mobile device

Real hardware only. Chromium desktop results do not satisfy this section.

- [ ] [NEW] Touch controls appear on a touch device and not on desktop; every action reachable
  by touch alone.
- [ ] [UNPROVEN] Portrait and landscape both usable; rotating mid-session does not strand the HUD.
- [ ] [NEW] Notch / home-indicator safe areas respected — no control under the indicator.
- [ ] [NEW] Default scale is legible without pinch-zooming.
- [ ] [UNPROVEN] Audio starts after the first gesture; the hardware mute switch behaves sanely.
- [ ] [UNPROVEN] A 30-minute play soak without a reload, crash or growing stutter.
- [ ] [UNPROVEN] Saves survive closing the browser/PWA entirely and relaunching.

## 6. Campaign-pack lifecycle

**Start from a genuinely inactive state** — no pack installed. Uninstall first if one
is. The engine is not supposed to fall back on hidden built-in content, and that is
precisely what this proves.

- [ ] [NEW] With no pack installed, the game starts and says so plainly rather than silently
  offering content.
- [ ] [NEW] Install `campaign-packs/proving_grounds_public`, select it, launch its
  bundled map, and play one encounter **to a result** (win or lose). This is the item
  that closes `IMPL-ZERO-CONTENT-BASE-PACK`, whose exit has always been "finishes one
  encounter".
- [ ] [NEW] **The board is populated.** Enemies are present, they act on their phase,
  your units carry their weapons, and the objective is stated. Earlier extractions
  produced maps with terrain and start tiles but no enemies and no objectives, and
  rosters whose units had no inventory — an empty board here is a serious regression,
  not a content gap.
- [ ] [UNPROVEN] Save, exit, relaunch, continue — the run resumes on the same pack.
- [ ] [UNPROVEN] Switching packs restores the baseline: content from a deselected pack is gone.
- [ ] [NEW] `campaign-packs/proving_grounds_invalid` is **refused at activation** with a
  message naming the map and the off-grid tile, the previously active pack is still
  active afterwards, and nothing is left half-activated. (It is broken semantically, not
  syntactically, so it may install and then fail to activate — that ordering is the
  point. See that folder's README for the exact expected message.)

## 7. Save recovery

- [ ] [UNPROVEN] Load existing v0.6.x saves with their campaign packages installed.
- [ ] [NEW] A missing campaign package blocks restore **without changing the save**. Move the
  pack folder out of
  `%APPDATA%\Godot\app_userdata\Project Prometheus\campaign_packs\installed\`, relaunch,
  load the save, then move it back. (Note the folder name: the user-data directory was
  renamed off `Fire Emblem RPG` and migrated in v0.7.0 — confirm the migration carried
  saves, settings and installed packs across.)
- [ ] [UNPROVEN] The recovery message identifies the missing pack, states that progress was not
  modified, and offers a way out (Manage Campaigns / Retry / Back) rather than a raw
  path or error code.
- [ ] [REGRESSION] Retry after Save still works (regression check — passed in v0.5.6, before
  MapResultsScreen was restructured).

## 8. Carry-forward still open

- [ ] [UNPROVEN] **FileDialog cancel/Escape input ownership.** Returned `FAILED` in v0.6.0, and the
  v0.6.1 fix was never reported back. Record the outcome and the `escape_consumed_by`
  value from the log. First Escape must close the dialog once.
- [ ] [REGRESSION] **Filesystem check the logs cannot answer:** confirm NO v0.3.0 resize-trace file
  exists in the user-data directory. The log half already passed (no `[V030 TRACE]`
  lines in any of the seven v0.6.0 logs).

Closed on v0.6.0 evidence — **do not re-run**: controller hot-plug telemetry
collection, logging/telemetry presence, package save validation (ordinary-load half),
and Retry-after-Save first verification.

## 9. Return requirements

A verbal "it worked" cannot satisfy sections 1, 3 or 8.

- [ ] [UNPROVEN] **The whole Godot log directory is attached**, from every executable used.
- [ ] [UNPROVEN] Screenshots for anything marked FAIL, plus the Windows resolution sweep.
- [ ] [UNPROVEN] Which executable produced each result (debug vs release), and the BUILD STAMP line
  copied from its log.
- [ ] [UNPROVEN] For the mobile section: device model and OS version.

Returning the logs is not enough on its own — the v0.6.0 logs came back complete and
then sat uninspected while the items they answered were still recorded as outstanding.
Whoever triages this return greps the logs and records the result.

## Result

- Tester / host:
- Date:
- PASS / FAIL:
- Notes and screenshot references:
