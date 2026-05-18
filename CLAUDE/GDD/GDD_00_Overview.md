# Game Design Document
## [PROJECT NAME — PLACEHOLDER]
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
| `GDD_09_Checklist.md` | Master implementation checklist (MVP — milestones M0–M7) |
| `GDD_10_Roadmap.md` | Phase 2 roadmap — milestones M8–M16 |

Supporting documents (not numbered): `GDD_Assumptions.md` records design decisions
made from GBA Fire Emblem convention; `GDD_Manual_Tasks.md` lists tasks that require
the Godot editor and cannot be done by editing files.

> GDD_01–GDD_09 have been resynced to the implementation — they describe the code
> as built. GDD_10 is forward-looking. The MVP architectural amendments (A1–A4) that
> were once tracked in a separate `GDD_updates.md` are now folded into GDD_01–GDD_09.

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

### MVP (Milestone 1 — Playable Prototype)
- Grid-based map with terrain
- 6 starter classes (Soldier, Mercenary, Archer, Mage, Cleric, Knight)
- Basic weapon types (Sword, Lance, Bow, Fire tome, Heal staff)
- Full combat resolution (hit, crit, damage, weapon triangle, counterattack, follow-up)
- Player turn + Enemy turn loop
- Simple enemy AI (attack weakest target in range)
- Experience and leveling
- Permadeath toggle (unit is incapacitated, not deleted)
- 1 playable map with a Rout objective
- Basic UI (unit info, attack preview, turn management)

### Phase 2 — Content Expansion
- Remaining handbook classes
- Full weapon roster
- Generic and class skills
- Additional map objectives (Seize, Rout, Escape, Defend, Defeat the Boss)
- Status conditions (Poison, Sleep, Silence, Berserk, Stun)
- Class promotion system
- Forging system
- Additional maps
- **Between-map save / load** — roster state, current map, gold; saved at map end and on quit

### Phase 3 — Polish & Release
- [PLACEHOLDER — Story / campaign structure]
- [PLACEHOLDER — Art pass]
- [PLACEHOLDER — Audio]
- **Mid-battle suspend save** — full battle state serialization; built on Phase 2 save infrastructure
- Settings menu (keybindings, audio, gameplay options)
- Steam / GitHub release preparation

---

## Tech Stack

| Component | Choice | Notes |
|---|---|---|
| Engine | Godot 4 (stable) | Free, open source, excellent 2D tooling |
| Language | GDScript | Default Godot language, Python-like, beginner friendly |
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
