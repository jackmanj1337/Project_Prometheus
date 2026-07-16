# Project Prometheus Coordination Registry

This orphan branch is the repository-local coordination source of truth. It is
never merged into gameplay branches.

- `branches.yaml` is authoritative for work and release records.
- `ACTIVE_WORK.md` and `RELEASE_TRAINS.md` are generated views.
- Git refs are authoritative for physical branch and tag existence.
- Numbered GDD documents remain authoritative for intended game behavior.

Use the scripts in `scripts/` rather than editing generated Markdown. Mutating
commands fetch and fast-forward this branch, update the registry, validate it,
commit, and push. Set `COORDINATION_BRANCH` while testing an agent candidate;
the permanent branch defaults to `coordination`.

```sh
scripts/work-status.sh
scripts/check-work-registry.sh
scripts/start-work.sh WORK-ID "Title" agent/codex/2026-07-16/example codex integration main SHA
scripts/pause-work.sh WORK-ID "Reason"
scripts/finish-work.sh WORK-ID MERGE_OR_PR_REFERENCE
scripts/start-release.sh v0.5.0 release/v0.5.0 integration SHA
```

Feature branches consume the pushed map with:

```sh
git show origin/coordination:ACTIVE_WORK.md
```

The permanent `coordination` ref and worktree require human creation under the
current protected-branch policy. Until then this candidate is exercised through
`agent/codex/2026-07-16/coordination-candidate`.
