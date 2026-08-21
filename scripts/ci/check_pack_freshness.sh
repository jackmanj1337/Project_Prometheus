#!/usr/bin/env bash
# Fails when a campaign pack checked in beside this repo no longer validates
# against the engine in this working tree.
#
# WHY THIS EXISTS. Both Proving Grounds packs sat broken for roughly two weeks
# across two engine schema changes -- magic_weapon_requires_uses_mag (76ce4096)
# and self-contained pack skills (c11e9488) -- reporting `adapter valid: false`,
# 31 errors, and loading NOTHING (classes=0 maps=0 campaigns=0). No suite, hook
# or CI job noticed. It surfaced only because someone tried to hand a pack to a
# tester during a playtest round.
#
# WHY IT LIVES HERE AND NOT IN A SUITE. The packs live in their own repos
# (Project_Prometheus_Campaign_Pack_0 / _FE). A check inside a pack repo cannot
# see the engine schema at all, and this repo's CI checks out only this repo
# (actions/checkout@v4, single repository), so a GDScript suite under
# scripts/tests/ would skip on every CI run -- a green suite that checked
# nothing, which is precisely the failure mode above. The one place both sides
# are visible is a developer workspace, where the pack repos are siblings. So
# this binds to pre-push: the moment a schema change is about to be published.
#
# The engine owns the schema, so the engine carries the check. Packs are found
# by globbing siblings rather than by reading the workspace manifest, so this
# keeps working if that manifest moves or a new pack repo is cloned.
#
# Usage: bash scripts/ci/check_pack_freshness.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIBLING_ROOT="$(dirname "$REPO_ROOT")"
GODOT_BIN="${GODOT_BIN:-godot}"

cd "$REPO_ROOT" || exit 1

# Packs are <sibling repo>/packs/<pack name>/manifest.json. This repo has no
# top-level packs/ directory, so it cannot match itself; its test_fixtures packs
# are deliberately out of scope because suites already exercise those.
mapfile -t manifests < <(
	find "$SIBLING_ROOT" -mindepth 4 -maxdepth 4 \
		-path "$SIBLING_ROOT/*/packs/*/manifest.json" 2>/dev/null | sort
)

if [[ ${#manifests[@]} -eq 0 ]]; then
	# LOUD, and deliberately not fatal. No sibling packs means CI or a standalone
	# clone, where this cannot run. Saying so is the point: a silent skip here
	# would read as coverage that does not exist.
	echo "check_pack_freshness: SKIPPED -- no campaign pack repos beside $REPO_ROOT" >&2
	echo "  Pack schema freshness is NOT verified in this environment." >&2
	echo "  It is checked on pre-push in a workspace that has the pack repos cloned." >&2
	exit 0
fi

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "check_pack_freshness: FAIL -- ${#manifests[@]} pack(s) found but '$GODOT_BIN' is not on PATH" >&2
	echo "  Packs are present, so this environment is expected to verify them." >&2
	exit 1
fi

echo "check_pack_freshness: validating ${#manifests[@]} pack(s) against this working tree..."
failed=0

for manifest in "${manifests[@]}"; do
	pack_dir="$(dirname "$manifest")"
	label="${pack_dir#"$SIBLING_ROOT"/}"
	log="$(mktemp)"

	# Validated through the SAME path activation takes, so a pass here means the
	# pack activates. validate_pack.gd exits 1 on an invalid adapter or a failed
	# activation, 2 on a missing/unreadable manifest.
	"$GODOT_BIN" --headless --path . --script "res://scripts/tools/validate_pack.gd" \
		-- --pack "$pack_dir" >"$log" 2>&1
	status=$?

	counts="$(grep -m1 -E '^classes=' "$log" || true)"

	if [[ $status -ne 0 ]]; then
		echo "  FAIL  $label (validate_pack exit $status)" >&2
		# The whole report from the verdict line down, not a grep for expected
		# phrasings: the error detail is emitted as a free-form indented line
		# ("  Tier2Catalogue: cannot open required JSON ..."), so a pattern list
		# reports the failure without ever saying what broke.
		sed -n '/^=== pack validation/,$p' "$log" | sed 's/^/        /' | head -30 >&2
		failed=1
	elif ! grep -q "adapter valid: true" "$log"; then
		# Exit code and reported verdict are checked independently: a tool that
		# exits 0 while printing a failure verdict is the false green this whole
		# check exists to prevent.
		echo "  FAIL  $label (exit 0 but no 'adapter valid: true' in output)" >&2
		failed=1
	elif [[ -n "$counts" && "$counts" =~ ^classes=0\ .*\ maps=0\ .*\ campaigns=0 ]]; then
		# A pack that validates and loads nothing is the silent-rot shape: the
		# broken packs reported exactly classes=0 maps=0 campaigns=0.
		echo "  FAIL  $label (validates but loads no content: $counts)" >&2
		failed=1
	else
		echo "  ok    $label  ${counts:-(no counts reported)}"
	fi
	rm -f "$log"
done

if [[ $failed -ne 0 ]]; then
	echo "check_pack_freshness: FAIL -- a checked-in pack no longer validates against this engine." >&2
	echo "  Either the schema change needs a migration, or the pack needs regenerating:" >&2
	echo "    extract_proving_grounds_pack.gd -> scripts/retune_public_pack.py -> validate_pack.gd" >&2
	exit 1
fi

echo "check_pack_freshness: PASS -- ${#manifests[@]} pack(s) still validate."
