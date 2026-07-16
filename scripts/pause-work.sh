#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coordination.sh"
[[ $# -eq 2 ]] || { echo "usage: $0 WORK_ID REASON" >&2; exit 2; }
coord_update "coordination: pause $1" pause "$@"
