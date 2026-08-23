---
Role: dated
Type: playtest
Status: Pending validation
Last verified: 2026-07-23
---

# v0.5.5 Windows Verification Checklist

## Purpose

This build is the **visual pass** for the v0.5.4 controller/UI rework and this
round's input-ordering repair. v0.5.4 reworked Prep, Results, Defeat, and Rewind
for controller navigation and added authored result-actions, but its returned
playtest found: the controller could not reach Prep; Defeat/Victory did not
repeat on held input and their selectors did not cycle; Rewind became
unreachable after being reopened; and the HUD-editor phase marker was locked
under the toolbar. The root-cause review traced the navigation failures to the
directional suppression being wired one input stage too late, so the engine's
built-in focus step and the menu's own poller **both** moved focus. This round
moves that suppression to the correct stage and adds the missing open-dropdown
gate.

**Part A** verifies this round's repairs. **Part B** re-runs the checks that
still could not be completed in prior v0.5 rounds (controller hotplug, provenance
logging, the connected-campaign benefit, FileDialog printable bindings, and the
Continue telemetry). **Part C** is the retained regression sweep.

Use a fresh folder containing only the supplied executable and fixture.

**How this checklist is read.** There is no PASS/FAIL box. Triage derives the
verdict from your comments, the checks you complete, the returned `godot.log`,
your screenshots, and any failures you record. A check left blank is not a pass —
it is unknown. Mark anything you could not run `NOT RUN — <reason>`, and describe
what you actually observed for anything that looked wrong. **A controller is the
primary instrument this round — if none is available, say so up front, because
Part A is mostly pad behavior.**

**What the log already captures — do not retype it.** Treat these blocks in
`godot.log` as authoritative: the framed `=== RUNTIME ENVIRONMENT ===` block
(OS/CPU/GPU/display/locale/window), `PLAYTEST CONTROLLER` lines (connect at
startup and every hotplug), and `PLAYTEST CONTEXT` JSON lines (campaign/node/
package identity at start, restore, and node launch — one `campaign_restored`
per Continue, a `campaign_restaged` on a re-stage, and a `node_resumed` line when
a suspended battle is continued).

## Build identity

