---
Type: plan
Status: Active - research-goal handoff
Last verified: 2026-07-24
---

# UI/UX Research Pass — Goal Handoff

## Purpose

Run the research phase of the UI/UX architecture and reuse pass before the
campaign/data discussion is finished. This is deliberately a research and
question-framing pass, not permission to ratify schemas or implement UI.

The pass should establish a shared player-facing vocabulary, compare proven
interfaces to readable implementations, identify constraints in the current
Project Prometheus UI, and give the owner a compact set of consequential
questions with evidence-backed recommendations.

## Goal To Create

At the start of the research session, use the goal mechanism to create this
objective (no token budget unless the owner explicitly supplies one):

> Research reusable UI/UX architecture for Project Prometheus, grounded in the
> current project and cited external evidence. Produce (1) a vocabulary sheet
> defining stable player-facing and implementation-neutral interaction terms,
> and (2) an owner-questions document containing evidence, alternatives,
> recommendations, dependencies, and explicit decisions to defer. Compare the
> visible UI with readable source code for at least one and no more than four
> relevant projects. Do not ratify campaign/data schemas or begin
> implementation. Stop and request owner judgement immediately if useful
> evidence is blocked by CAPTCHA or robots.txt, or before downloading or
> building any research tool.

Keep the goal active until both documents exist, cite their evidence, pass the
documentation checks, and the tracker points to them. Completing research does
not mean the questions are answered; the owner walkthrough is a later task.

## Scope

Research the shared interaction foundation used across campaign library,
Load/New Game, convoy/shop, prep activities, and later record-oriented screens:

- record lists, selection, sorting, filtering, badges, empty/error/loading states;
- master-detail information hierarchy and action placement;
- modal versus non-modal action menus, confirmation, cancellation, and recovery;
- keyboard, mouse, controller, focus, held-repeat, and contextual prompt behavior;
- responsive layout, menu scaling, text density, accessibility, and 200% stress;
- HUD-layout-editor controller interaction: enter edit mode, choose panel, move,
  scale, reset, accept/cancel, and input ownership;
- reusable concepts that Project Prometheus can adopt without assuming a final
  campaign/data schema.

Inspect the current Project Prometheus scenes/scripts and existing UI research
before external comparison. Record what is already shared, duplicated, or
inconsistent. Treat current behavior as evidence, not automatically as the
desired design.

## Evidence Standard

- Cite every externally derived factual claim with a direct source link.
- Prefer primary sources: official documentation, project documentation,
  repositories, issue/design discussions maintained by the project, and the
  running/released UI itself.
- For each source-code comparator, pin the repository URL and inspected tag or
  commit. Link relevant files or stable lines where practical.
- Pair code findings with produced UI evidence from the same version: an
  official screenshot/video/manual, a locally runnable build already available,
  or a clearly identified project page. Do not infer visible behavior from code
  alone without labeling the inference.
- Compare at least one and at most four projects whose source code is readable.
  Choose projects for relevance and inspectability, not name recognition. At
  least one should demonstrate strong controller/focus behavior or a reusable
  list/detail architecture. More projects are not inherently better.
- Separate facts, interpretations, recommendations, and unresolved questions.
  Record important conflicting evidence rather than silently selecting one side.
- Include an evidence matrix mapping each recommendation/question to Project
  Prometheus evidence and external comparator evidence.
- Keep quotations short; paraphrase and cite. Record licenses/provenance for any
  reusable code or assets encountered, but do not copy them into the project.

## Mandatory Stop And Ask Conditions

Stop research and request the owner's judgement/help immediately when:

1. a useful page, repository view, video, demo, or documentation source is
   blocked by CAPTCHA or robots.txt and owner inspection could unblock the
   evidence;
2. downloading a new tool, executable, repository not already available, asset
   bundle, or large dataset would materially improve the pass;
3. building, installing, or enabling any research/tooling dependency would be
   useful now or likely useful for future passes;
4. inspecting the produced UI requires an owner-only platform, account,
   purchase, private access, or live visual judgement.

