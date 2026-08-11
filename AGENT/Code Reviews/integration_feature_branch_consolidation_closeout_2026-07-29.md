# Integration Feature-Branch Consolidation Closeout

**Status:** Accepted
**Reviewed:** 2026-07-29
**Integration baseline:** accepted v0.5.8 plus the released-line reconcile
**Consolidated integration:** `f1d6f87ad317b0e7feafb2b04dd253bead535c5a`

## Outcome

Every feature-bearing branch that forked from the old integration line has been
content-reviewed against accepted v0.5.8. Current `agent/integration` contains the
accepted behavior, research, decisions, plans, and repaired prototypes. No old
source branch remains an implementation dependency or an outstanding feature base.

Commit ancestry is intentionally not the acceptance test: most source commits were
selectively reapplied or their files were semantically unioned, so their old tips are
not ancestors even though their accepted content is present.

## Source-branch dispositions

| Source branch | Disposition on current integration |
|---|---|
| `web-distribution-freeze` | Absorbed in Wave 1; current GDD retains the freeze plus newer v0.5.8 platform state. |
| `text-entry-governance` | Absorbed and adapted in Wave 1; TEXT-06 is enforced with an empty current allow-list and its research sources landed in Wave 2. |
| `fe-schema-trial-handoff` | Already content-equivalent before intake; historical handoff retained with a UTC name. |
| `predicate-combat-operations-plan` | Absorbed in Wave 1 and unioned into the newer predicate/control-plane row. |
| `dialogue-recruit-capture-research` | Accepted plans, portfolio, registers, and connected amendments absorbed in Wave 1 without old release-gate text. |
| `campaign-data-research` | Curated by file in Wave 2. Eleven final research/decision sources and five register links landed; every omitted path is classified in `integration_consolidation_wave2_intake_review_2026-07-29.md`. |
| `update-fe-contract-plans` | Superseded duplicate of the campaign-data line ending before its final closeout; it contributes no additional accepted content. |
| `bbcode-injection-hardening` | Reapplied and extended in Wave 3A. All current rich-text sinks and the archive resource-format boundary are covered; 110-suite gate green at intake. |
| `entity-schema-prototype` | Reapplied and repaired in Wave 3B. Missing, empty, unknown, and nested-object types fail closed with entity-qualified errors; 111-suite gate green. |
| `class-schema-trial-v1` | Recovered in Wave 3C. Five valid pressure packs and all eight negative-contract errors execute in the required test gate; presentation collisions are explicit advisory warnings. |

The consolidation work branches themselves are ancestors of integration and need no
content classification. Policy/reconcile/readiness branches show zero unique commits
and zero unique files against current integration.

## Repeated-risk closures

- Clean clones cannot reuse a stale Godot class/import cache silently.
- Evidence trees are outside Godot import discovery and do not regenerate sidecars.
- New session-note names require an exact UTC second and descriptive slug.
- Imported rich text is escaped at render boundaries while executable Godot resource
  formats remain rejected independently.
- Declarative schema types fail closed; negative fixtures are executed, not counted.
- Broad research branches are curated by authoritative final files and explicit
  omission inventories rather than bulk merged.

## Remaining work after consolidation

There are no outstanding feature branches from this consolidation set. The plans and
tracker rows recovered here describe future implementation work (for example the
zero-content vertical, dialogue/custody slices, predicate combat operations, and
campaign-library UX); they are new tasks based on current integration, not unfinished
merges from the old branches.
