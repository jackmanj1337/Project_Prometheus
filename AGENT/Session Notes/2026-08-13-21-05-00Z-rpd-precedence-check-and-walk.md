# Session Note - 2026-08-13-21-05-00Z — `RPD-1..18` precedence check and walk

## Branch context

- Branch: `agent/integration` (docs line — this is where research packets are walked)
- Base branch: `agent/integration`
- Base SHA: `f7e2adea`
- Coordination Work ID: `RESPONSIVE-PREP-DEPLOYMENT-RESEARCH-2026-08-12`

## What was done

**`RPD-1..18` is RESOLVED.** The responsive prep/deployment packet — queue item 3 of the
unbuilt-screen agenda, written 2026-08-12 and never walked — was taken ahead of
`DRC-PLAN-REDERIVATION-2026-08-13` at the owner's instruction. Thirteen questions ruled, three
closed by precedence, two derived without being put to the owner.

### The precedence check found the worst case yet

`AGENT/Docs/design/rpd_precedence_diff_2026-08-13.md` is the fourth `DOC-014` check in two days,
and the fourth to change the questions before the owner saw them.

**`RPD-1..18` cited no ratified decision at all** — not one bracket id in either the register or
its comparative research. This is a harder failure than `TSV`'s on 2026-08-13: `TSV` argued against
ratified text three times and lost all three, but it engaged with the corpus. `RPD` was written as
though the prep surface had never been designed, when **the prep hub was resolved in June
(`PHB-1..7`) and its structure ratified in July** (`EPUX`'s whole *"Prep hub structure, convoy and
shops"* section). Those two documents already answered three of the eighteen questions and
constrained eight more. Nothing outside `RPD` cited `RPD` either, so no propagation had run in
**either** direction.

The clearest illustration: **`[RPD-18]` re-derived `[PHB-7]` correctly, from scratch, without
knowing `PHB-7` exists.** It reached the right answer — a between-map save does not persist the
plan; re-authored from campaign state on return — which is `PHB-7`'s *"no bespoke hub-suspend
snapshot; re-entering prep re-derives"*, ruled 2026-06-23.

### One question gated five, and the answer came from yesterday's dialogue walk

`[RPD-1..5]` all turn on a single undecided thing: **is Map Preview a canvas or a list+detail
screen?** `[RPD-4]` proposed three simultaneous panes, which contradicts `[EPUX-03]`'s *"never
three panes — a third collapses at 200% Menu Scale and steals width from the terminal panel"*, and
which `UBS-4` had rejected **one day earlier** for the same class of surface with *"the tactical
map is a canvas, not a list+detail screen, so the pane model would have to be extended to it."*

**Ruled: Map Preview is a canvas**, governed by `UBS-4`'s rule at every size class — surfaces
occupy the canvas region and never the control band. One presenter rule now covers dialogue and
Map Preview both. `[RPD-4]` is rejected as written; `[RPD-2]`'s Compact sheets survive but as
*canvas-region* sheets (a screen-bottom sheet would have covered the control band, the exact defect
`[UUI-2]` and `UBS-4` exist to prevent); `[RPD-3]`'s landscape half was already correct and its
Medium-tablet drawer becomes a canvas-region band, so portrait and landscape stop being two rules.
Nothing in `EPUX-03` needed amending — it already lists Map Preview among the full-width panels the
shell presents *alone*, and this ruling strengthens that reading rather than contradicting it.

### One ruling reached well beyond its own packet

**`[RPD-15]` closed a question deferred twice since July.** Its visible-when-invalid half was
already `[EPUX-02]`'s default, but its second clause — *keep it focusable* — was written down as
unruled in two places: `[EPUX-02]` (*"Derived, not ruled … Recommend focusable-but-not-activatable;
not settled here"*) and `[EPUX-04]`, which called it a shell-level decision and deferred it to
`EPUX-06/07`. **Neither `EPUX-06` nor `EPUX-07` ever ruled it.** Ruled now: **focusable but not
activatable, at the shell, across all five availability surfaces** — a disabled entry takes focus so
the unmet reason is reachable by keyboard, controller and screen reader rather than hover-only.
Both `EPUX` bullets are amended; the dangling deferral is gone.

### The duplicate-state and duplicate-mechanism shapes appeared again

Both patterns from the `DRC` session recurred, which is now four consecutive walks:

- **`[RPD-10]` proposed a sixth availability vocabulary** (glyph + text for required / excluded /
  dead / unavailable). `[EPUX-02]` ruled *one* two-state rule across four surfaces, `DRC-11` added
  the map as a fifth and rejected a richer vocabulary to do it, and `TSV-8` lost this same argument
  earlier the same day. Ruled: a `REQ` predicate returning an `[EPUX-02]` unmet reason; *dead* and
  *excluded* are unit **state** from `DRC-19..24`'s five dimensions, not a display vocabulary.
- **`[RPD-16]`'s "required unit" wanted to be a flag** — the shape `DRC-25` ruled against yesterday
  (transition attaches to the *opportunity*, no `recruitable` flag on the unit) and that retired
  `[RCR-2]`'s `recruited:<id>`. Derived, not asked: required-ness is a `REQ` predicate over the
  roster, a property of *the mission*.
- **`[RPD-17]` proposed a third persistence primitive** — an "explicit safe transition" for suspend
  payloads. Ruled instead: **the deployment plan IS a staged transaction whose commit point is
  Begin Battle**, which is `[PHB-5]` restated in the two-primitive vocabulary; suspend discards the
  stage (`PHB-7`), campaign Retry is a `MapLedger` snapshot restore. `RPD-17`'s own goal — *never
  allow a plan that spawn ignores* — becomes **structural** rather than a rule to enforce.

### Two smaller findings worth keeping

**`[RPD-14]` was a deferral, not a question** ("research before committing"). `EPUX`'s **subject
memory** had already solved the same invalidation problem with tiered confidence — firm within a
visit, best-effort across, falling back when the remembered subject died or left. Ruled: generalize
that tiering to the deployment plan, per slot. No new preset concept, no invalidation rules to
invent.

**`[RPD-4]`/`[RPD-5]`'s "at FHD" wording invented a breakpoint the engine has no notion of.**
`ResponsiveLayout` derives three classes from logical width alone and `[UUI]` calls 1280×720
*"Expanded — now the largest class"*. The comparative research was **already correct** (it labels
1920×1080 *"Expanded FHD"*); only the register's question text drifted. Ruled: bounded workspace,
no internal breakpoint, revisit only on playtest evidence — the posture `EPUX` used for subject
memory. Preserve the eight-viewport proof set when amending.

Also recorded, because it would otherwise read as an inconsistency: **`[RPD-7]`'s no-confirm swap
is consistent with `CAU-4` by construction** — a swap is reversible before Begin Battle, so it
emits no confirmation tag, and `CAU-4`'s presets govern only the engine-derived tag set. What
no-confirm owes is undo, and the staged-transaction ruling makes that structural.

## Commits

Ownership is in `CLAIMS.tsv`. Four commits from `1695108c` to the agenda/tracker update:
`1695108c` the precedence diff and its control-plane registration (written and committed **before**
the walk, so the owner saw narrowed questions rather than the packet as authored); `ee9a2837` the
eighteen rulings and the register close; `6068e18b` the propagation write-backs into `EPUX-02`,
`EPUX-04`, the `EPUX` prep-hub section and the `PHB` register — done in the same session rather
than left as debt, since one-directional propagation is precisely what made this walk necessary.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks, run after every register edit.
- `python3 AGENT/Docs/gen_docs_index.py` — regenerated and committed alongside each change.
- `python3 scripts/ci/check_session_commit_claims.py --fix` — claimed as we went, before each
  subsequent commit rather than at the end.
- Pre-commit hooks green throughout (analyzer tests 12/12, scene integrity 23 scripts, GDScript
  style 320 files). Docs-only paths skipped the Godot suite as expected.
- One check earned its keep at authoring time: `check_docs.py`'s active-doc-ownership rule refused
  the precedence diff until it was registered on the control plane — which is the mechanism that
  stops a design doc becoming invisible the way `RPD` itself had.

## Next

**`DRC-PLAN-REDERIVATION-2026-08-13`** is unchanged and still the sequenced next action — it was
scheduled for this session and deferred by owner instruction, not blocked. It gates thirteen build
rows (`DRC-V1-S00..S11` and `EPIC-DIALOGUE-CUSTODY-V1`), none of which may be picked up until it
lands.

**`NMTE-1..20` is now the last unwalked packet of the written set** (queue item 2), and it still
gates `CEUI`'s search rows. Every other written packet — `TSV`, `L10N`, `CRD`, `SKF`, `DRC`, `RPD` —
is resolved.

**Debts carried out of this walk**, all recorded in the register and none blocking:

1. `[RCR-4]` still owes `[REQ]` a banner — carried from the `DRC` Group A walk, and now
   load-bearing for `[RPD-10]` too, since both depend on `REQ`'s display path for the reason string.
2. The `RPD` register's `[RPD-4]`/`[RPD-5]` question text should be amended to drop the invented
   FHD boundary; the comparative research needs no change.
3. Seven `UBS` packets still need authoring before their sessions can run (`UBS-2` transaction
   surface, `UBS-6` convoy/shop, `UBS-7` compendium, `UBS-8` editor, `UBS-9` credits).

**Process, now four for four.** Every precedence check run in the last two days changed the
questions before the owner saw them, and one found its predecessor partly wrong. This one found a
packet with zero citations against a corpus that had already answered three of its questions.
**Assume every 2026-07/08 packet owes this check until it has had one** — and write the check
*before* the walk, not as a retrospective.
