---
Type: code review
Status: Active - implementation readiness evidence
Last verified: 2026-07-28
---

# FE Schema Implementation Readiness Audit

## Verdict

The accepted planning contracts can be landed on `agent/integration` now as a
documentation-only extraction. Runtime implementation must still wait for the active
v0.5.8 return, release acceptance, and release/integration reconciliation.

Do not merge `agent/from-integration/campaign-data-research` wholesale: it is 84
commits and 103 changed files ahead of integration. This preparation branch instead
extracts only the campaign-ownership findings, five approved implementation plans,
their GDD/control-plane wiring, and the accepted FE schema contract/handoff edits.

## Release/integration audit

Fetched identities on 2026-07-28:

- `origin/agent/integration`: `58a4a049`
- `origin/agent/playtest-release-v0.5.8-fixes`: `bd6b5adb`
- merge base: `258ed12a3842`
- divergence: integration has 72 unique commits; v0.5.8 has 99 unique commits.
- `origin/agent/stable-release`: `c88ce987`, an ancestor of integration with no
  unique stable commits.

A non-mutating `git merge-tree --write-tree` reports 11 textual conflicts, all in
documentation, policy, session history, or hooks:

- `AGENT/Docs/INDEX.md`
- `AGENT/Docs/plans/project_control_plane_2026-06-29.md`
- `AGENT/GDD/GDD_07_Screens_Panels.md`
- `AGENT/GDD/GDD_10_Roadmap.md`
- `AGENT/Review Procedures/00_Master_Review_Procedure.md`
- `AGENT/Session Notes/2026-07-17.md`
- `AGENT/Session Notes/2026-07-19.md`
- `AGENT/Session Notes/INDEX.md`
- `AGENTS.md`
- `scripts/hooks/pre-commit`
- `scripts/hooks/pre-push`

This refresh does not authorize the merge. After the v0.5.8 result is accepted,
repeat the audit against the accepted release tip, preserve both session histories,
regenerate documentation indexes, and retain the newest aligned policy/hook guards.

## Entity-schema prototype reuse decision

`agent/from-integration/entity-schema-prototype` is two commits ahead of integration
(`286b062f`, `39a99863`) and changes only `EntitySchemaRegistry.gd`, its focused test,
and session evidence. It is a useful scaffold, not a complete implementation slice.

Reuse:

- engine-owned `kind@version` schema selection;
- fail-closed unknown schema and unknown field handling;
- deterministic field traversal and exact JSON-style paths;
- nonempty resolving `source_refs` and structured error codes;
- pure, headless validation with no pack executable authority.

Extend before adoption:

- the accepted existing `ClassData` field vocabulary;
- package/catalogue/document/field context and suggested fixes in errors;
- distinct missing document, dangling reference, and missing occurrence-audit codes;
- source-registry and occurrence-audit schemas plus draft-only waiver classification;
- bounded class and advancement-edge variants;
- `ClassAdvancement` edges/routes and cross-owner override rejection;
- generated schema/golden/invalid fixture projections.

Therefore do not merge the prototype as a standalone finished feature. Start the
class vertical from its validator/test structure after `IMPL-FORMULA-REGISTRY-V1`,
then expand it under `IMPL-ZERO-CONTENT-FAMILIES` and its recorded exits.

## Ready branch and check sequence

After live acceptance and reconciliation:

1. Start `agent/from-integration/zero-content-foundation` for
   `IMPL-ZERO-CONTENT-FOUNDATION`; run no-pack boot, atomic activate/deactivate,
   invalid-pack diagnostics, docs, and the full suite.
2. Start `agent/from-integration/formula-registry-v1` only after foundation merges;
   verify hit RNG vectors, range bounds, cost preview/commit purity, predicates, and
   versioned pressure formula descriptors.
3. Start `agent/from-integration/zero-content-families` only after formula v1;
   begin with the class/provenance/variant/advancement vertical and its exact-path,
   migration, and no-mutation failure fixtures.
4. Start `agent/from-integration/progression-pressure` only after the class vertical;
   cover no-profile compatibility, committed-route-only updates, caps/rounding,
   save/suspend/Retry/Rewind, and preview/execution parity.

Each branch targets `agent/integration`, registers exact paths before editing, and
stops at a green commit if the v0.5.8 return arrives.
