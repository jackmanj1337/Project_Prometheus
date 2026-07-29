---
Type: code-review
Status: Findings recorded
Last verified: 2026-07-22
Build reviewed: v0.5.4 / 305b230
---

# v0.5.4 Playtest Root-Cause Review

## Scope and release recommendation

Reviewed the returned checklist, `godot.log`, and original HUD-editor screenshot
under `AGENT/v0.5.4/`. Source was traced at the baked build commit `305b230` and
the current branch tip (the relevant implementations are unchanged). This review
classifies unchecked checklist rows as **unknown**, not passes or failures.

**Recommendation: do not promote v0.5.4 yet.** The v0.5.3 critical repair set
passed its live checks, but the return discovered one high-impact controller
access defect spanning Prep/Results/Defeat, one reproducible Rewind reopen defect,
and one HUD-editor interaction defect. The log contains no crash, parser, restore,
package-validation, or transaction failure. Its seven warnings all come from one
HUD toolbar sizing mistake described below.

## Confirmed outcomes

- A1-A4 passed: resumed campaign results, resumed-map Retry, fresh-map healing,
  and the per-campaign save cap/Replace behavior are accepted.
- A5-A6 passed the requested input-blocking and toolbar-button checks, but the
  screenshot/comment exposed the separate phase-marker overlap defect below.
- B2 and B3 passed their primary functional checks. B2 additionally exposed a
  reopen focus failure and missing held-input/lookahead behavior.
- Controller basics and modal input isolation passed. Prep access, held repeat,
  selector cycling, and hotplug remain failed or unknown as detailed below.
- A7, B4, B5, FileDialog printable bindings, and the final clean-log declarations
  were left blank. The returned log independently confirms populated build/runtime
  blocks, context records, and controller startup detection, but it cannot replace
  the unrun behavior checks (especially hotplug and connected-campaign benefits).

## Findings

### [High] V054-RC-01 — Prep, Results, and Defeat do not implement the shared controller/repeat contract

**Reported behavior**

The Xbox controller could not access Prep. Defeat and victory screens accepted
single navigation input but did not repeat while held, and selectors did not
cycle. This is release-blocking for controller accessibility because Prep is a
mandatory campaign transition.

**Root cause**

`PrepScreen` extends bare `Control`. `_ready()` builds dynamic `CheckButton`, Up,
and Down controls but never assigns initial focus, listens for an input-mode
change, or installs a repeat policy (`scripts/ui/PrepScreen.gd:1,22-31,127-160`).
A mouse click can establish focus; a controller arriving at an unfocused screen
cannot.

`MapResultsScreen` and `GameOverScreen` also extend bare `Control`. Each grabs one
button when shown (`MapResultsScreen.gd:70-80`, `GameOverScreen.gd:124-128`), so
single Godot focus events work, but their `_unhandled_input()` functions only
consume input (`MapResultsScreen.gd:245-247`, `GameOverScreen.gd:158-164`). They
do not poll `MenuRepeatPolicy`, wrap the focus list, or apply focus lookahead.

The repository already has the intended implementation in `ModalScreen.gd`: it
handles gamepad-mode focus acquisition, neutral-latched held repeat, wrapping,
focus containment, and scroll lookahead. These three screens predate or bypass
that shared base, so this is contract drift rather than an input-map problem.

**Recommended solution**

Extract the focus/repeat behavior from `ModalScreen` into a reusable component or
base usable by both hide/show overlays and scene-root screens. Adopt it in Prep,
Results, and Defeat; do not paste three new polling loops. Prep should explicitly
focus the first enabled unit toggle (falling back to Save/Begin), rebuild rows
without losing the logical `{unit_id, control-role}` focus, wrap across row
controls/actions, and expose its `ScrollContainer` for lookahead. Results/Defeat
should use the same repeat policy and wrap only visible, enabled actions.

Add dispatched-input tests with an Xbox-equivalent mapping: enter Prep with no
mouse focus, navigate/toggle/reorder/begin; hold down through Defeat; navigate a
branch successor on Results; switch mouse→pad while each screen is visible.

