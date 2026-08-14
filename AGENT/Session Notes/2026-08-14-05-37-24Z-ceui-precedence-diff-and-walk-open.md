# Session Note - 2026-08-14 (CEUI precedence diff, and the first three walk rulings)

## Branch context

- Branch: `agent/integration` (docs line; precedence diffs and register rulings land here directly)
- Base branch: `agent/integration`
- Base SHA: `c5fb12745ed078252da74b118f21edbba2e5ce63`
- Coordination Work ID: `S9-CEUI-PRECEDENCE-DIFF-2026-08-14-2026-08-14`, then
  `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`

## What was done

**`S9` — the `CEUI` precedence diff, sixth `DOC-014` check in the series and the largest.**
Forty questions plus the twelve `NMTE` residues `[NMTE-S4]` folded into this walk, checked against
one corpus at once: `CSA-1..37`, Campaign Library Branch K / `CL-ADV-01..03`, `ICO`, `EXT`,
`EPUX-02/03/04/06/11/15/21/24/28`, `PHB-5/7`, the two-primitive ruling, `UUI-1..19`, `TSV-1..24`,
`L10N-1..18`, `CRD-1..10`, `RPD-15`, `DLUX-10..16`, `DRC-2/4/9/11/17`, `TEXT-01..15`, `LEG-4`, and
the built code.

**The packet cites two ratified ids in forty questions** (`CSA-11/17`, `CSA-30/31`); its research
cites three. Not as bare as `RPD`, which cited nothing, but the **widest** miss in the series,
because the editor is the one surface downstream of assets, licensing, validation, localization,
transactions, persistence *and* distribution simultaneously. Disposition: **4 closed by
precedence** (`CEUI-2`'s option set, `CEUI-6`, `CEUI-32`, `CEUI-39`'s choice), **21 narrowed**,
**6 live conflicts**, **12 live as written**, **4 `NMTE` collapsed**, 1 deferred to `S12`, plus
**6 promoted questions** the packet never asks.

**The six conflicts.** (1) The editor floor was specified three incompatible ways — Branch K's
dismissible `1920×1080` warning, `[CEUI-5]`'s hard `1920×880` state, `[NMTE-S2]`'s recommendation.
(2) The editor **ships to web** (Branch K, cost accepted) where `user://` is volatile browser
storage (`CSA-36`), and nine questions assume a desktop filesystem and a second application.
(3) An editor Undo stack is a **third persistence primitive** beside the two ruled 2026-08-13 —
`RPD-17` and `DRC-33` were both rejected for that shape, and nothing in `scripts/` implements undo
today. (4) `CEUI-15` cites "the shared transaction vocabulary" when two ratified vocabularies
answer to that name. (5) `CEUI-31` contradicts `[DLUX-13]` (authoring-time expansion, no live
link). (6) `CEUI-22` contradicts `[DLUX-11]` (hand-edited JSON is a first-class validator input) —
and is compounded by the web target, where there is nothing to "open externally" in.

**The promoted question that turned out to gate the walk:** does Menu Scale apply to the editor?
`[UUI-8]` multiplies the density tokens without changing the size class, so if it reached the
editor, `2.0×` on `1920×880` is an effective `960×440`, `[CEUI-5]`'s floor never fires because it
is measured in physical pixels, and `CEUI-1`'s four regions sit in exactly the case `[EPUX-03]`
cited when it ruled *"never three panes: a third collapses at 200% Menu Scale"*.

**`S10` opened, three rulings taken in the diff's §7 order.**

- **`[CEUI-S1]` the editor owns its own scale, font size and density settings** — the player's
  Menu Scale does not reach it, because the editor is heavy text entry, dense dropdowns and a
  hosted game session. Recorded as a **fourth `DENSITY_TOKENS` column** per the `[UUI-11]`
  precedent ("add a third column, not a local override"), not a second scaling system;
  `DENSITY_TOKENS` still holds only `touch` and `controller`, so `dense` is ruled-and-unbuilt and
  the editor column lands with it. Inherits `[UUI-18]`'s confirm-or-revert with no new decision.
  Settings scope defers to `S12`.
