---
Type: research and planning handoff
Status: Planned — next-session discussion preparation; no implementation
Last verified: 2026-07-23
Tracker: DISCUSS-CAMPAIGN-LIBRARY-UX-2026-07-23
---

# Campaign Library UX — Research and Owner-Discussion Handoff

## Outcome

Prepare the campaign library for an intensive owner design session. Research
comparable systems, identify useful design/research tools, map the complete player
journey, and produce a comprehensive question packet about behavior and interaction.

This is a research and planning session. Do not implement runtime code, scenes,
save schemas, package formats, or v0.5 release changes. Do not silently turn
competitor behavior into Project Prometheus behavior: distinguish observations,
inferences, recommendations, and owner decisions.

## Required grounding

Read these local sources before external research:

1. `zero_content_engine_implementation_plan_2026-07-23.md`;
2. `pack_associated_save_implementation_plan_2026-07-23.md`;
3. `campaign_data_ownership_research_findings_2026-07-23.md`;
4. `campaign_pack_engine_boundary_plan_2026-07-15.md`;
5. current `CampaignLibraryScreen`, New Game, Load Game, pack catalogue,
   installer/preflight, save identity, migration, and export code/tests; and
6. tracker rows `PP-STRATEGIC-DATA-OWNERSHIP`, `IMPL-ZERO-CONTENT-FOUNDATION`,
   `IMPL-PACK-SAVE-SCHEMA`, `IMPL-PACK-SAVE-LOAD-MIGRATION`, and
   `IMPL-PACK-SAVE-EXPORTS`.

Treat the approved ownership decisions as constraints: the engine can boot with no
content; packs are self-contained; the engine writes user state grouped by pack and
campaign identity; installable packs remain clean; portable saves and full backups
are separate surfaces; pack scripts remain disallowed.

## Research track A — comparable implementations

Use current primary sources where possible: official manuals, product documentation,
support articles, design talks, source repositories, and screenshots/video supplied
by their owners. Record access date and direct links. Investigate at least one useful
example from each category:

- game campaign/module libraries and launchers;
- mod managers with enable/disable, dependency, version, and conflict states;
- save selectors that group saves by game/module/profile;
- user-created campaign browsers or scenario selectors;
- import/export and backup/restore workflows; and
- offline-first libraries whose content may be missing, moved, corrupt, or outdated.

Candidate comparisons may include games with campaign/module selection, tabletop
virtual-tabletop modules, open-source game launchers, and established mod managers.
Select comparisons because their interaction problem is relevant, not because their
visual style resembles this project.

For every comparison capture:

- library information architecture and entry hierarchy;
- first-run/no-content behavior;
- install, import, enable, disable, update, duplicate, and removal flows;
- version/dependency/conflict presentation;
- save-to-content association and missing-content recovery;
- metadata shown before launch;
- keyboard/controller accessibility and focus behavior, when documented;
- destructive-action protections and error recovery;
- what works well, what fails, and what is inappropriate for this project; and
- the exact Project Prometheus decision or question the observation informs.

Do not reproduce copyrighted interface art. Small attributed screenshots may be
linked as research evidence; the deliverable should primarily use original diagrams
and paraphrased observations.

## Research track B — useful tools

Evaluate tools rather than adopting them automatically. Cover:

- low-fidelity wireframing and clickable-flow prototyping;
- state-machine, user-flow, and information-architecture diagrams;
- accessibility checks for contrast, text scaling, focus order, and controller-only
  completion;
- terminology/content-design consistency and error-message inventories;
- usability-test scripts, observation capture, and decision matrices;
- Godot-native UI prototyping options that do not contaminate the release branch;
- fixture generation for installed/missing/corrupt/incompatible packs and saves; and
- screenshot or interaction regression tooling suitable for later validation.

For each tool record licence, cost, offline/export capability, repository-friendly
formats, collaboration burden, accessibility support, and whether it produces a
durable artifact we can review in Git. Prefer open formats and tools that do not make
the design dependent on a hosted proprietary account.

Deliver a short recommended toolkit with one primary and one fallback choice for:
wireflows, state diagrams, question/decision tracking, and later usability testing.

## Research track C — current-state interaction audit

Build a screen/action/state inventory from the code and tests. At minimum cover:

- Main Menu entry points;
- Campaign Library;
- New Game campaign and rule-profile selection;
- Load Game and manual/autosave grouping;
- pack import, preflight, install, enable/disable, and replacement;
- missing, disabled, incompatible, mutated, invalid, and corrupt pack states;
- missing-family or invalid-reference activation failures;
- save migration, fingerprint mismatch, and rollback;
- portable-save import;
- clean-pack export;
- full backup and restore; and
- cancellation, retry, progress, success, partial-failure, and destructive-confirm
  states.

For each state record entry conditions, information displayed, available actions,
default focus, confirm/cancel behavior, next state, persistence effects, error path,
and whether keyboard, mouse, and controller can complete it.

## Question-packet requirements

