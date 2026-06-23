---
Type: plan
Status: Active — planning queue
Last verified: 2026-06-23
---

# Planning Backlog — Items Needing Implementation-Ready Plans (2026-06-20)

Status: Active — planning queue
Last verified: 2026-06-21

Upcoming roadmap items that do **not** yet have an implementation-ready plan or design
doc. **None of these are blocked from *planning*** by the current execution blockers (no
live screen; no `gh`/token for the `main` PR merge) — planning is docs-only. They are the
candidates for the next planning session(s). Indexed from `AGENT/GDD/GDD_10_Roadmap.md` →
*Open Items Register*.

> **Already plan-ready (excluded from this list):** M8 (full `ConditionManager` spec +
> enforcement hooks + checklist), M9a/M9b, M10, M11, M12, M13 (full specs in GDD_10);
> v0.2.3 (implemented — live-verify only); the Debug Web build
> (`handoff_2026-06-20_web_debug.md` — 4 slices + decisions, ready to execute after v0.2.3).

For each item: **State** = what exists today; **Plan should produce** = the deliverable a
planning session would write.

---

## 1. Input / controls cluster — highest near-term leverage

Sequenced right after the Debug Web build; the gamepad layer is the keystone for Steam
Deck + phone-controller + virtual-gamepad + web shell. Entirely docs-only to plan.

- **Input-mode / gamepad implementation plan. ✅ DECISIONS + GAMEPAD ARM DONE (2026-06-20j).**
  - The 4 open decisions are resolved (see `input_mode_architecture_design_2026-06-20.md`
    → Resolved decisions) and the **gamepad arm** has a full impl plan:
    `gamepad_layer_implementation_plan_2026-06-20.md` (action map, focus wiring, bindings,
    analog repeat, `input_mode_changed` seam, 4 slices, test plan).
  - **Broader resolver — ✅ PLAN DRAFTED (2026-06-21):**
    `AGENT/Docs/input_mode_resolver_implementation_plan_2026-06-21.md` (Auto/Touch/K&M
    detect-floor + conditional-promotion resolver, gray/back-door availability, the
    `[controls]` persistence + `mouse_cursor` relocation, and the DoD#2 `check_docs` guards
    for the `input_mode` / `touch_controls` value-sets). **Decisions resolved 2026-06-21**
    ([ICD-1] new `InputModeManager` autoload, [ICD-2] resolver = gamepad slice 3, [ICD-3]
    touch-first detection) — **build-ready**; slice 1 (persistence + guards) has no
    dependency. See `AGENT/Docs/input_controls_open_decisions_2026-06-21.md`.
- **V021-15 — shared selector extraction. ✅ DESIGN DONE (2026-06-20j):**
  `AGENT/Docs/shared_selector_extraction_design_2026-06-20.md`.
  - Was: three surfaces navigate independently (sheet grid, forecast F-cycle, terrain
    F-paging); no extraction design. It is the single joypad-wiring point.
  - Produced: scope = extract a `SelectionCursor` navigation core + an input-routing/arbiter
    convention (NOT a unified render widget); rendering stays per-surface; per-consumer
    adoption notes + headless test plan. Implements with the gamepad layer.