**Difficulty:** medium, about 1-2 focused development days. The policy exists;
the work is safely reusing it and pinning dynamic-row focus behavior.

### [High] V054-RC-02 — Rewind reopen focuses a button already queued for deletion

**Reported behavior**

Rewind is controller/keyboard accessible the first time. After closing and
reopening it, neither controller nor keypad can access it until the map reloads.

**Confirmed root cause**

`RewindSelector.open()` calls `queue_free()` on old choice buttons, immediately
adds replacements, then focuses `_choices.get_child(0)`
(`scripts/ui/RewindSelector.gd:16-30`). `queue_free()` is deferred until the end
of the frame, so on a same-frame reopen child zero is still an old button. Focus
is placed on that doomed control and disappears when it is freed. The replacement
buttons never receive focus. This precisely explains why a full scene reload
repairs the symptom.

The related Load Game rebuild avoids this exact ordering issue by removing each
old child from its parent before adding replacements (`LoadGameScreen.gd:71-81`).

**Recommended solution**

Remove old children from `_choices` before queuing them for deletion, keep an
explicit reference to the first newly-created enabled button, and defer
`grab_focus()` until after visibility/layout settles. Restore focus to the
invoking Map Menu/Defeat Rewind button on Cancel. Add an open→cancel→open
dispatched-input regression test; current Rewind tests exercise data selection,
not focus lifetime.

**Difficulty:** small, a few hours including tests.

### [Medium] V054-RC-03 — Rewind lacks the shared held-repeat and focus-lookahead behavior

**Reported behavior**

The seven-row list scrolls and all rows are reachable, but held navigation does
not repeat and the focused row sits at the viewport edge without preview space.

**Root cause**

`RewindSelector` relies only on Godot's default focus navigation and sets
`ScrollContainer.follow_focus = true` (`RewindSelector.tscn:40-46`). It does not
use `MenuRepeatPolicy` or the three-row lookahead implemented by
`ModalScreen._apply_focus_lookahead()`. `follow_focus` guarantees visibility,
not context beyond the focused item.

**Recommended solution**

Make the reusable focus controller from V054-RC-01 usable by embedded selectors.
Point it at `Panel/VBox/Scroll`, use the established neutral/repeat timings, and
apply capped lookahead after each step. This should land with RC-02 so Rewind has
one coherent input fix rather than two competing navigation mechanisms.

**Difficulty:** small-to-medium, roughly half a day once RC-01's shared seam exists.

### [Medium] V054-RC-04 — The HUD editor's toolbar intentionally makes panels in its top band unselectable

**Evidence**

The screenshot shows the red `turn_label` frame underneath the full-width top
toolbar. The tester reports that the phase marker is locked under the controls
and cannot be interacted with.

**Root cause**

The editor builds drag handles first, then adds a full-width, 48-pixel
`MOUSE_FILTER_STOP` strip above them (`HudLayoutEditor.gd:36-39,75-81,93-102`).
That was added so overlapping frames cannot eat toolbar clicks, but it makes the
inverse interaction impossible: any panel whose editable area falls under the
strip cannot receive a click or begin a drag. The phase label is authored at the
top of the HUD, so it reliably hits this conflict.

The same toolbar code also sets `size.y` after applying opposing top-wide
anchors (`HudLayoutEditor.gd:99-101`). Godot warns that the size will be
overridden. All seven warnings in the returned log point to this line; they are
not gameplay failures but are a confirmed construction error.

**Recommended solution**

Replace the full-width blocking strip with a toolbar container whose mouse
footprint is only its actual controls, and put toolbar buttons above handles by
z-order. When a handle overlaps an actual toolbar control, permit selecting it
from its visible non-overlapped area and dragging it out; additionally offer a
keyboard/controller panel cycle so no panel can become mouse-inaccessible.
Constrain panel clamping against an explicit editor safe area if the product
decision is that saved panels may not live beneath controls. Use offsets or a
fixed-height container—not `size.y` plus opposing anchors—to remove the warning.

