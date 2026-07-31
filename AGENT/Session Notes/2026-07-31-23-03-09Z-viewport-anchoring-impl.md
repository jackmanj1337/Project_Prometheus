# Session Note - 2026-07-31 — Viewport anchoring implementation

## Branch context

- Branch: `agent/from-integration/viewport-anchoring`
- Base branch: `agent/from-integration/viewport-aspect-decisions` (sibling off `agent/integration`)
- Base SHA: `d1302b729519e074756968ea3af7ba72bdfa3e22`
- Coordination Work ID: `IMPL-VIEWPORT-ANCHORING-2026-07-31`

## What was done

Opened `IMPL-VIEWPORT-ANCHORING-2026-07-31`, the first slice of the UI/UX pass, implementing
the viewport **expand** model from the owner-ratified `UI-VIEWPORT-ASPECT-2026-07-31`.

**Sequencing decisions (this session, owner-confirmed):**
- Branch base: **sibling off `agent/integration`** (via the decisions branch), independent of
  the still-open text-entry branch. Both edit `SettingsManager.gd` but in different sections
  (`[display]` vs `[controls]`); the tracker `dependencies` link records the coordination and
  clears the `check_tasks` path-overlap via its existing `depends_on` exemption.
- Menu-scale reconciliation: **menus keep a fixed on-screen size** (menu factor divided by the
  global content factor), not the single-knob collapse.

**Slice 1+2 (committed, done):** viewport config + `content_scale_factor` setting + menu-scale
reconciliation. Combined into one commit because the factor apply and the menu-scale division
share a single source of truth (`_apply_menu_scale` / `factor_from_settings`), so splitting them
would leave a knowingly-broken intermediate (oversized menus or a changed default view).

Key findings:
- Headless probe reproduced design-doc §C.1 exactly (factor 1.0 → 30×16.9 @1080p / 40×22.5
  @1440p; identity diagonal 1.5 @1080p and 2.0 @1440p both → 20×11.2).
- The aspect flip collapsed the headless logical viewport to the real 64×64 window (12 suites
  failed), because tests implicitly relied on `keep`'s fixed base. Fixed centrally with a
  **headless fallback** in `_apply_content_scale` (keep + project base when
  `DisplayServer.get_name() == "headless"`) — production never ships headless, so it is
  unaffected, and `root.size` pinning is unusable (headless reclaims it to 64×64 after a frame).
- `check_docs` E5 (render-config) enforced `aspect="keep"`; flipped it to `expand` (DoD#2).

**Slice 3 (committed, done):** the anchoring refactor. Replaced MenuScale's imperative
`_recenter` with declarative scene anchors (center preset + `grow_both`); content-grow panels
are content-sized, scroll-frame panels use `custom_minimum_size` sized to fit the 1280x720
minimum reference viewport. Deleted `_recenter`, `_on_centered_target_resized`, the
re-entrancy/resize-hook meta machinery, and the now-vestigial `centered` param across 9 scenes
+ 8 scripts. Subtleties resolved: (1) the aspect flip meant scroll panels lost `_recenter`'s
viewport-cap — fixed by sizing frames within the min reference viewport; (2) Godot only lays
out visible nodes, so the V026-01a test now shows the panel before measuring (it reaches
content width when visible); (3) Promotion/Reclass have an internal follow-focus OptionsScroll,
so they keep a fixed frame rather than pure content-grow.

## Commits claimed

- `8c92b879693c308ae0391f756b686fd8c28def9a` — Viewport expand model: content_scale_factor setting + menu-scale reconciliation
- `32c28fcaa62fa21f1cddcbb7116a9da8b1eee5be` — Anchoring refactor: declarative menu centring, retire MenuScale._recenter

## Gates

- `bash run_tests.sh` — PASS, all suites green (also run inside pre-commit).
- `test_settings_manager` — 36 passed, 0 failed (+1 new content-scale test).
- `python3 AGENT/Docs/check_docs.py` — PASS (E5 now guards `expand`).
- `bash scripts/ci/check_gdscript_style.sh` — PASS (257 files).
- Headless viewport probes: scratchpad `viewport_probe.gd` / `vp_stable.gd` (not committed).

## Next

- Slice 4: resolution / resize write-back rework (presets + free resize). Rework
  `applied_windowed_size()`'s 16:9 request clamp and the `_requested_window_size` /
  `_last_window_mode` maximize-vs-edge-drag detection, which lean on the `keep` contract.
- Slice 5 (pixel-snap: `snap_2d_transforms_to_pixel`; content_scale_factor x zoom check),
  Slice 6 (design floor + GDD/roadmap DoD#1 + tracker `playtest_ref`).
- Task stays `in_progress`: a real visual pass (16:9 / Deck / ultrawide / web, 100%/200%
  screenshots) is owner-return-gated and cannot run headless. The scroll-panel frames were
  sized to a 1280x720 min reference; the design floor (Slice 6) should ratify that minimum.
