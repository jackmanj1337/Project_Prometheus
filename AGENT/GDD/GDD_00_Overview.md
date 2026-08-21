# Game Design Document
## Fire Emblem Tabletop RPG Adaptation
### A Top-Down Turn-Based Strategy RPG

**Status:** Active — project entry point.
**Last verified:** 2026-07-29
**Governance:** `AGENT/Docs/governance/documentation_governance_2026-06-13.md`

This is the starting page for any contributor. It defines the documentation
authority model, points to the feature and decision indices, and summarizes the
project scope, release definition, baseline, work routing, and platform targets. It
does **not** hold rule detail — each rule lives in its owning numbered chapter.

---

## Documentation Authority (DOC-001)

The numbered GDD owns project **design rules and target design**. The Awakening
corpus is a **reference** for building features; a corpus rule becomes a project
target only through an explicit **adoption-matrix** entry plus a GDD update. A later
edit to the corpus never changes project rules on its own.

When documents disagree, use this order:

1. **Ratified dated decisions and resolved registers** — the decision register,
   dated decision records, feature registers, and governance standards in
   `AGENT/Docs` (see the decision index below).
2. **Code and tests for claims about implemented behavior.** If shipped behavior
   contradicts a ratified decision, the mismatch is a tracked gap rather than a
   silent rule change.
3. **Project Control Plane**
   (`AGENT/Docs/plans/project_control_plane_2026-06-29.md`) for exact work status,
   Track IDs, dependencies, source docs, tests, and next actions.
4. **The numbered GDD** (`GDD_01`–`GDD_08`) for concise domain contracts, with
   each section's status label distinguishing implemented from target design.
5. **Active design sources and implementation plans** for supporting detail.
6. **Session notes, reviews, and archived documents** as historical evidence, not
   active design or schedule authority.
7. **The Awakening corpus** (`Content Expansion/New_Content_Expansion/`) as external
   reference, binding only where an adoption-matrix entry has adopted it.

> This order is written from **DOC-001**. The earlier D-C direction (corpus
> authoritative for rules) is **superseded** — see `decision_index.md`.

### Status vocabulary

Every status-bearing section uses one label — **Implemented · Pending validation ·
Known issue · Target design · Planned · Deferred · Open decision · Historical ·
Superseded** — plus a `Last verified` date. The unqualified words "current,"
"complete," and "canonical" are prohibited in status-bearing sections. A feature may
carry a **split status** (an `Implemented` line and a `Target design` line) during
migration. Full table + the GDD section template: the governance doc.

---

## Navigation

| Index | Purpose |
|---|---|
| `GDD_Feature_Index.md` | **Start here for a feature** — routes each feature to its rule owner, Track IDs, code/data, tests, decisions, and reference source. |
| `AGENT/Docs/plans/project_control_plane_2026-06-29.md` | Exact work rows, Track IDs, dependencies, source docs, tests, and next actions. |
| `GDD_10_Roadmap.md` | Human build guide: dependency bands, next-work summary, and links to control-plane rows. |
| `AGENT/Docs/INDEX.md` / `AGENT/Docs/REGISTERS.md` | Generated navigation for active documentation and decision registers. |
| `AGENT/Docs/decisions/decision_index.md` | Every decision ID (DOC-/RULE-/SET-/RNG-/OPEN-/AWR-) with status and home. |
| `GDD_Adoption_Matrix.md` | Which Awakening corpus rules are adopted (target / with variation / rejected / deferred) and the GDD owner of each variation. |
| `AGENT/Docs/governance/documentation_governance_2026-06-13.md` | Status vocabulary, section shape, and documentation definition-of-done rules. |

### Document map (live set)

| File | Owns |
|---|---|
| `GDD_00_Overview.md` | This file — authority model, indices, release definition, platform targets |
| `GDD_01_Architecture.md` | Project structure, scene/autoload composition, extension boundaries |
| `GDD_01_Runtime_Contracts.md` | CampaignRules, deterministic events, snapshots, shared runtime service boundaries |
| `GDD_01_Data_Contracts.md` | Resource schemas, persistence fields, validation and authoring bindings |
| `GDD_02_Core_Mechanics.md` | Grid, turns, combat resolution, RNG model, EXP, permadeath, terrain combat |
| `GDD_03_Units_Classes.md` | Units, classes, progression, promotion, reclass |
| `GDD_04_Weapons_Items.md` | Weapons, items, weapon triangle, WEXP, economy-facing rules |
| `GDD_05_Skills.md` | Skills, triggers/precedence, Pair Up/support, status conditions |
| `GDD_06_Maps_Objectives.md` | Terrain, movement categories, objectives, authored-map contracts |
| `GDD_07_UI_UX.md` | Cross-cutting UI state, feedback, accessibility, and parity |
| `GDD_07_Input_Cursor.md` | Input bindings/modes, repeat policy, cursor and threat interaction |
| `GDD_07_Screens_Panels.md` | Screen/panel catalog, settings and per-surface behavior |
| `GDD_08_Enemy_AI.md` | AI behavior, parity obligations, performance constraints |
| `GDD_10_Roadmap.md` | Build guide — dependency-band narrative, next-work queue, validation/release summaries, Track ID links |

