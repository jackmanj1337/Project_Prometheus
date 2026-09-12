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
  - **Infrastructure that other branches EXECUTE must also reach the feature
    base.** Going direct to `agent/staging-area` is right, but staging only ever
    flows onward to `main` — never back into `agent/integration`. So a hook or CI
    check that feature branches *run* lands where those branches can never see it,
    and the two lines silently run different code. That is not hypothetical: it is
    how the session-claim check came to give two tools opposite verdicts on the
    same commit. After landing such a change on staging, merge it to
    `agent/integration` as well. In `Project_Prometheus`,
    `scripts/ci/check_shared_infrastructure_sync.py` fails the staging push that
    would create the gap.
  - When a change is genuinely both, split it: the product part takes the
    release line, the infrastructure part goes direct. If it cannot be split,
    treat it as product.
- In `Project_Prometheus` the other agent-owned lifecycle refs are
  `agent/stable-release`, `agent/integration`, and `agent/playtest-release`.
  `agent/stable-release` is stable and is what merges into
  `agent/staging-area` on an accepted release, `agent/integration` is the normal
  **feature** base, and `agent/playtest-release` isolates release hardening.
  Workspace `coordination/tasks.json` owns the active-work registry; the retired
  Project-local coordination branch is preserved only under the
  `archive/agent/coordination-registry` tag. `agent/staging-area` is not a feature
  base — feature work still starts from `agent/integration` and lands there. Do
  not revive the obsolete mixed-case `Agent/main` convention.
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
  - **There is no server-side enforcement.** These repos are private on a plan
    where branch-protection rules can be created but are *not enforced*, so
    nothing on GitHub's side can refuse a bad push. The hooks are not a backup
    layer — they are the only preventive control. Treat `--no-verify` as a
    policy violation, not a shortcut.
  - Because of that, hooks must be *verifiably* active: the container repo's
    `check-hooks.sh` asserts every repo has `core.hooksPath` set and every
    required hook present
    **and executable** (git silently skips a non-executable hook), `--fix`
    installs them, `clone-repo.sh` installs them on clone, and `health-check.sh`
    counts a missing hook as a health finding.
  - Detection backs up prevention: the `sync-staging-area` workflow verifies on
    every push to `main` that each new non-merge commit was already on
    `agent/staging-area`, and fails loudly if not. It cannot block the push, but
    it will not silently fast-forward over one either.
  - Known gap: a **fast-forward** merge onto `main` creates no commit, so no
    commit-time hook sees it. It is caught at push, and after the fact by the
    provenance check above.
  - Two hook sets implement this and must stay aligned: `hooks/` in the
    container repo (installed by `scripts/install-hooks.sh --repo <name>`,
    used by the campaign packs) and a `scripts/hooks/` directory inside
    `Project_Prometheus`, which keeps its own versioned hooks and sets
    `core.hooksPath` to them.
- **Retiring a ref: archive as a TAG, never as a branch.** A retired `agent/**`
  ref is preserved as `archive/agent/<its original name>` — e.g. branch
  `agent/from-integration/foo` → tag `archive/agent/from-integration/foo` — and
  the branch is then deleted. Ruled 2026-08-23; it converges two conventions that
  had both been in use (14 `archive/*` tags from before July, and 31
  `agent/archive/**` branches created by the 2026-08-12 retirement review).
  - **A tag is the correct primitive because it preserves reachability.** A commit
    lives exactly as long as some ref reaches it; deleting the last such ref loses
    it. Consolidation can only *move* a ref, never remove it, so archiving frees
    no clone space — history retains the bytes either way. The win is that
    `git branch -r` then lists only live work.
  - **Archive tags are immutable and create-only.** `pre-push` in both hook sets
    refuses to move an existing `archive/agent/**` tag, and exempts these tags
    from the exact-HEAD and full-suite checks — an archive tag points at a retired
    tip by design, never at current HEAD.
  - **Never delete an archive tag.** Confirm content has genuinely landed before
    retiring anything (compare content and function signatures, not commit
    hashes), and remember that containment in a base is necessary but not
    sufficient — a ref cited by a non-`completed` tracker row still anchors that
    row's claim verification.
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
- Agents may create and push archive tags matching `archive/agent/**`, which
  retire an `agent/**` ref (see *Retiring a ref* above). Create-only: `pre-push`
  refuses to move one, and the never-move/never-delete rule below applies in
  full.
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
  different hashes, archive the branch rather than forcing a conflicted merge —
  as an `archive/agent/<branch>` **tag**, per *Retiring a ref* above. (Until
  2026-08-23 this clause said the opposite: that agents could not create archive
  tags and should record the archive as an `agent/archive/<branch>` branch. That
  instruction is what produced the 31 archive branches the 2026-08-23 conversion
  had to undo.)

