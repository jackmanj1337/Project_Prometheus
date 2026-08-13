# UI Album Sources

The authored HTML/CSS behind every published UI album, recovered from the Artifact service
and stored here so the drawings survive independently of it. **Build UI against these**, not
against a screenshot or a URL.

Each file is **self-contained**: one `<title>`, one `<style>`, then the page. No external
stylesheets, fonts, scripts or images — everything, including the captured screenshots in
the responsive album, is inlined. They adapt to light and dark through
`prefers-color-scheme` and honour an explicit `data-theme` on the root element.

## Viewing one

They are body fragments, exactly as authored, because the Artifact service supplies the
`<!doctype html><html><head>…<body>` skeleton at publish time. To open one locally, wrap it:

```bash
F=AGENT/Docs/wireframes/albums/shop_transaction_album.html
{ echo '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body>'
  cat "$F"
  echo '</body></html>'; } > /tmp/album.html
```

Then open `/tmp/album.html`. Any browser will do; none of them need a server.

## The albums

| File | What it draws | Decisions it belongs to |
|---|---|---|
| [`shop_transaction_album.html`](shop_transaction_album.html) | Shop transaction surface — 11 lifecycle states × 10 viewports, 137 frames, generated from one `renderDevice()` function | `TSV-1..9`, `EPUX-13..17`, `SHC-1..8`, `CUR-1..7` |
| [`unified_ui_proof_set_album.html`](unified_ui_proof_set_album.html) | The proof set — Main Menu, Campaign Library, Settings and map HUD across the six ratified viewports, 26 frames as inline SVG | `UUI-1..19` |
| [`responsive_ui_research_album.html`](responsive_ui_research_album.html) | The responsive redesign research pass, six sub-albums, plus **three real captures** of a v0.7.0 web export at 1179×2556 DPR 3 | `SMALL-SCREEN-UI-REDESIGN-2026-08-05` |
| [`text_entry_compact_wireframes.html`](text_entry_compact_wireframes.html) | Compact text entry — the keyboard-replaces-the-band model, layout options measured in millimetres against a real iPhone keyboard | `TEXT-ENTRY-ON-MOBILE-COMPACT-2026-08-06` |
| [`landscape_dead_space_model.html`](landscape_dead_space_model.html) | Landscape dead-space rule and the split keyboard, with the columns-per-side table by aspect | `MOBILE-WEB-CONTROLLER-2026-08-04`, `UUI-1/2` |

Standalone SVG frames extracted from the proof set live one level up in
[`../`](../) — use those when you want a single frame rather than the album around it.

## Published copies

The same albums are published as Artifacts. The URLs are convenient for reading and
commenting, and are **not** the source of truth — a published page can be edited or lost
independently of this repo.

| File | Artifact |
|---|---|
| `shop_transaction_album.html` | <https://claude.ai/code/artifact/65c72398-077d-4d63-858d-b9b8c2ff9af5> |
| `unified_ui_proof_set_album.html` | <https://claude.ai/code/artifact/34929585-0ec2-4e96-9040-b084ce5e7fe1> |
| `responsive_ui_research_album.html` | <https://claude.ai/code/artifact/d84bbb29-6e89-4fc7-890e-f1cc0286b9b5> |
| `text_entry_compact_wireframes.html` | <https://claude.ai/code/artifact/52b44060-565d-4252-8bd4-2f3b220bb37d> |
| `landscape_dead_space_model.html` | <https://claude.ai/code/artifact/99846a07-bde4-4b07-9b9c-6a3febfa80bd> |

If you edit a file here and want the published copy to match, republish it — the two do not
sync themselves.

## What these are and are not

- **They are drawings, not a component library.** No file here is imported by the game. They
  are HTML because HTML draws responsive layouts quickly and measurably, not because the UI
  is HTML — the UI is Godot scenes.
- **The numbers in them are measured, not chosen.** The shop album measures its own layout
  after mount and writes the result into the captions, so a quoted extent or row count is
  what the browser produced. Treat a figure in a caption as evidence; treat a figure in
  prose as a claim that should cite one.
- **The metrics come from `ResponsiveLayout.DENSITY_TOKENS`.** Where an album and the engine
  disagree, the engine wins and the album is stale — that has happened once already, and the
  proof set records it as a finding.

## Regenerating

Only the shop album has a generator, because only it is programmatic:

```bash
node AGENT/Docs/design/shop_wireframes/render_sheets.mjs   # 11 contact-sheet PNGs
```

The other four are hand-authored pages. Edit the file.