When stopping, state exactly what is blocked or proposed, why it matters, its
source/licence/risk where known, the expected benefit to this and future work,
and the best fallback if the owner declines. Do not evade access controls or
substitute an uncited summary for blocked primary evidence.

Ordinary web reading, repository browsing, and inspection of tools/repositories
already present in the workspace do not require a pause.

## Deliverables

### 1. Vocabulary sheet

Create:

`AGENT/Docs/design/ui_ux_interaction_vocabulary_2026-XX-XX.md`

For each term include:

- preferred term and short definition;
- player-facing meaning versus engine/widget meaning, where different;
- synonyms or ambiguous terms to avoid;
- examples and non-examples;
- input/accessibility implications;
- whether it is descriptive now, recommended, or owner-decision pending.

Keep the vocabulary implementation-neutral. Do not turn growing author-facing
concepts into a closed enum or silently define campaign/data ownership.

### 2. Research and owner-questions document

Create:

`AGENT/Docs/design/ui_ux_architecture_research_and_questions_2026-XX-XX.md`

It must contain:

- scope, method, sources, comparator-selection rationale, and limitations;
- current-project UI inventory and observed consistency/debt;
- one-to-four source-code/produced-UI comparator studies;
- cross-project findings and evidence matrix;
- stable question IDs grouped into a walkthrough-friendly decision tree;
- for every question: why it matters, evidence, viable options, tradeoffs,
  recommendation, default if deferred, dependencies, and what must not yet be
  decided because campaign/data work is open;
- a proposed owner-walkthrough order that starts with high-leverage principles
  and avoids repeatedly deciding the same interaction in individual screens;
- a clear list of research gaps or requested owner inspections.

Questions should be consequential choices, not requests for approval of obvious
best practices. If research resolves something without owner preference, record
it as a finding and explain the evidence instead of manufacturing a question.

## Boundaries

- No production code, scenes, assets, schemas, or implementation plan.
- No final campaign/data ownership, persistence, identity, catalogue, or save
  contract decisions.
- No visual-theme or asset-registry ratification while the art/import questions
  remain open; research may identify requirements and vocabulary.
- No copying third-party code or assets during research.
- No assumption that a comparator's pattern fits this project merely because it
  works there; map every recommendation to Godot, current project structure,
  controller-first use, scaling, and campaign-author extensibility.
- Research can recommend a reusable widget boundary, but implementation waits
  for owner decisions and the normal feature lifecycle.

## Read First

1. `AGENT/Docs/design/campaign_library_ux_decisions_2026-07-24.md`
2. `AGENT/Docs/design/ui_ux_asset_inventory_and_reuse_2026-07-02.md`
3. `AGENT/Docs/design/ui_ux_art_asset_research_2026-07-02.md`
4. `AGENT/Docs/design/player_facing_scope_map_2026-06-23.md`
5. `AGENT/Docs/plans/band_ui_initial_designs_review_2026-06-30.md`
6. Current `ModalScreen`, `SelectionCursor`, `FocusNavigator`, `MenuScale`,
   `InputDisplay`, `InputModeManager`, Settings, Load, New Game, Campaign Library,
   and HUD Layout Editor scenes/scripts and their tests.

## Completion Gate

- Both deliverables exist and cross-link each other.
- External factual claims and comparator observations are cited.
- Between one and four readable-source projects are paired with produced-UI
  evidence and pinned to inspected versions.
- The vocabulary distinguishes observations, recommendations, and pending terms.
- Questions have stable IDs, recommendations, defaults, dependencies, and defer
  markers for campaign/data-dependent decisions.
- The local-project audit and evidence matrix are present.
- `AGENT/Docs/INDEX.md` is regenerated.
- `python3 AGENT/Docs/check_docs.py` and the repository fast checks pass.
- `coordination/tasks.json` points to the resulting documents and is regenerated
  and validated.

After this gate, stop for the owner walkthrough. Do not translate the findings
into implementation until the relevant decisions are recorded.
