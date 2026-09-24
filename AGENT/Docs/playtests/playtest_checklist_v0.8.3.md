---
Role: dated
Type: playtest
Status: Candidate preparation
Last verified: 2026-09-24
---

# v0.8.3 Windows Tester Checklist

v0.8.1 and v0.8.2 were both rejected before native testing. This replacement
keeps their feature scope. It carries v0.8.2's two forecast fixes plus the one
finding that rejected v0.8.2: below about 1000 px of usable width the forecast
ran off the right edge of the screen. Return this completed
checklist, the diagnostics ZIP, and screenshots for every failed visual check.

## 0 — Identity and clean start

- [ ] `BUILD_INFO.json`, `SHA256SUMS.txt`, the executable BUILD STAMP and Main
  Menu all say v0.8.3 and agree on the source commit.
- [ ] Start with a clean profile. New Game and Load Game show clear empty states.
- [ ] Import the supplied `free-roam.zip` without editing or re-zipping it.

## 1 — Rejection fixes (must run first)

- [ ] In Chapter 3 — The Commander, attack the Bridge Fighter with Unit_06
  (Knight, Iron Lance). The attacker shows `▼ Weapon Triangle -10 Hit, -2 Dmg`.
  The defender shows both `▲ Weapon Triangle +10 Hit, +2 Dmg` and
  `▲ Weapon Effectiveness ×3 Might`.
- [ ] At 1280×720, 1920×1080, under 600 px wide, and menu/content scales 0.5 and
  2, the two defender rows are distinct, readable, and do not overlap the terrain
  card, forecast totals, or More Info column. Screenshot every size.
- [ ] Under 600 px wide (content scale 1), the forecast fits entirely on screen:
  no column, row or More Info text is cut off at any edge. On a narrow window the
  panel is meant to stack attacker, defender and More Info vertically, and at
  medium widths it may put More Info below the two combatants. State whether the
  stacked layout is still easy to compare.
- [ ] Open Hallowed Rites through More Info in the internal Chapter 6 matchup.
  It says `Overrides in this fight: Undead Frailty.` It contains no snake_case
  profile or rule ids.
- [ ] The forecast itself still shows Hallowed Rites and omits Undead Frailty;
  the explanation belongs in More Info rather than adding a misleading applied row.

## 2 — Relationship regression

- [ ] Prologue: Unit_02 sword versus the lance dummy shows disadvantage under
  Unit_02 and advantage under the dummy; Unit_01 lance versus lance shows no row.
- [ ] Chapter 1: Unit_04 Fire versus E2_Mage Thunder shows no row (anima is
  neutral to anima).
- [ ] Chapter 3: Unit_04 Fire versus the Chapel Bishop's light tome shows the
  magic-triangle +10 Hit/+2 Dmg and -10 Hit/-2 Dmg rows.
- [ ] Chapter 1: Equip Unit_01's Horseslayer before attacking E3_Cavalier. The
  forecast shows `▲ Weapon Effectiveness ×3 Might`, and the displayed damage
  changes by the relationship's actual contribution.
- [ ] Mouse selection and the `F`/pad-button-2 More Info cycle reach every row;
  Enter commits the attack and the on-screen hint says so.
- [ ] The campaign-provided UI font activates and restores on exit. Arrows,
  bullets, dashes, checkmarks and infinity symbols never become boxes.

## 3 — Internal authored proof

The supplied internal FE pack is private-only. Do not redistribute, stream, or
include it in a public build; delete the tester copy when the round closes.

- [ ] Reach Chapter 6 with Hallowed Bearer and Free Company Axeman present and
  confirm their non-weapon stats are still identical.
- [ ] Against the same Revenant, Hallowed Bearer shows Hallowed Rites +5 Dmg and
  the control axeman shows Undead Frailty +1 Dmg. Record Hit/Dmg/Crit for both.
- [ ] Land the Hallowed hit. Unit Details names `Hallowed Sear`, shows `-3` and
  the remaining phases; Resistance's breakdown includes the same condition and
  reaches the displayed total.
- [ ] The duration ticks down and expires. Suspend & Quit and Continue preserve
  its remaining duration and both units' state.

## 4 — Native and editor regression

- [ ] Diagnostics identify v0.8.3, Windows, GPU/display/DPI, window mode,
  installed/active packs and the interaction rows exercised above.
- [ ] Export Diagnostics produces a readable ZIP containing the current session.
- [ ] End Turn, Suspend & Quit, destructive quit and save replacement dialogs
  state what Enter does and focus the safe intended action.
- [ ] Settings remains usable below 600 px wide and at scale 0.5/2.
- [ ] Restore `campaign_backup_v2.zip`; exercise both migration packs and both
  same-version fingerprint-collision packs.
- [ ] At 1920×1080 or larger, Campaign Editor opens on its own opaque background.
  Open or create a working copy, change one value, save it, verify dirty-state
  behavior, then close the editor and confirm menu scale is restored.

## 5 — Judgement and return

- [ ] State whether two simultaneous relationship rows are readable and useful.
- [ ] State whether the suppression explanation makes the missing Undead Frailty
  row understandable without prior knowledge.
- [ ] State whether relationship names read as game language or implementation labels.
- [ ] State whether the condition name, duration and arithmetic explain the live stat.
- [ ] State whether the game is presently playable, clear and polished (not whether
  its campaign tuning is difficult or balanced).
- [ ] Return the checklist, diagnostics ZIP, defect screenshots, Windows/GPU/display
  details, build stamp, sections run, and any save needed to reproduce a failure.
- [ ] Confirm deletion of the internal FE pack copy.

Native acceptance remains pending until this evidence is reviewed.
