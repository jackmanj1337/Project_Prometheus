# Planning Backlog — Items Needing Implementation-Ready Plans (2026-06-20)

Status: Active — planning queue
Last verified: 2026-06-21

Upcoming roadmap items that do **not** yet have an implementation-ready plan or design
doc. **None of these are blocked from *planning*** by the current execution blockers (no
live screen; no `gh`/token for the `main` PR merge) — planning is docs-only. They are the
candidates for the next planning session(s). Indexed from `AGENT/GDD/GDD_10_Roadmap.md` →
*Open Items Register*.

> **Already plan-ready (excluded from this list):** M8 (full `ConditionManager` spec +
> enforcement hooks + checklist), M9a/M9b, M10, M11, M12, M13 (full specs in GDD_10);
> v0.2.3 (implemented — live-verify only); the Debug Web build
> (`handoff_2026-06-20_web_debug.md` — 4 slices + decisions, ready to execute after v0.2.3).

For each item: **State** = what exists today; **Plan should produce** = the deliverable a
planning session would write.

---

## 1. Input / controls cluster — highest near-term leverage

Sequenced right after the Debug Web build; the gamepad layer is the keystone for Steam
Deck + phone-controller + virtual-gamepad + web shell. Entirely docs-only to plan.

- **Input-mode / gamepad implementation plan. ✅ DECISIONS + GAMEPAD ARM DONE (2026-06-20j).**
  - The 4 open decisions are resolved (see `input_mode_architecture_design_2026-06-20.md`
    → Resolved decisions) and the **gamepad arm** has a full impl plan:
    `gamepad_layer_implementation_plan_2026-06-20.md` (action map, focus wiring, bindings,
    analog repeat, `input_mode_changed` seam, 4 slices, test plan).
  - **Broader resolver — ✅ PLAN DRAFTED (2026-06-21):**
    `AGENT/Docs/input_mode_resolver_implementation_plan_2026-06-21.md` (Auto/Touch/K&M
    detect-floor + conditional-promotion resolver, gray/back-door availability, the
    `[controls]` persistence + `mouse_cursor` relocation, and the DoD#2 `check_docs` guards
    for the `input_mode` / `touch_controls` value-sets). **Decisions resolved 2026-06-21**
    ([ICD-1] new `InputModeManager` autoload, [ICD-2] resolver = gamepad slice 3, [ICD-3]
    touch-first detection) — **build-ready**; slice 1 (persistence + guards) has no
    dependency. See `AGENT/Docs/input_controls_open_decisions_2026-06-21.md`.
- **V021-15 — shared selector extraction. ✅ DESIGN DONE (2026-06-20j):**
  `AGENT/Docs/shared_selector_extraction_design_2026-06-20.md`.
  - Was: three surfaces navigate independently (sheet grid, forecast F-cycle, terrain
    F-paging); no extraction design. It is the single joypad-wiring point.
  - Produced: scope = extract a `SelectionCursor` navigation core + an input-routing/arbiter
    convention (NOT a unified render widget); rendering stays per-surface; per-consumer
    adoption notes + headless test plan. Implements with the gamepad layer.
