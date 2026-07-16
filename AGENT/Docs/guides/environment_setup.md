# Environment Setup — Transfer to a New Machine

**Last verified:** 2026-07-04

Everything needed to bring this project up on a fresh machine and pick up
work where this session left off.

## TL;DR

```bash
# 1. Clone (uses the configured SSH remote — see "SSH remote" below)
git clone git@github.com-project-prometheus:jackmanj1337/Project_Prometheus.git
cd Project_Prometheus

# 2. Add API keys
cp .env.example .env  # or create from scratch — see "API keys" below
$EDITOR .env

# 3. Build the dev container (downloads Godot + export templates, ~1.5 GB)
docker compose build

# 4. Start the container
docker compose run --rm agents-godot

# 5. First-run auth
claude login    # or set ANTHROPIC_API_KEY in .env
codex login     # or set OPENAI_API_KEY in .env

# 6. Verify
godot --version          # → 4.6.stable.official.89cea1439
bash run_tests.sh        # → PASS: all suites green
```

## Components

### Docker host

- Docker 24+ with Compose v2 (`docker compose`, not `docker-compose`).
- ~5 GB free disk for the image + a developer-home volume.
- Linux, macOS, or Windows with WSL2.

### What `docker compose build` produces

Per `Dockerfile`:

- Ubuntu 22.04 base.
- Godot 4.6 stable headless binary at `/usr/local/bin/godot`.
- **Godot export templates** for 4.6 stable, baked into
  `/opt/godot-export-templates/4.6.stable/`. First container start
  symlinks them into `~/.local/share/godot/export_templates` for the
  `developer` user, so `godot --export-debug` works immediately.
- Node 20 LTS, Claude Code CLI, Codex CLI.
- Non-root `developer` user. Project is mounted read-write at
  `/workspace`.

### docker-compose volumes

- `.:/workspace` — your local checkout, live.
- `developer-home:/home/developer` — persists `~/.claude`,
  `~/.codex`, and CLI auth across container restarts. **First
  container start populates this volume from the image.** If you
  delete the volume (`docker compose down -v`), you'll re-login on
  next start.

### API keys

Login auth via `claude login` / `codex login` is the recommended path
and persists in `developer-home`. If you prefer key-based auth, drop a
`.env` next to `docker-compose.yml`:

```env
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
```

`.env` is git-ignored.

### SSH remote

The remote is configured under a custom host alias so the project's
deploy key does not collide with personal GitHub auth:

```
$ git remote -v
origin git@github.com-project-prometheus:jackmanj1337/Project_Prometheus.git
```

On a new machine, add to `~/.ssh/config`:

```
Host github.com-project-prometheus
    HostName github.com
    User git
    IdentityFile ~/.ssh/project_prometheus_ed25519
    IdentitiesOnly yes
```

…and copy the matching SSH private key from your password manager to
`~/.ssh/project_prometheus_ed25519` (`chmod 600`). Then `git fetch`
should succeed.

If you don't want a custom host alias, change the remote to plain
`git@github.com:jackmanj1337/Project_Prometheus.git` and use a default
identity:

```bash
git remote set-url origin git@github.com:jackmanj1337/Project_Prometheus.git
```

## Godot project layout (what gets shipped via git)

- `project.godot` — engine config (`config_version=5`, Godot 4.6 features).
- `data/` — every `.tres` content resource (classes, weapons, items,
  skills, maps, rosters) plus `resource_manifest.json` indexes used by
  export-safe runtime enumeration.
- `scripts/` — gameplay code. Autoloads live under `scripts/autoloads/`.
  Tests under `scripts/tests/`.
- `scenes/` — `.tscn` scene files.
- `.godot/global_script_class_cache.cfg` — **tracked** (see comment in
  `.gitignore`). Headless `--script` runs don't regenerate the cache, so
  any new `class_name` needs a manual entry committed alongside.
- `export_presets.cfg` — Windows preset used for playtest builds.
  Currently at `v0.4.1`; it excludes `AGENT/**`, `scripts/tests/**`, and
  both `scripts/tools/**` and root `tools/**` so internal documentation,
  screenshots, test harnesses, and authoring tools are not packaged into tester
  builds.

## What's NOT tracked and what to do about it

- `.godot/` editor cache (except the class cache file above) — Godot
  regenerates it on first headless run.
