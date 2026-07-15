---
Type: plan
Status: Active - implementation plan
Last verified: 2026-06-29
---

# Stat Registry Implementation Plan

**Started:** 2026-06-29.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
row `B3-STAT-REGISTRY`.

**Purpose.** Make stat names author-extensible registry data while preserving
the existing developer preset stats and save compatibility.

## Recommendation

Use the legacy-field plus extension-dictionary model.

Legacy fields stay on `UnitData` and `ClassData` for editor ergonomics and
existing data compatibility. Author-defined stats live in dictionaries and are
read through the same stat API. This avoids a full data rewrite while removing
the hardcoded stat-list bottleneck.

## Target Model

Add a `StatRegistry` seeded by developer preset entries. Each entry declares:

```text
id
label_key
short_label
display_order
default_value
storage_key
class_base_key
grows
capped
cap_default
required_by
docs_text
```

The developer preset includes existing progression/combat stats:

```text
hp, strength, magic, defense, resistance, skill, speed, luck
```

It should also register existing non-growth tactical stats:

```text
movement, constitution, line_of_sight
```

`hp` is the progression stat and maps to `UnitData.max_hp`; live `UnitData.hp`
remains mutable health state, not a growth stat.

## Missing Stat Policy

All runtime stat readers should go through a registry-aware stat API. If a reader
asks for a stat that does not exist on the unit, it returns `0` instead of
crashing.

Policy split:

- Registered stat, missing value on a unit or class: use the registry
  `default_value`.
- Registered stat, missing growth: use `0`.
- Registered stat, missing cap: use `cap_default` (`-1` for uncapped unless the
  stat entry says otherwise).
- Unregistered stat read at runtime: return `0`.
- Authored data that references an unregistered stat: fail load validation.

The `0` fallback is a runtime safety net, not permission for typoed content.

## Required-System Notes

Some systems may behave badly if their expected preset stats are missing, even
though stat readers return `0`:

- Combat formulas expect strength, magic, defense, resistance, skill, speed, and
  luck.
- Level-up and promotion expect hp plus the growth-enabled stats.
- Pathfinding and class display expect movement.
- Carry, shove, rescue, and weight-like systems expect constitution when those
  systems are enabled.
- Fog and sight systems expect line_of_sight when those systems are enabled.

Use `required_by` metadata so validation can report a clear error or warning
when a campaign disables or omits a stat needed by an enabled system.

## Implementation Steps

1. **Reserve the schema shape.**
   - Add F1 rows for `UnitData.extra_stats` and any save-visible registry
     selection.
   - Keep legacy fields in place.
   - Add `ClassData.extra_stat_bases: Dictionary` for class bases that do not
     have typed legacy fields.

2. **Build the registry service.**
   - Seed developer presets from existing stat names.
   - Expose deterministic helpers:
     `stat_ids()`, `growth_stat_ids()`, `display_stat_ids()`,
     `has_stat(id)`, `definition(id)`.
   - Preserve explicit display order.

3. **Centralize stat access.**
   - Update `Unit.get_effective_stat(stat_id)` to:
     read legacy storage when present, then `extra_stats`, then registry default,
     then `0`.
   - Add helper APIs for base reads and writes so promotion/reclass/growth code
     does not call `data.get()` or direct fields for author stats.
   - Update every stat reader to use the helper path.

4. **Replace hardcoded iterators.**
   - Replace `ClassData.STAT_KEYS`, `Unit._GROWTH_STATS`,
     `LevelUpScreen._STAT_NAMES`, `StatBreakdown.STAT_LABELS`, promotion loops,
     reclass loops, and validation loops with registry iteration.
   - Keep a small legacy map only for storage keys, such as `hp -> max_hp` and
     `strength -> strength`.

5. **Update validation.**
   - `DataManager` validates unknown stat keys in growth, cap, modifier, skill,
     requirement, and formula data against the registry.
   - Missing registered stat values default per policy.
   - Add or extend a `check_docs.py`/lint guard so new gameplay code does not add
     direct base-stat reads when `get_effective_stat()` or the stat API is
     required.

6. **Convert UI and authoring display.**
   - Character sheet, level-up screen, promotion screen, reclass screen, More
     Info, and stat breakdown display iterate registry metadata.
   - UI hides stats absent from the active registry unless a debug view is asking
     for raw data.

7. **Test the migration.**
   - Existing unit-stat, promotion, reclass, stat-breakdown, and combat tests
     pass under the developer preset.
   - Add one custom stat fixture, such as `charisma`, with base, growth, cap, UI
     label, and modifier coverage.
   - Add tests for missing registered value, missing growth, missing cap,
     unregistered runtime read returning `0`, and authored unregistered reference
     failing validation.

## Options Considered

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Legacy fields plus `extra_stats` | Smallest migration, keeps Godot inspector usability, preserves saves. | Requires a legacy storage map and discipline around stat access helpers. | Use this. |
| Dictionary-only stats | Clean uniform model after migration. | Large data/save/UI rewrite; high regression risk for little immediate gain. | Defer unless the legacy map becomes a real burden. |
| Core stats closed, extension stats open | Lower risk for combat-critical stats. | Reintroduces a closed/open split authors must understand; still needs most registry plumbing. | Avoid unless validation proves required-system metadata is not enough. |

## DoD

- Adding `charisma` as data requires no engine switch edit.
- Runtime stat reads for missing ids return `0`.
- Authored references to unknown stat ids fail validation.
- Existing behavior under developer presets is unchanged.
- `check_docs.py` or an equivalent lint catches new hardcoded stat-list drift.
