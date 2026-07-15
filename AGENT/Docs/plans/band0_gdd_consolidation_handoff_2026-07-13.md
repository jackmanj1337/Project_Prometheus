---
Type: plan
Status: Planned
Last verified: 2026-07-13
---

# Band 0 GDD Consolidation — Next-Session Handoff

## Outcome

Advance the four remaining Band 0 rows as one documentation-only stream:

- finalize `B0-DOC-ROLE-MANIFEST` and its mechanical ownership enforcement;
- validate `B0-VOCAB-NAMING`, normalize retired active terminology, and add the
  retired-vocabulary check;
- execute `B0-GDD-CONSOLIDATION` as audit -> de-duplication -> code
  reconciliation -> chapter split;
- finish `B0-GDD-ANCHORS` only after the rewritten headings are stable.

Most of this work is already authorized by the role manifest, vocabulary
manifest, DOC-001 authority order, and the 2026-07-09 owner decision to use a
prune-and-split-in-place consolidation. Do not pause for isolated ambiguities.
Record genuinely unresolved choices in one owner-decision packet and continue
all independent work.

## Branch Start — Do This First

The workspace manifest still names `v0.3.0-features` as `active_branch`, but the
accepted v0.4/Band 2 work and this handoff live on
`agent/claude/2026-07-12/v0.4-prep`. Do **not** run
`scripts/agent-start-task.sh` unchanged: it would branch from the older active
line and omit the newer state.

Start with a clean checkout at the commit containing this handoff, confirm that
it descends from `8ac007c` (`Close v0.4 review fix pass`), then create the new
branch directly:

```bash
git status --short --branch
git merge-base --is-ancestor 8ac007c HEAD
git switch -c "agent/codex/$(date -u +%F)/band0-gdd-consolidation"
```

If this handoff has first been integrated into another accepted branch, branch
from that integrated commit instead. Never rebase, reset, or discard the
existing v0.4 work to satisfy the stale workspace manifest.

This stream is documentation-only. Do not mix release metadata, playtest-return
repairs, or feature implementation into the branch.

## Read First

1. This handoff.
2. `AGENT/Docs/plans/project_control_plane_2026-06-29.md`, Band 0 rows.
3. `AGENT/Docs/plans/doc_role_manifest_2026-06-29.md`.
4. `AGENT/Docs/plans/project_vocabulary_manifest_2026-06-29.md`.
5. `AGENT/Docs/governance/documentation_review_2026-07-05.md`.
6. `AGENT/Docs/governance/documentation_system_audit_2026-06-23.md`.
7. `AGENT/Docs/governance/documentation_lifecycle_2026-06-13.md`.
8. `AGENT/Docs/governance/documentation_governance_2026-06-13.md` and
   `AGENT/Docs/decisions/decision_index.md` for DOC-001 and DoD rules.
9. `AGENT/GDD/GDD_00_Overview.md`, `GDD_10_Roadmap.md`, and
   `GDD_Feature_Index.md` before touching numbered chapters.

Do not treat session notes as active design authority. Use them only to locate
the governing register, decision, plan, code, or validation evidence.

## Authority and Decision Boundary

Resolve material in this order:

1. Ratified decision records and resolved feature registers.
2. Shipped behavior plus tests for claims about implemented behavior.
3. The Project Control Plane for work status, dependencies, and next action.
4. Numbered GDD chapters for concise domain contracts.
5. Active design sources and implementation plans for detail.
6. Session notes and archived documents as historical evidence only.

Proceed without owner input when the result follows mechanically from those
sources. This includes role classification, status-location cleanup, explicit
vocabulary replacements, exact-duplicate removal from an active contract,
unambiguous shipped-code reconciliation, link updates, generated-index updates,
and chapter splitting that preserves content and identifiers.

Stop only the affected item and add it to the decision packet when:

- two equal-authority active sources genuinely conflict and no later decision,
  code behavior, or test resolves them;
- resolving the conflict would choose new player-facing behavior or feature
  scope rather than document an existing decision;
- a proposed deletion contains unique rationale or evidence;
- a new document taxonomy, Track ID, public name, or release commitment would
  be required.

Archive or mark superseded instead of deleting. Existing governance requires
fresh owner confirmation before bulk moves or deletion; this handoff does not
grant it. The already-approved split of `GDD_01` and `GDD_07` is not a deletion,
but all content, decision/register IDs, Track IDs, and inbound links must survive.

## Correct the Tracker Order First

The control plane currently says `B0-GDD-CONSOLIDATION` depends on
`B0-GDD-ANCHORS`, while `B0-GDD-ANCHORS` says anchors are added after rewritten
headings stabilize. That order is inverted.

In the first planning commit:

1. Make consolidation depend on the role and vocabulary contracts, not final
   anchors.
2. Make `B0-GDD-ANCHORS` follow the consolidation/split pass.
3. Update both rows' next actions and link this handoff as the execution source.
4. Recheck whether `B0-DOC-ROLE-MANIFEST` is still accurately `Target design` or
   should remain so until its enforcement lands.

Do not mark any row Implemented merely because a plan or audit exists.

## Execution Plan

### Phase 0 — Read-only audit and implementation plan

Produce one active plan under `AGENT/Docs/plans/` containing:

- an inventory of `GDD_00`-`GDD_08`, `GDD_10`, and the Feature Index;
- section-level ownership under the role manifest;
- retired vocabulary occurrences, excluding Historical/Superseded material and
  genuine historical quotations;
- duplicated contracts and their authoritative owner;
- contradictions grouped as resolved mechanically vs. decision required;
- drift between implemented code/tests, the control plane, and GDD prose;
- proposed `GDD_01` and `GDD_07` split boundaries and filenames;
- an inbound-link and stable-ID migration inventory;
- a commit-sized phase schedule and validation matrix.

