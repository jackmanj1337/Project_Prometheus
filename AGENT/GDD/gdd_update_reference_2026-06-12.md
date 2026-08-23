---
Role: topic
Topic ID: GDD-GDD-UPDATE-REFERENCE-2026-06-12
---

# GDD Update Reference — Full Review Consolidation (2026-06-12)

> **ARCHIVED (Stage 5.2d, 2026-06-13 / DOC-010).** All dispositions from this
> document have been imported into `decision_record_2026-06-13_june_reference_import.md`
> and applied to GDD_01–GDD_08. This file is retained for provenance; do not use it
> as a live action list. The companion `rng_determinism_design_2026-06-11.md` is in
> `AGENT/Docs/` and active as an implementation plan for `RngService`.

**Purpose:** single working reference for the upcoming GDD update pass.
Consolidates every finding, decision, and action item from the 2026-06 design
review. File under `AGENT/Docs/` alongside its companion document:

> **Companion:** `rng_determinism_design_2026-06-11.md` — the complete RNG /
> rewind / suspend-save / online design contract (decision records RNG-1
> through RNG-4, RngService spec, snapshot contract, test plan, build order).
> This reference does not duplicate it; items below point into it.

**Status markers used throughout:**
- **RATIFIED** — decided by the project owner in this review. Copy into the
  dated-decisions log verbatim.
- **RECOMMENDED** — reviewer proposal with a suggested default. Needs an
  explicit ratify/reject.
- **OPEN** — question with no answer yet.

---

## 1. Ratified Decisions (copy to `AGENT/Docs` decisions log)

**D-A — Public identity (2026-06-12).** All FE-derived names (project title,
classes, items, terminology) are placeholders and will be renamed before any
truly public release. Architecture note: names live in data files, so the
rename is a data pass; repo name, doc terminology, and store identity entrench
over time — schedule the rename decision point no later than the first public
release-candidate milestone.

**D-B — 1.0 definition (2026-06-12).** 1.0 = every offline, non-data-pipeline
feature implemented + one short campaign. Implications:
- M15 Part B (online) is explicitly post-1.0.
- M11 full handbook coverage (53 classes / full weapon & skill rosters) is
  **no longer release-blocking** — only content the short campaign needs is.
  Re-scope M11 into "campaign content" (1.0) and "full coverage" (post-1.0).

**D-C — Rules authority (2026-06-12).** The most recent Awakening corpus
update is authoritative for game rules, except where a dated human decision
overrules it. Implications:
- Rewrite GDD_00 → Documentation Authority: human dated decisions →
  Awakening corpus → current code/tests → GDD_01–08 → roadmap docs →
  Assumptions/Checklist as history. (Corpus moves from rank 6 to rank 2.)
- Reword design pillar 1 ("Rules-faithful"): faithfulness target is the
  Awakening-updated ruleset, not the original handbook.
- B10 (corpus reconciliation) is promoted from doc chore to the task that
  determines live rules. Raise its priority; do during stabilization.

**D-D — Campaign prerequisites (2026-06-12).** Deployment screen, shops, and
a recruit mechanic are prerequisites for campaign mode. Implications:
- Add three dependency edges to GDD_10a §3: campaign milestone ← deployment
  screen; ← shops; ← recruit mechanic.
- Resolves the roster death-spiral question (recruitment replaces losses) and
  the weapon-durability economy inside campaigns (shops).
- Residual: long standalone maps with no shop can still soft-lock on broken
  weapons — see OPEN-5.

**D-E — Reclassing growth (2026-06-12).** Second Seal growth up to stat caps
is sanctioned, not an exploit. Stat caps are the balance lever; do not add
anti-grind guards. Add a note in GDD_03 → Promotion and Reclass so future
work doesn't "fix" reclass farming.

