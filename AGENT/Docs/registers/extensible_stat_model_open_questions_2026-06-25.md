---
Type: register
Status: OPEN
Last verified: 2026-06-27
Register: STM-1..5
Resolved-in: —
---

# Author-Extensible Stat Model — Migration Plan + Open Questions (PINNED, not yet firmed)

**Started:** 2026-06-25 (session 2026-06-25l). **Status: a PINNED EXPLORATION**, surfaced from the
battalion pass (`[BAT-6]` rank + a "command/leadership" question) and a "do we have a Charisma stat"
question. Captures the **migration plan** for evolving the stat model so campaign authors can add new
stats, **with the legacy base stats kept for comparability**. **Not owner-ratified** — the decisions
below are *recommended directions* to be confirmed when this is picked up in the define-all sweep /
scheduling pass (atlas §3b). Owner = a new foundation **F14**; rides F1 (schema) + F4 (`CampaignRules`).
Branch `docs-reorg-2026-06-23`.

**Thesis.** The stat model is **already half data-driven**, so author-extensible stats are an
*evolution, not a rewrite*. The asymmetry: the **read path is string-keyed** and **growths/caps/wexp are
already `Dictionary`s**, but **base-stat storage is hardcoded `@export` fields** and the **stat list is
enumerated as literals in ~5 places**. Closing that asymmetry is the whole job.

**Pattern:** mirrors `[IEQ]`/`[PXP]` (a foundation data-model firming). Legend: **[OPEN]** /
**[DIRECTION]** (recommended, pending ratification).

---

## 1. State today (code-grounded)
- **No Charisma / Charm / Leadership / Command stat exists.** Base combat stats = `strength`, `magic`,
  `defense`, `resistance`, `skill`, `speed`, `luck` (+ `max_hp`/`hp`, `movement`, `constitution`,
  `line_of_sight`), all hardcoded `@export var` on `UnitData.gd` and `ClassData.gd` (`base_*`).
- **Read path is string-keyed.** `Unit.get_effective_stat(name)` (`Unit.gd:300`) does
  `data.get(name)` + modifiers matched by `mod["stat"] == name`. Combat/skills already address stats by
  string — **any** UnitData property name resolves.
- **Growths / caps / wexp are already dicts.** `ClassData.player_growth_rates` / `enemy_growth_rates` /
  `stat_caps` and `UnitData.growth_rates` / `weapon_wexp` are keyed by stat-name string.
- **The stat *list* is hardcoded in ~5 canonical spots:** `ClassData.STAT_KEYS` (`ClassData.gd:45`),
  `Unit._GROWTH_STATS` (`Unit.gd:821`, used at 783/1022/1083/1109/1125), `LevelUpScreen._STAT_NAMES`,
  `StatBreakdown.STAT_LABELS`, and `DataManager` validation. The reclass/promotion stat-copy table
  (`Unit.gd:~1050`) maps `base_strength → strength`-style field pairs.
- **`CampaignRules` exists** (`scripts/resources/CampaignRules.gd`) — the author-config home for a stat
  registry (F4 "named author profile" mechanism).

## 2. The asks this register answers