- **Key rebinding UI. ✅ PLAN DRAFTED (2026-06-21):**
  `AGENT/Docs/key_rebind_ui_implementation_plan_2026-06-21.md` — capture-UI flow, conflict
  handling, reset, per-device-slot model (so a K&M rebind can't wipe the pad binding), and
  composition with the input-mode setting. **Decisions resolved 2026-06-21** ([ICD-4]
  per-device slots, [ICD-5] all actions rebindable + always-on Reset + human-readable cfg +
  capture-any-device-now, [ICD-6] swap on conflict) — **build-ready**; slices 1–2 (persistence
  foundation + K&M rebind UI) have no remaining dependency. See
  `input_controls_open_decisions_2026-06-21.md`.
- **Gamepad binding audit.**
  - State: Platform Targets says "audit all actions for joypad events" — no plan; zero
    `InputEventJoypad*` bindings exist today.
  - Plan should produce: the per-action audit + binding scheme (folds into the input-mode plan).

## 2. Campaign / save cluster — gates the 1.0 campaign (D-D)

**✅ PLAYER-FACING SCOPE FIRMED (2026-06-21b)** then **✅ TECHNICAL PLAN + DECISIONS DRAFTED
(2026-06-21):** `AGENT/Docs/campaign_save_technical_plan_2026-06-21.md` (architecture, schema,
flows, slices) + `AGENT/Docs/campaign_save_open_decisions_2026-06-21.md` (**[CST-1..12] all
RESOLVED**; one [CST-13] deferred to execution kickoff). Player-facing firming:
`campaign_save_player_facing_firming_2026-06-21.md`. **KEY SEQUENCING ([CST-12] → C): Package A
(`RngService`) is built FIRST, before the §2 spine** — so the next EXECUTION step is a Package A
plan, then §2 slices 1–7. Otherwise §2 is build-ready.

**MVP scope (firmed):** linear-but-overworld-ready progression graph · between-map prep
(deploy/bench, per-map required/excluded/cap, player placement, manual save, launch) ·
human-readable JSON saves (version + label + integrity hash) · in-app slots + filesystem
export/import (single `.json`, zip-sniffing importer) · persistent re-loadable suspend ·
Continue = resume-most-recent · multi-choice Game Over · rewind RULE+charges+defeat-entry
(mechanic deferred to `RngService`/Package A) · rules player-locked/story-flippable/tinkerer-warned.
**Deferred from MVP:** convoy (D), shop (E), recruit (F), Pair-Up persistence + Support + Rescue
(H), campaign-PACK format (I3), the rewind mechanic (J). **Cross-version save transfer: not a
concern until 1.0** (keep `format_version`, no migration code pre-1.0).

The technical plan should produce:
- **CampaignRules contract + `GameState` consolidation.** Full per-save rule schema + the
  **story-flip mutation seam** (scripted, not player UI) + snapshot-serializer changes.
- **Campaign save schema + serialize/deserialize seam** (isolated from file I/O): roster, gold,
  items, progression-graph position, rules, rewind charges, slot metadata + `save_label` +
  `format_version` + integrity hash. JSON save/load + **export/import** (zip-vs-json sniff) +
  the **slot menu** + **Continue/Load** UI.
- **Progression-graph node model** (linear-degenerate now, overworld-ready) + map data fields
  (`required_units`/`excluded_units`/`deployment_cap`/deploy tiles/`next`).
- **Prep screen** architecture (deploy/bench/placement/save/launch).
- **Mid-battle suspend save** serializer (incl. activation-scheduler state + the M15B
  save-and-continue tie-in). **Forward dep:** also serialize the threat-range `_watch_set` +
  `_danger_mode` (`individual_threat_range_design_2026-06-21.md` §5/slice 4). **Reserve room
  for the 2026-06-21d register forward-deps** (later data-growth, not a reshape):
  `discovered_units` (fog), `ai_awake` (territorial AI), `map_objects_state` (doors/chests/
  siege), `rewind_charges` (Package A → consolidated here per [PKGA-3]).
- A **decisions register** for the code-facing choices the firming left open.

## 2b. DEFERRED from the campaign/save MVP — do-not-forget tracker (firmed 2026-06-21b)

These were explicitly scoped OUT of the campaign/save MVP during the player-facing firming
(`campaign_save_player_facing_firming_2026-06-21.md`). The MVP save schema reserves room for
them so each is **later data-growth, not a reshape** — but they still need their own design/
plan when re-surfaced. Re-surface candidates **after the §2 spine lands**. Each names the
firming branch it came from.

- **Convoy / inventory (branch D).** Shared party convoy (item quantities + store), in-prep
  trade, on-map convoy access, and `max_inventory = 8` enforcement (defined, unenforced today).
  Save reserves `party_items`. Needs: convoy UX + per-unit inventory management plan.
- **Shop / economy (branch E).** Between-map buy/sell shop spending `party_gold`; gold sinks/
  sources; forge (E3) likely its own later item. Needs: economy + shop-screen plan.
- **Recruit, green→player (branch F).** Interactive on-map Talk/Recruit action + roster-join
  UX. Roster growth is already save-supported. Needs: recruit-mechanic design. (D-D prerequisite.)
- **Pair Up persistence + prep pairing (branch H1).** Today pairings reset each map; making
  them persist + manageable in prep needs the registry serialized into the save + prep UI.
- **Support system (branch H2).** Ranks/affinity/conversations/bonuses; firming-notes prior =
  version its data separately from map runtime state. Large new system. Needs: full design.
- **Rescue system (branch H3).** Carry/drop, weight/CON, canto interactions; Pair-Up/Rescue
  mutual-exclusion prior stands. Needs: full design.
- **Campaign-PACK format + authoring tools (branch I3).** The distributable homebrew-campaign
  bundle (maps + roster + progression graph + rules); likely home for zip-bundling/compression.
  The MVP importer is built to **sniff zip-vs-json** so a pack imports with no migration. Needs:
  pack-format + authoring/distribution plan.
  - **CONTENT MODEL — RESOLVED 2026-06-23 (`[ICO-1..6]`, owner REFRAMED to SELF-CONTAINED).** Register:
    `AGENT/Docs/campaign_content_overlay_open_questions_2026-06-23.md`. The pack carries **content**
    (weapons/items/classes/skills, incl. **labels + art**), not just maps/roster/rules. **Model =
    SELF-CONTAINED, everything user-defined** (NOT the base+overlay fork — *this reverses the
    direction first set 2026-06-23a*). Each campaign is a **complete, independent bundle**; **no
    runtime inheritance/overlay** — `select_campaign(c)` *replaces* the content dicts with c's full
    set. Default content ships with the **builder** as a copy-from palette and is **copied
    `res://`→`user://` on first run**; the loader then uniformly enumerates `user://` campaign dirs;
    all content art is **raw-loaded** (`Image.load_from_file`→`ImageTexture`). Relabel ("Iron Sword"
    vs "Bronze Katana") is still cheap — id-keyed + `display_name` on the resource — but it's a
    whole-resource copy in the campaign, not a runtime override. **Costs accepted:** content
    duplication/bloat + **no central patch propagation** (fix a default → re-ship each campaign).
    **Two tiers (art in the package, never the save):** (1) campaign package [complete content + art,
    in `user://`], (2) per-playthrough **save** [state by id; binds to a campaign id; resolves against
    **that campaign's own set**].
  - **Resolved sub-decisions ([ICO-1..6], 2026-06-23):** include = **self-contained** (a); override
    granularity = whole-resource, trivial w/o merge (b); override-intent = **authoring-time provenance
    `forked_from` only**, no runtime validation (c); versioning = **provenance stamp
    `builder_content_version`**, no load gate (d); location = **copy to `user://` on first run** +
    uniform enumeration (e); **item `icon`** = new `@export var icon: String` on `WeaponData`+`ItemData`
    + `resolve_icon()` raw-Image helper, **field+seam now / UI render deferred** (f).
  - **DMR / DataManager dependency.** `[DMR-1..4]` RESOLVED 2026-06-23 — its `_apply_overlay()` *merge*
    stub is **superseded by a replace-load** under self-contained (the `select_campaign()`/
    `_load_all(source)` seam stands). **Heaviest new build work = the first-run seed-copy + `user://`
    enumeration + reset/repair path (ICO-5)**, not a merge engine. The eventual **GUI campaign editor**
    (AI vision §2/§GUI) is the authoring surface (copy-from-defaults → edit → write whole resources).
- **Rewind MECHANIC (branch J — distinct from the MVP hooks).** The actual per-action Turnwheel
  is blocked on `RngService` (Package A) — `rng_determinism_design_2026-06-11.md`. **Sequencing
  RESOLVED (§2 technical plan, [CST-12] → C, 2026-06-21): Package A is built FIRST, before the §2
  spine.** So the mechanic is unblocked by the time §2 lands. **Open follow-on ([CST-13],
  deferred to §2 execution kickoff):** fold the Turnwheel mechanic INTO §2 vs ship §2 with rule+
  charges+menu hooks and do the mechanic immediately after (rec: hooks-only, mechanic next).
  Needs: Package A plan, then the in-battle turnwheel UI + state-history capture/replay.
- **Cross-version save migration (branch I5).** Loading old saves in new builds is **not a
  concern until 1.0**; keep `format_version` as insurance, write no migration code pre-1.0.
- **PvP / scenario mode (NEW — surfaced by §2 [CST-7], 2026-06-21).** A standalone non-campaign
  match mode reusing the **preserved standings/rankings renderer** (the old GameOverScreen
  ranking logic, kept extractable rather than deleted when the victory/defeat screens split). No
  progression/save advance. Needs: scenario-mode design (setup, factions, win/rank, no campaign).

## 3. Release gates needing a plan (not just execution)

> **DRAFT PLANS + OPEN-QUESTIONS REGISTERS written 2026-06-21d** (all registers OPEN —
> not yet walked/resolved): `public_identity_rename_open_questions_2026-06-21.md` [REN-1..5],
> `legal_licensing_open_questions_2026-06-21.md` [LEG-1..5],
> `broken_weapon_mode_open_questions_2026-06-21.md` [BWN-1..5]. See session note 2026-06-21d.

- **D-A — public-identity rename.** State: gate; **draft + register [REN-1..5] drafted**
  (rec: rename display-names only, keep ids; [REN-1] needs the user's actual names).
- **DOC-012 / OPEN-12 — legal/licensing.** State: blocking pre-1.0 gate; **research/decision
  register [LEG-1..5] drafted** (NOT a code plan; [LEG-1] needs the owner to name the corpus).
- **OPEN-5 — broken-weapon degraded mode.** State: **register [BWN-1..5] RESOLVED 2026-06-22h**
  (build-ready after §2 [CST-4]). Owner reframe → **per-weapon `break_behavior` (`destroy`/`degrade`)
  + `CampaignRules` default** (not one global toggle); Broken still derived from `uses_remaining==0`
  (no new `InventoryEntry` field); penalty = global `GameConstants` defaults + per-weapon overrides,
  applied at `CombatResolver` + shown debuff-red on the character sheet; **repair deferred to the
  §2b/E shop** (no v1 item); unified weapon-stat-delta display reserved for weapon-upgrades.

## 4. UI / UX enhancements — backlog bullets, no plans

Range-on-hover overlay; movement path arrows; **individual unit threat range — ✅ DESIGNED
2026-06-21 (`AGENT/Docs/individual_threat_range_design_2026-06-21.md`); unblocks the gamepad
contextual R3 danger-zone. [TUR-1..4] ALL RESOLVED (persistent watch set + display-mode
cycle; darker-red watch layer + "D" markers; contextual MMB; auto-promote/demote, prune dead,
survive phases + save/load). Slice 1 (extraction) build-ready; slice 2 needs one editor step
(darker-red tile); slice 4 (save serialization) is a forward dep on §2.**; grid-visibility
slider; camera settings (edge-pan buffer + scroll responsiveness); attack-by-target
selection; richer combat prediction (crit / triangle / effective flags); combat-prediction
layout; minimap toggle. Each needs a short design before scheduling; several pair naturally
(hover overlays + threat range + path arrows form one "map readability" plan).

> **MAP-READABILITY CLUSTER drafted 2026-06-21d:** `map_readability_open_questions_2026-06-21.md`
> [MRD-1..6] (hover-peek overlay + path arrows + the designed individual threat range +
> grid-visibility slider; register OPEN). Camera settings / attack-by-target / richer
> prediction / minimap remain separate un-planned bullets.

## 5. Other systems — backlog bullets, no plans

Fog of war / LoS; rescue & carry; doors & chests (Pick/Unlock/Key); additional AI profiles
(territorial, guard_tile, healer, boss); stationary weapon interaction (Ballista/Onager);
cap-management UI (manual skill swap, `max_inventory` trade UI); FE map sprite importer
productionization (4 decisions already noted in the backlog); `DataManager._ready()`
decomposition (named phases sketched, no full plan).

> **DRAFT PLANS + REGISTERS written 2026-06-21d** (all OPEN; see session note 2026-06-21d):
> `fog_of_war_los_open_questions_2026-06-21.md` [FOW-1..6] ·
> `ai_profiles_open_questions_2026-06-21.md` [AIP-1..5] ·
> `doors_chests_open_questions_2026-06-21.md` [DCH-1..6] ·
> `stationary_weapons_open_questions_2026-06-21.md` [STW-1..6] ·
> `map_sprite_importer_open_questions_2026-06-21.md` [IMP-1..6] ·
> `datamanager_decomposition_open_questions_2026-06-21.md` [DMR-1..3].
> **Cross-cutting:** doors/chests + siege share ONE `map_objects` tile-object model (do
> doors/chests first; siege inherits it). **Still un-planned here:** rescue & carry (§2b/H3),
> cap-management UI (folds into convoy §2b/D). Package A (`RngService`) draft =
> `package_a_rngservice_open_questions_2026-06-21.md` [PKGA-1..4] (gaps only).
>
> **STATUS UPDATE 2026-06-22g:** **RESOLVED** registers — PKGA `[PKGA-1..4]`, FOW `[FOW-1..7]`,
> DCH `[DCH-1..6]`, DTR `[DTR-1..8]`, MET `[MET-1..9]`, **AIP FULLY** (`[AIP-1..16]` +
> `[AIP-A11/A12]`; Group A first-build spec = `ai_first_build_design_2026-06-22.md`, Group B closed
> 2026-06-22e), **STW `[STW-1..6]` RESOLVED 2026-06-22f** (build-ready; inherits DCH's
> `map_objects`; occupy-tile mount, move-and-fire allowed, object-owned ammo, **enemy AI siege use
> in v1** → `siege_operator` promoted into STW v1), and **MRD `[MRD-1..6]` RESOLVED 2026-06-22g**
> (build-ready; [MRD-1] C range∩threat blend + opaque hover/arrows · [MRD-2]/[MRD-4] B hold-to-peek,
> compute-on-press · [MRD-5] A terrain-only `grid_dim` slider · [MRD-6] A threat-range first; TUR
> folds in), and **BWN `[BWN-1..5]` RESOLVED 2026-06-22h** (build-ready after §2 [CST-4]; per-weapon
> `break_behavior` + `CampaignRules` default, global+per-weapon penalty, repair deferred to §2b/E,
> debuff-red character-sheet display). **Still OPEN (next planning):** IMP `[IMP-1..6]`, DMR
> `[DMR-1..3]`, plus release gates REN `[REN-1..5]` / LEG `[LEG-1..5]` (owner-input-blocked).

## 6. Maps

Maps 002–005 authored against the M16 objective condition types (Seize, Boss Defeat,
Escape, Survive/Defend).

---

## Recommended next-session focus

**§1 planning is now COMPLETE (drafted 2026-06-21).** The bulk landed 2026-06-20j; the two
remaining plans were drafted 2026-06-21, both decision-free:

1. **Broader input-mode resolver plan** — `input_mode_resolver_implementation_plan_2026-06-21.md`.
2. **Key-rebind UI plan** — `key_rebind_ui_implementation_plan_2026-06-21.md`.

Every choice those two plans could not make was consolidated in
`input_controls_open_decisions_2026-06-21.md` and **all resolved 2026-06-21** (ICD-1..6;
ICD-7 is tune-live, non-blocking). **§1 is now fully build-ready** — both plans have a
no-dependency first slice. The next §1 step is **execution**, not planning.

After §1, the next planning cluster is **§2 Campaign / save** (gates the 1.0 campaign, D-D).

> Superseded recommendation (kept for provenance): the original text here recommended
> starting §1 from the input-mode 4 decisions → V021-15 design → gamepad audit; all of that
> is now done (2026-06-20j).
