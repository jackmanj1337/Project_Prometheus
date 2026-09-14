---
Role: dated
---

# Code Review — 2026-09-14

**Score:** 5/10

Scope: bounded semantic review at engine `ad2e6be729013f46a3978269c8ea0f6248f81aad`.
Luna W2/W5/W8 reviewed pack import/activation, New Game selection, save/load/migration,
editor document save and working-copy import, and phase-start condition/Renewal
transactions. The lead independently checked consequential paths. Baselines and
workspace identities are in [the rollup](full_review_rollup_2026-09-14.md).

## Verified findings

### High — Editor save commits clean state before the disk accepts it

`CampaignEditorShell.save_active_document()` (`scripts/editor/CampaignEditorShell.gd:376`)
calls `EditorDocument.save()` (`scripts/editor/EditorDocument.gd:293`), which replaces
`_saved`, clears the overlay, and emits the clean state. Only afterward does
`CampaignEditorScreen._on_shell_document_saved()` (`scripts/ui/CampaignEditorScreen.gd:477`)
call the writer. On failure it emits `document_save_failed` but does not restore dirty
state. `EditorDocumentSet.close()` (`scripts/editor/EditorDocumentSet.gd:71`) consequently
allows closing without the unsaved-change confirmation.

The lead's isolated production-class probe observed `dirty=true`, writer refusal,
`dirty=false`, retained edited value, then `close outcome=closed`.
`/tmp/full-audit-editor-save-probe.gd` and `.log` preserve the probe locally. It uses a
null working-copy writer to force refusal and the production shell/document/close
classes; the real screen's error branch was independently read. The probe logged
resource-leak shutdown warnings; it is evidence of this state transition, not a clean
full-suite result or a native UI test. Edits and undo remain in memory before close,
so retry is possible: immediate destruction of all in-memory edits is **not** claimed.

The same outer operation has a disk-side gap: `EditorPackWriter.write()`
(`scripts/editor/EditorPackWriter.gd:69-99`) writes each document directly, continues
past errors, and updates the catalogue last only when there are no prior errors.
A late document/catalogue failure leaves earlier writes in place. This is confirmed
from the write/error branches, without a filesystem fault-injection claim.

One owner, `AUDIT-EDITOR-SAVE-ATOMICITY-2026-09-14`, should coordinate dirty state,
undo/recovery, document files and catalogue through successful persistence. Severity
reflects authoring work at risk after a refused save, not proven loss in a returned pack.

### Medium — Campaign preferences cannot distinguish two builds of one version

`CampaignPackRegistry` permits fingerprint-distinct builds with the same id/version.
`NewGameScreen.gd:273-296` omits fingerprint from options; `_same_run_identity()` at
`:460-465` compares campaign/id/version only. `SaveManager.gd:811-828` persists those
same three fields. Refresh/reopen selects the first match at `NewGameScreen.gd:468-478`,
so a preference for the second build can select the first. Direct selection still
activates the chosen path, and ordinary save identities retain fingerprints. This is
selection identity loss, not demonstrated save corruption.

Owner: `AUDIT-CAMPAIGN-PREFERENCE-IDENTITY-2026-09-14`. Extend the existing identity
path and verify two authored same-version builds, including refresh and last-started.

## Candidates retained with uncertainty

`configure_suspend_resume()` (`GameState.gd:370-412`) activates content before later
refusals without the rollback used by `configure_campaign_resume()` (`:1088-1138`).
The worker proposed malformed ledger/mutable state as triggers, but `SaveData.validate()`
already checks those before ordinary loading. Those inputs do not yet prove a
player-reachable failure. `AUDIT-SUSPEND-ROLLBACK-2026-09-14` owns proving a reachable
late failure or rejecting this candidate. No confirmed High finding is assigned here.

DataManager's diagnostic key (`DataManager.gd:744-770`) omits fingerprint/source/reason.
Consecutive refused validations may collapse distinct evidence. The worker's broader
claim that successive successful activations collapse is not accepted: registry commit
records normally interleave in the same category. Investigation remains within the
campaign-identity row; no demonstrated successful-activation collapse is reported.

## Positive observations and limits

Installer stages and validates before promotion. DataManager constructs a complete
candidate and validates map semantics before committing it. Between-map resume now
snapshots and restores content/campaign/mutable state; the August finding is repaired
there. SaveManager stages slot and index replacement together. Condition and Renewal
preparation use shared effect transactions before applying mutations; phase-start
ordering is explicit. Native Renewal/Continue interaction remains the existing
`V0719-RENEWAL-SUSPEND-CELL-2026-09-14` evidence task.

Reviewed paths include CampaignPackInstaller/Registry/Tier2RuntimeAdapter,
DataManager/RegistryManager, NewGameScreen/CampaignManager/SaveManager/GameState,
EditorDocument/DocumentSet/PackWriter/WorkingCopy/AssetManager, CampaignEditorShell/Screen,
SkillHandler/ConditionManager/TurnManager and their targeted test sources.
Not reviewed exhaustively: all 251 code-assigned paths, full combat/AI trigger matrices,
every migration vocabulary, all editor export/reimport branches, performance or native
rendering. The score reflects serious verified save-boundary debt in this sample.
August's unsafe inventory converter and other unrelated findings were not rechecked.
