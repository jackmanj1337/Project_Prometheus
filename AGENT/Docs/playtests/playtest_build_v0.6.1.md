---
Role: dated
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
- Source commit: `a39879613a89259ec4bbb284f0cdd58db468799e` (both executables)
- Source tree: `58a8e15701c9d656cd0b7cc8fbc16c35a41d54a7`
- Baked product version / preset: `0.6.1` / `Project Prometheus v0.6.1`
- Baked BUILD STAMP: `version=0.6.1 commit=a3987961`, verified present in both binaries
- Godot: `4.6.3.stable.official.7d41c59c4`
- Release executable: `106145512` bytes, SHA-256
  `9c1c42864df4e876af6780ca62ad1666d1da835ac0acc644be2a8e1d79aa3dd0`
- Debug executable (`--export-debug`, `OS.is_debug_build()` true): `102273768` bytes,
  SHA-256 `c97699f47de800d8de0d8240b614b7734120a429a6b54df4699158f9b2ab0942`
- Bundle: `builds/tester/Project_Prometheus_v0.6.1_tester_bundle.zip`, SHA-256
  `c2798099d0f0b8de882844f10595259fa827c6566c570669fd969e5086c76078`
- Per-artifact provenance: `BUILD_INFO.json` inside the bundle
- Automated gate: 119 suites green; Playwright album 133/133

Unlike the first v0.6.1 attempt, both executables come from the same commit, so the
tag policy's "tag points at the exact BUILD STAMP commit" has a single answer.

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
