
> **Historical** — External Awakening reference corpus; not active Project Prometheus rules or public-pack content.

# Fire Emblem Awakening Technical Reference Corpus
**Project Index / Corpus Specification**

> **Project authority notice:** This corpus is external Awakening reference
> material. It does not override the numbered Project Prometheus GDD or dated
> decisions. See [`GDD_Adoption_Matrix.md`](../../../../../GDD/GDD_Adoption_Matrix.md).

**Corpus ID:** `fea-tech-corpus`  
**Game:** Fire Emblem Awakening  
**Platform:** Nintendo 3DS  
**Version Scope:** International retail release (mechanically normalized against JP release differences where relevant)  
**Corpus Version:** `0.1.0-phase0`  
**Normalization Status:** Canonicalized  
**Intended Consumers:** Simulator engines, rules engines, modding tools, technical wikis, analytics pipelines, RAG systems, data extraction, systems modeling.

---

# Table of Contents

1. [Corpus Overview](#corpus-overview)
2. [Corpus Design Goals](#corpus-design-goals)
3. [Global Normalization Assumptions](#global-normalization-assumptions)
4. [Glossary](#glossary)
5. [Naming Conventions](#naming-conventions)
6. [Schema Conventions](#schema-conventions)
7. [Mechanical Precision Standards](#mechanical-precision-standards)
8. [Canonical Data Representation Rules](#canonical-data-representation-rules)
9. [File Map](#file-map)
10. [Document Dependency Graph](#document-dependency-graph)
11. [Versioning Strategy](#versioning-strategy)
12. [Canonical Abbreviations](#canonical-abbreviations)
13. [Corpus Roadmap](#corpus-roadmap)

---

# Corpus Overview

This corpus defines a complete technical reference implementation of Fire Emblem Awakening systems and data. "Canonical" in this directory means canonical to the normalized Awakening reference, not canonical to Project Prometheus.

The corpus is designed to function as a canonical source for:

- deterministic simulator implementation
- combat engine reproduction
- probability modeling
- systems analysis
- modding reference
- balance analysis
- AI implementation
- rules engine development
- structured wiki/reference work
- machine ingestion
- retrieval-augmented generation (RAG)

The corpus prioritizes:

1. **Mechanical accuracy**
2. **Internal consistency**
3. **Normalization**
4. **Machine readability**
5. **Human readability**
6. **Searchability**
7. **Implementation utility**
8. **Exhaustive coverage**

No intentional abstraction, summarization, or simplification will be used where a mechanic can be represented explicitly.

---

# Corpus Design Goals

The corpus SHALL:

- represent all player-facing mechanics
- represent hidden/internal mechanics
- normalize inconsistent in-game presentation
- expose formulas explicitly
- expose implementation assumptions
- separate lookup/reference data from systems logic
- distinguish deterministic vs probabilistic systems
- distinguish displayed vs internal values
- preserve simulator-grade precision

The corpus SHALL NOT:

- collapse mechanically distinct systems
- omit hidden mechanics
- omit edge cases
- assume player intuition
- compress data for readability at the cost of precision
- mix speculative behavior with confirmed behavior without annotation

---

# Global Normalization Assumptions

## Canonical Ruleset

The corpus assumes the mechanically complete international retail ruleset of Fire Emblem Awakening.

Where regional differences exist:

- international behavior is primary
- differences are documented explicitly
- internal formulas are prioritized over UI representation

---

## Gender-Locked Class Normalization

Gender-locked classes are normalized into universal class definitions unless mechanics diverge.

### Rule

If two gender variants are mechanically identical, represent as a single class definition.

### Examples

| In-Game Distinction | Corpus Representation |
|---|---|
| Pegasus Knight | Universal Class |
| Fighter | Universal Class |
| Barbarian | Universal Class |
| Priest / Cleric split | Unified only if mechanics identical |
| Troubadour | Unified unless divergence exists |

Mechanical divergence requires separate definitions.

Divergence includes:

- weapon access
- class skills
- growth modifiers
- stat caps
- promotion options
- class flags
- internal restrictions

---

## Numeric Weapon Rank Representation

Weapon proficiency is normalized into numeric WEXP.

### Canonical Thresholds

| Rank | WEXP |
|---|---:|
| E | 1 |
| D | 31 |
| C | 71 |
| B | 121 |
| A | 181 |
| S | 251 |
| Cap | 400 |

All class and unit documentation MUST represent:

- base WEXP
- starting rank
- maximum WEXP
- maximum rank
- promotion carryover
- reclass retention
- inheritance rules
- enemy assignment logic

UI rank labels are secondary to numeric representation.

---

## Internal Level Normalization

Displayed levels and internal levels are separated.

Canonical promoted internal level:

`Promoted Internal Level = 20 + Displayed Level`

The corpus distinguishes:

- displayed level
- internal level
- autolevel inputs
- reclass reset behavior

---

## Formula Standardization

All formulas use normalized notation.

### Formatting Rules

- variables in `PascalCase`
- explicit operators
- deterministic order of operations
- parenthetical grouping
- hidden constants documented

### Example

```text
FinalGrowth =
UnitGrowth + ClassGrowth
```

---

## Terminology Normalization

The corpus standardizes terminology.

| UI Term | Corpus Term |
|---|---|
| Weapon Level | WEXP |
| Weapon Rank | Rank |
| Promotion Bonus | Promotion Modifier |
| Pair Up | Pair Up |
| Double Attack | Follow-Up Attack |
| Effective Damage | Effectiveness Multiplier |

---

## Unknown Behavior Policy

Unknown or disputed mechanics are represented as:

```text
Confirmed
Likely
Disputed
Unverified
```

Unverified assumptions MUST NOT be represented as fact.

---

# Glossary

## Core Terms

| Term | Definition |
|---|---|
| WEXP | Numeric weapon experience value |
| Internal Level | Hidden level used for scaling calculations |
| Displayed Level | Visible player-facing level |
| Class Growth | Growth modifier provided by class |
| Unit Growth | Character-specific growth value |
| Final Growth | Unit Growth + Class Growth |
| Promotion Modifier | Flat stat change on promotion |
| Autolevel | Algorithmic stat gain generation |
| Effective Damage | Bonus damage multiplier vs target group |
| Vulnerability Group | Classification for effectiveness targeting |
| Pair Up | Support mechanic involving lead/support units |
| Dual Strike | Offensive support attack |
| Dual Guard | Defensive nullification trigger |
| Proc Skill | Chance-based skill activation |
| Follow-Up Attack | Additional attack from speed differential |
| Reclass | Class reassignment via Second Seal |
| Child Unit | Parent-derived recruitable unit |
| Inheritance | Transfer of classes, stats, skills, growths |
| Internal Flag | Hidden class property used mechanically |
| Cap | Maximum stat or progression limit |

---

## Mechanical Categories

| Category | Description |
|---|---|
| Deterministic | Produces fixed output |
| Probabilistic | Randomized output |
| Derived | Calculated from other values |
| Hidden | Not shown directly in UI |
| Static | Never changes |
| Dynamic | Recomputed during play |

---

# Naming Conventions

## File Naming

Canonical format:

```text
awakening_[domain].md
```

Examples:

```text
awakening_core_systems.md
awakening_classes_base.md
awakening_skills.md
```

Naming rules:

- lowercase only
- underscore separator
- singular system names where appropriate
- deterministic naming

---

## Header Structure

Markdown heading hierarchy:

```text
# Document

## Category

### Subcategory

#### Detail
```

No skipped heading levels.

---

## Class Names

Canonical in-game English names.

Examples:

- Lord
- Great Lord
- Dark Mage
- Dark Knight
- Falcon Knight

No abbreviations in canonical references.

---

## Stat Names

Canonical stat schema:

| Canonical Name | Abbreviation |
|---|---|
| Hit Points | HP |
| Strength | STR |
| Magic | MAG |
| Skill | SKL |
| Speed | SPD |
| Luck | LCK |
| Defense | DEF |
| Resistance | RES |
| Movement | MOV |

---

# Schema Conventions

## Universal Table Rules

Tables SHALL:

- use deterministic ordering
- maintain stable columns
- avoid merged semantics
- preserve numeric values

Missing values SHALL use:

```text
N/A
```

Never blank cells.

---

## Formula Representation

Formula syntax:

```text
Output =
InputA + InputB
```

Multipliers:

```text
Damage =
Attack × Multiplier
```

Conditional formulas include trigger conditions.

---

## Boolean Representation

Allowed values:

```text
True
False
Conditional
```

---

## Range Representation

Format:

```text
1
1–2
2
```

---

## Probability Representation

Represented as:

```text
Percent
Decimal
Underlying Formula
```

Example:

```text
Proc Rate =
Skill ÷ 2
```

---

## Ordering Rules

Data ordering priority:

1. Player-facing canonical order
2. Internal game order
3. Alphabetical fallback

---

# Mechanical Precision Standards

Every system MUST include:

- formulas
- hidden constants
- trigger conditions
- edge cases
- caps
- exceptions
- implementation assumptions

Every probabilistic mechanic MUST include:

- activation conditions
- proc rate
- stacking interaction
- exclusions
- AI handling

Every class MUST include:

- metadata
- WEXP state
- caps
- growths
- movement
- vulnerabilities
- skills
- promotion data
- reclass data

---

# Canonical Data Representation Rules

## Effective Damage

Represent using explicit multipliers.

Example:

```text
EffectiveDamage =
BaseDamage × Multiplier
```

Do not use descriptive shorthand.

---

## Stat Caps

Represent numerically.

No “high/low” descriptors.

---

## Inheritance

Represent as:

```text
InheritedClassPool
InheritedSkills
InheritedGrowths
InheritedStats
```

---

## Skills

Represent with:

- trigger condition
- formula
- stacking rules
- exclusions
- AI usage
- hidden behavior

---

# File Map

| Phase | File | Purpose |
|---|---|---|
| 0 | awakening_project_index.md | Corpus specification |
| 1 | awakening_core_systems.md | Core systems and formulas |
| 2 | awakening_lookup_tables.md | Canonical lookup tables |
| 3 | awakening_classes_base.md | Base class encyclopedia |
| 4 | awakening_classes_promoted.md | Promoted class encyclopedia |
| 5 | awakening_classes_special.md | Special/NPC/DLC classes |
| 6 | awakening_skills.md | Skill encyclopedia |
| 7 | awakening_weapons_physical.md | Physical weapons |
| 8 | awakening_weapons_magic.md | Magical weapons |
| 9 | awakening_items.md | Item encyclopedia |
| 10 | awakening_archetypes.md | Simulation archetypes |
| 11 | awakening_appendices.md | Supplemental references |
| Final | awakening_master_index.md | Corpus navigation |

---

# Document Dependency Graph

```text
awakening_project_index
│
├── awakening_core_systems
│   ├── awakening_lookup_tables
│   ├── awakening_classes_base
│   │   └── awakening_classes_promoted
│   │       └── awakening_classes_special
│   │
│   ├── awakening_skills
│   ├── awakening_weapons_physical
│   ├── awakening_weapons_magic
│   ├── awakening_items
│   ├── awakening_archetypes
│   └── awakening_appendices
│
└── awakening_master_index
```

Dependency rationale:

- systems precede lookup data
- lookup data precedes encyclopedic references
- class references precede inheritance systems
- skills depend on class data
- appendices depend on all prior documents
- master index depends on completed corpus

---

# Versioning Strategy

Semantic versioning model:

```text
MAJOR.MINOR.PATCH
```

Definitions:

| Component | Meaning |
|---|---|
| MAJOR | Structural schema changes |
| MINOR | New content additions |
| PATCH | Corrections/clarifications |

Examples:

```text
1.0.0
1.1.0
1.1.3
```

Phase completion checkpoints:

```text
0.1.0 = Phase 0
0.2.0 = Phase 1
0.3.0 = Phase 2
...
1.0.0 = Complete Corpus
```

---

# Canonical Abbreviations

| Abbreviation | Meaning |
|---|---|
| HP | Hit Points |
| STR | Strength |
| MAG | Magic |
| SKL | Skill |
| SPD | Speed |
| LCK | Luck |
| DEF | Defense |
| RES | Resistance |
| MOV | Movement |
| WEXP | Weapon Experience |
| AS | Attack Speed |
| AVO | Avoid |
| HIT | Hit Rate |
| CRT | Critical Rate |
| DDG | Dodge |
| DS | Dual Strike |
| DG | Dual Guard |
| IL | Internal Level |
| UL | Unit Level |
| CL | Class Level |
| EXP | Experience |
| RNG | Random Number Generation |
| DLC | Downloadable Content |
| NPC | Non-Player Character |

---

# Corpus Roadmap

## Phase 0

`awakening_project_index.md`

Project architecture and normalization rules.

---

## Phase 1

`awakening_core_systems.md`

Includes:

- stat system
- growth mechanics
- leveling system
- promotion system
- reclassing
- WEXP
- combat system
- Pair Up
- enemy generation
- child mechanics
- vulnerability/effectiveness

---

## Phase 2

`awakening_lookup_tables.md`

Includes:

- stats reference
- weapon types
- WEXP thresholds
- movement types
- terrain categories
- vulnerabilities
- effectiveness matrix
- rank progression

---

## Phase 3

`awakening_classes_base.md`

All base/tier 1 classes.

---

## Phase 4

`awakening_classes_promoted.md`

All promoted classes.

---

## Phase 5

`awakening_classes_special.md`

Includes:

- special classes
- enemy-only
- NPC
- DLC
- SpotPass
- transformation classes

---

## Phase 6

`awakening_skills.md`

Complete skill encyclopedia.

---

## Phase 7

`awakening_weapons_physical.md`

Includes:

- swords
- lances
- axes
- bows

---

## Phase 8

`awakening_weapons_magic.md`

Includes:

- tomes
- dark magic
- staves
- beaststones
- dragonstones

---

## Phase 9

`awakening_items.md`

Complete item encyclopedia.

---

## Phase 10

`awakening_archetypes.md`

Simulation-ready archetype templates.

---

## Phase 11

`awakening_appendices.md`

Includes:

- promotion graph
- reclass graph
- vulnerability matrix
- skill inheritance legality
- enemy generation examples
- DLC compatibility

---

## Final Phase

`awakening_master_index.md`

Master navigation index across entire corpus.
