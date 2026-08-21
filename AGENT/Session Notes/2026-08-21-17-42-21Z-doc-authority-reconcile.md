# Session Note - 2026-08-21

## Branch context

- Branch: `agent/from-integration/doc-authority-reconcile`
- Base branch: `agent/integration`
- Base SHA: `51a8e6a4c8e9646679d241bba02355a5fb2b0615`
- Coordination Work ID: `AUDIT-DOC-AUTHORITY-RECONCILE-2026-08-09`

## What was done

- Replaced the active June migration inventory with the present typed-tree lifecycle
  policy: generated retrieval manifests, typed homes, atomic link repair,
  supersession/archive rules, and the canonical cross-branch tracker.
- Reconciled `OPEN-11` across its decision record, decision index, GDD_00 platform
  authority, and GDD_07 cross-reference. The temporary letterbox choice was revisited
  when UI scale shipped: expand plus persisted Viewport Scale is delivered, while native
  Steam Deck validation remains outstanding. The index therefore says
  `Pending validation`, not `Implemented`.
- Added documentation check 47. It requires the lifecycle authority to name the typed
  homes, generated manifests, and layout owner, and rejects the specific obsolete
  flattened paths found by the August documentation review.
- Deliberately left campaign-resume and FileDialog GDD clauses untouched. The tracker
  assigns those corrections to their implementation/acceptance rows.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`, NOT here.

Commit 96314fb4 carries the authority rewrite, OPEN-11 reconciliation, regenerated
index, and paired mechanical guard.

The following closeout commit also refreshes the two edited GDD files' document-level
`Last verified` dates. That check only became red after 96314fb4 gave the files a new
Git commit date; keeping the repair separate preserves the evidence that the guard
caught its own omission.

## Gates

- `bash run_tests.sh` — PASS, all 148 suites green; required Python and browser tests
  also green.
- Exact staged-tree fast check from `agent-work commit` — PASS; receipt tree
  `76c024eb870c0ae712151e8eb7241b6dd9c29776`.
- `python3 AGENT/Docs/check_docs.py` — PASS, 47 checks.
- Negative in-memory probe — PASS: check 47 rejected
  `AGENT/Docs/decision_index.md` as an obsolete flattened path.
- `git diff --check` — PASS.

## Next

The owner selected `AUDIT-CONTROL-PLANE-LIVENESS-2026-08-09` for the next session.
Start it independently from the container repository's `agent/staging-area`; do not add
that infrastructure work to this product/documentation branch. Any returned Windows
playtest packet still preempts queued work.
