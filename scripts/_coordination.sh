#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="${COORDINATION_BRANCH:-coordination}"
REMOTE="${COORDINATION_REMOTE:-origin}"

require_coordination_branch() {
  local current
  current="$(git -C "$ROOT" branch --show-current)"
  if [[ "$current" != "$BRANCH" ]]; then
    echo "expected coordination branch '$BRANCH', found '$current'" >&2
    exit 1
  fi
}

sync_coordination() {
  require_coordination_branch
  if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
    echo "coordination worktree must be clean before mutation" >&2
    exit 1
  fi
  git -C "$ROOT" fetch "$REMOTE" "$BRANCH" || true
  if git -C "$ROOT" show-ref --verify --quiet "refs/remotes/$REMOTE/$BRANCH"; then
    git -C "$ROOT" merge --ff-only "$REMOTE/$BRANCH"
  fi
}

commit_and_push() {
  local message="$1"
  python3 "$ROOT/scripts/work_registry.py" check
  git -C "$ROOT" add branches.yaml ACTIVE_WORK.md RELEASE_TRAINS.md
  if git -C "$ROOT" diff --cached --quiet; then
    echo "registry already has requested state"
    return 0
  fi
  git -C "$ROOT" commit -m "$message"
  if git -C "$ROOT" push "$REMOTE" "$BRANCH"; then
    return 0
  fi
  echo "push rejected; fetching, rebasing, and revalidating once" >&2
  git -C "$ROOT" fetch "$REMOTE" "$BRANCH"
  git -C "$ROOT" rebase "$REMOTE/$BRANCH"
  python3 "$ROOT/scripts/work_registry.py" check
  git -C "$ROOT" push "$REMOTE" "$BRANCH"
}

coord_update() {
  local message="$1"
  shift
  sync_coordination
  python3 "$ROOT/scripts/work_registry.py" "$@"
  commit_and_push "$message"
}
