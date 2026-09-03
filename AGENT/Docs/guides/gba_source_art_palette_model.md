---
Role: topic
Type: reference
Status: Active - measured reference
Last verified: 2026-08-26
---

# The GBA Source-Art Palette Model

**What this is for.** Any pack built by copying a Game Boy Advance game — which
is what the three-game acceptance target asks for — imports art that was drawn
under hardware rules the editor cannot see. Getting those rules wrong does not
produce an error; it produces art that looks subtly wrong and decisions that are
confidently backwards. This page is the model, the checks that confirm it, and
what it changes about importing and palette work.

It exists because the same mistake was made three times in one week on the FE
pack, always the same way: **treating a colour as a property of a tile, when it
is a property of the palette bank the tile reads through.** Everything below was
measured from the art rather than read from documentation; the corroborating
sources are at the end.

Companion: [`fe_map_sprite_importer_guide.md`](fe_map_sprite_importer_guide.md)
builds the importer itself and deliberately stops short of palette work. This is
the part it defers. Palette swaps as *pack data* are governed by `[CSA-18]`,
`[CSA-19]`, `[CSA-20]`, `[CSA-21]`, `[CSA-24]`, `[CSA-25]`, `[CSA-27]` — see
[`GDD_11_Campaign_Editor.md`](../../GDD/GDD_11_Campaign_Editor.md), *Assets,
Provenance, And Palette Work*. Licensing of imported art is `[LEG-4]` and is not
softened by anything here.

---

## 1. The hardware

A GBA background is built from **8×8 tiles**, not the 16×16 cells a map appears
to use. In the mode these games use, a tile is **4 bits per pixel**: a pixel
stores an *index* from 0 to 15, not a colour.

The colour comes from a **palette bank**. Palette RAM holds **16 banks of 16
entries**, and each tile's 16-bit tilemap entry carries the bank number
alongside the tile index and two flip bits. **Entry 0 of a bank is transparent**,
so an opaque background tile can show at most **15 colours**.

Colours are stored as **BGR555** — five bits per channel. Every rip in the FE
tree expanded them by shifting left three, so every channel is a multiple of 8
and the brightest value is 248, never 255.

Three consequences that matter more than they look:

- **A 16×16 map cell is four hardware tiles**, and they need not share a bank.
  In practice a coherent terrain cell does, and each of its quarters holds ≤15
  colours even when the cell as a whole holds more than one bank could supply.
- **A tile's palette is not its own.** It is a *view* of a bank shared with every
  other tile that reads through that bank.
- **A map has sixteen banks.** Running out is a real constraint; using a second
  one is not a compromise.

## 2. Is this art actually from the hardware?

Two checks, both cheap, both worth running at import:

| Check | What it proves |
|---|---|
| Every channel of every pixel is a multiple of 8 | The art is 5-bit BGR555 expanded by `<<3`. Nothing has rescaled, blended, alpha-composited or lossily compressed it. |
| No 8×8 tile shows more than 15 distinct colours | The art still obeys the bank limit, so it is a framebuffer rather than a re-render. |

On the three staged FE7 maps both checks pass with **zero** violations across
~300,000 pixels. A single failure means the file has been through something, and
every measurement taken from it afterwards is suspect. **Run these before
trusting any other measurement**, not after.

A useful corollary for provenance work: a colour that is not a multiple of 8
did not come from GBA hardware. That is a cheap signal for "this asset has been
edited or re-encoded", independent of any metadata.

## 3. Recovering the banks

The bank assignment is not in the picture, but it is recoverable, because the
constraint is strong: if every tile reads through one bank of ≤15, then the
map's colours must **partition** into a few such banks.

```
1. Cut every distinct 8×8 tile; record its set of colours.
2. Best-fit-decreasing: hardest tiles first, each into whichever open bank
   its colours grow least, opening a new bank only when none can take it.
3. Break ties on the sorted colour tuple, so the result does not depend on
   iteration order.
```

**Always run the null model beside it.** Shuffle which colours each tile uses,
holding every tile's colour *count* fixed, and re-run. If the grouping is a
property of the art, the two numbers are far apart. If it is an artefact of the
packer, they are close, and the reconstruction means nothing.

Measured on the three staged FE7 maps:

| Map | Colours | Banks | Floor | Null model |
|---|---|---|---|---|
| ch01 | 60 | **5** | 4 | 63–65 |
| ch14 | 69 | **5** | 5 | 140–145 |
| ch22 | 37 | **3** | 3 | 51–57 |

An order of magnitude apart. ch01 additionally never reached its floor of 4
under 4,000 random orderings, so its 5 is structural rather than greedy weakness.
Fire Emblem's own tileset format is documented in the romhacking community as
carrying **five palettes per tileset** — which is what two of the three land on
from pixels alone.

