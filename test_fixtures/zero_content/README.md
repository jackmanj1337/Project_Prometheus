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

## Known vocabulary drift — normalize when the Tier-2 validator lands

These were authored against draft shapes and have **not** been reconciled with the
ratified contract in
`AGENT/Docs/plans/zero_content_engine_implementation_plan_2026-07-23.md`. They are
ported as-is rather than silently rewritten, because there is no engine validator
yet to prove a rewrite preserves each fixture's intended diagnostic. Fix these as
part of Tier-2 adoption, together with the expected-error corpus:

1. **All 11 manifests** carry `"internal_only": true`. The manifest key set (plan
   lines 50–62) has no such key; the field is `distribution_policy:
   private_only | authorized_internal | public_candidate`.
2. **All 11 manifests** use dotted `package_id`s (`internal.fixture.z0_...`).
   Package contract review finding 4 (`AGENT/Code
   Reviews/package_contract_plan_review_2026-07-30.md`) requires RFC 4122 UUIDs.
3. **`z1_invalid_missing_occurrence/data/sources.json`** uses
   `rights_status: "project_owned_test_data"`, outside the closed set
   `unchecked | verified | disputed | no_grant`; uses `verified_or_accessed_at`
   where the contract says `verified_at`; and omits `license_id`,
   `distribution_scope`, and `attribution_required`.
4. **`z1_valid_registry/data/sources.json`** uses
   `distribution_scope: "internal_only"`, outside the closed set
   `private_only | authorized_internal | public`; and `license_id:
   "project-owned"`, which is neither an SPDX id nor a `LicenseRef-*` as the
   contract requires when `rights_status` is `verified`.

Items 1 and 2 are exactly the regeneration the FE-pack tracker row still has
pending (review findings 4 and 5). Doing it here first means it happens once, in
the destination, rather than twice.
