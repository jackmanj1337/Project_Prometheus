#!/usr/bin/env bash
# Read-only environment doctor — run on a new machine to see what still needs setup.
# Informational: prints [OK]/[WARN]/[FAIL] per prerequisite. Always exits 0; treat the
# WARN/FAIL lines as a to-do list. Pairs with scripts/setup_dev.sh (which fixes them).
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
ok()   { printf '  [OK]   %s\n' "$1"; }
warn() { printf '  [WARN] %s\n' "$1"; }
bad()  { printf '  [FAIL] %s\n' "$1"; }

echo "Environment doctor — Project Prometheus"
echo

# Godot 4.6
if command -v godot >/dev/null 2>&1; then
	v="$(godot --version 2>/dev/null | head -1)"
	case "$v" in
		4.6*) ok "Godot on PATH: $v" ;;
		*)    warn "Godot on PATH but not 4.6 (CI uses 4.6): $v" ;;
	esac
else
	bad "Godot not on PATH — install 4.6 stable (+ export templates for builds/)"
fi

# Python 3 (check_docs.py + MCP server)
if command -v python3 >/dev/null 2>&1; then
	ok "python3: $(python3 --version 2>&1)"
else
	bad "python3 not found (needed by check_docs.py and the godot-analyzer MCP)"
fi

# Versioned git hooks active
hp="$(git config --get core.hooksPath || true)"
if [[ "$hp" == "scripts/hooks" ]]; then
	ok "git hooks active (core.hooksPath=$hp)"
else
	warn "git hooks NOT active — run: bash scripts/setup_dev.sh"
fi

# .env present
if [[ -f .env ]]; then
	ok ".env present"
else
	warn ".env missing — copy from .env.example (or use login-based auth)"
fi

# Tracked Godot class cache (lets headless tests resolve class_name on a fresh clone)
if [[ -f .godot/global_script_class_cache.cfg ]]; then
	ok "global_script_class_cache.cfg present"
else
	warn "Godot class cache missing — run: bash scripts/setup_dev.sh"
fi

# Remote reachability (networked; checks the custom SSH host alias resolves)
if git ls-remote origin -q >/dev/null 2>&1; then
	ok "git remote 'origin' reachable"
else
	warn "cannot reach 'origin' — set up SSH host alias/key (git@github.com-project-prometheus)"
fi

# Tooling smoke checks
if python3 AGENT/Docs/check_docs.py >/dev/null 2>&1; then ok "check_docs.py runs clean"; else warn "check_docs.py failed — run it directly to see why"; fi
if bash scripts/ci/check_rng_usage.sh >/dev/null 2>&1; then ok "RNG-usage guard runs clean"; else warn "RNG guard reported issues — run it directly"; fi

echo
echo "Full verification: bash run_tests.sh   (38 GDScript suites)"
echo "See AGENT/Docs/new_machine_transfer_checklist.md for the complete move checklist."