- Executable: `Project_Prometheus_v0.5.5_debug.exe` (the Main Menu reads `v0.5.5`;
  the authoritative version is the log's BUILD STAMP)
- Campaign fixture: `two-map-skirmish-1.0.zip`
- Expected executable size: `102184552` bytes
- Expected executable SHA-256: `f1041663c03afd5a0ee0349fd99171cb63cfb7a5ce6ee74c903a434ad1c6f200`
- Expected fixture size: `4271` bytes
- Expected fixture SHA-256: `5b5ae637ff782b0b134355bbc409971e590cd1c09e3119a5303a96b3e330123e`
- Expected BUILD STAMP: version `0.5.5`, commit `6651481`, built `2026-07-23T00:56:21Z`

PowerShell:

```powershell
Get-FileHash .\Project_Prometheus_v0.5.5_debug.exe -Algorithm SHA256
Get-FileHash .\two-map-skirmish-1.0.zip -Algorithm SHA256
```

- [ ] Filenames, sizes, hashes, Main Menu `v0.5.5`, and the log's BUILD STAMP all
      match the values above. Stop and report if identity differs.

## Tester

Default tester is the project owner. If someone else runs it, name them in your
comments; identity is deliberately not baked into the log.

---

# Part A — v0.5.5 fix verification (controller-first)

## A1. Prep is reachable and navigable by controller (V054-RC-01) — critical

The v0.5.4 bug: the Xbox controller could not access the Prep screen at all.

Reach a between-map **Prep** screen with **only the controller** — do not touch
the mouse after Prep appears (a mouse click would establish focus and hide the
bug).

- [x] On arrival, a control is **already focused** (a unit toggle, or Save/Begin
      if no unit is eligible) — you can move immediately with the d-pad/stick.
- [x] The d-pad/stick moves focus through the unit toggles, the Up/Down reorder
      controls, and Save/Begin; **holding** a direction **repeats** at a steady,
      readable cadence (not one step, not a runaway sprint).
- [x] Toggling a unit and reordering with the row's Up/Down controls works by pad;
      rebuilding the roster does **not** throw focus back to the top.
- [x] Begin starts the map; Save writes a manual slot (feeds Part C save checks).

Focused control on arrival, and whether held-repeat felt right: Works, but when scroling up from save the focus goes to Unit_06 but the scrolling window doesn't adjust to make it viewable. Non blocking bug. Consider leaving and making the refined prep screen a higher priority.)

## A2. Results and Defeat step exactly once and cycle (V054-RC-01/-03) — critical

The v0.5.4 bug: no repeat on held input on the Victory/Defeat screens, and the
selectors did not cycle. The repair also must not overshoot — pressing a
direction **once** must move focus **one** item, not two.

On a **Victory** (Results) screen and a **Defeat** (Game Over) screen, both by
controller:

- [x] A **single** d-pad press moves focus **exactly one** button — it does not
      skip every other option or jump two at a time.
- [x] **Holding** the direction repeats at the same steady cadence as A1.
- [x] Navigation **wraps**: moving past the last action returns to the first (and
      past the first returns to the last).
- [x] Confirm/cancel select and back out as expected on both screens.

Single-press step count seen (one vs two), and whether it wrapped: save should not remove retry without campaign rul

## A3. Results successor dropdown navigates itself, not the screen behind it (V054-RC-01)

On a **branching** Victory where Results shows the successor **dropdown**
(OptionButton), open the dropdown with the controller and press up/down.

- [ ] Up/down move the **highlight inside the open dropdown list** — focus on the
      buttons **behind** the dropdown does **not** move while it is open.
- [ ] Closing the dropdown (select or cancel) returns control to the Results
      buttons with no surprise focus jump.

What moved while the dropdown was open: I could not find anything labeled successor dropdown. No bugs noticed in any exercised area, but it is possible that this system just exposed?

## A4. Rewind is reachable every time it is opened (V054-RC-02) — critical

The v0.5.4 bug: Rewind was pad/keyboard-accessible the first time, but after
being closed and reopened neither controller nor keypad could access it until the
map was fully reloaded.

Open the map-menu (or Defeat) **Rewind** selector, **Cancel** it, then **open it
again** — repeat this open→cancel→open cycle a few times without reloading the map.

- [x] **Every** reopen lands focus on a live choice button — the controller and
      keyboard can move through the list on the 2nd, 3rd, … open, not just the 1st.
- [x] With more rows than fit, held up/down **repeats** through the list and keeps
      a little **padding** visible past the focused row (you can see a row or two
      ahead in the direction you are moving), and the panel stays at its authored
      height with a scrollbar.
- [x] Choosing an off-screen row restores that boundary correctly (HP, units,
      phase, cursor, RNG, economy, remaining charges).

Reopen behavior across several cycles, and whether padding/lookahead appeared: When moving the cursor from cancel down to the bottom most selection, the scrolling section jumps up to around the middle of the list but the cursor stays on its correct location. if you d-pad up one more slot the view lines up with the cursor at the very bottom with a single row hidden. If you go up once more, then you get a similar visual jump up the line while the cursor goes to the correct place that is no longer on the screen.

## A5. HUD editor: the top-edge phase marker is reachable (V054-RC-04)

The v0.5.4 bug: the phase marker sat under the full-width toolbar strip and could
not be selected or dragged; the log also carried seven anchor-size warnings.

Open **Settings → Display & Accessibility → Edit HUD Layout** (over a live map if
you can).

- [ ] The **phase/turn marker at the top edge** can be **clicked to select** and
      **dragged** — the toolbar band no longer swallows clicks over empty space.
- [x] **Every** toolbar button still responds (Scale −/+, Reset, Done, Cancel),
      including where a panel overlaps an actual toolbar button.
- [x] Pressing **left/right on the keyboard or d-pad cycles the selected panel**,
      so a panel is reachable even where a control overlaps it.
- [x] Done saves; Cancel restores the layout as it was on open.
- [ ] In the returned `godot.log`, there are **no** repeated toolbar anchor/size
      warnings after the BUILD STAMP.

Screenshot of the phase marker selected/moved, and any button that did nothing: Add a note to later look into more complete controler bindings for the edit hud layout

## A6. Authored victory result actions (V054-FR-03)

v0.5.4 added campaign-authored Retry / Save / Quit on the Victory (Results)
screen. Defaults show all of them.

- [x] On a Victory, **Retry Battle**, **Save**, **Quit to Main Menu**, and
      **Continue** are present (per the campaign's default policy).
- [x] **Retry Battle** discards the pending result and routes back through Prep;
      the win is **not** committed (Continue/Load afterwards does not resume past
      the map you just retried).
- [x] **Save** commits the result **first**, then writes a between-map slot — a
      readable status line confirms it, and the button disables so you cannot
      double-save. Loading that slot resumes at the committed position (no replayed
      rewards, no lost win).
- [x] **Quit to Main Menu** leaves no active campaign resuming a finished map.

Which actions appeared, and Retry/Save/Quit behavior observed: Save should not remove retry by default

## A7. Continue telemetry & Results-quit hygiene (V053-08 / V053-09)

- [ ] In the returned `godot.log`, each **Continue** logs `campaign_restored`
      **once** (a re-stage logs `campaign_restaged`) — not two identical lines.
- [ ] A Results screen whose only option is **Return to Menu**, when taken, leaves
      **no active campaign** (Main Menu Continue does not resume a dead campaign).

Log lines seen around a Continue: Continue was not disabled, but a "Alert! Could not load the campaign save. Progress was not resumed."


# Part B — Carried-forward checks not completed in prior v0.5 rounds

## B1. Controller hotplug (NOT RUN in v0.5.1 / v0.5.2 / v0.5.3 / v0.5.4)

- [ ] Connecting/disconnecting the controller mid-session is handled without a
      crash, and a `PLAYTEST CONTROLLER` line appears on connect **and** disconnect.
- [ ] After a reconnect, controller navigation still works on the current screen.

Controller model (or `NOT RUN — no controller`): No crash or errors noticed during testing. log not checked.

## B2. Provenance logging present (tester-confirm this round)

Open the returned `godot.log` (do not retype it — just confirm it is populated):

- [ ] It begins with the **BUILD STAMP**, then a framed `=== RUNTIME ENVIRONMENT
      ===` block with populated OS/CPU/GPU/display/locale/window fields.
- [ ] `PLAYTEST CONTEXT` JSON lines appear at campaign start, at each node launch,
      and after every Continue/restore (with a `node_resumed` line for a resumed
      battle).

Confirm present, and note anything empty/`headless`/malformed: ____________________

## B3. Connected-campaign / NG+ benefit (NOT RUN since v0.5.1 — no completion record)

If you can produce a fresh **Proving Grounds** completion this round, run this;
otherwise mark `NOT RUN — no Proving Grounds completion record`.

- [x] A **clean** start (None — start clean) does **not** grant the Proving Grounds
      Medal and does **not** inherit its gold.
- [x] A **record-backed** start begins with exactly the final Proving Grounds party
      gold, and the designated unit has one **Proving Grounds Medal** (infinite
      uses); no other unit gets a duplicate.
- [x] The benefit applies **once** — Retry, map reload, and Continue do not
      duplicate it.

Record used (or `NOT RUN — no completion record`): Fresh record created and used 3400 gold and proving grounds medal.

## B4. FileDialog printable bindings (v0.5.3/v0.5.4 left blank)

- [x] In Import, the first press of `X` types `x` and `Z` types `z` (they do not
      confirm/cancel); Backspace and editing work; importing
      `two-map-skirmish-1.0.zip` succeeds.

What the keys did in the filename field: works but the escape button fully closes out the file system instead of just backing out of the text box.

---

# Part C — Retained regression sweep

Re-exercise the areas the fixes touch. Part A covers their focused behavior.

- [ ] **Mid-battle Continue records the result** — Suspend & Quit mid-map,
      relaunch, Continue drops onto the same live map; playing to a win advances
      the campaign and autosaves (not "next battle is unavailable").
- [ ] **Retry on a resumed map** repopulates the board with all units and the
      objective HUD (not an empty painted map).
- [ ] **Between-map full heal** (Permadeath Off) — a fallen/retreated unit and a
      damaged unit both re-enter the next map at full HP; a suspend→Continue of a
      damaged board still restores exact mid-map HP.
- [ ] **Per-campaign save budget + Replace** — the 4th distinct manual save is
      refused with the slots-full message; Replace succeeds at the cap; a different
      campaign still saves; Load Game Delete frees a slot.
- [ ] **HUD editor input gate** — with the editor open, WASD/arrows do not drive
      the settings screen or the map behind it; closing restores navigation.
- [ ] **Campaign selector source ownership** — shipped choices appear once; an
      imported package appears once without hiding shipped content; stable across
      Suspend/Continue.
- [ ] **Two-Map Skirmish progression** — Chapter 1 Rout resolves, Results offers
      `Continue: River Pass`, and River Pass loads with the expected units/objective.
- [ ] **Load fidelity** — Autosave/Load Game preserves package identity, roster,
      gold, inventory, rewind history, and remaining charges.
- [ ] **Menu Scale & layout** — Main Menu, Prep, Results, dialogs, Unit Details,
      Attack Preview, and the Action Menu stay on-screen and readable at 0.5x,
      1.0x, and 2.0x; resize/maximize/restore recenters.
- [ ] **Combat** — one confirmed combat resolves exactly once with matching HP/
      durability/XP/death; Attack Preview cancel changes nothing.

Notes/screenshots for anything that regressed: ____________________

## Logs and return package

- [ ] No crash, assertion, parser, missing-resource, restore, package-validation,
      or transaction error appears in the log after the BUILD STAMP.
- [ ] For each failure, record exact steps, expected vs actual behavior,
      repeatability, the relevant save name, and an original-resolution screenshot.

Return to:

`/workspace/godot-prometheus-env/repo/Project_Prometheus/AGENT/Incoming/v0.5.5/`

Include the completed checklist, the **original** `godot.log`, and focused
screenshots for: the Prep screen with controller focus (A1), the Results/Defeat
screens (A2), the open successor dropdown (A3), the reopened Rewind selector
(A4), the HUD editor with the phase marker selected/moved (A5), and the victory
result actions (A6). Then tell the maintainer:

```text
v0.5.5 return is ready in AGENT/Incoming/v0.5.5/.
```
</content>
