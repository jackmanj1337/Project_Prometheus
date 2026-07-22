---
Type: playtest
Status: Pending validation
Last verified: 2026-07-22
---

# v0.5.4 Windows Verification Checklist

## Purpose

This build is the **visual pass** for the v0.5.3-return fix set (V053-01…-09 plus
a HUD-editor teardown-contract follow-up). The container can run headless tests
but cannot prove live Windows visuals or real input — that is what this checklist
is for. **Part A** verifies this round's repairs. **Part B** re-runs the checks
that could not be completed in prior v0.5 rounds (controller, the full-history
Rewind scrollbar, the reworded Survive check, provenance logging, and the
connected-campaign benefit). **Part C** is the retained regression sweep.

Use a fresh folder containing only the supplied executable and fixture.

**How this checklist is read.** There is no PASS/FAIL box. Triage derives the
verdict from your comments, the checks you complete, the returned `godot.log`,
your screenshots, and any failures you record. So a check left blank is not a
pass — it is unknown. Mark anything you could not run `NOT RUN — <reason>`, and
describe what you actually observed for anything that looked wrong.

**What the log already captures — do not retype it.** The build logs its own
provenance. Treat these blocks in `godot.log` as authoritative:

- The framed `=== RUNTIME ENVIRONMENT ===` block is authoritative for OS, OS
  version, CPU, GPU (name/vendor/type), rendering API, display server,
  locale/time zone, and window/screen geometry.
- `PLAYTEST CONTROLLER` lines are authoritative controller evidence (connected
  at startup and every hotplug).
- `PLAYTEST CONTEXT` JSON lines are authoritative campaign, node, and package
  identity at campaign start, restore, and node launch. This round they should
  show **one** `campaign_restored` per Continue (a re-stage now logs
  `campaign_restaged`), and a `node_resumed` line when a suspended battle is
  continued.

Because of that, this checklist names the **exact** campaign and scenario to run
so the log can prove the requested path was exercised — please run precisely the
named path, not a substitute.

## Build identity

