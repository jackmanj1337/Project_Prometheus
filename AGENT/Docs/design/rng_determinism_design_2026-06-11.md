---
Role: dated
Type: design
Status: Target design
Last verified: 2026-06-23
---

# RNG Determinism, Rewind, Suspend Save & Online Model — Implementation Plan

**Status:** **Target design** — implementation plan for Package A (`RngService`),
dated 2026-06-11, two-RN update 2026-06-13. Lives in `AGENT/Docs/` (moved from
`AGENT/GDD/`, Stage 3.1, DOC-010).
**Binding rules now live in the GDD:** `GDD_01 → Determinism, Snapshot & Online
Contract` (RNG-1…4, canonical roll order, snapshot/online) and `GDD_02 → Combat
Resolution & Hit RNG` (two-RN hit model). **This file is the build guide** — code,
integration sweep, tests, and build order — not the authority for the rules. It is
archived once `RngService` and its tests land.
**Supersedes:** the inline `randi() % 100` rolls in GDD_02. Both the *source* of the
roll (now `RngService`) and the *hit mechanic* change: the single-roll `roll < pct`
rule is replaced by the two-RN model (RULE-001) — see §5. Single-roll is **Superseded
by RULE-001**.
**Consumers:** rewind (Turnwheel-style), mid-battle suspend save, Retry,
reproducible headless tests, M15 Part B host-authoritative online play.

> **Amendment (2026-07-06):** B1-PKGA Slice 1b landed — `RngService` autoload +
> the combat hit/crit migration, with tests T1/T3/T7 green
> (`test_rng_service.gd`, `test_rng_combat_determinism.gd`). Per
> [`combat_roll_resolver_open_questions_2026-06-30.md`](../registers/combat_roll_resolver_open_questions_2026-06-30.md)
> (CRR-1..8), RULE-001 is reframed as the **default preset** of the
> author-selectable hit-roll resolver seam (`two_roll`; `single_roll` is the
> second built-in; selection = `CampaignRules.hit_formula`). Growth/skill
> migration (Slice 1c), the raw-RNG guard (Slice 1d), and snapshot persistence
> (Step 2) remain outstanding.

---

## Decision Records

> Copy these four entries into `AGENT/Docs/design_decisions_log_*.md` when
> ratifying. They are the binding rules; everything below is implementation.

**RNG-1 — Hash-chained context-seeded dice (2026-06-11).**
All gameplay dice derive from `seed = mix(map_seed, history_hash, event_record)`.
`history_hash` advances on every **committed, non-undoable unit action**
(action kind, acting unit, from/to tiles, target). Equip, undone moves, menu
navigation, cursor movement, danger-zone toggles, and previews **never**
advance it. Each dice-bearing event draws all of its rolls from its own
freshly seeded RNG in the canonical roll order (§5). Level-ups are chained
events keyed by `(unit_id, new_level)`, one event per level on EXP overflow.

**RNG-2 — RNG state lives in the snapshot contract (2026-06-11).**
`{map_seed, history_hash}` is serialized inside every map snapshot
(Retry, rewind checkpoints, suspend save). Restoring a snapshot restores the
dice timeline: replaying the identical committed-action sequence reproduces
identical outcomes, byte for byte.

**RNG-3 — Accepted exploits, priced by rewind charges (2026-06-11).**
Two manipulations are knowingly permitted: (a) *probing* — rewinding and
repeating the exact same action shows the same outcome (irreducible in any
deterministic rewind system); (b) *Wait-to-reroll* — committing any cheap
action (e.g. a Wait) re-seeds all subsequent dice. Both are priced by a
limited rewind-charge pool owned by `CampaignRules` (default 3–5 per map;
0 = ironman). No further anti-manipulation machinery is planned.

**RNG-4 — Online play is host-authoritative (2026-06-11).**
M15 Part B does **not** use deterministic lockstep. The host simulates; remote
clients receive committed result payloads and apply them through the existing
`apply_combat_result()` / snapshot seams. Determinism guarantees are therefore
**engine-local only** (same machine, same Godot build). The custom mixer (§3)
is still mandatory — it protects suspend saves and the dice chain from Godot
version upgrades changing engine `hash()` / RNG internals.

---

## 1. Goals and Non-Goals