Do not simply lower all handles below 48 pixels: that would silently rewrite the
player's HUD layout and prevent a legitimate top-edge phase marker.

**Difficulty:** small-to-medium, about half a day plus a Windows visual pass.

### [Feature] V054-FR-01 — Player-chosen save replacement and campaign-grouped Load Game

**Request**

Allow multiple saves at the same checkpoint/rule set, let a player choose which
old record to overwrite at a save opportunity, and group/sort Load Game by
campaign while the larger menu/data-engine redesign is pending.

**Current constraint**

Prep derives one fixed label from the node (`"<chapter> — Prep"`) and treats any
matching label as the replacement target (`PrepScreen.gd:231-266`). Load Game
renders one newest-first flat list (`LoadGameScreen.gd:10-16,71-82`) even though
each mirrored header already carries `campaign_id`, node, origin, and rule data.
Therefore two runs at the same chapter collide by presentation label even though
the slot storage itself supports distinct ids.

**Recommended solution**

Keep save storage policy in `SaveManager`, but add a save-opportunity dialog that
shows the current campaign's three manual slots: select an existing row to
replace or an empty row to create, with an optional player label. Identity must
be `slot_id`, never display label. In Load Game, build stable campaign groups
from source-qualified identity `{package_id, package_version, campaign_id}` and
sort groups by display name while retaining newest-first order inside each
group. Put autosave/completed records in labeled subsections so they are not
mistaken for manual slots. This is compatible with the future campaign-owned
menu design and does not require separating engine/data first.

**Difficulty:** medium, 2-3 days including save-index compatibility and UI tests.

### [Feature/design] V054-FR-02 — Strategic roster screen and map-position deployment

**Request**

Replace the current classic-mode/death flow with a separate roster menu and a
map-based deployment screen where the cursor selects units and trades positions.

**Assessment and recommended architecture**

This is not a localized fix. Prep currently expresses deployment as a pure
`unit_id -> start_tile` plan and a linear roster-order UI. Preserve that
`DeploymentPlan` contract: build a new map preview/editor as another author of
the same plan rather than moving deployment state into scene nodes. A separate
roster/activity screen should edit party-level choices; the map editor should
only assign eligible units to authored start tiles and swap occupants. This
keeps save/retry validation and data-authored deployment constraints intact.

Implement in slices: (1) noninteractive map preview from `BattleMapDef`, (2)
cursor + occupied/empty start-tile selection and swap, (3) roster drawer/bench,
(4) controller/touch/accessibility polish. Campaign rules determine casualty
eligibility before the UI receives its roster; the screen must not hardcode
"classic mode" branches.

**Difficulty:** large, approximately 1-2 weeks for a tested first version. Track
as a feature on `agent/integration`, not as v0.5.4 release hardening.

### [Feature/design] V054-FR-03 — Victory Retry, Quit, and Manual Save

**Request**

Offer Retry, Quit, and Manual Save on Results when campaign rules permit them.

**Risk and recommended semantics**

Results deliberately leaves campaign position uncommitted until Continue. That
is the right transaction boundary and must remain so. `Retry` may discard the
pending result and restore ledger round zero, matching Defeat. `Quit` is
ambiguous: "abandon this run" and "return now, continue later" are different
actions and must not share a label. A manual save of the uncommitted victory is
dangerous because loading it could replay rewards or lose the win.

Recommended UI:

- `Retry Battle`: only when the rule/policy registry permits it; clear pending
  result, restore round zero, and route campaign retries through Prep.
- `Save & Return`: first commit the result and successor transaction, write the
  normal between-map slot, then return to menu. On branching results, require a
  successor choice first.
- `Abandon Run`: destructive confirmation, explicitly ends the campaign.

Expose these as campaign-authored result-action policies/open registry entries,
not a closed campaign-id switch. Reuse the save selector from FR-01.

**Difficulty:** medium-to-large, 3-5 days because transaction/idempotency tests
are more important than the buttons.

## Additional evidence and unknowns