- **Key rebinding UI. ✅ PLAN DRAFTED (2026-06-21):**
  `AGENT/Docs/key_rebind_ui_implementation_plan_2026-06-21.md` — capture-UI flow, conflict
  handling, reset, per-device-slot model (so a K&M rebind can't wipe the pad binding), and
  composition with the input-mode setting. **Decisions resolved 2026-06-21** ([ICD-4]
  per-device slots, [ICD-5] all actions rebindable + always-on Reset + human-readable cfg +
  capture-any-device-now, [ICD-6] swap on conflict) — **build-ready**; slices 1–2 (persistence
  foundation + K&M rebind UI) have no remaining dependency. See
  `input_controls_open_decisions_2026-06-21.md`.
- **Gamepad binding audit.**
  - State: Platform Targets says "audit all actions for joypad events" — no plan; zero
    `InputEventJoypad*` bindings exist today.
  - Plan should produce: the per-action audit + binding scheme (folds into the input-mode plan).

## 2. Campaign / save cluster — gates the 1.0 campaign (D-D)

Larger; build from `campaign_rules_firming_notes_2026-05-25.md` (has open questions).

- **CampaignRules contract + wiring into `GameState`.** State: stub class exists
  (`exp_gaining_factions`), fields still loose on `GameState`, firming notes open. Plan
  should produce: the full per-save rule schema (default + adjustable/locked per rule),
  the `GameState` migration, and the snapshot-serializer changes.
- **Between-map save / load.** State: backlog bullet. Plan should produce: the JSON
  save schema + load flow + where it sits relative to the suspend save.
- **Pre-battle deployment + convoy/trade + recruit (D-D prerequisites).** State: bullets,
  "design together" intent, no plan. Plan should produce: one canonical roster/inventory
  flow spanning deployment, convoy, trade, and the green→player recruit mechanic.
- **Mid-battle suspend save.** State: field list in the backlog, no plan. Plan should
  produce: the serialization plan (incl. activation-scheduler state) + the M15B disconnect
  save-and-continue tie-in.

## 3. Release gates needing a plan (not just execution)

- **D-A — public-identity rename.** State: gate, no plan. Plan should produce: the
  placeholder→project-owned name mapping table + the data-pass scope/order (faction, class,
  item names, GDD prose, data strings).
- **DOC-012 / OPEN-12 — legal/licensing.** State: blocking pre-1.0 gate, no research doc.
  Plan should produce: source-corpus license research + attribution-strategy decision.
- **OPEN-5 — broken-weapon degraded mode.** State: optional-rule bullet. Plan should
  produce: the rule design + likely `CampaignRules` toggle.

## 4. UI / UX enhancements — backlog bullets, no plans

Range-on-hover overlay; movement path arrows; **individual unit threat range (now a
prerequisite — the gamepad contextual R3 danger-zone is gated on it; see
`gamepad_layer_implementation_plan_2026-06-20.md` §4)**; grid-visibility
slider; camera settings (edge-pan buffer + scroll responsiveness); attack-by-target
selection; richer combat prediction (crit / triangle / effective flags); combat-prediction
layout; minimap toggle. Each needs a short design before scheduling; several pair naturally
(hover overlays + threat range + path arrows form one "map readability" plan).

## 5. Other systems — backlog bullets, no plans

Fog of war / LoS; rescue & carry; doors & chests (Pick/Unlock/Key); additional AI profiles
(territorial, guard_tile, healer, boss); stationary weapon interaction (Ballista/Onager);
cap-management UI (manual skill swap, `max_inventory` trade UI); FE map sprite importer
productionization (4 decisions already noted in the backlog); `DataManager._ready()`
decomposition (named phases sketched, no full plan).

## 6. Maps

Maps 002–005 authored against the M16 objective condition types (Seize, Boss Defeat,
Escape, Survive/Defend).

---

## Recommended next-session focus

**§1 planning is now COMPLETE (drafted 2026-06-21).** The bulk landed 2026-06-20j; the two
remaining plans were drafted 2026-06-21, both decision-free:

1. **Broader input-mode resolver plan** — `input_mode_resolver_implementation_plan_2026-06-21.md`.
2. **Key-rebind UI plan** — `key_rebind_ui_implementation_plan_2026-06-21.md`.

Every choice those two plans could not make was consolidated in
`input_controls_open_decisions_2026-06-21.md` and **all resolved 2026-06-21** (ICD-1..6;
ICD-7 is tune-live, non-blocking). **§1 is now fully build-ready** — both plans have a
no-dependency first slice. The next §1 step is **execution**, not planning.

After §1, the next planning cluster is **§2 Campaign / save** (gates the 1.0 campaign, D-D).

> Superseded recommendation (kept for provenance): the original text here recommended
> starting §1 from the input-mode 4 decisions → V021-15 design → gamepad audit; all of that
> is now done (2026-06-20j).
