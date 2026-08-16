---
Type: decision-record
Status: Applied
Last verified: 2026-06-29
Decision IDs: SET-011..014
---

# Decision Record — Project Scope Reframe (2026-06-29)

## Context

The project had accumulated two overlapping frames: a faithful tactical-RPG adaptation
and a broader authoring/tooling direction. The 2026-06-29 owner walk resolved the
priority order so the GDD can be audited against one clear goal.

## Decisions

| ID | Decision | Applied in |
|---|---|---|
| SET-011 | The primary project goal is learning and portfolio value: demonstrable engineering quality, readable architecture, and a showable result outrank commercial-release optimization. | `GDD_00_Overview.md` |
| SET-012 | The secondary product direction is a flexible tactical-RPG builder: users should eventually build and share campaigns with custom assets and rule data. | `GDD_00_Overview.md`; Project Control Plane |
| SET-013 | Power-user access has a security boundary: in-app authoring is data-only first and will not exceed sandboxed scripting; full control means forking the public source. | `GDD_00_Overview.md`; registry/preset docs |
| SET-014 | The portfolio target is a slice-first playable web demo: first a polished playable slice, then evidence that it was authored through the builder. This does not resequence the Band 1-8 build order. | `GDD_00_Overview.md`; `REL-WEB-DEMO` |

## Consequences

- Existing corpus numbers, tactical formulas, profile names, and content examples remain
  useful as developer-provided presets and validation content, not as reasons to
  hardcode author-facing vocabularies in the engine.
- Author-facing extension points follow the `[EXT]` open-registry model unless a GDD
  section explicitly marks an engine-only exception.
- Public campaign packs are data + assets first. A future sandboxed scripting layer is
  allowed only as a bounded expansion after the data-only path is useful.
- The current dependency bands remain in force. This record reframes active prose and
  adds the web-demo target row; it does not reopen v1-scope decisions.

