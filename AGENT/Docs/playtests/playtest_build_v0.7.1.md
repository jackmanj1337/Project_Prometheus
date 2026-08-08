---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-08-08
---

# v0.7.1 Windows tester candidate

This private Windows candidate verifies the first installable extraction produced after
the v0.7.0 return. It includes fixes for catalogue/document identity and for item-effect
fields that were lost by extraction. It is not an accepted release and carries no tag.

- Source branch: `agent/playtest-release-v0.7.1`
- Source commit: recorded per artifact in `artifact-manifest-*.json` and
  `BUILD_INFO.json`; it is read from the exported artifact rather than transcribed here.
- Baked product version / preset: `0.7.1` / `Project Prometheus v0.7.1`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: the full suite must be green on the exact exported commit.

The supplied pack is `prometheus-v071-playwright-test` version `0.1.0`. Before bundling,
its archive passed installer preflight, Tier-2 activation, all eight map playability checks,
and all three roster checks. The Windows pass exercises the native file dialog, physical
input devices, real rendering, and human visual judgement unavailable in the container.

Use `playtest_checklist_v0.7.1_windows.md`. Return the completed checklist, debug log,
and screenshots for every failed visual item.
