---
Role: dated
Type: register
Status: RESOLVED 2026-08-08 — CAU-1..10 and CAU-1A..1C; CAU-4 amended 2026-08-13
Last verified: 2026-08-13
Register: CAU-1..10
---

# Combat Actions UX — Owner Questions

Companion research:
[`combat_actions_ux_research_2026-08-08.md`](../design/combat_actions_ux_research_2026-08-08.md).
All mechanics named here are already governed by their mechanical registers. These questions
settle presentation and interaction only.

### [CAU-1] One action menu or family submenus? — **RESOLVED**

Always enter an action through the predictable staged sequence `action → source → method →
targeting`. Once targeting/forecast opens, it becomes an editable workspace: the player may
cycle any compatible source, method, or target and the complete preview updates live. Preserve
every selection that remains legal; if a change invalidates another field, rewind only to the
earliest unresolved stage. This establishes the interaction shape without yet deciding the
cycling controls or every invalidation edge case.

#### [CAU-1A] Which forecast fields receive direct cycling controls? — **RESOLVED**

Expose direct previous/next controls for source and method, while target, destination, and area
changes remain on the map cursor. Show a cycling control only when at least two compatible values
exist.

#### [CAU-1B] What happens when a live change invalidates another selection? — **RESOLVED**

Preserve every still-valid selection. When a source change invalidates the selected method, fall
back to the new source's declared default method. If the resulting source/method combination
invalidates the target, select the legal target with the shortest map distance from the previous
target; break ties by shortest distance from the acting unit, then deterministic map reading order
(top-to-bottom, then left-to-right). Source/method combinations with no legal targets remain
visible but disabled in staged menus and are skipped by forecast cycling. If changing game state
nevertheless leaves the current combination targetless, retain its source and method, clear its
target, and show the invalid reason.

#### [CAU-1C] May live cycling change the top-level action family? — **RESOLVED**

No. Group ordinary unit actions under three sturdy intent-based families: `Attack` for primarily
hostile effects, `Assist` for beneficial/repositioning effects, and `Item` for direct inventory
use or mutation. Reserve `Interact` as a distinct future family whose contents will be defined in
the map-interaction packet. Authored objective commands such as `Escape` and `Seize` remain
contextual, individually named top-level entries rather than being hidden under `Interact`.
Objective commands come from an open registry, not a hardcoded list. Source, method, target, and
destination are editable inside a forecast, but live cycling never crosses its selected family or
objective command; changing that top-level choice returns to the action stage.

### [CAU-2] Target-first or destination-first displacement? — **RESOLVED**

Select the affected target first, then the destination when the rule admits more than one legal
result. Auto-select and advance when exactly one destination exists; omit the destination stage
when the selected participants fully determine the result, as with a basic swap.

### [CAU-3] How are area actions previewed? — **RESOLVED**

Tint every affected tile, distinguish the selected origin/center, and outline every affected unit
the player can currently see. The forecast shows visible ally/enemy summary counts plus a
scrollable per-target outcome list; selecting a unit on the map and its outcome row highlights the
other. On smaller surfaces, show the summary and selected target first and open the complete list
on demand. Affected unseen tiles may be tinted, but neither their markers nor the summary may
confirm hidden occupancy; describe possible undisclosed effects generically. Harmful friendly
fire receives a strong warning outline and requires explicit confirmation.

### [CAU-4] When is confirmation required? — **RESOLVED**

The forecast is always shown, but every additional confirmation step is controlled by player game
rules. Previews emit open confirmation tags rather than hardcoding action kinds; the initial tags
are `ordinary_action`, `limited_resource`, `multiple_targets`, `friendly_fire`, `relocation`,
`inventory_mutation`, `objective_action`, and `unusual_uncertainty`. Provide `Minimal` (no extra
confirmation), `Recommended` (friendly fire, limited resources, inventory mutation, and objective
actions), `Always`, and per-tag `Custom` presets. These are global player settings with an optional
campaign/run override. Disabling an extra confirmation never removes the forecast or changes an
action's legality.

