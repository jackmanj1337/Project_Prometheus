# Session Note - 2026-08-04 terrain variants and pack-introduced terrain

## Branch context

- Branch: `agent/from-integration/terrain-variants-runtime-sources`
- Base branch: `agent/integration`
- Base SHA: `e4bd00b1a18f3ecf1b3c63ebbe72d3309b82f2cf`
- Coordination Work ID: `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01`

## What was done

Built `[TER-1]` and `[TER-2]` together, as their decision record requires — both
need the same runtime tile-source machinery, so building them separately would
have meant reopening a closed vertical twice.

**`[TER-1]` variant layer.** A grid char now maps to a *variant*, which names the
terrain whose stat block it shares and carries its own art and label.
`TerrainRegistry` seeds one implicit variant per engine terrain from that
terrain's own char/label/source, so the layer is additive: every pack authored
before variants existed behaves exactly as before.

The load-bearing decision is that `id_for_grid_char` still answers with the
**terrain** id. That is what keeps the change cheap — `GridManager.get_terrain_at`,
AI scoring, tags and every existing test match on terrain ids and none of them
had to learn variants exist. `variant_for_grid_char` is the new lookup, and only
the renderer calls it.

This is the shape that answers `RULE-011`/`AWR-8`: a throne is a variant of fort,
not a terrain of its own. Per the decision record, those close when this **builds**
— which now needs the visual pass below.

**`[TER-2]` pack-introduced terrain.** `TerrainTileSetBuilder` duplicates the
engine's generated tileset and appends one `TileSetAtlasSource` per variant whose
art is pack media, stamping each source's `terrain_type` custom data with the
**terrain** id. That breaks the four-way rendering lock at exactly one point, so
the `terrain_id` vocabulary in `EntitySchemaRegistry` is no longer closed.

The *reason* behind the old retune-only boundary is unchanged and still enforced,
just relocated to where the media reference can actually be resolved: an
introduced terrain that names no resolvable art would paint as wall with no
diagnostic, so `TerrainRegistry.collect_coherence_errors` refuses it, and the
builder refuses missing, undecodable, and undersized art with a diagnostic naming
the variant.

A variant deliberately carries **no** stats. One that could set `def_bonus` would
be a second terrain wearing a variant's name, reintroducing the hand-synced
duplicate stat blocks the six-table consolidation removed, one layer up.

## Commits claimed

- `422e4c1127cd483aabf328c0464ad6893458941c` — Split terrain art identity from stat identity and let packs introduce terrain

## Gates

- `bash run_tests.sh` — all suites green.
- `test_terrain_registry` — 17 passed, 0 failed (4 new variant assertions; two
  pre-existing pins updated to the new contract, see below).
- `test_terrain_tile_set_builder` — 5 passed, 0 failed (new suite).
- `test_entity_schema_registry` — 60 passed, 0 failed.

Two assertions were **deliberately inverted**, because they pinned the boundary
`[TER-2]` lifts:

- `test_terrain_registry` "a terrain the engine cannot paint is refused" now
  asserts a pack *may* introduce terrain that names resolvable art.
- `test_entity_schema_registry` "terrain identity" no longer expects
  `vocabulary_value_unknown` for an unknown id. It still pins that
  `tile_source_id` is not authorable — that remains engine identity.

## Next

**Blocker for closure: the Windows visual pass.** `[TER-2]` is a rendering
change; tile sizing and atlas regions are visual correctness and the container
can only prove the sources are built, stamped, and refused correctly. Per the
decision record, do not mark `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01`
done on a headless green suite, and do not close `RULE-011`/`AWR-8` until the
pass lands.

Not built here, and deliberately: `[TER-6]`'s phase-effect and stat-contribution
generalisations stay queued behind `ARCH-ONE-PRIMITIVE-LIST-2026-08-01` so
terrain effects register as primitives rather than forming a sixth dispatch
table.
