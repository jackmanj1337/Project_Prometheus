# Session Note - 2026-08-15-06-57-41Z-distribution-surface-walk

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `1c921ce6`
- Coordination Work ID: `DISTRIBUTION-SURFACE-2026-08-15`

## What was done

`S5`+`S6` — authored, drew, precedence-checked and walked the distribution-surface packet in one
sitting, the way the editor arc ran. **`DSX-1..28` are RESOLVED**, rulings `[DSX-S1]`–`[DSX-S28]`.

**The owner widened the scope twice before any question was written**, first to on-map Trade and
provider convoy access — with the battlefield shop ruled **the same interface, different trigger**
rather than a second screen — then to skills, techniques (styles), battalions and "a version of
forge". Loadout was added on recommendation. Nine consumers in one packet.

**The reframe that made the widening cheap rather than expensive.** Four ratified rulings already
delegate presentation to *one* undrawn surface: `CNV-8` (convoy panel functions, 2026-06-30,
predating the responsive programme), `BAT-10` ("reuses the existing equip/loadout UI affordances"),
`LDC-1` (one earned-superset / equipped-subset / cap mechanism across skills, styles and granted
sources) and `RPD-11` (Manage Roster is an **open registry** of panels; Loadout/Skills/Details/Swap
are shipped defaults, not the set). There are no loadout frames in any album. Designing these one at
a time yields four panel shapes inside one registry — so the packet's spine is **one shell, N
adapters: holder · pool · detail**, and `[DSX-S1]` ruled it, with the escape hatch **declared**
rather than improvised.

**The dependent-choice layer (`DSX-23..28`) was an owner proposal mid-session**, and the precedence
check changed it before it was drawn. `RPD`'s prep-hub amendment **already ratified its gesture** for
deployment placement — select-then-select, committing on the second selection, no confirm *because a
swap is reversible* — so the layer must **absorb** that ruling rather than duplicate it (registered
as a named `R3` candidate in the same session). And `EPUX-26` rejected a second navigation **level**
for the forge while **naming no pane**, so a dependent set is legal exactly when it *replaces a
region* rather than adding one. Related near-miss recorded: the skeleton's three Expanded regions
are not three levels either — the holder is the subject already chosen, which is the reading the
shop's ruled 2026-08-12 composition established after `EPUX-03`.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

The proof set, the precedence diff and the packet land together, with the four propagation debts the
session created paid in the same change: the control plane gains the `DSX` section, the sequencing
plan gains the `R3` candidate, and the `SHP`/`TSV`/shop-wireframes corrections below are applied at
source.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` / `REGISTERS.md`.
- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 44 checks. One failure en route
  (`active-doc-ownership`: a new design source needs a Control Plane or Feature Index link, not just
  a frontmatter field) fixed by giving the diff its control-plane entry.
- Proof set measured headless via the Playwright harness at
  `/opt/prometheus-web-harness/node_modules`; no page errors. 24 frames, 8 consumers, 4 viewports.

## What the measurement decided, rather than argued

1. **The ~1.9-screen detail column at the Compact floor is structural to the family, not a shop
   problem.** Convoy transfer 1.92, skill equip 1.86, shop purchase 1.9 — three unrelated consumers,
   one number. `[DSX-S11]` accepts it and promotes the shop album's finding 2 to a rule: **the
   reason leads the step**.
2. **The overlay opt-in is the only workable floor configuration** — 4.4 rows with the control band,
   10.4 with it (`[DSX-S12]`, recommended in-surface, never automatic).
3. **`--row` is a floor, not a height** (`[DSX-S22]`): a name plus a sub-line measures **35 px
   against a 28 px controller token**, a 25% overrun *before* `L10N-7`'s 1.4× extent.
4. **The `SHC-5` landscape rail is worth 90 px of height on-map** — window 250 → 340 px, 5.2 → 7.1
   rows, battlefield-shop detail 1.81 → 1.33 screens. The first landscape pass used horizontal
   chrome and contradicted `SHC-5`; corrected before measuring. The result reproduces the `SHC`
   walk's 3.6 → 7.0 gain to within a tenth of a row, which is a useful check that these frames and
   the shop album agree.
5. **The dependent set belongs in the pool, for both kinds** (`[DSX-S5]`). At 852×393: Trade pool
   placement fits with a 1.26-screen result column, detail placement costs a stale 1.62-screen pane
   **and** a 2.14-screen column; forge is 1.05 against 2.04. One rule, not two — and option C's
   premise fails because the pool's rows stop being actionable the moment stage 2 begins.

## The line held three times in one walk

`[DSX-S6]`, `[DSX-S18]` and `[DSX-S27]` all refuse the same tempting rule — *"confirm when the
action is irreversible and spends"*. That is the engine-side risk classification `TSV-8` rejected
and `RPD-9` rejected again; confirmation stays `EPUX-06`'s **authored, raise-only predicate**, and
the shell's obligation is instead to state a **reversibility class**: freely reversible, reversible
until exit, irreversible. Those three classes are now load-bearing rather than descriptive, because
`[DSX-S6]`'s no-confirm commit stands on them. `[DSX-S26]` discharges the no-receipt-store
legibility problem `TSV`'s consequence 5 assigned to this session by name — mandatory line above the
verb **and** a one-time entry notice, deliberately over-stated because it is the one place where the
*absence* of a mechanism has to be visible.

## Propagation debts found and paid

- **`SHP-1..5` were never open.** Every one carries an owner resolution from 2026-06-23k and the
  register header reads `RESOLVED 2026-07-02`; only the inline `[OPEN]` markers were stale. Two
  documents cited them as blocking and concluded *"all prices are illustrative"*. Markers flipped,
  both sentences corrected: prices are illustrative because no **content** exists, which blocks
  nothing.
- **The shop wireframes doc was stale in three places** — `TSV-10..24` "remain open" (all resolved
  2026-08-13), repeated in *What this does not decide*, and a `hypotheses` status after the
  `SHC`/`CUR` redraw. Corrected, and the doc now records `[DSX-S25]`: its composition **is** the
  family skeleton, a naming change with no redraw.
- **`UBS-6`'s own agenda text** still described "the single `party_gold` wallet", superseded by
  `CUR-1..7`. Noted in the diff (F3).
- **`DISCUSS-CONVOY-SHOP-UX-2026-07-23` is `completed`**, which means the research finished —
  standing rule 3, fourth hit. Its rulings are `EPUX-08..17`; the packet cites them and re-asks none.

## Next

- **`UBS-6` does NOT lift yet.** `[DSX-S28]` reversed the recommendation: the gate lifts when the
  family's album sheets are drawn to these rulings **and approved**, not at the walk. Drawing them is
  the next deliverable.
- **Open consistency question raised at the walk and left open:** `UBS-8` was lifted at the close of
  the `CEUI` walk on 2026-08-14, *before* its editor album was approved. The two surviving gates were
  therefore released by different standards. Either `UBS-8`'s lift is provisional until the editor
  album is approved, or `[DSX-S28]` is a `DSX`-only stricture. This affects `R2`'s gate and needs an
  owner call.
- `S7`/`S8` (compendium) remains independent and unblocked.
