# All-Band Initial UI Designs Review (2026-06-30)

**Scope:** UI-facing designs across Bands 1-8 in the control plane and their
source docs. This review collects the initial UI surfaces to review before they
turn into implementation plans, with extra attention to user-provided themes,
user-provided assets, shared reusable assets, and safe defaults.

## Executive Summary

The docs already point in the right direction: one PHB panel framework, one
shared selector/input path, one effect forecast family, one dialogue/activity
stage model, and self-contained campaign packs with raw-loaded user assets.

Main risk: later features may build private panels, private selectors, or
hardcoded asset assumptions. The UI plan should define shared theme and asset
resolution rules before Band 4-6 panels multiply.

## Cross-Cutting UI Theme And Asset Recommendations

### Theme Contract

Create a data-driven `UiThemeDef` / `PresentationTheme` registry instead of
hardcoded theme switches. A theme should be presentational only, matching
`PHB-6`; mechanics stay on panels, rules, predicates, and resources.

Suggested fallback chain:

1. Panel/activity explicit theme override.
2. Progression node `theme`.
3. Campaign default theme.
4. Shipped default campaign theme copied into `user://`.
5. Engine fallback Theme and placeholder assets.

Each theme should provide optional ids/paths for:

- panel frame/stylebox, background, accent colors, fonts, button/icon atlas;
- prep/hub background art and optional music;
- dialogue/activity stage defaults;
- cursor and selection/highlight styling;
- condition/effect/resource icon sets.

Do not make a closed enum for theme ids. Theme ids are authored data and should
resolve through the same registry/validation path as other author-facing
vocabularies.

### Asset Resolution

Use string ids/paths and a shared resolver for user assets. This matches
`ICO-5/6`: all campaign content is copied to `user://`; art is raw-loaded via
`Image.load_from_file` -> `ImageTexture`; empty or missing item icons remain
valid.

Recommended defaults:

- missing item/weapon icon -> text-only row plus generic item icon if a layout
  requires an image;
- missing portrait -> class/faction silhouette or neutral speaker plate;
- missing dialogue/background art -> live map background or neutral prep
  background;
- missing panel skin -> default `UiThemeDef`;
- missing resource/effect icon -> text label plus generic token;
- missing activity sprite -> generated placeholder tile/sprite, with validation
  warning;
- missing sound/music -> silent fallback, not load failure unless marked
  required by content.

### Reusable UI Assets

Treat these as shared components before feature plans multiply:

- `PanelSelector` for PHB service panels such as convoy, shop, loadout, training,
  recruitment, and PvP buy screens.
- `SelectionCursor` / input-context owner for More Info, forecast, terrain pages,
  and gamepad wiring.
- `EffectForecastPanel` for Source+Style, utility staves, action grants,
  conditions, and AoE/multi-target previews.
- `StagePresentation` for dialogue, activity intros/outros, avatar scenes, and
  future cutscenes.
- `AssetResolver` for icons, portraits, backgrounds, activity sprites, fonts,
  sounds, and user-uploaded avatar art.
- Registry-owned display metadata (`label_key`, `icon`, `help_key`,
  `default_value`) for resources, effects, panels, actions, and predicates.

## Band UI Inventory

### Band 1 - Campaign And Save Gate

- **Initial UI surfaces found:** campaign selector, rules screen with mandated
  locked values and editable defaults, Continue/Load, manual save, suspend,
  victory/defeat flow.
- **Source docs:** campaign save player-facing firming and technical plan.
- **Review note:** campaign/rules screens should already consume theme tokens
  and registry display metadata. User campaigns need their own name, icon,
  banner/background, and fallback image.

### Band 2 - Shared Runtime Contracts

- **Initial UI surfaces found:** no main player panels, but resource ledger
  quotes, projection/forecast output, action/effect validation, and registry
  display metadata feed later UI.
- **Source docs:** registry manifest, resource ledger, projection forecast,
  action/effect contracts.
- **Review note:** do the display metadata here so later panels do not invent
  labels/icons/help text locally.

### Band 3 - Core Authoring Foundations

- **Initial UI surfaces found:** PHB prep/on-map panel container, text-key seam,
  CampaignRules/tunable selection, calendar/date presentation hooks, resource
  display metadata.
- **Source docs:** `PHB-1..7`, Band 3 implementation plan.
- **Review note:** `theme`/`location_label` should resolve through the theme
  registry. The PHB container should accept panel ids and panel data schemas,
  not branch by hardcoded panel type.

### Band 4 - Campaign Loop Vertical Slice

- **Initial UI surfaces found:** convoy panel, shop panel, dialogue v1 overlay,
  doors/chests/village activation prompts, recruit talk/recruit flow,
  difficulty/death-mode selection, prep/deployment, conditional promotion UI.
- **Source docs:** Band 4 handoff, convoy plan, shop plan, dialogue register.
- **Review note:** convoy/shop already call for rough keyboard+mouse PHB panels
  plus a shared selector/detail-pane. Keep item row fields author-selected, use
  item/resource icons when present, and fall back to text-only rows.

### Band 5 - Tactical V1 Enrichment

- **Initial UI surfaces found:** condition/status display, duration labels,
  skill/effect display, loadout cap panel, Source+Style action/source/style
  selection, generalized effect forecast, action-grant preview, secondary
  movement affordance, utility staff forecast.
- **Source docs:** Source+Style player flow, loadout cap register, action-grant
  register, condition/duration control-plane rows.
- **Review note:** this band needs a shared combat-action UI language. Effects,
  conditions, resources, source/style costs, and gates should render from
  registry metadata and icons, with text fallback. Do not let utility staves,
  action grants, and combat arts each build a different forecast panel.

### Band 6 - V1-Lean / Stretch

- **Initial UI surfaces found:** campaign import/export and status-record
  picker, rescue/carry affordances, fog/discovery display, property capture
  progress/action panel, relationship minimum screen/hooks, bonus EXP/training
  panels, map readability overlays, input/gamepad/keybinding/settings, web debug
  touch shell, sprite importer tool UI.
- **Source docs:** campaign status/property plan, MRD/TUR designs, input-mode
  and selector plans, bonus/training registers.
- **Review note:** this is the largest UI debt band. Campaign import/status UI
  needs clear compatible/incompatible/default states. Property capture and
  training should reuse PHB panel controls and resource icons. Map overlays
  should theme colors through tokens while preserving accessibility contrast.

### Band 7 - Optional After Stable Core

- **Initial UI surfaces found:** broken weapon display/repair affordance, arena
  risk/bet/cash-out panel, battalion attach/resource/gambit UI, stationary
  weapon targeting/ammo, forging service, PvP map selector/buy phase/standings,
  property recruitment/production stores, AI recruitment admin/debug needs.
- **Source docs:** BEA, PVP, battalion, stationary weapon, broken weapon, and
  campaign status/property docs.
- **Review note:** most of this should be reuse. Arena and PvP should consume
  PHB panels and the existing resource/roster selector stack. Forging needs a
  design pass before any UI plan.

### Band 8 - Post-v1 / Parked

- **Initial UI surfaces found:** ActivityRunner viewport/templates, public
  campaign builder/authoring GUI, content resync/compatibility report, remote
  play lobby/controller UI, Laguz/Awakening supplement UI, hex topology map
  affordances, perception/forecast-fidelity UI, ML evaluation tooling, Vision
  Pro presentation.
- **Source docs:** minigame runtime research, activity initial specs, designer
  authoring contract, content resync contract, online decisions.
- **Review note:** activities and builder are asset-heavy. They need the same
  theme, asset resolver, validation report, and fallback placeholder system as
  gameplay panels. Public scripting remains parked; templates should be plain
  data with validated sprite/sound/background refs.

## Review Questions For UI Planning

1. **Theme schema:** What fields must the first `UiThemeDef` include for PHB,
   dialogue, activity, and map overlays without over-designing?
2. **Asset ids:** Should UI assets be referenced by raw path, asset id, or both?
   Recommendation: authors use ids where reuse matters; ids resolve to raw paths
   in the campaign pack.
3. **Required vs optional assets:** Which UI assets are hard errors when missing?
   Recommendation: almost none. Prefer validation warnings plus defaults except
   for assets that a specific authored activity marks required.
4. **Shared selector ownership:** Does Band 4 `PanelSelector` become the seed of
   the Band 6 selector/input work? Recommendation: yes.
5. **Icon rendering timing:** ICO reserves item/weapon icons before UI rendering.
   Which panel first consumes them? Recommendation: convoy/shop rows, because
   they benefit most while still allowing text-only fallback.
6. **Dialogue/activity stage reuse:** Should activity intros/outros reuse DLG
   stage elements? Recommendation: yes, via a presentation primitive that is not
   coupled to dialogue speakers.
7. **Author preview hooks:** Which panels need previews before commit?
   Recommendation: shops/training/loadout/source-style/arena/PvP buy all need
   quote/preview hooks from resource ledger and projection contracts.

## Immediate Recommendations

1. Add a thin `UiThemeDef`/asset-resolution design note before more PHB panels
   are planned.
2. When drafting Band 4-6 panel plans, require a "theme/assets/defaults" section
   that names user-provided assets, reusable assets, and fallbacks.
3. Keep `theme` cosmetic. Do not encode discounts, stock, objectives, or rules in
   skins/backgrounds.
4. Make every growing UI vocabulary a registry: panel types, activity types,
   resource icons, effect icons, condition icons, source/style display families,
   and theme ids.
5. Build tests for missing asset fallbacks early. They will prevent user packs
   from crashing because a portrait, icon, or background is absent.

