#!/usr/bin/env bash
# Run this BEFORE exporting a build. It:
#   1. Bakes the current git commit + version + UTC timestamp into res://build_info.json
#      so the exported game (where git is unavailable) can stamp its startup log.
#   2. Drops the Godot self-contained marker (._sc_) into builds/ so the exported exe
#      writes its user data — including logs/godot.log — NEXT TO THE EXE instead of the
#      OS %APPDATA% dir. The marker MUST be shipped in the release zip alongside the exe.
#
# build_info.json is gitignored (it is a per-build artifact); the editor falls back to
# the live git commit when the file is absent, so dev runs still stamp a real commit.
set -euo pipefail
cd "$(dirname "$0")/../.."   # repo root (res://) — this script lives in scripts/tools/

# Version comes from the single source of truth: the export preset's product_version.
VERSION="$(grep -E '^application/product_version=' export_presets.cfg \
	| head -1 | sed -E 's/.*="(.*)"/\1/')"
COMMIT="$(git rev-parse --short HEAD)"
BUILT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > build_info.json <<EOF
{
  "version": "${VERSION}",
  "commit": "${COMMIT}",
  "built_at": "${BUILT_AT}"
}
EOF
echo "wrote build_info.json  (version=${VERSION} commit=${COMMIT} built_at=${BUILT_AT})"

# Self-contained marker next to where the exe is exported (export_path is ./builds/...).
mkdir -p builds
: > builds/._sc_
echo "wrote builds/._sc_  (self-contained marker — include it in the release zip)"
