#!/usr/bin/env bash
# One-time dev setup for a fresh clone / new machine.
# Run from anywhere in the repo:  bash scripts/setup_dev.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

echo "[1/2] Activating versioned git hooks (scripts/hooks)..."
git config core.hooksPath scripts/hooks
echo "      pre-commit now runs check_docs.py + RNG guard + (path-filtered) test suite."

echo "[2/2] Building Godot import + global class cache (needed for headless tests)..."
if command -v godot >/dev/null 2>&1; then
	godot --headless --path . --import --quit-after 1000 || true
	echo "      done."
else
	echo "      WARN: 'godot' not on PATH. Install Godot 4.6 stable, then re-run this script."
fi

echo
echo "Setup complete. Verify the toolchain with:"
echo "  python3 AGENT/Docs/check_docs.py   # docs checks"
echo "  bash scripts/ci/check_rng_usage.sh # RNG guard"
echo "  bash run_tests.sh                  # full GDScript suite"