**RNG-1 … RNG-4 (2026-06-11).** Hash-chained context-seeded dice; RNG state
in the snapshot contract; accepted exploits priced by rewind charges;
host-authoritative online. Full text in the companion doc. Chain parameters
ratified in-review: **every committed, non-undoable unit action advances the
dice timeline** (Equip and undone moves never do); **level-up growth rolls
are chained to history** (one event per level, keyed unit+new level);
online determinism is **engine-local only** (host rolls, clients apply).

---

## 2. GDD Edits, File by File

### GDD_00_Overview.md
- [ ] Rewrite Documentation Authority order per **D-C**.
- [ ] Reword design pillar 1 per **D-C** (Awakening-updated ruleset).
- [ ] Amend "Current Implemented Baseline": mark Pair Up pass 1 and the
      attack-preview More Info panel as **partial / known-broken** (see §4
      bug list). Add a standing "Known broken" subsection so the baseline
      never overstates again.
- [ ] Add a **1.0 definition** line per **D-B** and re-scope the Phase 2/3
      bullets accordingly (full content coverage moves post-1.0).
- [ ] Add a **Platform Targets** section (see §8): desktop primary; Steam
      Deck verified at release; web export as playtest channel; gamepad with
      the rebind milestone; mobile deferred to its own touch-grammar
      milestone. Note D-A rename gate before public release.
- [ ] Note the renderer decision (Compatibility/OpenGL — see §7) in the tech
      stack table.

### GDD_01_Architecture.md
- [ ] Add `RngService` to the autoload order list (after `EventBus`, before
      `GameState`) per companion doc §2.
