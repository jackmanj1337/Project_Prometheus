---
Type: playtest
Status: Exported - pending live Windows validation
Last verified: 2026-08-06
---

# v0.7.0 Windows Tester Candidate

The consolidated v0.7.0 candidate: the v0.6.0 return-fix line, viewport anchoring and
the Viewport Scale setting, terrain variants and pack-introduced terrain, the
mobile-web controller and its UX gaps, the crossing resolver, and the campaign-pack
extraction slice that makes an installed pack playable. Not an accepted release: it
does not close the native Windows gates (real GPU rendering, physical controllers,
native FileDialog Escape ownership) that a container cannot exercise, which is exactly
what the accompanying bundle exists to buy.

Fog of war is deliberately **not** in this candidate's scope: it computes and draws
nothing, so there is nothing to look at.

- Source branch: `agent/integration`
- Source commit: recorded per artifact in `artifact-manifest-*.json` and
  `BUILD_INFO.json`, read back from the binary rather than written here. A commit
  written into this file would name the commit *before* the file was committed, which
  is never the commit that was exported.
- Baked product version / preset: `0.7.0` / `Project Prometheus v0.7.0`
- Godot: `4.6.3.stable.official.7d41c59c4`
- Automated gate: full suite green on this exact commit
  (`audit/check-receipts/Project_Prometheus-full.json`, scope `head`)

Sizes, SHA-256 digests and the read-back BUILD STAMP for each executable are recorded
in the bundle's `BUILD_INFO.json` and `artifact-manifest-*.json`, which are written by
the exporter from the artifact itself rather than transcribed here — v0.6.1 proved
that a hand-copied identity is the one that goes stale.

This file's `Source branch` line is what `scripts/ci/check_release_source_branch.py`
verifies before `scripts/tools/prepare_build.sh` will bake `res://build_info.json`.
The first v0.6.1 export attempt had no such record, so the bake was skipped rather
than fixed, and both shipped executables carried a stale `v0.6.0` BUILD STAMP while
every filename said v0.6.1.

## Campaign packs in this round

This is the first candidate whose bundled campaign pack **plays**. Earlier extractions
emitted maps as terrain and start tiles with weaponless rosters: they installed,
activated, and put the player on an empty board. Both packs now carry an encounter per
map and full unit inventories, verified with
`godot --headless --script res://scripts/tools/validate_pack.gd -- --pack <pack>
--require-playable` (activates; 8/8 maps playable; no unarmed unit).

Use `playtest_checklist_v0.7.0.md`. Return the completed checklist together with the
whole log directory, not a summary.

## Round 2 — re-cut Windows-only, 2026-08-06

The first bundle (candidate `36baae04`, assembled 2026-08-05) was **never run**. It is
superseded rather than amended, and the older zip should be discarded.

- Candidate: `agent/integration` `6cf2c89a8683948772f6b99271955e18ef83552b`
- Automated gate: full suite green on that exact commit — receipt tree
  `755c412b2a745cfee2b3f489e3aba73373efd207`, which is the same tree recorded in both
  artifact manifests, so the tested tree and the exported tree are provably one tree.
- Both executables re-exported from it in `--mode release`; BUILD STAMP read back as
  `version=0.7.0 commit=6cf2c89a` in each.

**Two reasons for the re-cut.** The web export preset shipped `experimentalVK:true`,
which raised the platform keyboard over the game's own grid keyboard on every touch
device (fixed at `6779677c`); and the size-class seam landed. Both post-date the first
freeze.

**Scope narrowed on purpose.** The round asks only what a Windows machine and a
controller can settle. Web, PWA, mobile-device and touch items are deferred to a second
pass, and no screenshot album ships — every question on the round's decision sheet is
answerable live in the application. The documents for this round are
`playtest_checklist_v0.7.0_windows_round.md`, `v0.7.0_windows_round_decision_sheet.md`,
`v0.7.0_windows_round_display_gated_tasks.md` and
`v0.7.0_windows_round_onboarding.md`.

**Why it was cut now rather than after the responsive redesign.** The redesign's Settings
work is queued behind `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`'s claim on
`SettingsManager.gd`, and that row closes only on a Windows return — so waiting for the
redesign to cut the bundle, while the redesign waits on the bundle to release the claim,
is a cycle. Cutting the Windows half now breaks it.
