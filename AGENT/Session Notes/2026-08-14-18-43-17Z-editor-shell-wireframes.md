# Session Note - 2026-08-14 (editor shell wireframes)

## Branch context

- Branch: `agent/integration`
- Base branch: `agent/integration`
- Base SHA: `18765ac89bd2e96dffa65ef6d67952f3a02ad00b`
- Coordination Work ID: `DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31`

## What was done

Took the previous session's stated next action — **generate editor wireframes** — and drew the
shell end to end. **Twenty-nine frames: twelve lifecycle states, the seven workspaces, and the
shell at all three display viewports.** No decisions were made; the album consumes
`[CEUI-S1]`–`[CEUI-S12]` and raises nine findings for the owner rather than answering anything.

**The set is programmatic, not hand-drawn.** Every frame comes from one `render(cfg)` over one
token table, so changing a ruling redraws the album instead of requiring frames to be edited
individually. Captions carry `{{placeholder}}` substitutions filled from the same `geom()` the
frame was laid out from, and the anatomy sheet measures the mounted DOM — a caption structurally
cannot drift from the drawing it describes. Verified headless: 29 frames, 30 sheets, no console
errors, no unfilled measurement slots, no horizontal body scroll.

**The display question had an exact answer, and it was worth deriving before drawing.**
`[CEUI-S2]` measures the floor as `window ÷ editor scale`; `[CEUI-S1]` makes that scale the
editor's own. Adding one constraint — never render editor type physically smaller than an FHD
display at 100% shows it — collapses the whole thing to
`max effective = physical resolution − (chrome × DPR)`. **A display's physical resolution, not its
CSS window and not its OS scale setting, bounds how much editor an author can have.** Three
consequences drove the set:

1. **4K at Windows' default 200% scaling produces exactly the floor window** — the same `1920×880`
   an FHD display gives at 100%. The floor was derived from FHD and 4K lands on it by arithmetic.
2. **4K at 150% and QHD at 100% are the same window**, so the entire FHD/QHD/4K range reduces to
   **three** effective viewports, not a continuum. That is why the album has three width columns.
3. **The one configuration that fails outright is FHD at 125%** — a common Windows default on 1080p
   laptops — and it fails on *height*, by 216 px, not on width.

**Extra width is answered by content kind, because a single size class has no breakpoint to use.**
Four responses, and every workspace is one of them: **canvas fills** (Maps, Graph), **grid
reflows** (Assets), **form caps** at an 880 px measure (Content, Release), **table extends**
(Localization) — plus **simulator is fixed**, which is the one most likely to be implemented wrong.
`[CEUI-S3]`'s embedded session derives its size class from its *sub-viewport*, so stretching the
game view to fill a 4K editor would silently change the size class the author believes they are
previewing. That is the exact `[DLUX-15]` failure the per-size-class obligation exists to prevent.
Measured: the `1280×720` preview reaches 1:1 at the QHD viewport and must stop there.

**Nine findings, `EW-1..9`**, each with options and a recommendation in the register's format so
they can be walked rather than re-derived. Two are load-bearing. **`EW-1`: nothing bounds the
editor scale knob's *lower* end.** `[CEUI-S2]` narrowed `[CEUI-5]`'s cost paragraph by naming the
knob as the remedy for the 1366×768 author — but clearing the floor there requires `0.64×`, at
which editor type is 64% of the physical size FHD@100% shows. Recommended: allow it, warn below
`DPR × scale = 1.0` using the confirm-or-revert dialog `[CEUI-S1]` already inherited, because a
fixed stop cannot tell a low-DPI laptop from a legible high-DPI display at the same scale value.
**`EW-8`: two themes render simultaneously**, which turns `[UUI-9]`/`[UUI-13]`'s *metrics are
computed, paint is authored* from a principle into a test obligation.

**Measured at the floor, and it is the tightest number in the set:** the document area is
`1260 × 552` — **nineteen rows** at the editor pitch, in the workspace where records are authored,
on the display class the floor was derived from. `EW-4` recommends defaulting the bottom panel by
height rather than shortening the chrome, because merging the workspace bar into the header
guarantees `[CEUI-S11]`'s scroll fires at the only viewport the editor has, in every locale.

**Two things the album proposes that no ruling supplies.** The **editor token column** —
`[CEUI-S1]` ruled the fourth `DENSITY_TOKENS` column exists and did not fill it in; Sheet 8 gives
the values every frame was laid out from, beside the real `touch`/`controller` columns read from
`ResponsiveLayout.gd`, plus six editor-only tokens with no game analogue. And a **status bar**,
because four pieces of state have nowhere to live — including *which context owns the keyboard*,
`[CEUI-S3]` point 4, which must be visible outside the Test workspace precisely because the
arbitration problem exists when focus is somewhere unexpected.

**Discipline held on the unwalked half.** Sections B–F and the twelve `NMTE` residues are drawn as
*frames* with a dashed outline naming the open question — Inspector (`CEUI-9–12`), map/graph tools
(`CEUI-23–25`), issue presentation (`CEUI-17–20`), asset manager (`CEUI-33–36`). The issue panel
in particular was left blank on purpose: the precedence diff found its severity model and gates are
already ruled in three other places, so guessing would have created a fourth.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`. Documentation only; no code changed. The album,
the design doc, the control-plane and register pointers, and the two wireframe README updates.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` then `python3 AGENT/Docs/check_docs.py` — **PASS (44
  checks)**. The first run failed check 30 (`active-doc-ownership`) until the new design doc was
  named in the Project Control Plane; that is the check doing its job, not a workaround.
- Headless render verification via the workspace Playwright harness — 29 frames, 30 sheets, **no
  console errors**, zero unfilled `data-out` measurement slots, `bodyScrollX: false`.
- No code changed. `ResponsiveLayout.gd`'s `DENSITY_TOKENS` were **read** to source Sheet 8's
  `touch` and `controller` columns — not modified.
- Album published as an Artifact and the URL recorded in `albums/README.md`, per the convention
  that the repo copy is the source of truth and the published page is a convenience.

## Next

**`S11` — the second half of the `CEUI` walk:** Sections B–F residues (`CEUI-9–12`, `17–21`,
`23–31`, `33–36`, `39`, `40`) and the twelve `NMTE` questions. The wireframes are input to it, not
a substitute: every dashed region in the album is one of those questions.

**Walk `EW-1..9` alongside it.** They are shell questions and belong with the shell rulings, not
with the interiors. `EW-1` and `EW-3` are the two that change what gets built rather than how it
looks — the scale knob's lower bound, and whether the floor gate tests the *real* window or the
pessimistic 200 px chrome constant.

**Still owed from the previous session**, unchanged and not picked up here: a successor row for the
separately distributed curated UI element combinations (`[CEUI-S7]`), and `[L10N-16]`'s
pseudolocale-capture boundary between the Localization and Test workspaces (`[CEUI-S12]`). The
album makes the second one concrete — the `pseudo` column is drawn in Localization and the capture
control is drawn in Test, which is exactly the ambiguity `[CEUI-S12]` left unstated.

**`UBS-8` has still not lifted** and the `UUI-15` album hold has not released. Drawing ahead of the
gate was an owner decision; it is recorded as such in the album, the design doc and the register.
