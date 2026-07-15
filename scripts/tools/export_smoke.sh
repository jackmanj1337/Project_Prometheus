#!/usr/bin/env bash
# Usage: export_smoke.sh ARTIFACT -- COMMAND [ARG ...]
set -u
artifact="${1:-}"
[[ "${2:-}" == "--" && -n "$artifact" ]] || { echo "usage: $0 ARTIFACT -- COMMAND [ARG ...]" >&2; exit 2; }
shift 2
log="$(mktemp)"
"$@" >"$log" 2>&1
code=$?
size=0
hash="missing"
if [[ -f "$artifact" ]]; then
	size="$(wc -c < "$artifact")"
	hash="$(sha256sum "$artifact" | awk '{print $1}')"
fi
printf 'export-smoke: exit=%d artifact=%s bytes=%s sha256=%s\n' "$code" "$artifact" "$size" "$hash"
if [[ "$code" -ne 0 ]]; then cat "$log" >&2; fi
rm -f "$log"
exit "$code"
