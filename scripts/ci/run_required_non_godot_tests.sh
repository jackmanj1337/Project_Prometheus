#!/usr/bin/env bash
# Discover and run the repository's required Python infrastructure and browser tests.
# Keep discovery here so adding a test file cannot leave it outside the normal gate.
set -euo pipefail

cd "$(dirname "$0")/../.."

PYTHON_TESTS=()
while IFS= read -r path; do
  PYTHON_TESTS+=("$path")
done < <(find scripts/ci -maxdepth 1 -type f -name 'test_*.py' | sort)

BROWSER_TESTS=()
while IFS= read -r path; do
  BROWSER_TESTS+=("$path")
done < <(find tools/web -maxdepth 1 -type f -name '*.test.mjs' | sort)

if [[ ${#PYTHON_TESTS[@]} -eq 0 ]]; then
  echo "FAIL: no Python infrastructure tests found under scripts/ci/" >&2
  exit 1
fi
if [[ ${#BROWSER_TESTS[@]} -eq 0 ]]; then
  echo "FAIL: no browser-shell tests found under tools/web/" >&2
  exit 1
fi

echo "running required non-Godot tests (${#PYTHON_TESTS[@]} Python files, ${#BROWSER_TESTS[@]} browser files)..."
for path in "${PYTHON_TESTS[@]}"; do
  # The exact-staged-tree hook exports Git repository variables. Fixture tests
  # create throwaway repositories, so inheriting those variables would redirect
  # their git commands into the real checkout.
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_PREFIX python3 "$path"
done
node --test "${BROWSER_TESTS[@]}"

echo "PASS: required non-Godot tests green"
