#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coordination.sh"
[[ $# -eq 4 ]] || { echo "usage: $0 VERSION BRANCH SOURCE_BRANCH SOURCE_SHA" >&2; exit 2; }
coord_update "coordination: start release $1" start-release "$@"