| Goal | Met by |
|---|---|
| Rewind + identical replay ⇒ identical outcome (no savescum) | RNG-1 + RNG-2 |
| Different event never inherits another event's numbers (no roll *transfer* / *burning*) | event identity in the seed (§3) |
| Any earlier committed action changes all later dice (player-requested "butterfly" behavior) | chain advancement on every committed action (§4) |
| Suspend save cannot reroll anything on reload | RNG-2 |
| Reproducible headless tests | seeded `map_seed` + scripted action sequences (§10) |
| Online-ready without cross-platform determinism debt | RNG-4 (§9) |

**Non-goals:** hiding outcomes from a determined prober (impossible under
deterministic rewind — see RNG-3); input-log replays (state is kilobytes;
store snapshots or result logs instead); cryptographic-quality randomness.

---

## 2. `RngService.gd` — new autoload

Register in `project.godot [autoload]` **after `EventBus`, before
`GameState`** (no dependencies; must exist before anything rolls). Update the
GDD_01 autoload-order list — the twelve become thirteen:
`GameConstants → EventBus → RngService → SettingsManager → GameState → …`.

```gdscript
# scripts/autoloads/RngService.gd
extends Node

var map_seed: int = 0          # rolled once per map in start_map(); recorded
var history_hash: int = 0      # advances per committed action — see §4

func start_map(seed_override: int = 0) -> void:
    # seed_override != 0 is the test/replay hook; 0 = roll a fresh seed.
    map_seed = seed_override if seed_override != 0 else _entropy_seed()
    history_hash = 0

# ── Event API ────────────────────────────────────────────────────────────────
# A dice-bearing action calls begin_event() to obtain its private RNG, draws
# every roll from it in canonical order (§5), then calls commit_event() with
# the SAME record when the action commits. A non-dice action calls only
# commit_event(). Previews call NEITHER.

func begin_event(kind: String, record: Array[String]) -> RandomNumberGenerator:
    var s := _mix(map_seed, history_hash)
    s = _mix(s, _hash_string(kind))
    for field in record:
        s = _mix(s, _hash_string(field))
    var rng := RandomNumberGenerator.new()
    rng.seed = s
    return rng

func commit_event(kind: String, record: Array[String]) -> void:
    history_hash = _mix(history_hash, _hash_string(kind))
    for field in record:
        history_hash = _mix(history_hash, _hash_string(field))

# ── Persistence (consumed by the snapshot contract) ─────────────────────────
func to_save_dict() -> Dictionary:
    return {"map_seed": map_seed, "history_hash": history_hash}

func from_save_dict(d: Dictionary) -> void:
    map_seed = int(d.get("map_seed", 0))
    history_hash = int(d.get("history_hash", 0))

# ── Mixing primitives ────────────────────────────────────────────────────────
# SplitMix64-style finalizer. NEVER replace with engine hash(): its semantics
# are not guaranteed stable across Godot versions, and a change would silently
# invalidate in-flight suspend saves and the determinism tests.
#
# GDScript ints are signed 64-bit with wrapping arithmetic. If 16-digit hex
# literals with the high bit set are rejected by the parser, use the signed
# decimal equivalents given in the comments.
static func _mix(a: int, b: int) -> int:
    var z: int = (a ^ b) + -7046029254386353131    # 0x9E3779B97F4A7C15
    z = (z ^ (z >> 30)) * -4658895280553007687     # 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) * -7723592293110706605     # 0x94D049BB133111EB
    return z ^ (z >> 31)

# Deterministic string fold over UTF-8 bytes. Do NOT use String.hash() —
# same engine-stability argument as above.
static func _hash_string(s: String) -> int:
    var h: int = 0
    for b in s.to_utf8_buffer():
        h = _mix(h, b)
    return h

static func _entropy_seed() -> int:
    var r := RandomNumberGenerator.new()
    r.randomize()
    return r.randi() | (r.randi() << 32)
```

Notes:

- The per-event `RandomNumberGenerator` is **local and throwaway** — it is
  never stored, never serialized. All persistence is the two ints.
- A right-shift in GDScript is arithmetic (sign-extending), not logical.
  That weakens the mixer's avalanche slightly versus the canonical unsigned
  SplitMix64 but is irrelevant at this quality bar; do **not** "fix" it later,
  because changing the mixer is a save-breaking change (see §11 versioning).
- Cosmetic randomness (sprite flicker, future SFX variation) must NOT use
  this service — give presentation code its own un-chained RNG so visual
  polish can never perturb gameplay dice.

---

## 3. Event Records

An event record is `(kind: String, record: Array[String])`. The record is the
**identity** of the action; identical identity + identical history ⇒ identical
dice. Canonical field formats (order matters — it is part of the identity):

