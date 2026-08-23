---
Role: topic
Type: decision-record
Status: Applied
Last verified: 2026-07-20
Decision IDs: REN-1..5
---

# Decision Record — D-A Public-Identity Rename Gate (2026-07-20)

**⚠️ Not legal advice.** Exposure judgements below are engineering judgement, not
a legal opinion.

## Context

`public_identity_rename_open_questions_2026-06-21.md` framed REN-1..5 as a
pre-1.0 release gate, on the stated premise that *"all Fire Emblem–derived names
are placeholders (factions, classes, items, GDD prose, data strings)"*.

A grounding scan on 2026-07-20 found that premise overstates the data surface.

## The scan that reframed the gate

Searching `data/` and `AGENT/GDD/` for FE-specific terms with word boundaries:

- **`data/` is clean.** Zero matches across every `.tres`, registry, and roster
  file. No character names, no FE-coined vocabulary.
- **Class `display_name`s are generic RPG vocabulary** — Archer, Bishop,
  Cavalier, Cleric, Fighter, General, Hero, Knight, Mage, Mercenary, Paladin,
  Ranger, Sage, Sniper, Soldier, plus compounds (Great Knight, Bow Knight, Mage
  Knight, War Monk, War Cleric, Dark Knight) and three project coinages
  (Paragon, Sentinel, Vanguard). These are D&D-era and general fantasy terms used
  across many franchises. Nintendo does not own them.
- **All exposure is in GDD prose**, and it is not uniform:

| Tier | Terms | Hits | Assessment |
|---|---|---|---|
| Clear third-party IP | Chrom, Lucina, Marth, Micaiah, Sigurd, Seliph, Roy, Hector, Eliwood | 33 | Copyrighted characters. Must go. |
| FE-coined | Manakete, Falcon Knight | 52 | Terms the franchise invented. Should go. |
| Generic fantasy | pegasus, wyvern, valkyrie, troubadour, myrmidon, swordmaster | 258 | Mythology and history. Not FE's to own. |
| Naming the inspiration | "Fire Emblem" | 49 | Nominative reference — lawful, but see REN-1. |

**Consequence: this is a documentation pass, not a data pass.** The register's
plan front-loads `data/.tres` because boot-validation guards it. There is no data
work to front-load. That inverts the ordering in REN-3 and shrinks the gate
substantially.

## Decisions

| ID | Decision | Applied in |
|---|---|---|
| REN-1 | **Replace character names and FE-coined terms; also strip "Fire Emblem" references.** The 9 character names and the FE-coined vocabulary (Manakete, Falcon Knight) get owned replacements. The 49 mentions naming Fire Emblem as the inspiration are removed. Generic fantasy terms (pegasus, wyvern, valkyrie, troubadour, myrmidon, swordmaster) are **kept** — renaming words the franchise never owned is effort without legal gain, and "pegasus knight" reads clearer to players than a coinage. | This record; `REN-GDD-PASS-2026-07-20` |
| REN-2 | **Display names only; ids stay opaque.** Confirmed as the standing rule. Largely moot today since `data/` needs no rename, but it governs any future pass: ids are referential keys across maps, registries, `promotes_to`, `reclass_options`, and the save format, and renaming them is a graph-wide rewrite for zero public benefit. | This record |
| REN-3 | **Ordering inverted: GDD prose IS the pass.** Data-first ordering is moot. The pass is GDD prose, then a check on `map_registry.json` labels and roster references for completeness. | This record |
| REN-4 | **Banned-string check in `check_docs.py`.** The banned list lands as a new check, failing pre-commit and CI if any term reappears. Per DoD#2, and a green check is the gate's completion signal. | `REN-BANNED-STRING-CHECK-2026-07-20` |
| REN-5 | **No save/back-compat concern.** Ids are unchanged, so saves keyed on ids load fine; only displayed strings differ — and none of those change either. Save-transparent. | This record |

## Consequences

### Stripping "Fire Emblem" is a presentation decision, not a legal one

Naming your inspiration in design documentation is nominative reference and is
lawful. The reason to remove it is that a public design-doc tree citing a
Nintendo franchise 49 times invites scrutiny and reads as derivative even where
the work is not — the mechanics are the owner's own (see
`decision_record_2026-07-20_leg_licensing_gate.md`, LEG-1).

Worth weighing during the pass: **zero mentions may read as evasive** where one
honest line does not. A single acknowledgement of genre lineage — "inspired by
classic turn-based tactical RPGs" — is defensible, accurate, and less
conspicuous than either 49 mentions or a suspiciously scrubbed document. The
decision as taken is to strip; if the pass finds a passage where removal makes
the design rationale incomprehensible, prefer rewriting to a generic descriptor
over deleting the reasoning.

### The banned-string check must not apply to `Campaign_Pack_FE`

`Campaign_Pack_FE` is the designated home for FE-derivative material and is
internal-only (`NOTICE.md`, `PACKFE-LICENSING-2026-07-19`). Its README says
"fire emblem" deliberately. A banned-string check that swept that repo would fail
permanently on content that is correct where it sits. Scope the check to
`Project_Prometheus` — and, when Pack_0 gains content, to Pack_0.

### The gate is cheaper than the register assumed

Because `data/` is clean and ids are out of scope, there is no referential-graph
risk, no save migration, and no boot-validation exposure. What remains is a prose
edit plus a guard. This should not be treated as a high-blast-radius pass.

### Ordering relative to licensing is unchanged

LEG-5 keeps DOC-012 after this gate. That still holds: the licensing review
should not be reviewing FE-named content. Neither blocks internal or playtest
builds.

## Follow-ups

| Task | What |
|---|---|
| `REN-GDD-PASS-2026-07-20` | The prose pass: replace 9 character names and FE-coined terms, strip "Fire Emblem" references, keep generic fantasy vocabulary. Build the placeholder→owned mapping table first. |
| `REN-BANNED-STRING-CHECK-2026-07-20` | `check_docs.py` check enforcing the banned list. Scoped to this repo, never `Campaign_Pack_FE`. |
