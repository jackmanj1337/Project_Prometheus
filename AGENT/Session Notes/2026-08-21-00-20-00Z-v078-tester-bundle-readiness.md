# Session Note - 2026-08-21

## Branch context

- Branch: `agent/playtest-release-v0.7.8`
- Base branch: `agent/playtest-release-v0.7.8`
- Base SHA: `b14d49439f2dd651e1e107b8328b98a2729f804c`
- Coordination Work ID: `WINDOWS-PASS-READINESS-2026-08-20`

Picked up [`v078_round_out_handoff_2026-08-20.md`](../Docs/plans/v078_round_out_handoff_2026-08-20.md)
and answered its §1 question first: **the round has not returned.**
`WINDOWS-PASS-READINESS-2026-08-20` is still `in_progress`, the checklist in the repo is
blank, and no return evidence exists anywhere. So §1's preemption rule did not fire and
nothing here triages a return.

## What was done

The handoff says a candidate "is out". It was **cut, not delivered** — and it could not
have been played if it had been handed over as it stood. Three defects, in the order they
were found.

**1. The candidate was never packaged.** Every round from v0.6.1 to v0.7.7 shipped a
`builds/tester/Project_Prometheus_vX.Y.Z_tester_bundle.zip`; v0.7.8 had only the raw
export directory. Two checklist items are unperformable without the bundle, because the
bundle is what generates the things they name — "the executable matches the supplied
checksum" (there was no `SHA256SUMS.txt`) and "the commit recorded in `BUILD_INFO.json`"
(there was no `BUILD_INFO.json`; that file is a bundle artifact, not a repo file, which is
also why the checklist's reference to it looked satisfiable and was not).

**2. The build ships no campaign content, and no pack was staged.** `export_presets.cfg`
excludes `data/**`, so a fresh install has nothing to play. Verified against the artifact
rather than the config: the exe contains no `data/campaigns` path (0 hits against 9 for
`scenes/`). Checklist sections 3, 5 and 6 — overworld gate reasons, terrain variants, and
the battle/save/Continue smoke — all need an imported pack. None was supplied and the
checklist named none.

**3. The pack the checklist was written against does not validate.** Section 3's example
sentence quotes a Proving Grounds node label, so the intended pack is unambiguous. Both
copies — public (`Campaign_Pack_0`) and internal (`Campaign_Pack_FE`) — fail:
`adapter valid: false`, 31 errors, `classes=0 weapons=0 items=0 maps=0 campaigns=0`. The
pack loads **nothing**. Cause is staleness, not corruption: the packs were generated
2026-08-04, and `magic_weapon_requires_uses_mag` (`76ce4096`, 08-08) plus self-contained
pack skills (`c11e9488`, 08-16) both landed after. Re-running the documented two-step
pipeline fixes it completely.

### The ordering hazard, which is the finding worth keeping

Sections 1 and 2 require Continue, Load Game **and** New Game to be gated at once. New
Game stops being gated the moment a pack is installed. So a tester who installs the
supplied pack before starting — the obvious thing to do with a supplied pack — silently
destroys `[ANN-5]`, the row the handoff calls this round's highest-value item, and it
cannot be recovered without clearing saves and packs and starting over. The checklist gave
no ordering and named no pack, so getting this right was left to inference. It now states
the order explicitly, names the pack, and says to clear a previous round's state first.

The section 3 example was also wrong in a way that would have read as a defect: from the
start node the first unreached node is Chapter 2, whose prerequisite is Chapter 1, so the
reason reads *"Clear Chapter 1 - First Blood first."* The checklist asked for Chapter 2.

### What was NOT done, deliberately

**The artifact was not rebuilt, re-exported, or touched.** §1 forbids it and there was no
reason to: the candidate verifies clean. The bundled exe is byte-identical to the one the
handoff recorded — `sha256sum -c` passes against `d143efb1…`, size 106,085,592, stamp
`0.7.8`/`b14d4943`, `source_tree 0a0bd488` matching the full-test receipt. Packaging an
existing artifact is not re-exporting it.

**No debug executable and no web archive.** v0.7.7 shipped both. Producing either now
means exporting new artifacts for an outstanding round, which is the thing §1 rules out.
Called out here rather than quietly omitted: nothing on this checklist needs debug
controls, but the tester will notice the difference from last round.

## Commits

Ownership is in `CLAIMS.tsv`.

`56c71838` on `agent/playtest-release-v0.7.8` carries the checklist fix — ordering block,
named pack, corrected example. It is the only change to this repo and it is docs-only. Two
further commits regenerate the packs in their own repos: the internal re-extraction in
`Campaign_Pack_FE` and the public regeneration in `Campaign_Pack_0`, each on its existing
`agent/from-main/…` branch.

Repairs went to the release line, not `agent/integration`, per §1. The checklist is
therefore now **different on the two branches** — one more thing for the acceptance merge
to fold back, alongside the `playtest_build_v0.7.8.md` split the handoff already flags.

## Gates

- `bash run_tests.sh` — **PASS, 148 suites, 0 failures.** Checked past the exit code, per
  the harness trap the handoff records: 0 `SCRIPT ERROR` lines, 132 `=== Results:` lines
  all reporting `0 failed`. (`test_zero_content_export_gate` prints `(no summary)`; it is
  a non-GDScript gate that emits no Results line, and it is pre-existing.)
- `python3 AGENT/Docs/check_docs.py` — PASS, all 46 checks.
- `pytest` in both pack repos — 5 passed each.
- `validate_pack.gd` on the regenerated public pack — `adapter valid: true`,
  `activates: true`, **8/8 playable maps**, 24 classes, 16 weapons, 7 terrain, 3 rosters.
- `export_pack_archive.gd` — `INSTALLABLE`, archive root `prometheus-proving-grounds/`
  matching the manifest id, 149 entries. This tool performs a real install into a
  throwaway storage root, so "installable" is measured, not inferred from the zip shape.
- Bundle: `builds/tester/Project_Prometheus_v0.7.8_tester_bundle.zip`, SHA-256
  `3dffaa25fe4460601150dec3d45d4a0ec23da64ee0f8b2c3f3429de01ea1bf0a`, 8 entries, all
  staged files present, and `sha256sum -c SHA256SUMS.txt` OK against the candidate.

## Next

**Hand the bundle to the Windows host.** It is complete and verified; nothing else gates
the round.

While it is out, §1 still binds and the handoff's §3 order is unchanged:
`AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20` first (its open design question already has
its answer recorded — prefer the check over the shared builder), then
`REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`, then
`PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20`.

**One thing this session did not chase.** Nothing checks that a shipped pack still
validates against the engine it ships beside. The Proving Grounds packs sat broken for
roughly two weeks across two schema changes, and the only reason it surfaced is that
someone tried to hand one to a tester. `AVAILABILITY-SURFACE-GATE-GUARD` is about to build
exactly this shape of thing — a test-time check over shipped surfaces — and a pack-freshness
check is the same argument applied to content. Worth a row.