| Field | Format | Example |
|---|---|---|
| acting unit | `UnitData.unit_id` | `"unit_02"` |
| tile | `"x,y"` (internal 0-based coords, NOT the 1-based display coords) | `"7,11"` |
| target unit | `unit_id`, or `"-"` if none | `"e3"` |
| level | decimal int string | `"5"` |

### Kind catalogue

| `kind` | Dice? | `record` |
|---|---|---|
| `"attack"` | yes | `[attacker_id, from_tile, to_tile, defender_id]` |
| `"staff"` | no (heal is deterministic; EXP is flat) | `[healer_id, from_tile, to_tile, target_id]` |
| `"item"` | usually no | `[unit_id, from_tile, to_tile, item_id]` |
| `"wait"` | no | `[unit_id, from_tile, to_tile]` |
| `"seize"` / `"escape"` | no | `[unit_id, tile]` |
| `"pair_up"` / `"swap"` / `"separate"` | no | `[unit_id, partner_or_tile]` |
| `"trade"` | no | `[unit_id, partner_id]` — advances on **every executed trade**, regardless of whether that trade ends the turn |
| `"shove"` | no | `[unit_id, target_id, direction_tile]` |
| `"levelup"` | yes | `[unit_id, new_level]` |
| `"skill_activated"` (future `player_activated` skills) | per skill | `[unit_id, skill_id, target_or_dash]` |

`from_tile` is the pre-move tile, `to_tile` the committed destination. This
means **a unit's chosen path destination changes its own dice**, per the
ratified "every committed action" rule. Movement that is later undone never
existed: no commit, no chain advance.

New action types added in M8/M9/M10 **must** add a row to this table in the
same commit that adds the action. An action missing from the chain is a
determinism bug (the §10 lint test catches raw `randi`, but a silently
un-chained action is caught only by review — hence this rule).

---

## 4. Chain Advancement Rules

**Advance the chain** at the moment an action becomes non-undoable — in the
current flow, the point where the action executes and `TurnManager` will mark
the unit `MOVED→DONE` (or the action resolves for non-turn-ending commits like
mid-turn Trade).

| Advances `history_hash` | Never advances |
|---|---|
| Every row in the §3 kind catalogue, for **every faction** — AI and hotseat actions chain identically to blue's | **Equip** (free, repeatable mid-turn — chaining it would be an infinite zero-cost reroll crank) |
| Each level-up event (after its rolls are drawn) | Undone moves (not committed by definition) |
| Future M10 extra activations (each committed Secondary Movement / Dance / Galeforce action is its own event) | Menu open/close, cursor motion, danger-zone toggle, `inspect_unit`, More Info |
| | `preview_combat()` and all SkillHandler `preview` / `dry_run` paths |
| | Phase changes, fort healing, condition ticks, `start_of_turn` skills (deterministic effects — no dice today; if a future per-turn effect needs dice, give it a chained `kind` of its own) |

Ordering within one action: `begin_event` (seed reads the **pre-action**
hash) → draw all rolls → apply → `commit_event` (hash now includes this
action) → any resulting `levelup` events begin/commit next, in unit-id order
if multiple units leveled from one exchange (symmetric EXP).

---

## 5. Canonical Roll Order (binding contract)

Within a single `"attack"` event, rolls are drawn from the event RNG in
exactly this order, mirroring the exchange list built by `resolve_combat()`:

1. For each strike, in exchange-list order (initiator → counter → follow-up,
   with Vantage/Brave reordering already applied by the existing builder):
   1. **Hit rolls — two-RN model (RULE-001).** Draw **two** integers
      `rng.randi_range(0, 99)` in order: `r1` then `r2`. The strike **hits when
      `floor((r1 + r2) / 2) < displayed_hit`** (the resolved/displayed hit
      chance). **Both draws are always consumed, even on a miss** — the count
      is fixed so the roll order never depends on the outcome.
      *(Clarified 2026-07-06, CRR-2: the per-strike hit-RN count is the
      selected resolver's fixed `rn_count` — default `two_roll` = 2; changing
      it is save-breaking as already stated.)*
   2. **Crit roll** — drawn **only if the hit landed** (a miss consumes two
      rolls, a hit consumes three; this is fine because the consumer is private
      to the event).
   3. **Activation rolls** for skills with `activation_chance_stat`, in the
      unit's skill-list order, only at the trigger points where SkillHandler
      actually rolls (e.g. Miracle on `on_damaged`).
2. After the exchange: `"levelup"` events as separate chained events (§4).