Operational guides live in `AGENT/Docs` (`environment_setup.md`, `testing_guide.md`,
`map_authoring_guide.md`, `fe_map_sprite_importer_guide.md`) and are linked from the
relevant feature rows; the GDD does not duplicate them.

### Documents being retired or migrated

Per the lifecycle table (`AGENT/Docs/governance/documentation_lifecycle_2026-06-13.md`), these
are **not** authority sources; retrieve via Git history once removed:

- `GDD_09_Checklist.md` — **Deleted** (Stage 5.2, 2026-06-13); MVP build sequence,
  retrieve via Git. Open backlog items were already in GDD_10_Roadmap Phase 3 (DOC-006).
- `GDD_10a_Overview.md` — **Deleted** (Stage 4.1, 2026-06-13); content merged into
  `GDD_10_Roadmap.md` Appendix A–C. Retrieve via Git history if needed (DOC-004).
- `GDD_Assumptions.md` — **Deleted** (Stage 5.2, 2026-06-13); assumptions are now
  embedded in owning GDD chapters (GDD_02/03/06/07/08) or in design decisions.
  Retrieve via Git if needed (DOC-006).
- `GDD_Manual_Tasks.md` — **Moved** (Stage 5.2, 2026-06-13); now at
  `AGENT/Docs/guides/manual_test_playbook.md` (DOC-007).

---

## Project Scope (SET-011..014)

Status: **Active**
Last verified: 2026-06-29

This project is first a learning project and portfolio display piece. Decisions optimize
for demonstrable engineering quality, readable architecture, durable tests, and a
showable result. Commercial-release optimization is not the primary lens.

The secondary product direction is a flexible tactical-RPG builder. The engine should
let users build and share campaigns with custom assets, maps, rosters, rules, and
presentation data. The owner's FE-inspired rules and project examples are useful as
developer-provided presets and validation content; author-facing vocabularies should
not require engine edits when new content variants are added.

Power-user access has a clear boundary. Public source is the unlimited-access path:
someone who wants full control can fork the repo and change the engine. In-app campaign
authoring is data-only first, and any later in-app scripting must stay sandboxed. Shared
campaign packages must not require executable code.

The portfolio showpiece is a slice-first playable web demo: first a polished,
complete-looking playable slice, then evidence that the slice was authored with the
builder. This framing does not resequence the Band 1-8 build order; it is tracked by
`REL-WEB-DEMO` in the Project Control Plane.

## Design Pillars

1. **Rules-faithful** — combat math, weapon triangles, and stat interactions follow the
   project's authored FE-inspired rules, while treating those values as authorable
   presets where the engine exposes a rule profile.
2. **Extensible by design** — all content lives in data files, not hardcoded logic.
3. **Readable systems** — the player always has the numbers: hit, crit, and expected
   damage are shown before committing to an attack.
4. **Dependency-sliced delivery** — each build slice leaves the game playable and
   testable without consuming foundations that have not landed.

---

## Release Definition (D-B)

**1.0 = all offline, non-pipeline features + one short playable campaign**, framed as
the first builder-authored portfolio slice rather than a commercial-content endpoint.
Exact scope acceptance and sequencing live in `REL-1P0-SCOPE`; this section records
the ratified release boundary, not a separate work queue.

- Campaign **content** for the short campaign is in 1.0; full content coverage is
  post-1.0 (M11 re-scoped).
- **Online play** (M15 Part B, host-authoritative) is **post-1.0**.
- **Public-identity rename** (D-A): all FE-derived names are placeholders; a data-pass
  rename lands no later than the first public release candidate.
- **Legal/licensing review** (DOC-012 / OPEN-12) is a **blocking pre-1.0 gate** for
  FE-derived numeric values and shipped assets. LEG-1 confirmed there is no source
  handbook or published rules corpus to license. This gate is **separate from** the
  rename and is not satisfied by it.

---

## Implemented Baseline

Status: **Implemented** (high-level project baseline; per-feature target design is
separate).
Last verified: 2026-07-13

The shipped baseline is a data-driven tactical map/combat loop with faction phases,
terrain, authored objectives, roster progression, weapons/items/skills, enemy AI,
Pair Up, campaign/suspend state, and keyboard/gamepad-aware UI and settings. Shared
Band 1/2 services now cover deterministic RNG, save encoding, registries,
actions/effects, resource transactions, occupancy, death handling, and projection.

