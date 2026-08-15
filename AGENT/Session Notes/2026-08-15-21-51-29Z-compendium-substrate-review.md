# Session Note - 2026-08-15 (compendium substrate review)

## Branch context

- Branch: `agent/integration` (docs line — documentation-only change, no feature branch)
- Base branch: `agent/integration`
- Base SHA: `0b0b834a6d68be7f208183a39556dd56d8a60587`
- Coordination Work ID: `COMPENDIUM-2026-08-15`

## What was done

Reviewed `CMP-1..15` and audited the semantic system underneath it. The packet is sound; **the
substrate was not**. `generated_reference_model_implementation_plan_2026-07-30.md` was cited by
both the register and the precedence diff as ratified architecture, but nobody had checked it
against rulings that **post-date** it. Nine had never been folded in.

**The sharpest is fifteen days old and was known at the time.** `[CSA-13]` — closed
**2026-07-31, one day after the plan** — ruled attribution a separate, non-suppressible channel
precisely because carrying it as provenance means the `none` profile, the *player-facing* one, is
exactly the rendering path that strips required CC-BY attribution. The `CSA` walk labelled it "a
correctness defect rather than a preference" and "the sharpest finding of the walk". It survived
because it was **ruled in one document and the defect lived in another**, and nothing walks a
plan.

The other three `CSA` rulings bind the same plan and never reached it: `[CSA-15]` (More Info is
**three** regions, not two — art is a fact for data and its own region for layout), `[CSA-14]`
(the in-game compendium **and** the HTML output animate art live; GFM/PDF keep still frames), and
`[CSA-26]` (the reference shows **native, unswapped colours** plus a swap enumeration, where More
Info shows the context-resolved variant). `CSA` had stated the vocabulary gap outright — *"no
visual/art/animation fact anywhere in it"* — and since unknown fact kinds **fail** strict
exports, without an `art_asset` kind the compendium cannot legally show a sprite.

`L10N` never reached the substrate either. `title` correctly used `{text_key, fallback}` but
**`author_notes.body` was a raw string**, making author notes structurally untranslatable and
contradicting `[L10N-3]`'s pack-owned locale catalogues.

**A diff correction.** `F1` claimed *"only line 466 is stale."* The plan specifies in-game search
in **two** places — line 466 and the **Slice 6** bullet. Correcting one would have left the
delivery slice still specifying the cut capability. The static-HTML full-text search sentences
are deliberately untouched, exactly as `F1` argued.

**What the corrections left open became section `F`, `CMP-16..21`** — five things `CMP-1..15`
assumed that nothing specifies, plus one the plan has carried unresolved since 2026-07-30:

- **`CMP-17` — what actually *discovers* an entry.** `CMP-5`, `CMP-6` and `CMP-7` all presuppose
  a mechanism, and `[CMP-S2]` rules what an undiscovered entry looks like, but the plan's only
  sentence is *"discovery/visibility policy supplied by campaign rules"* — no trigger vocabulary,
  no event, no authoring surface. **This now leads the walk order:** the other three decide
  *policy* for a mechanism it defines, and ruling policy first produces decisions nobody can
  implement.
- `CMP-18` — entry IDs become **durable save keys** if discovery is per-save; the ID-stability
  rule is written only for renderers. This is `[L10N-9]`'s own reasoning applied where nobody
  applied it.
- `CMP-19` — the runtime-subject-to-entry resolver. `[TSV-11]` commits *instance* IDs; entries
  are *definitions*.
- `CMP-20` — the player-facing name, unruled since 2026-07-30 and now a chrome message ID.
- `CMP-21` — is the compendium's pack line the credits channel or a second one? `[CRD-2]` scopes
  the credits view identically to `CMP-13`'s compendium.

`CMP-10` and `CMP-11` are **amended**: art breaks the "identical layout" claim, and attribution
is off the provenance axis entirely, so `CMP-11` governs *diagnostic* provenance only.

**One measurement is owed a re-check.** Every proof-set frame was drawn with two entry regions,
so `[CMP-S3]`'s 520-px pane was measured against a layout missing `[CSA-15]`'s third. The ruling
probably survives — B's gain is horizontal, an art region costs vertical — but it should be
re-checked before the album is drawn, not after (`CMP-16`).

## Commits

Ownership is in `CLAIMS.tsv`. `f87d94a1` corrects the plan (a *Corrections Folded In* table at the
top records every ruling applied and its date), extends the register to `CMP-1..21`, and updates
the precedence diff with `F7`–`F9` plus the `F1` correction. `3969d94f` is the claim.

Both tracker rows were updated: `IMPL-REFERENCE-COMPENDIUM`'s text-entry prerequisite is
**discharged** (diff `F2` — all three premises died in the `NMTE` walk), and
`COMPENDIUM-2026-08-15` records the review.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` → regenerated; `REGISTERS.md` verified by grep to carry
  `CMP-1..21` (a PASS alone does not prove index inclusion).
- `python3 AGENT/Docs/check_docs.py` → **PASS**, all 44 checks.
- Pre-push full suites → **PASS**, all green. Receipt:
  `audit/check-receipts/Project_Prometheus-full.json` (tree `4c0a3348`, exit 0).
- `python3 coordination/check_tasks.py` → **OK: 425 tasks valid, no conflicts.**

## Next

**The `S8` walk, with the reordered agenda:** `CMP-17` first, then `CMP-1..4`, `CMP-5..7`,
`CMP-8..9`+`CMP-19`, `CMP-10..12`+`CMP-16`, `CMP-13..15`, then `CMP-18`/`CMP-20`/`CMP-21`. This is
the last `UBS` group.

Two things the walk should not have to rediscover: the plan is **no longer pristine 2026-07-30
architecture** — read its corrections table before citing it — and the `art_asset` fact work has
**no slice assigned**, because it post-dates the delivery breakdown. Both the compendium (Slice 6)
and the HTML output (Slice 7) consume it, and it depends on the `[CSA-4]` art catalogue. Flagged
in the plan rather than guessed.
