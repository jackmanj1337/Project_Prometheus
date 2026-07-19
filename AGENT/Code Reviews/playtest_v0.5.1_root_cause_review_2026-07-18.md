---
Type: code-review
Status: Findings recorded
Last verified: 2026-07-18
Build reviewed: v0.5.1 / d96d035
---

# v0.5.1 Playtest Root-Cause Review

## Review scope and release recommendation

Reviewed every returned file under `AGENT/Incoming/v0.5.1/`: the completed
handbook, five Godot logs, and nine original-resolution screenshots. Source was
reviewed at the tagged build commit `d96d035` (an ancestor of this checkout).
Focused runtime reproductions used Godot 4.6.3, matching the returned build. The
full 103-suite automated test run passed on 2026-07-18; the confirmed live
failures therefore identify missing integration assertions rather than a
pre-existing red test suite.

**Recommendation: do not promote v0.5.1.** The return confirms two independent
release-blocking state-machine defects and one global content-source defect that
causes several high-impact symptoms. Sections 7–9 of the handbook were materially
blocked, so carry-forward/save compatibility remains unvalidated.

## Owner decisions for v0.5.2

Settled 2026-07-19:

1. **Campaign selection is a gateway, not the final map picker.** Eventually a
   selected campaign opens campaign-owned menus. Campaign authors declare in
   data whether players may choose a starting map/node or must follow authored
   progression order. The engine provides the open policy/registry primitives;
   it must not hardcode individual campaign flows. The v0.5.2 source-ownership
   repair must preserve this direction even if the richer campaign menu itself
   is delivered later.
2. **Casualty semantics accepted.** Permanent deaths report `Unit Name — Fallen`;
   casual-mode removals report `Unit Name — Retreated`; escape is not a casualty.
   The result record survives scene-node removal.
3. **Two-Map Skirmish becomes a playable full-history fixture.** Alden, Mira,
   and all raiders receive authored weapons/proficiencies; Chapter 1 receives a
   deserialized rout objective and must advance naturally. The fixture retains
   the full activation history of the current map (`undo_activations = -1`) as a
   stress/acceptance test. Retention and spending remain separate: retain the
   full map history while keeping four uses per map and `full_history` pricing
   at one charge per selected boundary.
4. **Printable bindings stand down for text entry.** When a `LineEdit` or other
   text editor owns focus, printable gameplay confirm/cancel bindings must insert
   text normally instead of acting as menu actions. This is a general text-input
   rule, not a `FileDialog`-only exception.

## Findings

### [Critical] V051-RC-01 — A package activation replaces global content while the UI and active run still reference other sources

**Evidence**

- After importing Two-Map Skirmish, the screenshots show a selector containing
  both shipped campaigns/maps and installed-package entries.
- After suspend, the selector contains only package entries and duplicates.
- The returned log repeatedly reports shipped save inventory ids (`iron_lance`,
  `iron_sword`, `iron_bow`, `fire`, `heal_staff`, `vulnerary`) as missing.
- The same log repeatedly reports `cannot start unknown campaign
  'single_map__skirmish_01'`.
- Shipped Proving Grounds and single-map victories display `Finish Campaign`,
  then `Save: could not validate the next battle`.

**Root cause**

`DataManager.select_tier2_campaign_source()` clears every live catalogue and
replaces it with the selected package (`scripts/autoloads/DataManager.gd:138-155`).
Conversely, selecting shipped content clears the package catalogue
(`DataManager.gd:122-132`). `NewGameScreen._refresh_run_options()` first reads
whatever catalogue happens to be active, then appends every installed campaign
(`scripts/ui/NewGameScreen.gd:211-274`). The resulting rows therefore do not all
belong to the same source snapshot.

Source activation happens only when Start is pressed
(`NewGameScreen.gd:372-392`). This leaves three invalid windows:

1. opening/refreshing New Game while a package is active omits shipped rows and
   may append the same installed rows a second time;
2. shipped synthetic `single_map__*` rows captured from an earlier refresh can
   be selected while the package catalogue is active, so `CampaignManager`
   cannot resolve their ids;
