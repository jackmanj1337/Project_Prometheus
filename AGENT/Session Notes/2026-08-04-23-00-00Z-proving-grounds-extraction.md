# Session Note - 2026-08-04 Proving Grounds pack extraction

## Branch context

- Branch: `agent/from-integration/proving-grounds-extractor`
- Base branch: `agent/integration`
- Base SHA: `5dfa494a1ebc8f0726b937c09105f38cf5165dc4`
- Coordination Work ID: `IMPL-ZERO-CONTENT-BASE-PACK`

## What was done

Built the extraction half of zero-content Slice 3/4: a tool that projects
`res://data` into one self-contained Tier-2 pack, plus a validator that runs the
result through `CampaignTier2RuntimeAdapter.load` — the same path activation takes
— so "valid" means activatable rather than merely well-formed.

Output landed in `Campaign_Pack_FE` as the internal `proving_grounds` pack:
24 classes, 16 weapons, 8 items, 8 maps, 3 rosters, 1 campaign, 7 terrain.

**Extraction is a projection, not a copy.** The engine stores `.tres` resources
with typed arrays and resource references; a pack carries indexed JSON in the
registered `EntitySchemaRegistry` shapes with provenance per document. Four shapes
had to be read off the runtime rather than the zero-content fixtures, which use an
older spelling the parsers reject outright:

| Fixture spelling | What the runtime requires |
|---|---|
| `package_id` / `package_version` | `id` / `version` / `builder_content_version` / `format_version` |
| catalogue `schema_version` | catalogue `format_version` |
| `{"x": …, "y": …}` tiles | `[x, y]` |
| roster `id` / `display_name` | `unit_id` / `unit_name` |

The last one is the sharpest: reading `id` gave every unit an empty string, and the
roster's `unique_key` then reported that as a *duplicate* rather than as the missing
field it actually was.

**Provenance is the point.** Every document names a source. The audit's eleven
transcribed weapons and every non-placeholder class are stamped with a `disputed`
source rather than the project one, so the retune worklist is a grep instead of a
re-read of the audit prose. Nothing is emitted `verified` — extraction moves
numbers, it does not clear them.

**Two things had to be derived rather than copied**, and both are recorded as
occurrence audits so they are reviewable:

- Promoted classes ship zeroed bases in the engine, because promotion applies
  bonuses to a unit's own stats and the class is never instantiated cold. A pack
  class must stand alone and the Tier-2 runtime refuses a zero `base_hp`/
  `base_movement`, so those bases are `promotes_from[0]`'s plus
  `promotion_stat_bonuses`. **Balance-affecting and unreviewed.**
- Weapons still carrying only the legacy literal range string are normalized
  through `WeaponData._adapt_legacy_range`, so the pack carries the registered
  formula form and the compatibility boundary does not travel with it.

## Commits claimed

- `666802c5b7c47f733c52f172b9c8ed9453762605` — Add the base-pack extractor and a pack validator
- `f01e06488896ec7a414ca6836212983233db6ed4` — Stamp heal_staff as transcribed, and track the tool .uid sidecars

## Gates

- `validate_pack.gd` against the emitted pack: `valid: true`.
- Full `run_tests.sh` green (the tools are standalone; no suite depends on them).

## Next

**The pack does not play yet.** Battle encounters — placements, factions, turn
order, objectives, rewards — are not emitted, so its maps are terrain and start
tiles only. That is the next slice, and it is what gates the plan's stated Slice 4
exit ("select the base pack, start a campaign, load a map/roster, finish one
encounter").

Also still absent, and reported by the tool on every run rather than dropped
silently: skills (55 resources) and the pair-up table have no registered Tier-2
kind at all; advancement edges are not emitted, so every class carries an empty
`advancement_edge_refs`.
