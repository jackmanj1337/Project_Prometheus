# Wireframes — Unified UI Programme

Standalone SVG frames from the wireframe album. Each file is self-contained: it carries its
own stylesheet and hatch pattern, adapts to light and dark via `prefers-color-scheme`, and
renders in any browser or SVG viewer without the album page.

**Album (the readable view, with captions and rationale):**
[`albums/unified_ui_proof_set_album.html`](albums/unified_ui_proof_set_album.html) — the
authored source, stored in-repo. Also published at
<https://claude.ai/code/artifact/34929585-0ec2-4e96-9040-b084ce5e7fe1>, which is a
convenience copy rather than the source of truth.

**Every other UI album source:** [`albums/`](albums/README.md) — shop transaction surface,
the responsive redesign research pass, Compact text entry and the landscape dead-space
model, all self-contained and openable in any browser.

**Decisions these are drawn against:**
[`../registers/unified_ui_decisions_2026-08-12.md`](../registers/unified_ui_decisions_2026-08-12.md) — `UUI-1..17`

**Sequencing:**
[`../plans/unified_ui_programme_2026-08-12.md`](../plans/unified_ui_programme_2026-08-12.md)

---

## Scale

Every frame except `01` is drawn at a uniform **0.5×** of its logical pixel size, so any two
frames are directly comparable by eye. Logical pixels are what the game lays out in —
`backing size ÷ content_scale_factor` — not device pixels. Frame `01` is the true-relative-scale
reference at 0.20×.

## The six viewports

| Logical | Class | Aspect | Control region |
|---|---|---|---|
| 360 × 640 | Compact | 9:16 | yes — the ratified design floor |
| 393 × 852 | Compact | 19.5:9 | yes — measured real phone |
| 852 × 393 | Medium | 21:9 | yes — 4:3 view + two side columns |
| 768 × 1024 | Medium | 3:4 | yes — tablet, proportionally smaller band |
| 1024 × 768 | Expanded | 4:3 | no — desktop |
| 1280 × 720 | Expanded | 16:9 | no — desktop |

## Reading a frame

| Element | Means |
|---|---|
| Heavy outer stroke | the physical screen |
| Plain fill | the game view — the Godot canvas; all engine UI lives here |
| Diagonal hatch | the control region — dead space the game view declined |
| Dashed inset | the safe area; interactive content insets to it, art bleeds past |
| Amber fill on a row | the focused row; `▸` is the focus ring in controller mode |
| `[name]` in amber | the `theme_type_variation` role that paints that region |
| Dashed red outline | a state that is opt-in, or a defect being fixed |
| Red `!` beside a row | reachability risk — applies live, then confirms in 15s or reverts |

## Contents

| File | Screen | Viewport |
|---|---|---|
| `01_…true-relative-scale` | — | all six, to scale |
| `02`–`07` | Main Menu | 360×640, 393×852, 852×393, 768×1024, 1024×768, 1280×720 |
| `08`–`13` | Campaign Library | 360×640, 360×640 opt-in, 852×393, 768×1024, 1024×768, 1280×720 |
| `14`–`21` | Settings | section index, Display page, **confirm-or-revert dialog**, opt-in, 852×393 tabs, 768×1024 tabs, 1024×768 pack-themed tabs, 1280×720 tabs |
| `22`–`27` | Map HUD | 360×640, 393×852, 852×393, 768×1024, 1024×768 layout editor, 1280×720 |

Settings carries eight frames rather than six: it is paged by section (`UUI-19`), it is the
only dual-themed screen (`UUI-16`), and it owns the confirm-or-revert safety net (`UUI-18`).

## Status

This is the **proof set** (`UUI-17`) — four screens chosen because between them they exercise
every archetype: a plain menu, a list/detail record screen, the worst-case settings list, and
the map HUD with its control region. The remaining nineteen built screens are drawn to these
conventions once the proof set is accepted.

Five screens are deliberately absent — shop, convoy, reference compendium, credits and
dialogue. `UUI-15` holds them until their research sessions run; the agenda is
[`../registers/unbuilt_screen_research_agenda_2026-08-12.md`](../registers/unbuilt_screen_research_agenda_2026-08-12.md).

The **campaign editor** was the sixth. It is now drawn, in
[`albums/campaign_editor_shell_album.html`](albums/campaign_editor_shell_album.html) — but
ahead of the gate, not through it: `UBS-8` and the `UUI-15` hold release only when the whole
`CEUI` walk closes, and it has not. The editor is also outside the six viewports above; it is
Expanded-only at a `1920 × 880` effective floor (`[CEUI-5]`, `[CEUI-S2]`) and carries its own
scale and density tokens (`[CEUI-S1]`), so none of the proof set's viewport table applies to it.

**These frames are specifications, not screenshots.** Where a frame and the shipped build
disagree, the frame is the target and the difference is work.

## Regenerating

The frames are authored in the album page and extracted from it, so the album and the files
cannot drift. Re-extract after editing the album rather than editing an SVG by hand.
