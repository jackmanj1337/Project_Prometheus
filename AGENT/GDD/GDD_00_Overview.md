# Game Design Document
## Fire Emblem Tabletop RPG Adaptation
### A Top-Down Turn-Based Strategy RPG

---

## Document Index

| File | Contents |
|---|---|
| `GDD_00_Overview.md` | This file. Project goals, scope, tech stack, document map |
| `GDD_01_Architecture.md` | Godot project structure, data-driven design, extensibility patterns |
| `GDD_02_Core_Mechanics.md` | Grid, turns, combat, stats, EXP, permadeath |
| `GDD_03_Units_Classes.md` | Unit data structure, MVP classes, promotion system |
| `GDD_04_Weapons_Items.md` | Weapon/item data structures, MVP content, forging |
| `GDD_05_Skills.md` | Skill system architecture, MVP skills |
| `GDD_06_Maps_Objectives.md` | Map structure, terrain, objectives, MVP maps |
| `GDD_07_UI_UX.md` | All UI screens and panels |
| `GDD_08_Enemy_AI.md` | AI system design and extension hooks |
| `GDD_09_Checklist.md` | Historical MVP implementation checklist (milestones M0-M7) |
| `GDD_10_Roadmap.md` | Phase 2 roadmap — milestones M8–M16 |
| `GDD_10a_Overview.md` | One-screen ordered overview — every planned feature + deferred fix in recommended completion order; companion to GDD_10 |

Supporting documents (not numbered): `GDD_Assumptions.md` records design decisions
made from GBA Fire Emblem convention; `GDD_Manual_Tasks.md` lists tasks that require
the Godot editor and cannot be done by editing files.

### Documentation Authority

When documents disagree, use this order:

1. Ratified dated decisions and later addenda in `AGENT/Docs`.
2. Current code and tests for shipped behavior, except where they violate a
   ratified decision.
3. `GDD_01` through `GDD_08` as the live design/implementation contract.
4. `GDD_10_Roadmap.md` and `GDD_10a_Overview.md` for future work and status.
5. `GDD_Assumptions.md` and `GDD_09_Checklist.md` as historical records.
6. The Awakening corpus as external reference until a rule is explicitly
   adopted into this GDD.

---

## Vision Statement

A faithful digital adaptation of the Fire Emblem tabletop RPG ruleset, designed as a
top-down grid-based turn-based strategy game. Built to be extensible — core systems are
implemented first, with classes, maps, items, and skills added as self-contained data
without requiring engine changes.

---

## Design Pillars

1. **Rules-faithful** — Combat math, weapon triangles, and stat interactions follow the
   handbook as closely as reasonable for a digital game.
2. **Extensible by design** — All content (classes, weapons, skills, maps) lives in data
   files, not hardcoded logic. Adding a new class should never require touching combat code.
3. **Readable systems** — The player always has access to the numbers. Hit chance, crit
   chance, and expected damage are shown before committing to an attack.
4. **Modular milestones** — The game is playable and testable at the end of each
   development phase, even if content is thin.

---

## Scope

### Current Implemented Baseline
- Grid-based map with terrain
- 6 starter classes (Cavalier, Mercenary, Archer, Mage, Cleric, Knight)
- Basic weapon types (Sword, Lance, Bow, Fire tome, Heal staff)
- Full combat resolution (hit, crit, damage, weapon triangle, counterattack, follow-up)
- Faction-based phase loop with authored turn order, alliance groups, and controller ownership
- Whole-phase hotseat support for non-blue factions
- Simple enemy AI profiles (`basic`, `passive`, `healer`) with per-faction dispatch
- Experience and leveling
- Permadeath toggle (unit is incapacitated, not deleted)
- Promotion and Second Seal reclassing
- Pair Up pass 1 (`Pair Up`, `Swap`, `Separate`, snapshot persistence)
- Multi-condition objective system (Rout, Seize, Defeat Boss, Escape, Survive / Defend, Protect)
- 8 registered maps including validation maps and objective showcase maps
- Basic UI plus Settings, New Game map selector, character sheet, and More Info panels

### Phase 2 — Content Expansion
- Remaining handbook classes
- Full weapon roster
- Remaining generic and class skills
- Status conditions (Poison, Sleep, Silence, Berserk, Stun)
- Forging system
- Additional campaign maps and progression flow
- **Between-map save / load** — roster state, current map, gold; saved at map end and on quit

### Phase 3 — Polish & Release
- [PLACEHOLDER — Story / campaign structure]
- [PLACEHOLDER — Art pass]
- [PLACEHOLDER — Audio]
- **Mid-battle suspend save** — full battle state serialization; built on Phase 2 save infrastructure
- Settings expansion: key rebinding, display options, and accessibility controls
- Steam / GitHub release preparation

---

## Tech Stack

| Component | Choice | Notes |
|---|---|---|
| Engine | Godot 4 (stable) | Free, open source, excellent 2D tooling |
| Language | GDScript | Default Godot language; current codebase is entirely GDScript |
| Data format | Godot Resources (.tres) | Native editor support; JSON acceptable for maps |
| Version control | Git + GitHub | Public repo for open source release |
| Target platform | Desktop (Windows, Mac, Linux) | Mobile deferred to Phase 3 |

---

## Release Targets

- **GitHub** — Open source repository, MIT license recommended
- **Steam** — Possible later release; no monetization planned
- **Mobile** — Deferred; note that UI will need a significant redesign pass for touch

---

## Conventions Used in These Documents

- `[PLACEHOLDER]` — Content not yet designed; label clearly in code and assets
- `MVP` — Required for the first playable build
- `Phase 2+` — Planned but not in the first milestone
- Code references use `ClassName` or `script_name.gd` format
- Checklist items use GitHub-style task lists: `- [ ] Task`