3. changing the global source while another campaign/save still exists makes
   `CampaignManager.get_active_campaign()`, successor validation, and save
   reference validation read the wrong catalogue.

The results UI amplifies the failure: an empty successor list is rendered as
`Finish Campaign` (`scripts/ui/MapResultsScreen.gd:125-128`) even when lookup
failed, while Continue later detects that the nonterminal successor cannot be
prepared (`MapResultsScreen.gd:166-172`). The label is therefore false, not proof
that the progression graph marked the map terminal.

**Suggested fix**

- Make catalogue lookup source-qualified. Prefer immutable per-source catalogue
  objects keyed by `{package_id, package_version}` plus the shipped source, with
  an active run retaining its own source identity. Do not let discovery mutate
  the running campaign's catalogue.
- Build New Game rows from explicit shipped discovery plus installed-package
  summaries. Deduplicate by `{campaign_id, package_id, package_version}`.
- Activate and validate a row's source before `start_campaign`, as one
  transaction; on failure restore the previous source/run.
- Keep campaign source identity in `CampaignManager` (not only save payloads),
  and assert that every active campaign/node lookup uses that identity.
- In `MapResultsScreen`, render `Finish Campaign` only when
  `pending_result.campaign_complete` is true. An empty successor list on a
  nonterminal result must be a disabled error state with the unresolved ids.
- Add an integration test that alternates shipped → package → shipped, opens New
  Game after suspend, loads a shipped save while a package was last active, and
  wins a nonterminal shipped node after package discovery.

### [High] V051-RC-02 — Rewind snapshots taken between AI activations are not marked as resumable AI boundaries

**Evidence**

Selecting the final red activation restored an enemy-phase board, but cursor,
menus, inspection, and zoom were locked. Only terrain-page flipping remained;
the tester had to terminate the process.

**Root cause**

Every transition to `DONE` queues an activation snapshot
(`scripts/core/TurnManager.gd:696-708`). The normal deferred flush captures
`capture_suspend_turn_state()`, but that serializer writes
`controller_boundary = "between_ai_activations"` only while
`_ai_suspend_exit_pending` is true (`TurnManager.gd:189-203`). That flag is set
only by the separate Suspend & Quit transaction (`TurnManager.gd:736-750`), not
by ordinary AI history pushes.

On scene restoration, an AI phase resumes only if the saved boundary has that
exact marker (`TurnManager.gd:159-167`). A rewound AI snapshot therefore reloads
with enemy ownership and locked player input, but no AI coroutine is restarted.

**Suggested fix**

- Give activation-history capture an explicit boundary argument. An AI action
  snapshot flushed after the action unwinds should serialize
  `between_ai_activations` regardless of whether the user requested suspend.
- Keep the suspend-request flag separate from the semantic controller boundary;
  the former decides whether to write/quit, the latter decides how any restored
  snapshot resumes.
- Add an end-to-end test that completes at least two AI actions, rewinds to each
  boundary, reloads `GameMap`, waits for the controller to resume, and asserts
  the correct faction/phase plus no duplicate action.

### [High] V051-RC-02b — The first rewind incorrectly exhausts every remaining charge

**Evidence**

The tester confirmed this occurred in both Proving Grounds (`per_activation`)
and Two-Map Skirmish (`full_history`): after one successful rewind, the Map Menu
showed no remaining charges and disabled Rewind. This was not limited to an
expensive older-row selection or to the fixture's one-charge cost mode.

**Confirmed root cause**

The option builder and `rewind_to_history()` correctly calculate and stage
`restored_charges = rewind_charges_left - cost`
(`scripts/autoloads/GameState.gd:943-974`). `configure_suspend_resume()` also
correctly installs the staged ledger and charge count (`GameState.gd:366-423`).

The loss occurs on the following scene load. `GameMap._ready()` copies the resume
payload into a local variable, then unconditionally calls
`GameState.reset_map_state()` (`scripts/core/GameMap.gd:58-68`). That reset clears
the live ledger and explicitly sets `rewind_charges_left = 0`
(`GameState.gd:326-341`). The resume path later restores units, turn state, Pair
Up, RNG, cursor, and threat UI from the local payload, but never restores the
cleared ledger or charge count (`GameMap.gd:349-365`). The first rewind therefore
works until scene replacement, then reloads with zero charges and no history.

