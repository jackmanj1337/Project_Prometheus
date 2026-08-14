---
Type: design
Status: Shell drawn as ruled, interiors drawn as frames; all ten findings now ruled (EW-10 built; EW-1..9 by [CEUI-S50])
Last verified: 2026-08-14
Tracker: DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Campaign Editor — Shell and Lifecycle Wireframes

## What this is

Eleven lifecycle states, seven workspaces and three display viewports of the campaign editor,
drawn against the Section A rulings that closed on 2026-08-14. Twenty-eight frames, all produced
by one `render(cfg)` function from one token table, so changing a ruling redraws the set instead
of requiring frames to be edited by hand.

- Album source:
  [`../wireframes/albums/campaign_editor_shell_album.html`](../wireframes/albums/campaign_editor_shell_album.html)
  — self-contained, opens in any browser.
- Drawn against
  [`../registers/campaign_editor_ui_open_questions_2026-08-12.md`](../registers/campaign_editor_ui_open_questions_2026-08-12.md)
  — `CEUI-1/3/4/5/7/8` and the owner rulings `[CEUI-S1]`–`[CEUI-S13]`.

**Status.** The *shell* is drawn as ruled. The *interiors* are drawn as frames and marked with a
dashed red outline wherever a region's position and role are settled and its contents are not.
Sections B–F of the register (`CEUI-9–12, 17–21, 23–31, 33–36, 39, 40`) and the twelve `NMTE`
residues scheduled as `S11` are unwalked; nothing in this set may be read as answering them.

**The lifecycle has no entry transition.** An earlier draft opened on a *this will end your run*
confirmation, drawn from `[CEUI-S9]` call 2's quit-to-shell framing. `[CEUI-S13]` removed it by
moving the entry point: the editor is offered **only from the main menu**, where no pack is active,
so it never ends a run. Call 2's requirement survives as a **precondition** on the entry point
rather than as editor behaviour — and `EW-10` records that the precondition is ratified
(`[CSA-28]` clause (f)) and not yet built.

**This is not a gate being met.** `UBS-8` lifts and the `UUI-15` album hold releases only when the
whole `CEUI` walk closes, which it has not. Wireframing the shell ahead of that was an owner
decision, and the session note records it as such.

## Dependency position

This consumes ratified decisions rather than reopening them:

| Decision | What it fixes here |
|---|---|
| `CEUI-1` (option A) | Tree / centre / Inspector / bottom panel, with the editor exempt from the `EPUX-03` pane budget |
| `CEUI-3` (option B) | Tabbed documents; each tab an independent `[CEUI-S6]` transaction |
| `CEUI-4` (option A) | Fixed layout, resizable and collapsible regions, never rearrangeable in v1 |
| `[CEUI-5]` + `[CEUI-S2]` | `1920 × 880` **effective** floor; below it, the explanatory minimum-size state |
| `[CEUI-S1]` | The editor's own scale, font size and density settings — a fourth token column |
| `[CEUI-S3]` | Test is an embedded playable session: a snapshot, two themes, stated keyboard owner |
| `[CEUI-S4]` | Web is lesser on durability only; the standing export recommendation ships |
| `[CEUI-S5]` | Raw JSON as a **peer** view, on every platform |
| `[CEUI-S6]` | Staged transaction per document; file-touching operations excluded from Undo |
| `[CEUI-S8]` | Id rename confirmed per rename, with a recovery snapshot |
| `[CEUI-S9]` | Strict editor/library separation; two export destinations |
| `[CEUI-S10]` | Export-back forks the id; the manifest gains an optional author |
| `[CEUI-S11]` | Header labels always, scrolls on overflow |
| `[CEUI-S12]` | Seven workspaces: Content, Maps, Graph, Assets, Localization, Test, Release |
| `[CEUI-S13]` | The editor is main-menu-only, so there is **no** entry transition and no entry confirmation |

## The display model, which is the answer to "FHD, UHD and 4K"

`[CEUI-S2]` measures the floor as `window ÷ editor scale`. `[CEUI-S1]` makes that scale the
editor's own. Combining them with the constraint that editor type should never be *physically*
smaller than an FHD display at 100% shows it gives one expression:

```
max effective viewport = physical resolution − (chrome allowance × DPR)
```

The consequence is that a display's **physical** resolution, not its CSS window and not its OS
scale setting, bounds how much editor an author can have. Two displays reporting identical CSS
windows are not equivalent — the 4K one can trade its scale knob for room and the FHD one cannot.

Three results fell out and drive the whole set:

1. **A 4K display at Windows' default 200% scaling produces exactly the floor window.** The same
   `1920 × 880` an FHD display gives at 100%. The floor was derived from FHD; 4K lands on it by
   arithmetic.
2. **4K at 150% and QHD at 100% are the same window**, so the entire FHD/QHD/4K range reduces to
   **three** distinct effective viewports: `1920 × 880`, `2560 × 1240`, `3840 × 1960`.
3. **The one configuration that fails outright is FHD at 125%** — a common Windows default on 1080p
   laptops — and it fails on *height*, by 216 px, not on width.

**Vertical room grows faster than horizontal** as displays grow, because the chrome allowance is a
fixed subtraction rather than a proportion. That is why panel defaults in this set are driven by
height and not by width.

## Four width responses, one per kind of content

The editor is a single size class, so extra width cannot be answered with a breakpoint. It is
answered by what the content *is*:

| Response | Rule | Workspaces |
|---|---|---|
| **Canvas fills** | Takes all remaining space. More width is more map, more graph. | Maps, Graph |
| **Grid reflows** | Fixed tile size, column count grows. Never a stretched tile. | Assets |
| **Form caps** | Single-column forms cap at an 880 px measure and centre; above 2400 px of centre a second document column is offered. | Content, Release |
| **Table extends** | Fixed key column, locale columns added until width runs out. | Localization |
| **Simulator is fixed** | Sized by the *simulated* size class, not the editor. Extra width becomes surround. | Test |

The last row is the one most likely to be got wrong. `[CEUI-S3]` put a real playable session inside
the editor and `[CEUI-S2]` made the editor's scale independent of it, so the embedded game view
derives its size class from its **sub-viewport**. Stretching that view to fill a 4K editor would
silently change the size class the author believes they are previewing — the exact failure
`[DLUX-15]`'s per-size-class preview obligation exists to prevent. Measured in the album: the
`1280 × 720` preview reaches 1:1 at the QHD viewport and must not grow beyond it.

## Findings — ten, all ruled 2026-08-14

Full options and recommendations are in Sheet 7 of the album. **`EW-1`–`EW-9` were ruled by
`[CEUI-S50]`** in the `S11` sitting, each taking the recommendation below; `EW-10` is built
(`CampaignManager.quit_to_shell()`). Summarised:

| Id | Finding | Recommendation |
|---|---|---|
| `EW-1` | Nothing bounds how far **down** the editor scale knob may go. Clearing the floor on a 1366×768 laptop costs 36% of physical type size. | Allow it, but warn below `DPR × scale = 1.0` using the confirm-or-revert `[CEUI-S1]` already inherited |
| `EW-2` | The floor is a *working layout* on FHD and a *minimum* on everything else, so every above-floor affordance is invisible to the typical author | Design content-kind responses, and require every above-floor affordance to be **additive**, never a relocation |
| `EW-3` | The three-viewport collapse depends on the 200 px chrome allowance being right | Keep 200 for design; **measure the real window** for the gate |
| `EW-4` | At the floor the document area is **552 px** tall with the panel open — nineteen rows | Default the panel by height, not globally; do **not** shorten the chrome |
| `EW-5` | The bottom panel's span and default state are unruled, and the workspaces want different answers | Centre column only, default per workspace |
| `EW-6` | Four pieces of state have nowhere to live, including **which context owns the keyboard** | A 22 px status bar |
| `EW-7` | The split view above 2400 px is new, but built from ruled primitives | Offered and remembered, never automatic |
| `EW-8` | Two themes render simultaneously; `[UUI-9]`/`[UUI-13]`'s metrics/paint split becomes load-bearing | Not a design choice — a **test obligation** |
| `EW-9` | A 24 px minimum target assumes an input device that is stated but not enforced | Keep 24, warn on non-kbm input; reachability is `CEUI-40`'s job, not target size |
| `EW-10` | `[CEUI-S13]`'s entry precondition is ratified (`[CSA-28]` clause (f)) and **unbuilt** — `deactivate_campaign_package()` has no production caller | Not a design question: give it a caller, and **assert** at editor entry rather than assuming |

## The proposed editor token column

`[CEUI-S1]` ruled the editor is a fourth `DENSITY_TOKENS` column plus its own multiplier through
the same assembler, following `[UUI-11]`'s precedent. It did not fill the column in. Sheet 8 of the
album proposes the values every frame was laid out from, alongside the real `touch` and
`controller` columns read from `scripts/autoloads/ResponsiveLayout.gd`, plus six editor-only tokens
with no game analogue (`workspace_bar`, `tab_height`, `tree_width`, `inspector_width`,
`form_measure`, `split_threshold`).

`min_target` is the one needing an owner's eye — proposed at 24 against touch's 44 and controller's
0. See `EW-9`.

## What this set does not draw

Deliberately, and per the closing note of the `S10` session:

- **Inspector interiors** — `CEUI-9–12`, unwalked.
- **Map and graph tool interiors** — `CEUI-23–25`, unwalked.
- **Issue presentation, severity and gates** — `CEUI-17–20`; the precedence diff found these are
  already ruled in three other places, so guessing here would create a fourth.
- **Asset manager interiors** — `CEUI-33–36`, found by the diff to be a layout problem awaiting
  assembly.
- **Search** — the twelve `NMTE` residues scheduled as `S11`.

> **All five are now ruled — `S11` closed the walk on 2026-08-14.** Inspector interiors by
> `[CEUI-S23]`, map and graph tools by `[CEUI-S30]`–`[CEUI-S32]`, issues and gates by `[CEUI-S26]`/
> `[CEUI-S27]`, asset manager interiors by `[CEUI-S36]`–`[CEUI-S39]`, search by `[CEUI-S43]`/
> `[CEUI-S44]`. This set is **not** revised to include them: the frames it draws are correct as
> drawn, and interiors are a **new drawing pass** with `[CEUI-S50]`'s ruled token column and its
> `EW-4`/`EW-5`/`EW-6` panel, status-bar and height rules as its metrics.

## Regenerating

The album is hand-authored but programmatic: edit `T` (the token table), `geom()` or `render()` in
the album's `<script>` and every frame redraws. Captions carry `{{placeholder}}` substitutions
filled from the same geometry the frame was laid out from, and the anatomy sheet measures the
mounted DOM, so a caption cannot drift from the drawing it describes.

To open it locally, wrap the body fragment as described in
[`../wireframes/albums/README.md`](../wireframes/albums/README.md).
