#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_coordination.sh"
[[ $# -eq 2 ]] || { echo "usage: $0 WORK_ID MERGE_OR_PR_REFERENCE" >&2; exit 2; }
coord_update "coordination: finish $1" finish "$@"
