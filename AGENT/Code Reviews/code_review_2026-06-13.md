# Code Review — 2026-06-13 (whole codebase)

**Scope:** all ~96 `.gd` files under `scripts/` (12.7k src LOC / 11k test LOC).
**Process:** `AGENT/Docs/code_review_instructions.txt`. Document-only — no code changed.
**Reference spec:** the consolidated GDD (`GDD_Feature_Index.md` → owning chapters) was
used as the contract to check code against; see §6 for how well it held up.

---

## 1. Executive Summary

**Code quality rating: 8 / 10.**

This is a mature, defensively-written, heavily-tested GDScript codebase. Combat
resolution — the rule-dense core — is excellent: a single guarded strike loop, a
side-effect-free preview path, and careful skill-trigger ordering. The two standing
debts are both already tracked in the GDD: combat/skill/level-up RNG runs on the global
`randi()` (no deterministic `RngService` yet), and `DataManager._ready()` has grown into
a ~525-line monolith. Neither is a correctness bug; both are structural.

---

## 2. Issues Found

### [Medium] `DataManager._ready()` is a ~525-line monolith
- **File & Line:** `scripts/autoloads/DataManager.gd:28-553` (next function at :554).
- **Problem:** A single `_ready()` loads every resource directory, validates each
  schema, runs cross-reference checks (effectiveness tags, unit_id uniqueness across
  roster + enemy placements), and builds the default roster. One function with many
  responsibilities is hard to read, and none of its phases can be unit-tested in
  isolation — a test must boot the whole autoload.
- **Root cause:** load + validate logic accreted phase-by-phase as data types were
  added, never extracted.
- **Recommended fix:** extract the phases into private helpers called by `_ready()` —
  e.g. `_load_all_resources()`, `_validate_cross_references()`, `_build_default_roster()`,
  `_dedup_unit_ids()`. Pure document/data functions become directly testable. The
  helper functions below line 554 show the file already favors this shape.
- **Tradeoffs:** a mechanical refactor touching startup; needs the full suite green
  after (it is wired into pre-commit) and care that load order is preserved.

### [Medium] Combat/skill/level-up RNG uses global `randi()` — not deterministic
- **File & Line:** `CombatResolver.gd:444,451`; `SkillHandler.gd:189`;
  `Unit.gd:1069`.
- **Problem:** Hit, crit, skill-proc, and per-stat growth rolls all call the engine
  global `randi() % 100`. This is non-seedable and non-reproducible, which blocks
  deterministic replay, mid-battle suspend/restore, and host-authoritative online — all
  three are on the roadmap. The call sites are already at four and will multiply as
  skills/content land.
- **Root cause:** the deterministic `RngService` (GDD_01 §Determinism "Package A") is
  designed but not yet built; current code is the documented project baseline.
- **Recommended fix:** land the thin `RngService` wrapper now and route these four call
  sites through it (`rng.roll(100)` etc.) even before the full chained-seed model, so
  new code can't reintroduce a bare `randi()`. This is exactly RNG-1 / SET-001's intent.
- **Tradeoffs:** none functional today; it's pre-work for the determinism milestone. Do
  it before more proc-skills add call sites, not after.

### [Low] Manual snapshot field lists couple `UnitData` ↔ `GameState`
- **File & Line:** `GameState.gd:485-526` (`_snapshot_unit_data`) and `:529-561`
  (`_restore_unit_data`).
- **Problem:** Both functions enumerate UnitData fields by hand. A new mutable field
  added to `UnitData` but not to *both* lists silently fails to roll back on Retry —
  a quiet correctness bug class.
- **Root cause:** explicit field lists (chosen deliberately — the comments explain the
  deep-copy and forward-compat-default care, which is genuinely good).
- **Recommended fix:** keep the explicit lists (they're readable and the `.get()`
  defaults are correct), but treat `test_snapshot_coverage.gd` as the load-bearing guard
  it is — every new mutable UnitData field must be added there too. Consider a comment
  on the `UnitData` field declarations pointing at both snapshot lists.
- **Tradeoffs:** a reflection-based snapshot would remove the coupling but lose the
  explicit forward-compat defaults; not worth it now.

### [Low] `compute_damage` no-context path can't see Giantkiller (4×)
- **File & Line:** `CombatResolver.gd:336-337`.
- **Problem:** When called without a context dict (direct test calls), effectiveness
  defaults to `3.0 if _is_effective else 1.0` — the 4× Giantkiller branch in
  `_get_effectiveness_multiplier` is unreachable. A test exercising effectiveness via
  this path silently under-tests the 4× case.
