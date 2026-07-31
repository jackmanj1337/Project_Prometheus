# Session Note - 2026-07-31 (zero-content Slice 2: fixture port + edge/route schemas)

## Branch context

- Branch: `agent/from-integration/zero-content-families-class`
- Base branch: `agent/integration`
- Base SHA: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`
- Coordination Work ID: `IMPL-ZERO-CONTENT-FAMILIES`

## What was done

Two pieces, both on the zero-content Slice 2 line.

**1. Ported the synthetic Z0/Z1 fixture corpus out of the FE pack.** The Z0/Z1
tranches authored under `ZERO-CONTENT-PREDICATE-FIXTURE-PLAN-2026-07-29` in
`Project_Prometheus_Campaign_Pack_FE` contain no FE-derived data — every record is
synthetic and project-owned. The fixture plan calls for engine tests to use
"synthetic equivalents"; these already are them, so re-authoring them here would
have produced a second diagnostic corpus destined to drift. Ported verbatim into
`test_fixtures/zero_content/` (35 files) plus
`test_fixtures/zero_content_expected_errors/` (8 files), with a README recording
provenance and four known vocabulary drifts against the ratified package contract
(manifest `internal_only`, dotted `package_id`s, out-of-vocabulary `rights_status`
and `distribution_scope`). Ported as-is rather than rewritten because there is no
Tier-2 validator yet to prove a rewrite preserves each fixture's diagnostic.

Two of those drifts are exactly the regeneration the FE-pack tracker row still has
pending (review findings 4 and 5). Doing it in the destination means it happens
once rather than twice. The FE pack keeps its copies for now so its standalone
`pytest` suite still runs.

**2. Registered the `advancement_edge` and `advancement_route` schemas** — the
"edge/route schemas" gap named in the `IMPL-ZERO-CONTENT-FAMILIES` row, and the
next class-family exit after the 2026-07-30 class foundation. Fixed and branching
edges share one schema and one commit path, differing only in destination count.
Edge variants are deliberately narrower than class variants: destination, gains,
and operations only, never the routes that gate the transition.

Descriptors previously had no trusted-registry check at all, so a pack could name
any `handler_id` and fail only at runtime, mid-transition. Added an **open handler
registry** (`EntitySchemaRegistry.register_handler`, seeded with
`class_advancement_v1`): unknown handlers and unadmitted handler versions now fail
validation before preview. Built as a registry rather than a match statement per
the repo architecture principle — adding a handler is a registration, not an
engine edit.

## Commits claimed

- `58cddb177aefe2ce1468d5c905cc2409c96b158e` — Port synthetic Z0/Z1 zero-content fixtures into the engine
- `b29359d21bf908f602f4a53508c71482b3d3d924` — Add advancement edge/route schemas and a trusted handler registry

## Gates

- `bash scripts/godot-import-cache.sh --repo Project_Prometheus` — import pass run
  before testing (a bare `--quit` rebuilds neither the import nor the class cache).
- `bash run_tests.sh` — PASS, all suites green, both before and after the change.
- `godot --headless --script scripts/tests/test_entity_schema_registry.gd` —
  22 passed, 0 failed (13 pre-existing + 9 new: golden edge, fixed/branching parity,
  empty-destination rejection, edge variant override boundary, unknown handler,
  unsupported handler version, golden route, zero-requirement route, untrusted
  requirement descriptor).
- `gdformat --check` clean on both touched scripts.

## Next

Remaining on the class family before it closes: variant **eligibility** descriptors
are still not handler-checked. Class and edge variants are consistent in this today,
and closing it should close both together — doing only edges would make the two
variant kinds diverge. Then complete occurrence auditing, Tier-2 catalogue/runtime
adapter adoption, cross-references, fixtures wired to the ported corpus, and durable
selection round-trips. After that, the next family in the plan's migration matrix.

Not done, and flagged to the owner: the FE-pack fixture plan's 16-item
"Plan-completeness checks against the public engine work" list is largely stale —
spot-checking it against `band3_core_authoring_foundations_implementation_plan_2026-06-30.md`
Slice 5 and the zero-content plan, most items are already answered (predicate/value-term
serialization, unavailable-subject semantics, complexity budgets, consumer context
bindings, unmet-reason presentation, fingerprint byte stream, quarantine, draft-waivable
provenance, rights/licence/distribution vocabulary, SVG admission). That list lives on
`codex`'s in-progress branch, so it was left untouched rather than edited underneath
active work.