> **Amended 2026-08-13 — confirmation authority is split by origin.** `CAU-4` as written let the
> `Minimal` preset strip an authored confirmation, which `[EPUX-06]` forbids as **raise-only** and
> `[TSV-21]` re-affirmed five days after `CAU-4` was ruled. The conflict existed independently of any
> packet. **Ruling:** an author's confirmation predicate on a specific action is a **floor no player
> setting can lower**; the presets above govern the **engine-derived tag set only**. Nothing else in
> `CAU-4` changes.
>
> **Amended 2026-08-13 by `[DRC-14]` — three tags added.** The engine-derived tag registry gains
> `recruitment` (allegiance or controller change), `custody_change` (capture, release, transfer), and
> `execution` (permanent unit removal). Three separate tags, not one combined transition tag, because
> they have three distinct reversibility profiles — a player may set `Always` on execution while
> leaving recruitment at `Recommended`. Custody is deliberately independent of allegiance
> (`[RCR-5]`). Per the split above, `Minimal` still strips all three: a campaign that needs execution
> always confirmed authors the predicate on the action.

### [CAU-5] How is uncertainty written? — **RESOLVED**

The registered preview handler uses the execution rules and only viewer-permitted information to
emit the strongest truthful detail level: `exact` when every relevant input is known and
deterministic; `distribution` when all outcomes and probabilities can be calculated safely;
`bounded` when guaranteed limits are known but probabilities are unavailable, too expensive, or
disclosive; and `qualitative` when even numeric bounds would leak information or safe simulation
is unavailable. The record carries outcomes/bounds, cause, and an open fallback reason such as
`hidden_information`, `runtime_only_effect`, `calculation_budget`, or `authored_uncertainty`.
Compact layouts may collapse but never reduce the available evidence. A missing or broken preview
handler is a repair error that disables the action; it is not presented as uncertainty.

### [CAU-6] Do non-strike actions use attack choreography? — **RESOLVED**

No choreography is inferred from the top-level family or target relationship. Each authored action
explicitly selects a registered kind such as `strike`, `displacement`, `state_change`, `transfer`,
or `area_cast`, with future kinds supplied through the open registry. A nonstandard action may
explicitly request `strike` when it genuinely fits, but refresh, repair, shove, rescue, and similar
actions never inherit run-in/impact motion merely because they share a menu or affect an enemy.
Kinds share CFB callouts and logging while retaining their own motion and timing.

### [CAU-7] What does cancellation restore? — **RESOLVED**

Back unwinds navigation stages rather than each live forecast edit: extra confirmation → forecast
→ destination/area (when separate) → target → method → source → action → map control. Returning
to a menu highlights its current selection; clearing the current stage preserves every earlier
valid choice. Forecast cycling does not add undo steps. No cost is spent or reserved and no history
is written before final confirmation. Back from extra confirmation preserves the forecast; after
execution begins, cancellation is unavailable and the separate rewind system owns reversal.

### [CAU-8] How are carry state and refreshed state shown afterward? — **RESOLVED**

Reuse the existing status/condition badge system for refreshed state, with its source, effects,
and expiration in the character sheet; normal ready/selectable presentation still communicates
whether the unit can act. Reuse and generalize the Pair Up UI for rescue, capture, and future
registered carried-unit relationships. Show summary counts per relationship type and cycle through
individual carried-unit records using the participant controls; every entry retains identity,
portrait, relationship type, restrictions, and relevant state. Counts summarize but never replace
the individual list. Runtime mechanics own capacity and restrictions while the UI accepts any
number returned. Transient CFB callouts/logging supplement rather than replace this evidence.

### [CAU-9] Where do costs and item mutations appear? — **RESOLVED**

Show every applicable cost in the live forecast beside the source or method that incurs it, using
explicit before→after values that update when source, method, or target changes. Text plus an icon
warns when a source will break, empty, or be consumed; colour is never the only evidence and an
inventory row never simply disappears. Unaffordable options remain visible but disabled with the
exact unmet requirement. After resolution, the unified CFB log records the actual mutations.

### [CAU-10] What is the controller focus order? — **RESOLVED**

Focus follows `action → source → method → target → destination/area` when required → forecast →
optional confirmation. Source and method remain explicit focused stages even with one usable entry.
Targeting stages move focus to the map cursor; forecast cycling updates without stealing that
focus. Back reverses the same order, cancel returns to the acting unit, and reopened menus restore
their selection and scroll position. Disabled entries accept focus to expose their unmet reason
but cannot be confirmed. Mouse/touch interaction updates the same logical controller focus.
