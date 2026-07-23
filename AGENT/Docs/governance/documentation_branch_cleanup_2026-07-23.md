# Documentation and Branch Cleanup — 2026-07-23

**Type:** Governance record  
**Status:** Complete with preserved exceptions  
**Assumption:** `agent/stable-release` will be certified, advance through
`agent/staging-area` and `main`, and then be merged forward into
`agent/integration` before the campaign-data implementation slices begin.

## Documentation disposition

- Moved the loose campaign-data questions, documentation review, container
  tooling handoff, playtester comments, and GDD update reference into typed
  `AGENT/Docs/archive/` homes.
- Moved the retired Awakening content-expansion corpus out of the live GDD tree
  into `archive/reference/content_expansion/`, retaining historical markers and
  repairing its live links.
- Removed empty source directories and untracked `.import` cache debris whose
  source images were absent.
- Removed one exact duplicate Godot log and two byte-identical class drafts;
  their canonical copies remain in the archive.
- Regenerated the documentation index and repaired links to the relocated
  material.

## Branch disposition

Thirty local branches and one remote telemetry branch whose tips were already
reachable from retained lifecycle/release branches were deleted. Three further
local branches were deleted after content-equivalence checks. The remote
`agent/from-integration/ai-scorer-decisions` branch was deleted after proving
that its merge tree matched an already-reachable parent and both parents were
in `agent/integration`.

The following branches were deliberately retained because their unique commits
have not yet been dispositioned safely:

- `agent/GUI-testing`: four unique UI/research commits (also preserved by the
  existing `archive/agent/GUI-testing` tag).
- `agent/codex/2026-07-12/v0.3.2-build`: five unique historical build commits.
- `agent/codex/2026-07-16/recover-encounter-planning`: recovered planning work.
- `agent/codex/2026-07-16/recover-stale-main-ai-scorer`: recovered scorer and
  playtest evidence.
- `agent/codex/2026-07-16/recover-v041-playtest`: recovered v0.4.1 evidence;
  it subsumes the deleted local v0.4 build branch.
- `agent/coordination`: legacy coordination history in a separate worktree.
- `agent/playtest-release-v0.5-fixes`: two unique release-documentation commits.

## Deferred review questions

1. Should the uniquely committed GUI work be merged forward, or is the existing
   archive tag sufficient so the branch can be deleted?
2. Once the recovered v0.3.2/v0.4.x evidence is copied into the typed archive,
   may their recovery/build branches be deleted?
3. Has every still-relevant row from the legacy `agent/coordination` registry
   been migrated to workspace `coordination/tasks.json`, permitting retirement
   of that branch and worktree?
4. Should the two unique commits on `agent/playtest-release-v0.5-fixes` be
   retained as release-line history, or archived and retired after v0.5.4 is
   certified?

