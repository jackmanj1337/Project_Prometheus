---
Type: playtest
Status: Awaiting Windows return
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
- Source commit: `acd79ea48a914e21d94db44196da30423de4f8cd`.
- Baked product version / preset: `0.7.5` / `Project Prometheus v0.7.5`
- Supplied replacement pack SHA-256:
  `36be0615b5799043d341487e40e898636d418a45c041c479ffdc27b3de16a423`.
- Automated gate: all 138 suites passed; focused no-pack Main Menu test passed 3/3.
- Source tree: `dcfe1f79d2e8e1cbb922efe1891734718280e32f`.
- Release executable: 105,994,088 bytes; SHA-256
  `e031ad2702b56d520dd12779862f291e510f9d84d8960e0224ffbfab2d4af1e5`.
- Debug executable: 102,122,344 bytes; SHA-256
  `c9c90ff85e2a1ed69f67fe7ae2af4792ecfc23dd7a16555ff84ec7c3dfc0db12`.
- Tester bundle: `Project_Prometheus_v0.7.5_tester_bundle.zip`; 10 files;
  SHA-256 `603e6c1231269d01464532fb8bd6c6799d2c4e4be7aca85e96d3bd7f0ee96311`.

Use `playtest_checklist_v0.7.5_windows.md` and begin with the Campaign Library presence
check before running the remaining native acceptance items.
