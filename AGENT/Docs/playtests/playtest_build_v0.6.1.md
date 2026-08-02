---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-08-02
---

# v0.6.1 Windows Tester Candidate

Release and debug Windows executables for the v0.6.0 return-fix line, plus the
responsive-window and HUD-attachment work. Not an accepted release: it does not close
the native Windows gates (real GPU rendering, physical controllers, native FileDialog
Escape ownership) that the container cannot exercise.

- Source branch: `agent/from-v060-return-fixes-playtest/v061-ui-playwright-responsive`
- Baked product version / preset: `0.6.1` / `Project Prometheus v0.6.1`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Bundle: `builds/tester/Project_Prometheus_v0.6.1_tester_bundle.zip`
- Per-artifact provenance: `BUILD_INFO.json` inside the bundle

This file's `Source branch` line is what `scripts/ci/check_release_source_branch.py`
verifies before `scripts/tools/prepare_build.sh` will bake `res://build_info.json`. The
first v0.6.1 export attempt had no such record, so the bake was skipped rather than
fixed — and both shipped executables carried a stale `v0.6.0 / cbd1f832` BUILD STAMP
while every filename and document said v0.6.1. The exporter now bakes and re-verifies
the stamp itself and refuses to build when it does not match HEAD and the preset
version, so a missing record fails loudly at export instead of silently downstream.

Use [`playtest_checklist_v0.6.1.md`](playtest_checklist_v0.6.1.md). Return the completed
checklist and the entire Godot log directory together. Confirm the startup BUILD STAMP
reads `version=0.6.1` before reporting anything.
