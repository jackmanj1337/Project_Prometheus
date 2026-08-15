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

## After the walk — the album, and two more rulings

**`[DSX-S29]`: `UBS-8`'s lift is provisional too.** The owner answered the consistency question by
extending the stricter standard: **a `UBS` gate turns on its album being approved, not on its walk
closing.** Propagated to the `UBS` agenda, the `CEUI` register and the sequencing plan's Stage C and
`R2` entries, so `R2` now waits on approvals rather than walks.

**The album is drawn** — `wireframes/albums/distribution_surface_album.html`, 73 frames, nine
consumers, six viewports, with the shell/adapter contract, the dependent-choice layer across four
consumers, six shared states, four findings and a measurement appendix. Medium **portrait** is new
here (the proof set drew only landscape) and lands at 8.8 rows.

**The album rendered blank for the owner, and that is worth recording as a process fact.** Both
albums generated every frame from a render function at load, so they showed prose and no devices
anywhere scripts do not run — which is where they were read. Fixed by **baking**: the generators
became `<name>.src.html` (source of truth), `bake_album.mjs` renders them once and writes static,
script-free albums under the original filenames with the measurement captions baked at their
computed values. Verified with `javaScriptEnabled: false`. The baker refuses to write an empty album
or one that raised a page error, so a broken source cannot silently produce a blank file. The shop
album answers the same problem with PNG contact sheets; both approaches are now in the wireframes
README so the next album picks one deliberately.

**Findings 3 and 4 came from an owner question**, not from the drawing — how hard would roster-wide
convoy visibility be? Checking rather than estimating turned up that it is **already ratified**
(`EPUX-08`'s global item-first view, `CNV-4`'s unrestricted in-prep movement) and that under
`[DSX-S1]` it is a **pool source**, not a feature. Which exposed **finding 3: the segmented control
means a direction in three adapters and a source in two** — one control, two meanings, in a shell
whose point is that a control means one thing everywhere. No `DSX` ruling covers it because each
adapter was drawn against its own ratified vocabulary. The proposal (control = source, direction
implied by which side you take from) is **drawn, not asserted**, in two new frames. **Finding 4**:
taking a battalion from another unit is not ruled — `BAT-10`'s pool is unassigned only — and would
silently restat the unit it came from.

Code checked while answering, so the next reader does not re-derive it: `GameState.player_roster` and
`UnitData.inventory` are already in memory; `SaveData.gd` already carries `party.convoy.entries` with
a legacy `items` migration; **no convoy UI or `ConvoyService` exists at all**; and
`Unit.set_equipped_weapon` **reorders** the inventory, so "equipped" is a position rather than a flag
— which is the guard a cross-holder take actually needs.

## Then: the compendium packet (`S7`), authored in the same session

`CMP-1..15` authored and ready to walk next session — the **last `UBS` group**. Its substrate is an
approved **plan** rather than a register, so the packet cites the reference-model architecture and
asks only what it leaves open.

Three owner calls taken before the walk: **`[CMP-S1]`** closed candidate list, no in-game search;
**`[CMP-S2]`** undiscovered entries **hidden**, a *named exception* to the availability vocabulary
because here the reason string is the spoiler — the fourth surface to inherit that vocabulary and the
first to be exempted; **`[CMP-S3]`** shape **B**, chosen against a measured alternative (A's category
pane was 239 × 986 px for eight rows).

**`[UBS-7]`'s "reachable outside a campaign" was a conflation** — the out-of-campaign reference is the
*exported* GFM/PDF/HTML artifact, which the plan already specifies in full. So the compendium is
campaign-scoped and inside the pack theme boundary, and the chrome-versus-pack-themed question is
**dissolved rather than answered** — the same shape as the `NMTE` modality collision.

**The precision worth keeping:** the plan's *in-game* search (line 466) is superseded, but its
*static HTML* full-text search is **not** — that is a browser artifact, and correcting both would
have removed a ratified capability.

Two findings came from drawing: **hiding entries does not hide the shape of the graph** (a visible
entry can link to a hidden one, and the plan's validator fails activation on unresolved references,
so any omission must be a presentation filter over a complete graph), and **back/forward history has
no precedent in the programme** — the chain's step-back and a history stack are different mechanisms.

## Next

- **`UBS-6` does NOT lift yet.** `[DSX-S28]` reversed the recommendation: the gate lifts when the
  family's album sheets are drawn to these rulings **and approved**, not at the walk. Drawing them is
  the next deliverable.
- ~~Open consistency question~~ — **answered in session as `[DSX-S29]`**: `UBS-8` is provisional
  too, so the **editor album needs its own approval pass** before that gate lifts.
- **Album findings 1–4 need disposition** at the approval pass. Finding 1 (nothing caps the row
  measure at Expanded — a 1240 px pool puts a name and its price ~1200 px apart) is a real build
  input, not a cosmetic note.
- **`S8` — walk `CMP-1..15`.** Ready as written; take `CMP-6` (links to hidden entries) early, since it is the only question in the packet that can produce a save-visible inconsistency and it constrains the exporter and validator, not just the screen.
- Two documents are owed edits by that walk regardless of outcome: the reference-model plan's line 466, and `IMPL-REFERENCE-COMPENDIUM`'s discharged text-entry prerequisite.