Within a `"levelup"` event: one growth roll per stat in `ClassData.STAT_KEYS`
order (`hp, strength, magic, defense, resistance, skill, speed, luck`),
matching the existing `growth_random` path. `growth_fixed` draws nothing but
the event still commits (it is a committed action outcome and the player
chose the leveling method; keeping the commit makes the chain identical
across leveling methods for the same action sequence).

**Rule for future skills (M9):** a new skill that adds a roll must *append*
its roll at its trigger's slot in this order — never reorder existing draws.
Reordering is a save/replay-breaking change (§11).

Add a pointer to this section in the `CombatResolver.gd` file header next to
the combat-context schema, and add `"rng": RandomNumberGenerator` to the
combat-context dictionary so SkillHandler activation rolls draw from the
event RNG instead of global state.

---

## 6. Integration Points (code-touch list)

| File | Change |
|---|---|
| `project.godot` | Register `RngService` autoload (position per §2). |
| `scripts/core/CombatResolver.gd` | `resolve_combat()` calls `begin_event("attack", record)` at the top (immediately after the existing `combat_started` emit) and stores the rng in the combat context; every `(randi() % 100)` becomes a draw from `context.rng`; `apply_combat_result()` calls `commit_event` with the same record after committing, before EXP/level-up handling. `preview_combat()` is untouched and must remain roll-free. |
| `scripts/skills/SkillHandler.gd` | Activation-chance rolls read `context.rng`. The `preview` flag already excludes random-activation skills from forecasts — keep that invariant; previews must never draw. |
| `scripts/units/Unit.gd` | `level_up()` wraps its growth rolls in a `begin_event("levelup", [data.unit_id, str(level + 1)])` / `commit_event` pair (one pair per level on overflow). |
| `scripts/core/TurnManager.gd` | The single chokepoint that marks actions committed calls `commit_event` for non-dice kinds (`wait`, `seize`, `escape`, pair actions, future trade/shove). Dice-bearing kinds commit inside their own resolution path (above) — TurnManager must not double-commit them. |
| `scripts/core/EnemyAI.gd` | No changes — AI actions flow through the same resolve/commit paths. Verify tie-breaks remain RNG-free (stable sort by unit id / tile order); the AI must never touch RngService directly. |
| `scripts/items/ItemHandler.gd` | Item use commits an `"item"` event. No current item rolls dice; if one ever does, it becomes a `begin_event` consumer. |
| `scripts/autoloads/GameState.gd` | `take_map_snapshot()` / `restore_map_snapshot()` include `RngService.to_save_dict()` / `from_save_dict()`. (Migrates automatically when the shared snapshot contract lands; until then, add it to the existing manual snapshot.) |
| `GDD_01` | Autoload order list; CombatResolver section gains the frame-atomicity invariant (§7) and a pointer to §5. |
| `GDD_02` | Combat Resolution: replace "The roll is `randi() % 100`" with a reference to this contract. **The hit mechanic changes to the two-RN model (RULE-001):** draw two 0–99 RNs, hit when `floor((r1+r2)/2) < displayed_hit`. The old single-roll `roll < pct` rule is **Superseded by RULE-001**. |

### Migration sweep

- [ ] `grep -rn "randi\|randf" scripts/` — route every gameplay hit through
      RngService; known sites: CombatResolver hit/crit, `Unit.level_up()`
      growths, SkillHandler activation chance (Miracle), `_entropy_seed` is
      the one permitted residual.
- [ ] Add the lint test (§10 T5) in the same commit so regressions fail CI.

---

## 7. Frame-Atomicity Invariant (prerequisite, already true)

Combat resolves entirely within one frame: `resolve_combat()` builds and
rolls, `apply_combat_result()` commits. There is therefore **no mid-exchange
state to serialize, ever** — snapshots and saves only exist *between*
committed actions. This single property is what makes suspend save and rewind
cheap.

**Binding rule (add to GDD_01 → CombatResolver):** resolution must remain
frame-atomic. When Phase 3 combat animations land, the animation is
presentation replaying an already-committed result dictionary; quitting or
suspending during an animation saves the post-combat state. Presentation never
holds game state.

---

## 8. Snapshot Contract, Suspend Save, Rewind

### 8.1 Snapshot contract (shared by Retry / suspend / rewind)

Generalize `GameState.take_map_snapshot()` into a capture that returns one
`Dictionary`:

