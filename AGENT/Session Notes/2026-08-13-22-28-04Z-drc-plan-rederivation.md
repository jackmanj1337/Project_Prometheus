# Session Note - 2026-08-13-22-28-04Z

## Branch context

- Branch: `agent/integration` (plan docs are refused on a feature branch by the docs-guard)
- Base branch: `agent/integration`
- Base SHA: `40fed4a3` (tip when the session opened)
- Coordination Work ID: `DRC-PLAN-REDERIVATION-2026-08-13`

## What was done

**The dialogue/recruit/capture integrated implementation plan is re-derived and its `Needs revision`
marker is cleared.** `Status:` now reads *Active — re-derived 2026-08-13 against the RESOLVED
DRC-1..33 register and DLUX-1..16*. This ungates the thirteen build rows (`DRC-V1-S00..S11` and
`EPIC-DIALOGUE-CUSTODY-V1`) that derive from it by name and slice number.

This was **not** a research walk. Every question the plan derives from was already ruled across the
four `DRC` sittings, so the task was agreement, not decision, and
[`plans/drc_plan_rederivation_handoff_2026-08-13.md`](../Docs/plans/drc_plan_rederivation_handoff_2026-08-13.md)
carried the divergence list section by section. **The handoff's headline held**: the plan was in
materially better shape than its own tracker row implied — §3.1 already listed exactly `DRC-19`'s
five dimensions and already named one `UnitTransitionService` as the only writer, §3.1 already
forbade derived booleans (the ruling `[RCR-2]`'s flag lost to, where the plan was right and the
register wrong), §3.3 already put `ActionJournal` above `ActionPrimitiveRunner`, and §3.2's
requirements already returned a localized unmet-reason descriptor. The work was surgical
reconciliation, not a rewrite.

**Sections changed:** the header block; §2 (three retired assumptions named — `[RCV-4]`'s
`recruit(unit)`, `[RCR-2]`'s flag, `[RCR-3]`'s inversion); §3.1 (sparse patch, five-dimensions-only
scope, `target_activation`, single-writer service, `custody_status` authoritative with carry
derived); §3.2 (fifth `EPUX-02` surface, `[RPD-15]` focus inheritance, split-by-origin confirmation,
`[REQ-13(b)]` re-point); §3.3, rewritten (two named primitives, the stage-inside-snapshot nesting,
the `EPUX-06` invariant consequence, the `TSV` word collision); §3.5 (per-swap commit, `EPUX-24` and
`EPUX-21` by name, descriptor permission predicate); §3.6 (flat entries, tool IDs plus alias,
`DLUX-3` profiles with `prison_visit` dropped, `UBS-4` placement, `DLUX-16` stage direction,
`DRC-9` as structural); §3.7 (registered capture methods, capture as a field group on the existing
`DRC-13` entry, `incapacitated_and_carryable`, opportunity-attached transition); §4 (transition
record referencing the item ledger, pending-items tray); §5 (slices 0, 2, 5, 6, 9, 10); §6 (four
blocking checks, alias uniqueness, `refresh` warning); §7.

**The structural divergence most likely to have been built wrong** was §3.1's *"requested
before/after fields"* where `DRC-20` ruled a **sparse patch** with unset meaning unchanged. The
written field list covered three of the five dimensions, so a transition could not have moved a
recruited enemy out of the enemy turn group. That, `target_activation`, and the narrowing to five
dimensions are now explicit in both §3.1 and the Slice 2 row.

