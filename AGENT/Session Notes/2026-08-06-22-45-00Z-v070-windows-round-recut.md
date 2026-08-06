# Session Note - 2026-08-06

## Branch context

- Branch: `agent/from-integration/v070-windows-recut`
- Base branch: `agent/integration`
- Base SHA: `6cf2c89a8683948772f6b99271955e18ef83552b`
- Coordination Work ID: `V070-BUNDLE-EXECUTION-2026-08-04`

## What was done

A planning and scheduling session that turned into a re-cut.

**The finding that drove it.** The schedule had a cycle in it. The responsive UI
programme ends with "the bundle waits rather than shipping an unusable portrait build",
while the open-questions inventory names the same Windows session as the critical path —
because `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29` claims `SettingsManager.gd` and the
Settings screen, and closing it releases four queued pieces. One of those pieces is
flipping the retired `1280.0 / 720.0` in `fit_content_scale_factor_for_size`, which is
what makes portrait usable. So the bundle was waiting on the redesign and the redesign
was waiting on the bundle. Owner decision: re-cut Windows-only and run it immediately.

**What was verified before planning around it.** The 2026-08-05 bundle was real and
intact — SHA-256 `22f1a472…1bba39` matched the tracker exactly, both executables stamped
`36baae04`. It simply was never run, and two things landed after its freeze: the
`experimentalVK:true` export-preset fix (`6779677c`) and the size-class seam.

**The re-cut.** Candidate `6cf2c89a`, full suite green on that exact commit, both
executables re-exported from it. Scope narrowed to what a Windows machine and a
controller can settle; web, PWA, mobile-device and touch items deferred to a second pass
with their rows intact. No screenshot album ships — every question on the round's
decision sheet is answerable live in the application, and a Playwright album is browser
evidence in a Windows-only bundle.

Four new bundle documents (checklist subset, decision sheet, display-gated list,
onboarding); the superseded round's four documents marked, and the web onboarding marked
**deferred rather than superseded** because it will be reused.

**A defect found in the deferred web onboarding, not fixed here.** Its export command
carries a literal `<commit>` placeholder, so returned web evidence could not have been
attributed to a commit. Recorded in the document as a must-fix before the mobile pass
ships, and it must pin a commit containing the `experimentalVK` fix.

## Commits

`83c7e368` re-cut the round: the four new Windows-round documents, the supersession
marks on the old set, and the round-2 record appended to `playtest_build_v0.7.0.md`.

## Gates

- `bash scripts/run-full-tests.sh --repo Project_Prometheus` — PASS, all suites green on
  `6cf2c89a`. Receipt tree `755c412b2a745cfee2b3f489e3aba73373efd207`.
- Both artifact manifests record `source_tree` `755c412b…` — the same tree as the receipt,
  so the tested tree and the exported tree are provably one tree.
- BUILD STAMP read back from both binaries: `version=0.7.0 commit=6cf2c89a`.
- `validate_pack.gd --require-playable` on both packs: activates, 8/8 maps playable, no
  unarmed unit.
- `check_docs.py` — PASS.
- Bundle: `builds/tester/Project_Prometheus_v0.7.0_tester_bundle.zip`, 229 entries,
  SHA-256 `f0b52815219795e8ecb043c8d750c42d94be74b615dc9b2ceb5b6f899dbb4f20`.

## Next

The bundle is ready to hand to the owner. The single most valuable line in the return is
`escape_consumed_by` from checklist §4 — it releases the `SettingsManager.gd` claim that
the Settings conversion, the persisted Menu Mode and information density, and dropping
`system` from the text-entry vocabulary are all queued behind.

Still unscheduled from the inventory, and untouched by this session: the landscape
game-view rectangle decision (blocks the entire landscape keyboard), the 20+ unheld
design discussions, and the licensing pair where the register reads RESOLVED but the gate
was never cleared.