- [ ] CombatResolver section: add the **frame-atomicity invariant**
      ("resolution must remain frame-atomic; presentation never holds game
      state; combat animations replay an already-committed result") and a
      pointer to the canonical roll order (companion doc §5).
- [ ] Document the **snapshot contract** (`to_save_dict`/`from_save_dict`,
      `schema_version`) as the single serialization surface for Retry,
      suspend, rewind, and resync; note that every milestone adding runtime
      state must register it here (companion doc §8.1).
- [ ] Add the **combat modifier pipeline order** (one page): base stats →
      permanent modifiers → pair-up bonuses → combat-duration skill mods →
      conditions → terrain → weapon triangle → S-rank bonus → clamps.
      RECOMMENDED order; ratify before M9b authoring. Pull the combat-context
      Dictionary schema out of the code header into this section; add
      `GameConstants.CTX_*` key constants and a debug-mode context validator.
- [ ] Add `GameConstants.STAT_*` constants for stat keys (typo class +
      StringName perf — §7).
- [ ] Note the **no per-unit shader tinting** rule: team color via `modulate`
      or per-faction variants baked into the atlas at load; never per-unit
      materials (batching — §7).
- [ ] GridManager: document the logic-side terrain grid (`PackedByteArray`
      parsed from `MapData.grid`; TileMapLayer is presentation-only — §7).

### GDD_02_Core_Mechanics.md
- [ ] Combat Resolution: replace the inline `randi() % 100` description with
      a reference to the RNG contract (mechanic unchanged: roll 0–99,
      `roll < pct` hits).
- [ ] Add the ratified answers once OPEN-3/4/6 are decided: mid-exchange
      weapon breakage, enemy EXP gating, simultaneous-victory tie-break,
      fort/throne heal rounding (§5 has recommended defaults).
- [ ] Action table: confirm Trade and Shove rows carry roadmap pointers
      (they fell out of the roadmap entirely — §6).
- [ ] Note D-E (reclass growth to caps sanctioned) where EXP/internal_level
      is described; state the invariant for whichever EXP basis is ratified.

### GDD_03_Units_Classes.md
- [ ] Resolve the **Soldier class** contradiction: Map 001 places E1/E6 as
      Soldier and Assumption #29 lists it, but GDD_03 has no Soldier. Either
      document it as an enemy-only class or fix Map 001's table (OPEN-9).
- [ ] Add the D-E note to Promotion and Reclass.
- [ ] Clarify multi-skill level-1 unlocks (Mercenary: `vantage` +
      `swordfaire`; Cleric: `renewal` + `miracle`) vs. the singular
      "level-1 class skill" wording — confirm `skill_unlocks` supports lists
      per level and say so.
- [ ] Cleric "Light E": either schedule a Light tome in Phase 2 priorities or
      drop the dead rank (OPEN-10).

### GDD_05_Skills.md
- [ ] Add the **condition/skill precedence ruling** once ratified (OPEN-2;
      recommended default in §5) so all M9b `.tres` authoring follows one
      interpretation.
- [ ] Add the M9 author rule: any new skill that rolls dice appends its draw
      at its trigger's slot in the canonical roll order — never reorders
      (companion doc §5; enforced by test T7).

### GDD_06_Maps_Objectives.md
- [ ] Add the **reinforcement schedule schema** to MapData before Maps
      002–005 get a second authoring pass (§6).
- [ ] Record the coordinate-display convention: internal 0-based `Vector2i`,
      (0,0) top-left; UI displays 1-based with (1,1) top-left. (Currently
      buried in a Manual_Tasks sub-bullet.) Mirror in GDD_07.
- [ ] Map 001: pacing note — playtest for dead turns (large map, MOV-5
      Knight, chokepoint fights then a long march); consider `territorial`
      guards or trimming before public release. Check boss-on-throne math
      (heal vs. level-1 roster damage output) for slog risk.

### GDD_07_UI_UX.md
- [ ] Add the **UI capacity rule**: every menu/panel scrolls or paginates
      past N entries, enforced in the shared modal/menu base (kills the
      level-up overflow, terrain-panel truncation, and future action-menu
      growth as one fix).
- [ ] Add the **hover-parity invariant**: everything shown on mouse hover is
      also shown by cursor-on-tile. (Already true via keyboard parity; naming
      it protects the future touch grammar — §8.)
- [ ] Coordinate-display convention (mirror of GDD_06 item).
- [ ] HUD: panel contents rebuild only when the hovered tile's content
      changes; cache built strings per terrain type (RichTextLabel re-parse
      cost on weak CPUs — §7).
- [ ] Colorblind faction-identity plan (§9): facing convention, badge,
      palette luminance, overlay differentiation; palette table as data for a
      future accessibility toggle.

### GDD_08_Enemy_AI.md
- [ ] Note the **AI-parity checklist** practice: each milestone declares
      which new mechanics the AI must use / must respect defensively / may
      ignore (write into each milestone's checklist, starting M8).
- [ ] Phase 2 scoring section: add the preview-cost design constraint
      (memoize per attacker/defender/weapon per phase, or base-preview +
      per-tile terrain deltas — never naive preview-per-tile; §7).
- [ ] Add the multi-source distance field design note (one flood per faction
      phase replaces per-enemy Dijkstra; also the substrate for
      threat-avoidance — §7).
- [ ] AI tie-breaks must be RNG-free and stable (sort by unit id / tile
      order) — determinism requirement from the RNG contract.

### GDD_10_Roadmap.md / GDD_10a_Overview.md (the latter deleted 2026-06-13, Stage 4.1)
- [ ] **Do not reorder the C-bucket milestone sequence** — ratify the
      Decision-10 order as reviewed. Changes are at the edges only:
- [ ] Reconstitute **Bucket A** from the Manual_Tasks sweep (§4) and place it
      visibly ahead of C4, with C11's pending manual validation alongside.
- [ ] Grow **Bucket B** with slotted prep items:
      - B11: RngService + migration sweep (companion §12 step 1) — before C4.
      - B12: Snapshot contract + Retry migration (step 2) — before C4.
      - B13: Modifier-pipeline order doc — before C6 (M9b authoring).
      - B14: Condition/skill precedence ruling — before C5 (M8).
      - B15: M10 target activation state-machine **decision on paper**
        (DONE becomes counter/state, Secondary Movement/Dance/Galeforce expressible) —
        before C5, because M8 tick semantics ("start of holder's activation")
        must be written against the future shape.
      - B16: Content pipeline (CSV/spreadsheet → `.tres` generator under
        `scripts/tools/`) — before C8 (M11).
      - B17: Registry/manifest headless test (walk `map_registry.json`, load
        every map, cross-check `resource_manifest.json`) — anytime, cheap.
- [ ] Add dependency edges to §3: M8 ← B15 (activation model);
      C12 ← RNG determinism + snapshot contract (subsumes the existing
      "C12 needs suspend save" edge); campaign ← deployment screen, shops,
      recruit mechanic (D-D); rewind ← snapshot contract.
- [ ] New Bucket E / Systems entries (§6 feature list): Trade, Shove,
      convoy/supply, reinforcement system, recruitment (Talk), enemy item
      drops, villages/map events, in-map unit list, difficulty settings,
      suspend save (companion step 3), rewind (companion step 4), gamepad +
      device-aware rebind UI, web export playtest channel, deployment screen,
      shops.
- [ ] Re-scope M11 per D-B (campaign content = 1.0; full coverage =
      post-1.0).
- [ ] Raise B10 priority per D-C; schedule inside the stabilization window.
- [ ] Release-gate (D1) additions: Compatibility-renderer smoke test on the
      weakest available machine; a Steam Deck (or any 800p/gamepad) pass;
      colorblind-simulator screenshot check.

### GDD_Assumptions.md (deleted 2026-06-13, Stage 5.2)
- [ ] Annotate drifted entries with "superseded by …" one-liners (matching
      the #18/#36 pattern): #29 (Soldier→Cavalier roster; pending OPEN-9),
      #48–49 (implemented AI has no kill-priority / terrain tie-break —
      GDD_08 governs), #52 (pause is 0.25s/0.12s per GDD_08).

### GDD_Manual_Tasks.md (moved 2026-06-13, Stage 5.2)
- [ ] After the §4 sweep, findings live in Bucket A; Manual_Tasks returns to
      being a task list, not a shadow bug tracker.
- [ ] Add the process rule to standing agent instructions: playtest findings
      are triaged into Bucket A **same-day** (rule existed in GDD_10a §5;
      it wasn't in the loop that wrote the notes).

### Sprite importer guide (`fe_map_sprite_importer_guide.md`)
- [ ] Hard rule: all unit animation frames ship in shared sprite
      sheets/atlases (draw-call batching — §7).
- [ ] Hard rule: every map sprite reserves a clear corner region for the
      faction badge overlay; per-faction variants (tint + badge) are baked at
      import/load, not composited per-frame (§9).
- [ ] Facing convention: player-faction sprites face right; enemy face left
      (§9).

---

## 3. Decisions Still Open (ratify during the update pass)

| # | Question | RECOMMENDED default |
|---|---|---|
| OPEN-1 | Supports system: in or out? | Decide yes/no and log it; if "yes-later", it's a named post-1.0 item, owned by the campaign-rules layer. |
| OPEN-2 | Condition/skill precedence | Conditions are not skills: Nihil never blocks them; conditions that disable acting also disable that unit's combat-start skills. One general rule, exceptions logged per-skill. |
| OPEN-3 | Mid-exchange weapon breakage | Breakage cancels that unit's remaining strikes in the exchange (consistent with attacks-determined-upfront). |
| OPEN-4 | Enemy/AI EXP | Gate `add_exp()` to player-controlled factions; enemies grow only via authored levels. Keeps designed enemy stats valid. |
| OPEN-5 | Standalone-map durability soft-lock | Accept for now; note that enemy weapon drops (Bucket E) close it when they land. Alternative: 0-Mt unarmed fallback. |
| OPEN-6 | Simultaneous victory/defeat | Evaluate defeat before victory; if multiple groups still win in one pass, prefer the acting faction's group; else declare the existing draw. |
| OPEN-7 | Fort/throne heal rounding | floor(10% max HP), min 1 (matches Renewal). |
| OPEN-8 | Renderer backend | Ship Compatibility (OpenGL); required for web export anyway; nothing used needs Forward+. |
| OPEN-9 | Soldier class | Author it as a documented enemy-only class (smallest change that makes Map 001 + Assumption #29 true). |
| OPEN-10 | Cleric "Light E" | Keep, and put a Light tome in the Phase 2 weapon priorities (else drop the rank). |
| OPEN-11 | Steam Deck 16:10 | Letterbox at first verification; revisit "expand" with the UI-scale setting. |
| OPEN-12 | Handbook author permission/credit | Research the tabletop handbook's license for derivative digital works; decide attribution. Separate from D-A's rename. |
| OPEN-13 | Suspend-file lifecycle | Keep until map resolves (reload-scumming already impossible per RNG-2); companion doc §8.2 assumes this. |

---

## 4. Stabilization Sweep — Bucket A Reconstitution (sources since moved, Stage 5.2)

Source: indented findings inside `GDD_Manual_Tasks.md`. Promote each with an
ID + repro line. Fix order (ratified by review discussion):

1. - [ ] **Attack preview / More Info broken** — "regular information is
       nowhere to be found." Breaks the Readable Systems pillar. First.
2. - [ ] **Seize action unavailable** — blocks Map 002 objective showcase and
       any objective regression sweep.
3. - [ ] **Modal-escape cluster** (likely shared root in ModalScreen /
       cursor-state plumbing — diagnose together): cannot cancel/click out of
       map menu; can't click out of level-up screen; cursor-return-on-cancel
       regression.
4. - [ ] **Pair Up pass-1 bugs**: Swap expends the action but doesn't change
       lead; paired turn doesn't auto-end; bonuses not visibly applied in
       playtest. (Fix to pass-1 spec; campaign-rules milestone still owns the
       deeper semantics — keep that boundary.)
5. - [ ] **Level-up screen**: doesn't expand/scroll at 5+ stat gains (interim
       fix; the §2 GDD_07 UI capacity rule is the permanent one); queued
       multi-level flow check.
6. - [ ] **C11 (M15A hotseat) manual validation** — pending since May; cheap;
       closes a milestone.

Also during stabilization (ratified plan):
- [ ] B17 registry/manifest test.
- [ ] B11 + B12 (RNG service, snapshot contract) — exit criteria for the
      stabilization phase: "docs true, Bucket A empty for real, snapshot
      round-trip test green."
- [ ] B10 corpus reconciliation (priority raised by D-C).
- [ ] OPEN-2/3/4/6/7 ratified as one-line dated decisions.
- [ ] HUD rebuild guard (GDD_07 item — an hour).
- [ ] `OS.low_processor_usage_mode = true` + verify tweens (battery/heat on
      laptops/Deck; one line).
- [ ] Optional, high value-per-hour: web export playtest build on itch
      (needs OPEN-8 = Compatibility; cross-origin headers checkbox; note
      "saves are local to this browser").

---

## 5. CampaignRules Resource (stub now)

Recurring deferrals all point at a "campaign settings layer" with no owner.
Create the stub resource with known fields; stop five systems from inventing
five override mechanisms:

```gdscript
# data/campaign/CampaignRules.gd (Resource)
@export var follow_up_speed_threshold: int = 5
@export var max_equipped_skills: int = 5
@export var pair_up_enabled: bool = true
@export var rewind_charges: int = 3        # 0 = ironman/disabled
# future: support rules, rescue rules, difficulty modifiers
```

Difficulty settings (§6) likely live here too (enemy level offset / density
modifier — cheap given static enemy stat formula).

---

## 6. Feature Additions (ratified: all enter planning)

| Feature | Notes / placement |
|---|---|
| Trade, Shove | Designed in GDD_02 but absent from every bucket — tracking leak. Bucket E; Trade advances the dice chain on every executed trade (companion §3). |
| Convoy / supply | `party_items` is currently unreachable by units; required once shops exist. Bucket E, near shops. |
| Reinforcements | Schema into MapData **before** Maps 002–005 second pass; spawn schedule + dormant `passive` AI hook already anticipated. |
| Turn rewind | Fully designed — companion doc §8.3; build step 4. Charges on CampaignRules. |
| Recruitment (Talk) | **Campaign prerequisite per D-D.** Faction-flip action; independent of story writing. |
| Shops | **Campaign prerequisite per D-D.** |
| Deployment screen | **Campaign prerequisite per D-D**; also triggered the moment roster > map slots. |
| Enemy item drops | Nearly free via `reward_items`; closes OPEN-5 when landed. |
| Villages / map events | Map-object system like doors; Phase 3 "chapter texture" theme. |
| In-map unit list | Status menu from Map Menu; subject to UI capacity rule. |
| Difficulty settings | Enemy level offset/density via CampaignRules. |
| Suspend save | Companion doc §8.2; build step 3. |
| Supports | OPEN-1 — decide, don't omit. |

Meta-note (deliberate, named): the roadmap is strong on combat-engine depth
and thin on the chapter-texture layer (map events, mid-map interactions).
Treat that as an intentional Phase 3 theme, not a blind spot.

---

## 7. Performance / Architecture Backlog

Honest framing: nothing is slow at current scale; these matter at Phase 2
scale and each belongs inside the milestone that touches its system, specced
now so the naive version is never built.

1. - [ ] **Logic-side terrain grid.** GridManager parses `MapData.grid` into
       a flat `PackedByteArray` at setup; all terrain/geometry queries read
       it; TileMapLayer becomes presentation-only. Hottest call path in the
       game currently routes through TileMap node API + string custom-data
       lookups inside Dijkstra. Also: headless tests stop needing a TileMap;
       future terrain mutation (doors, villages) gets one write point.
       *Fits stabilization (contained in GridManager, existing tests).*
2. - [ ] **Multi-source distance field per faction phase** replaces
       per-enemy whole-map Dijkstra in AI; gradient descent gives "move
       toward nearest hostile" free; second field from the player side gives
       threat-avoidance. *Slot: tactical-AI task.*
3. - [ ] **ThreatCache** keyed by unit, invalidated by `unit_moved` /
       `unit_died` / future terrain-changed signals; danger zone = union of
       cached sets. *Prerequisite for always-on danger zone + per-unit threat
       display.*
4. - [ ] **preview_combat cost model** for M14 scoring: memoize per
       (attacker, defender, weapon) per phase, or base preview + per-tile
       terrain deltas. Write into the tactical-AI spec.
5. - [ ] **Flat arrays + key types**: Dijkstra maps as packed arrays indexed
       by tile id (enabled by item 1); `StringName`/`GameConstants.STAT_*`
       for stat keys.
6. - [ ] **Effective-stat dirty-flag cache** — designated but NOT built;
       leave a comment at `get_effective_stat()` marking it as the cache
       point if profiling ever demands.
7. - [x] Snapshot-as-plain-dicts — already the plan via the snapshot
       contract; doubles as the perf fix vs. Resource duplication.

Full-art / old-device chokepoints (decided priorities):
- [ ] **Renderer**: OPEN-8 (Compatibility recommended); D1 release-gate smoke
      test on weakest machine regardless.
- [ ] **Atlas rule** into the importer guide before any art is commissioned.
- [ ] **No per-unit shader tinting** (GDD_01 note); palette swaps baked at
      load if ever wanted.
- [ ] **HUD rebuild guard** (stabilization, §4).
- [x] Pacing levers (movement speed, banners, level-up settings) already
      exist; Phase 3 combat animations must ship with instant-skip +
      per-side toggles (the scaffolded `combat_animations` field).

---

## 8. Platform Targets (new GDD_00 section; details)

- **Gamepad — nearly free** (the virtual cursor *is* a gamepad design): joypad
  events on existing InputMap actions; analog→cursor with existing repeat
  timing; deadzones in `MapCursorInput`. Real work: device-aware glyphs in
  `InputDisplay.gd` + controls list; rebind UI designed per-device from day
  one. *Slot: with the rebind milestone.*
- **Steam Deck — easiest "console" win**, core audience: 1280×800 (OPEN-11),
  UI-scale setting matters at 7" (promotes that backlog item), release
  checklist pass.
- **Web — playtest channel, could be near-term**: Compatibility renderer
  required; cross-origin-isolation headers (itch checkbox) or single-threaded
  export; audio after first user gesture; `user://` = IndexedDB → surface
  "saves local to this browser", never the canonical save home.
- **Mobile — deferred, protected cheaply**: touch ≠ mouse (no hover, no held
  middle-click). Future touch grammar: tap-to-cursor / tap-again-confirm,
  direct drag-pan, pinch zoom (keep the Phase 2 zoom hooks alive — mandatory
  on phones). Protections now: input stays semantic via InputMap (done);
  **hover-parity invariant** named in GDD_07; note 30px menu buttons are
  below touch minimums (future milestone's problem). Plus notches/safe areas,
  aspect ratios.
- **Cross-platform freebies**: `low_processor_usage_mode` (§4); all
  persistence through `user://` via the snapshot contract (abstracts desktop
  / IndexedDB / mobile / future Steam Cloud with zero per-platform code).

---

## 9. Colorblind-Safe Faction Identity (#7 — recommendations accepted for planning)

Principle: never encode faction in hue alone; pair color with a second
channel.

1. - [ ] **Facing convention now (free)**: player-faction sprites face right,
       enemies left (importer guide rule). Necessary, not sufficient (>2
       factions).
2. - [ ] **Faction shape badge** (circle/triangle/square/diamond), baked into
       per-faction sprite variants **at import/load into the atlas** (no
       per-frame overlays, no shaders — consistent with §7 batching rules).
       Importer-guide rule **now**: every sprite reserves a clear corner.
3. - [ ] **Palette luminance separation**: keep blue/red/green/yellow but
       choose shades that survive a grayscale screenshot test. Faction colors
       become a data table → free Phase 3 "alternate palette" toggle.
4. - [ ] **Overlay audit — same bug**: movement-blue vs attack-red vs danger
       overlays are hue-only; differentiate by luminance/alpha or hatched
       texture variants (overlay tiles come from the existing tileset tool —
       fits stabilization).
5. - [ ] **Verification**: run map screenshots through Color Oracle / Sim
       Daltonism (deuteranopia + protanopia minimum) at palette-selection
       time and again when real sprites land. Add to D1 release gate.

---

## 10. Parking Lot (explicitly deferred by owner)

- [ ] **#8 — Doc-lifecycle rule**: "a milestone's definition-of-done includes
      updating affected GDD_01–08 sections; GDD_10a status flips in the same
      commit." One process sentence; prevents the drift class this review
      found. *Owner to revisit.*
- [ ] **#9 — Minimal SFX scope**: four sounds (cursor tick, confirm, hit,
      crit) vs. waiting for the Phase 3 audio milestone; silence makes
      playtests feel broken. *Owner to revisit.*

---

## 11. Quick Index — what to do in what order

1. §4 stabilization sweep (docs-true first, then the six fix items, then the
   B-items listed there).
2. §2 GDD edits — can be batched with the sweep's doc work; §1 decisions and
   §3 ratifications land in the same pass.
3. §5 CampaignRules stub + §9 importer-guide rules (minutes each; do with the
   doc pass).
4. Roadmap surgery (GDD_10/10a items in §2) — Bucket A/B/E updates, edges,
   M11 re-scope, D1 gate additions.
5. Everything else rides its named milestone slot.