### What is not recoverable

- The **index order** inside a bank, and which entry was the transparent 0.
  A picture cannot carry either.
- Whether two banks genuinely **duplicated** a colour or the packer put it in
  both. Where a tile's colours fit two banks, the greedy pass may duplicate.
- Therefore: the result is *a* valid partition, not provably the cartridge's.
  It is sound for grouping and for counting; it is not a ROM dump.

## 4. What this changes for the importer and the editor

**A palette swap is a bank remap.** `[CSA-18]`'s exact-RGBA mapping tables are
the right shape, and the bank is the right *unit* to author one against. A swap
set derived from a bank covers every tile that shares it; a swap set derived
from one tile covers that tile and silently misses its siblings.

**"Repaint into the bank", never "into the other tile's colours".** This is the
error that cost the FE pack two wrong recommendations. Two tiles that look
related — grass and forest, in the measured case — are frequently *one bank*.
Art repainted to match the colours one of them happens to spend is restricted to
an arbitrary subset: in the measured case it compressed an 85-point brightness
range into 39, and the feature stopped reading as a shape at all. Repainting
into the whole bank kept the range at 108 and cost nothing.

**Mixing source maps costs a bank, not coherence.** Two maps from the same game
routinely share *no* colours at all — measured overlaps of 0, 0 and 3 across the
three FE7 maps, and three grass tiles from three chapters share **zero** colours
pairwise while sitting at near-identical brightness. That reads as "these cannot
be combined", and for **per-index** remapping it is true: there is no shared
index space to swap through. But a map has sixteen banks and the busiest of the
three uses five. Importing a tile from a second map spends one spare bank, which
is what banks are for. Do not let a disjointness measurement veto a mix.

**A fringe cannot be keyed off.** Art cut from a rendered map carries a strip of
whatever it stood on. That strip is drawn in the *structure's* own sub-palette,
so it shares no colour with the ground beside it — measured, a gatehouse showed
43 green-ish pixels of which **zero** were the grass tile's colours. There is no
mask to find. The fix is to repaint each such pixel from the nearest pixel that
is not fringe, scanning into the structure, which keeps the tile inside its own
palette by construction. Any importer feature offering to "remove the
background" from tile art should be understood as offering this, not a chroma key.

**Green-ness is not provenance.** A predicate like `g > r+16 and g > b+16` says a
pixel *looks* green. It does not say the pixel came from the grass tile. Naming a
field after the former and reading it as the latter is how the mask-hunt above
starts. Name such fields for what they count.

**Watch for `uint8` overflow in colour predicates.** `c[0] + 16` on a numpy
`uint8` wraps for any channel above 239, so near-white pixels read as green. It
is silent apart from a `RuntimeWarning` and it inflated a repaint from 51 pixels
to 75. Cast to `int` before comparing.

## 5. Where the measured data lives

All of it is generated and byte-verified — re-derived from the sources by
`--check` on every test run, so it cannot drift silently.

Repository `Project_Prometheus_Campaign_Pack_FE`, branch
`agent/from-from-main-proving-grounds-extraction/fe-terrain-handcut`:

| Path | What it holds |
|---|---|
| `tools/fe_palette_banks.py` | The reconstruction, the null model, the checks in §2 |
| `assets/pipeline_trials/PALETTE_BANKS.md` | Generated: every bank of every map, and which role reads through which |
| `assets/pipeline_trials/PALETTE_BANKS_REPORT.json` | The same, machine-readable, with full palettes |
| `tools/fe_terrain_handcut.py` | The repaint and bank-remap rules of §4, applied |
| `assets/pipeline_trials/handcut/HANDCUT.md` | Generated: the seven-tile terrain set and why each treatment |

**That art is internal-only.** Official Intelligent Systems / Nintendo work with
no redistribution grant: never public, never in a build, cured only by
replacement. The pack's `NOTICE.md` governs, `[LEG-4]` governs what may be
committed here, and nothing on this page changes either. The *model* is
transferable; the pixels are not.

## 6. Sources

The hardware model is standard and externally documented; the numbers above are
ours.

- Tonc, [*Regular tiled backgrounds*](https://www.coranac.com/tonc/text/regbg.htm)
  — tilemap entry layout, the palette-bank field.
- Tonc, [*Sprite and background overview*](https://www.coranac.com/tonc/text/objbg.htm)
  — 4bpp vs 8bpp, 16 banks of 16, entry 0 transparent.
- Fire Emblem Universe, [*Tilesets and palettes*](https://feuniverse.us/t/tilesets-and-palettes/945)
  and the [*Graphics*](https://tutorial.feuniverse.us/gfx) tutorial — five
  palettes per tileset, tiles as 8×8 blocks with TSA.
