# Zero-content Z0/Z1 fixture corpus

Synthetic, project-owned acceptance fixtures for zero-content boot, catalogue
closure, and the provenance (source/occurrence/media registry) contract.

## Where these came from

Authored under `ZERO-CONTENT-PREDICATE-FIXTURE-PLAN-2026-07-29` in
`Project_Prometheus_Campaign_Pack_FE` (branch
`agent/from-main/zero-content-predicate-fixture-plan`, Z0 and Z1 tranches,
2026-07-29/30) and ported here verbatim on 2026-07-31.

They were ported because they contain **no FE-derived data** — every record is
synthetic and project-owned (`locator: internal://synthetic-source`). The fixture
plan states that "public engine tests use synthetic equivalents"; these already
*are* the synthetic equivalents, so re-authoring them in this repo would have
produced a second diagnostic corpus destined to drift from the first. The private
pack keeps the tranches where FE data genuinely enters (Z2 and P0–P3).

The FE pack copies remain in place for now so its standalone `pytest` suite keeps
running. Once the engine-side Tier-2 validator exists, that suite should consume
this corpus as a parity client rather than keep its own copy — see
`planning/zero_content_predicate_fixture_plan.md` in the pack repo, which already
declares its `tests/test_zero_content_fixtures.py` "deliberately non-canonical" and
slated to become an engine-validator parity client.

## Contents

`z0_*` — manifest/catalogue shells and structural failures: complete-empty,
draft-disabled, unsupported schema, unsafe path, case-folded id collision.

`z1_*` — provenance registry: one valid source/occurrence/media registry plus
missing source refs, dangling source, missing occurrence coverage, unindexed byte,
and a multi-error fixture that locks aggregation and stable ordering.

Expected diagnostics live outside the package roots, in
`test_fixtures/zero_content_expected_errors/`, keyed by fixture directory name.

## Contract normalization

Normalized on 2026-07-31 from the FE-pack authoring copy and mirrored here: every
manifest has a deterministic RFC 4122 UUID and `distribution_policy: private_only`;
source records use the ratified rights vocabulary and
`LicenseRef-Project-Prometheus-Test-Data`. The engine-owned fixture validator now
proves that normalization preserved every intended diagnostic.
