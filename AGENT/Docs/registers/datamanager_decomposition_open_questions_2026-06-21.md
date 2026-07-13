---
Type: register
Status: RESOLVED 2026-06-23
Last verified: 2026-06-23
Register: DMR-1..4
Resolved-in: 2026-06-23d
---

# `DataManager._ready()` Decomposition (§5) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Last verified:** 2026-06-23
**Status:** Register RESOLVED 2026-06-23 (`[DMR-1..4]`). Mostly a **pure refactor** (no player-facing
behavior change); **[DMR-4]** adds the per-campaign **load seam** — still behavior-preserving
(the new load-source param defaults to today's `res://data/` → identical boot; `select_campaign()` is new but
unused until I3/§2 wires it). Build-ready.

> **AMENDED post-resolution (2026-06-23, ICO reframe).** `[DMR-4]` was resolved (2026-06-23d) as a
> **base+overlay merge** seam; the owner then reframed the content model to **SELF-CONTAINED** (`[ICO-1..6]`
> RESOLVED 2026-06-23e, `campaign_content_overlay_open_questions_2026-06-23.md`). The seam survives but is now
> a **replace-load, NOT a merge**: `select_campaign(c)` does `_load_all(c.content_dir)` and *replaces* the
> content dicts — there is **no `_apply_overlay()` merge engine to build**. The overlay/merge wording in §1–§3
> below is retained for provenance; **read it as replace-load.** Heaviest build is now the ICO-5 first-run
> seed-copy (`res://`→`user://`) + `user://` enumeration, not a merge engine.
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