- **`[CEUI-S2]` the floor is measured in effective pixels** — `window ÷ editor scale`, the same
  shape as the ratified `backing ÷ content_scale_factor`. A 1366×768 author scales down and clears
  it; the minimum-size state survives below that and names the knob as the remedy. Resolves the
  three-way conflict: Branch K's resolution warning is **superseded**, its **input-mode axis
  survives** (the only mechanism that tells an author their input is wrong), its declutter row is
  untouched.
- **`[CEUI-S3]` the simulator is an embedded playable session**, resolving `CEUI-26` in part. It
  subsumes `[DLUX-15]`'s per-size-class preview and `[L10N-16]`'s pseudolocale captures, which a
  launch-out model would have needed a second mechanism for.

**Five consequences of `[CEUI-S3]`, two of them defect risks.** `ResponsiveLayout` and
`InputModeManager` must become **context-scoped** — both are autoloads holding one global state
derived from the whole window, and there is exactly **one** production consumer today
(`UnitDetailsScreen.gd`), so this is nearly free now and a migration after the responsive rollout.
The session is a **snapshot** in the two-primitive vocabulary (capture at launch, discard at exit),
which keeps `[DLUX-15]`'s "never commits campaign state" honest without an exemption and collapses
`CEUI-27`'s fixture into the snapshot's starting state. **Autosave must be sandboxed** or a test
session writes into the player's slots. Keyboard arbitration returns as an editor question — the
same "who owns printable input" problem `NMTE` dissolved for the game UI. And two themes render in
one window (chrome-themed editor, pack-themed game view), a second instance of the Settings shape.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`98017fdb` wrote the diff and paid two propagation debts inside the same change: the `CEUI`
research claimed the editor is "hidden behind the existing runtime/developer gate" (Branch K rules
the entry **visible everywhere by default**; developer mode gates loose-folder packs and the deep
validator only), and it treated "no built-in content palette" as an inherited decision when
`DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31` closed `completed` with `decision_required: true` and
**no ruling written to any document** — `grep -ri "content palette" AGENT/Docs/` returns nothing,
while `[ICO-1]`'s ratified text still says default content ships with the builder as a copy-from
palette. That row is **reopened**. `4faa6433` recorded `[CEUI-S1..S3]`, amended `[CEUI-5]` twice
(effective-pixel measurement, and narrowing its "not a consumer of any size-class-conditional
decision" sentence, which is true of the chrome and false of the embedded session), and marked
`CEUI-1` unblocked and `CEUI-26` partially resolved. The control plane carries the diff's summary
so `check_docs.py` check 30 can see an owner for it.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks, run after each docs change.
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated and committed with the change.
- `bash scripts/agent-push.sh --repo Project_Prometheus` — full suites **green**, receipt at
  `audit/check-receipts/Project_Prometheus-full.json`; `session-claims` PASS (780 audited).
- `python3 coordination/check_tasks.py` — **OK**, 420 tasks valid, no conflicts.

## Next

**Resume `S10` at diff §3.2 — the web target.** Ruling it once covers `CEUI-16`, `CEUI-22`,
`CEUI-33`, `CEUI-37`, `CEUI-38` and `CEUI-2`'s residue; walking them individually produces six
inconsistent platform stances. Then §3.3 (is editor Undo a third primitive?), which then settles
`CEUI-13/14/15/31` in minutes, and §4.3/§4.4 — the content palette, and **what the embedded
session activates**, now urgent because `[CEUI-S3]` cannot activate anything without it.

Do **not** re-walk `CEUI-2`/`6`/`32`/`39`'s choice, the eight closed `NMTE` questions, or
`CEUI-19`'s severity taxonomy (already ruled twice in the same shape by `[CRD-9]` and `[L10N-14]`,
plus `[DRC-17]`'s blocking checks — reconcile four, do not invent a fifth).

**No propagation debt carried out of this session.** All four found were paid here: the research
doc's two misstatements (`98017fdb`), `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`'s stale
"waits on `NMTE`" row text, and `[CEUI-S2]`'s supersession of Branch K's resolution warning, which
now carries an amendment banner in `campaign_library_ux_decisions_2026-07-24.md` recording exactly
which of its three mechanisms survived. The `L10N-7` 1.3× debt the `NMTE` diff logged was already
paid before this session opened.