- Executable: `Project_Prometheus_v0.5.4_debug.exe` (the Main Menu reads `v0.5.4`;
  the authoritative version is the log's BUILD STAMP)
- Campaign fixture: `two-map-skirmish-1.0.zip`
- Expected executable size: `<FILLED AFTER EXPORT>` bytes
- Expected executable SHA-256: `<FILLED AFTER EXPORT>`
- Expected fixture size: `4271` bytes
- Expected fixture SHA-256: `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- Expected BUILD STAMP: version `0.5.4`, commit `<FILLED AFTER EXPORT>`, built `<FILLED AFTER EXPORT>`

PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.5.4_debug.exe -Algorithm SHA256
Get-FileHash .\two-map-skirmish-1.0.zip -Algorithm SHA256
```

- [ ] Filenames, sizes, hashes, Main Menu `v0.5.4`, and the log's BUILD STAMP all
      match the values above. Stop and report if identity differs — a mismatched
      log cannot be triaged against this build.

## Tester

Default tester is the project owner. If someone else runs it, name them in your
comments; identity is deliberately not baked into the log.

---

# Part A — v0.5.4 fix verification

## A1. Mid-battle Continue records the campaign result (V053-01) — critical

The v0.5.3 bug: continuing a **suspended mid-battle** map orphaned the map from
the campaign, so the eventual win/loss was ignored and Results showed
"next battle is unavailable" → Return to Menu, losing the win.

Run the shipped **Proving Grounds** campaign (or the imported Two-Map Skirmish).
Launch a battle node, take **one or two turns so it is genuinely mid-battle**,
then use **Suspend & Quit**. Fully close the app, relaunch it, and choose
**Continue**.

- [ ] Continue drops you back onto the **same** live map at the exact turn/units
      you left (not a fresh board).
- [ ] Play the map to a **victory**. Results resolves normally and offers the real
      successor (e.g. `Continue: <next node>` or `Finish Campaign` on a terminal
      node) — **not** "Save: next battle is unavailable" and **not** a bare
      `Return to Menu` / "Campaign Data Error".
- [ ] The win **counts**: the campaign position advances and an autosave is
      written (Continue/Load afterwards resumes at the next node, not the map you
      just won).
- [ ] Repeat the suspend→Continue path but this time play to a **defeat**; the
      Defeat screen appears normally (feeds A2).

Successor button wording seen, and node before/after: ____________________

## A2. Retry on a resumed map repopulates the board (V053-02) — critical

The v0.5.3 bug: hitting **Retry** after a defeat on a **resumed** map reloaded an
**empty** board — no units on either side, no objective HUD.

From the suspend→Continue **defeat** in A1, choose **Retry**.

- [ ] The map reloads with **all units present** on both sides and the
      **Objectives HUD visible** — not an empty painted map.
- [ ] The retried map plays normally from its start (ledger round 0), and can be
      won or lost again without the empty-board symptom.

Units seen after Retry, and whether the objective panel appeared: ____________________

## A3. Between-map full heal (V053-03)

The v0.5.3 bug: with Permadeath **Off**, a unit that fell (retreated) re-entered
the next map at **0 HP** ("walking dead") and died to any hit.

With **Permadeath Off**, on a campaign map let one unit **fall** (be defeated so
it retreats) and let another take damage but survive; then **win** the map and
advance to the **next** campaign map.

- [ ] The retreated unit re-enters the next map at **full HP** (not 0 / not
      "walking dead").
- [ ] The unit that took damage also re-enters at **full HP** (no carried damage
      between maps).
- [ ] Contrast — a **suspend & Continue** of a *damaged* board still restores the
      exact mid-map HP (the heal is a fresh-launch step only, never applied to a
      resumed board).

Unit HP entering the next map, and the resumed-board HP: ____________________

## A4. Per-campaign manual save budget + Replace + slots-full message (V053-04)

The v0.5.3 bug: manual Prep saves failed "randomly" (a global cap of 3), Replace
failed at the cap, and the only feedback was "Save failed."

In **one** campaign, use **Save** at Prep to create manual saves.

- [ ] The **3rd** manual campaign save still succeeds; the **4th distinct** one is
      refused with a readable message naming the cap, e.g. **"All 3 campaign save
      slots are in use — delete one from Load Game."** (not a bare "Save failed.").
- [ ] Saving again at a Prep whose label already exists prompts **"Replace Save?"**
      and, when confirmed, **succeeds even at the cap** (it overwrites in place —
      no "Save failed.", no duplicate, exactly one slot for that label).
- [ ] A manual save in a **different** campaign still succeeds while the first
      campaign is at its cap (the budget is **per-campaign**, not global).
- [ ] **Load Game** offers a **Delete** on a save (with a confirm prompt); deleting
      one frees a slot so a new save in that campaign succeeds again.

Message text seen at the cap, and per-campaign/Replace behavior: ____________________

## A5. HUD Layout Editor blocks input underneath (V053-05)

The v0.5.3 bug: while the HUD layout editor was open, WASD/arrow keys still drove
the settings screen (and the map cursor) **behind** it.

Open **Settings → Display & Accessibility → Edit HUD Layout** (open it **over a
live map** if you can, so both consumers are exercised).

- [ ] With the editor open, pressing **WASD / arrow keys** does **not** scroll or
      move focus on the settings screen behind it.
- [ ] If opened over a live map, the **map cursor does not move** and the map does
      not accept input while the editor is open.
- [ ] Closing the editor (Done or Cancel) **restores** normal keyboard navigation
      on the settings screen — focus repeat works again immediately.

Screenshot of the open editor, and any leaked movement: ____________________

## A6. HUD Layout Editor toolbar is fully usable (V053-06) — the live check

The v0.5.3 report: toolbar buttons glowed on hover but "did nothing"; and a
Done/Cancel dead-button could not be reproduced from source and needs a live look.

In the open editor:

- [ ] **Scale Panel −/+** are **disabled (greyed)** until you click a panel frame
      to select it; after selecting a panel, they visibly change its scale.
- [ ] **Every** toolbar button responds to a click — **Scale −**, **Scale +**,
      **Reset**, **Done**, **Cancel** — including where a panel frame overlaps the
      toolbar strip (no frame "eats" a toolbar click).
- [ ] **Done** saves the layout (reopen Settings → the change persists); **Cancel**
      discards changes back to how the layout was when you opened the editor.
- [ ] Drag a panel and confirm it moves; **Reset** returns panels to the authored
      layout.

Which buttons responded, and Done/Cancel behavior: ____________________

## A7. Continue telemetry & Results-quit hygiene (V053-08 / V053-09)

- [ ] In the returned `godot.log`, each **Continue** logs `campaign_restored`
      **once** (a re-stage logs `campaign_restaged`) — not two identical
      `campaign_restored` lines.
- [ ] If you ever reach a Results screen whose only option is **Return to Menu**,
      taking it leaves **no active campaign** (Main Menu Continue does not resume a
      dead campaign; starting fresh behaves cleanly).

Log lines seen around a Continue: ____________________

---

# Part B — Carried-forward checks not completed in prior v0.5 rounds

## B1. Controller coverage (NOT RUN in v0.5.1 / v0.5.2 / v0.5.3)

No controller was available in the previous three rounds, so **every** pad check
and all `PLAYTEST CONTROLLER` evidence remain unverified. If a controller is
available this round, run it; otherwise mark `NOT RUN — no controller` and say so.

- [ ] Menu navigation (Main Menu, Settings, Load Game) works by **d-pad/stick +
      face buttons**; confirm/cancel map to the expected buttons.
- [ ] On a map, the **d-pad/stick moves the cursor**, confirm selects, cancel backs
      out; the Action Menu and Rewind selector are navigable by pad.
- [ ] **Hotplug**: connecting/disconnecting the controller mid-session is handled
      without a crash, and a `PLAYTEST CONTROLLER` line appears on connect and
      disconnect.
- [ ] While a modal (Results / Defeat / HUD editor) is open, the **d-pad/stick do
      not** drive the map behind it.

Controller model (or `NOT RUN — no controller`): ____________________

## B2. Full-history Rewind scrollbar (V053-10 — could not be exercised in v0.5.3)

The v0.5.3 tester could not build enough history to overflow the Rewind selector,
so the new scrollbar was never seen live. Build a **long** history: play several
turns with **many** activations (the between-map heal makes a longer campaign map
survivable), then open the map-menu **Rewind** selector.

- [ ] With more rows than fit, the selector shows a **vertical scrollbar** and
      **stays at its authored height** (it does **not** grow taller than the panel
      / off the screen as history grows).
- [ ] Scrolling (mouse wheel and **keyboard focus**) moves through the full list;
      the oldest rows are reachable and selectable.
- [ ] Choosing an off-screen row restores that boundary correctly (HP, units,
      phase, cursor, RNG, economy, and remaining charges).

Rough number of rows, and whether it scrolled vs grew: ____________________

## B3. Map 005 pure-Survive — reworded (V053-07: the old turn-8 item was untestable)

`map_005_defend`'s survive target is 6, so the v0.5.3 "passing turn 8 does not
lose" check could never be exercised. Reach **map_005_defend** by any path.

- [ ] The objective reads a plain **Survive N turn(s)** — there is **no**
      "Hold (x, y)" tile requirement.
- [ ] **No defeat occurs on any turn up to the survive target** — you are not
      "timed out" before reaching it.
- [ ] Surviving **to** the required turn resolves the map as a **victory**.
- [ ] Any other map that shows a "Hold (x, y) …" objective reads its coordinates
      one-based (top-left tile is `(1, 1)`).

Objective text seen, and the turn the map resolved on: ____________________

## B4. Provenance logging present (v0.5.3 left §9 blank — tester-confirm this round)

Open the returned `godot.log` (do not retype it — just confirm it is present and
populated):

- [ ] It begins with the **BUILD STAMP**, then a framed `=== RUNTIME ENVIRONMENT
      ===` block with populated OS/CPU/GPU/display/locale/window fields.
- [ ] `PLAYTEST CONTEXT` JSON lines appear at campaign start, at each node launch,
      after every Continue/restore (with a `node_resumed` line for a resumed
      battle), naming the campaign, node, and package.
- [ ] A `PLAYTEST CONTROLLER` line appears for any controller used (or none if B1
      was `NOT RUN`).

Confirm present, and note anything empty/`headless`/malformed: ____________________

## B5. Connected-campaign / NG+ benefit (NOT RUN in v0.5.1 — no completion record)

v0.5.1 could not test the record-backed New Game benefit because no fresh
**Proving Grounds** completion record existed. If you can produce one this round
(complete Proving Grounds), run this; otherwise mark
`NOT RUN — no Proving Grounds completion record`.

- [ ] A **clean** start (None — start clean) does **not** grant the Proving Grounds
      Medal and does **not** inherit its gold.
- [ ] A **record-backed** start begins with exactly the final Proving Grounds party
      gold, and the designated unit has one **Proving Grounds Medal** (infinite
      uses); no other unit gets a duplicate.
- [ ] The benefit applies **once** — Retry, map reload, and Continue do not
      duplicate it.

Record used (or `NOT RUN — no completion record`): ____________________

---

# Part C — Retained regression sweep (v0.5.3 / v0.5.2 / v0.5.0)

Re-exercise the areas the fixes touch; Part A already covers their focused
behavior and is **cross-referenced, not restated** here.

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
- [ ] **Paired escape** — pairing the two escape units and escaping the lead takes
      both off the map on one action; neither is later a casualty; both survive into
      the next node with sane coordinates (v0.5.3 review row 3).
- [ ] **FileDialog printable bindings** — in Import, the first press of `X` types
      `x` and `Z` types `z` (they do not confirm/cancel); Backspace and editing
      work; import `two-map-skirmish-1.0.zip` succeeds (v0.5.3 review row 5).
- [ ] **Manual End Turn** — with more than one unit able to act, End Turn advances
      the phase exactly once, and Rewind then offers one boundary per auto-waited
      unit (v0.5.3 review row 6).
- [ ] **Menu Scale & layout** — Main Menu, Prep, Results, dialogs, Unit Details,
      Attack Preview, and the Action Menu stay on-screen and readable at 0.5x,
      1.0x, and 2.0x; windowed resize/maximize/restore recenters and does not drift
      controls off-screen.
- [ ] **Combat & deferred skills** — one confirmed combat resolves exactly once with
      matching HP/durability/XP/death; Attack Preview cancel changes nothing; a
      promotion-validation combat emits no `_apply_unimplemented` warning.

Notes/screenshots for anything that regressed: ____________________

## Logs and return package

- [ ] No crash, assertion, parser, missing-resource, restore, package-validation,
      or transaction error appears in the log after the BUILD STAMP.
- [ ] For each failure, record exact steps, expected vs actual behavior,
      repeatability, the relevant save name, and an original-resolution screenshot.

Return to:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.4/`

Include the completed checklist, the **original** `godot.log`, and focused
screenshots for: Main Menu layout, the mid-battle Continue → Results progression
(A1), the Retry-repopulated board (A2), the between-map HP of a fallen unit (A3),
the slots-full save message (A4), the open HUD Layout Editor (A5/A6), and the
overflowing Rewind selector with its scrollbar (B2). Human comments remain
required for observed behavior, reproduction steps, expected/actual results, and
anything not run. Then tell the maintainer:

```text
v0.5.4 return is ready in AGENT/Incoming/v0.5.4/.
```
