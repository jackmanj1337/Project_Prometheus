---
Role: dated
---

# Meta-Review — The Review Procedure Itself (2026-06-14)

> A review *of the reviewer*: how `AGENT/Review Procedures/` performed during its
> first real run (the 2026-06-14 full audit, rollup
> `AGENT/Code Reviews/full_review_rollup_2026-06-14.md`). Written by the
> orchestrator from direct observation plus the "Procedure friction" section each
> of the five pillar agents was asked to return. This is the dog-fooding pass the
> user requested: exercise the procedure and document where it bent.

## 1. Verdict

**Procedure score: 8/10 — effective, with fixable friction.** It did the one thing
a review procedure exists to do: it **found real problems a lighter process would
miss.** Specifically, the multi-pillar design surfaced a shipped correctness bug
(CR-2 fort-heal) via Doc↔Code *contradiction* that the Code pillar — scoring itself
9/10 on internal consistency — did not catch on its own. It also **corroborated the
top operational risk across three independent pillars** (CR-1 untracked `.uid`),
which is exactly the redundancy a fan-out design is supposed to buy. The parallel
execution worked: five agents ran concurrently (~4–7 min each) and merged cleanly
into one scorecard. The deductions below are all process-mechanics, not a failure
of the core method.

**Strongest evidence it works:** the gap-hunt that *preceded* this run. The
procedure as first authored claimed "skips nothing" yet missed four areas
(`tools/` Python, non-`data/` `.tres`, `.uid` sidecars, the empty `code/` dir). The
holes were caught — but by an ad-hoc question, not by the procedure. That is the
central meta-finding (MR-1).

## 2. Findings

Severity = impact on the *quality/reliability of future audits*.

