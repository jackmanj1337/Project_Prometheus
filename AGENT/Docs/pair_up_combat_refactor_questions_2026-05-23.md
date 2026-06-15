# Pair Up Combat Refactor — Next Session Questions

## Purpose
Prepare the next Awakening compatibility pass so implementation can begin from
 a settled question list instead of reopening combat-model scope from scratch.

## Already settled
- Pair Up scaffolding is the next implementation pass after the internal-level
  and class-schema work.
- Pair Up must be campaign-configurable and disableable in settings.
- Pair Up is a foundational combat subsystem, not a one-off skill effect.
- Pair Up-related skills imported before full Pair Up mechanics exist should
  either gain alternate effects or remain intentionally disabled.
- Stored WEXP, internal level, and class availability decisions from the prior
  passes are now in place and should be treated as fixed inputs for the combat
  refactor.

## Questions to answer before implementation

### 1. Pair Up unit model
- What is the runtime representation of a Pair Up?
- Recommendation:
  - store an explicit lead/support relationship on units or in combat context
  - avoid implicit adjacency-based inference once a unit is actually paired

### 2. Map-state behavior outside combat
- While paired, does only the lead unit exist on the tactical grid, with the
  support unit removed from independent targeting/movement?
- Recommendation:
  - yes, represent only the lead on the map while preserving support identity in
    state
  - this keeps selection, pathing, and occupancy rules simpler

### 3. Pair Up action flow
- What exact player actions create, break, or swap a Pair Up on map?
- Recommendation:
  - start with create + separate only
  - defer swap/advanced rearrangement until the base system is stable

### 4. Combat preview responsibilities
- Which Pair Up bonuses and support effects must appear in forecast immediately?
- Recommendation:
  - all deterministic stat modifiers
  - Dual Strike / Dual Guard chances if implemented in that pass
  - never hide support-driven effects from preview if live combat will use them

### 5. Pair Up stat-bonus source
- Are Pair Up bonuses authored on the support unit, on class data, or on a
  dedicated support-bonus table?
- Recommendation:
  - use dedicated data-driven tables or a dedicated resolver
  - do not bury Pair Up bonuses inside unrelated class or skill fields

### 6. Dual Strike and Dual Guard rollout order
- Do Dual Strike and Dual Guard land in the first Pair Up pass or in a follow-up
  pass after scaffolding?
- Recommendation:
  - land the scaffolding, combat context, and preview-safe state model first
  - add Dual Strike / Dual Guard only once the paired-unit context is stable

### 7. AI expectations
- Must AI understand Pair Up immediately, or can early support be player-only /
  disabled for AI-controlled factions?
- Recommendation:
  - implement a simple AI-safe baseline in the first pass
  - avoid a human-only mechanic if combat math can still be affected by it

### 8. Save / snapshot behavior
- What exact Pair Up state must survive map snapshot and restore?
- Recommendation:
  - paired partner ids
  - lead/support role
  - any Pair Up cooldown/flags if the design introduces them

### 9. UI scope for the first pass
- Which screens need to show Pair Up state immediately?
- Recommendation:
  - action menu
  - unit details
  - combat preview
  - any cursor/HUD state that needs to distinguish paired vs unpaired lead units

### 10. Skill handling policy during transition
- Which existing or planned skills need alternate effects before full Pair Up
  mechanics land?
- Recommendation:
  - identify them up front and document each as:
    - `disabled intentionally`
    - `temporary alternate effect`
    - `ready for full Pair Up implementation`

## Recommended implementation order
1. Define the paired-unit runtime state and snapshot format.
2. Add campaign settings and validators for Pair Up enable/disable.
3. Refactor combat context to include lead/support data cleanly.
4. Update preview and live combat to read the same Pair Up-aware context.
5. Wire basic on-map Pair Up / separate actions.
6. Add AI-safe handling.
7. Add or re-enable Pair Up-dependent skills.

## Suggested first questions to answer next session
- Does only the lead unit occupy the map while paired?
- Do Dual Strike and Dual Guard land in the first Pair Up pass or a follow-up?
- What is the minimum UI surface required for the first Pair Up rollout?
