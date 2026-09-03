---
Role: dated
Type: playtest
Status: Awaiting return - shipped in the v0.7.0 Windows-round bundle
Last verified: 2026-08-06
---

# v0.7.0 Windows round — verification checklist

**A deliberate subset, not a replacement.** The full superset lives in
[`playtest_checklist_v0.7.0.md`](playtest_checklist_v0.7.0.md) and still owns the web,
PWA and mobile-device sections. This round drops those on purpose: they are deferred to
a second pass once the responsive redesign makes portrait worth looking at. Nothing has
been dropped for being tedious — only for needing a phone.

**Why the round was re-cut.** The 2026-08-05 bundle (candidate `36baae04`) was never
run. Since then the web export preset was fixed (`experimentalVK:true` was raising the
platform keyboard over our own grid keyboard on every touch device) and the size-class
seam landed. Rather than have you test a build that was already superseded, this round
is exported from `6cf2c89a`. **Discard the older zip.**

**No screenshot album ships with this round.** Every decision the sheet asks for is
answerable live in the application on your own display, and a Playwright album is
browser evidence in a Windows-only bundle. The album returns with the mobile pass.

**Unreported is not passed.** v0.6.1 shipped to testers and no return was ever recorded
— there is no `AGENT/Docs/playtests/evidence/v0.6.1/` — so everything the v0.6.1
checklist asked for is still unproven and is repeated below rather than assumed.

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
and has to be thrown away.

- [ ] [UNPROVEN] Every executable matches `SHA256SUMS.txt` (`sha256sum -c SHA256SUMS.txt`).
- [ ] [NEW] Startup log BUILD STAMP reads **`version=0.7.0 commit=6cf2c89a`** in EVERY
  executable, and matches `BUILD_INFO.json`. Main Menu shows `v0.7.0`. If it reads
  `36baae04` you are running the superseded bundle — stop and get the right one.
- [ ] [UNPROVEN] The debug executable shows the DEBUG MODE banner and the release executable does
  not. Same source commit, exported `--export-debug` and `--export-release`.

## 2. Windows

Nothing in this section was reported back for v0.6.1.

- [ ] [UNPROVEN] Review centered menus at 1280×720, 1280×800, 1365×768, 1920×1080, 2560×1440 and
  3840×2160. **Note on 1280×720:** this build was authored against it as a design floor.
  That floor was **retired on 2026-08-06** and replaced by a 360×640 size-class model, so
  report what you see — do not read this item as ratifying 1280×720.
- [ ] [UNPROVEN] At 2× menu/content scale, New Game scrolls; Unit Details stacks its regions;
  Results stacks report/actions; no centered frame leaves the safe viewport.
- [ ] [UNPROVEN] **Windows are no bigger than they need to be.** Load Game and Campaign Library
  should be modest centered dialogs, NOT near-fullscreen panels. This is the change most
  likely to look wrong, and the automated containment checks cannot see it — an
  over-large window is still inside the viewport. Feeds decision 1.
- [ ] [UNPROVEN] Non-zero safe-area padding; HUD panels attach and clamp.
- [ ] [UNPROVEN] Contextual action, attack-preview, weapon, item and map menus stay anchored to
  gameplay rather than being forced to screen center.
- [ ] [NEW] **Viewport Scale:** changing the setting re-anchors the map and HUD without
  clipping or drift, and the setting survives a restart. Try both ends of the slider.
  Feeds decision 3.
- [ ] [NEW] **Terrain variants:** tiles introduced by the active pack paint at the correct
  size with correct atlas regions, and visually distinct variants of one terrain still
  behave identically (same movement cost, same defence). Tile sizing and atlas regions
  are exactly what a headless run cannot check. Feeds decision 4.
- [ ] [UNPROVEN] Complete a representative map without a crash or stuck modal.

## 2a. The size-class seam — first look, and the reason this build is newer

The `ResponsiveLayout` seam landed **after** the previous bundle was frozen, so this is
the first build anyone can look at it in. Nothing is waiting on your verdict — the row is
closed — but eleven screen conversions are about to be built on top of it, and a defect
found now is far cheaper than one found underneath eleven screens.

Headless cannot reach any of this: the test harness pins the logical viewport at
1280×720, so **a real window is the only way these run at all**.

