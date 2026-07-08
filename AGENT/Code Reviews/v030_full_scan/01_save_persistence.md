# Pass 1 — Save/persistence codec

> Part of the v0.3.0 full-scan (`AGENT/Code Reviews/v030_full_scan/`).
> Boundary: `ab81a21`..`b7bcfd2`. Document-only; no production edits.

## Files read (at head `b7bcfd2`, via working tree — no production code lands after `b7bcfd2`)

- `scripts/save/SaveData.gd` (509 lines, new in delta)
- `scripts/save/SaveCodec.gd` (270 lines, new in delta)
- `scripts/autoloads/SaveManager.gd` (203 lines, new in delta)

Cross-referenced tests: `scripts/tests/test_save_data.gd`,
`test_save_codec.gd`, `test_save_manager.gd`.

## Summary

Solid, defensively-written JSON codec. Every parse path is tolerant
(`_with_defaults` / `_merge_missing` / typed coercers), legacy-name migrations are
handled (`whole/protected`→`payload_hash/schema_hash`, `party_gold`/`gold`,
`items`→`convoy.entries`, `permadeath_enabled`→`death_mode`), and the large-int RNG
fields are stored as decimal strings to dodge Godot's lossy JSON number path. No
High/Medium **correctness** bugs found in this subsystem. Findings are all Low:
one confirmed dead branch (with a needless disk read) that reaches production, one
dead helper, and duplication/robustness cleanups.

The carried **High** finding (fresh maps never call `RngService.start_map()`) is
out of scope for this pass — it lives in Pass 2 (`RngService`/`GameState`) and
Pass 5 (map startup order).

## Findings

### L1 — `has_continue_save()` has a dead if/else and does a needless disk read
`scripts/autoloads/SaveManager.gd:31-35`
```gdscript
func has_continue_save() -> bool:
    var last_played := get_last_played()               # disk read of the index
    if String(last_played.get("kind", "")) == LAST_PLAYED_SUSPEND:
        return has_suspend()
    return has_suspend()                                # identical to the if-branch
```
- **Problem:** both branches return `has_suspend()`, so the `if` is inert, and
  `get_last_played()` (which calls `load_index()` → a `FileAccess` read + JSON
  parse) is computed and discarded on every call.
- **Why it matters:** reaches production — `MainMenu.gd:42-43` calls it to decide
  whether to show *Continue*. Currently harmless (result is correct) but it is a
  wasted index read on the menu path and, more importantly, an unfinished branch:
  it reads as if it *intends* to distinguish save kinds but doesn't. A later edit
  could "fix" one branch and silently change menu behavior.
- **Root cause:** placeholder for a future multi-kind save model (`kind` field
  already exists on `last_played`) that was never differentiated.
- **Fix:** collapse to `return has_suspend()`. When a second save kind actually
  lands, reintroduce the branch *with* distinct bodies and a test. Cheap, zero risk.

### L2 — `_vector_array_from_variant()` is dead code
`scripts/save/SaveData.gd:458-467`
- **Problem:** defined but never called anywhere (`grep` across `scripts/` returns
  only the definition). `_vector_dict_or_null` (its per-element helper) *is* used by
  `_normalize_suspend`; the plural array form is orphaned.
- **Why it matters:** dead code per procedure §4B; invites confusion about whether
  some suspend/runtime field is meant to be a vector array.
- **Fix:** delete it, or wire it into whatever runtime vector-list field was
  intended (none currently normalized as one).

### L3 — `_normalize_rules()` merges then fully overwrites the same keys
`scripts/save/SaveData.gd:126-132`
```gdscript
var out := _with_defaults(root.get("rules", {}), _default_campaign()["rules"])
if source is Dictionary:
    _merge_missing(out, source)          # recursively fills missing keys from source
    for key in source.keys():
        out[key] = source[key]           # then overwrites every source key wholesale
```
- **Problem:** the `for` loop assigns `out[key] = source[key]` for every key in
  `source`, discarding the recursive result of `_merge_missing(out, source)` for
  those same keys. The `_merge_missing` call is redundant work with no observable
  effect (for keys only in defaults, they were already present from
  `_with_defaults`; for keys in source, the loop replaces them).
- **Why it matters:** confusing intent — a reader assumes the recursive merge is
  load-bearing for nested rule dicts, but it isn't; the loop is a shallow overwrite.
  If a nested rules sub-dict ever needs merge-not-replace semantics, this looks like
  it already does it but doesn't.
- **Fix:** drop the `_merge_missing(out, source)` line (the loop alone is the actual
  behavior), or, if nested-merge is desired, drop the loop and rely on
  `_merge_missing` — but not both.

