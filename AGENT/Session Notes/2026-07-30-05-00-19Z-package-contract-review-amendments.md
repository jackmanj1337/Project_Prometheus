# Session Notes — 2026-07-30-05-00-19Z-package-contract-review-amendments

## Branch context

- Branch: `agent/from-integration/package-contract-review-amendments`
- Base branch: `agent/integration`
- Base SHA: `0704ac90907c608e0573d79cd04269d78a1dc351`
- Coordination Work ID: `AMEND-PACKAGE-CONTRACT-REVIEW-FINDINGS-2026-07-30`

## What was done

- Owner decision recorded: **Option A** for review finding 1 — the `on_zero`
  vocabulary reverts to the ratified REQ-16 set. Band-3 Slice 5 now serializes
  `"on_zero": "to_max" | "to_zero" | {"to_value": <ValueTerm>}` with defined
  semantics (clamp ceiling / zero / fallback term; never a runtime error), citing
  the review and decision date. The owner also approved the three recommended
  defaults: staged P0, conservative ASCII path grammar, and documenting the
  two-valued `not`-over-absent-subject behavior.
- Zero-content plan amendments (findings 2, 3, 7, 10): fingerprint step 1 now
  defines the admitted ASCII path grammar; step 3 enumerates the exact excluded
  manifest keys, rejects unknown manifest fields before hashing, and pins the
  projection to RFC 8785 canonical JSON with integer-only numbers and no trailing
  newline; the algorithm-id record encoding is exact; the receipt lives in
  engine package-library metadata, never inside the pack root; fingerprints are
  defined only for structurally closed packs (draft backups get an archive
  checksum with no snapshot-identity claim); the engine schema registry owns the
  closed diagnostic-code registry, with the private corpus codes provisional
  until Z0 parity.
- Band-3 plan amendments (findings 6, 8, 9): added the P0/P1 private-parity test
  bullet mirroring the zero-content Z0/Z1 bullet; documented and test-pinned that
  `not` over an absent-subject predicate evaluates true; replaced the stale
  colon-encoded subject shorthand in step 2 with the canonical subject objects.
- Archived the executed review handoff to `AGENT/Docs/archive/handoffs/` with a
  Historical marker, retired its doc-role-manifest ownership row, and repaired
  its relative links plus the review document's back-link.

## Commits claimed

- `572b84c3d41f5985df3b56c9f03f9faad8181db8` — Land package contract review amendments (owner: on_zero Option A)

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` + `python3 AGENT/Docs/check_docs.py`:
  PASS — all 43 documentation checks green.
- `git diff --check`: clean. Docs-only change; pre-commit skipped the Godot suite
  by policy.
- Workspace tracker validation recorded in the container-repo commit for this
  session.

## Next

Z0 canonical-validator implementation may start from `agent/integration` (blocking
amendments 1–3 are landed), pairing with the private Z0/Z1 receipts. FE-side work
stays with `ZERO-CONTENT-PREDICATE-FIXTURE-PLAN-2026-07-29`: regenerate fixture
manifests (UUID `package_id`s, `distribution_policy: private_only`) before Z0/Z1
parity, and stage P0 into P0a/P0b before predicate fixture authoring.