- [ ] [NEW] **Unit Details stacks below 1024 logical px.** It used to split side-by-side
  down to 900. The 900–1023 band deliberately moved from side-by-side to stacked, so the
  760px-minimum panel can never be pushed wider than the window. Drag the window narrow
  and confirm the stacked layout is the right call in that band — this is the one part of
  the seam recorded as wanting a human's eye.
- [ ] [NEW] **Dragging across a class boundary settles once.** Drag the window slowly
  through the boundary and back. The layout must re-flow **once when the drag settles**,
  not flicker per frame, and a window parked exactly on the boundary must not oscillate
  between layouts.
- [ ] [NEW] **A class change does not cost you state.** With Unit Details open — a section
  selected, the panel scrolled, More Info showing a target — drag the window across the
  boundary. Selection, scroll position and the open More Info target must all survive.
- [ ] [NEW] Same three checks driven from **Settings → Viewport Scale** instead of the
  window: changing the scale while looking at a screen changes its size class too.

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
  unreported in v0.6.1. Name the pad you used.
- [ ] [REGRESSION] Hot-plug: connect, disconnect and reconnect the pad mid-session; prompts switch
  keyboard↔controller each time. (Telemetry itself PASSED on v0.6.0 evidence — this is
  a regression check on the prompts, not a re-collection.)

## 4. Text entry and FileDialog — the item this round exists for

Run these on the **debug** executable and keep the log. This section closes
`IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`, and that row's claim on
`SettingsManager.gd` and the Settings screen is blocking three other pieces of work.

- [ ] [UNPROVEN] **First Escape ownership.** With the filename field focused in a save/export
  dialog, press Escape **once**. It must move focus to the **file list** — not close the
  whole dialog. This is newly possible: the previous implementation searched for a `Tree`
  and Godot 4's FileDialog has none, so the handoff matched nothing and did nothing.
- [ ] [NEW] **Read back `escape_consumed_by`** from the log and record the value. Escape is
  hooked at four stages; three are probably redundant, and this value is what lets them be
  deleted on evidence rather than guessed. **This is the single most valuable line in the
  return.**
- [ ] [NEW] The on-screen grid keyboard withdraws when you leave the field by click or Tab —
  it must not be left floating over the dialog.
- [ ] [NEW] The space key renders with a visible label, and a key the field rejects renders
  disabled with an explanatory tooltip rather than doing nothing.
- [ ] [UNPROVEN] The typed value is kept when the dialog is confirmed.

## 5. Campaign-pack lifecycle

**Start from a genuinely inactive state** — no pack installed. Uninstall first if one
is. The engine is not supposed to fall back on hidden built-in content, and that is
precisely what this proves.

- [ ] [NEW] With no pack installed, the game starts and says so plainly rather than silently
  offering content.
