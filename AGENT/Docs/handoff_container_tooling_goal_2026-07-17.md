# Handoff — Container Tooling and Agent Workflow Goal

**Prepared:** 2026-07-17  
**Next-session mode:** Create and pursue one persistent goal  
**Primary repository:** `https://github.com/jackmanj1337/Project_Prometheus_Container`  
**Source review:** `AGENT/Code Reviews/process_history_tooling_review_2026-07-17.md`

## Goal to create next session

Use the goal mechanism at the start of the next session with this objective:

> Version, test, and harden the Godot Prometheus top-level container tooling in `Project_Prometheus_Container`; implement the approved phased workflow improvements for safe multi-repository agent work; migrate ownership of top-level scripts, container files, and shared agent policy into that repository; verify the complete workflow in disposable repositories; and deliver the work on an `agent/**` branch with a human-review handoff, without changing game behavior or merging a PR.

Do not set a token budget unless the user explicitly requests one. Keep the goal active across turns until every accepted phase below is implemented and verified, or a genuine external decision/blocker prevents further progress.

## Confirmed decisions

The user approved the overall recommendations with these choices:

1. `Project_Prometheus_Container` is the versioned owner for top-level Docker/container files, shared scripts, `repos.yaml` support, and multi-repository agent instructions.
2. Existing credentials have read and push access. On 2026-07-17:
   - remote `HEAD` resolved to `main` at `e6b7934afe7cb83559d1011f14e0a340ab3f6b56`;
   - an authenticated `git push --dry-run` to `agent/access-check` succeeded;
   - no remote branch was created by the check.
3. Rename `export-linux-steamdeck.sh` to a generic Linux exporter. Do not claim Steam Deck validation until explicit Deck-specific checks exist.
4. Test receipts may be reused only when they match the exact staged tree or exact `HEAD` and the same configured command.
5. Active-work coordination should update `agent/coordination` automatically, using fetch/validate/commit/push with bounded retry and never force-pushing.
6. Build a tested CLI/library first. An MCP server is optional and must be a thin adapter over the same core, not a second implementation.

## Starting state and cautions

- Workspace root: `/workspace/godot-prometheus-env`.
- The workspace root is not currently a Git checkout. Its top-level files and scripts therefore lack history.
- The new container repository was not cloned during the review. Discover its contents before planning migration; do not assume it is empty.
- `Project_Prometheus` was already dirty before the review. Existing modifications include playtest/GDD files, `CLAUDE.md`, and untracked `builds/`. Preserve them. Do not use `git add -A` or otherwise absorb them.
- The review and this handoff are the only intended files added by this review session.
- Changes to Dockerfiles, Compose files, GitHub workflows, signing configuration, or release automation require explicit user approval before editing. Inspection and planning are allowed.
- Never read or copy `.env`, `.env.*`, credentials, signing keys, or other protected files.
- Agents may push only `agent/**` branches and must not merge PRs.

## Required startup sequence

1. Create the goal using the objective above.
2. Read, in order:
   - this handoff;
   - `AGENT/Code Reviews/process_history_tooling_review_2026-07-17.md`;
   - `/workspace/godot-prometheus-env/repo/AGENTS.md`;
   - `/workspace/godot-prometheus-env/config/AGENTS.godot.md`;
   - the new container repository's own `AGENTS.md`, if present.
3. Read the latest `Project_Prometheus` session note and skim its INDEX only for context; do not alter unrelated project work.
4. Inspect the remote/container repository and its branch policy. Clone it into the manifest-appropriate location without overwriting any existing directory.
5. Pin and report the container repository branch, HEAD, worktree status, remotes, and applicable instructions.
6. Create an `agent/**` task branch from the repository's intended development base. If the repository does not yet define one, use an `agent/codex/<date>/<slug>` branch from `main`; do not invent lifecycle branches until the repository policy is established.
7. Inventory source and destination files and propose an explicit migration map before moving or deleting anything.

## Scope and implementation order

