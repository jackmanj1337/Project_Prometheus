# Session Note - 2026-07-31-02-57-28Z-campaign-sprite-authoring-register-close

## Branch context

- Branch: `agent/from-integration/campaign-sprite-authoring-register`
- Base branch: `agent/integration`
- Base SHA: `a8a558bc19cb9402804b2b369fa8355b4e3f802f`
- Coordination Work ID: `DECISION-CSA-CAMPAIGN-SPRITE-AUTHORING-2026-07-30`

## What was done

Second owner walk over `AGENT/Docs/registers/campaign_sprite_authoring_open_questions_2026-07-30.md`.
Resumed from the register's own "Status at 2026-07-31 session close" table rather
than from conversation, per the prior note's handoff instruction.

**Every item that table listed as open is now decided.** `[CSA-1..36]` are
answered including all sub-questions; `[CSA-37]` remains the only undecided row
and is deliberately spun out to `BACKLOG-SETTINGS-EXPORT-SCOPE-2026-07-30`.

Decisions taken this session:

| Item | Decision |
|---|---|
| `[CSA-7]` pivot | Optional per frame, default bottom-centre; lives in the sidecar frame table |
| `[CSA-14]` live view | Both — in-game compendium animates as well as exported HTML |
| `[CSA-22]` done swap | Keyed lookup, one swap per (faction, state); editor derives state variants |
| `[CSA-27]` theme removed | Fall back to pack default, notify once per (pack, theme-id) |
| `[CSA-28]`(c) | Absence falls back to engine primitives, never a shipped art set — stated explicitly |
| `[CSA-28]`(d) | Taxonomy default-icon-atlas row superseded outright, not narrowed to shell |
| `[CSA-28]`(f) | Skin follows `active_package_identity`; quit-to-shell deactivates |
| `[CSA-28]`(g) | Skin resolution rides the atomic content-session activation already built |
| `[CSA-28]`(h) | Unregistered slot → warn and ignore; never fails the pack |
| `[CSA-31]`(a) | Generate on creation, silently |
| `[CSA-31]`(a2) | Extractor reports frequency per colour (derived, recomputed on scan) |
| `[CSA-31]`(b) | Explicit `generated` flag on `art_asset@1`, not inferred from a missing source |
| `[CSA-31]`(c) | Fill + optional baked label; generate plain, bake later; generated art only |
| `[CSA-31]`(e) | Closed by (a1) — the extractor is the palette step; imports do not degrade to tint |
| `[CSA-31]`(f) | No hints. Schemas are blank; first-time authors fork a public pack |
| `[CSA-33]`(a) | Empty library offers import only; the editor is reached separately |
| `[CSA-33]`(b) | Files beside the binary, offered for import; never silent auto-install |
| `[CSA-33]`(c) | `res://`→`user://` seed-copy clause superseded |

**Two owner answers overrode the recommendation, and they cohere.**
`[CSA-33]`(a) (empty library offers import only, not template generation) and
`[CSA-31]`(f) (no value hints; point authors at forking a public pack) together
say the onboarding answer to an empty install is **someone else's pack**, not a
blank template. `[CSA-30]`'s "nobody starts from scratch" is now the shipped
experience rather than an expectation, and `[CSA-31]`(d)'s "the generator *is*
the from-scratch path" survives as a capability but not as the promoted route.

**Constraint recorded that falls out of that:** "public packs" means
`Campaign_Pack_0`. `Campaign_Pack_FE` is internal-only under `[LEG-4]`
(FE-derivative art) and must never be presented in-product as a fork target —
whatever surface encourages forking needs an explicit list, not "whatever is
installed".

**One item closed by inference rather than a direct answer**, flagged in the doc
as the line to correct if wrong: `[CSA-31]`(e). Its open question was whether
imported art degrades to tint-only; `[CSA-31]`(a1) had already greenlit building
the palette extractor, which *is* the extraction step (e) said was needed.

## Carried forward — NOT done this session

**Three edits are owed to `AGENT/Docs/design/campaign_asset_taxonomy_and_format_2026-07-01.md`.**
They are *decided* here and *not applied* there. That document is a ratified
contract, and leaving the superseded statements standing guarantees someone
builds against them:

1. `[CSA-28]`(d) — delete the Tier-1a "ship the default set as one packed atlas"
   row and the reserved packed-frame-table form.
2. `[CSA-33]`(c) — delete the "(defaults seed-copied `res://`→`user://` on first
   run)" clause.
3. `[CSA-2]` — delete the now-subject-less "`.tres` is an authoring convenience"
   clause.

Do them in one pass.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated `INDEX.md` + `REGISTERS.md`
  (CSA row flips OPEN → RESOLVED), committed in the same change per check 18.
- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 43 checks green.
- Pre-commit hook: analyzer tool tests 12/12 OK; scene-integrity PASS;
  session-claims PASS (277 commits audited); evidence-matrices PASS;
  gdscript style PASS (257 files). Godot suite skipped — docs-only change.
- No code changed this session, so no playtest or visual pass is implicated.

## Commits claimed

- `27fd480471f6ef6feaa70dd2d2c65697260192af` — Close the CSA register: all remaining sub-questions answered

## Next

Two bounded actions, in order:

1. **Apply the three taxonomy edits** listed under "Carried forward" in one pass
   on this branch. This is the only thing keeping a ratified document in conflict
   with a resolved register.
2. **Start the ungated engine-side slices.** `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`
   blocks only the UI-facing work; not gated and ready are the sidecar schema +
   validator, the runtime slicer, `AssetResolver` semantic groups + fallbacks,
   `art_asset@1` with source/licence, and `Unit`→`AnimatedSprite2D`.

**`[CSA-22]` needs its own slice** and must not be folded into another one: it
made the tint work non-additive, turning `_base_modulate` (`Unit.gd:78-93`) and
`set_done_appearance()` (`Unit.gd:605-608`) into fallback paths behind a swap
lookup, which is a restructure rather than an extension.
