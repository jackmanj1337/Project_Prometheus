You are an AI agent here to help me with my project and teach me to code better.

Be brief and quickly point out any errors and what problems they may cause

Admit when you don't know things

Ask questions whenever you think it would be useful, but provide a recommendation based on standard coding best practices

---

## Shared workspace rules

These apply to every repo in the `godot-prometheus-env` workspace and are kept
in sync automatically — see the note inside the block.

<!-- BEGIN SHARED: policy -->
<!-- Managed block — do not edit here. Edit config/shared/policy.md in the container repo, then run scripts/check-agents-sync.py --write -->

### Branch policy
- Agents may create, commit to, and push **only** branches matching `agent/**` —
  and within that namespace they **should** push freely. Pushing an `agent/**`
  branch to `origin` needs no user confirmation and no "recovery reason"; it is
  the normal way work is shared and backed up. Push early and often.
- Never push directly to `main`.
- **`agent/staging-area` is the only door to `main`.** Every repo has one,
  branched from its `main`. Agents merge into it; the human reviews and merges
  one PR, `agent/staging-area` → `main`. Nothing else opens a PR against `main`,
  and nothing reaches `main` by another route.
  - Keep it mergeable: it is only ever `main` plus work that is ready. If a
    change is not ready for a human to merge to `main`, it does not belong here
    — leave it on its own `agent/**` branch.
  - After the human merges it to `main`, `agent/staging-area` fast-forwards back
    onto `main` and the cycle repeats. The
    `.github/workflows/sync-staging-area.yml` job does this automatically.
- **How work reaches `agent/staging-area` depends on what it is.**
  - **Product** — game code, data, and content — goes through the release line
    first: `agent/integration` → `agent/playtest-release` → `agent/stable-release`,
    and only an accepted release merges from `agent/stable-release` into
    `agent/staging-area`. Product never shortcuts into the staging area, so
    everything that reaches `main` has been through playtest verification.
  - **Infrastructure** — hooks, CI workflows, `AGENTS.md` and the shared policy
    blocks, tracker and coordination files, container/tooling scripts — goes
    **directly** into `agent/staging-area` from its own `agent/**` branch. It is
    not release-gated, because gating a safety mechanism or a policy fix behind a
    game release delivers it late for no benefit.
  - When a change is genuinely both, split it: the product part takes the
    release line, the infrastructure part goes direct. If it cannot be split,
    treat it as product.
- In `Project_Prometheus` the other agent-owned lifecycle refs are
  `agent/stable-release`, `agent/integration`, `agent/playtest-release`, and
  `agent/coordination`. `agent/stable-release` is stable and is what merges into
  `agent/staging-area` on an accepted release, `agent/integration` is the normal
  **feature** base, `agent/playtest-release` isolates release hardening, and
  `agent/coordination` owns the active-work registry. `agent/staging-area` is
  not a feature base — feature work still starts from `agent/integration` and
  lands there. Do not revive the obsolete mixed-case `Agent/main` convention.
- **Merge policy — the target branch decides who merges.**
  - Agents **may** merge a feature or fix branch back into the `agent/**` base it
    forked from (its origin base), and may merge between `agent/**` branches
    generally, once the branch's required checks pass. No PR or human approval is
    needed for an `agent/**` → `agent/**` merge.
  - Agents **must not** merge anything into a non-`agent/**` branch. Any merge
    whose target is `main` (or any other non-`agent/**` ref) is a human action.
    Route it through `agent/staging-area` rather than handing off a branch of
    its own; use `prepare-manual-pr.sh` when a hand-off summary is wanted.
  - The rule is about the *target*, not the source: an `agent/**` branch merging
    into `main` is still human-only.
  - Enforcement, in layers: `pre-merge-commit` refuses a merge commit onto a
    non-`agent/**` branch; `pre-commit` refuses to *conclude* a merge there
    (git leaves a rejected merge staged and invites `git commit`); `pre-push`
    refuses any destination ref that is not `refs/heads/agent/*` or a `v*`
    release tag.
  - Known gap: a **fast-forward** merge onto `main` creates no commit, so no
    commit-time hook sees it. It is caught at push. `--no-verify` bypasses all
    of them — the hooks make the policy hard to violate by accident, not
    impossible to violate on purpose.
  - Two hook sets implement this and must stay aligned: `hooks/` in the
    container repo (installed by `scripts/install-hooks.sh --repo <name>`,
    used by the campaign packs) and a `scripts/hooks/` directory inside
    `Project_Prometheus`, which keeps its own versioned hooks and sets
    `core.hooksPath` to them.
