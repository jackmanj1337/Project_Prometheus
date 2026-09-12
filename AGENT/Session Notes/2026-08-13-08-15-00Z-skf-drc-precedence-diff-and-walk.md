# Session Note - 2026-08-13 (SKF/DRC precedence diff and owner walk)

## Branch context

- Branch: `agent/integration` (docs line — packets are written here per the standing rule)
- Base branch: `agent/integration`
- Base SHA: `5f2db41d4503193aee346eb19a942f296c1b46b0`
- Coordination Work IDs: `DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23`,
  `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23`

## What was done

The two packets scheduled next — `SKF-1..12` and `DRC-1..33` — owed the mandatory precedence
check that became a standing rule after the `TSV` walk. Ran it, then the owner walked the
findings.

**The diff** is `AGENT/Docs/design/skf_drc_precedence_diff_2026-08-13.md`. Across the two
packets it found nine questions already answered, six arguing against ratified text, five
claiming an inheritance that does not exist, and three constraints ratified after `SKF` was
written. Three findings mattered more than the per-question dispositions:

1. **`SKF-2`/`SKF-6` inherit an attribution ruling that was never made.** They cite
   `[CFB-10]`/`[CFB-11]`; `CFB-10` is the resolution pipeline and `CFB-11` is callout scope.
   Attribution lives in an *unnumbered* `CFB` research-doc section, with the redirect requirement
   belonging to `[CVR-4]` — designed but unbuilt, zero rendered paths. So those two are the
   **first** place attribution gets decided, not specializations.
2. **`DRC` predates `DLUX-1..16` by thirteen days and only `DRC-15` was reconciled.** `DLUX`
   answers eight `DRC` questions and contradicts two, while `DLG`/`RCV`/`RCR` all carry banners
   pointing *at* `DRC` — propagation ran one way only.
3. **`UBS-4` had no written question anywhere**, despite the agenda assigning it to this session
   as the one cross-cutting question with no other owner.

**The walk** ruled twelve items. `SKF`: author-set category defaults (narrowly amending `CFB-5`,
whose per-skill ban stands); settings scoped per campaign; activation order with priority
tie-break; `DLUX-10`'s warning model adopted verbatim for missing metadata; dwell budget as floor
plus bounded scaling; direction handled by decomposing each channel. `DRC`: the tactical map ruled
a fifth `EPUX-02` surface; `DRC-13` folded into `DRC-30`'s interaction-policy registry; profiles
amended to `DLUX-3` with `prison_visit` dropped; `UBS-4` ruled for Compact.

**Two outcomes exceeded their questions.**

*Confirmation authority*, settled program-wide as **split by origin** — authored predicates are a
floor no player setting can lower, `CAU-4`'s presets govern the engine-derived tag set. This
resolved a conflict existing independently of both packets: `CAU-4`'s `Minimal` preset let a
player strip an authored confirmation, which `EPUX-06` forbids as raise-only and `[TSV-21]`
re-affirmed five days *after* `CAU-4` was ruled.

*Transaction ownership*, settled as **two named primitives**. Chasing `DRC-33`'s inverted
dependency surfaced **four** ratified staging/rollback mechanisms — `MapLedger`, `EPUX-24`'s
transaction core, `EPUX-06`'s activity snapshot, and the action journal — differing only in
*policy* (retention, charging, who may trigger) while sharing every *hard* part (overlay reads,
commit ordering, RNG determinism, save participation). Ruled into a **staged transaction** and a
**snapshot**, with policy layered on top. Reopens none of the four, and defines the nesting `DRC`
never addressed: a conversation *stages* inside an activity that is *snapshot*.

That second outcome produced **`DOC-014` — "Ratified is not frozen"**, on owner instruction.
Written to *strengthen* the precedence rule rather than dissolve it: re-litigating from ignorance
stays prohibited, reopening from discovery is encouraged, and the discriminator is whether the
precedence check ran first. It binds all eleven settled-descriptors in live use
(`RESOLVED` 1756, `Ratified` 406, `Accepted` 292, `CLOSED` 270, `firmed` 171, `locked` 163,
`confirmed` 152, `decided` 143, `settled` 136, `Approved` 95, `Adopted` 42) plus `Target design`,
so no register escapes by having picked a different label.

## Commits

Ownership is in `CLAIMS.tsv`. In order: the precedence diff itself; the
`symmetric`→`bidirectional` rename `DRC` ordered in July and nobody applied (six sites, including
inside `DRC`'s own option text), enforced per DoD#2 by three vocabulary-manifest rows driving
check [31]; the `SKF` rulings plus four corrected `Inherited:` lines; `DOC-014`; and the `DRC`
rulings plus two housekeeping fixes.

The vocabulary ban is on the **compounds**, not the bare word — `symmetric` is used correctly and
unrelatedly across these docs (EXP, fog, handicap, style slots), so a blanket ban would be
false-positive noise. Accepted residual gap: the spaced-pipe form cannot be a manifest row,
because a pipe terminates the table cell.

Housekeeping: `gen_docs_index.py` dropped the `Register:` header for any doc not typed
`register`, defeating `_registers_md`'s own `or d.register` selector and leaving `DLUX-1..16` —
sixteen ratified decisions — out of `REGISTERS.md` entirely. That is a direct contributor to this
diff being owed at all. Fixed so an **explicit** header is catalogued whatever the type, with the
body heuristic still scoped to register docs. And
`dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md` read `Accepted` while its
`Decision source` register was `OPEN` and cited `DLUX` zero times despite a 2026-08-09 re-verify —
the day `DLUX` landed. Marked **Needs revision** with its known divergences listed.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, all 43 checks, after every commit.
- Vocabulary guard **verified by planting a term**, not by trusting a green run: check [31]
  rejected `directed/symmetric`, tree restored, re-checked green. It then caught the diff document
  itself naming the banned compounds — the sanctioned-quotation path working.
- `gen_docs_index.py` fix verified by diffing `REGISTERS.md`: the first attempt catalogued **92**
  docs that merely *mention* a range (including this diff); the corrected version adds exactly
  **one** row.
- `run_tests.sh` via `agent-push.sh` — all suites green.
- `coordination/check_tasks.py` — OK, 415 tasks valid, no conflicts.
- Two rows registered: `SETTINGS-PERSISTENCE-SCOPE-REVIEW-2026-08-13` and
  `OPTIMIZATION-PASS-RATIFIED-DECISIONS-2026-08-13`.

**Two tooling hazards hit.** `agent-add-task.sh` reported success while printing the *previous*
row's id — the row was never created; caught by reading the tracker rather than the exit line.
And the commit prepare step segfaulted (exit 139) on a stale Godot import cache;
`godot-import-cache.sh` fixed it, but that rebuild generates `.import` sidecars under
`AGENT/Docs/` which dirty the tree. Zero such files are tracked (126 are, all real game assets),
and `.gitignore` already ignores Godot sidecars for documentation evidence — **an ignore rule for
`AGENT/Docs/**/*.import` would stop this recurring**, left for the owner since `.gitignore`
routing is an infrastructure call.

## Next

Both packets are ready for their actual walks, which is what the diff was for. `SKF` has eight
questions left (`SKF-2`, `4`, `6`, `7`, `9`, `10`, plus the residue of `8`, `11`, `12`) — start
with `SKF-2`/`SKF-6`, now reweighted as primary attribution decisions. `DRC-1..18` has five left
after the drops and narrows. Then: `UBS-4`'s non-Compact size classes and the direction metadata
`[DLUX-16]`'s portrait stage never declared; the `CAU-4` tag additions for recruitment, custody
and execution; and `DRC-19..33` when scoped.
