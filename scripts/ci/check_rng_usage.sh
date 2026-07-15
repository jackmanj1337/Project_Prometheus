#!/usr/bin/env bash
# check_rng_usage.sh — fail on new unmarked engine-RNG use in non-test GDScript.
#
# Combat, skill-proc, and growth RNG currently call the engine global randi(); the
# deterministic RngService that replaces them is milestone M9a (RNG-1 / SET-001). Until
# it lands, the known call sites are tagged with a trailing `# rng-allow: ...` marker.
# This guard stops NEW unmarked randi()/randf()/randomize() from creeping in before the
# service exists (AGENTS.md PL#9: a checkable rule ships with its check).
#
# To add a legitimately-allowed site, append `# rng-allow: <reason>` to that line.
# Run from anywhere: scripts/ci/check_rng_usage.sh   (exit 0 = clean, 1 = violations)
set -euo pipefail
cd "$(dirname "$0")/../.."

pattern='\b(randi|randf|randi_range|randf_range)[[:space:]]*\(|\brandomize[[:space:]]*\('
violations=0

while IFS= read -r line; do
	[[ -z "$line" ]] && continue
	if ! grep -q 'rng-allow' <<<"$line"; then
		echo "  $line"
		violations=$((violations + 1))
	fi
done < <(grep -rnE "$pattern" --include='*.gd' scripts | grep -v '/tests/' || true)

if [[ "$violations" -gt 0 ]]; then
	echo "FAIL: $violations unmarked engine-RNG use(s) in non-test GDScript."
	echo "      Route through RngService (M9a) or mark the line with '# rng-allow: <reason>'."
	exit 1
fi
echo "check_rng_usage: PASS — no unmarked engine-RNG use in non-test GDScript"
