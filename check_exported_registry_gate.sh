#!/usr/bin/env bash
# Export a PCK and prove that its engine registry vocabulary matches the source
# checkout while excluded built-in campaign catalogues remain absent.
set -euo pipefail

cd "$(dirname "$0")"

if [[ $# -ne 1 ]]; then
	echo "usage: $0 <exact-campaign-pack.zip>" >&2
	exit 2
fi

ARCHIVE="$(realpath "$1")"
[[ -f "$ARCHIVE" ]] || { echo "campaign pack not found: $ARCHIVE" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PCK="$WORK/exported-registry-gate.pck"
SOURCE_LOG="$WORK/source.log"
EXPORT_LOG="$WORK/export.log"

godot --headless --path . --script res://scripts/shared/ExportedRegistryGate.gd \
	-- --source-mode "$ARCHIVE" >"$SOURCE_LOG" 2>&1
godot --headless --path . --export-pack "Project Prometheus v0.7.0" "$PCK"
if ! (cd "$WORK" && godot --headless --main-pack "$PCK" \
	--script res://scripts/shared/ExportedRegistryGate.gd -- "$ARCHIVE") >"$EXPORT_LOG" 2>&1; then
	cat "$EXPORT_LOG" >&2
	exit 1
fi

source_report="$(sed -n 's/^EXPORTED_REGISTRY_GATE_JSON://p' "$SOURCE_LOG")"
export_report="$(sed -n 's/^EXPORTED_REGISTRY_GATE_JSON://p' "$EXPORT_LOG")"
if [[ -z "$source_report" || -z "$export_report" ]]; then
	echo "registry report missing" >&2
	cat "$SOURCE_LOG" >&2
	cat "$EXPORT_LOG" >&2
	exit 1
fi
if [[ "$source_report" != "$export_report" ]]; then
	echo "source/export registry ids differ" >&2
	echo "source: $source_report" >&2
	echo "export: $export_report" >&2
	exit 1
fi

cat "$EXPORT_LOG"
echo "source/export registry ids match"
