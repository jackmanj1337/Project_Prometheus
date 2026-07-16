#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

for tool in gdformat gdlint; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "check_gdscript_style: FAIL — $tool is missing; install requirements-dev.txt" >&2
		exit 1
	fi
done

# gdtoolkit 4.5.0 hardcodes ~/.cache. Some containers expose a read-only HOME;
# retain the original user site on PYTHONPATH while moving HOME only for this run.
cleanup_home=""
if ! mkdir -p "${HOME}/.cache/gdtoolkit" 2>/dev/null; then
	user_site="$(python3 -m site --user-site)"
	cleanup_home="$(mktemp -d)"
	export PYTHONPATH="${user_site}${PYTHONPATH:+:${PYTHONPATH}}"
	export HOME="$cleanup_home"
	mkdir -p "$HOME/.cache/gdtoolkit"
fi
trap '[[ -z "$cleanup_home" ]] || rm -rf "$cleanup_home"' EXIT

mapfile -d '' files < <(git ls-files -z '*.gd')
if [[ "${#files[@]}" -eq 0 ]]; then
	echo "check_gdscript_style: PASS — no tracked GDScript"
	exit 0
fi

gdformat --check "${files[@]}"
gdlint "${files[@]}"
echo "check_gdscript_style: PASS — ${#files[@]} tracked GDScript file(s)"