The focused `test_rewind.gd` passed 7/7 because it asserts the correct charge
immediately after `configure_suspend_resume()` and never loads the replacement
`GameMap`. `test_suspend_map_runtime.gd` passed 9/9 but does not assert retained
ledger size or charges after scene initialization. This is a concrete
producer/consumer integration-test gap.

**Suggested fix**

- Split `reset_map_state()` into board-transient cleanup and full new-map cleanup,
  or re-install the staged ledger/charges transactionally after board cleanup.
  Do not simply skip all cleanup on resume: stale unit nodes still must be
  discarded before the serialized board is spawned.
- Keep `begin_map_rewind_budget()` fresh-map-only (it already is guarded by
  `not is_resuming`); preserve the staged ledger and charge count on resume.
- Add integration coverage for two consecutive rewinds in both modes, asserting
  the displayed charge count after each scene reload.

### [High] V051-RC-03 — Results promise casualty/reward/progression summaries that the result producer never supplies

**Evidence**

The screenshots show `Rewards: None reported`, `Casualties: None reported`, and
`Progression: Resolved`. The tester confirmed that a unit was permanently killed
on the first Proving Grounds rout map; that unit was absent from the casualty
row. Progression then failed before the second map could be accessed.

**Root cause**

`MapResultsScreen` reads `result.rewards`, `result.casualties`, and
`result.progression` (`scripts/ui/MapResultsScreen.gd:94-114`).
`CampaignManager._record_result()` creates none of those fields; it records only
campaign/node/victory/successor/completion/winner/standings
(`scripts/autoloads/CampaignManager.gd:513-538`). Repository search found no
later producer for the three displayed fields. Gold appears only because the UI
separately listens for `reward_committed`.

**Suggested fix**

- Define one typed/validated map-result payload and populate it at resolution.
- Capture casualties from the campaign party delta/death disposition records,
  not from surviving scene nodes. Distinguish permanent death, casual retreat,
  and no casualty if the UI intends to report all three.
- Put the committed reward receipt and authored reward ids into the same payload.
- Replace the hardcoded `Resolved` fallback with actual progression text, or
  omit the row until a producer exists.
- Add producer/consumer contract tests; a UI fallback test alone cannot catch a
  missing producer.

### [High] V051-RC-04 — The imported combat fixture is structurally valid but not gameplay-complete

**Evidence**

The imported roster and all six raiders had no weapon or weapon proficiency.
The handbook's known objective-deserialization limitation also prevents natural
Chapter 1 completion. This makes the two-map fixture unsuitable for validating
campaign progression through normal play.

**Root cause**

The package catalogue declares classes, maps, roster, and one item, but no
weapons. Its roster/enemy JSON has no inventory or weapon-experience fields.
`CampaignTier2RuntimeAdapter.Result` has no weapons collection and the adapter
builds only classes/items/rosters/maps/campaigns
(`scripts/resources/CampaignTier2RuntimeAdapter.gd:8-63`). `_build_rosters()` and
`_enemy_placements()` apply scalar properties but do not decode inventory
entries (`CampaignTier2RuntimeAdapter.gd:111-136,206+`). The fixture test asserts
counts only, so an unplayable roster passes.

**Suggested fix**

- Extend the Tier-2 open catalogue/validator/adapter with weapon documents and
  inventory-entry decoding; keep this registry-driven rather than a closed
  weapon switch.
- Validate that a combat-intended unit has at least one usable offensive/healing
  action, unless it explicitly opts into an unarmed/noncombat role.
- Give Alden, Mira, and each raider authored proficiencies and usable weapons.
- Deserialize the already-authored objective-condition registry before using
  this fixture as a two-map progression acceptance test.
- Strengthen `test_two_map_campaign_fixture.gd` to assert usable combat actions
  and a resolvable Chapter 1 victory, not only unit counts.

### [Medium] V051-RC-05 — Mirroring Z/X into Godot's generic UI actions conflicts with filename entry

**Evidence**

