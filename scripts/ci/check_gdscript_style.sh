#!/usr/bin/env bash
# Verify (default) or apply (--fix) GDScript formatting and lint.
#
# --fix exists because the check-only form left "run gdformat yourself" as a manual
# step, and a hand-run gdformat misses the HOME workaround below — the very thing this
# script was written to carry. Formatting rejections at commit time are now one
# command to clear, using the same tool invocation CI will judge.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FIX="false"
while [[ $# -gt 0 ]]; do
	case "$1" in
		--fix) FIX="true"; shift ;;
		-h|--help) echo "Usage: $0 [--fix]"; exit 0 ;;
		*) echo "Unknown argument: $1" >&2; exit 2 ;;
	esac
done

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

# --cached AND --others: a brand-new .gd is not in the index yet, but the pre-commit
# hook sees it the moment it is staged. Checking only tracked files meant a new file
# was invisible here and rejected there — --fix would report "0 files reformatted"
# about the very file that was blocking the commit. --exclude-standard keeps gitignored
# scratch scripts out.
mapfile -d '' files < <(git ls-files -z --cached --others --exclude-standard '*.gd')
if [[ "${#files[@]}" -eq 0 ]]; then
	echo "check_gdscript_style: PASS — no tracked GDScript"
	exit 0
fi

if [[ "$FIX" == "true" ]]; then
	# Rewrite in place, then still run the checks: formatting is fixable, lint
	# findings are not, so --fix must not be mistaken for "the gate passed".
	gdformat "${files[@]}"
fi

gdformat --check "${files[@]}"
gdlint "${files[@]}"
echo "check_gdscript_style: PASS — ${#files[@]} tracked GDScript file(s)"
