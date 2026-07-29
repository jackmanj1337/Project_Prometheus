# Pillar 1 — Code Review (2026-07-15)

Procedure: `AGENT/Review Procedures/01_Code_Pillar.md`
Previous substantive review: `AGENT/Code Reviews/code_review_v0.3.0_release_delta_2026-07-07.md`
Snapshot: `agent/codex/2026-07-15/prep-save-followup` at `08b3b5c2aa5dfb1e773a87d07890b9c7629ef1b3`
Scope: all 122 non-test `scripts/**/*.gd` files, with a line-by-line risk pass over the 94 files changed since the prior review snapshot `b7bcfd2ec6738e857faced0f92abb76bf4b2b3d8`
Baseline supplied by the full-audit orchestrator: `check_docs.py` 35/35 PASS; `bash run_tests.sh` 98 suites PASS; RNG usage guard PASS; Godot 4.6.3, Python 3.12.13, pytest 9.1.1, gh 2.96; gdlint/gdformat unavailable.

**Score:** 6/10

## Executive Summary

The campaign/save branch has strong domain separation and unusually broad defensive validation for a new persistence and package-import surface. The July RNG lifecycle, prompt refresh, keybinding coverage, and much of the open-registry debt were addressed. However, the new external-file boundary applies archive limits only after reading an entire file into memory, a rejected campaign load can leave the active content source and campaign position partially changed, and two portable export paths can destroy an existing artifact before the replacement is secured. Those are release-relevant correctness and resilience issues even with all 98 automated suites green.

## Issues

### High — Import security limits are applied only after the entire external file is loaded

**File & line:** `scripts/resources/CampaignArchivePreflight.gd:34-48`, `scripts/resources/CampaignArchivePreflight.gd:72-93`, `scripts/autoloads/SaveManager.gd:194-207`

**Problem:** `CampaignArchivePreflight.inspect_zip()` opens the user-selected archive and immediately allocates a `PackedByteArray` for `file.get_length()` bytes. Entry and total compressed/uncompressed limits are checked later by `inspect_entries()`. Portable-save inspection follows the same shape: it reads the complete selected file before checking its artifact kind, and it has no explicit byte budget at all.

**Root cause:** the limits model protects extracted ZIP metadata and payload totals, but there is no outer artifact-size boundary before whole-file buffering. The implementation therefore assumes a selected file is small enough to allocate before it can decide that the file violates policy.

**Why it matters:** a malformed or simply enormous local artifact can exhaust memory or stall the UI before the advertised import limits take effect. This is an external-input availability risk on the player-facing Campaign Library and Load Game import surfaces.

**Recommended fix:** reject files whose `get_length()` exceeds a ratified maximum before `get_buffer()`. Parse ZIP central-directory metadata from bounded reads (or at minimum gate the whole archive by `max_total_compressed` plus bounded metadata overhead). Add a separate portable-save byte limit and a regression that uses an oversized sparse/temp artifact without allocating its full contents.

**Tradeoffs:** a hard artifact cap rejects unusually large legitimate packs, so expose one documented player-facing package budget and keep optional media budgets aligned with it. Streaming central-directory parsing is more work but avoids tying metadata inspection to archive size.

### High — A failed campaign resume is not transactional and can leave live state partially replaced

**File & line:** `scripts/autoloads/GameState.gd:913-955`, `scripts/autoloads/GameState.gd:659-670`, `scripts/autoloads/CampaignManager.gd:561-638`, `scripts/save/SaveData.gd:88-106`, `scripts/save/SaveData.gd:287-303`, `scripts/resources/MutableCampaignState.gd:46-71`

**Problem:** `configure_campaign_resume()` says every rejecting check occurs before live state is written, but it activates the saved campaign package at line 927 and calls `CampaignManager.restore_campaign_state()` at line 938 before validating/restoring mutable campaign state at lines 941-944. `SaveData.validate()` does not validate the structure inside `campaign.mutable_state.rule_patches`; malformed patch entries survive normalization and fail only in `MutableCampaignState.apply_dict()`. The function then returns false after the content source, campaign id, node, cleared nodes, flags, variables, and rules may already have changed.

**Root cause:** validation and application are interleaved across three owners. The roster and item conversion are staged, but package activation, campaign position, rules, and mutable-state validation do not share a complete preflight/commit boundary.

**Why it matters:** acknowledging a tamper warning on a structurally malformed portable save can report that loading failed while silently replacing part of the running campaign state. A later menu action or save can then operate on a mixed old/new state.

**Recommended fix:** introduce a pure resume preflight that resolves package/campaign references and constructs a staged campaign position, normalized rules, and `MutableCampaignState` without touching autoload state. Commit all staged values only after every component succeeds. At minimum, extend `SaveData.validate()` to validate mutable-state internals and add a regression asserting all relevant autoload fields remain byte-for-byte unchanged after a deliberately late failure.

