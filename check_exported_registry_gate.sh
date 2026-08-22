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

# The release name changes with every candidate. Resolve the one Windows preset
# from its platform instead of baking a versioned display name into this gate.
mapfile -t WINDOWS_PRESETS < <(
	awk '
		function emit() { if (active && platform == "Windows Desktop") print name; active = 0 }
		/^\[preset\.[0-9]+\]$/ { emit(); name = ""; platform = ""; active = 1; next }
		/^\[/ { emit(); active = 0; next }
		active && /^name="/ { value = $0; sub(/^name="/, "", value); sub(/"$/, "", value); name = value }
		active && /^platform="/ { value = $0; sub(/^platform="/, "", value); sub(/"$/, "", value); platform = value }
		END { emit() }
	' export_presets.cfg
)
if [[ ${#WINDOWS_PRESETS[@]} -ne 1 || -z "${WINDOWS_PRESETS[0]}" ]]; then
	echo "expected exactly one Windows Desktop export preset, found ${#WINDOWS_PRESETS[@]}" >&2
	exit 1
fi
WINDOWS_PRESET="${WINDOWS_PRESETS[0]}"

godot --headless --path . --script res://scripts/shared/ExportedRegistryGate.gd \
	-- --source-mode "$ARCHIVE" >"$SOURCE_LOG" 2>&1
godot --headless --path . --export-pack "$WINDOWS_PRESET" "$PCK"
[[ -s "$PCK" ]] || { echo "Godot reported success but produced no export PCK" >&2; exit 1; }
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
