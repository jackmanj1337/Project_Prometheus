# Session Note - 2026-08-04 Mobile Web Controller Slice 1

> **Carried copy.** The original of this note lives on the docs line as
> `2026-08-04-06-04-31Z-mobile-web-controller-slice-1-docs.md`. This branch descends from
> `agent/integration`, whose pre-commit claims checker reads notes from the
> working tree, so the claim for `eb235ff2` has to be present here too; the
> filename check on this branch also requires the timestamped form.
> **Delete one of the two copies when this branch merges toward the docs
> line** — leaving both makes `eb235ff2` claimed twice.

## Branch context

- Branch: `agent/from-integration/mobile-web-controller`
- Base branch: `agent/integration`
- Base SHA: `cd7797fe0985999bac16fd4c6b46e1e299c580fe`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`

## What was done

- Created and registered the new product feature branch.
- Added the versioned, platform-neutral controller-layout value model.
- Added six starting combinations, portrait/landscape selection, fail-closed
  schema handling, normalized geometry, element sanitization, and non-mutating
  device-specific viewport clamping.
- Avoided the PWA shell and export preset because active tracker rows still own
  those paths.

## Commits claimed

- `eb235ff2a07ea8a835da73a1ceb7be724d7a4674` — Add versioned mobile controller layout model

## Gates

- `test_controller_layout.gd`: PASS, 13 assertions.
- `bash run_tests.sh`: PASS, all 117 suites.
- GDScript formatter and linter: PASS.
- Documentation, RNG, scene-integrity, analyzer, and evidence hooks: PASS.

## Next

Add the persistence/manager layer on the feature branch without touching the
currently claimed PWA shell, export preset, input-mode manager, or safe-area
service. Claim shell paths only after their existing tasks merge or release them.