- The log has complete build/runtime blocks and `PLAYTEST CONTEXT` records for
  shipped and package campaigns. Startup controller detection names an XInput
  controller. Hotplug disconnect/connect was not demonstrated.
- Repeated Continue sequences show one `campaign_restored`, followed by
  `campaign_restaged`; this supports V053-08. Several launches include a second
  restore/restage sequence because the combined log spans many app sessions;
  timestamps/action markers are insufficient to prove whether every sequence
  corresponds to exactly one user Continue.
- There is no logged crash or error. The seven HUD toolbar warnings should still
  be fixed because the checklist explicitly asked for a clean post-stamp log.
- B5 connected-campaign benefit and FileDialog X/Z behavior remain unvalidated;
  do not infer acceptance from unrelated green rows.

## Recommended implementation order

1. Fix Prep/Results/Defeat focus and held repeat (RC-01); Prep is the controller blocker.
2. Fix Rewind stale-focus lifetime and adopt repeat/lookahead (RC-02/RC-03).
3. Fix HUD toolbar hit-testing and anchor warning (RC-04).
4. Run focused automated dispatched-input tests and the full suite.
5. Cut a Windows verification build covering controller-first Prep, held/cyclic
   Results/Defeat navigation, Rewind open→close→open, and top-edge phase-marker drag.
6. Schedule FR-01 separately; route FR-02/FR-03 through design review before implementation.

## Tracker comparison and disposition

Reconciled against `coordination/tasks.json` on 2026-07-22:

- **V054-FR-01 folded into `PP-STRATEGIC-DATA-OWNERSHIP`.** That task already
  owned the New/Load → campaign selector, campaign-owned menu space, save/pack
  deduplication, and human-readable labels. It now also owns campaign-grouped
  Load Game sections and player-chosen manual-slot creation/replacement. The
  duplicate `MENU-CAMPAIGN-SUBMENUS-DESIGN` row is closed as folded into it.
- **V054-FR-02 added as `B4-PREP-MAP-DEPLOYMENT-2026-07-22`.** It is a later
  `B4-PREP-DEPLOYMENT` slice using the already-completed `B3-PHB` registry
  foundation, not a new competing prep architecture.
- **V054-FR-03 added as `B4-RESULT-ACTIONS-2026-07-22`.** Historical design
  already settled that victory Retry drops the pending result and routes campaign
  play through Prep. The wider campaign-authored action policy and transactional
  Save & Return/Abandon behavior were not otherwise tracked.

## Decisions required before fixing RC-01…RC-04

**No owner/product decision is required to begin the four v0.5.4 fixes.** The
recommended defaults follow contracts already present in the repository:

1. RC-01: reuse/extract the existing `ModalScreen` focus-repeat behavior across
   Prep, Results, and Defeat. This is implementation structure, not game design.
2. RC-02: detach old Rewind buttons before deferred deletion, focus a newly
   created button, and restore caller focus on Cancel. The observed behavior has
   only one correct outcome.
3. RC-03: use the established repeat timing, cyclic focus, and capped three-row
   lookahead already used by other modal lists.
4. RC-04: keep the toolbar at the top, limit hit blocking to its actual controls,
   add panel cycling as an accessibility escape hatch, and fix the invalid anchor/
   size combination. This preserves the present visual design without moving or
   rewriting saved HUD panels.

The only scope choice is release management: whether to repair all four in the
next verification build. **Recommendation: yes.** RC-01 and RC-02 are mandatory;
RC-03 shares their input seam, and RC-04 is small, user-visible, and responsible
for every warning in the returned log. Deferring either medium finding would
force another known-defect playtest round for little risk reduction.

Later features do require decisions, but they do not block these fixes:

- `PP-STRATEGIC-DATA-OWNERSHIP`: final campaign-owned menu/data boundary and save
  selector presentation.
- `B4-RESULT-ACTIONS-2026-07-22`: which actions campaigns may enable and the
  explicit confirmation that Save & Return commits before writing a slot.
- Map deployment needs no new policy decision at this stage because it preserves
  the settled `DeploymentPlan` and authored start-tile contracts.
