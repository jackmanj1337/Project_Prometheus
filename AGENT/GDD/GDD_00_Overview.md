# Game Design Document
## Fire Emblem Tabletop RPG Adaptation
### A Top-Down Turn-Based Strategy RPG

**Status:** Active — project entry point.
**Last verified:** 2026-07-07
**Governance:** `AGENT/Docs/governance/documentation_governance_2026-06-13.md`

This is the starting page for any contributor. It defines the documentation
authority model, points to the feature and decision indices, and summarizes the
project scope, release definition, baseline, known issues, and platform targets. It
does **not** hold rule detail — each rule lives in its owning numbered chapter.

---

## Documentation Authority (DOC-001)

The numbered GDD owns project **design rules and target design**. The Awakening
corpus is a **reference** for building features; a corpus rule becomes a project
target only through an explicit **adoption-matrix** entry plus a GDD update. A later
edit to the corpus never changes project rules on its own.

When documents disagree, use this order:

1. **Ratified dated decisions** — the decision register, dated decision records, and
   governance standards in `AGENT/Docs` (see the decision index below).
2. **The numbered GDD** (`GDD_01`–`GDD_08`) as the live design/implementation
   contract, with each section's status label distinguishing implemented from target.
3. **Code and tests** for shipped behavior, except where they contradict a ratified
   decision (in which case the code is a tracked gap, not the rule).
4. **Project Control Plane** (`AGENT/Docs/plans/project_control_plane_2026-06-29.md`)
   for exact work rows, Track IDs, dependencies, source docs, tests, and next
   actions.
5. **`GDD_10_Roadmap.md`** for the human build guide: dependency-band narrative,
   next-work queue, release/validation summaries, and links to Track IDs.
6. **The Awakening corpus** (`Content Expansion/New_Content_Expansion/`) as external
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
| `AGENT/Docs/decisions/decision_index.md` | Every decision ID (DOC-/RULE-/SET-/RNG-/OPEN-/AWR-) with status and home. |
| `GDD_Adoption_Matrix.md` | Which Awakening corpus rules are adopted (target / with variation / rejected / deferred) and the GDD owner of each variation. |

### Document map (live set)

| File | Owns |
|---|---|
| `GDD_00_Overview.md` | This file — authority model, indices, release definition, platform targets |
| `GDD_01_Architecture.md` | Project structure, data/serialization contracts, autoload order, snapshot/RNG seams |
| `GDD_02_Core_Mechanics.md` | Grid, turns, combat resolution, RNG model, EXP, permadeath, terrain combat |
| `GDD_03_Units_Classes.md` | Units, classes, progression, promotion, reclass |
| `GDD_04_Weapons_Items.md` | Weapons, items, weapon triangle, WEXP, economy-facing rules |
| `GDD_05_Skills.md` | Skills, triggers/precedence, Pair Up/support, status conditions |
| `GDD_06_Maps_Objectives.md` | Terrain, movement categories, objectives, authored-map contracts |
| `GDD_07_UI_UX.md` | UI/UX behavior, input, settings, accessibility |
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
presentation data. Existing handbook/corpus values and project examples are useful as
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
   adopted corpus/handbook rules as closely as reasonable for a digital game, while
   treating those values as authorable presets where the engine exposes a rule profile.
2. **Extensible by design** — all content lives in data files, not hardcoded logic.
3. **Readable systems** — the player always has the numbers: hit, crit, and expected
   damage are shown before committing to an attack.
4. **Modular milestones** — the game is playable and testable at the end of each phase.

---

## Release Definition (D-B)

**1.0 = all offline, non-pipeline features + one short playable campaign**, framed as
the first builder-authored portfolio slice rather than a commercial-content endpoint.

- Campaign **content** for the short campaign is in 1.0; full content coverage is
  post-1.0 (M11 re-scoped).
- **Online play** (M15 Part B, host-authoritative) is **post-1.0**.
- **Public-identity rename** (D-A): all FE-derived names are placeholders; a data-pass
  rename lands no later than the first public release candidate.