### Process machinery (one-in-one-out)

Every gate, hook, guard, tracker, register and document class here was a rational
fix for a real incident. The flaw is not any one of them — it is that the set is
append-only.

- **Adding a check, hook, guard, document class or tracker requires naming one to
  retire.** State the retirement in the same change that adds the mechanism.
  "Nothing to retire" is a permitted answer only when it is written down with a
  reason; it is never the default.
- This binds process machinery only. It does not bind product code, tests of
  product behaviour, or a pack's own content.
- The rule exists because the cost is invisible until someone measures it.
  Measured 2026-08-23 on `agent/integration`: 226,030 lines of markdown against
  335 tracked `.gd` files; 596 session notes (the practice was retired
  2026-08-23 and the corpus frozen); 78 registers with **zero** still
  open; 119 plans; 473 tracker rows across 14 phases. The pre-commit hook had
  spent **≈3.95 h of the prior 30 days linting every tracked `.gd` file on commits
  that contained no GDScript at all** — half the total hook budget, unnoticed
  until it was timed.
- It also binds cleanup. Closing one staging-line infrastructure drift "properly"
  on 2026-08-23 would have meant landing three NEW guards to fix the damage caused
  by carrying too many. That is precisely the shape this rule exists to stop: the
  remedy for append-only machinery must not itself be an append.

### Correct a document in place

**When a document is wrong, edit it. Do not write a new dated document saying so.**
Owner-ruled 2026-08-23, and it applies to dated records too — session notes,
playtests, code reviews, registers — not only to maintained guides.

- **Git is the history mechanism.** A second file was never serving that purpose; it
  was making the corpus bigger and the current answer harder to find.
- What a correction owes is a line in the document itself saying what changed and
  when, not a new file.
- This is why the corpora here grew append-only: being wrong produced another dated
  document, every time. Measured 2026-08-23: 224,535 lines of markdown, of which the
  subject-sorted spine is 7,553 — **3.4%**. The rest is sorted by when it was written.

*One-in-one-out: nothing is retired for this, and the reason is written down as the
rule requires — it adds no check, hook, guard, tracker or document class, so it does
not increase the number of distinct mechanisms an agent must maintain. It retires a
habit, which is the point.*

### Session notes are retired

**Do not write a session note, in any repo.** The practice was retired on
2026-08-23 (`RETIRE-SESSION-NOTES-2026-08-23`, owner-ruled) and every
`AGENT/Session Notes/` tree is frozen evidence — read it, never add to it. Nine
mechanisms went with it, including the note-index gate, the filename check, the
scaffolder and the `notes` subcommand of `tools/history_audit.py`.

Record a session's outcome where it is read instead: **commits** in
`AGENT/Ledger/CLAIMS.tsv`; **what was done and why** in the tracker row's
`reference` (`agent-update-task.sh --append-reference`); **what to do next** in
`<container>/AGENT/WAITING_WORK.md` and the row's `trigger` / `order` /
`dependencies`; **a
ruling** in a register, with a citable ID.

The practice had already lapsed when it was retired — four consecutive sessions
wrote no note and lost nothing — and a tracker row's `reference` was measured to
be a strict superset of the note covering the same work.

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
- **A foundation closes on an adopter, not on its own tests.** A row that ships an
  engine primitive, registry or service closes as `completed` only when a non-test
  caller exists, *or* when it names a dated successor row — one that is already in
  the tracker — which will supply one. Failing either, it closes as `in_review`.
  Three foundations shipped with an API, a green suite and no adopter before this
  was written: `PrepActivityRegistry`, whose only non-test reference in the whole
  repo was a comment; `RequirementFormulaRegistry`; and `RequirementSystem`. Each
  read as delivered work while inviting the next slice to build a second path for
  the same job, which is the cost the tracker exists to prevent.