- The container repo's `agent-start-task.sh` defaults to
  `agent/from-<base-leaf>/<slug>`,
  grouping every branch under the base it forked from (e.g. base
  `agent/integration` → `agent/from-integration/<slug>`; base `main` →
  `agent/from-main/<slug>`). The `from-` segment keeps the name distinct from the
  base branch itself so lifecycle bases don't trip the ref-prefix guard. The tool
  and date are recorded in the coordination registry, not the branch name, so the
  `<slug>` must be unique per base — the launcher hard-rejects a name that already
  exists. Override the whole name with `--branch` (still must start with
  `agent/`); release fixes use explicit sibling names such as
  `--branch agent/playtest-release-v0.5-fixes --base agent/playtest-release`. The
  launcher rejects local or remote ref-prefix collisions before creation.
- **Split confirmed work from visually-unverified work.** When a change set mixes
  an already-verified fix with newer work that still needs a Windows-host visual
  pass (the container can run headless/software rendering but cannot provide the
  required real visual validation), commit the confirmed
  fix to the active feature branch and put the unverified work on a separate
  branch that serves as that round's playtest build source until the visual pass
  confirms it, then merge back — both branches are `agent/**`, so the agent can
  do that merge itself once the visual pass lands. Push both to `origin` freely.

### Branch and tag policy
- Agents may create, commit to, and push branches matching `agent/**` freely.
- Agents may create and push release tags matching `v[0-9]*.[0-9]*.[0-9]*`.
- A release tag must point to the exact commit baked into the corresponding
  executable’s BUILD STAMP.
- Before pushing a release tag, agents must verify:
  - all required automated checks pass;
  - the executable was exported successfully;
  - its size and SHA-256 are recorded;
  - the tag does not already exist remotely at a different commit.
- Agents must never move, overwrite, force-push, or delete a remote tag.
- Correcting an incorrectly published tag requires explicit user approval.
- Agents must not push to, or merge into, `main` or any other non-`agent/**`
  branch.

### Attribution policy
- Git author stays the human identity. Never add a model as author,
  committer, or `Co-authored-by` trailer.
- Add tool/model metadata as commit trailers instead:
  ```text
  AI-Tool: <Codex CLI or Claude Code>
  AI-Model: <model if known, otherwise unknown>
  AI-Run-ID: <generated run id>
  AI-Workspace: godot-prometheus-env
  ```

### Protected files — never read, modify, or commit
- `.env`, `.env.*`
- `*.pem`, `*.key`, `*.p12`, `*.pfx`
- `secrets.*`, `credentials.*`
- signing credentials
- The container repo's `agent-commit.sh` also hard-blocks committing anything matching
  these patterns — treat that as a safety net, not the actual boundary.

Require explicit user approval before changing:
- `.github/workflows/**`
- `Dockerfile`, `docker-compose.yml`
- export signing config / release automation

### Line endings & binary handling
Follow the `.gitattributes` convention already used in `Project_Prometheus`
and apply it to the campaign packs too:
- Text/data formats (`*.sh`, `*.py`, `*.gd`, `*.cfg`, `*.tres`, `*.tscn`,
  `*.godot`, `*.json`) are LF-normalized so tooling and hooks survive a
  Windows-native checkout.
- `*.md` is left as plain `text` (no forced EOL).
- Binary assets (`*.png`, `*.jpg`, `*.wav`, `*.ogg`, `*.ttf`, `*.otf`,
  `*.import`) are marked `binary` — no EOL munging, no diff noise.

### Commit hygiene
- Make regular, small commits with messages describing the logical step, not
  a batch of unrelated changes.
- Run whatever `fast_test_command` is configured for the repo in
  `repos.yaml` before committing; run `full_test_command` before a push/PR
  handoff.
- **A textual merge conflict does not mean the work is missing.** Before doing a
  real merge or rebase of a branch that looks "genuinely unmerged", check whether
  its fixes already landed independently on the target — compare content and
  function signatures, not commit hashes. If the work is already present under
  different hashes, archive the branch rather than forcing a conflicted merge.
  Note the tag policy above only authorizes agents to create `vX.Y.Z` release
  tags, so record the archive as an `agent/archive/<branch>` branch (or ask a
  human to create a non-release `archive/<branch>` tag) — do not create the
  archive tag yourself.

### Task tracking (canonical)
- Active work across **all** repos and branches is tracked in
  `coordination/tasks.json` in the container repo (one level above `repo/`).
- Nothing may live only outside that tracker. Every open task, plan, handoff,
  sub-tracker, or checklist anyone is expected to return to must have a row —
  even when the detail lives in a document inside a project repo. The row may be
  a pointer: put the document path in the task's `reference` or `playtest_ref`.
- What is not allowed is open work recorded *only* in a per-repo plan, a session
  note, a branch name, or a PR description. A plan on an unmerged branch is
  invisible to anyone not standing on that branch.
- After adding or finishing work, run `coordination/gen_active_work.py` to
  regenerate the human-readable view, then `coordination/check_tasks.py` to
  validate.

<!-- END SHARED: policy -->

---

## Project_Prometheus-specific rules

### Code style & architecture

Keep code simple and readable, following GDScript style guidlines

