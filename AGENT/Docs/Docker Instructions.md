# Godot + Claude Code + Codex — Terminal Dev Container

A Docker environment for developing this Godot project with both Claude Code and Codex from one terminal container.

## What's inside

- **Ubuntu 22.04** base
- **Godot 4.6** (headless; no display needed)
- **Node.js 20 LTS**
- **Claude Code CLI** (`@anthropic-ai/claude-code`)
- **Codex CLI** (`@openai/codex`)
- Non-root `developer` user for safety
- Persistent Claude/Codex auth via named Docker volume

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- An **Anthropic API key** from [console.anthropic.com](https://console.anthropic.com), or Claude login auth
- An **OpenAI API key**, or Codex login auth

---

## Quick Start

### 1. Add your API key

Create a `.env` file next to `docker-compose.yml`:

```bash
ANTHROPIC_API_KEY=sk-ant-your-key-here
OPENAI_API_KEY=sk-your-openai-key-here
```

Login-based auth also works and is saved in the `developer-home` Docker volume.

### 2. Build the image

```bash
docker compose build
```

This takes ~2–3 minutes the first time (downloads Godot binary).

### 3. Start the container

```bash
docker compose run --rm agents-godot
```

You'll land in an interactive bash shell inside `/workspace`.

### 4. Authenticate the CLIs

On first run, authenticate with your Anthropic account:

```bash
claude login
codex login
```

Follow the OAuth flows. Sessions are saved in the `developer-home` Docker volume, so you only do this once.

### 5. Start coding!

```bash
# Open Claude Code in your project
claude

# Open Codex in your project
codex

# Or start with a prompt
claude "Create a simple Godot 4 platformer player scene in GDScript"
```

---

## Working with Godot from the terminal

```bash
# Run a Godot project (headless)
godot --path /workspace/my-game

# Run a specific scene
godot --path /workspace/my-game res://scenes/main.tscn

# Check syntax / import resources
godot --path /workspace/my-game --import

# Export a game (requires export templates, see Dockerfile comments)
godot --path /workspace/my-game --export-release "Linux/X11" /output/game.x86_64

# Run GDScript unit tests (if using GUT or similar)
godot --path /workspace/my-game --script res://tests/run_tests.gd
```

> **Note:** `godot` in this container is aliased to `godot --headless` automatically.
> Godot won't render visuals — it's purely for scripting, importing, and exporting.

---

## Useful Claude Code commands

```bash
# Start interactive session
claude

# Ask Claude to write/edit code
claude "Add double-jump to the Player.gd script"

# Review files
claude "Review my project structure and suggest improvements"

# One-shot non-interactive
claude -p "Explain what res://scenes/enemy.tscn does"
```

## Useful Codex commands

```bash
# Start interactive session
codex

# Or use the container alias
ai-codex
```

---

## Project structure tip

Put your Godot project directly in the folder that contains `docker-compose.yml`.
It gets mounted at `/workspace` inside the container.

```
my-game/               ← clone/create your Godot project here
├── Dockerfile
├── docker-compose.yml
├── .env               ← your API key (git-ignored!)
├── project.godot
├── scenes/
├── scripts/
└── ...
```

Add `.env` to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

---

## Changing the Godot version

Edit `docker-compose.yml`:

```yaml
args:
  GODOT_VERSION: "4.2"   # or "3.5.3"
```

Then rebuild:

```bash
docker compose build --no-cache
```

---

## Stopping & cleaning up

```bash
# Stop the container
docker compose down

# Remove the image too
docker compose down --rmi local

# Remove everything including the auth volume (forces re-login)
docker compose down -v --rmi local
```