**The four propagation debts were paid, not deferred into Slice 0.** `[RCR-2]` carries a retirement
banner, `[RCR-3]` an ownership amendment, `[RCR-4]` the `[REQ]` banner it has owed since June (the
load-bearing one — `REQ`'s display path supplies the reason string `[DRC-11]`'s fifth-surface ruling
and `[RPD-10]`'s deploy eligibility both depend on), `[RCR-7]`/`[RCV-6]` an undersized-reservation
warning, `[RCV-4]` the `recruit(unit)` amendment, and `[REQ-13(b)]`'s `is_captured` now reads
`custody_status`. One-directional propagation is what made the `DRC` walks necessary in the first
place; the register's debt list is marked paid so it is not re-worked.

Nothing was reopened. The eleven questions disposed of by precedence without being asked are named
in the plan's header so a slice author does not reintroduce them.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`, claimed as we went.

- `6da19db4` re-derives the plan (363 insertions, 84 deletions across one file).
- `23611b71` pays the four propagation debts across `RCR`, `RCV`, `REQ` and the `DRC` register.

Tracker updates went to the docs line (`agent/staging-area`) through
`scripts/agent-update-task.sh --append-reference`: the epic ungated, Slices 0/2/5/6/9 annotated with
what changed for each, and `DRC-PLAN-REDERIVATION-2026-08-13` closed.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks, run after each edit set.
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated with each change (no index delta resulted;
  no doc was added, moved or retitled).
- `python3 scripts/ci/check_session_commit_claims.py --fix` — claimed after each commit; 763
  post-bootstrap commits audited, PASS.
- Pre-commit hooks green throughout (GDScript style 320 files, evidence matrices, docs-only paths
  skipping the Godot suite as expected). The full suite ran once on the first commit attempt: all
  suites green.
- `python3 coordination/check_tasks.py` — **OK**, 416 tasks valid, no conflicts.
- **One guard earned its keep:** the docs-guard refused the plan commit on
  `agent/from-integration/drc-plan-rederivation` — plans live on the docs line so they cannot strand
  on an unmerged branch. The feature branch was deleted and the work committed to `agent/integration`
  directly. The tracker row's `branch` field was updated to match.

## Second half — the sequencing pass

After the re-derivation landed, the owner asked for a sequencing pass over every open register,
research/design packet and planned discussion topic, with review breaks for cohesion and for
re-assessing questions built on assumptions that have since moved. That is
[`research_and_discussion_sequencing_2026-08-13.md`](../Docs/plans/research_and_discussion_sequencing_2026-08-13.md)
(`5115c429`), row `RESEARCH-SEQUENCING-2026-08-13-2026-08-13`, registered on the control plane.

**Its headline reordered the schedule before it was written.** The unbuilt-screen agenda that governs
the queue is substantially overtaken and the overtaking is invisible from inside it: five of nine
`UBS` items are design-complete, three of them discharged the day *after* the agenda was authored —
`UBS-1` by `CFB`/`SKF`/`CAU`, `UBS-2` by `TSV`/`SHC`/`CUR`, `UBS-4` and `UBS-5` by the `DRC`/`DLUX`
walks, `UBS-9`'s design half by `CRD`. Only `UBS-3` (`NMTE`) survives as a live cross-cutting
dependency. The same drift is suspected across roughly half the twenty unscheduled discussion rows.

So the schedule opens with a **disposition sweep rather than a walk** — `S1` classifies every
unscheduled row as closed by precedence, narrowed to residue, or genuinely live, and writes the
disposition into the row so the finding cannot be lost a second time. Ordering sessions that are
already answered would spend the whole schedule re-deriving ratified text, which is what `RPD-18`
did when it reproduced `PHB-7` from scratch without knowing `PHB-7` existed.

## Next

**`S1` — the disposition sweep — is the agreed next session** (owner, 2026-08-13). It touches no
code, so it runs parallel to any build line, and every session after it gets shorter.

**The thirteen build rows are also open** and no longer gated. `DRC-V1-S00` (reconciliation and
no-code fixtures) is the entry point; its remaining scope is the wider
`DLG/DSP/VIL/STY/PHB/CNV/DTH/F1` sweep, since the `RCR`/`RCV`/`REQ` banners are already paid. Note
that the merged `DRC-V1` + `PREP-V1` build order is scheduled at break `R1`, not before it — the two
epics share four primitives.

**One real cross-plan dependency, recorded in the epic row and §7's gates:** the plan now consumes
`[EPUX-24]`'s transaction core, `[EPUX-21]`'s quantity primitive, `[EPUX-11]`'s pending-items tray
and `[EPUX-06]`'s activity snapshot **by name**, and all four are owned by the prep/economy line. So
slice sequencing spans both plans — this is a dependency, not a cross-reference, and picking up
Slice 5 or Slice 9 before those primitives exist would mean building them twice.

**Still open from the `RPD` walk, unchanged by this session:**

1. `NMTE-1..20` is the last unwalked packet of the written set and still gates `CEUI`'s search rows.
2. Seven `UBS` packets need authoring before their sessions can run.
3. `B4-PREP-MAP-DEPLOYMENT-2026-07-22` cites a decision source that predates `RPD-1..18` — the same
   plan-derives-from-a-moved-source shape this session existed to fix, caught early.
4. The `RPD` register's `[RPD-4]`/`[RPD-5]` question text still carries the invented FHD boundary.
