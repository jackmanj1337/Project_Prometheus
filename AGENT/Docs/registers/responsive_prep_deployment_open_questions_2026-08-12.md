---
Type: register
Status: OPEN — research prepared, owner walk not started
Last verified: 2026-08-12
Register: RPD-1..18
Tracker: RESPONSIVE-PREP-DEPLOYMENT-RESEARCH-2026-08-12
---

# Responsive Prep and Deployment — Owner Questions

Research: [Responsive Prep and Map Deployment](../design/responsive_prep_deployment_comparative_research_2026-08-12.md)

## Composition and navigation

### [RPD-1] Is the map the persistent primary surface at every size class?

**Recommendation:** yes. Compact changes the adjacent controls into sheets; it does not
replace the map with a menu during routine deployment.

### [RPD-2] Should Compact use three bottom-sheet pages: Units, Unit and Mission?

**Recommendation:** yes. They cover selection, contextual configuration and battle context
without introducing a second navigation hierarchy.

### [RPD-3] Should Medium tablet keep a persistent drawer while Medium landscape overlays a drawer only inside the game-view rectangle?

**Recommendation:** yes. The landscape control columns are reserved and must never be
covered; tablet portrait has enough width for a persistent secondary surface.

### [RPD-4] Should Expanded use roster / map / selected-unit panes simultaneously?

**Recommendation:** yes, with Mission and Readiness folded into header/footer at the
1024×768 boundary and expanded into their own regions at FHD.

### [RPD-5] What maximum workspace width should FHD and 4K use?

**Recommendation:** token-scaled sidebars with a bounded central workspace; allow the map to
grow to a configured ceiling and use remaining width as breathing room, not longer rows.

## Roster and placement

### [RPD-6] Does Manage Roster own who deploys while Map Preview owns where?

**Recommendation:** yes, with both editing one live `DeploymentPlan`.

### [RPD-7] What is the fastest substitution gesture for each input family?

**Recommendation:** select placed unit, choose replacement from roster/bench, confirm once;
touch may drag only as an optional shortcut, never as the sole accessible route.

### [RPD-8] How are two occupied starting tiles swapped?

**Recommendation:** select source then destination, with a visible swap preview and a
controller/touch-neutral `Swap` action.

### [RPD-9] Are empty deployment slots warnings or neutral capacity?

**Recommendation:** neutral unless a campaign rule requires an exact count. Do not imply the
player is wrong for deploying below the cap.

### [RPD-10] How are required, excluded, dead and otherwise unavailable units represented?

**Recommendation:** separate status glyph + text vocabulary, with required preselected,
excluded/dead unavailable but inspectable, and no reliance on color alone.

## Information and configuration

### [RPD-11] Which selected-unit actions belong in the quick card?

**Recommendation:** Loadout, Skills, Details and Swap. Class change, convoy-wide work and
other deep configuration stay behind Manage Roster's open panel registry.

### [RPD-12] Which mission facts remain visible without opening Mission?

**Recommendation:** objective, defeat condition and exceptional deployment constraint;
terrain, threats, rewards and chests live in the Mission surface.

### [RPD-13] How should enemy ranges and terrain inspection behave during prep?

**Recommendation:** reuse map inspection vocabulary, with independent threat overlays and a
clear return to placement mode so inspection never accidentally moves a unit.

### [RPD-14] Should unit configurations or whole deployment plans be reusable presets?

**Recommendation:** research before committing. Player feedback supports reducing repeated
configuration, but presets introduce invalidation rules when roster, class, items or map
start tiles change.

## Readiness, exceptional state and persistence

### [RPD-15] Is Begin Battle always visible, even when invalid?

**Recommendation:** yes. Keep it focusable and expose a player-facing unmet reason rather
than hiding it or presenting an inert disabled control.

### [RPD-16] What happens when a required unit is permanently dead or otherwise unavailable?

**Recommendation:** content validation should prevent impossible authored states where it
can; runtime must show the specific contradiction and use an author-selected fallback or
block, never silently drop the requirement.

### [RPD-17] How do Retry and suspend-resume enter prep?

**Recommendation:** campaign Retry restores map-start state and previous plan before prep;
bare-map Retry remains direct. A suspend payload must be cleared through an explicit safe
transition or prep must be skipped—never allow a plan that spawn ignores.

### [RPD-18] What deployment state survives leaving prep, saving, resizing or changing input mode?

**Recommendation:** resize/input/theme changes preserve the live plan, selection, focused
unit and open information surface. A between-map campaign save does not persist the plan;
returning later authors it again from the current campaign state.
