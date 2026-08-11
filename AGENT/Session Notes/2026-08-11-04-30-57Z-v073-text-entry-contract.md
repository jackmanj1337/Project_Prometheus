# Session Note - 2026-08-11 Text Entry Contract

## Branch context

- Branch: `agent/from-integration/v073-text-entry-contract`
- Base branch: `agent/integration`
- Base SHA: `b3d567d6ed5800b3dc479fb39f407c5b12385918`
- Coordination Work ID: `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`

## What was done

- Completed v0.7.3 remediation Session 3 by consolidating the general single-value
  request/result contract. Requests now carry presentation metadata, caller-owned
  normalization and validation, button labels, and dismissal policy.
- Added selection-aware caret editing and a generation-tagged submitted/cancelled
  result. Session replacement and repeated completion cannot emit two results for one
  generation.
- Updated the text-entry GDD and roadmap boundary. Same-viewport presentation and real
  event ownership remain Session 4, not part of this pure-contract slice.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`, NOT here.

The behavior and inseparable documentation commit is `49ad86b9`.

## Gates

- `test_text_entry_service.gd`: 32 passed, 0 failed.
- `test_text_entry.gd`: 29 passed, 0 failed.
- Required Python/browser checks: PASS.
- All 137 Godot suites: PASS.
- Documentation, RNG, analyzer, scene-integrity, evidence-matrix, claim, and GDScript
  style hooks: PASS.

## Next

Session 4: build the reusable same-viewport modal and prove one-event ownership with
real dispatched input. Begin with `ModalScreen.gd`, `FocusNavigator.gd`, input-mode
code, `TextEntryService.gd`, and the current filename prompt path.
