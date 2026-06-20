# Planning Backlog — Items Needing Implementation-Ready Plans (2026-06-20)

Status: Active — planning queue
Last verified: 2026-06-20

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

- **Input-mode / gamepad implementation plan.**
  - State: architecture design exists (`input_mode_architecture_design_2026-06-20.md`) but
    has **4 unresolved open decisions** and no build/test plan.
  - Plan should produce: resolve the 4 decisions (default touch style; `mouse_cursor` cfg
    location / `[input]` section; glyph swapping scope; Deck aspect), then a sliced build
    plan + headless test plan for the detect-floor/conditional-promotion resolver and
    gray/fallback logic, plus the DoD#2 `check_docs` guard spec for `input_mode` /
    `touch_controls` value-sets.
- **V021-15 — shared selector extraction.**
  - State: three surfaces navigate independently (sheet grid, forecast F-cycle, terrain
    F-paging); no extraction design. It is the single joypad-wiring point.
  - Plan should produce: a component design (focus model, input contract, how each of the
    three consumers adopts it) so the gamepad-binding work has one wiring point.
- **Key rebinding UI.**
  - State: `SettingsManager.rebind_action` exists; the capture UI does not; backlog bullet only.
  - Plan should produce: capture-UI flow (conflict handling, reset-to-default, persistence)
    and how it composes with the input-mode setting.
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

Range-on-hover overlay; movement path arrows; individual unit threat range; grid-visibility
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

**The input/controls cluster (§1).** It is fully unblocked (docs-only), the highest
near-term leverage (keystone for every non-keyboard platform), and sequenced right after
the Debug Web build. Suggested order: resolve the input-mode 4 open decisions → write the
**V021-15 shared selector extraction design** (the concrete first artifact and the single
joypad-wiring point) → fold the key-rebind UI + gamepad binding audit into the input-mode
implementation plan.
