# Session Note - 2026-08-13 (SKF/DRC second walk — SKF closed, DRC-1..18 complete)

## Branch context

- Branch: `agent/integration` (docs line)
- Base branch: `agent/integration`
- Base SHA: `4e540417`
- Coordination Work IDs: `DISCUSS-SKILL-STATUS-FEEDBACK-2026-07-23`,
  `DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23`

## What was done

The precedence diff was built last session so these two packets could actually be walked. This
session walked them. `SKF-1..12` is **closed**; `DRC-1..18` is **complete**; the three drafting
items the previous note deferred are ruled. Only `DRC-19..33` remains, still deferred pending
scoping.

**`SKF` — the remaining eight.** The headline is `SKF-2`: **attribution had never been decided
anywhere in the project**, and the citation that claimed otherwise was the defect the diff caught.
Ruled as *the record carries everything, each channel declares the subset it renders* — source,
cause, attempted cause, blocking cause, intended target, actual resolved target — **with one field
forced onto every channel that fires**: a target substitution by the `RDR`/`CVR`/`RCT` families is
always rendered. That is deliberately the general rule of which `[CVR-4]`'s "forecast must show the
protector as the actual defender" is one case, so `CVR-4` was amended to point at it rather than
continuing to carry a standalone unbuilt requirement.

`SKF-6` supplied the discriminator the rest of the register needed: **does an external cause explain
the non-event?** A target property or a blocker does (`immune`, `negated` — callout, per `CFB-2`);
a resolution landing with zero delta does not (`no_effect` — log-only, on `[CFB-1]`'s silent side).
`SKF-9` then falls straight out of it as a **mechanical delta test**, which deletes the undefined
term "tactically meaningful" from the register rather than trying to define it. The option that
would have fired `no_effect` only for player-initiated attempts was rejected on the spot: it forks
feedback by actor, which `CFB`'s ratified parity principle bans outright.

`SKF-4`, `7`, `8`, `11` and `12` all resolved the same direction — **derive rather than declare**,
per `[CFB-17]`. Stacking and the removal rule derive from the registry declaration and the removal
predicate; presentation priority derives from `SKF-8`'s new open band registry; icon/badge derives
from authored asset presence. **"Animation role" is dropped, not deferred** — new vocabulary
mis-attributed to `[CFB-18]`, proposed ahead of a rig `CFB-18` itself records does not exist, and it
would have been precisely the hand-maintained parallel field `CFB-17` banned.

**`DRC` — the remaining five.** `DRC-2` keeps runtime data flat with stable line IDs; worth noting
the argument that would have justified nodes (resume boundaries) had already been removed by
`DRC-9`'s own atomic-v1 ruling, so this was narrower than it looked. `DRC-4` mints tool IDs with
optional author aliases. `DRC-12` takes option C but **rides `DRC-13`'s interaction-policy registry
rather than opening a second one**. `DRC-17`'s four residue checks block; option C fixtures stay
supported but never mandatory, because making them mandatory would gate the fork-a-public-pack
onboarding model behind writing tests.

`DRC-9` produced the outcome most worth carrying forward: the July ruling **stands unchanged, but
is now structural instead of a rule to obey**. Under last session's two-primitive ruling a
conversation *is* a staged transaction, so a save discards the stage and only committed state was
ever serializable — no staged consequence can leak into a save **by construction**. `[DLG-11]`'s
banner was updated to say the supersession is now mechanical, not a prohibition someone must
remember.

**The three drafting items.** `UBS-4` extends to Medium and Expanded **unchanged** — canvas region
only, never the control band, with `map_talk`'s band shrinking proportionally as more board becomes
visible. One presenter, not one per size class. The side-rail alternative was rejected because the
tactical map is a canvas, not a list+detail screen, so the pane model would have had to be extended
to reach it.

`[DLUX-16]`'s stage direction is the one that came out better than any option offered. Owner ruling:
**the flip is for the stage; the box follows reading direction.** The stage is screen-absolute and
declares non-mirroring, so the facing flip stays a pure art flip with nothing to compose against.
The dialogue box justifies to the locale and renders the line as **one inline run** —
`Speaker: words words words more words.` The speaker name is the *head of that paragraph*, not a
separately positioned name plate, so it inherits justification and **needs no direction metadata of
its own**. `L10N-12`'s obligation is discharged by removing a component rather than annotating one.
Derived constraint written in alongside it: per `[L10N-8]` that form must be a **single localizable
template**, never `name + ": " + text` in GDScript, or a locale cannot change the separator or order.

`[CAU-4]` gained `recruitment`, `custody_change` and `execution`, closing `[DRC-14]`. Three tags,
not one, because they carry three distinct reversibility profiles. The `CAU-4` block also picked up
the **split-by-origin** amendment ruled last session, which it had been missing — that conflict
existed independently of any packet and `CAU-4` was the document actually carrying the defect.

## Commits

Ownership is in `CLAIMS.tsv`. One commit: the walk and every propagation it owes, as a single
logical step — the rulings and their consequences in `CVR-4`, `DLG-11`, `CAU-4`, `DLUX-16` and the
responsive design are not separable, and `check_docs.py` check 18 validates the **working tree**, so
a partial commit would leave a checkout of it index-stale.

## Gates

- `python3 AGENT/Docs/check_docs.py` — PASS, all 44 checks.
- Pre-commit chain — RNG guard, analyzer tests (12), scene integrity (23 scripts), session claims
  (733 commits audited), evidence matrices, GDScript format + lint (320 files) all PASS.
- `coordination/check_tasks.py` — OK.

**DoD#2 — a deliberate no-check call, recorded rather than left silent.** Nothing mechanically
checkable lands today, because every ruling is design ahead of build: the pack validator, the
dialogue presenter and the feedback registry do not exist yet, so `SKF-12`'s field list and
`DRC-17`'s blocking checks have nothing to attach to. The one vocabulary candidate — "animation
role", dropped by `SKF-11` — appears **only in the record of its own rejection**, so a manifest row
would need roughly ten quotation exemptions to guard a term that never reached code, data, or a
ratified doc. That is unlike yesterday's `symmetric`→`bidirectional` case, where the retired term
was the *authoritative definition* in `RCV-3` and an author could plausibly re-introduce it.

## Next

`SKF` needs nothing further. The named follow-ons, in order:

1. **`DRC-19..33`** — the recruitment/capture half, still unscoped. §3 of the precedence diff
   travels with it and already carries four live `EPUX`/`TSV` findings, including the nesting the
   two-primitive ruling now answers.
2. **`CEUI-1..40`** still waits on `NMTE-1..20` for its search rows.
3. **Build work unblocked but not started**, unchanged from the shop session: the landscape
   predicate in the composition selector, the generated Explore submenu, the `MapMenu.gd:75`
   renderer, and abbreviation opt-in per call site.

One correction owed and **not** done here, carried from the diff's §5.2:
`plans/dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md` was marked
**Needs revision** last session, and today's `DRC` rulings change it further — `DRC-2`, `4`, `9`,
`12` and `17` are all decision-source questions it derives from. It should be re-derived before
anyone implements from it.