### [STM-1] Charisma-equivalent stat — does not exist; adding ONE is moderate/mechanical — **DIRECTION**
None exists. Adding a single *known* stat (e.g. `charisma`) is bounded but touches ~8 spots **because
storage + enumeration are hardcoded** (the math is free — read path/caps/growths are already
string/dict-driven the moment the key exists):
1. `UnitData`: `@export var charisma` · `ClassData`: `base_charisma` + add `"charisma"` to `STAT_KEYS`.
2. `Unit.gd`: add to `_GROWTH_STATS` (if it levels) + the reclass/promotion copy table (`~1050`).
3. `DataManager` validation · `LevelUpScreen._STAT_NAMES` · `StatBreakdown.STAT_LABELS`.
4. Hardcoded-stat-list tests · GDD docs (DoD#1).
**Effort: ~1 focused day + tests + docs.** The grep for the ~5 hardcoded lists is the checklist.

### [STM-2] Battalion "command/leadership" check — cheap, rides existing rails — **DIRECTION**
The canonical FE/3H split, both supported:
- **Charm = a stat** → answered by `[STM-1]` (or `[STM-4]` as author data). Battalion behavior reads
  `host.get_effective_stat("charisma")` — trivial.
- **Authority = a proficiency rank** → a `command_wexp` counter run through the **existing
  `weapon_rank_for_wexp` threshold helpers** (the exact reuse `[BAT-6]` already specified for battalion
  rank). Gambit power / passive-bonus magnitude / endurance scales with the host's command rank.
**The cost is shared, not new:** earning a *non-weapon* proficiency is the **`[AGT §6]` / A5
non-combat-proficiency-EXP gap** (`add_wexp` is weapon-track keyed). **Consuming** the rank is hours;
**earning** it rides that pin. Battalion-side consumption is `get` + a threshold lookup.

### [STM-3] Author-defined stats — the evolution (legacy base stats stay) — **DIRECTION (the migration plan)**
Evolution, not rewrite, because the read path + caps/growths are already data-driven. Four steps:
1. **Parallel dict layer.** `UnitData.extra_stats: Dictionary` (name→value) + `ClassData` extra-stat
   bases/caps/growths (the dict shape `stat_caps`/growths already use).
2. **A stat registry on `CampaignRules`/manifest.** Authors declare
   `[{id, display_name, default, grows?, capped?, combat_role}]` (F4 named-profile mechanism).
3. **One read-path change.** `get_effective_stat` falls back to `extra_stats.get(name)` when the field is
   absent → legacy fields and author stats become uniform to **every** existing reader for free.
4. **Replace the ~5 hardcoded enumerations** (`STAT_KEYS`, `_GROWTH_STATS`, the UI label dicts,
   validation) with `legacy_stats + registry.stats`; display / level-up / growth-rolls iterate the
   registry.
**Legacy base stats stay as typed fields** (comparability + zero migration of existing `.tres`); the
read path unifies them with author stats. **Effort: moderate-to-large — a foundation pass (several
days).**
**Gotchas:**
- **Direct field access (`data.strength`) bypasses the registry** — fine for legacy stats, but author
  stats must *only* be addressed by name. Add a `check_docs`/lint guard banning **new** direct base-stat
  field reads (steer to `get_effective_stat`).
- **Stable iteration order** for the registry (display order + deterministic growth-roll RNG).
- **Save/schema:** `extra_stats` + the registry are **new persistent surface** → reserve at the F1 lock
  (see §3). This makes STM a member of the define-all sweep ahead of F1.

### [STM-4] Sequencing — do the evolution first if author-stats is wanted at all — **OPEN (owner call at scheduling)**
If author-defined stats is on the roadmap *at all*, do **`[STM-3]` first** — then **Charisma collapses to
data** (an author adds a `charisma` row to the registry; **zero engine change**), and `[STM-1]`'s ~8
hardcoded touch-points never get paid. If author-stats is *not* wanted, hardcode Charisma via `[STM-1]`.
**Recommendation: STM-3-then-charisma-as-data**, because hardcoding Charisma now and adding extensibility
later means doing the stat-list surgery twice. **Owner call, deferred to the prioritization/define-all
sweep.**

### [STM-5] Missing / undefined stat-information handling — **OPEN (look-into, owner 2026-06-27d)**
Once stats are author-data (STM-3), the engine must define **what happens when stat information is
absent** — a real robustness surface the migration plan only touches via the STM-3 read-path fallback.
Facets to firm at the STM walk:
- **Registered stat, missing per-entity value** (a unit/`ClassData`/item has no value for a stat that the
  registry *does* declare) → **fall back to the registry `default`** (STM-3 read-path); missing **growth**
  defaults to `0`, missing **cap** to uncapped (`-1`) — matches today's defaults. *Soft, never an error.*
- **Reference to an UNREGISTERED stat** (a `[REQ-16]` term, skill/effect, `[TCV-3]` tag-scoped modifier,
  or UI label names a stat not in `legacy_stats + registry.stats`) → **hard load-time validation error**
  via the existing `DataManager` seam (`_check_stat_dict` / `_VALID_*`), not a silent runtime `0`. **Fail
  loud at author time.** (The recommended policy split: *registered-but-unset = soft default; referenced-
  but-unregistered = hard error.*)
- **Save migration** — a save predating a stat's addition: absent key → registry default on load; a stat
  later *removed* from the registry → stored values are ignored/dropped, never a crash.
- **Cross-pack / imported content** — the campaign content model is **self-contained packs**, so within a
  pack the registry is authoritative; an imported unit/item referencing a stat the active pack lacks hits
  the same validation policy (reject or map at import).
- **UI** — undefined stats in a campaign that doesn't define them must **not** render blank rows; display
  iterates the active registry only.
- **Composition note:** `[TCV-3]` (custom-variable tag-scoped stat effects) and `[REQ-16]` (stat value
  terms) are the main *consumers* that can name a stat — they inherit this policy rather than defining
  their own; walk them aware of STM-5.

---

## 3. F1 schema implications (reserve at the Phase-B lock)
- **`UnitData.extra_stats`** (name→value author-stat store) — new persistent per-unit field.
- **The `CampaignRules` stat registry** (author stat definitions) — campaign data, lock its shape.
- (`ClassData` extra-stat bases/caps/growths are data-def, not per-unit save state.)
- Coordinate with F3/`[PXP]` if a **command/non-weapon proficiency track** lands (`[STM-2]`) — that track
  is the `[AGT §6]`/A5 proficiency-EXP generalization, not a separate reserve.

## 4. Effort summary
| Ask | Scope | Effort |
|---|---|---|
| `[STM-2]` battalion *consumes* a command stat/rank | `get` + threshold lookup | hours (rails exist) |
| `[STM-1]` add ONE known stat (Charisma) | ~8 hardcoded touch-points; math free | ~1 day + tests/docs |
| `[STM-3]` author-extensible stat model | dict layer + registry + read fallback + de-hardcode ~5 lists | several days (foundation pass) |
| earn a non-weapon (command) proficiency | the `[AGT §6]`/A5 gap | shared, not new |

## 5. Reconcile-don't-relitigate
- The model is **already half data-driven** — do **not** "rewrite the stat system"; evolve it (dict layer
  + registry + read-path fallback). Legacy fields **stay**.
- Charisma (a **stat**) and Command/Authority (a **proficiency rank**) are **different axes** — `[STM-1]`
  /`[STM-4]` vs the `[BAT-6]`/`[AGT §6]` proficiency path. Don't conflate.
- This is a **pin**, not a firming — ratify at the define-all sweep before any build.
