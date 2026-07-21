---
Type: playtest
Status: Pending validation
Last verified: 2026-07-21
---

# v0.5.3 Windows Verification Checklist

## Purpose

This build verifies the nine v0.5.3 repairs and retains the v0.5.2/v0.5.0
regression coverage they touch. Use a fresh folder containing only the supplied
executable and fixture.

**How this checklist is read.** There is no PASS/FAIL box. Triage derives the
verdict from your comments, the checks you complete, the returned `godot.log`,
your screenshots, and any failures you record. So a check left blank is not a
pass — it is unknown. Mark anything you could not run `NOT RUN — <reason>`, and
describe what you actually observed for anything that looked wrong.

**What the log already captures — do not retype it.** The build now logs its own
provenance. Treat these blocks in `godot.log` as authoritative; you do not need
to transcribe Device Manager, dxdiag, or the campaign you picked:

- The framed `=== RUNTIME ENVIRONMENT ===` block is authoritative for OS, OS
  version, CPU, GPU (name/vendor/type), rendering API, display server,
  locale/time zone, and window/screen geometry.
- `PLAYTEST CONTROLLER` lines are authoritative controller evidence (connected
  at startup and every hotplug).
- `PLAYTEST CONTEXT` JSON lines are authoritative campaign, node, and package
  identity at campaign start, restore, and node launch.

Because of that, this checklist names the **exact** campaign and scenario to run
so the log can prove the requested path was exercised — please run precisely the
named path, not a substitute.

## Build identity

- Executable: `Project_Prometheus_v0.5.3_debug.exe`
- Campaign fixture: `two-map-skirmish-1.0.zip`
- Expected executable size: `__________` bytes
- Expected executable SHA-256: `__________`
- Expected fixture size: `4271` bytes
- Expected fixture SHA-256: `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- Expected BUILD STAMP: version `0.5.3`, commit `__________`, built `__________`

PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.5.3_debug.exe -Algorithm SHA256
Get-FileHash .\two-map-skirmish-1.0.zip -Algorithm SHA256
```

- [ ] Filenames, sizes, hashes, Main Menu `v0.5.3`, and the log's BUILD STAMP all
      match the values above. Stop and report if identity differs — a mismatched
      log cannot be triaged against this build.

## Tester

Default tester is the project owner. If someone else runs it, name them in your
comments; identity is deliberately not baked into the log.

---

## 1. Main Menu and baseline smoke

- [ ] Main Menu reaches a stable idle state and reads `v0.5.3`, without blocking
      errors, clipping, or title/version overlap.
- [ ] New Game, Continue, Load Game, Settings, and Quit remain usable.
- [ ] WASD, Z/X, mouse, and controller navigation work as applicable.

Screenshot at 1280x720 and notes: ____________________

## 2. Map 005 is pure Survive (review row 1)

Reach **map_005_defend** (the defend map) through any path that launches it.

- [ ] The objective text reads a plain **Survive N turn(s)** — there is **no**
      "Hold (x, y)" tile requirement.
- [ ] There is **no** turn-limit defeat: passing turn 8 does not lose the map.
- [ ] Surviving to the required turn resolves the map as a victory.
- [ ] If any other map shows a "Hold (x, y) …" objective, its coordinates read as
      one-based (top-left tile is `(1, 1)`, not `(0, 0)`).

Objective text seen, and turn the map resolved on: ____________________

## 3. Paired escape restores both roster coordinates (review row 3)

Run the shipped **Proving Grounds** campaign and reach its **Escape** map
(`map_004_escape`; escape tiles are the three right-edge tiles, one-based
`(17, 3) / (17, 4) / (17, 5)`).

- [ ] Pair Up the two escape units (`unit_01_cavalier` lead + `unit_02_mercenary`
      support), then move the **lead** onto an escape tile and confirm escape.
- [ ] Both the lead and the paired support leave the map together on that one
      escape action.
- [ ] Neither escaped unit is later shown as a casualty.
- [ ] After escape, both units survive into the next node with sane state (they do
      not reappear at a stale/off-map tile or vanish from the roster).

Escape tile used, and both units' post-escape status: ____________________

## 4. Full-history Rewind (review rows 4 and 7)

On any map, perform several blue and red activations, then open the map-menu
Rewind selector.

- [ ] Opening Rewind **hides the map menu behind it** and keeps modal focus; the
      tactical map does not accept input while the selector is open.
- [ ] Every retained activation from the full history is selectable; each row —
      including the oldest — costs exactly one charge.
- [ ] Choosing a row restores HP, inventory, units, phase, cursor, RNG, economy,
      **and** the remaining-charge count, all consistently.
- [ ] Cancelling the selector restores the map menu and its focus and **does not**
      consume a charge or leave the cursor locked.
- [ ] The restored charge count survives Suspend & Quit / Continue.
- [ ] Repeat the same Rewind flow from the **Defeat** screen (lose a map): its
      selector behaves identically and never leaves the screen input-locked.

Oldest/newest rows, charge sequence, and any stuck-focus moment: ____________________

## 5. FileDialog printable bindings (review row 5)

Open **New Game > Manage Campaigns > Import** and focus the filename field.

- [ ] The first press of X types `x`; Z types `z`; they do **not** confirm or
      cancel the dialog.