- **Root cause:** documented backward-compat shortcut for direct calls.
- **Recommended fix:** ensure the 4× path is covered through the context-carrying call
  (it is, in the live flow); add a test note so no one assumes the no-context path is
  the full model.
- **Tradeoffs:** trivial; documentation/test-hygiene only.

---

## 3. Positive Observations

1. **Autoload-access discipline is consistent.** Autoload scripts reach other autoloads
   via `get_node_or_null("/root/X")` + `.call()/.get()`, never bare identifiers — the
   exact pattern that prevents headless `--script` compile failures. A grep across the
   autoload/handler scripts found zero violations (only comments mention the names).
2. **CombatResolver's single guarded strike loop** (`_run_strike_series`,
   `CombatResolver.gd:627`) centralizes the "is either side dead? / did the weapon
   break?" rule so it cannot drift across the four strike series (attacker, counter,
   vantage, follow-up). This is the right abstraction for the trickiest part of combat.
3. **Side-effect-free preview.** `preview_combat` snapshots the mutable UnitData fields
   that skills touch, runs the real modifier pass for an accurate forecast, then restores
   — and `dry_run` stops a preview from burning limited-use skill counters. Subtle and
   correct.
4. **Defensive throughout.** ~48 `push_error` / 27 `push_warning`, `.get()` defaults,
   `has_method` guards, and only **2** TODOs and **2** stray `print()` across 12.7k src
   LOC. Stubbed skills `push_warning` loudly rather than failing silently.
5. **Test coverage is real.** ~11k test LOC (≈0.86× src), 38 suites, and a dedicated
   `test_snapshot_coverage.gd` that guards the manual snapshot lists in §2's Low finding.

---

## 4. Architectural Observations

- **RNG centralization is the highest-leverage next step.** It's not just tech debt —
  it gates determinism, save/rewind, and online, which are all roadmapped. Every week
  without `RngService` adds bare-`randi()` call sites to migrate later.
- **DataManager is doing two jobs:** runtime data access (the small helpers at the
  bottom) and one-shot startup load+validate (the monolith `_ready`). Splitting the
  startup pipeline into named, testable phases would clarify both.
- **GameState ↔ UnitData snapshot coupling** is acceptable given the coverage test, but
  it's the kind of hand-maintained mirror that rots; keep the test exhaustive.

## 5. Prioritized Action Plan

1. **Land `RngService` and route the 4 `randi()` call sites through it** (Medium #2).
   Highest impact — unblocks determinism work and stops call-site proliferation.
2. **Decompose `DataManager._ready()` into testable phases** (Medium #1). Readability +
   unit-testable load/validate.
3. **Document the snapshot-coverage contract** on `UnitData` fields + keep
   `test_snapshot_coverage.gd` exhaustive (Low #3).
4. **Add a test note / coverage for the Giantkiller 4× path** (Low #4).

---

## 6. Documentation Field-Test (testing the new GDD as a review spec)

This review used the consolidated docs as the contract. Verdict: **they held up well.**

- **Routing worked.** `GDD_Feature_Index.md` → "Combat calculations & RNG" pointed to
  GDD_02 §Combat Resolution & GDD_01 §Determinism, with code anchors `CombatResolver.gd`
  and `DataManager.get_weapon_triangle_result` — both real, both the right files.
- **Every concrete spec claim I checked matched the code:**
  - `randi()` single-roll hit = **project Implemented**, two-RN = **Target** → code uses
    `randi() % 100` (`CombatResolver.gd:444`). ✓
  - Weapon triangle flat **±10 Hit / ±2 Damage** (GDD_04) → `_triangle_accuracy`/
    `_triangle_damage` return exactly ±10 / ±2. ✓
  - Crit **×3** (GDD_04) → `base_dmg * 3` (`CombatResolver.gd:452`). ✓
  - AI profiles `basic/passive/healer` (GDD_08) → `EnemyAI.gd` + `DataManager` validator. ✓
- **Split-status labels were predictive:** the things the GDD marks "Target design" are
  exactly the things not yet in code (RngService, rank-scaled triangle), and the
  "Implemented" lines all matched shipped behavior. The DOC-013 project/corpus rewrite
  reads cleanly in context.
- **One gap:** many feature-index rows still show `Automated coverage TBD (S3)`, so the
  index routed me to the code but not always to the owning test suite. Populating those
  cells would make it a complete review map.

Net: the documentation is accurate enough to review code against — a strong result for
a freshly-consolidated doc set. `check_docs.py` (8 checks) is green.