### L4 — Duplicated JSON-coercion helpers across SaveData and SaveCodec
`scripts/save/SaveData.gd` (`_as_int`, `_int_dict_from_variant`,
`_string_array_from_variant`) vs `scripts/save/SaveCodec.gd` (same three, plus
`_is_json_int`)
- **Problem:** near-identical coercers are maintained in both files. `SaveData._as_int`
  (479-484) and `SaveCodec._as_int` (268-269) are functionally equivalent but
  written differently, so a future tolerance tweak (e.g. accepting `"12"` strings)
  must be made twice or the two drift.
- **Why it matters:** SaveData already depends on SaveCodec (`preload` at line 4 and
  calls `SaveCodec.vector2i_*`, `validate_inventory_entry_dict`). The primitive
  coercers are the natural shared surface.
- **Fix:** promote the coercers to `SaveCodec` static helpers and have SaveData call
  them, or extract a tiny `JsonCoerce` helper. Low priority; behavior is currently
  consistent.

### L5 — `SaveData.from_dict()` uses `load()` while GameState uses `SaveDataScript.new()`
`scripts/save/SaveData.gd:34-37` vs `scripts/autoloads/GameState.gd:448`
- **Problem:** `from_dict` does `load("res://scripts/save/SaveData.gd").new()` from
  inside the class itself, whereas `GameState` constructs the same type via the
  preloaded `SaveDataScript.new()`. A `class_name SaveData` static method can call
  `SaveData.new()` (or `new()`) directly.
- **Why it matters:** `load()` per call goes through `ResourceLoader` (cached, so no
  real perf cost) but the inconsistency is a style smell and the string path is a
  refactor hazard (rename/move breaks it silently at runtime, not compile time).
- **Fix:** use `SaveData.new()` / `new()` in `from_dict`. If it was a deliberate
  headless class-cache workaround, add a one-line comment saying so — otherwise it
  looks accidental.

### L6 — `save_suspend()` is a non-atomic single-slot write (robustness)
`scripts/autoloads/SaveManager.gd:38-56`
- **Problem:** writes directly to `suspend.json` (`FileAccess.WRITE` truncates on
  open). A crash/power-loss mid-`store_string` leaves the only suspend slot
  truncated/corrupt. Additionally, if the file write succeeds but
  `_write_last_played` returns false, `save_suspend` returns `false` while a valid
  suspend file is on disk (the load path keys off file existence, so *Continue* would
  still work — an inconsistent success/return signal).
- **Why it matters:** it is a save system; the suspend slot is the player's only
  in-progress-map recovery point. Corruption is caught on load (validate → `null`,
  reported) so it degrades to data-loss, not a crash — which caps this at Low, but
  it's the highest-value hardening in this subsystem.
- **Fix:** write to `suspend.json.tmp`, `close()`, then `DirAccess.rename` over the
  real path (atomic on the same volume). Separately, decide whether index-write
  failure should fail the whole save or just warn.

### L7 (informational) — silent drops in tolerant loaders
- `SaveCodec._dict_array_from_variant` (241-248) silently skips non-Dictionary items
  in `conditions`/`active_modifiers`; `SaveData._normalize_party` convoy fallback
  (163-166) calls `.is_empty()` on `out["convoy"]["entries"]` which would error if a
  malformed save stored `entries` as a non-Array.
- **Why it matters:** tolerant-by-design, but a corrupt array element vanishes with
  no diagnostic, and the convoy path assumes `entries` is an Array after
  `_with_defaults` (true for well-formed saves, fragile for hand-edited ones).
- **Fix:** none required; if you want defense, coerce `entries` through
  `_array_from_variant` before `.is_empty()`. Noted for completeness, not action.

## Positive observations

1. **Large-int RNG safety is handled correctly** (`SaveData.gd:195-201`,
   `_rng_int_string`) — `map_seed`/`history_hash` are stored as decimal strings so
   Godot's lossy JSON number parse can't silently corrupt the deterministic
   timeline; `_validate_rng` accepts int *or* decimal-string, matching the
   round-trip test's `{"map_seed": "12345"}` expectation.
2. **Legacy-save migrations are centralized and covered** — `whole/protected`,
   `party_gold`/`gold`/root-gold, `items`→`convoy.entries`,
   `permadeath_enabled`→`death_mode` all normalize in one place, and
   `test_save_data.gd`'s `old-save defaults` case exercises them.
3. **Clean layering** — `SaveData`/`SaveCodec` stay pure `RefCounted` with zero I/O;
   `SaveManager` is the sole owner of `user://` paths and the only place
   `FileAccess`/`DirAccess` appear, with `_data_manager()` gated on `is_inside_tree()`
   so headless `.new()` construction stays safe.

## Verdict

No blocker in this subsystem. All findings Low; L1 (dead branch + needless read on
the menu path) and L6 (non-atomic suspend write) are the two worth acting on before
v0.3.0, both low-risk. Subsystem quality is high.