The tester confirmed that `x` and `z` produced no visible character or other
noticeable action while naming a file in the in-game export dialog, while WASD
typed normally. The campaign export uses an embedded Godot `FileDialog`
(`scenes/ui/CampaignLibraryScreen.tscn:72-76`).

**Confirmed root cause; mitigation still needs product-level validation**

`SettingsManager` deliberately mirrors the game's confirm/cancel bindings into
global `ui_accept`/`ui_cancel`; defaults are Z and X
(`scripts/autoloads/SettingsManager.gd:1023-1063`). `FileDialog` and its buttons
consume those generic actions, so the filename `LineEdit` does not reliably
receive the printable characters.

A focused Godot 4.6.3 headless reproduction opened a real save-mode `FileDialog`,
focused `FileDialog.get_line_edit()`, and injected printable W, X, and Z key
events with the project's live input mirroring. W changed `wasd` to `wasdW`; X
and Z left the text unchanged and the dialog visible. This exactly reproduces
the Windows report without involving campaign export code. The existing
`test_campaign_library_screen.gd` passed 4/4 because it invokes the
`file_selected` callback directly and never types in the dialog.

**Suggested fix**

- Prefer physical game actions in game-owned menus and avoid globally adding
  printable gameplay keys to Godot's generic text/UI actions. A first diagnostic
  attempt to erase X/Z from `ui_cancel`/`ui_accept` after the dialog was already
  open did not restore typing, so do not ship that narrow workaround without
  lifecycle testing; configure mappings before popup or isolate menu navigation
  from text-edit contexts at the input-routing layer.
- Add a UI test that focuses the export filename field and injects lowercase X
  and Z, asserting the text changes without accepting/cancelling the dialog.

### [Low] V051-RC-06 — Main Menu fit scaling makes the ornament frame unnaturally narrow

**Evidence**

The screenshot at 2560×1440 shows a tall, very narrow ornament around the five
buttons. Settings at 1.0× is readable but also demonstrates that the intended
visual language uses substantially wider controls.

**Root cause**

The authored Main Menu panel is only 300 px wide at the 1280×720 design size
(`scenes/ui/MainMenu.tscn:35-40`). `MainMenu.apply_menu_scale()` fits that aspect
ratio into the available rectangle (`scripts/ui/MainMenu.gd:39-54`); fitting can
scale the panel but cannot improve its authored width-to-height ratio.

**Suggested fix**

Author a larger minimum horizontal size for the panel/buttons (or a theme
constant shared by primary menus), then visually verify at 1280×720, 2560×1440,
maximized ultrawide, and every menu-scale setting. This is visual polish, not the
cause of the blocked campaign tests.

## Rewind retention answer

The returned v0.5.1 fixture overrides only `rewind_cost_mode = full_history` and
keeps four charges; that did **not** imply unbounded retention. For v0.5.2 the
owner has explicitly separated the two controls: Two-Map Skirmish sets
`undo_activations = -1` to retain the full current-map activation history, while
keeping four one-charge rewind uses. The handbook must test both independently:
all committed activation boundaries remain listed, but only four selections may
be spent during the map.

## Clarifications resolved with the tester

1. The first successful rewind disabled Rewind and displayed zero remaining
   charges in both cost modes.
2. A unit was permanently killed on the first Proving Grounds rout map and was
   omitted from the casualty report.
3. In the in-game export filename field, X and Z produced no visible effect;
   ordinary letters including WASD typed normally.
4. On the faction-demo results screen, the first click produced
   `Save: could not validate the next battle`; it did not advance or return to
   the menu.

## Minimum repair/verification order

1. Fix source-qualified catalogue ownership and the false terminal-results UI.
2. Fix rewind charge persistence and AI-boundary rewind capture/resume.
3. Add the result-payload producer and permanent-casualty semantics.
4. Make the imported fixture combat- and objective-complete.
5. Instrument/fix FileDialog X/Z handling; widen the Main Menu frame.
6. Run the full automated suite, then cut a focused Windows build that first
   retests source switching, nonterminal victory, enemy-phase rewind, and a
   shipped save after package activation. Only after those pass should the
   blocked carry-forward and compatibility sections be repeated.