```gdscript
{
  "schema_version": 1,
  "map_id": String,
  "campaign_rules": { permadeath, leveling_method, auto_promote, pair_up, ... },
  "rng": RngService.to_save_dict(),
  "turn": {
      "turn_number": int, "active_faction_idx": int,
      "unit_states": { unit_id: int },          # READY/MOVED/DONE
      "seize_records": [...], "escape_records": [...],
      "group_eliminated_round": {...},
  },
  "party": { "gold": int, "items": [...] },
  "pair_up": PairUpRegistry state,
  "units": [ UnitData.to_save_dict(), ... ],    # MUST include the non-@export
      # runtime fields: tile_position, mastery_skills, active_modifiers,
      # skill_use_counters, damage_taken_this_map, conditions
}
```

Retry = restore checkpoint 0. The existing hand-rolled snapshot migrates onto
this; the round-trip equality test (§10 T2) is the migration's acceptance
gate.

### 8.2 Suspend save

- Trigger: Map Menu → "Suspend & Quit" (and optionally on quit-to-menu
  confirm). Only available in the free-cursor state — which, given §7, is the
  only state that exists between frames anyway.
- Storage: capture → `user://saves/suspend.json` (JSON via `FileAccess`, or
  `ConfigFile`; JSON preferred — diffable in bug reports). Single slot.
- Main Menu "Continue" un-greys when the file exists; loading routes through
  the existing launch-state plumbing (`configure_next_map` + a
  `resume_snapshot` field) so `GameMap` spawns from snapshot data instead of
  authored placements.