**Extended by [DMR-4] (RESOLVED → A):** `_load_all()` gains an `overlay_source := null` param and
an `_apply_overlay()` stub; a new public `select_campaign(campaign)` does
`_load_all(DEFAULTS, campaign.content_dir)` + id-cache re-resolve. `_ready()` still calls
`_load_all()` with no overlay, so boot is unchanged. The merge *semantics* inside `_apply_overlay()`
are the I3 content-overlay register's job (sub-decisions a–e), not this refactor's.

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
- **Resolution:** **A (2026-06-23).** Unify into one collected channel — `_validate_all() ->
  Array[String]` folds the `skill.validate()` loop + `collect_validation_errors` +
  `collect_map_registry_validation_errors`, and a single `_report()` sink push_errors them.
  `skill.validate()`'s bool return is kept for its other callers (not deleted).

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
- **Resolution:** **A (2026-06-23).** Load errors stay surfaced inline at the I/O site
  (`_load_directory`'s existing `push_error` + `LoadResult`); only the cross-reference
  *validation* phase feeds the unified `_validate_all()` channel. Two failure classes kept
  distinct on purpose. (Forward note: when [DMR-4]'s overlay load lands, an overlay-load
  failure is the same *load*-class fault — surfaced inline too, not via `_validate_all`.)

### [DMR-3] Test additions  **[OPEN]**
- **A — Add a `_validate_all()` round-trip test** (good fixtures → `[]`; one broken fixture
  per validator category → expected message). Low effort, high regression value.
- **B — Rely on the existing `collect_*` tests** (already cover the sub-validators).
- **Rec: A** — the existing tests cover the *sub*-validators; a `_validate_all` test pins the
  *composition* (that all phases run and nothing is dropped when they're stitched together).
  This is the safety net that makes the refactor confidently behavior-preserving.
- **Resolution:** **A (2026-06-23).** Add a `_validate_all()` composition test (good fixtures →
  `[]`; one broken fixture per validator category → its expected message) to pin the phase
  stitching. **Plus a [DMR-4] seam test:** `_load_all(base, null)` is byte-identical to today's
  boot, and `_apply_overlay()` is a no-op stub call (asserts the seam is reached without changing
  resolution) — see [DMR-4].

### [DMR-4] Campaign base+overlay load seam — how far to design now  **[RESOLVED → A]**
The L2 keystone the campaign **designer** side resolves through (framing doc
`campaign_save_expectations_and_foundations_2026-06-23.md`): the save resolves ids against
`defaults ∪ campaign overlay`, but `DataManager` only loads global `res://data/` at boot today. <!-- retired-vocabulary: historical-quotation -->
How much of the overlay *load path* do we lock in this refactor?
- **A — Parameterize the seam now; defer merge semantics to I3.** `_load_all(base_source,
  overlay_source := null)` + a `select_campaign(campaign)` / re-resolve entry point that calls
  `_load_all(DEFAULTS, campaign.content_dir)` + an `_apply_overlay(overlay)` **stub seam**. Makes
  the `defaults ∪ overlay` load path real and testable; the merge *rules* (include-subset /
  override-by-id / exclude / id-namespace / default-content versioning) are filled by the I3
  content-overlay register (sub-decisions a–e), not here.
- **B — Rename-only, preclude nothing.** Keep "don't bake in global-only" as a comment; design the
  whole overlay (seam + semantics) later in I3. L2 stays a note, not a real seam.
- **C — Full overlay design now.** Define the merge semantics here too — but those are the
  unratified I3 sub-decisions a–e; doing them here front-runs the content-model walk (out of order).
- **Rec: A** — locks the **load-path shape** (where the overlay is applied + the re-resolve trigger)
  so I3 only has to fill `_apply_overlay()`'s body, while staying behavior-preserving today
  (`overlay_source` null default = identical boot; `select_campaign()` unused until §2/I3 wires it).
  Clean DMR-owns-plumbing / I3-owns-semantics split.
- **Resolution:** **A (2026-06-23).** Parameterize the seam now, defer merge semantics to I3.
  **Division of labor locked:** DMR owns the load-path *shape* — `_load_all(base, overlay=null)`,
  `select_campaign()`/re-resolve entry, and the `_apply_overlay()` stub; **I3 owns the merge
  *semantics*** (a–e). **Build deltas over the pure refactor:** (1) `_load_all` gains the
  `overlay_source` param (null-default, behavior-preserving); (2) a new `select_campaign(campaign)`
  public entry (load DEFAULTS, then overlay, then re-resolve id caches) — present but uncalled in
  MVP until §2's campaign-select / I3 wire it; (3) `_apply_overlay()` ships as a documented no-op
  stub that pushes a clear error if handed a non-empty overlay (so a premature caller fails loud,
  not silently). **Forward dep:** `campaign.content_dir` / overlay source shape is an I3 + §2
  `CampaignData` field — DMR only assumes "a source the loader can enumerate," not its format.
- **UPDATE 2026-06-23 — `_apply_overlay()` MERGE superseded by a REPLACE-LOAD** (I3 register
  `campaign_content_overlay_open_questions_2026-06-23.md` [ICO-1] = **self-contained**, owner reframe):
  campaigns are self-contained (no `defaults ∪ overlay`), so `select_campaign()` *replaces* the content
  dicts with the campaign's complete set rather than merging an overlay. The seam DMR-4 stood up
  (`_load_all(source)` parameterization + `select_campaign()` entry) **still stands**; the
  `_apply_overlay()` merge body is **retired** in favour of `_clear_content()` + `_load_all(campaign.dir)`.
  Net: the seam work was not wasted; the merge semantics are simply dropped.

## 4. Notes
- **Risk: low.** No data, schema, or player-facing change; the static validators are already
  the right shape. The only behavioral subtlety is the `skill.validate()` channel ([DMR-1]).
  [DMR-4]'s seam is behavior-preserving (null-default overlay; uncalled `select_campaign`).
- **Sequencing:** the refactor ([DMR-1..3]) is independent of everything else — a good
  "palette-cleanser," no upstream blocker. **[DMR-4]'s `_apply_overlay()` body is downstream of
  the I3 content-overlay register** (a–e), and `select_campaign()` is wired by §2's campaign-select;
  the *seam* (this register) lands first and unblocks both.
- **DoD#1:** no GDD section changes behavior (the seam is inert until wired), so no roadmap status
  flip needed — internal refactor + a stubbed seam; note in the session note + the §H register-status
  line only.
- **DoD#2:** no new checkable vocab rule here. **Forward:** when I3 fills `_apply_overlay()`, its
  id-namespace-collision + default-content-version guards are the `check_docs`/validator candidates
  (tracked in the I3 register), not owed by this seam.

---

# Resolution Log
(newest first)

- **2026-06-23 — Register RESOLVED (`[DMR-1..4]`), walked one-by-one with the owner.** [DMR-1] **A**
  unify error channels (`_validate_all()` folds the skill loop + both collect_* sets → one `_report`).
  [DMR-2] **A** load errors stay inline at the I/O site; only validation feeds the channel.
  [DMR-3] **A** add a `_validate_all()` composition test + a [DMR-4] seam test (null-overlay = identical
  boot, stub reached). **[DMR-4] NEW + A** — parameterize the campaign base+overlay **load seam** now
  (`_load_all(base, overlay=null)` + `select_campaign()` + `_apply_overlay()` stub), **defer merge
  semantics to I3**. Locks the DMR-owns-plumbing / I3-owns-semantics split; behavior-preserving today.
  **Next: open the I3 content-overlay register (a–e) — it fills `_apply_overlay()`'s body.**
- **2026-06-21d — Register drafted** (3 refactor questions, recs A/A/A) from `planning_backlog §5`.
