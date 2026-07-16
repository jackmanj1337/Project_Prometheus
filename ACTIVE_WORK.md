# Active Work

Generated from `branches.yaml`; do not edit directly.

| Work ID | Title | Status | Branch | Owner | Target | Base | Dependencies | Blockers | Reference | Updated | Playtest |
|---|---|---|---|---|---|---|---|---|---|---|---|
| BRANCH-CONSOLIDATION-2026-07-16 | Consolidate Project Prometheus branches and establish release flow | in_progress | agent/codex/2026-07-16/integration-candidate | codex | integration | main | — | workflow-scope PAT required to push integrated workflow history, human creation of protected integration and coordination refs | local integration commit 33d1c0c | 2026-07-16 | — |
| RECOVERY-STALE-MAIN-AI | Preserve stale-main AI scorer and v0.4.0 evidence | in_review | agent/codex/2026-07-16/recover-stale-main-ai-scorer | codex | integration | main | BRANCH-CONSOLIDATION-2026-07-16 | scorer implementation predates current AI composition seam | 82cb73c code; 7861e38 playtest evidence | 2026-07-16 | v0.4.0 evidence at 7861e38 |
| RECOVERY-ENCOUNTER-PLANNING | Preserve AI scorer planning from encounter worktree | in_review | agent/codex/2026-07-16/recover-encounter-planning | codex | integration | agent/b4-encounter-model-slice2 | BRANCH-CONSOLIDATION-2026-07-16 | — | planning content integrated as 808103e | 2026-07-16 | — |
| RECOVERY-V041-PLAYTEST | Preserve returned v0.4.1 playtest evidence | in_review | agent/codex/2026-07-16/recover-v041-playtest | codex | integration | agent/codex/2026-07-14/v0.4.0-windows-build | BRANCH-CONSOLIDATION-2026-07-16 | — | 540d021 | 2026-07-16 | v0.4.1 returned evidence at 540d021 |
| LEGACY-PREP-SAVE-FOLLOWUP | Campaign save and package follow-up line | in_review | agent/codex/2026-07-15/prep-save-followup | codex | integration | main | BRANCH-CONSOLIDATION-2026-07-16 | — | fully contained in encounter-model line | 2026-07-16 | — |
| LEGACY-V040-RELEASE | v0.4 playtest, release fixes, and build line | playtesting | agent/codex/2026-07-14/v0.4.0-windows-build | codex | release/v0.4.2 | main | BRANCH-CONSOLIDATION-2026-07-16 | release fixes require port to split MapResults/GameOver architecture | eight local commits through 7b9ec1e | 2026-07-16 | v0.4.2 build record at 7b9ec1e |
| LEGACY-V032-BUILD | v0.3.2 focused rerun evidence line | in_review | agent/codex/2026-07-12/v0.3.2-build | codex | archive | main | BRANCH-CONSOLIDATION-2026-07-16 | — | preserve build/checklist evidence; reject obsolete reverts | 2026-07-16 | v0.3.2 checklist at 6d84554 |
| LEGACY-GUI-TESTING | GUI behavior changes and pixel-art research | in_review | agent/GUI-testing | legacy-agent | integration | main | BRANCH-CONSOLIDATION-2026-07-16 | UI commits require comparison with newer menu-scale implementation | four unique commits through 633b43d | 2026-07-16 | — |