- **A builder feature closes on an authored pack, not on a caller inside the
  engine.** The rule above is the repo-scope form; this is its project-scope form.
  A row that ships authoring capability — a registry field, an editor surface, a
  schema, a pack-facing service — closes as `completed` only when a campaign pack
  exercises it through `select_campaign()` and is played. A test fixture does not
  count, and neither does an in-engine caller: a fixture proves the code runs, it
  does not prove the capability is reachable by someone who is not editing the
  engine, which is the entire product. Measured over the 30 days to 2026-08-23:
  2,477 documentation file-touches, 640 GDScript, and **11 to `data/`** — the
  builder had never been used to build anything, while Bands 0-2 read 23/23 built
  and Bands 3-8 read 5/70. The bottleneck is adoption, not deciding or building.

<!-- END SHARED: policy -->

---

## Project_Prometheus-specific rules

### Code style & architecture

Keep code simple and readable, following GDScript style guidlines

Architecture principle — author-facing extension points are OPEN REGISTRIES, not closed type-switches. When a vocabulary will grow with content (objective conditions, AI profiles, prep/on-map activities & panels, effects, stat names, resource types, …), make it a **data-driven registry / predicate the engine reads**, NOT a hardcoded `enum` + `match` that needs an engine edit per addition. The closed enum is the smell: if adding content requires editing a GDScript switch, reconsider. This recurred repeatedly in design (objective conditions → `[TCV-4]`, AI profiles `[AIP]`, panel/activity types `[SAC]`, the mini-game module seam, stat model `[STM]`). Aligns with the ratified author-extensibility model `[EXT]` (data composition, engine provides primitives, no-code). Rationale + the full pattern: `AGENT/Docs/registers/authoring_extensibility_open_questions_2026-06-26.md`.

Architecture principle — ONE CAMPAIGN PACK IS ACTIVE AT A TIME, and a pack is COMPLETELY SELF-CONTAINED. `[ICO-1..6]` (RESOLVED 2026-06-23) settled this: `select_campaign()` loads **one** self-contained content set, not a `defaults ∪ overlay` merge. There are no content dependencies, imports, qualified external ids, load-order resolution, or references into another pack, and the campaign library deliberately shows **no** dependency controls so it does not imply a false load-order model (`CL-LIFE-08`). Code matches: `CampaignPackInstaller` rejects only a re-install of the same id *and* version and never cross-checks ids against other installed packs; the runtime carries a single `active_package_identity`.

**The consequence agents keep getting wrong:** two different packs shipping the same content id is **fine** — they are never loaded together, so it is not a collision and not an error. Id uniqueness is a rule *within* a pack's own export set. Do not design cross-pack id checks, namespacing-to-avoid-collision schemes, or "which pack wins" precedence. If a contract sentence reads as though several packs are considered together (e.g. `class_schema_trial_v1`'s "across all packs considered together during installation or load"), it means the one loaded set, not the installed library.

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

All Documentation should go and be read from the appropriate subfolder in the AGENT folder

Documentation layout & index (DSR, 2026-06-23): AGENT/Docs/ is sorted by TYPE — `guides/ governance/ decisions/ registers/ design/ plans/ playtests/` for live docs, and `archive/{consolidation,plans,playtests,handoffs,reference,evidence}/` for historical/superseded ones (never deleted; each archived .md carries a `> **Historical**`/`> **Superseded** by [..](path)` marker in its first 10 lines). Retrieval: `AGENT/Docs/INDEX.md` = what's active; `AGENT/Docs/REGISTERS.md` = the `[XXX-n]` open-question registers catalog (OPEN/RESOLVED + resolved-where); `AGENT/Docs/decisions/decision_index.md` = governance IDs (DOC/RULE/SET/OPEN/RNG/AWR). INDEX.md and REGISTERS.md are GENERATED — after adding/moving/retitling a doc or changing its header, run `python3 AGENT/Docs/gen_docs_index.py` and commit the result in the SAME change (enforced by check_docs.py check 18; design rationale in `AGENT/Docs/governance/documentation_system_design_2026-06-23.md`).

