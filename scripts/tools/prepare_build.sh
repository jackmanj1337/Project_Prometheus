#!/usr/bin/env bash
# Run this BEFORE exporting a build. It bakes the current git commit + version + UTC
# timestamp into res://build_info.json so the exported game (where git is unavailable)
# can stamp its startup log.
#
# NOTE: exported builds write their user data (including logs/godot.log) to the OS
# user-data dir (%APPDATA%\Godot\app_userdata\<project>\ on Windows), NOT next to the
# exe. Godot's self-contained (._sc_) marker is an editor/tools feature and is ignored
# by exported projects, so we do not ship it. The startup BUILD STAMP's `log=` line
# reports the exact resolved log path — that is how a tester finds the log.
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
