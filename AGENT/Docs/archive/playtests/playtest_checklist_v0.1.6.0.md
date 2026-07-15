> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Playtester Checklist — v0.1.6.0 (focused re-test)

**Status:** Pending validation — focused re-test list for the build cut after the
v0.1.5.0 return pass. This is the versioned checklist for v0.1.6.0; it is
**focused, not a full handbook**. Pair it with the completed
`AGENT/Docs/playtest_checklist_v0.1.5.0_returned_2026-06-14.md` and the full
`AGENT/Docs/playtest_checklist_v0.1.5.0.md` handbook: only the items below changed
since v0.1.5.0, plus the new character-sheet checks. Items the v0.1.5.0 tester
already passed and that did not change do not need re-running.
**Last verified:** 2026-06-14

This is **not** a full handbook. Most of the v0.1.5.0 build was re-verified as
passing; this covers what is new or was left open.

## Distribution bundle (what the tester needs)

Hand the tester **all three** of these together — this focused checklist does not
repeat the setup/controls/basic-flow sections or the unchanged checks:

1. `Project_Prometheus_v0.1.6.0_debug.exe` (the build).
2. **This** file (`playtest_checklist_v0.1.6.0.md`) — the changed + new checks.
3. `playtest_checklist_v0.1.5.0.md` — the full handbook: build setup, controls,
   terms, and every check whose behaviour did not change since v0.1.5.0.

## Build

- Executable: `Project_Prometheus_v0.1.6.0_debug.exe`
- Source commit: `a947faf`
- Expected file size: `101,214,696` bytes
- Expected SHA-256:
  `706faf26a9b49fbffde1d295cc3dd1d2239e8bcdae304c2cab66186ea7f80705`
- Manifest: `AGENT/Docs/playtest_build_v0.1.6.0.md`

Optional PowerShell integrity check:

```powershell
Get-FileHash .\Project_Prometheus_v0.1.6.0_debug.exe -Algorithm SHA256
```

The fixes/feature below are verified by the automated suite and headless checks.
The dev container cannot render a window, so the **visual** items (the green/red
stat colouring, the reclass wrap, the no-counter Battle Speed line, the character
sheet breakdown) still need a human eyeball pass on the real build.

## Changelog since v0.1.5.0

- **#8.6 — reclass option lines wrap (was a horizontal scrollbar).** The Second
  Seal picker's option buttons now autowrap; the list scrolls vertically only.
- **#8.3 — defender Battle Speed shown on no-counter previews.** The Damage field's
  More Info now reads `Attacker N vs Defender M … (defender cannot counter)` instead
  of hiding the defender's value.
- **NEW — comprehensive character-sheet stat breakdown.** The `I` inspect sheet now
  shows, per stat: **Personal base + Class base + Class cap**, the **Effective** value
  (green when raised by a bonus, red when lowered by a net debuff), and a **Bonuses**
  list with each bonus's amount + source (Pair Up, the unit's stat skills, items /
  tonics). Caps with no authored value show a loud `NO_CAP_DEFINED`; intentionally
  uncapped stats (MOV/CON/LoS) show "—".
- **#8.5 closure — pair-up now appears on the character sheet.** Previously the Pair
  Up bonus showed only on the HUD corner panel, never on the `I` sheet. It now appears
  on the sheet too (the surface the v0.1.5.0 tester reported as empty).

## Re-verify (previously failed/flagged — should now pass)

### R1 — Reclass option lines wrap (handbook 8.6)
On Map 950, use a unit's `Second Seal` and open the class list.

**Expected**
- Each option's long `old +Δ -> new / cap` line wraps to additional lines within
  the panel — **no horizontal scrollbar**.
- The list still scrolls vertically when there are many options, and every option
  is reachable.

### R2 — Defender Battle Speed on a no-counter preview (handbook 8.3)
Preview an attack the defender cannot counter (e.g. an Archer hitting a melee-only
enemy from 2 tiles). Open More Info (`F`) and cycle to **Damage**.

**Expected**
- The Battle Speed line shows **both** sides, e.g. `Attacker 7 vs Defender 3`,
  followed by `(defender cannot counter)` — the defender's value is no longer hidden.

### R3 — Re-run the two v0.1.5.0 NOT-RUN items
These came back unchecked with no comment; confirm pass/fail this round.
- **3.1 (Map 002 Seize):** routing every Red unit without seizing does **not** trigger
  a victory; the map stays active.
- **8.4 (Map 950):** `Strength Tonic` gives `+4 Str` for `4 turns`, the modifier line
  shows in the breakdown, and Effective returns to Base after four full turns.

## New checks to add to the handbook

### N1 — Character-sheet stat breakdown (Map 950, `Pair Up: On`)
Pair `M950_Hero_SkillCap` as **lead** with `M950_Cavalier` as **support**. On the
next Blue phase, put the cursor on the **Hero** and press `I`, then select the
**Strength** stat (click it or cycle `F`).

**Expected**
- The breakdown shows `Personal base`, `Class base  +N  (Hero)`, and `Class cap N`.
- **Effective** is shown in **green** (a bonus is raising it).
- **Bonuses** lists `Pair Up  +3  (this combat)` for Strength (and the matching
  `+3 Spd / +2 Skl / +3 Def / +1 Lck` on those stats). This is the #8.5 surface that
  previously showed nothing — it must now appear **on the sheet**, not just the HUD.

### N2 — NO_CAP_DEFINED placeholder (Map 950)
After demoting `M950_General` to `Soldier` (handbook 8.6 flow), press `I` on that unit
and inspect any combat stat.

**Expected**
- The Class cap line reads a loud `NO_CAP_DEFINED` (Soldier is an intentional
  cap-less placeholder). Every non-placeholder class shows a real cap number.

### N3 — Tonic shows in the breakdown + green (ties to 8.4)
After applying `Strength Tonic` (8.4), press `I` and select Strength.

**Expected**
- Effective is green; Bonuses lists the tonic with its `+4` and remaining duration.
- (A **red** Effective for a net debuff is covered by automated tests; verify live
  only if the build exposes a stat-lowering source.)

## Unchanged / still deferred

- **2.4 — weapon names in the combat preview.** Enhancement, not implemented this
  round; do not report as a regression.
- **Aura stat contributions** — aura skills remain M9 stubs (they affect hit/dodge/
  crit, not base stats), so they do not appear in the stat breakdown yet. By design.
- The §10 known-deferred issues from the v0.1.5.0 handbook are unchanged.