**Tradeoffs:** a formal staged-resume object adds code, but it makes the existing transactional claim true and gives mid-map resume the same reusable safety boundary.

### Medium — Portable exports delete or truncate an existing artifact before replacement succeeds

**File & line:** `scripts/resources/CampaignPackExporter.gd:55-80`, `scripts/resources/CampaignStatusStore.gd:37-51`, `scripts/autoloads/SaveManager.gd:175-191`, `scripts/autoloads/SaveManager.gd:493-500`

**Problem:** campaign-pack export writes and preflights a temporary archive, but then removes the existing destination before renaming the temporary file. Campaign status export similarly removes the existing record before promoting its `.tmp`. If either rename fails, the previous valid artifact is gone. Portable save export is weaker still: it opens the destination directly with `FileAccess.WRITE`, truncating an existing file before the new JSON write is known to finish.

**Root cause:** transactional replacement is implemented for internal named saves, but the same backup/promote/rollback primitive was not reused by the three portable export surfaces.

**Why it matters:** a transient filesystem, permission, antivirus, removable-drive, or process failure can destroy the user's previous export while returning an error. Status records are particularly sensitive because the generated `record_id` can collide for repeated exports within the same timestamp second.

**Recommended fix:** centralize an absolute-path staged replacement helper: write and flush a same-directory temp, move the existing destination to a backup, promote the temp, restore the backup on failure, then remove the backup. Add fault-injection tests for failure after backup and before promotion for all three callers.

**Tradeoffs:** backup-based replacement leaves one more cleanup path and may not be truly atomic on every platform, but it prevents avoidable data loss and matches the existing named-save design.

### Medium — Remaining content vocabularies still bypass the open-registry architecture

**File & line:** `scripts/autoloads/DataManager.gd:22-25`, `scripts/resources/ObjectiveCondition.gd:59-88`, `scripts/items/ItemHandler.gd:9-14`, `scripts/items/ItemHandler.gd:31-58`, `scripts/items/ItemHandler.gd:70-80`

**Problem:** AI profiles and stat names now have registry seams, but objective conditions and item effects remain closed constants plus `match` dispatch. Adding either authored vocabulary still requires coordinated engine edits.

**Root cause:** the campaign branch migrated several extension points but did not finish the older objective and item-effect seams.

**Recommended fix:** move objective evaluation/display predicates and item-effect validation/commit handlers behind the same registered primitive pattern used by `RegistryManager` and `ActionPrimitiveRunner`. Avoid introducing additional cases in the interim.

**Tradeoffs:** registry indirection is more machinery than a small switch. It becomes worthwhile when public campaign packs are an explicit supported surface, as they are on this branch.

### Low — New action-registry public methods omit return types

**File & line:** `scripts/actions/ActionPrimitiveRunner.gd:14`, `scripts/actions/ActionPrimitiveRunner.gd:51`, `scripts/actions/ActionPrimitiveRunner.gd:66`, `scripts/autoloads/ActionEffectRunner.gd:13`, `scripts/autoloads/ActionEffectRunner.gd:18`, `scripts/autoloads/RegistryManager.gd:58`, `scripts/registries/RegistryCatalog.gd:72`

**Problem:** public validation, commit, and lookup APIs omit return annotations despite consistently returning `ActionResult`-shaped objects or registry resources. This weakens editor/static-analysis help at a new core extension boundary.

**Root cause:** several new generic APIs were typed only as far as their arguments, likely to avoid class-cache coupling.

**Recommended fix:** use the already preloaded result/resource types where feasible, or explicitly annotate `Variant`/`Resource` where polymorphism is intentional. Document the stable shape when a precise type cannot be expressed.

**Tradeoffs:** explicit `Variant` does not add type safety, but it communicates intent; precise script types may require careful preload/class-cache handling in headless tests.

## Positive Observations

- Fresh-map RNG lifecycle is now correct: `GameMap` calls `RngService.start_map()` before the retry snapshot (`scripts/core/GameMap.gd:113-131`), while suspend resume stays on the restore path.
- Input mode now listens to `SettingsManager.settings_changed` and refreshes immediately (`scripts/autoloads/InputModeManager.gd:23-29`), and the rebind UI discovers normal InputMap actions rather than maintaining the former closed list (`scripts/ui/SettingsScreen.gd:735-758`).
- The campaign package boundary validates traversal, case-fold collisions, duplicate paths, encryption, compression methods, special files, content catalogues, and save-shaped JSON before installation (`scripts/resources/CampaignArchivePreflight.gd:79-183`, `scripts/resources/CampaignArchivePreflight.gd:186-197`, `scripts/resources/CampaignArchivePreflight.gd:221-283`).
- Named saves have a clear ownership split and a backup/rollback transaction for slot plus index updates (`scripts/autoloads/SaveManager.gd:454-480`).
- The map ledger returns deep copies, preserves the retry boundary, validates restore payloads, and truncates abandoned futures only after staging succeeds (`scripts/save/MapLedger.gd:84-107`, `scripts/autoloads/GameState.gd:841-870`, `scripts/autoloads/GameState.gd:1188-1237`).
- AI profile and stat growth vocabularies moved toward open registries, materially reducing the architecture debt called out in July (`scripts/core/AIProfileRegistry.gd`, `scripts/core/StatRegistry.gd`, `scripts/autoloads/RegistryManager.gd`).

