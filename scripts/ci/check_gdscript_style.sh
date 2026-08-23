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
explicit=()
while [[ $# -gt 0 ]]; do
	case "$1" in
		--fix) FIX="true"; shift ;;
		-h|--help) echo "Usage: $0 [--fix] [file.gd ...]"; exit 0 ;;
		--) shift; while [[ $# -gt 0 ]]; do explicit+=("$1"); shift; done ;;
		-*) echo "Unknown argument: $1" >&2; exit 2 ;;
		*) explicit+=("$1"); shift ;;
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

# Callers may name the files to check. The pre-commit hook passes exactly the staged
# .gd files: linting all 336 tracked scripts cost 17s on EVERY commit, including the
# 81% that touch no GDScript at all — measured at roughly half the repo's entire
# 30-day hook budget, spent re-checking files the commit did not touch. CI still runs
# the whole tree, so nothing stops being checked; it stops being checked per-commit.
# With no file arguments the whole-tree behaviour is unchanged, which is what CI and
# a bare --fix invocation rely on.
#
# --cached AND --others: a brand-new .gd is not in the index yet, but the pre-commit
# hook sees it the moment it is staged. Checking only tracked files meant a new file
# was invisible here and rejected there — --fix would report "0 files reformatted"
# about the very file that was blocking the commit. --exclude-standard keeps gitignored
# scratch scripts out.
scope="tracked"
if [[ "${#explicit[@]}" -gt 0 ]]; then
	scope="named"
	files=()
	for f in "${explicit[@]}"; do
		# A staged deletion or rename source no longer exists; gdformat would abort on it.
		# Written as an `if` rather than `[[ ]] &&` on purpose: under `set -e` a false
		# test as the loop's last command makes the loop's status non-zero and kills the
		# script — which would turn "the last named file is not a .gd" into a hook failure.
		if [[ "$f" == *.gd && -f "$f" ]]; then
			files+=("$f")
		fi
	done
else
	mapfile -d '' files < <(git ls-files -z --cached --others --exclude-standard '*.gd')
fi
if [[ "${#files[@]}" -eq 0 ]]; then
	echo "check_gdscript_style: PASS — no $scope GDScript to check"
	exit 0
fi

if [[ "$FIX" == "true" ]]; then
	# Rewrite in place, then still run the checks: formatting is fixable, lint
	# findings are not, so --fix must not be mistaken for "the gate passed".
	gdformat "${files[@]}"
fi

gdformat --check "${files[@]}"
gdlint "${files[@]}"
echo "check_gdscript_style: PASS — ${#files[@]} $scope GDScript file(s)"
