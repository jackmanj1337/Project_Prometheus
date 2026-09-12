---
Role: dated
Type: playtest
Status: Implemented - automated boundary evidence
Last verified: 2026-07-16
---

# AI Suspend Boundary Requirement/Evidence Matrix

**Track:** `B1-SUSPEND-TRANSIENT-RESEARCH`  
**Scope:** Suspend between AI unit activations  
**Reviewed:** 2026-07-16

| Requirement ID | Requirement | Implementation anchors | Automated evidence | Live/manual evidence | Result / finding |
|---|---|---|---|---|---|
| AIS-001 | An AI-phase request finishes the acting unit before capture. | `EnemyAI.run_phase`; `TurnManager.complete_ai_activation_boundary` | `test_turn_manager`: capture occurs only through the explicit post-action boundary. | Not required for the scheduler contract. | Pass |
| AIS-002 | The activation ledger is sealed exactly once before the slot capture. | `TurnManager._flush_activation_history`; pending guard | `test_turn_manager`: history grows by exactly one and capture runs once after the deferred callback unwinds. | Not required; byte/state serializers already have live suspend coverage. | Pass |
| AIS-003 | Continue resumes the already-started AI faction without repeating phase-start effects or replaying spent units. | `controller_boundary`; `_resume_suspended_ai_phase`; `_run_enemy_phases(true)` | `test_turn_manager`: restored red `DONE` state remains spent and the controller returns to blue. | Future release checklist should exercise the visible round trip. | Pass |
| AIS-004 | Failed writes preserve a playable map. | `perform_pending_ai_suspend`; `complete_ai_activation_boundary` failure branch | `test_turn_manager`: false writer clears intent/continuation and does not stop the controller. | Existing suspend checklist covers player-facing write failures. | Pass |
| AIS-005 | A committed victory/defeat cancels the request. | `complete_ai_activation_boundary` map-over gate | `test_turn_manager`: outcome clears the pending intent without capture. | Results sequencing already covered by `test_game_over_sequencing`. | Pass |
| AIS-006 | AI Map Menu access cannot mutate phase state. | `MapCursor._unhandled_input`; `MapMenu.set_ai_phase_mode` | `test_map_menu`: End Turn/Rewind disabled and Suspend focused; full suite remains green. | Future release checklist should confirm input feel. | Pass |
| AIS-007 | Existing local-faction suspend and serialized runtime restoration do not regress. | `MapCursor.can_capture_suspend`; shared capture path | `test_suspend_map_runtime` 9/0; `test_map_menu` 8/0; full 100-suite run green. | Existing v0.3.0.d local suspend path was live-validated. | Pass |

All in-scope requirements have direct automated evidence. Immediate capture
inside AI actions and unrelated transient modal/action states remain rejected and
are not claimed by this implementation.