## Architectural Observations

- `SaveData` (normalization/validation), `SaveCodec` (typed conversion), `SaveManager` (disk), and `GameState` (runtime state) remain sensible boundaries. The transactional-load finding is a coordination gap between these layers, not evidence that the split itself is wrong.
- The branch added 10,071 lines across 94 production scripts since the prior snapshot. `MapCursor` (2,061 lines), `TurnManager` (1,345), `GameState` (1,314), `Unit` (1,214), and `SettingsManager` (1,123) remain high-coupling change hotspots. No single size is a correctness defect, but future campaign work should prefer the new service/resource seams over growing these owners further.
- The action primitive layer is a promising reusable registry boundary. Item effects are already beginning to route `stat_buff` through it, making the remaining closed item dispatch a tractable incremental migration.
- No raw gameplay RNG regression was found. The only non-test `randomize`/`randi` uses are the documented map-seed entropy source and Unit's explicitly allowed headless fallback.

## Prioritized Action Plan

1. Add an outer byte budget before any whole-file import buffering; cover both campaign ZIP and portable-save inspection.
2. Make campaign resume a validate-then-commit transaction and test unchanged live state on every late rejection path.
3. Reuse a backup/promote/rollback helper for campaign pack, status record, and portable save exports.
4. Continue registry migration for objective conditions and item effects; do not add new closed cases.
5. Add explicit return annotations to the action/registry APIs and introduce gdlint/gdformat when the dependency is available.

## Delta vs Previous Review

Previous substantive baseline: `code_review_v0.3.0_release_delta_2026-07-07.md` at `b7bcfd2` (score 6/10).

- **Fixed:** fresh maps now seed/reset `RngService` before retry snapshot capture (`scripts/core/GameMap.gd:123-131`).
- **Fixed:** Settings changes refresh `InputModeManager` through the settings signal (`scripts/autoloads/InputModeManager.gd:23-29`).
- **Fixed:** the rebind surface now discovers non-debug player actions from `InputMap`; the previously omitted More Info, Peek Range, and Zoom actions are explicitly ordered/labeled (`scripts/ui/SettingsScreen.gd:680-720`, `scripts/ui/SettingsScreen.gd:735-758`).
- **Partially fixed:** AI profiles and stat vocabularies gained registry-backed seams, but objective conditions and most item effects remain closed dispatch lists.
- **Newly introduced:** the archive and portable-save whole-file import surfaces, partial campaign-resume transaction, and portable export replacement paths were added after `b7bcfd2`; the three findings above are not merely newly scoped old code.
- **No regression found:** the prior spawn-source/`ai_profile` fix still holds, and the raw-RNG guard remains clean.

## Review Sample and Verification

- Enumerated all 122 non-test GDScript files and reviewed the complete 94-file production delta from `b7bcfd2` to the pinned SHA.
- Read the complete new campaign/save/package/ledger resource group and their primary UI/autoload call sites; spot-checked state ordering in `GameMap`, `CampaignManager`, `GameState`, and `SaveManager`.
- Searched all in-scope scripts for raw RNG, per-frame callbacks, untyped function returns, TODO/FIXME/pass markers, and previous-finding symbols.
- Falsifiable lifecycle checks: RNG seed occurs before snapshot; failed mutable-state restore occurs after package/campaign mutation; export destinations are removed/truncated before successful finalization; archive bytes are buffered before limits are evaluated.
- Did not rerun the supplied green test/document baseline, per Pillar 1 procedure. `git diff --check` was clean before this report was added.

## Procedure Friction

- The pillar procedure still names the RNG design at its pre-reorganization path; the live file is `AGENT/Docs/design/rng_determinism_design_2026-06-11.md`.
- The requested prior-report glob also matches prep/handoff and specialized release-delta files. “Latest by date” is ambiguous when several same-day artifacts have different roles; the procedure should specify that substantive completed reviews outrank prep documents, then use commit ancestry/date as the tiebreaker.
- The procedure requests `mcp__godot-analyzer__get_autoloads`, but that tool was not exposed in this audit environment. Filesystem inspection remained sufficient, and the supplied headless baseline covered registration/parser failures.
- Pillar 1 defines score bands only through the master, not a code-specific scoring rubric despite saying each pillar has one. This report used the master bands and held the score at 6/10 because two High correctness/resilience issues remain.
- gdlint/gdformat were unavailable, so style/type review was limited to targeted static searches and manual inspection rather than a reproducible whole-tree lint result.
