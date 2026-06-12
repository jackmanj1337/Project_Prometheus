# Fire Emblem Awakening Technical Reference Corpus
# Master Index

> **Project authority notice:** This corpus is external Awakening reference
> material. It does not override the numbered Project Prometheus GDD or dated
> decisions. See [`project_adoption_matrix.md`](project_adoption_matrix.md).

**File:** `awakening_master_index.md`  
**Final Phase:** Master Index  
**Corpus Version:** `1.0.0`  
**Status:** Complete phase-sequenced corpus index  
**Scope:** Navigation guide, corpus summary, document links, dependency order, and recommended reading order.

---

# Table of Contents

1. [Corpus Summary](#corpus-summary)
2. [Complete Document Links](#complete-document-links)
3. [Navigation Guide](#navigation-guide)
4. [Dependency Order](#dependency-order)
5. [Recommended Reading Order](#recommended-reading-order)
6. [Corpus File Map](#corpus-file-map)
7. [Implementation Use Cases](#implementation-use-cases)
8. [RAG Ingestion Guide](#rag-ingestion-guide)
9. [Version and Completion Status](#version-and-completion-status)

---

# Corpus Summary

This corpus is a multi-document technical reference for **Fire Emblem Awakening** systems and data.

The corpus is structured for:

- simulator implementation
- rules engine development
- combat modeling
- growth/stat modeling
- class and skill analysis
- weapon/item lookup
- enemy generation
- child inheritance modeling
- DLC and special-class compatibility handling
- modding reference
- searchable wiki/reference use
- retrieval-augmented generation ingestion

The corpus is intentionally split into smaller markdown files to preserve:

- navigability
- searchability
- schema consistency
- machine-readability
- human-readability
- focused document scope
- phase-by-phase dependency control

---

# Complete Document Links

- [`project_adoption_matrix.md`](project_adoption_matrix.md) — Project adoption status and authority boundary
- [`awakening_project_index.md`](awakening_project_index.md) — Project Index
- [`awakening_core_systems.md`](awakening_core_systems.md) — Core Systems
- [`awakening_lookup_tables.md`](awakening_lookup_tables.md) — Canonical Lookup Tables
- [`awakening_classes_base.md`](awakening_classes_base.md) — Base Classes
- [`awakening_classes_promoted.md`](awakening_classes_promoted.md) — Promoted Classes
- [`awakening_classes_special.md`](awakening_classes_special.md) — Special / NPC / Enemy / DLC Classes
- [`awakening_skills.md`](awakening_skills.md) — Skill Encyclopedia
- [`awakening_weapons_physical.md`](awakening_weapons_physical.md) — Weapon Encyclopedia — Physical Weapons
- [`awakening_weapons_magic.md`](awakening_weapons_magic.md) — Weapon Encyclopedia — Magic, Staves, and Stones
- [`awakening_items.md`](awakening_items.md) — Item Encyclopedia
- [`awakening_archetypes.md`](awakening_archetypes.md) — Archetype Templates
- [`awakening_appendices.md`](awakening_appendices.md) — Appendices

---

# Navigation Guide

| Topic | Document | Use |
|---|---|---|
| Project Index | [`awakening_project_index.md`](awakening_project_index.md) | Corpus overview, normalization assumptions, glossary, schemas, file map, dependency graph, versioning, and roadmap. |
| Core Systems | [`awakening_core_systems.md`](awakening_core_systems.md) | Stat system, growths, levels, promotion, reclassing, WEXP, combat, Pair Up, enemy generation, child mechanics, effectiveness. |
| Canonical Lookup Tables | [`awakening_lookup_tables.md`](awakening_lookup_tables.md) | Stats, weapon types, WEXP thresholds, movement types, terrain categories, vulnerability groups, effectiveness, multipliers, rank progression. |
| Base Classes | [`awakening_classes_base.md`](awakening_classes_base.md) | All regular tier-1/base class definitions using normalized class schema. |
| Promoted Classes | [`awakening_classes_promoted.md`](awakening_classes_promoted.md) | All regular promoted/tier-2 class definitions using normalized class schema. |
| Special / NPC / Enemy / DLC Classes | [`awakening_classes_special.md`](awakening_classes_special.md) | Special, single-tier, transformation, NPC, enemy-only, boss-only, DLC, and placeholder classes. |
| Skill Encyclopedia | [`awakening_skills.md`](awakening_skills.md) | All skills with category, trigger, formula, proc rate, stacking, AI usage, source classes, and hidden mechanics. |
| Weapon Encyclopedia — Physical Weapons | [`awakening_weapons_physical.md`](awakening_weapons_physical.md) | Swords, lances, axes, and bows with rank, WEXP requirement, stats, durability, cost, sell value, effectiveness, and special effects. |
| Weapon Encyclopedia — Magic, Staves, and Stones | [`awakening_weapons_magic.md`](awakening_weapons_magic.md) | Tomes, dark magic, staves, beaststones, and dragonstones with normalized schema. |
| Item Encyclopedia | [`awakening_items.md`](awakening_items.md) | Healing items, consumables, valuables, seals, boosters, utility items, DLC items, and item formulas. |
| Archetype Templates | [`awakening_archetypes.md`](awakening_archetypes.md) | Simulation-ready generic growth packages and role templates for unit/enemy generation. |
| Appendices | [`awakening_appendices.md`](awakening_appendices.md) | Promotion graph, reclass graph, vulnerability matrix, effective damage matrix, inheritance legality, internal-level conversion, examples, DLC compatibility. |

---

# Dependency Order

The corpus was authored in a strict dependency sequence.

| Phase | Document | Title | Purpose | Depends On |
|---|---|---|---|---|
| Phase 0 | [`awakening_project_index.md`](awakening_project_index.md) | Project Index | Corpus overview, normalization assumptions, glossary, schemas, file map, dependency graph, versioning, and roadmap. | N/A |
| Phase 1 | [`awakening_core_systems.md`](awakening_core_systems.md) | Core Systems | Stat system, growths, levels, promotion, reclassing, WEXP, combat, Pair Up, enemy generation, child mechanics, effectiveness. | Phase 0 |
| Phase 2 | [`awakening_lookup_tables.md`](awakening_lookup_tables.md) | Canonical Lookup Tables | Stats, weapon types, WEXP thresholds, movement types, terrain categories, vulnerability groups, effectiveness, multipliers, rank progression. | Phases 0–1 |
| Phase 3 | [`awakening_classes_base.md`](awakening_classes_base.md) | Base Classes | All regular tier-1/base class definitions using normalized class schema. | Phases 0–2 |
| Phase 4 | [`awakening_classes_promoted.md`](awakening_classes_promoted.md) | Promoted Classes | All regular promoted/tier-2 class definitions using normalized class schema. | Phases 0–3 |
| Phase 5 | [`awakening_classes_special.md`](awakening_classes_special.md) | Special / NPC / Enemy / DLC Classes | Special, single-tier, transformation, NPC, enemy-only, boss-only, DLC, and placeholder classes. | Phases 0–4 |
| Phase 6 | [`awakening_skills.md`](awakening_skills.md) | Skill Encyclopedia | All skills with category, trigger, formula, proc rate, stacking, AI usage, source classes, and hidden mechanics. | Phases 0–5 |
| Phase 7 | [`awakening_weapons_physical.md`](awakening_weapons_physical.md) | Weapon Encyclopedia — Physical Weapons | Swords, lances, axes, and bows with rank, WEXP requirement, stats, durability, cost, sell value, effectiveness, and special effects. | Phases 0–6 |
| Phase 8 | [`awakening_weapons_magic.md`](awakening_weapons_magic.md) | Weapon Encyclopedia — Magic, Staves, and Stones | Tomes, dark magic, staves, beaststones, and dragonstones with normalized schema. | Phases 0–7 |
| Phase 9 | [`awakening_items.md`](awakening_items.md) | Item Encyclopedia | Healing items, consumables, valuables, seals, boosters, utility items, DLC items, and item formulas. | Phases 0–8 |
| Phase 10 | [`awakening_archetypes.md`](awakening_archetypes.md) | Archetype Templates | Simulation-ready generic growth packages and role templates for unit/enemy generation. | Phases 0–9 |
| Phase 11 | [`awakening_appendices.md`](awakening_appendices.md) | Appendices | Promotion graph, reclass graph, vulnerability matrix, effective damage matrix, inheritance legality, internal-level conversion, examples, DLC compatibility. | Phases 0–10 |

## Dependency Graph

```text
awakening_project_index.md
│
├── awakening_core_systems.md
│   │
│   ├── awakening_lookup_tables.md
│   │   │
│   │   ├── awakening_classes_base.md
│   │   │   └── awakening_classes_promoted.md
│   │   │       └── awakening_classes_special.md
│   │   │
│   │   ├── awakening_skills.md
│   │   ├── awakening_weapons_physical.md
│   │   ├── awakening_weapons_magic.md
│   │   ├── awakening_items.md
│   │   ├── awakening_archetypes.md
│   │   └── awakening_appendices.md
│   │
│   └── awakening_master_index.md
```

## Dependency List

```text
awakening_project_index.md <- N/A
awakening_core_systems.md <- Phase 0
awakening_lookup_tables.md <- Phases 0–1
awakening_classes_base.md <- Phases 0–2
awakening_classes_promoted.md <- Phases 0–3
awakening_classes_special.md <- Phases 0–4
awakening_skills.md <- Phases 0–5
awakening_weapons_physical.md <- Phases 0–6
awakening_weapons_magic.md <- Phases 0–7
awakening_items.md <- Phases 0–8
awakening_archetypes.md <- Phases 0–9
awakening_appendices.md <- Phases 0–10
awakening_master_index.md <- all completed corpus documents
```

---

# Recommended Reading Order

| Order | Document | Title |
|---:|---|---|
| 1 | [`awakening_project_index.md`](awakening_project_index.md) | Project Index |
| 2 | [`awakening_core_systems.md`](awakening_core_systems.md) | Core Systems |
| 3 | [`awakening_lookup_tables.md`](awakening_lookup_tables.md) | Canonical Lookup Tables |
| 4 | [`awakening_classes_base.md`](awakening_classes_base.md) | Base Classes |
| 5 | [`awakening_classes_promoted.md`](awakening_classes_promoted.md) | Promoted Classes |
| 6 | [`awakening_classes_special.md`](awakening_classes_special.md) | Special / NPC / Enemy / DLC Classes |
| 7 | [`awakening_skills.md`](awakening_skills.md) | Skill Encyclopedia |
| 8 | [`awakening_weapons_physical.md`](awakening_weapons_physical.md) | Weapon Encyclopedia — Physical Weapons |
| 9 | [`awakening_weapons_magic.md`](awakening_weapons_magic.md) | Weapon Encyclopedia — Magic, Staves, and Stones |
| 10 | [`awakening_items.md`](awakening_items.md) | Item Encyclopedia |
| 11 | [`awakening_archetypes.md`](awakening_archetypes.md) | Archetype Templates |
| 12 | [`awakening_appendices.md`](awakening_appendices.md) | Appendices |

## Reading Strategy by Use Case

| Use Case | Recommended Path |
|---|---|
| Simulator implementation | Project Index → Core Systems → Lookup Tables → Classes → Skills → Weapons → Items → Archetypes → Appendices |
| Combat engine implementation | Core Systems → Lookup Tables → Skills → Weapons Physical → Weapons Magic → Appendices |
| Class/reclass engine | Project Index → Core Systems → Lookup Tables → Base Classes → Promoted Classes → Special Classes → Appendices |
| Child inheritance engine | Core Systems → Classes → Skills → Appendices |
| Enemy generation | Core Systems → Lookup Tables → Classes → Archetypes → Appendices |
| Wiki/reference use | Master Index → Project Index → target topical document |
| RAG ingestion | Project Index → each topical document as separate chunk group → Master Index last |
| Modding reference | Lookup Tables → Classes → Skills → Weapons → Items → Appendices |

---

# Corpus File Map

| File | Content Domain | Primary Schema Type | Machine-Readable Use |
|---|---|---|---|
| `awakening_project_index.md` | Project architecture | Corpus metadata | Corpus routing, terminology, schema conventions |
| `awakening_core_systems.md` | Systems formulas | Formula/reference sections | Rules engine primitives |
| `awakening_lookup_tables.md` | Canonical tables | Lookup tables | Constants, enums, terrain, rank, vulnerability tables |
| `awakening_classes_base.md` | Base classes | Class schema | Class database tier 1 |
| `awakening_classes_promoted.md` | Promoted classes | Class schema | Class database tier 2 |
| `awakening_classes_special.md` | Special classes | Class schema | Special/NPC/enemy/DLC class database |
| `awakening_skills.md` | Skills | Skill property schema | Skill resolver, proc engine, AI skill behavior |
| `awakening_weapons_physical.md` | Swords/lances/axes/bows | Weapon schema | Physical weapon database |
| `awakening_weapons_magic.md` | Tomes/staves/stones | Weapon schema | Magical/utility/stone weapon database |
| `awakening_items.md` | Items | Item property schema | Inventory, class-change, booster, DLC item database |
| `awakening_archetypes.md` | Generic templates | Archetype schema | Unit generation and simulation fixtures |
| `awakening_appendices.md` | Graphs/matrices/examples | Appendix tables | Cross-document implementation references |

---

# Implementation Use Cases

## Rules Engine Bootstrap

Minimum load order:

```text
1. awakening_project_index.md
2. awakening_core_systems.md
3. awakening_lookup_tables.md
4. awakening_classes_base.md
5. awakening_classes_promoted.md
6. awakening_classes_special.md
7. awakening_skills.md
8. awakening_weapons_physical.md
9. awakening_weapons_magic.md
10. awakening_items.md
11. awakening_archetypes.md
12. awakening_appendices.md
```

## Core Entity Types

Recommended entity domains:

```yaml
entities:
  stats:
    source: awakening_lookup_tables.md
  formulas:
    source: awakening_core_systems.md
  classes:
    sources:
      - awakening_classes_base.md
      - awakening_classes_promoted.md
      - awakening_classes_special.md
  skills:
    source: awakening_skills.md
  weapons:
    sources:
      - awakening_weapons_physical.md
      - awakening_weapons_magic.md
  items:
    source: awakening_items.md
  archetypes:
    source: awakening_archetypes.md
  graphs_and_matrices:
    source: awakening_appendices.md
```

## Suggested Parser Keys

| Entity Type | Primary Key |
|---|---|
| Class | Markdown `## [Class Name]` |
| Skill | Markdown `## [Skill Name]` |
| Weapon | Markdown `## [Weapon Name]` |
| Item | Markdown `## [Item Name]` |
| Archetype | Markdown `## [Archetype Name]` |
| Lookup table | Nearest heading path |
| Formula | Code block or inline formula under heading |

---

# RAG Ingestion Guide

## Recommended Chunk Boundaries

| Document Type | Chunk Boundary |
|---|---|
| Project index | Heading-level chunks |
| Core systems | `##` and `###` sections |
| Lookup tables | Individual tables with heading context |
| Class documents | One class per chunk |
| Skill encyclopedia | One skill per chunk |
| Weapon documents | One weapon per chunk |
| Item encyclopedia | One item per chunk |
| Archetypes | One archetype per chunk |
| Appendices | One graph/matrix/example per chunk |

## Metadata Fields

Recommended metadata:

```yaml
metadata:
  game: Fire Emblem Awakening
  corpus: fea-tech-corpus
  corpus_version: 1.0.0
  document: filename
  phase: phase_number
  entity_type: class | skill | weapon | item | archetype | system | lookup | appendix
  entity_name: heading_name
  dependency_level: integer
  source_scope: normalized_technical_reference
```

## Retrieval Routing

| Query Type | Route To |
|---|---|
| Formula or combat question | `awakening_core_systems.md`, `awakening_lookup_tables.md` |
| Class stats/growths/caps | Class document matching class tier |
| Skill activation/stacking | `awakening_skills.md` |
| Weapon stat/effect | Physical or magic weapon document |
| Item effect | `awakening_items.md` |
| Promotion/reclass graph | `awakening_appendices.md` |
| Enemy generation | `awakening_core_systems.md`, `awakening_archetypes.md`, `awakening_appendices.md` |
| Child inheritance | `awakening_core_systems.md`, `awakening_appendices.md` |
| DLC compatibility | `awakening_classes_special.md`, `awakening_items.md`, `awakening_appendices.md` |

---

# Version and Completion Status

## Corpus Version

```text
1.0.0
```

## Phase Completion Table

| Phase | File | Status |
|---|---|---|
| Phase 0 | `awakening_project_index.md` | Complete |
| Phase 1 | `awakening_core_systems.md` | Complete |
| Phase 2 | `awakening_lookup_tables.md` | Complete |
| Phase 3 | `awakening_classes_base.md` | Complete |
| Phase 4 | `awakening_classes_promoted.md` | Complete |
| Phase 5 | `awakening_classes_special.md` | Complete |
| Phase 6 | `awakening_skills.md` | Complete |
| Phase 7 | `awakening_weapons_physical.md` | Complete |
| Phase 8 | `awakening_weapons_magic.md` | Complete |
| Phase 9 | `awakening_items.md` | Complete |
| Phase 10 | `awakening_archetypes.md` | Complete |
| Phase 11 | `awakening_appendices.md` | Complete |
| Final Phase | `awakening_master_index.md` | Complete |

## Completion Definition

The corpus is complete when all phase files exist and the master index links all documents.

```yaml
corpus_complete: true
version: 1.0.0
documents_completed: 13
numbered_phases_completed: 12
final_phase_completed: true
```

---

# End of Final Phase — Master Index