- [ ] [NEW] Import `campaign-packs/proving_grounds_public.zip` (the archive, not an
  unzipped folder — the importer takes ZIPs only), select it, launch its
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
- [ ] [NEW] `campaign-packs/proving_grounds_invalid.zip` is **refused at activation** with a
  message naming the map and the off-grid tile, the previously active pack is still
  active afterwards, and nothing is left half-activated. (It is broken semantically, not
  syntactically, so it may install and then fail to activate — that ordering is the
  point. See that folder's README for the exact expected message.)

## 5a. What real content proves — the zero-content model's first look

The content families (classes, weapons, rosters, items, maps, terrain, media) were built
one at a time against synthetic fixtures. This is the first bundle where a **real
extracted pack** exercises them on a display, and the pack was authored to hit specific
cases. Each item below names the case it hits, so a failure points somewhere.

- [ ] [NEW] **Both packs installed at once, sharing content ids.** Import
  `proving_grounds_public.zip` **and** `proving_grounds_internal.zip`. They share 70 of their 71
  documents by name and use *identical content ids* — `archer` is `archer` in both — while
  carrying different package ids. **This is legal by design and must not error:** one pack
  is active at a time and a pack is self-contained, so two packs shipping the same content
  id is not a collision. Confirm both install, either can be selected, switching swaps the
  content wholesale, and nothing complains about duplicate ids. A "duplicate id" message
  here is a design violation, not a content problem.
- [ ] [NEW] **The four-faction map really has four factions.** Load
  `map_001_c3_factions`. It authors **blue, green, red and yellow**, and all four must act
  on their own phases. Until 2026-08-01 a Godot trap silently left an authored typed array
  **empty** with no diagnostic, so this map would have fallen back to the blue+red default
  and looked merely boring rather than broken. It was the fifth instance of that trap.
- [ ] [NEW] **Each objective type states its own condition.** The pack ships five distinct
  victory conditions across its maps — `rout` (map_001), `seize` (map_002), `defeat_boss`
  (map_003), `escape` (map_004), `survive` (map_005) — and `protect` / `turn_limit` defeat
  conditions. Open each map and confirm the stated objective matches, and let one
  `turn_limit` map run out to confirm the loss actually fires. These resolve through an
  open registry, so a missing type fails quietly rather than loudly.
- [ ] [NEW] **Promotion.** `map_950_promotion_validation` is purpose-built: six level-9
  unpromoted units, a level-19 mercenary one level short, several promoted units and a
  level-14 hero at its skill cap. Level the mercenary once and confirm the promotion offer
  appears, names the right destination class, and applies its gains. This is the first look
  at the advancement edge/route seam with real content rather than fixtures.
- [ ] [NEW] **Terrain numbers still behave.** Terrain used to live in **six** engine tables
  that each owned part of the same vocabulary, including two move-cost tables a code
  comment asked editors to hand-sync. They were consolidated into one authority on
  2026-08-01. A test pins the exact numbers, but confirm in play: move cost differs by
  terrain *and* by movement type, a flier crosses ground terrain at flat cost, a wall
  blocks the flier too, forts heal, and terrain defence/dodge bonuses appear in the attack
  preview.

### Known gaps — do NOT report these as bugs

The extraction reports them as absent, and a return slot spent on them is wasted:

- **Skills do nothing.** Units carry skill ids that nothing in the pack resolves — there is
  no registered skill kind yet. Expect them to be inert.
- **No pair-up.** Same reason.
- **No fog on any map.** The map document schema admits no `fog_enabled`, so a fog chapter
  extracts as a clear map. Fog draws nothing in this build regardless.
- **Public numbers are untuned by construction.** The public pack's stats are generated to
  be original, not balanced; its manifest says `authoring_status: draft`. Report *broken*,
  not *unbalanced*.

## 6. Save recovery

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

## 7. Carry-forward still open

- [ ] [REGRESSION] **Filesystem check the logs cannot answer:** confirm NO v0.3.0 resize-trace file
  exists in the user-data directory. The log half already passed (no `[V030 TRACE]`
  lines in any of the seven v0.6.0 logs).

The other carry-forward item — FileDialog cancel/Escape input ownership — is section 4
of this checklist rather than a line here, because it is what the round is for.

Closed on v0.6.0 evidence — **do not re-run**: controller hot-plug telemetry
collection, logging/telemetry presence, package save validation (ordinary-load half),
and Retry-after-Save first verification.

## 8. Return requirements

A verbal "it worked" cannot satisfy sections 1, 3 or 4.

- [ ] [UNPROVEN] **The whole Godot log directory is attached**, from every executable used.
- [ ] [UNPROVEN] Screenshots for anything marked FAIL, plus the Windows resolution sweep.
- [ ] [UNPROVEN] Which executable produced each result (debug vs release), and the BUILD STAMP line
  copied from its log.
- [ ] [NEW] The `escape_consumed_by` value from §4, copied out of the log.

Returning the logs is not enough on its own — the v0.6.0 logs came back complete and
then sat uninspected while the items they answered were still recorded as outstanding.
Whoever triages this return greps the logs and records the result.

## Not in this round

Deferred to the mobile pass, with their tracker rows: web and PWA (`IOS-DEVICE-PWA-VERIFICATION-2026-08-03`),
mobile device and touch (`MOBILE-WEB-UX-GAPS-2026-08-03`, `DEDICATED-TOUCH-CONTROLS-2026-08-03`).
Fog of war is in neither round: it computes and draws nothing, so there is nothing to look at.

## Result

- Tester / host:
- Date:
- PASS / FAIL:
- Notes and screenshot references:
