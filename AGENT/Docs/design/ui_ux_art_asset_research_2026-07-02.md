---
Role: dated
Type: design
Status: Reference / research (not a spec)
Last verified: 2026-07-02
---

# UI/UX & Art-Asset Design Research — For the Eventual UI/UX Pass

**Started:** 2026-07-02.
**Status:** Reference / research (not a spec). External-practice research on how UI/UX and
its accompanying art assets are designed and used in tactics/SRPG games, gathered to inform the
eventual UI/UX pass. It **does not decide anything** — the internal architecture stance already
lives in `AGENT/Code Reviews/band_ui_initial_designs_review_2026-06-30.md` (theme registry,
asset resolver, fallbacks) and the `[ICO-1..6]` campaign-asset decisions. This note supplies the
genre conventions and production workflow those plans should be measured against.

---

## A. Why this note exists

We are a grid tactics / SRPG in the Fire Emblem lineage. Players arrive with **strong genre
expectations** about what information the screen owes them and where it lives. The eventual UI/UX
pass is cheaper and better if we (1) honor those conventions instead of reinventing them, and
(2) understand how the art assets behind them are actually produced, so our raw-loaded,
author-supplied asset model (`[ICO-5/6]`) lines up with how artists ship UI.

---

## B. Genre conventions our players already expect

These are the load-bearing SRPG UI surfaces. Treating them as first-class (they map onto our
`EffectForecastPanel` / registry-metadata plan) means players read our game for free.

- **Combat forecast / info window.** Select attacker → target and a stat window previews the
  exchange *before commit*: both units' names (ally blue / enemy red), equipped weapon, resulting
  HP, hit%, damage, crit%, and follow-up. First appeared in FE *Genealogy*; now universal. This is
  exactly our projection/forecast contract rendered as UI.
- **Follow-up / multiplier badges.** A small `x2` (double attack / brave) or `x4` marker on the
  damage number, rather than a second line of text. Compact encoding of a rule the player must
  see at a glance.
- **Danger / threat range.** A toggle that paints the union of all enemy reachable-attack tiles so
  the player can position and bait. (We already have `[individual_threat_range]` design.)
- **Weapon-type color coding.** Weapon/affinity types get a consistent color + icon (FEH: sword=red,
  lance=blue, axe=green) reused everywhere the type appears — advantage arrows, unit cards, forecast.
  One icon/color per vocabulary entry, resolved from data, not redrawn per screen.
- **Unit info panel + map menu.** A persistent-but-dismissable panel for the selected unit
  (stats, equipped, status), and a context menu anchored to the cursor for actions.
- **Tuck-away rule.** Information the player needs *when they need it*, hidden otherwise. SRPG
  screens are dense; the craft is progressive disclosure (tabs, tooltips, "More Info" paging — we
  already do this for terrain), not cramming everything into one frame.

## C. UI/UX design principles (tactics-specific)

- **Clarity over immersion.** Strategy/stat-heavy games lean almost entirely **non-diegetic** —
  players need exact numbers instantly; readability beats in-world flavor. (Diegetic/meta framing is
  a garnish, not the substrate, for a game like ours.)
- **Visual hierarchy by size + color + position.** Critical values (HP, hit%, the forecast result)
  render larger and higher-contrast than secondary detail. Size is the primary hierarchy lever.
- **Safe zones.** Pin persistent HUD to screen edges/corners; keep the board center clear for the
  tactical view. Matters doubly for our mobile-web target (`[mobile_web_lens]`) where thumbs occlude
  corners and text must survive scaling.
- **Introduce complexity in layers.** Break multifunction screens into simple ones; don't surface a
  mechanic's UI before the mechanic is taught.
- **Consistency = a token system.** Same panel frame, same icon language, same spacing everywhere.
  This is *why* the internal review pushed a `UiThemeDef` token registry rather than per-panel skins.

## D. How the art assets are actually produced (the pipeline)

Understanding this makes our asset contract match how artists deliver:

- **Nine-slice (9-patch) panels.** Panel/box/button/tooltip backgrounds are drawn once as a small
  bitmap divided into 4 corners + 4 edges + 1 center; the engine stretches edges/center but keeps
  corners crisp at any size. This is the standard way one small asset skins arbitrarily-sized panels.
  Godot has native `NinePatchRect` / `StyleBoxTexture` — the theme registry should reference these.
- **Icon sets from a vector source.** Icons (weapon types, conditions, resources, effects, item
  categories) are authored in a vector tool with a shared grid, stroke weight, and corner radius,
  then exported to a **texture atlas / sprite sheet** (PNG w/ transparency, padded to avoid MIP
  bleed) for runtime batching. One atlas → fewer texture swaps.
- **Fonts.** Either rasterized-to-atlas at fixed sizes (pixel/bitmap fonts, common in retro SRPGs)
  or **SDF/MSDF** fonts that scale cleanly to any resolution. Given our display-scaling work and
  web target, SDF is the safer default for body text; a bitmap face is fine for a stylized title.
- **Cursors, selection/highlight, portraits, map sprites** are their own asset classes with their
  own fallbacks (silhouette/neutral plate for a missing portrait, generated placeholder for a
  missing sprite) — the `AssetResolver` already anticipates this.
- **Reference tooling.** The **Game UI Database** (gameuidatabase.com) is the standard screenshot
  reference library for studying how shipped games lay out these surfaces — useful during mockups.

**Fit with our model:** all of the above is just **string-id/path → resolved texture**, which is
exactly `[ICO-5/6]` (copy campaign pack to `user://`, raw-load art via
`Image.load_from_file → ImageTexture`, empty/missing icons stay valid). Nine-slice frames, icon
atlases, and fonts should be *authored assets referenced by the theme registry*, with engine
placeholders as the terminal fallback. No closed enum of theme/asset ids — same open-registry rule
as everything else.

## E. The design workflow (do this before building panels)

Standard order, and the reason the internal review said "write a thin `UiThemeDef` note *before*
Band 4-6 panels multiply":

1. **Mood board** — a collage that fixes the visual vibe (palette, type, framing) *before* layout.
2. **Wireframe** — greybox blueprint of each surface: what info is on it, hierarchy, flow. No art.
3. **Mockup** — the wireframe skinned with the mood-board style; the first "what it looks like".
4. **Prototype** — interactive, to validate the flow feels right.
5. **Asset production + implementation** — cut the nine-slices/icons/fonts to the mockup; build.

Skipping straight to implementation is the expensive mistake: you discover the information
architecture problems (what SRPG players need on screen) only after the art is committed.

## F. Implications for our eventual UI/UX pass

1. **Wireframe the SRPG staples first** (forecast, threat range, unit panel, map menu) as the shared
   vocabulary; feature panels (shop/convoy/loadout/forge) inherit from it.
2. **Author one icon/color per registry entry** (weapon/affinity types, conditions, resources,
   effects) and render it everywhere from metadata — never redraw per screen.
3. **Theme = nine-slice frames + atlas + font + palette tokens**, resolved through `UiThemeDef` with
   the documented fallback chain; keep it cosmetic (no rules in skins).
4. **Design to safe zones and scaling from day one** given the mobile-web/display-scaling targets.
5. **Every UI vocabulary stays an open registry**, matching the project's core architecture rule.

---

## Sources

- [UI and UX in Tactical Games: Three Considerations — Games R UX / Medium](https://medium.com/games-r-ux/ui-and-ux-in-tactical-games-three-considerations-82c546e9e48)
- [Game UI: design principles, best practices, and examples — Justinmind](https://www.justinmind.com/ui-design/game)
- [The 4 Types of Game UI: Diegetic vs Non-Diegetic — Superfiles](https://superfiles.in/game-ui-design-guide-diegetic-spatial.php)
- [Diegetic vs Non-Diegetic UI: The 4-Type Framework — Nasty Rodent](https://nastyrodent.com/diegetic-and-non-diegetic-ui/)
- [Combat forecast — Fire Emblem Wiki](https://fireemblemwiki.org/wiki/Combat_forecast)
- [Danger Radius — Fire Emblem: Three Houses (SuperCheats)](https://www.supercheats.com/fire-emblem-three-houses/walkthrough/danger-radius)
- [Weapon Triangle — Fire Emblem Wiki (Fandom)](https://fireemblem.fandom.com/wiki/Weapon_Triangle)
- [What Is Nine Slice And How Does It Work? — GameMaker](https://gamemaker.io/en/blog/slick-interfaces-with-9-slice)
- [How to Make Pixel Art Game Assets — Pixnote](https://pixnote.net/en/learn/game-assets/)
- [Graphic and font assets preparation — Unity Manual](https://docs.unity3d.com/6000.4/Documentation/Manual/best-practice-guides/ui-toolkit-for-advanced-unity-developers/graphic-and-font-assets-preparation.html)
- [Game UI Database](https://www.gameuidatabase.com/)
- [How to Create a Mood Board for UI/UX — Halo Lab](https://www.halo-lab.com/blog/mood-board-design)
- [How can you use wireframes to plan game UX design? — LinkedIn](https://www.linkedin.com/advice/1/how-can-you-use-wireframes-plan-game-ux-design-skills-game-design-xaske)
