# Session Note - YYYY-MM-DDx

## Branch context

- Branch: `agent/<owner>/<date>/<task>`
- Base branch: `agent/integration`
- Base SHA: `0000000000000000000000000000000000000000`
- Coordination Work ID: `WORK-ID`

## What was done

- Summarize outcomes and evidence.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`, NOT here. Claim as you go:

    python3 scripts/ci/check_session_commit_claims.py --fix

Do not write `` - `<sha>` — <subject> `` lines in this note; the check rejects a claim
that exists only in note prose, because that is the retired model. Describe the work
below in whatever form is useful to a reader — short SHAs in prose are fine.

- What the commits accomplished, and why.

## Gates

- Record commands, pass/fail counts, and evidence paths.

## Next

State the next bounded action or explicit blocker.
