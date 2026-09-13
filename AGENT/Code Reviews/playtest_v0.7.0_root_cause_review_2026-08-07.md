---
Role: dated
---

# v0.7.0 Windows Playtest Return — Root-Cause Review

**Date:** 2026-08-07
**Build under review:** BUILD STAMP `version=0.7.0  commit=6cf2c89a`, verified in both logs
**Branch reviewed:** `agent/integration` @ `487dafaf` (the candidate's descendant)
**Evidence:** `AGENT/Docs/playtests/evidence/v0.7.0/`
**Return record:** [`../Docs/playtests/playtest_v0.7.0_windows_return_2026-08-07.md`](../Docs/playtests/playtest_v0.7.0_windows_return_2026-08-07.md)
**Verdict:** Do not ship `6cf2c89a`. Six confirmed blockers, two of which are content-
correctness defects that no headless suite can currently see. The round nevertheless
succeeded at what it was for: an installed pack played to a result, and four display-gated
rows can now close or move.

## How to read the supersession column

Every finding carries a **Disposition**. The round's stated purpose was to avoid repairing
surfaces that the responsive redesign is about to rewrite, so each finding is judged
against `AGENT/Docs/design/responsive_ui_redesign_2026-08-06.md` (eleven screen
conversions, size-class model, 360×640 floor) and against the open tracker rows.

| Disposition | Meaning |
|---|---|
| **Fix now** | Behaviour or data, not layout. The redesign will not touch it, and leaving it costs a later round. |
| **Fold in** | Real defect, but the file is already claimed by scheduled work that rewrites it. Attach the requirement to that row; do not spot-patch. |
| **No action** | Working as designed, already scheduled for deletion, or not reproducible from the returned evidence. |

## Executive summary

The two most expensive findings are not UI at all.

`V070-02` — every tome in both shipped packs computes damage as **STR − DEF** instead of
**MAG − RES**, because `uses_mag` is absent from every extracted weapon document and
defaults to `false`. This is the sixth instance of the failure shape the bundle's own
display-gated document warned about: *a field the projection does not emit takes a silent
default that changes behaviour, and validation passes.* It explains the tester's "the mage
was not doing as much damage as it used to … consistent between public and private pack"
exactly — consistent because the extractor dropped the field in both.

`V070-04` — `CampaignRules.exp_gaining_factions` exists, defaults to `["blue","green"]`,
round-trips through saves, is asserted by two test suites, is rendered to the player on the
Prep screen — and **is read by no gameplay code**. `CombatResolver` awards EXP to attacker
and defender unconditionally, so red units gain EXP and level mid-battle. A ratified rule
with full persistence and zero enforcement.

`V070-01` is the release blocker a first-time player hits before anything else: on any
display taller than 1080p, the first-launch content scale is derived from the **screen**
while the window opens at the project default **1280×720**, so the main menu renders into a
427×240 logical viewport and collapses. `main menu at default.png` shows it.

`V070-06` is why the round's headline question came back unanswered even though the tester
ran the test: the four-stage Escape instrumentation writes nothing to the log, so a guard
that fails to engage is indistinguishable from a guard that was never exercised.

---

## V070-01 — Blocker — First-launch content scale is derived from the screen, applied to the window

**Disposition: Fix now.** The redesign consumes this value (`logical viewport = backing ÷
content_scale_factor`) rather than replacing it; every size class a machine lands in is
wrong until it is right.

**Evidence.** Decision sheet 3: *"the default also appeared to be viewport 3x when I opened
it on the 4k monitor but the app still opened at 1280x720 so the main menu was unusable. At
1x viewport, the main menu looked fine at 720p."*
`raw/screenshots/main menu at default.png` — a 1280×720 window on a 3840×2160 desktop, title
legible, entire menu button column collapsed into one unreadable strip.

**Root cause.** `SettingsManager._derived_content_scale_factor()`
(`scripts/autoloads/SettingsManager.gd:1390-1396`) returns
`identity_factor_for_height(DisplayServer.screen_get_size(screen).y)` on desktop —
2160 ÷ 720 = **3.0**. `project.godot:60-61` opens the window at 1280×720. The logical
viewport is therefore 1280÷3 × 720÷3 = **427×240**, well under every authored minimum.

The correct function already exists and is already used on the web-touch path:
`fit_content_scale_factor_for_size(window_px)` (`:1379-1383`) floors the factor to what the
**window** can actually show. The desktop branch simply does not consult it.

**Recommended fix.** Take the minimum of the two on first launch, and re-fit on window
resize rather than only on screen change:

```gdscript
var identity := identity_factor_for_height(DisplayServer.screen_get_size(screen).y)
var fit := fit_content_scale_factor_for_size(DisplayServer.window_get_size())
return minf(identity, fit)
```

**Note the file claim.** `SettingsManager.gd` is claimed by
`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`, and the display-gated document expected this
round to release that claim. It did not (`V070-06`). This fix and that one now have to be
sequenced against each other rather than one waiting on the other — see the return record.

**Related, same file, lower severity (`V070-12`).** Decision sheet 3 also reports *"you can
currently still slide the viewport scale up high enough that at small resolutions the menu
gets cut off."* `normalize_content_scale_factor` clamps to `CONTENT_SCALE_FACTOR_MAX = 4.0`
(`:98-99`) with no window-relative ceiling. The same `fit_...` helper gives one. Fix in the
same change; it is the same bug seen from the slider instead of the default.

---

## V070-02 — Blocker — Extraction drops `uses_mag`; every tome deals physical damage

**Disposition: Fix now.** Content correctness. Nothing in the redesign or the prep/economy
work touches the damage formula.

**Evidence.** Checklist §5 free text: *"look for changes to the combat system recently, the
mage was not doing as much damage as it used to but all the stats look about the same,
consistent between public and private pack."*

Measured against the trees, not inferred:

| Source | `mt` | `uses_mag` |
|---|---|---|
| `data/weapons/fire.tres` (legacy project data) | 4 | `true` |
| `Campaign_Pack_FE` `packs/proving_grounds/data/weapon__fire.json` (internal) | 4 | **absent** |
| `Campaign_Pack_0` `packs/proving_grounds/data/weapon__fire.json` (public) | 4 | **absent** |

`grep -rn uses_mag` across both packs' `packs/` trees returns **nothing**, for all 16
weapons. Might is identical, which is why the stats "look about the same".

**Root cause.** Three things line up, and each on its own would have been caught:

1. `scripts/tools/extract_proving_grounds_pack.gd` never emits `uses_mag`.
2. `CampaignTier2RuntimeAdapter._build_weapons()`
   (`scripts/resources/CampaignTier2RuntimeAdapter.gd:170-194`) builds `WeaponData` with
   `_apply_properties(value, raw, …)`, which copies only keys present in `raw`. The export
   default `WeaponData.uses_mag = false` (`scripts/resources/WeaponData.gd:44`) therefore
   survives.
3. `EntitySchemaRegistry` declares `uses_mag` as a valid weapon property
   (`scripts/data/EntitySchemaRegistry.gd:352`) but requires nothing of it. The registry
   *does* cross-check that `wexp_track` coheres with `combat_family`
   (`wexp_track_family_mismatch`), so `fire` / `elemental_magic` validates happily while
   the flag that makes it magic is missing.

The consequence at `CombatResolver.compute_damage()` (`scripts/core/CombatResolver.gd:512-531`):
`base_stat` becomes STR instead of MAG and `def_stat` becomes DEF instead of RES. A mage
attacks with its worst stat into the defender's best one, both ways.

**Recommended fix — all three layers, in this order.**

- **Validator first** (`EntitySchemaRegistry`): a weapon whose `combat_family` /
  `wexp_track` resolves to a magic family and does not declare `uses_mag: true` is a
  document error, alongside the existing `wexp_track_family_mismatch`. This is what makes
  the class of defect loud instead of silent, and it is the DoD#2 obligation for the rule.
- **Extractor** (`extract_proving_grounds_pack.gd`): project `uses_mag` from the source
  `.tres`.
- **Re-emit both packs** and re-run `validate_pack.gd`. The new validator check is what
  proves the re-emission worked.

**Why this keeps happening.** Five prior instances (most recently `MapData.factions`) were
typed arrays left empty; this is the same shape with a boolean. Consider a general adapter
rule — a projected document that omits a property the schema declares should be reported
rather than defaulted — but that is a design question for
`IMPL-ZERO-CONTENT-FAMILIES`, not a condition of this fix.

---

## V070-03 — Blocker — Left click no longer selects in the default mouse mode

**Disposition: Fix now.** Input semantics, one line, and it contradicts a ratified design.

**Evidence.** Checklist §2 free text: *"Left click on the map no longer activates units …
second attempt failed to reproduce any of these except the mouse."* The mouse one
reproduced every time because it is unconditional.

**Root cause.** `MapCursor._handle_mouse_button()` (`scripts/core/MapCursor.gd:941-946`):

```gdscript
if event.button_index == MOUSE_BUTTON_LEFT:
    if _mouse_cursor_mode() == "click":
        _handle_primary_pointer_press(event.position)
elif event.button_index == MOUSE_BUTTON_RIGHT:
    _on_cancel()
```

The default mode is `follow` (`SettingsManager.gd:115`), so the left branch is dead on a
default install. Right-click cancel is ungated, which is why cancel works and confirm does
not — a combination that reads as "the mouse half-works".

`git log -L 941,947` attributes the gate to `9c62a599` *"V021-17: add mouse click cursor
mode"*. That commit **deleted** the comment that stated the opposite intent: *"Mouse clicks
are still accepted as confirm/cancel … because clicks are intentional and the toggle is
scoped to cursor follow, not all mouse input."* The design it implements says the same:
`AGENT/Docs/design/mouse_only_cursor_mode_design_2026-06-19.md:32` —
***`follow`** … cursor tracks hover; **click selects**.* The gate was added to the wrong
branch.

**Recommended fix.** Restore left-click confirm outside `disabled`:

```gdscript
if event.button_index == MOUSE_BUTTON_LEFT:
    match _mouse_cursor_mode():
        "click": _handle_primary_pointer_press(event.position)
        "follow": _on_confirm()
        _: pass          # "disabled" ignores the pointer entirely
```

**Test gap that let it through.** `scripts/tests/test_map_cursor.gd` covers click mode's
relocate-then-select contract and that motion is inert in click mode. Nothing asserts that a
left click in **follow** mode confirms. Add that assertion in the same change — it is the
regression that would have failed.

---

## V070-04 — Blocker — `exp_gaining_factions` is persisted, displayed, tested, and never enforced

**Disposition: Fix now.** Rules enforcement, not layout.

**Evidence.** Checklist §2 free text: *"also noticed red units gaining xp … later also
noticed red unit at higher level than they should be once."*
Log `godot2026-08-06T20.46.44.log`, one exchange, two awards:

```
"correlation":"tr-000003","fields":{"amount":14,"unit_id":2517471594805},"stage":"exp_awarded"
"correlation":"tr-000003","fields":{"amount":6,"unit_id":2518595670003},"stage":"exp_awarded"
```

`raw/screenshots/prep screen.png` renders the rule to the player in the same session:
`Exp Gaining Factions: ["blue", "green"]`. Red is not in the list; red gained EXP anyway.

**Root cause.** `CombatResolver.gd:1492-1495`:

```gdscript
if attacker.is_inside_tree() and atk_exp > 0 and not attacker_died:
    attacker.add_exp(atk_exp)
if defender.is_inside_tree() and def_exp > 0 and not defender_died:
    defender.add_exp(def_exp)
```

Neither call consults the rule. `Unit.add_exp()` (`scripts/units/Unit.gd:646-671`) then
levels any unit whose EXP crosses 100, and `Unit.level_up()` already knows about factions —
`_resolve_growth_rates()` (`:911-922`) branches on `team != "blue"` to pick the enemy growth
table. So the engine has a faction-aware level-up path being driven by a faction-blind EXP
path.

`grep -rn exp_gaining_factions scripts/` returns `CampaignRules.gd:33` (the declaration),
`SaveData.gd`, `GameState.gd` (serialization both ways) and two test files. **No consumer.**

**Recommended fix.** Gate the award at the single place both branches pass through — the
`add_exp` calls in `CombatResolver` — reading
`GameState.campaign_rules.exp_gaining_factions` and matching on `unit.team`. Do not gate
inside `Unit.add_exp()`: staff use, and any later non-combat EXP source, should go through
the same rule, so the check belongs beside the rule lookup rather than in the mutator.
Add a `test_combat` case asserting a red defender receives nothing under the default rules,
and a second asserting it *does* when an author adds `"red"` — the rule is authored data,
not a constant.

**Adjacent, do not conflate.** "Level up screen also not seen despite levels gained" is
consistent with this same defect rather than a second one: `LevelUpScreen._on_unit_leveled_up()`
(`scripts/ui/LevelUpScreen.gd:65-69`) deliberately returns for any unit whose `team != "blue"`.
If the levels the tester saw were red ones, the screen behaved correctly. Re-check after
`V070-04` lands before opening a separate row.

---

## V070-05 — Blocker — An invalid pack is refused correctly and then fails silently

**Disposition: Fix now.** Small, and it is the exit condition of a display-gated checklist
item that currently cannot be satisfied.

**Evidence.** Checklist §5: *"invalid campaign loads and can be selected, but when you click
start nothing happens."* The checklist required a message naming the map and the off-grid
tile. The log has the message — eighteen times, into `push_error`:

```
ERROR: DataManager: map 'campaign-pack:map_001' enemy placement tile (99, 99) is outside the grid
   [1] select_tier2_campaign_source (res://scripts/autoloads/DataManager.gd:275)
   [2] _activate_run_source (res://scripts/ui/NewGameScreen.gd:353)
   [3] _on_start (res://scripts/ui/NewGameScreen.gd:154)
```

**Root cause.** The validator is right and the plumbing is right: activation fails closed,
the previously active pack survives, and `DataManager` retains the reason in
`_activation_errors`, exposed by `content_status()["errors"]`
(`scripts/autoloads/DataManager.gd:274, 354-361`). `NewGameScreen._on_start()`
(`scripts/ui/NewGameScreen.gd:154-156`) then does:

```gdscript
if not _activate_run_source(run):
    return
```

— a bare early return. The screen already owns a `_status_feedback: Label` and already uses
it for five other failure messages (`:290-335`); the activation path is the one that does
not.

**Recommended fix.** On a false return, read `content_status()["errors"]` and set
`_status_feedback.text`, matching the existing `"Import failed: %s"` phrasing. Roughly four
lines. Cap the rendered list (the same error repeated per map entry is what produced
eighteen copies) and log the full set.

---

## V070-06 — Blocker — The Escape guard never engaged, and cannot say why

**Disposition: Fix now**, and it re-opens the round's central row rather than closing it.

**Evidence.** Checklist §4: *"The opening the file menu starts with the focus on the dialog
box and typing 'zxwasd' inserts those characters at the beginning of the box. the first
`escape` click still closes the entire menu and moves it too the new game menu."*
Both logs: **zero** `file_dialog_escape_owned` records, so `escape_consumed_by` is absent
from the return.

**What the evidence establishes.** `FileDialogInputGuard._handle_physical_escape()`
(`scripts/ui/FileDialogInputGuard.gd:104-129`) records the stage and emits telemetry
*before* it acts, so an absent record means the guard returned `false` at every one of its
four stages, on every Escape, for the whole session. Its first guard clause is
`not _filename_edit_active` (`:106`) — so the flag was false when Escape was pressed. The
`zxwasd` insertion proves the `LineEdit` had keyboard focus at that moment; the returned
keyboard screenshot proves the grid presenter opened at some point. Focus and the flag
disagreed.

**What the evidence cannot establish, and why that is the finding.** `_filename_edit_active`
is set only from the `focus_entered` **signal** (`:29, 154-161`) and is cleared from four
places (`:167, 178, 183, 187`). Whether the failure is a missed initial `focus_entered` on a
reused dialog Window, a `TextEntryService.begin()` returning false, or a session-ended
callback clearing it under the player is **not decidable from this return**, because the one
mechanism built to decide it — `_observe(stage)` at all four stages — routes to
`TextEntrySession.observe()` (`scripts/ui/text_entry/TextEntrySession.gd:79-80`), which
emits an in-memory signal and writes nothing anywhere.

That is the defect to fix first. Four stages of instrumentation were added specifically so
the Windows pass could keep the winning stage and delete the other three on evidence; they
produce no evidence.

**Recommended fix, in order.**

1. **Make the guard observable.** Record telemetry on every physical Escape *including the
   no-op path*, carrying `stage`, `_filename_edit_active`, the focus owner's path, and
   whether a text-entry session is active. One record per Escape per stage. Without this,
   the next Windows round returns the same silence.
2. **Stop trusting the signal for state.** Resolve edit-active from observable truth at the
   moment Escape arrives — `get_line_edit().has_focus()` plus the service's session state —
   rather than from a boolean assembled by five call sites. Keep `focus_entered` as the
   trigger for *opening* the presenter; do not let it be the authority for *ownership*.
3. **Then** re-run §4 and delete the redundant stages on the returned value.

**The second symptom is a separate bug in the same press.** "Moves it to the new game menu"
means the Escape closed the dialog *and* was consumed again by the screen underneath. One
press, two consumers. Whatever fix lands must mark the event handled at the stage that
wins, and §4 must be re-run with that explicitly checked.

**Consequence for the schedule.** This row does not close, so its claim on
`SettingsManager.gd`, `SettingsScreen.gd` and `SettingsScreen.tscn` does not release, and
the three pieces of work queued behind it stay queued. See the return record.

---

## V070-07 — Medium — Save-slot budgets are scoped by campaign id, so two packs share them

**Disposition: Fold in** to `IMPL-SAVE-PACKAGE-RECOVERY-PROVENANCE-2026-08-02` and
`MANIFEST-IDENTITY-SAVES-PACKS-2026-07-26`. Both already rework save identity and both name
`SaveManager.gd`; a spot patch to the scope key would be rewritten by either.

**Evidence.** Checklist §5: *"the internal pack was saying I was out of save slots the first
time I tried to save it after having made 3 saves on the public pack. They should be
separated enough that they shouldn't be able to know how many saves I have on a different
pack."* And §5a: *"Save slots seem to be getting shared between packs which should not be
able to happen."* The Prep screen screenshot shows the cap: `"count": 3, … "Campaign Save"`.

**Root cause.** `SaveManager.manual_slot_budget()`
(`scripts/autoloads/SaveManager.gd:411-430`) counts rows whose
`header.campaign_id == resolved_scope`, and `_active_campaign_scope()` (`:442-447`) returns
`CampaignManager.active_campaign_id` alone. The package is not part of the key.

The two packs ship 70 of 71 documents in common **by design** — identical content ids under
different package ids — and the logs confirm both run the same campaign id:

```
"campaign_id":"proving_grounds","package_id":"prometheus-proving-grounds"
"campaign_id":"proving_grounds","package_id":"prometheus-proving-grounds-internal-fe"
```

So the scope collides exactly as the architecture says it should be allowed to. The comment
at `:405` — *"scoped per-campaign so a save in one campaign never blocks saving in another
(V053-04)"* — is correct about its intent and wrong about its key.

**Requirement to attach to those rows.** Save scope is `(package_id, campaign_id)`, not
`campaign_id`. `IMPL-SAVE-PACKAGE-RECOVERY-PROVENANCE` is already going to snapshot
`package_id` into the save record, which is precisely the field the budget needs; this is one
extra clause on a row that is already opening the file, not new work.

---

## V070-08 — Medium — HUD layout editor: toolbar overflows, panels strand on resize

**Disposition: Fold in** to `DISCUSS-RESPONSIVE-DISPLAY-LAYERS-2026-08-02` (which owns "HUD
anchor/persistence migration, responsive modal bounds, safe areas") and then to the map-HUD
conversion, which the redesign sequences **last** precisely because it interacts with the
control region. Three of the four symptoms are the anchor model this discussion exists to
settle; fixing them now means fixing them twice.

**Evidence.** Checklist §2: *"the edit hud controls cover both the phase count and phase
indicator and the controls leak off screen at high viewport and the unit info page is not
clamped very close to the bottom left corner. and the hud panels dont stay clamped during
the edit screen so a resize can strand them unless edit mode is exited and restarted."*

`raw/screenshots/edit hud.png` confirms three of the four directly: the toolbar is
`PRESET_TOP_WIDE` with unwrapped children, so `Done` is clipped at the right edge; the
toolbar overlaps the `objective` panel at top-left; and `unit_info` sits at mid-left while
its attachment reads `Viewport: Bottom Left`.
`raw/screenshots/changing resolution after adjusting hud layout.png` confirms the fourth —
after the window shrinks, `unit_info` and `terrain_corner` are gone from view entirely.

**Root cause of the stranding, specifically.** `HUD._queue_layout_reflow()` is connected to
`get_viewport().size_changed` (`scripts/ui/HUD.gd:143`), and `_reflow_layout()` (`:375-378`)
re-applies only `_active_layout`. `HudLayoutEditor` drives panels through
`_hud.set_panel_layout()` (`scripts/ui/HudLayoutEditor.gd:264, 274`) and keeps the pre-edit
layout in `_start_layout` for revert (`:372`); the in-progress edit is not what `_reflow_layout`
re-clamps. So a resize mid-edit re-applies a layout that is not the one on screen, and the
dragged panels keep stale absolute positions.

**The one piece worth doing now, separately.** The toolbar clipping (`Done` unreachable) is
not an anchor-model question — it is an editor that cannot be exited at some window sizes.
If the discussion row does not land soon, wrap the toolbar into a `HFlowContainer` as an
isolated change; it does not touch panel anchoring and will not be re-litigated.

---

## V070-09 — Medium — The phase banner is hard-coded 1280 px wide

**Disposition: Fix now.** Two properties in a scene file. It is nominally map-HUD territory,
but the redesign converts *layouts*, and this is a literal that will be copied forward if it
is not removed.

**Evidence.** Checklist §2: *"the phase banner does not always go across the entire screen at
2x viewport."*

**Root cause.** `scenes/ui/PhaseBanner.tscn` gives the root `Control` a full-rect preset, then
gives `$Panel` fixed offsets `offset_left = 0.0` / `offset_right = 1280.0`. The script
(`scripts/ui/PhaseBanner.gd:33-38`) correctly computes slide distances from
`get_viewport().get_visible_rect().size.x`, so the animation adapts and the panel does not —
which is why it reads as "sometimes" rather than "always".

**Recommended fix.** Anchor `$Panel` `anchor_left = 0.0`, `anchor_right = 1.0` with zero
offsets and keep the fixed height. The script needs no change.

---

## V070-10 — Medium — The Prep rules summary renders raw JSON at unbounded height

**Disposition: Fold in** to `PREP-V1-S01` (Prep shell), with one exception below. The tester
said it directly: *"we shouldn't put too much effort in as the prep screen is getting a
makeover anyway."*

**Evidence.** Checklist §5 free text, and `raw/screenshots/prep screen.png`, which shows the
summary consuming eight wrapped lines of literal JSON —
`Autosave Rules: [{ "rule_id": "campaign_progress", "trigger": "battle_end", … }]` — and
leaving three unit rows visible in the scroll below it.

**Root cause.** `PrepScreen._refresh_rules_summary()` (`scripts/ui/PrepScreen.gd:93-106`)
joins every rule row into one string with `str(row.get("value"))`. Scalars render fine;
`Dictionary` and `Array` values stringify as GDScript literals. The `Label` is a sibling
*above* the `Scroll` in the VBox, so it takes its natural height first and the unit list gets
what is left — which at high content scale is nothing.

**Requirement to attach to `PREP-V1-S01`.** Structured rule values need a player-facing
renderer, not `str()`; and the read-only rules block belongs inside the scroll region or in a
collapsed disclosure, never above it competing for height.

**The exception, if the Prep rework does not start soon.** Moving the `Label` inside the
existing `Scroll` is a one-line scene reparent that stops the screen from becoming unusable,
and it will be discarded by the rework without costing anything. Worth taking only if
`PREP-V1-S01` is more than a round away.

---

## V070-11 — Low — ~3,200 `push_error` calls for absent skill ids

**Disposition: Fix now.** Not a layout question, and it degrades every future return.

**Evidence.** 3,199 `DataManager: unknown skill id` errors across eleven ids in one session's
log; `wrath` alone accounts for 802. The backtrace is
`TurnManager._apply_start_of_turn_skills` → `SkillHandler.apply_trigger` →
`DataManager.get_skill` (`scripts/autoloads/DataManager.gd:1635`) — so it fires per unit, per
skill, per trigger, per phase.

**Assessment.** Inert skills are a documented known gap and correctly *not* a bug. The error
**volume** is a separate problem: it makes the log costly to grep, and it trains whoever
triages the next return to skim past `ERROR:` lines. Every finding in this review came out of
that log.

**Recommended fix.** Report each unresolved skill id **once per content activation** —
`DataManager` already holds `_activation_errors`, which is the natural home. An id absent from
the active pack is a content-authoring fact, not a per-frame runtime error.

---

## V070-12 — Low — Viewport Scale has no window-relative ceiling

Folded into `V070-01` above; recorded separately so the tracker row can cite it.

---

## V070-13 — Medium — Menus lay out correctly only after a resize

**Disposition: Fold in** to the eleven screen conversions. Every affected screen is on that
list, and the conversion replaces the layout pass that is misfiring.

**Evidence.** Checklist §2a: *"when opening some menus at nonstandard sizes the background is
centered, but the contents run off the right hand side until the screen is resized with the
menu open."*

**Assessment.** The symptom — correct after a resize, wrong on open — is a first-layout
ordering problem: content is measured before the panel has its final rect, and only the
`size_changed` path re-runs it. `LevelUpScreen` already documents this exact hazard and works
around it (`scripts/ui/LevelUpScreen.gd:55-58`: *"Deferred so the first-show sizing runs after
the (dynamic) stat label has been laid out — otherwise the panel pins a degenerate
narrow/tall frame (V025-05a)"*). The conversions should adopt that deferral as a rule rather
than rediscovering it per screen.

**Requirement to carry into the conversion work.** A converted screen must be correct on
first show without a resize, and each conversion branch's Playwright Compact capture must be
taken **without** an intervening resize — otherwise the capture hides precisely this defect.

---

## Reported, no action

| Report | Assessment |
|---|---|
| §2a *"settles once, but the boundary where it changes does not seem to be consistent between resizings"* | **Working as designed.** `ResponsiveLayout` applies 24 logical px of hysteresis, so the Compact→Medium boundary is deliberately not the Medium→Compact boundary. The tester confirmed the part that mattered — it settles once, and does not flicker. No change; the redesign doc should say so where a tester can read it. |
| §5 *"still has the preinstaled packless proving grounds"* and *"switching packs … no change noticed"* | **Already scheduled.** `NewGameScreen._activate_run_source()` (`:346-352`) falls back to `select_campaign_source("res://data")`, and `data/` still ships. Deleting it is `IMPL-ZERO-CONTENT-EXPORT-GATE` (Slice 4), whose trigger is *"delete project-data compatibility only after playable base pack and pack-aware loads pass"* — which this return just satisfied. Do not patch; unblock the row. |
| Decision 4, terrain variants: *"What was supposed to be seen here? … there is no variation noticed in either stat or visuals"* | **Not answerable from this bundle, and not an engine defect.** The shipped pack authors **no** terrain variants and contains **zero** asset files (`packs/proving_grounds/assets/` is empty; no `variants` key in any of the seven terrain documents). Dark-green forest and brown mountain are the engine's untextured fallback. `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01` stays open; its evidence requirement was unobtainable because the content to exercise it was never authored. |
| §3 *"a gray bar appeared on the left side near the objective screen … it later disappeared on a new campaign"* | **Not reproducible from the evidence.** One screenshot, no log correlate, self-resolved. Recorded in the evidence packet; do not open a row until it recurs with a repro. |
| §2 *"the case of controls mysteriously going dead returned but this time on keyboard … second attempt failed to reproduce"* | **Not reproducible.** The `TRANSITION` records show no lockout in the returned session — `modal_acquire` and `modal_release` are balanced (105 / 105), which is the specific failure this telemetry was built to catch. Keep the telemetry; do not open a row on one unreproduced sighting. |
| §5 *"the mage was not doing as much damage as it used to"* | **Explained by `V070-02`**, not a separate combat change. `CombatResolver.compute_damage()`'s return expression is unchanged since `af56399e`, and `mt` is identical across the legacy resource and both packs. |

## What the automated suites could not have caught

Recorded because the answer shapes where test effort goes next, not as an apology.

- `V070-01`, `V070-08`, `V070-09`, `V070-13` need a real window. The harness pins the logical
  viewport at 1280×720.
- `V070-02` and `V070-04` are reachable headless **today** and were not caught. Both are the
  same shape: a value the engine reads exists and is wrong, while every test asserts the
  value round-trips rather than that anything acts on it. Two cheap suite additions close the
  class — a fixture pack asserting a magic weapon damages RES, and a combat case asserting a
  faction outside `exp_gaining_factions` receives none.
- `V070-03` had a suite covering the *new* mode and none covering the default one.
- `V070-06` is the instrumentation gap itself.
