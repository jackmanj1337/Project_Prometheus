# Session Note - 2026-08-02-01-30-00Z-fog-plan-amendment

## Branch context

- Branch: `agent/integration` (docs line)
- Base branch: `agent/integration`
- Base SHA: `7b1bffd6665f036733a37e02cf591fd97669b58e`
- Coordination Work ID: `IMPL-CROSSING-RESOLVER-2026-08-01`

## What was done

Docs-line half of the fog build described in
[2026-08-02-01-00-00Z-fog-slices-1-3](2026-08-02-01-00-00Z-fog-slices-1-3.md)
(code on `agent/from-integration/crossing-resolver`). `AGENT/Docs/plans/` is
fenced to the docs line by the docs-guard hook, so the plan amendment could not
ride along with the code commit and lands here instead.

Amendments to `band6_fog_of_war_implementation_plan_2026-07-03.md`:

- The **`Unit.move_along_path` touchpoint is marked obsolete**. Fog does not
  touch movement at all — the shared crossing resolver resolves crossings over
  path-as-data and slice 3 is one registered consumer. The 2026-08-01 correction
  is kept beneath it, because its measurements are precisely why that seam exists.
- **Slice 1 marked implemented**, with the one deviation recorded:
  `fog_enabled` sits on `BattleEncounterDef`, not `MapData`. The encounter/map
  split post-dates the plan and carried `enemy_placements` — the field this one
  was to sit beside — with it, so the encounter layer is the plan's intent today.
- **Slice 3 marked implemented**, with its step 1 ("in the `move_along_path`
  per-step loop") explicitly flagged as superseded by `[PCM-3]` and **not
  followed**.
- **Slice 2 flagged NOT BUILT** and not closeable on a headless suite: the fog
  mask render and enemy hiding need a Windows visual pass, the same gate as
  `[TER-2]`.

## Commits claimed

- `06ef326df5caf1847e31683da9363e9becf2dfa8` — Fog plan: slices 1 and 3 are built; slice 2 is the visual-pass gate

## Gates

- Docs-only change; the pre-commit hook skipped the Godot suite by design. The
  code these amendments describe is gated in the sibling note above (115 suites
  green).
- `check_docs.py` clean at the time of the code commit.

## Next

Fog slice 2 (render) on a Windows session — see the sibling note.
