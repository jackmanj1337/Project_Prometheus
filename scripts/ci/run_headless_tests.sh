#!/usr/bin/env bash
set -euo pipefail

# CI/bootstrap wrapper for a fresh clone. Godot's global class cache is generated
# during the first project import scan; the headless test scripts depend on it.
cd "$(dirname "$0")/../.."

echo "Preparing Godot project import cache..."
godot --headless --path . --import --quit-after 1000

if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
  echo "FAIL: Godot import did not generate .godot/global_script_class_cache.cfg"
  exit 1
fi

echo "Running test suite..."
bash run_tests.sh
