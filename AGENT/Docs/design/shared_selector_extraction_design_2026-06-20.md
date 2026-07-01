---
Type: design
Status: Target design
Last verified: 2026-07-01
---

> **Band split (2026-07-01, review decision Q11).** **Component 1 (`SelectionCursor`,
> the pure navigation core) is pulled forward into Band 4** and becomes the core
> that the Band 4 `PanelSelector` (convoy/shop) is built on — one navigation core,
> proven by convoy/shop first. **Components 2 & 3 (the input-context owner / arbiter
> "Rebuild C" and the joypad-wiring point) stay in Band 6 (`B6-INPUT`)**, gated on
> the input-mode-architecture + gamepad-layer keystone that convoy/shop do not need.
> Band 6 EXTENDS — never replaces — the `PanelSelector` API and adopts this same
> cursor core across the three More-Info surfaces. This resolves open question #3
> below (yes, another selection model — `PanelSelector` — wants the same core).
> Source: `AGENT/Code Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md`.

# Shared Selector / More-Info Navigation Extraction (V021-15) — Design — 2026-06-20

Status: Target design
Last verified: 2026-06-20

Coupled work:
- `AGENT/Docs/design/input_mode_architecture_design_2026-06-20.md` (this is the single
  joypad-wiring point that design depends on; gamepad layer = keystone)
- `AGENT/Docs/archive/plans/more_info_mode_plan_2026-05-24.md` (the original More Info host pattern)
- `AGENT/Docs/design/terrain_more_info_paging_design_2026-06-19.md` (surface 3 today)

> **Tracking home:** `AGENT/GDD/GDD_10_Roadmap.md` → v0.2.1 findings **V021-15** and
> *Open Items Register* §B / §H. No code changes yet — this pins the component contract
> before the gamepad layer is built so the three surfaces are refactored once, correctly.

## Why this exists

Three More-Info surfaces each navigate independently today. The gamepad layer (zero
joypad bindings exist project-wide, verified 2026-06-20) needs **one** place to attach
d-pad / stick navigation. Extracting the shared navigation contract is that single
wiring point; without it, gamepad support would be wired three times.

## The three surfaces, as they actually are (read 2026-06-20)

| | Sheet grid (`UnitDetailsScreen`) | Forecast (`AttackPreview`) | Terrain (`HUD`) |
|---|---|---|---|
| State | `_entries[]` of `{category,key,title,row,col}` + `_current_index` (-1) | `_entries[]` of `{side,key,title}` + `_current_index` (-1) | `_terrain_more_page:int` (-1 hidden / 0 / 1) |
| Navigation | **2-D**: flat `_move_selection(±1)` + grid `_move_vertical(±1)` | 1-D forward-only `_cycle_more_info` | 1-D forward-only `cycle_terrain_more_page` |
| Backward | yes (cursor keys) | no | no |
| Presentation | mark a row with `▶ ` + detail in side panel | swap detail in side panel | swap a whole page (subset of rows), auto-size |
| "Off" state | index -1 = nothing selected | index -1 = nothing selected | page -1 = panel hidden |
| Input layer | `_input` (preempts focus nav) | `_unhandled_input` | `_unhandled_input` + `_higher_priority_more_info_visible()` gate |
| Trigger | `more_info` + `cursor_*` | `more_info` | `more_info` (arbitrated) |

**Finding:** these are two *presentation* patterns — a **selector** (pick one item,
mark it, show detail: surfaces 1 & 2) and a **pager** (step whole-panel views with an
off state: surface 3) — over **one** navigation pattern (an ordered cursor that advances
on an action, wraps, has an inactive/-1 state, and notifies on change). Unifying the
*rendering* is the over-abstraction trap (it fights the 2-D grid and the pager and would
be a heavy retrofit on the fixed-frame Settings / UnitDetails panels). Unifying the
*navigation + input* is exactly and only what gamepad wiring needs.

## Scope (decided 2026-06-20j)

Extract the **navigation core + input-routing/arbiter contract**. Rendering stays
per-surface. (Alternatives weighed and rejected: full unified render widget — fights the
grid/pager; input-contract-only — leaves three copies of wrap/inactive logic, no headless
test win; selector-for-1&2-only — terrain still needs separate joypad wiring.) The
input-layer standardization + the `more_info` arbiter are **in scope** here, because they
*are* the joypad-wiring boundary — splitting them out would split the one thing this
extraction exists to unify.

## Component 1 — `SelectionCursor` (pure logic)

A small `RefCounted` (no scene, no `Node`), owning an index over N items. Headless-unit-
testable; carries no rendering.

```
class_name SelectionCursor extends RefCounted

signal changed(index: int)          # emitted on every successful move (incl. to -1)

var index: int = -1                 # -1 = inactive / nothing selected / hidden
var _count: int = 0
var _cols: int = 1                  # 1 for 1-D consumers; grid width for the sheet
var _wraps: bool = true
var _has_inactive: bool = false     # true → -1 is a real stop in the cycle (terrain Hidden)

func configure(count: int, cols: int = 1, wraps := true, has_inactive := false) -> void
func advance(delta: int) -> void    # forward/back cycle; first move from -1 lands on 0 or last
func move_2d(row_delta: int, col_delta: int) -> void   # grid move; col-nearest on row change
func reset() -> void                # index = -1 (no signal unless it changed)
```

- **`advance`** is the shared `more_info` / `cursor_left|right` step. Wrap policy and the
  "-1 → first/last" first-press behaviour come straight from the existing
  `_move_selection`. When `has_inactive` is true the cycle includes -1 as a stop (terrain:
  Hidden → 0 → 1 → Hidden), reproducing `cycle_terrain_more_page` exactly.