Produce an intensive owner question packet grouped into the sections below. Every
question must include: why it matters, concrete alternatives, a recommendation when
evidence supports one, downstream consequences, and the default assumption if the
owner defers it.

### 1. Library mental model

- What is the top-level object: installed pack, campaign, campaign version, or saved
  run?
- Can one pack contain several launchable campaigns, and how are they grouped?
- What terminology should players see for pack, campaign, scenario, profile, run,
  save, backup, and import?
- Is the library a launcher, a manager, or both; which actions belong on its first
  screen versus a details screen?
- What metadata, provenance, thumbnail, compatibility, completion, and recent-play
  information earns space in the list?

### 2. First run and discovery

- What does a zero-content first boot show and what is its primary call to action?
- Can players browse local files, open an install folder, use bundled samples, or
  reach a future catalogue?
- Should the engine ship templates or examples, given the zero-playable-content
  boundary?
- How should an empty, scanning, permission-denied, or unreadable library differ?

### 3. Installation and lifecycle

- Is import preview mandatory before installation?
- What must be shown about identity, author, version, licence, signature/fingerprint,
  required engine version, and content families?
- What happens when the same id/version, same id/new version, or different id/same
  title is imported?
- Are enable/disable and uninstall separate actions?
- When may a pack be replaced in place, duplicated, rolled back, or retained beside
  another version?
- How are dependency/conflict concepts presented if v1 forbids pack dependencies?
- Which actions require confirmation, and which are reversible?

### 4. Launch and New Game

- Does selecting a campaign immediately expose Continue/New Game, or open details?
- Where are campaign-authored rule profiles chosen, explained, and compared?
- How are mandates, defaults, player-adjustable rules, and locked rules presented?
- What validation happens before the player invests time in setup?
- Should the library remember the last campaign, sort order, filters, and view mode?

### 5. Runs and saves

- Are saves displayed inside a campaign, inside a run, or in a global Load screen
  grouped by campaign?
- How are manual saves, autosaves, suspends, rewind checkpoints, completed runs, and
  imported portable saves distinguished?
- What labels are player-editable, and what identity remains system-generated?
- What happens when a campaign has many runs or a run has many saves?
- Which actions exist for resume, inspect, rename, duplicate, export, archive, and
  delete?

### 6. Missing or incompatible content

- Can a save remain visible when its pack is missing or disabled?
- What actions are offered: locate, import, enable, inspect, export, or delete?
- How are version mismatch, content fingerprint mismatch, missing migration path,
  corrupt archive, and invalid references distinguished in plain language?
- When is loading blocked versus allowed with a warning?
- How much technical diagnostic detail is visible by default, and how is the full
  report copied or exported?

### 7. Import, export, backup, and restore

- Where do portable save, clean pack, and full backup actions live?
- What names, file extensions, summaries, and warnings distinguish them?
- Does restore preview additions, replacements, conflicts, and required disk space?
- Is restore all-or-nothing, selectively restorable, or both?
- What is the rollback experience after validation or write failure?
- How are user state and clean pack data represented without implying that saves are
  embedded in distributable packs?

### 8. Navigation and accessibility

- List, grid, tabs, split-pane, or another hierarchy?
- What is the complete controller focus order for every state?
- What do confirm, cancel, context action, details, search/filter, and shoulder
  navigation do?
- How do text scaling, long titles, localization, missing images, and large libraries
  affect layout?
- Which information may rely on color or icons, and what redundant text is required?
- What loading operations need progress, cancellation, or non-blocking background
  behavior?

### 9. Safety, trust, and privacy

- What provenance and trust language is appropriate when packs contain data and art
  but no executable scripts?
- Should unknown or malformed content be quarantined, merely rejected, or retained
  disabled for inspection?
- What file paths or user information may diagnostics expose?
- What is the trash/recovery policy for packs, runs, and saves?

### 10. Author and advanced-user surfaces

- Can authors test an unpacked development pack alongside installed packs?
- How are validation reports surfaced without overwhelming ordinary players?
- Are duplicate ids, local modifications, and unsigned development builds visibly
  marked?
- Which actions belong in ordinary UI versus developer tools?

## Required deliverables

1. A cited comparative-research report with a feature/interaction matrix.
2. A tool evaluation and recommended research/prototyping toolkit.
3. A current-state screen/action/state audit tied to exact code and tests.
4. An original campaign-library information architecture and end-to-end wireflow,
   including failure and recovery branches.
5. The intensive owner question packet described above.
6. A short list of provisional recommendations clearly separated from decisions.
7. Tracker updates for every newly discovered open task or dependency.

## Definition of done

- At least four materially different comparable systems were studied, with primary
  sources and direct links.
- Research observations are separated from Project Prometheus recommendations.
- The wireflow covers no-content, happy-path, migration, missing-content, corrupt,
  import/export, backup/restore, cancellation, and rollback paths.
- Keyboard, mouse, and controller behavior is addressed throughout.
- Every owner question has alternatives, consequences, recommendation/default, and
  a stable id for recording the answer.
- No runtime or release-line files changed.
- Documentation checks and canonical tracker validation pass.

