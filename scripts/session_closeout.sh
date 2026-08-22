#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
python3 scripts/ci/audit_cadence.py
python3 scripts/ci/check_note_index.py
python3 scripts/ci/check_session_commit_claims.py
python3 scripts/ci/check_evidence_matrices.py