- `.import/` — Godot regenerates on first asset load.
- `export.cfg`, `export_credentials.cfg` — local-only.
- `builds/` — `.exe` artifacts. Re-export per
  `playtest_checklist_v0.3.1.md` to reproduce.
- `.env` — API keys.

If you cloned and these directories are missing, that's correct.
Running `godot --headless --path .` once populates `.godot/` and
`.import/`. The first `bash run_tests.sh` warm-up takes longer than
subsequent runs.

## Producing a Windows playtest build

From inside the container, after the image is built (or on the host
with Godot 4.6 + export templates installed):

```bash
# 0. Stamp the build FIRST — bakes commit+version+timestamp into build_info.json
#    so the exe can stamp its startup log.
bash scripts/tools/prepare_build.sh

# Debug build (slightly larger, useful for testers)
godot --headless --path . \
    --export-debug "Project Prometheus v0.4.1" \
    builds/Project_Prometheus_v0.4.1_debug.exe

# Release build
godot --headless --path . \
    --export-release "Project Prometheus v0.4.1" \
    builds/Project_Prometheus_v0.4.1.exe
```

The preset name must match `export_presets.cfg[preset.0].name` exactly.
Bumping the version means updating `name`, `export_path`, and
`application/product_version` in that file plus the `VersionLabel.text`
in `scenes/ui/MainMenu.tscn`.

### Where the log lives (`%APPDATA%`) and the BUILD STAMP

Exported builds write `user://` — including `logs/godot.log` and `settings.cfg` — to the
OS user-data dir, **not** next to the exe. On Windows that is
`%APPDATA%\Godot\app_userdata\Fire Emblem RPG\logs\godot.log`. Godot's self-contained
(`._sc_`/`_sc_`) marker is an editor/tools feature and is **ignored by exported
projects** — the v0.2.6 return proved this (the marker shipped, yet the log resolved to
`%APPDATA%`). So we no longer ship it. To find the log:

- **Use the BUILD STAMP.** The game prints a `=== BUILD STAMP ===` block at the very top
  of `godot.log` on every launch (`scripts/shared/BuildInfo.gd`, called from `Boot.gd`):
  version, git commit, built-at, a fresh per-launch `started_at`, and the resolved
  `user_data_dir=` / `log=` paths. **The `log=` line is authoritative** — it is the exact
  full path to the file, so a tester copies it from there.
- Testers who can't run the game yet can paste `%APPDATA%` into the Windows Explorer
  address bar and navigate to `Godot\app_userdata\Fire Emblem RPG\logs\`.
- `build_info.json` is gitignored (a per-build artifact); dev/editor runs fall back to
  the live git commit (tagged `-dev`) when it is absent.

## Running tests

```bash
# Full suite (~2-3 minutes; pre-commit also runs this)
bash run_tests.sh

# One suite
godot --headless --path . --script res://scripts/tests/test_unit_stats.gd
```

The pre-commit hook gates every commit on a green run. Failures
print as `FAIL <name>: ...` and exit non-zero.

## When you sit down at the new machine

1. Read the newest file in `AGENT/Session Notes/`.
2. Read `AGENT/Docs/archive/playtests/playtest_checklist_v0.2.1.md` to know what is
   shipped to testers and what remains open.
3. `bash run_tests.sh` to confirm the environment is clean.
4. Continue from the plan recorded in the newest session note.

## Things that might trip you up

- **Export-templates download is large.** First `docker compose build`
  pulls ~1.1 GB of templates. Subsequent rebuilds reuse the layer.
- **The class cache is hand-maintained.** When you add a new
  `class_name SomeName` to a `scripts/.../X.gd`, headless test runs
  can't resolve it until `.godot/global_script_class_cache.cfg` gains
  the entry. Open the project in the Godot editor once OR copy the
  pattern from an existing entry by hand.
- **Two of the autoloads (`PairUpRegistry`, `PairUpBonusResolver`,
  `CombatResolver`) are looked up by absolute path** (`/root/...`).
  Headless tests use a relay-node pattern to access them; see
  `test_pair_up_combat_context.gd` for the template.
- **Linux export from the container** uses the WINE-free path —
  there's no Windows code-signing. The resulting `.exe` is just a PE
  with the Godot runtime; testers run it directly.