AGENT/Docs is documentation, NEVER a `res://` resource tree (2026-08-13). Godot imports anything under the project root, so a wireframe or evidence image acquires a `.import` sidecar that nobody reads and that dirties the tree after any editor/import pass. Image-only doc directories therefore carry a `.gdignore` (Godot skips them entirely — no import, no sidecar, no `.godot/imported/` entry, and they stay out of the exported build), and `AGENT/Docs/**/*.import` in `.gitignore` is the backstop for a doc image dropped somewhere that has no `.gdignore`. **If the game or a test needs an asset that lives under AGENT/Docs, move or copy it OUT of AGENT/Docs** — a `.gdignore`d folder is absent from the resource filesystem and from every export, so depending on one fails at runtime, not at author time. Reading a document's *text* to validate the document is explicitly fine and is not what this bans: `test_release_metadata.gd` reads the playtest checklist and setup guide to assert they name the current version, which is a documentation check. Enforced from the consuming side by `check_docs.py` check 44, which rejects asset-extension `res://AGENT/...` references in `scripts/`, `scenes/` and `resources/`.

Documentation lifecycle definition-of-done (DoD#1, formerly PL#8): when a change alters behavior, update the affected GDD_01–08 section(s) AND flip the matching status in GDD_10_Roadmap.md in the SAME commit. Use the governance status vocabulary (AGENT/Docs/governance/documentation_governance_2026-06-13.md) — never the words "current", "complete", or "canonical" in a status-bearing section. (Pairs with the DOC-011 CI documentation checks.)

Enforcement definition-of-done (DoD#2, formerly PL#9): when you ratify a mechanical, checkable rule (a vocabulary ban, a required header, a path convention), land its automated check in the SAME change — extend AGENT/Docs/check_docs.py. A written rule with no check rots; check_docs.py runs in the pre-commit hook and in CI (.github/workflows), so it is the durable enforcement, not prose.

Code review instructions are in the AGENT/Docs folder

### Session notes are RETIRED

**Do not write a session note.** The practice was retired on 2026-08-23
(`RETIRE-SESSION-NOTES-2026-08-23`, owner-ruled). `AGENT/Session Notes/` is a frozen
evidence corpus — read it, never add to it. See its `README.md` for why, and for the
mechanisms that went with it.

Record a session's outcome where it is actually read:

| What you would have written | Where it goes |
|---|---|
| Commits made | `AGENT/Ledger/CLAIMS.tsv` (below) |
| What was done, and why | the tracker row's `reference` — `scripts/agent-update-task.sh --append-reference` |
| What to do next | `<container>/AGENT/WAITING_WORK.md`, plus the row's `trigger` / `order` / `dependencies` |
| A decision or ruling | a register under `AGENT/Docs/registers/`, with a citable ruling ID |

### Commit ownership

**Ownership lives in `AGENT/Ledger/CLAIMS.tsv`.** It is per commit and machine-read.
It sat under `AGENT/Session Notes/` until the notes were retired and moved out then,
because it is not a note and never was — conflating the two made every row in the
project contend for one file.

- Claim as you go with `python3 scripts/ci/check_session_commit_claims.py --fix`. It
  appends every unclaimed commit to the ledger, SHA-sorted. Claiming by hand at the
  end turns each push into a reject-edit-amend loop.
- The ledger is read from your **working tree**, unioned with the copy on
  `agent/integration` when that remote-tracking ref is present. It is a real file that
  travels with the branch, so **no fetch is required** and there is no second push.
- The pre-move path `AGENT/Session Notes/CLAIMS.tsv` is still read, so a branch cut
  before 2026-08-23 keeps working. That fallback is deleted once no live branch
  predates the move.

### Fixing a rejected check

| Rejection | Command |
|---|---|
| GDScript formatting | `bash scripts/ci/check_gdscript_style.sh --fix` (lint findings still need an edit) |
| Unclaimed commits | `python3 scripts/ci/check_session_commit_claims.py --fix` |
| Suites failed, suspect contention | `bash run_tests.sh --rerun-failed` — re-runs only the recorded failures, serially |

A red parallel run writes the failing suite names to `.test-failures`; a green run
clears it. Re-running in isolation is how contention is told apart from a real defect,
and it now leaves a record instead of retyped suite names.

Start a session by reading the container repo's standing handoff at
`<container>/AGENT/WAITING_WORK.md` and the
generated queue in `coordination/ACTIVE_WORK.md`, then the `reference` of the row
you are picking up. Do **not** start by reading session notes — they are frozen
history, useful only when a live document cites one by name.

---

If I say "Status Report" respond with "All Systems Online"
