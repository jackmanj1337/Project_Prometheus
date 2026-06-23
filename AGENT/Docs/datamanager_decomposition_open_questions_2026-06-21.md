# `DataManager._ready()` Decomposition (§5) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. **Pure refactor** — no player-facing behavior
change, so the register is short (sequencing/safety, not design).
**Source:** `planning_backlog_2026-06-20.md` §5 ("named phases sketched"); session note
2026-06-21c Tier 2 #8.
**Code:** `scripts/autoloads/DataManager.gd`. **Tests:** `test_data_manager.gd`,
`test_data_layer.gd`.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

`DataManager._ready()` is short and already mostly delegated:
```
_load_directory(classes) / weapons / items / skills
for skill in _skills: skill.validate()
for err in collect_validation_errors(...): push_error(err)
for err in collect_map_registry_validation_errors(...): push_error(err)
```
The **bulk of the file is already static, pure, testable validators** — this refactor's
hard work is largely done:
- `collect_validation_errors` → `_check_class_refs` / `_check_skill_refs` /
  `_check_weapon_refs` / `_check_item_refs` (each pure, returns `Array[String]`).
- `collect_map_registry_validation_errors` → `_validate_map_registry_entry` →
  `collect_map_data_validation_errors` → `_validate_condition_dict` /
  `_validate_objective_condition`.
- `register_loaded_resource` returns a `LoadResult` enum (already de-stringified per a prior
  code review).

So the "decomposition" is **not** untangling a monolith — it's naming the **load phase vs
validate phase vs report phase** as explicit, individually testable steps, and deciding
whether the in-progress `skill.validate()` loop and the two `push_error` loops should be
unified.

> **FORWARD DEP — campaign-overlay loading (campaign-PACK branch I3, direction set 2026-06-23).**
> The campaign-content model (`planning_backlog_2026-06-20.md` §2b branch I3) is **base-load +
> campaign-overlay**: core defaults from `res://data/`, then a selected campaign's content overlaid
> (include-subset / override-by-id / add-new) on campaign-select — *not* the boot-time global-only
> load today. **Keep the `_load_all()` phase parameterizable** (a load source/dir + an overlay pass),
> so this decomposition doesn't bake in global-only boot loading. No need to build the overlay now;
> just don't preclude it.

## 2. Draft plan

Extract `_ready()` into three named phases, each a function:
1. **`_load_all()`** — the four `_load_directory` calls (populates `_classes/_weapons/
   _items/_skills`). Already exists as calls; wrap them. **(Leave room for a campaign-overlay
   source per the forward-dep note above.)**
2. **`_validate_all() -> Array[String]`** — folds the `skill.validate()` loop +
   `collect_validation_errors` + `collect_map_registry_validation_errors` into ONE pure
   function returning all errors. Today the skill `validate()` loop push_errors *separately*
   from the collected list — unifying makes one error channel.
3. **`_report(errors)`** — the single `for err: push_error` sink.

`_ready()` becomes: `_load_all(); _report(_validate_all())`. This is a behavior-preserving
restructure; the existing static validators are untouched.

## 3. Open questions register

### [DMR-1] Scope: phase-naming only, or also unify the error channels?  **[OPEN]**
- **A — Phase-naming + unify all errors into one collected list** (`_validate_all`). The
  `skill.validate()` loop (which push_errors directly + returns bool) gets folded so every
  boot error flows through one `_report` sink — easier to test ("assert zero errors for good
  data") and consistent severity.
- **B — Phase-naming only**; leave `skill.validate()` push_erroring on its own path.
- **Rec: A** — one error channel is the real win: a single `_validate_all()` that a test can
  assert returns `[]` for valid fixtures and the right messages for broken ones. `skill.
  validate()` currently splits the channel; folding it is the cleanup worth doing. Keep
  `skill.validate()`'s own bool return for other callers (don't delete it).
- **Resolution:** _[OPEN]_

### [DMR-2] `_load_directory` push_error coupling  **[OPEN]**
`_load_directory` push_errors inline (load failures, dup ids) rather than returning them, so
load-phase errors don't flow through `_validate_all`.
- **A — Leave load errors inline** (a failed *load* is a different class of failure than a
  *validation* error — it must fail at the I/O point). Phases stay: load (fails loud inline)
  → validate (collected) → report.
- **B — Make `_load_all` also return collected errors** for a fully-unified channel.
- **Rec: A** — load failures (missing dir, dup id) are I/O/integrity faults best surfaced at
  the load site; validation is cross-reference logic. Keeping them separate mirrors the
  existing `LoadResult` enum design and avoids over-unifying. The phase boundary is the
  natural seam.
- **Resolution:** _[OPEN]_

### [DMR-3] Test additions  **[OPEN]**
- **A — Add a `_validate_all()` round-trip test** (good fixtures → `[]`; one broken fixture
  per validator category → expected message). Low effort, high regression value.
- **B — Rely on the existing `collect_*` tests** (already cover the sub-validators).
- **Rec: A** — the existing tests cover the *sub*-validators; a `_validate_all` test pins the
  *composition* (that all phases run and nothing is dropped when they're stitched together).
  This is the safety net that makes the refactor confidently behavior-preserving.
- **Resolution:** _[OPEN]_

## 4. Notes
- **Risk: low.** No data, schema, or player-facing change; the static validators are already
  the right shape. The only behavioral subtlety is the `skill.validate()` channel ([DMR-1]).
- **Sequencing:** independent of everything else; a good "palette-cleanser" between heavier
  planning items. No upstream blocker.
- **DoD#1:** no GDD section changes behavior, so no roadmap status flip needed — this is an
  internal refactor (note it in the session note only).