- **`move_2d`** generalises `UnitDetailsScreen._move_vertical` (land on the entry in the
  target row whose column is nearest). 1-D consumers never call it.
- The cursor knows nothing about *what* an index means — the consumer maps index → render.

## Component 2 — input-routing + arbiter convention

Two rules, replacing today's ad-hoc split:

1. **One interception layer.** A More-Info surface that must beat Godot focus navigation
   (the sheet's `cursor_*`) handles in `_input` and calls `set_input_as_handled()`;
   `more_info`-only surfaces may stay in `_unhandled_input`. Document this as the rule so
   new surfaces are consistent (the dual-UI-tax constraint from the input-mode design).
2. **One arbiter.** Generalise `HUD._higher_priority_more_info_visible()` into a single
   "who owns More-Info input right now" check so exactly one surface consumes `more_info`
   / `cursor_*` at a time (sheet > forecast > terrain, matching today's de-facto order).
   This is the contract the gamepad layer's focus-grab subscribes to on
   `input_mode_changed`.

### Absorbs the gamepad plan's "Rebuild C" (input-context owner)

The gamepad layer plan (`AGENT/Docs/plans/gamepad_layer_implementation_plan_2026-06-20.md` §2/§5)
deferred its structural input fix to here, because it is the same job as the arbiter above.
Today the "only one context is live" guarantee rests on a single `MapCursor._input_suppressed`
bool **plus** per-menu `set_input_as_handled()` discipline — fragile, because a menu that
ever stops consuming `cursor_*` would double-step once the gamepad binds d-pad to both
`cursor_*` and `ui_*`. Rebuild C replaces that with an **input-context owner / stack** that
guarantees exactly one of {map cursor, modal menu, More-Info selector} is live. With that in
place, the custom menus (`ActionMenu` / `ItemMenu` / `WeaponMenu`) can drop their manual
`_move_focus` / `_focused_idx` and move to **native Godot focus** (`ui_*`), since the owner —
not per-menu consumption — enforces exclusivity. The arbiter in rule 2 is the More-Info slice
of that same owner. Scope this together with the `SelectionCursor` extraction so the input
layer is rebuilt once.

## Component 3 — the joypad-wiring point

Because all three surfaces now route navigation through `cursor_*` + `more_info` via the
arbiter, gamepad support attaches in **one** place: add `InputEventJoypadButton` /
`InputEventJoypadMotion` events to the existing `cursor_up/down/left/right`, `more_info`,
`confirm`, `cancel` actions in `project.godot`. No per-surface joypad code. (Glyph/prompt
swapping is a separate polish follow-up per the input-mode decisions; this design only
guarantees the single attach point exists.)

## How each consumer adopts it

- **`UnitDetailsScreen`** — replace `_current_index` + `_move_selection` + `_move_vertical`
  with a `SelectionCursor` (`cols` = grid width, `wraps`, no inactive stop). `changed`
  drives `_refresh_highlight` + `_show_entry`. The pair-jump (`next_unit/prev_unit`) and
  `more_info`/`cancel`/`inspect_unit` toggles are unchanged.
- **`AttackPreview`** — replace `_current_index` + `_cycle_more_info` with a 1-D cursor
  (`cols=1`, no inactive). `changed` drives `_show_entry`. Click-select sets `index`.
- **`HUD` terrain** — replace `_terrain_more_page` with a cursor (`count=2`, `cols=1`,
  `has_inactive=true`). `changed` drives `_render_terrain_page` (index -1 hides the box).
  `cycle_terrain_more_page()` stays as the public entry point (V021-17 calls it) but
  delegates to `cursor.advance(1)`.

## Headless test plan

- New `test_selection_cursor.gd` — the pure-logic core: forward/back wrap; first-move
  from -1 → first/last; `has_inactive` cycle includes -1 (terrain Hidden parity);
  `move_2d` column-nearest landing + row clamp/wrap; `changed` fires only on real change.
- Update the three existing suites (`test_unit_details_screen`, `test_attack_preview_selector`,
  `test_hud`) to assert behaviour is preserved after each consumer swaps to the cursor —
  these are the regression guard for "refactor changes nothing observable."
- Focus-grab / highlight visuals and the live d-pad feel stay **live-verify** (gamepad
  milestone), not headless.

## Definition of done (when implemented)

- DoD#1: this is a refactor — if any observable navigation behaviour changes, update the
  affected GDD section and flip the V021-15 roadmap status in the same commit. Pure
  extraction (no behaviour change) only flips the status.
- DoD#2: no new value-set/path/header rule is introduced by the extraction itself, so no
  new `check_docs.py` guard is required here. (The gamepad `input_mode` / `touch_controls`
  guards are owned by the input-mode workstream.) If the arbiter priority order is written
  as a checkable rule, add its guard then.
- Sequencing: lands **with** the gamepad layer (it is that layer's prerequisite wiring
  point), after the input-mode impl plan resolves the layer's shape.

## Open questions (resolve at implementation)

1. **Owner of the arbiter** — a free function/static on a small helper, or a method on an
   existing autoload (`EventBus`/HUD)? Lean: static helper queried by each surface, to
   avoid a new autoload.
2. **`SelectionCursor` location** — `scripts/ui/` (UI-only use) vs `scripts/core/`. Lean:
   `scripts/ui/` since all three consumers are UI.
3. **Does `MapCursor`'s own selection model want the same core?** Out of scope for V021-15
   (map-tile cursor is a different interaction), but note it as a possible later consumer.
