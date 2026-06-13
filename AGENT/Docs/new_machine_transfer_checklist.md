# New Machine / Environment Transfer Checklist

**Status:** Active — operational runbook for moving this repo to a new machine.
**Last verified:** 2026-06-13

Run order on the new machine: **clone → `bash scripts/check_env.sh` (see gaps) →
fix the gaps below → `bash scripts/setup_dev.sh` → `bash run_tests.sh`.**

`scripts/check_env.sh` is a read-only doctor that reports `[OK]/[WARN]/[FAIL]` for each
prerequisite below. `scripts/setup_dev.sh` activates the git hooks and builds the Godot
cache.

---

## A. GitHub / git state

- All branches with work are pushed: `awakening-compatability-refactor`,
  `class-skill-rebuild`, `code-review-fixes-2026-05-21`. No stashes.
- Local `main` may sit a few commits ahead of `origin/main`, but those commits are also
  reachable from pushed feature branches, so **no commit data is at risk**. Advance
  `origin/main` only via the normal PR merge unless you deliberately want the ref moved.
- After cloning, check out the working branch: `git checkout awakening-compatability-refactor`.
- Verify nothing local is unpushed: `git status -sb` and `git log --oneline @{u}..HEAD`.

## B. Will NOT travel via git — recreate or copy by hand

| Item | Why / action |
|---|---|
| **SSH host alias** | `origin` is `git@github.com-project-prometheus:…`. Add a matching `Host github.com-project-prometheus` block in `~/.ssh/config` with the right `IdentityFile`, **or** rewrite: `git remote set-url origin git@github.com:jackmanj1337/Project_Prometheus.git`. Without this, push/pull fails. |
| **`.env`** | gitignored. `cp .env.example .env` and fill keys, or use login-based auth (`claude login` / `codex login`). |
| **Persistent agent memory** | Lives OUTSIDE the repo at `~/.claude/projects/-workspace/memory/` (`MEMORY.md` + `feedback_*.md`). Copy this directory to keep agent memory continuity; otherwise it starts empty. |
| **`.claude/` (repo-local)** | gitignored project Claude settings / permission allowlist. Copy to keep your allowlist, else re-grant on first use. |
| **Git hooks** | Versioned at `scripts/hooks/`; `scripts/setup_dev.sh` activates them via `core.hooksPath`. (They are NOT in `.git/hooks` of a fresh clone.) |
| **`.godot/` cache, `builds/`, `__pycache__`** | Regenerated. `setup_dev.sh` rebuilds the Godot import/class cache. Note: `.godot/global_script_class_cache.cfg` IS tracked so headless tests resolve `class_name` scripts on a fresh clone. |
| **Export signing creds** | `export_credentials.cfg` is gitignored — recreate only if you sign/export builds. |

## C. Toolchain to install

- **Godot 4.6 stable** on `PATH` as `godot` (matches `project.godot` + CI).
- **Godot 4.6 export templates** (only for `builds/` exports).
- **Python 3** — `check_docs.py`, the RNG guard, and the godot-analyzer MCP server.
- **MCP path:** `.mcp.json` references `tools/godot-analyzer-mcp/server.py`. `server.py`
  now defaults its project root to its own location, so it works even if the repo is not
  at `/workspace`. If `.mcp.json` still lists absolute `/workspace` paths and the new repo
  path differs, update those two paths (or drop the root arg).
- **Docker** (optional) — `Dockerfile` / `docker-compose.yml` are tracked; need `.env`.

## D. Verify after setup

```
bash scripts/check_env.sh            # doctor — should be all [OK]
python3 AGENT/Docs/check_docs.py     # docs checks → PASS (8 checks)
bash scripts/ci/check_rng_usage.sh   # RNG guard → PASS
bash run_tests.sh                    # full GDScript suite → 38 suites green
git push                             # confirms the SSH host alias resolves
```

## E. Notes (not blockers)

- `project.godot` renderer is **Forward Plus**; GDD_00 Platform Targets (OPEN-8) target
  **Compatibility (OpenGL)** for web export — a tracked pending change (Target design),
  not done. Whatever renderer is active drives the new machine's GPU/driver needs.
- `.gitattributes` forces LF on scripts/code so the hooks and tooling run on a
  Windows-native checkout too.