Architecture principle — author-facing extension points are OPEN REGISTRIES, not closed type-switches. When a vocabulary will grow with content (objective conditions, AI profiles, prep/on-map activities & panels, effects, stat names, resource types, …), make it a **data-driven registry / predicate the engine reads**, NOT a hardcoded `enum` + `match` that needs an engine edit per addition. The closed enum is the smell: if adding content requires editing a GDScript switch, reconsider. This recurred repeatedly in design (objective conditions → `[TCV-4]`, AI profiles `[AIP]`, panel/activity types `[SAC]`, the mini-game module seam, stat model `[STM]`). Aligns with the ratified author-extensibility model `[EXT]` (data composition, engine provides primitives, no-code). Rationale + the full pattern: `AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md`.

Make and frequently use unit tests whenever they are reasonable

Leave clear concise comments explaining what each section does and why decisions were made

### Branch lifecycle (repo-specific detail)

The shared block above defines who may push and who may merge. Specific to this
repo: register ownership before implementation, and keep source SHA,
test/playtest evidence, and final disposition in the coordination registry. The
registry checker is the durable enforcement for this lifecycle.

### Task tracking (repo-specific detail)

The shared block above states the tracker rule. Specific to this repo: the
detail behind a tracked task normally lives here under `AGENT/Docs/`, so the row
in `coordination/tasks.json` may be a pointer — put the document path in the
task's `reference` or `playtest_ref`. What is not allowed is open work recorded
only in a plan under `AGENT/Docs/plans/`, a session note, a branch name, or a PR
description.

That tracker is the only artifact spanning every repo and branch, so it is the only
place "what is still outstanding" can be answered completely. A plan on an unmerged
branch is invisible to anyone not standing on that branch: that is how a returned
playtest sat untriaged and a migration sat gated on an already-rejected release.
Put real ordering in a task's `dependencies`, not only in `trigger` prose.

### Documentation

Branch lifecycle: `main` is the stable line, `integration` is the normal base
and target for feature work, `release/**` isolates release hardening, and
`coordination` owns the active-work registry. Agents work and push only on
`agent/**`; humans create or advance protected refs, merge reviewed work, and
retire superseded branches. Register ownership before implementation and keep
source SHA, test/playtest evidence, and final disposition in the coordination
registry. The registry checker is the durable enforcement for this lifecycle.

All Documentation should go and be read from the appropriate subfolder in the AGENT folder

Documentation layout & index (DSR, 2026-06-23): AGENT/Docs/ is sorted by TYPE — `guides/ governance/ decisions/ registers/ design/ plans/ playtests/` for live docs, and `archive/{consolidation,plans,playtests,handoffs,reference,evidence}/` for historical/superseded ones (never deleted; each archived .md carries a `> **Historical**`/`> **Superseded** by [..](path)` marker in its first 10 lines). Retrieval: `AGENT/Docs/INDEX.md` = what's active; `AGENT/Docs/REGISTERS.md` = the `[XXX-n]` open-question registers catalog (OPEN/RESOLVED + resolved-where); `AGENT/Docs/decisions/decision_index.md` = governance IDs (DOC/RULE/SET/OPEN/RNG/AWR). INDEX.md and REGISTERS.md are GENERATED — after adding/moving/retitling a doc or changing its header, run `python3 AGENT/Docs/gen_docs_index.py` and commit the result in the SAME change (enforced by check_docs.py check 18; design rationale in `AGENT/Docs/governance/documentation_system_design_2026-06-23.md`).

Documentation lifecycle definition-of-done (DoD#1, formerly PL#8): when a change alters behavior, update the affected GDD_01–08 section(s) AND flip the matching status in GDD_10_Roadmap.md in the SAME commit. Use the governance status vocabulary (AGENT/Docs/governance/documentation_governance_2026-06-13.md) — never the words "current", "complete", or "canonical" in a status-bearing section. (Pairs with the DOC-011 CI documentation checks.)

Enforcement definition-of-done (DoD#2, formerly PL#9): when you ratify a mechanical, checkable rule (a vocabulary ban, a required header, a path convention), land its automated check in the SAME change — extend AGENT/Docs/check_docs.py. A written rule with no check rots; check_docs.py runs in the pre-commit hook and in CI (.github/workflows), so it is the durable enforcement, not prose.

Code review instructions are in the AGENT/Docs folder

### Session notes

These notes should include what was done that session, the commits made and plans for next session,

When you create a session note, start from `AGENT/Session Notes/TEMPLATE.md`, claim
each substantive non-merge commit by exact full SHA and subject, and add a one-line
row to `AGENT/Session Notes/INDEX.md` (newest first, with a brief topic summary).
Run `bash scripts/session_closeout.sh` before handing off or pushing.

Every time a new session is started go back and read the notes from the most recent session (and skim INDEX.md to locate older relevant notes).

---

If I say "Status Report" respond with "All Systems Online"
