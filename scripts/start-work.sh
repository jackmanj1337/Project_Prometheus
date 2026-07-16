#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coordination.sh"
[[ $# -ge 7 ]] || { echo "usage: $0 WORK_ID TITLE BRANCH OWNER TARGET BASE_BRANCH BASE_SHA [--scope local|remote]" >&2; exit 2; }
coord_update "coordination: start $1" start "$@"