### Phase 1 — Put the tooling on a safe foundation

- Establish clear repository ownership for:
  - `scripts/**`;
  - `docker/**`, `docker-compose.yml`, and related container setup files;
  - shared/multi-repo `AGENTS.md` and supporting documentation;
  - `repos.yaml` schema/example, while keeping machine-specific or secret values out of Git;
  - relevant root documentation and Renovate configuration if appropriate.
- Do not blindly copy cache/artifact files. Exclude `*:Zone.Identifier`, `__pycache__`, builds, audit output, and secrets.
- Add or repair `.gitignore`, `.gitattributes`, executable bits, installation/bootstrap documentation, and a non-secret example manifest.
- Add a tooling test entry point covering:
  - `bash -n`;
  - ShellCheck;
  - Python unit tests;
  - shell integration tests using temporary Git repositories and bare remotes.
- Add `repoctl validate` with complete, aggregated errors for duplicate names/paths, path containment, known repo kinds, URLs, branch-prefix policy, and scalar command fields.
- Correct false-success behavior in `setup-project.sh` and `godot-import-cache.sh`.
- Standardize argument-value validation and meaningful exit codes.

**Phase 1 gate:** tests demonstrate failed imports/checks return nonzero, invalid manifests are rejected, and valid existing manifest behavior remains compatible.

### Phase 2 — Enforce the already-approved agent workflow

- Change `agent-commit.sh` so explicit paths are the default; require an explicit `--all` for whole-tree staging.
- Preserve unrelated pre-staged/user changes and show the selected scope before committing.
- Run or accept an exact-tree fast-check receipt before commit.
- Add required commit trailers without changing the human Git author/committer:
  - `AI-Tool`;
  - `AI-Model`;
  - `AI-Run-ID`;
  - `AI-Workspace: godot-prometheus-env`.
- Require an exact-HEAD full-check receipt before push/handoff.
- Allow exceptional bypass only with an explicit recorded reason.
- Rewrite manual PR preparation to fetch and fail closed, use the merge base, report the complete range/count, validate trailers and receipts, avoid overwrites, and emit Markdown plus JSON.

**Phase 2 gate:** disposable-repo tests cover unrelated edits, existing staged files, protected filenames, failed checks, stale receipts, missing target refs, complete diff generation, and trailer preservation.

### Phase 3 — Make history work faster

- Add session-note scaffolding that selects collision-free names, pre-fills factual Git/check data, and atomically inserts the INDEX row.
- Keep summaries, decisions, and next-session narrative human-authored.
- Add a read-only history audit with structured output for:
  - session note/INDEX consistency and ordering;
  - commit-size/message trends;
  - anchored review score extraction;
  - decision-index duplicate/status/supersession checks;
  - version/tag/build-manifest traceability.
- Do not automate judgment about severity, scope drift, or whether behavior required a GDD update.

**Phase 3 gate:** run the audit against `Project_Prometheus` and confirm it reproduces the known 100-note/100-index-link consistency result without modifying that repository.

### Phase 4 — Implement active-work coordination

- Define and document a small machine-readable registry schema containing repository, branch, base branch/SHA, slug, tool, run ID, claimed paths/area, created time, and status.
- Implement register/list/close/prune/status operations.
- Detect overlapping claims and stale registrations.
- Update `agent/coordination` with fetch → validate → commit → push and bounded non-fast-forward retry.
- Never force-push or silently overwrite another registration.
- Decide and test recovery behavior when the task branch is created but registry publication fails.

**Phase 4 gate:** concurrency tests simulate two writers and prove no registration is lost.

### Phase 5 — Consolidate export and release tooling