Phase 0 edits no GDD contract text. It may correct the tracker-order defect,
wire this handoff/plan, and add the audit artifact itself. Commit the audit
separately so it remains reviewable.

### Phase 1 — Role and vocabulary enforcement

1. Revalidate the role manifest against the live directory layout.
2. Resolve stale transition exceptions whose owning rewrite rows are already
   implemented.
3. Add the smallest practical active-document ownership check to
   `AGENT/Docs/check_docs.py` in the same commit as the ratified mechanical rule.
4. Normalize only the explicit replacements in the vocabulary manifest.
5. Add a retired-vocabulary scan that understands active vs.
   Historical/Superseded documents and avoids false positives in the manifest's
   own retired-term table and quoted historical evidence.
6. Add focused checker fixtures/tests if the current checker structure supports
   them; at minimum prove each new check fails on a controlled temporary
   violation and passes after removal.

Do not perform broad synonym polishing. The manifest's named replacements are
the boundary.

### Phase 2 — De-duplicate and reconcile

Work one GDD owner chapter at a time:

1. Keep concise design contracts in `GDD_01`-`GDD_08`.
2. Keep work status and sequencing in the control plane/`GDD_10`.
3. Keep deliberation and rationale in registers/decision records.
4. Replace duplicated detail with direct links to its authoritative owner.
5. Reconcile implemented-behavior claims against production code and focused
   tests, not against memory or session-note summaries.
6. Preserve unique rationale; move it to the correct existing role if necessary
   rather than deleting it.
7. Update the matching control-plane and Feature Index references in the same
   commit.

Keep a live `Unresolved owner decisions` section in the audit/plan. Each entry
must contain the conflicting claims, authority level, affected paths, concrete
options, impact, and a recommendation. Do not interrupt the pass to ask one
question at a time.

### Phase 3 — Split oversized chapters

Split `GDD_01_Architecture.md` and `GDD_07_UI_UX.md` along the Phase 0 boundaries.
The exact filenames may be selected mechanically when they directly describe
existing role boundaries; add a decision-packet item if two materially different
ownership models remain plausible.

For each split commit:

- use `git mv` when a whole document is renamed; use normal patch edits when one
  source becomes multiple files;
- preserve headings or provide an explicit old-anchor -> new-anchor migration
  table;
- preserve every decision/register/Track ID and all unique contract text;
- update all live inbound Markdown links and `check_docs.py` path assumptions;
- update `GDD_00`, the Feature Index, `GDD_10`, and generated indexes as needed;
- run link and documentation checks before moving to the next chapter.

Do not combine both large chapter splits into one commit.

### Phase 4 — Exact anchors and closeout

After headings and filenames are stable:

1. Add exact section anchors from `GDD_Feature_Index.md` to the owning GDD
   contracts.
2. Run a repository-wide link and Track ID reachability check.
3. Update all four Band 0 rows to their evidence-supported final statuses.
4. Update `GDD_10` Known Follow-ups so no completed Band 0 task remains queued.
5. Regenerate `AGENT/Docs/INDEX.md` and `REGISTERS.md` when applicable.
6. Write the final session note with commits, validation, remaining owner
   questions, and next work.

If owner questions remain, finish every independent item and leave the affected
row/status explicit. Do not label the whole consolidation blocked.

## Commit Boundaries

Recommended sequence:

1. Correct tracker dependencies + add the Phase 0 audit/plan.
2. Finalize document-role rules + enforcement.
3. Normalize vocabulary + retired-term enforcement.
4. Reconcile/de-duplicate one numbered GDD chapter per commit or smaller.
5. Split `GDD_01` and migrate links.
6. Split `GDD_07` and migrate links.
7. Add stable exact anchors and close Band 0 statuses.
8. Add the closeout session note/index update.

Never mix checker-policy changes, mass prose migration, and both chapter splits
in one commit. Small commits make link regressions and lost rationale bisectable.

## Validation

At the start and after every commit-sized change:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
git diff --check
```

Also run targeted repository searches for each phase:

```bash
rg -n "Phase 3 Post-Awakening|M8-M13 implementation order|campaign overlay|wander area|mini-game module seam" AGENT --glob '*.md'
rg -n "GDD_01_Architecture|GDD_07_UI_UX" AGENT --glob '*.md'
rg -o "B[0-8]-[A-Z0-9-]+|VAL-[A-Z0-9-]+|REL-[A-Z0-9-]+|CLEAN-[A-Z0-9-]+|CONTENT-[A-Z0-9-]+|POLISH-[A-Z0-9-]+|UI-[A-Z0-9-]+" AGENT/GDD AGENT/Docs | sort -u
```

Run `bash run_tests.sh` before the final handoff because documentation checks are
part of the repository suite and path-sensitive GDScript/test references may be
touched. No gameplay behavior should change on this branch.

## Exit Conditions

The autonomous pass is done when:

- Phase 0 has an evidence-backed punch list and migration plan;
- role and retired-vocabulary rules have matching automated enforcement;
- unambiguous duplication and shipped-code drift are reconciled;
- `GDD_01` and `GDD_07` are split without lost IDs, rationale, or live links;
- the Feature Index points to stable exact anchors;
- Band 0 statuses and next actions match the resulting evidence;
- all documentation checks, generated-index checks, link checks, and the full
  repository suite pass;
- unresolved choices, if any, are consolidated into one owner-decision packet.

Do not wait for decisions that do not block independent work. Do not delete
unique evidence, make new player-facing design choices, or broaden this branch
into feature implementation.
