---
Type: playtest
Status: Pending validation - live Windows return only
Last verified: 2026-07-15
---

# Campaign/Save Post-audit Follow-up Requirement/Evidence Matrix

**Authority:**
[`campaign_save_post_audit_followup_handoff_2026-07-15.md`](../plans/campaign_save_post_audit_followup_handoff_2026-07-15.md)  
**Branch:** `agent/codex/2026-07-15/prep-save-followup`  
**Audit rule:** an automated pass proves only its stated surface. Unreturned live
rows remain unproven and block goal completion.

| Requirement | Implementation evidence | Verification evidence | Result / open finding |
|---|---|---|---|
| Phase 1: independent Decision state and Delivery status vocabulary | `50a5071`; `decision_index.md`; `check_docs.py` check 36 | Valid table passes; intentionally invalid token failed and was restored | **Pass** |
| Phase 2: one adjustable import-budget owner | `8c432d6`; `ImportBudgets.gd`; SaveManager/archive consumers | `test_save_import_budgets.gd`; hardcoded-limit search | **Pass** |
| Phase 2: warning acknowledgement and pre-buffer hard cap | `8c432d6`; portable-save UI/SaveManager paths | warning/cancel/acknowledge/hard-cap/integrity automated cases | **Automated pass; live dialogue rows pending below** |
| Phase 2: representative measurements | `campaign_save_import_budget_measurement_2026-07-15.md`; `SaveBudgetMeasurement.gd` | between-map, mid-map, large roster/convoy, shipped-policy ledger measurements below warning budget | **Pass** |
| Phase 3: campaign DOC-002 and section-local verification | `87bbfe4`; governance/GDD/index/control-plane updates | `check_docs.py` checks 37-38 and controlled negative fixtures | **Pass** |
| Phase 4: compatibility-preserving open objective conditions | `1169464`; objective registry entries/handlers and consumer routing | `test_open_authored_registries.gd`; objective/data/turn suites; closed-dispatch guard | **Pass** |
| Phase 4: compatibility-preserving open item effects | `1169464`; item registry entries/handlers and consumer routing | unknown/duplicate/validation/preview/commit/legacy-id cases; closed-dispatch guard | **Pass** |
| Phase 5: cadence report at closeout/pre-push | `de92011`; `audit_cadence.py`; closeout and pre-push hooks | current report prints elapsed days and commits without blocking | **Pass** |
| Phase 5: exact unique session commit ownership | `de92011`; template, bootstrap SHA, checker | duplicate claim fixture failed; current substantive commits through `6123352` are claimed by the next note/closeout sequence | **Pass through prior commit; current audit commit will require the normal next-note claim** |
| Phase 5: reusable multi-slice requirement/evidence matrix gate | `de92011`; template, ledger, checker | missing matrix fixture failed and was restored | **Pass** |
| Phase 5: quiet export smoke | `de92011`; `export_smoke.sh` | exit `0`, `102090960` bytes, SHA-256 `522c5687…a615` | **Pass** |
| Phase 5: pinned format/lint locally and in both workflows | `01f4e94`, `dd4f971`; `requirements-dev.txt`, configs, shared style script, hooks/workflows | 226 files pass; unformatted fixture failed; workflow YAML parses; owner approval obtained before edits | **Pass** |
| Phase 6: fresh traceable Windows artifact | `6123352`; follow-up build manifest/checklist | PE32+ x86-64, embedded BUILD STAMP `dd4f971`, size/hash and export exit verified | **Pass: build preparation/export only** |
| Phase 6: Prep focus and long-roster layout | follow-up checklist §1 | Original Windows log, platform/input details, requested screenshot | **Pending external live return** |
| Phase 6: five maps and branch results | follow-up checklist §2 | Completed transition/branch rows and screenshot | **Pending external live return** |
| Phase 6: defeat actions, Retry, Rewind | follow-up checklist §3 | Completed action/state-restoration rows | **Pending external live return** |
| Phase 6: manual/auto save, load, Continue, suspend | follow-up checklist §4 | Completed slot/rotation/resume rows | **Pending external live return** |
| Phase 6: portable warning and hard-cap dialogs | follow-up checklist §5 | Fixture sizes, completed mutation-safety rows, screenshots | **Pending external live return** |
| Phase 6: package import/export dialogs | follow-up checklist §6 | Success/rejection rows, screenshots, staging-state observation | **Pending external live return** |
| Phase 6: evidence archive and triage | follow-up checklist §7 | Returned checklist, original `godot.log`, platform/controller data, screenshots, triage record | **Pending external live return; blocks completion** |
| Full automated closeout | all phase commits | 40 documentation checks, pinned style checks, analyzer/RNG/scene checks, and all 100 Godot suites | **Green at `dd4f971`; rerun after live-return triage** |

## Current conclusion

Phases 1-5 and the environment-permitted Phase 6 build/export work are proven.
The Linux workspace has neither Wine nor a Windows GUI/controller surface, so it
cannot honestly substitute headless or Linux execution for the seven live-return
rows. Do not change related `Pending validation` delivery states or complete the
persistent goal until those rows are returned, archived, and triaged.
