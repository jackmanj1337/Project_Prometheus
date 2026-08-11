---
Type: playtest
Status: Candidate preparation
Last verified: 2026-08-11
---

# v0.7.5 Campaign Library repair candidate

This private candidate supersedes rejected v0.7.4. The v0.7.4 release was cut from
`agent/integration`, but the first-run Campaign Library repair had remained only on the
frozen v0.7.2/v0.7.3 release branches. As a result, v0.7.4 omitted the button, its
screen instance, Main Menu wiring, focus behavior, and regression coverage.

v0.7.5 carries the previously reviewed repair commit together with all v0.7.4 text
entry, exported-registry, and browser-transfer remediation. Its focused automated test
proves that a content-free Main Menu displays and focuses Campaign Library and opens it
directly.

- Source branch: `agent/playtest-release-v0.7.5`
- Source commit and artifact identities: pending exact-commit export.
- Baked product version / preset: `0.7.5` / `Project Prometheus v0.7.5`
- Supplied replacement pack SHA-256:
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.

Use `playtest_checklist_v0.7.5_windows.md` and begin with the Campaign Library presence
check before running the remaining native acceptance items.
