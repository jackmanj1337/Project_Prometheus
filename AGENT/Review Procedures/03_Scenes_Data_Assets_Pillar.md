---
Role: topic
---

# Pillar 3 — Scenes, Data & Assets Review

> **Status:** Active — corrected 2026-09-13
> **Last verified:** 2026-09-13
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`
> **Correction:** workers inspect bounded content and return evidence; the lead owns reports and follow-up.

Review the assigned scene, resource, data, import, UID, and autoload-registration
scope at the pinned SHA. The master supplies scope, baseline, prior-report
candidates, time/tool allowance, and coverage target. Do not edit, reimport,
write reports, or register tasks. Use analyzer tools when available and record
their version/commands and failures; use direct structural inspection as the
fallback.

Check scene scripts and node paths, external resources, exported references,
resource fields and cross-references, IDs and required values, `.gd.uid`
sidecars, imports, and autoload registration/order. Account for `.gdignore`,
generated imports, ignored build outputs, and intentionally untracked/generated
content before calling something orphaned. `.tres` and `.tscn` UIDs are
inline; the sidecar check applies to scripts. Do not assume every resource
family is loaded at once: validate the one loaded campaign-pack ID named by
the dispatch, and distinguish dynamic manifest references from dead paths.

For authored-content evidence, inspect the real pack manifest and its
`select_campaign()` path when assigned. A fixture or parser-only pass does
not prove a pack is playable. Native Windows or other visual acceptance is
evidence only when supplied by the lead; headless results do not establish it.

## Evidence returned to the lead

Return coverage (including pack ID), tools/probes and statuses, findings with
local ID, proposed severity, scene/resource path plus node/field and expected
source, contradictory source or reproduction, confidence (confirmed or
suspected), cross-pillar owner and existing task ID (or no match found),
positives, and friction. The lead assigns severity and score, deduplicates cross-pillar
items, and writes the report.

## Dispatch brief

> You are a `gpt-5.6-luna` read-only Scenes/Data/Assets worker. Review only
> `<scope>` at `<SHA>`, including loaded pack ID `<pack-id>` if applicable.
> The lead supplies `<baseline>`, `<prior-report candidates>`, `<time/tool
> allowance>`, and `<coverage target>`. Do not edit/reimport, write reports, or
> create tasks. Use the master return schema exactly; budgets never imply complete coverage.
> Return inspected paths, tool commands/status, evidence-backed
> findings, assumptions, positives, and friction. Separate headless evidence
> from native visual acceptance.