**MR-1 [High] — Coverage completeness was asserted, not enforced.** The "every
top-level dir maps to a pillar" guarantee did not exist until a manual gap-hunt
added it. Nothing in the procedure forces an auditor to prove the scope is total.
**Fix:** add a mandatory **tree-completeness preflight** to master §3 — enumerate
`ls -d */` + root config files, assert each maps to exactly one pillar, and *fail
the audit* if anything is unowned. (The coverage map now states the mapping; this
makes verifying it a required step, and is a PL#9 check candidate.) *Status: map
updated this session; preflight step still to add.*

**MR-2 [Medium] — Delta-baseline discovery is unreliable.** Two pillars got the
"first run / no prior report" question wrong: the orchestrator's own glob missed
`documentation_review_2026-06-13.md` and the Pillar 2 brief asserted "first dated
review" — false. **Fix:** make "auto-discover the latest matching report by
filename pattern" an explicit *procedure step* the pillar performs, and stop
asserting first-run/last-report state in the dispatch brief. The brief should hand
over a *pattern*, not a *conclusion*.

**MR-3 [Medium] — Same-day report-name collision, handled ad hoc.** Pillar 1's
spec'd output `code_review_YYYY-MM-DD.md` collided with an existing same-day review;
the orchestrator invented a `-14b` suffix on the fly. **Fix:** master must define a
deterministic same-day disambiguator (the existing `b`/`c` suffix convention, or a
`_NN` run tag), so reruns don't clobber or require improvisation.

**MR-4 [Medium] — Tooling assumptions baked into the prose.** Pillar 4's §E
over-indexed on "pytest absent" when the analyzer suite is stdlib `unittest`
runnable under plain `python3`; the real finding was *red + ungated*, not the
missing dependency. **Fix:** baseline §3 should *probe* tool availability up front
and pass results to pillars; §E should prefer the lowest-dependency runner and not
frame absence-of-pytest as the headline.

**MR-5 [Medium] — No per-pillar 1–10 rubric; master §6 is thin.** Pillar 4 reported
the pillar docs define no explicit scoring bands and fell back to master §6's
generic ones. The pillars *should* share one rubric (single source of truth), but
§6 needs to be explicit enough to apply unaided. **Fix:** flesh out master §6 bands
and have each pillar doc point to it by reference.

**MR-6 [Low] — Reports aren't machine-readable for trend tracking.** Pillar 5's
score-trend grep hit a `150 / 10` audio snippet (false positive) and noted score
extraction is fragile. **Fix:** require an anchored header line — e.g.
`**Pillar score:** N/10` — in every report, and add the matching `check_docs.py`
rule (already a master §10 candidate; promote it).

**MR-7 [Low] — Hardcoded corpus sizes rot.** Pillar 5's doc/brief said "~140
session notes"; the real count is 91. **Fix:** never bake counts into procedure
prose; say "all session notes (sample stated in the report)."

**MR-8 [Low] — Piped commands mask exit codes.** Pillar 4 found that piping a test
run to `tail`/`head` returned exit 0 and hid a real failure; it had to re-run
unpiped. **Fix:** add a one-line procedure note — capture exit codes *before*
piping output (`cmd; echo $?` or `set -o pipefail`).

**MR-9 [Low] — Pillar-specific scope edge cases the docs don't address:**
- *`.uid` mechanism* (P3 §F): Godot 4.4 embeds `uid=` inline in `.tres` (no
  sidecar) but `.gd` uses `.uid` sidecars — the check is right but the doc should
  name both mechanisms so it isn't misapplied.
- *Empty-dir scope* (P3 §G): git can't track empty dirs, so `code/` can't be
  "commit-deleted" — clarify untracked-empty dirs are in-scope as local cleanup +
  a doc-reference check, not a git change.
- *DOC-002 "every section"* (P2): the rubric gives no guidance on *defensible*
  deviations (the GDD_06/07/08 catalog layout). Decide whether a defensible
  deviation is a finding or an accepted variant (a governance question Pillar 2
  surfaced correctly).
- *CROSS delta references* (P1): a pillar's delta section necessarily references
  other pillars' files (e.g. `.tscn`); the `[CROSS]` tag handled it, but the doc
  should acknowledge delta sections may touch out-of-scope files.

**MR-10 [Low] — Analyzer/MCP capability gaps slow Pillar 3.** Not a procedure
defect but a tooling one the run exposed: `get_resource_fields` truncates
array-valued fields; there is no orphan / cross-ref / ID-uniqueness primitive
(Pillar 3 hand-rolled them in `find`/`grep`); spaced filenames produce
false-positive orphan-import noise. Feed to the tooling backlog (master §10).

## 3. What worked (keep)

- **Fan-out caught what depth missed.** The cross-pillar contradiction (CR-2) and
  triple-corroboration (CR-1) are direct dividends of the five-lens design.
- **The shared baseline (master §3) paid off** — one pinned SHA + one green
  baseline meant all five reports agree on ground truth; no pillar argued with
  another about whether tests passed.
- **The dispatch-brief blocks at the end of each pillar doc** made spawning five
  agents mechanical and consistent.
- **The friction-reporting ask** (added to each dispatch) is what made *this*
  document evidence-based rather than speculative — bake it into the procedure
  permanently (master §4: every pillar returns procedure-friction notes).

## 4. Recommended procedure edits (the fix pass)

In priority order; all are edits to `AGENT/Review Procedures/`:

1. **Master §3:** add the tree-completeness preflight (MR-1) + PL#9 check.
2. **Master §3/§4:** probe tool availability in the baseline (MR-4); make
   friction-reporting a permanent required return (MR-3 keep).
3. **All pillar docs:** replace dispatch-brief *assertions* about prior reports
   with a "discover latest matching report" step (MR-2).
4. **Master §7 + naming:** define the same-day report disambiguator (MR-3).
5. **Master §6:** flesh out the shared 1–10 bands (MR-5).
6. **Master §10 → promote to checks:** anchored score header (MR-6), `.uid`
   tracking (CR-1), version↔tag (rollup #5).
7. **Pillar docs:** the §F/§G/DOC-002/CROSS clarifications (MR-9), and the
   "capture exit codes before piping" note (MR-8).

These are documentation edits to the procedure and can land in one follow-up
commit; none require re-running the audit.
