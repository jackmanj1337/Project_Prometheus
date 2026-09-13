---
Role: topic
---

# Pillar 1 — Code Review

> **Status:** Active — corrected 2026-09-13
> **Last verified:** 2026-09-13
> **Part of:** `AGENT/Review Procedures/00_Master_Review_Procedure.md`
> **Correction:** Luna workers return evidence; the lead owns reports, scores, and reconciliation.

Review non-test GDScript for correctness, architecture, performance, security,
and maintainability. The master supplies the exact scope, commit SHA, baseline
results, prior-report candidates, time/tool allowance, and coverage target.

## Scope and method

Review only the assigned files or subsystem under the pinned SHA. Do not edit
files, create reports, rerun the shared baseline, or register tasks. Use the
lowest available dependency. A worker may inspect code and run narrowly scoped,
read-only probes when the dispatch allows it; return commands, exit status, and
raw evidence to the lead.

Check edge cases, failure handling and rollback/atomicity, state-machine reachability
and exit transitions, signal connection/disconnection lifetime,
typed values, duplication, layer boundaries, RNG ownership, per-frame work,
and input validation. Cite `file:line` for each claim and cite the source of
the expected behavior when calling something a defect. Mark unverified claims
as assumptions.

Project checks include typed-array call sites, exported node references, class
cache assumptions, and raw random calls in gameplay paths. Do not infer a bug
from a pattern alone: verify its runtime use and caller contract. Do not apply a
blanket “headless autoload cross-reference” rule; report only a demonstrated
failure or an untested boundary with evidence.

Setter review must follow Godot 4 semantics: directly naming a property inside
its own setter accesses the underlying member without recursively invoking that
setter. A separate backing field is optional. Indirect calls through another
function can invoke accessors again; inspect the actual call path before reporting
a recursion or state-update defect.
Reference: [Godot GDScript setters and getters](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#setters-and-getters).

## Evidence returned to the lead

Return the assigned coverage, files inspected, commands/probes run, and a
finding table with local ID, proposed severity, location, observed behavior,
expected source, reproduction/evidence, confidence (confirmed or suspected),
cross-pillar owner, existing task ID (or no match found), positive observations,
and tooling friction. The lead decides severity,
score, duplicates, and the final report path.

## Dispatch brief

> You are a `gpt-5.6-luna` read-only Code worker. Review only `<scope>` at
> `<SHA>`. The lead supplies `<baseline>`, `<prior-report candidates>`,
> `<time/tool allowance>`, and `<coverage target>`. Do not edit files, write a
> report, rerun shared baseline checks, or create tasks. Return inspected paths,
> using the master return schema; budgets never imply complete coverage. Return
> commands and exit statuses, evidence-backed findings with `file:line`,
> assumptions, positives, and friction to the lead.
