---
Role: topic
---

# FE-derived numeric provenance audit — 2026-07-30

**Status:** Implemented audit; remediation remains a product decision  
**Last verified:** 2026-07-30  
**Scope:** Public project presets in `data/classes/` and `data/weapons/` on
`agent/integration` at `8dd24243ad4a34cf78cf9c3e791122effee2d86f`  
**Limitation:** This is an engineering/provenance review, not legal advice.

## Outcome

The public preset is not numerically independent today. Ten of its twelve weapon
resources reproduce complete stat lines from the repository's older *Fire Emblem
TTRPG — Weapons & Items* table, one more differs in only one price cell, and all 23
non-placeholder class resources reproduce
the older class corpus's bases, growths, caps, or promotion bonuses. The newer
Awakening reference corpus is visibly different, so these are not accidental matches
to Awakening's retail values; they are deliberate carryovers from the older combined
TTRPG reference.

This creates a provenance and product-identity concern even though individual game
numbers are functional data. The concern is strongest in the selection, grouping,
names, and full-row replication. Before these presets are distributed as an original
base pack, replace or explicitly license/attribute the inherited tables. Do not treat
renaming alone as remediation.

## Method

1. Enumerated every tracked `.tres` under `data/weapons/` and `data/classes/`.
2. Compared weapon rank, Mt, Hit, Crit, range, Wt, uses, cost, effect, and WEXP with
   `Content Expansion/Old_Deferred/items_and_weapons.md`.
3. Compared class bases, player/enemy growths, caps, movement, constitution, line of
   sight, promotion bonuses, and promotion relationships with
   `Content Expansion/Old_Deferred/revised_classes_and_skills.md`.
4. Cross-checked the same-name entries in the newer
   `New_Content_Expansion/awakening_weapons_*.md` corpus to distinguish inherited
   TTRPG values from direct Awakening values.

The audit is intentionally conservative: exact means the authored resource's complete
relevant numeric row matches the older table, not merely that one or two common values
coincide.

## Weapon findings

| Public resource | Older TTRPG table comparison | New Awakening comparison | Finding |
|---|---|---|---|
| Iron Sword | E/6/85/0/1/7/45/460 | D/5/95/0/1/40/520 | Exact older row |
| Steel Sword | D/9/75/0/1/12/35/700 | C/8/90/0/1/35/840 | Exact older row |
| Iron Lance | E/7/80/0/1/8/45/450 | D/6/85/0/1/40/560 | Exact older row |
| Javelin | E/6/75/0/1–2/11/25/500 | D/2/80/0/1–2/25/700 | Exact older row |
| Iron Axe | E/8/75/0/1/10/45/270 | D/7/75/0/1/40/600 | Older row except cost (270 vs 300) |
| Iron Bow | E/6/85/0/2/5/45/540 | D/6/85/0/2/40/560 | Exact older row |
| Fire | E/4/80/0/1–2/2/40/600 | E/2/90/0/1–2/45/540 | Exact older row |
| Elfire | D/5/70/5/1–2/4/30/900 | D/5/85/0/1–2/35/980 | Exact older row |
| Thunder | E/5/75/0/1–2/3/40/700 | E/3/80/5/1–2/45/630 | Exact older row |
| Wind | E/3/85/0/1–2/1/40/500 | E/1/100/0/1–2/45/450 | Exact older row |
| Heal | E, range 1, Wt 2, 40 uses, 700 | E, range 1, 30 uses, 600 | Exact older row |
| Fists | E/0/80/0/1/0/infinite/0 | No corresponding entry | Project-original fallback |

Tuple order is rank/Mt/Hit/Crit/range/Wt/uses/cost where applicable. Effects also
match the older table for bow and elemental effectiveness. The Iron Axe cost is the
only material deviation among the eleven inherited or near-inherited rows; a single changed cell does
not establish independent tuning.

The Gleam/Radiance and Shade/Nightfall resources authored on the separate
`agent/from-integration/light-dark-tomes` branch use original names and deliberately
tuned rows. They were not present at this audit's base SHA and are not part of the
finding above.

## Class findings

The six base classes `archer`, `cavalier`, `cleric`, `knight`, `mage`, and
`mercenary` reproduce the older corpus's full base-stat, cap, player-growth, and
enemy-growth tables. Examples include Archer's base `16/5/0/8/6/0/5/0`, caps
`60/26/20/29/25/30/25/21`, and both complete growth rows; Cavalier, Cleric, Knight,
Mage, and Mercenary show the same field-for-field pattern.

The promoted resources reproduce the older corpus's caps, growths, and promotion
bonuses. Several project aliases share whole numeric definitions, strengthening the
evidence that the tables were imported and adapted rather than independently tuned:

| Identical public definitions | Shared inherited role/table |
|---|---|
| Ranger / Bow Knight | ranged mounted promotion |
| Hero / Sentinel | Mercenary promotion |
| Sage / Bishop | magic promotion |
| Mage Knight / Dark Knight | mounted magic promotion |
| Great Knight / Vanguard | armored mounted promotion |
| War Monk / War Cleric | hybrid healer promotion |

`soldier.tres` is an explicitly empty enemy-only placeholder and has no substantive
numeric table to audit. Skills and unit personal stats were outside this pass; they
should receive the same treatment before a public original-content claim.

## Risk classification

| Area | Classification | Reason |
|---|---|---|
| Weapon numeric rows | High provenance concern | Eleven named resources retain essentially complete older rows |
| Class numeric tables | High provenance concern | Bases, two growth tables, caps, and promotion bonuses move together |
| Fists fallback | Low | No matching source entry; engine-specific function |
| New Light/Dark branch | Low based on this review | Original names and newly selected values; keep design notes |
| Mechanics/formulas | Separate review | Rules and functional formulas require design review, not row-level retuning alone |

## Recommended remediation

1. Treat the current project preset as internal compatibility/test content until its
   provenance is resolved; do not label it an original distributable base pack.
2. Create an independently tuned numeric baseline from explicit project goals
   (time-to-kill, hit-rate bands, durability/economy targets, class-role budgets),
   recording rationale and playtest evidence for each family rather than perturbing
   inherited values mechanically.
3. Replace weapon and class tables as coherent systems. Random per-cell changes can
   preserve the same recognizable selection while producing worse balance.
4. Audit personal unit stats/growths, skills, item prices/effects, and map encounter
   numbers in follow-up rows before making a repository-wide originality claim.
5. Keep the FE campaign pack clearly separated and review its intended reference use,
   attribution, and distribution terms with the project owner or qualified counsel.

No gameplay value was changed by this audit.