Exact implemented/target splits live in `GDD_Feature_Index.md`, the owning numbered
chapters, and production tests. This overview intentionally does not mirror their
feature lists.

## Work And Validation Routing

The Project Control Plane owns exact status. Its Validation Queue contains live and
manual acceptance work; its Release Gate Queue contains merge, scope, legal, naming,
packaging, and web-demo gates. `GDD_10_Roadmap.md` summarizes only the next useful
slice. Confirmed findings must be routed to an existing or new Track ID instead of
being maintained as a second list here.

---

## Platform Targets

Status: **Pending validation** (renderer/platform policy implemented; native platform verification remains)
Last verified: 2026-08-21

| Aspect | Target | Source |
|---|---|---|
| Renderer | **Compatibility (OpenGL)** — required for web export; nothing needs Forward+ | OPEN-8 |
| Primary platform | Desktop (Windows, Mac, Linux) plus the portfolio web demo target | SET-014 |
| Steam Deck | **Expand** with persisted Viewport Scale and the 1280×720 authored floor. `UI-VIEWPORT-ASPECT` completed OPEN-11's promised post-UI-scale revisit; native Deck validation remains. | OPEN-11 / `UI-VIEWPORT-ASPECT` |
| Web | **Distribution FROZEN** (2026-07-26) — remains the slice-first portfolio demo target, but no web build is distributed until the data extraction completes and `FE-EXPORT-GUARD` enforces. See below. | OPEN-8, SET-014 / `FREEZE-WEB-DISTRIBUTION-2026-07-26` |
| Steam Deck — text input | **Deck Verified requires the game to display an on-screen keyboard automatically whenever text input is needed.** This is a certification gate, not a recommendation. See the release gate below. | `TEXT-04` / `RELEASE-CHECKLIST-DECK-OSK-2026-07-26` |
| Gamepad | Supported; real-controller acceptance remains tracked by `VAL-V030-GAMEPAD` | `B6-INPUT` / `VAL-V030-GAMEPAD` |
| Mobile | **Deferred** (post-1.0; needs a touch UI redesign) | — |

| Component | Choice | Notes |
|---|---|---|
| Engine | Godot 4 (stable) | 2D tooling; Compatibility renderer |
| Language | GDScript | Codebase is entirely GDScript |
| Data format | Godot Resources (`.tres`) for authored data | JSON-safe envelopes for campaign/suspend saves |
| Version control | Git + GitHub | Public repo; licensing gate (DOC-012) precedes public release |

### Release gate — web distribution is frozen (2026-07-26)

Status: **Deferred** (freeze in force; lifts on the condition below)
Last verified: 2026-07-26

Owner playtests run on `Campaign_Pack_FE` content, whose ratified rule is **never
public and never in a shipped build** — a public *build* redistributes FE-derived art
exactly as a public repo does. Web is a hosted channel, so a web playtest build would
breach that rule. Both statements could not stand, so web **distribution** is frozen.

- **Frozen:** distributing any web build — playtest or demo.
- **Not frozen:** building a web export locally to test. Nothing is published, so the
  web export stays available for development and automated UI testing.
- **Lift condition:** the data extraction is complete **and** `FE-EXPORT-GUARD` is
  enforcing. At that point the guard keeps the rule true mechanically, and this
  blanket freeze stops being the control.

The portfolio web demo is unaffected as a *target*; only distribution is paused.

### Release gate — Steam Deck on-screen keyboard (TEXT-04)

Status: **Planned** (gate applies only once a Steam build is scheduled)
Last verified: 2026-07-26

Recorded here rather than in a design document because a per-version checklist is
written after the fact and this must survive until Steam is actually targeted —
that placement is the substance of the ruling, not a filing detail.

- **Before any Steam Deck submission**, verify the game shows an on-screen keyboard
  automatically wherever it asks for text. Valve's own OSK satisfies this through
  GodotSteam (`showFloatingGamepadTextInput` / `showGamepadTextInput`).
- **No GodotSteam dependency is taken now** — we ship Windows Desktop and there is
  no Steam build. The `system` entry mode exists in the text-entry registry as a
  seam with no backend, so adopting it later is a drop-in rather than a retrofit.
- The ratified text-entry default already routes **touch and gamepad to the in-game
  keyboard**, so a Deck gets one automatically. Whether a *custom* keyboard alone
  satisfies Deck Verified is **not settled by any source** — that is a question for
  Valve, not further desk research.

---

## Conventions Used in These Documents

- Status-bearing sections use the governance status vocabulary + `Last verified` date.
- `[PLACEHOLDER]` — content not yet designed; label clearly in code and assets.
- Code references use `ClassName` or `script_name.gd` format.
- Checklist items use GitHub-style task lists: `- [ ] Task`.
- Per **DoD#1** (definition-of-done): a behavior change updates the affected GDD
  section(s) **and** flips the roadmap status in the **same commit**.