- Rename `export-linux-steamdeck.sh` to generic Linux, with a compatibility message/wrapper if needed.
- Factor Windows, Linux, and Web export scripts through one tested implementation while retaining clear user-facing commands.
- Add development and release modes.
- In release mode require clean, exact-HEAD-tested source; validate the preset; avoid accidental overwrite; and record source SHA, Godot version, platform, preset, size, SHA-256, and BUILD STAMP evidence.
- Verify expected Web artifact files and basic artifact postconditions.
- Add a safe release-tag verifier consistent with the existing no-move/no-overwrite policy.
- Fix `serve-web-local.sh` so `--repo` serves the repository's actual `index.html` directory.
- Make `update-tools-build.sh` use explicit/locked versions instead of defaulting to `latest`; editing this script or Docker configuration requires the user's explicit approval.

**Phase 5 gate:** test non-release exports where practical; use mocks/fixtures for destructive or unavailable platform operations; do not publish a release or tag merely to test the tooling.

### Phase 6 — Improve adoption, then decide on MCP

- Provide one canonical CLI over the tested Python workflow core, with existing shell names as compatibility wrappers.
- Update the applicable shared `AGENTS.md` with a concise mapping requiring the canonical commands for branch creation, checks, commits, pushes, handoffs, exports, releases, coordination, and session closure.
- Add `status --agent` output showing repo, branch, dirty state, registration, valid receipts, and exact next actions.
- Use hooks/remote protections to validate outcomes; do not rely only on prose.
- Audit and report bypasses with reasons.
- Measure whether agents still bypass or mis-parameterize the CLI.

**MCP decision gate:** only after the CLI is stable, add an MCP adapter if discoverability remains a demonstrated problem. Start read-only (`workspace_status`, `list_repos`, `task_status`, `history_audit`, `handoff_preview`). Mutating tools must call the same tested core and must not duplicate policy logic.

## Architecture constraint

Use this dependency direction:

```text
tested Python workflow library
├── canonical CLI for humans, agents, hooks, and CI
├── thin shell compatibility wrappers
└── optional thin MCP adapter
```

Do not place workflow rules independently in shell, Python, and MCP layers. The core library owns validation and state transitions; interfaces translate arguments and render results.

## Verification requirements

- Every substantive script retains a useful documented purpose or is replaced by a compatibility wrapper with a migration path.
- No operation stages files outside explicit scope unless `--all` is present.
- A receipt is valid only for the exact tree/HEAD and configured command that produced it.
- Missing/stale remote refs fail clearly rather than falling back to unrelated Git ranges.
- Setup/import/test failures propagate nonzero status.
- Temporary-repository tests cover dirty trees, detached HEAD, missing remotes, branch/ref-prefix collisions, failed checks, staged-scope preservation, and concurrent coordination updates.
- No test prints credentials or reads protected files.
- No remote tag is moved, deleted, overwritten, or created solely for testing.
- No direct push to `main`; no PR merge.

## Documentation and delivery

- The container repository should become the authoritative home for the migrated top-level tooling documentation and shared agent policy.
- Once that home exists, replace duplicated workspace/project descriptions with short links or generated copies where needed; avoid independent policy copies that can drift.
- Record architectural and operational decisions in the container repository.
- Make small commits by logical phase with required trailers and test evidence.
- At session end, write the appropriate session/handoff note in the container repository and generate a manual PR handoff.
- Push only the `agent/**` branch. Leave PR creation/merge to the established human process unless the user separately authorizes draft-PR creation.

## Stop and ask the user when

- The container repository already contains conflicting ownership or architecture rules.
- Migration would delete or overwrite top-level files whose source of truth is ambiguous.
- A requested change touches Docker/Compose, GitHub workflows, signing, or release automation without explicit approval.
- Remote branch protection prevents the approved coordination design.
- A choice would materially break existing host commands rather than providing a compatibility period.

## Definition of done for the goal

The goal is complete only when the approved phases are implemented in the versioned container repository, automated tests pass, migration/installation instructions work from a clean checkout, compatibility and coordination behavior are verified, the Linux exporter is generically named, the adoption policy is updated, and a pushed `agent/**` branch plus human-review handoff contains all work. MCP implementation is not required unless the Phase 6 decision gate demonstrates that it adds value.