- [ ] Ordinary letters, Backspace, and selection-replacement editing all work.
- [ ] Cancel and normal file selection still work; import
      `two-map-skirmish-1.0.zip` successfully.

Exact filename text tested: ____________________

## 6. Manual campaign save from Prep (review row 2)

At a campaign **Prep** screen (e.g. Proving Grounds or the imported skirmish),
use **Save**.

- [ ] Save succeeds with **no** id/label text boxes to fill in; the save is
      auto-labelled for the current chapter/activity (label ends `— Prep`).
- [ ] Saving again at the same Prep prompts **"Replace Save?"** before replacing.
- [ ] Cancelling that prompt leaves the existing save untouched.
- [ ] Confirming replaces it with a single fresh save (the old one is gone, and no
      duplicate is left behind).
- [ ] The saved slot appears in Load Game with the expected chapter label.

Save label seen, and replace-prompt behavior: ____________________

## 7. Manual End Turn (review row 6)

On a map with **more than one** of your units still able to act, open the map menu
and choose **End Turn** (confirm).

- [ ] The phase ends once — it does not double-advance or skip the enemy phase.
- [ ] After End Turn, Rewind offers one selectable boundary **per** remaining unit
      that was auto-waited (not a single lumped step), and each restores cleanly.

Units remaining at End Turn, and Rewind rows produced: ____________________

## 8. Results, casualties, and successor errors (review row 8)

- [ ] A rewarded map's Results resolves exactly once; `before + earned = total`
      gold with no duplication on reopen.
- [ ] With Permadeath On a defeated blue unit reads `Name — Fallen`; Off reads
      `Name — Retreated`; an escaped unit is **not** a casualty.
- [ ] A genuinely terminal campaign result — and only that — reads
      `Finish Campaign`.
- [ ] If a node ever reaches a results screen with no available next battle, the
      button reads **Return to Menu** and works (it is **not** a dead
      "Campaign Data Error" button and **not** falsely "Finish Campaign"). Report
      it if you hit this — the log records the campaign/node.
- [ ] While Results or the Defeat overlay is visible, taps, held keys,
      d-pad/stick, wheel, clicks, and pointer motion do **not** drive the map
      behind it.

Before/earned/total gold, and any successor-button wording: ____________________

## 9. Automatic provenance logging (review row 9)

Open the returned `godot.log` (do not retype it — just confirm it is present and
populated):

- [ ] It begins with the BUILD STAMP, then a framed `=== RUNTIME ENVIRONMENT ===`
      block with populated OS/CPU/GPU/display/locale/window fields.
- [ ] A `PLAYTEST CONTROLLER` line appears for any controller you used (and on
      connect/disconnect).
- [ ] `PLAYTEST CONTEXT` JSON lines appear at campaign start, at each node launch,
      and after any Continue/restore, naming the campaign, node, and package.

Confirm present, and note anything empty/`headless`/malformed: ____________________

## 10. Retained regression sweep (v0.5.2 / v0.5.0)

Re-exercise the areas the v0.5.3 fixes touch; §§2–9 already cover their focused
behavior and are **cross-referenced, not restated** here.

- [ ] **Campaign selector source ownership** — shipped choices appear once; an
      imported package appears once without hiding shipped content; switching back
      restores shipped data; the set is stable across Suspend/Continue.
- [ ] **Two-Map Skirmish progression** — Chapter 1 (The Crossroads) Rout resolves,
      Results offers `Continue: River Pass` (not `Finish Campaign`), and River Pass
      loads with the expected units/objective.
- [ ] **Save/Retry hygiene** — mid-map Suspend & Quit / Continue restores the exact
      turn and spent units; Retry restores the original board/RNG/economy without
      skipping a map or duplicating rewards; a completed suspended map clears its
      resume slot.
- [ ] **Load fidelity** — Autosave/Load Game preserves package identity, roster,
      gold, inventory, rewind history, and remaining charges; a corrupted/version-
      mismatched save copy is rejected without harming valid slots
      (`NOT RUN — no corrupted-save fixture` if none is prepared).
- [ ] **Menu Scale & layout** — Main Menu, Prep, Results, dialogs, Unit Details,
      Attack Preview, and the Action Menu stay on-screen and readable at 0.5x,
      1.0x, and 2.0x; windowed resize/maximize/restore recenters and does not drift
      controls off-screen.
- [ ] **Combat & deferred skills** — one confirmed combat resolves exactly once with
      matching HP/durability/XP/death; Attack Preview cancel changes nothing; a
      promotion-validation combat emits no `_apply_unimplemented` warning.

Notes/screenshots for anything that regressed: ____________________

## 11. Logs and return package

- [ ] No crash, assertion, parser, missing-resource, restore, package-validation,
      or transaction error appears in the log after the BUILD STAMP.
- [ ] For each failure, record exact steps, expected vs actual behavior,
      repeatability, the relevant save name, and an original-resolution screenshot.

Return to:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.3/`

Include the completed checklist, the **original** `godot.log`, and focused
screenshots for: Main Menu layout, the open Rewind selector (modal behavior),
Chapter 1 → River Pass results progression, casualty/successor labels, and the
paired-escape and post-rewind state. Human comments remain required for observed
behavior, reproduction steps, expected/actual results, and anything not run. Then
tell the maintainer:

```text
v0.5.3 return is ready in AGENT/Incoming/v0.5.3/.
```