- Lifecycle: **kept until the map resolves**, then deleted. Reload-scumming is
  already impossible (the dice timeline is inside the file), so the classic
  delete-on-load rule buys nothing and punishes crashes. *(Logged as part of
  RNG-2's scope.)*

### 8.3 Rewind (Turnwheel)

- A checkpoint = one snapshot capture, pushed **after every `commit_event`**
  (player *and* AI actions — rewinding into a bad enemy phase is the
  headline use case) plus one at each phase boundary.
- Storage: in-memory `Array[Dictionary]` ring buffer. State is kilobytes;
  keep the whole map's history (cap at, say, 500 entries defensively). Full
  snapshots, no deltas — not worth the complexity at this size.
- Each entry carries a display label built at push time:
  `"Turn 3 · Blue · Unit_02 → Attack E3"`.
- UI: a Map Menu entry ("Rewind…") opening a scrollable list (subject to the
  UI capacity rule — scroll past N entries); confirming restores that
  checkpoint and **truncates** all later entries; the dice timeline beyond the
  restore point is recomputed from new play, never replayed.
- Restore path v1: restore snapshot data, reload `GameMap.tscn` through the
  resume path (reuses the battle-hardened Retry flow; guarantees no stale node
  state in overlays / cursor FSM / HUD). In-place restore without a scene
  reload is a later polish item, not v1.
- Charges: `CampaignRules.rewind_charges` (default 3–5; 0 = ironman /
  disabled). Charges are spent on restore, not on opening the list. Charge
  count is itself snapshotted (rewinding does not refund the charge that
  performed it).
- Permadeath interaction: none needed — rewinding before a death restores the
  unit because the whole state restores. `is_incapacitated` set by a death you
  *don't* rewind stands as today.

---

## 9. Online Model (M15 Part B) — host-authoritative

Ratified as RNG-4. The host is the single simulation authority; remote
clients are renderers + input sources for their faction.

- **Protocol shape:** remote client sends an intended action
  (`kind + record`, §3 format — the event record doubles as the wire format);
  host validates legality, resolves (`resolve_combat()` etc.), commits, and
  broadcasts the **result payload** — for combat, the existing
  `resolve_combat()` result dictionary; for other actions, the committed
  record plus any state deltas. Remote clients apply via
  `apply_combat_result()` / the matching commit paths. The two-phase
  resolve/apply split is the network seam; no new combat code is needed.
- **Resync / late join:** ship a full snapshot (§8.1) — kilobytes.
- **What this buys:** zero cross-platform determinism requirements (mixed
  Godot builds, OSes, even future versions interoperate); no float/iteration
  -order audits; the host's suspend save is the session's save.
- **What it costs:** the host can cheat (acceptable for the friendly co-op
  M15B describes); replays are result-logs or snapshot sequences rather than
  input logs (fine at this state size).
- **Dependency edge for GDD_10a §3:** C12 (M15B) → this contract's snapshot
  + result-payload seams, which subsumes the existing "C12 needs mid-battle
  suspend save" edge.

---

## 10. Test Plan (headless, `scripts/tests/`)

| # | Test | Asserts |
|---|---|---|
| T1 | **Replay determinism.** `RngService.start_map(FIXED_SEED)`; run a scripted committed-action sequence recording every outcome (hits, crits, damage, growths); restore the turn-0 checkpoint; replay the identical sequence. | Byte-identical outcome log. |
| T2 | **Snapshot round-trip.** Capture mid-sequence → mutate state arbitrarily → restore → capture again. | First and second captures are deep-equal, including `rng`, non-export UnitData fields, pair-up, turn state. |
| T3 | **Butterfly + isolation.** From one checkpoint, branch three timelines: (a) A→B; (b) Wait with another unit, then A→B; (c) C→D, then A→B. | (a) repeated twice is identical to itself; A→B's roll values differ between (a) and (b) and between (a) and (c); C→D's roll values in (c) differ from A→B's in (a) (no transfer). |
| T4 | **Equip neutrality.** From one checkpoint: A→B vs. (equip-swap twice, then A→B). | Identical outcomes — Equip must not advance the chain. |
| T5 | **Raw-RNG lint.** Scan `scripts/core/`, `scripts/skills/`, `scripts/units/`, `scripts/items/` for `randi` / `randf` outside `RngService.gd`. | Zero hits. Fails loud when a future skill bypasses the service. |
| T6 | **Suspend round-trip.** Capture → serialize to JSON → parse → restore → replay one scripted attack vs. the un-suspended branch. | Identical outcome. |
| T7 | **Canonical roll order freeze.** A fixed-seed exchange with a known hit/miss/crit pattern, asserted against literal expected values. Freezes the **two-RN draw count** (RULE-001): two hit RNs per strike (+ a crit RN only on a hit). | Any reordering of §5 — including reverting to a single hit RN, or a new skill drawing early — breaks this test by design. |

T1+T3 are the spec's teeth; T7 is the tripwire for M9 authors.

---

## 11. Versioning & Compatibility Rules

- `schema_version` in every snapshot/suspend payload. Bump on any change to
  the snapshot shape; a loader seeing a newer version refuses with a clear
  error; older versions get explicit migrations (pattern precedent: the
  `mouse_targeting → mouse_cursor` settings migration).
- The following are **save-breaking** changes and require either a schema bump
  with migration or an accepted "old suspends invalidated" release note:
  changing `_mix` / `_hash_string`, reordering §5, changing any §3 record
  format, changing which actions advance the chain.
- Mixer and string-fold are frozen as specified. Engine `hash()` and
  `String.hash()` remain banned in this subsystem permanently.
- **Save-compat baseline (RULE-001, 2026-06-13):** the two-RN hit model in §5 is
  the contract's baseline. The single-roll model it replaced **never shipped in
  `RngService`** (this contract is being updated before Build Order Step 1), so
  there is **no in-flight suspend save or fixture to migrate** — no schema bump
  is needed for the two-RN change itself. Any *future* change away from two-RN
  (or to the §5 order) is save-breaking per the rule above.

---

## 12. Build Order

Each step ships standalone value; 1–2 fit the current stabilization window.

- [x] **Step 1 — RngService + migration sweep.** Autoload, mixer, §6 code
      touches, T1/T3/T4/T5/T7. *Value: reproducible combat tests immediately;
      M9 lands on the final dice architecture.* **Done 2026-07-06** (B1-PKGA
      Slices 1a-1d).
- [x] **Step 2 — Snapshot contract.** `to_save_dict` across §8.1; migrate the
      Retry snapshot onto it; T2. *Value: Retry hardened; every future
      milestone's runtime state has one place to register.* **Done for Retry
      2026-07-06** (B1-PKGA Slice 2: `GameState._snapshot_rng` + T2); the
      generalized one-Dictionary §8.1 capture lands with `B1-SAVECODEC`.
- [ ] **Step 3 — Suspend save.** §8.2 + Continue flow + T6. *Player-facing.*
- [ ] **Step 4 — Rewind.** Checkpoint ring + Map Menu UI + charges on
      `CampaignRules` (create the stub resource here if it doesn't exist yet).
      *Player-facing; mostly UI over existing machinery.*
- [ ] **Step 5 (deferred, with M15B) — result-payload protocol** per §9.

Roadmap placement: Steps 1–2 enter Bucket B with slot "before C4 (M9a)";
Steps 3–4 are new Bucket E → Systems entries (Step 4 may be pulled forward
any time after Step 2). Add the §9 dependency edge to GDD_10a §3.