- **Legal/licensing review** (DOC-012 / OPEN-12) is a **blocking pre-1.0 gate** —
  handbook/corpus derivative-works rights and attribution must be resolved before 1.0.
  This is **separate from** the rename and is not satisfied by it.

---

## Implemented Baseline

Status: **Implemented** (project behavior; corpus migration is **Target design** —
see the feature index and per-chapter status).
Last verified: 2026-06-13

- Grid-based map with terrain
- 6 starter classes (Cavalier, Mercenary, Archer, Mage, Cleric, Knight) — *being
  migrated to corpus class definitions (Target design, AWR-2)*
- Basic weapon types (Sword, Lance, Bow, Fire tome, Heal staff)
- Full combat resolution (hit, crit, damage, weapon triangle, counterattack, follow-up)
- Faction-based phase loop with authored turn order, alliance groups, controller ownership
- Whole-phase hotseat support for non-blue factions
- Enemy AI profiles (`basic`, `passive`, `healer`) with per-faction dispatch
- Experience and leveling; permadeath toggle (incapacitated, not deleted)
- Promotion and Second Seal reclassing
- Pair Up pass 1 (`Pair Up`, `Swap`, `Separate`, snapshot persistence)
- Multi-condition objectives (Rout, Seize, Defeat Boss, Escape, Survive/Defend, Protect)
- 8 registered maps including validation and objective-showcase maps
- Basic UI plus Settings, New Game map selector, character sheet, and More Info panels

The authoritative, per-feature implemented/target split lives in `GDD_Feature_Index.md`
and the owning chapters; this list is a high-level snapshot only.

## Known Issues & Pending Validation

Status: **Known issue**
Last verified: 2026-06-13

- **Combat preview render** — Known issue (2026-06-10); fix tracked in
  `AGENT/Docs/archive/plans/combat_preview_render_fix_plan_2026-06-10.md`.

The roadmap (`GDD_10_Roadmap.md`) owns the authoritative bug/pending-validation list;
confirmed playtest defects are migrated there during roadmap consolidation. This
summary is a pointer, not the tracker.

---

## Platform Targets

Status: **Target design** (renderer/platform decisions ratified; verification pending)
Last verified: 2026-07-07

| Aspect | Target | Source |
|---|---|---|
| Renderer | **Compatibility (OpenGL)** — required for web export; nothing needs Forward+ | OPEN-8 |
| Primary platform | Desktop (Windows, Mac, Linux) plus the portfolio web demo target | SET-014 |
| Steam Deck | **Letterbox** (keep 16:9) at first Deck verification; aspect expansion revisit routed to `UI-VIEWPORT-ASPECT` now that Menu Scale exists | OPEN-11 / `UI-VIEWPORT-ASPECT` |
| Web | Playtest distribution channel and slice-first portfolio demo target | OPEN-8, SET-014 |
| Gamepad | Supported, landing with the key-rebinding milestone | — |
| Mobile | **Deferred** (post-1.0; needs a touch UI redesign) | — |

| Component | Choice | Notes |
|---|---|---|
| Engine | Godot 4 (stable) | 2D tooling; Compatibility renderer |
| Language | GDScript | Codebase is entirely GDScript |
| Data format | Godot Resources (.tres) | JSON acceptable for maps/suspend saves |
| Version control | Git + GitHub | Public repo; licensing gate (DOC-012) precedes public release |

---

## Conventions Used in These Documents

- Status-bearing sections use the governance status vocabulary + `Last verified` date.
- `[PLACEHOLDER]` — content not yet designed; label clearly in code and assets.
- Code references use `ClassName` or `script_name.gd` format.
- Checklist items use GitHub-style task lists: `- [ ] Task`.
- Per **DoD#1** (definition-of-done): a behavior change updates the affected GDD
  section(s) **and** flips the roadmap status in the **same commit**.
