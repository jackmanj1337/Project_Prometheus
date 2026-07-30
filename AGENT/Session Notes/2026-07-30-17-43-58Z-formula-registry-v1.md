# Session Notes — 2026-07-30-17-43-58Z-formula-registry-v1 (formula registry v1)

## What was done

- Added separate immutable hit, range, cost, and requirement formula registries.
- Routed combat hit evaluation, weapon range, and ledger quantity pricing through them.
- Preserved legacy range strings strictly through a compatibility adapter.
- Added validation, preview-purity, overflow, unknown-id, and unmet-reason fixtures.

## Factual Git state

- Branch: `agent/from-integration/formula-registry-v1`
- HEAD: `8a4d91683397b6eae477efcee58105548eff36ca`
- Task merge base: `8dd24243ad4a34cf78cf9c3e791122effee2d86f`

## Commits

- `8a4d91683397b6eae477efcee58105548eff36ca` — Implement formula registry v1
- `27c1cb41c7a4483f2ecb47c792a77aa3e8bd97ae` — Record formula registry session

## Checks

- No exact-HEAD receipts found

## Decisions and context

- Formula handlers receive purpose-built dictionaries and cannot access Nodes, paths, or mutation.
- Pack selector migration remains in base-pack extraction; this slice supplies and adopts primitives.

## Next session

Proceed with Tier-2/base-pack selector adoption after this branch reaches integration.
