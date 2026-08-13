---
Type: implementation plan
Status: Active — re-derived 2026-08-13 against the RESOLVED DRC-1..33 register and DLUX-1..16
Last verified: 2026-08-13
Decision source: ../registers/dialogue_recruit_capture_research_questions_2026-07-27.md
Tracker: SYS-DIALOGUE-CONVERSATION-2026-07-23, SYS-RECRUIT-CAPTURE-2026-07-23, DRC-PLAN-REDERIVATION-2026-08-13
---

# Dialogue, Recruitment, Capture, Trade, and Prison — Integrated Implementation Plan

> **Re-derived 2026-08-13, clearing the `Needs revision` marker raised the same day.** The
> `Decision source` register now reads `RESOLVED` — `DRC-1..33` was walked across four sittings —
> and this plan has been reconciled against those rulings, against `DLUX-1..16` (ratified
> 2026-08-09, cited zero times by the previous revision), and against the three precedence diffs
> [`skf_drc`](../design/skf_drc_precedence_diff_2026-08-13.md),
> [`drc_group_a`](../design/drc_group_a_precedence_diff_2026-08-13.md) and
> [`drc_groups_bcde`](../design/drc_groups_bcde_precedence_diff_2026-08-13.md). The
> section-by-section divergence list lived in
> [`drc_plan_rederivation_handoff_2026-08-13.md`](drc_plan_rederivation_handoff_2026-08-13.md) and
> is discharged here.
>
> **What changed structurally**, and is the short list a slice author must not un-learn: the
> transition request is a **sparse patch over five dimensions and nothing else** (`DRC-20`,
> `DRC-23`), replacing `[RCV-4]`'s retired `recruit(unit)` contract; **`custody_status` is
> authoritative and carry is derived** (`DRC-29`); capture is **registered methods folded into the
> existing `DRC-13` interaction entry** (`DRC-27`); the transition attaches to the **opportunity**,
> not the unit (`DRC-25`); Trade commits **one transaction per swap** over `[EPUX-24]`'s core
> (`DRC-30`); the transition record **references** the item-instance ledger rather than copying it
> (`DRC-33`); and the action journal is a **consumer** of the general staged-transaction primitive,
> not the primitive itself (`DLUX` §7.3, and the two-primitive ruling).
>
> **Eleven `DRC` questions were disposed of by precedence without ever being put to the owner**
> (`DRC-3`, `5`, `6`, `8`, `10`, `15`, `16`, `18` against `DLUX`; `DRC-26` and `DRC-33`'s option
> choice in the B–E walk; plus `DRC-11`, `13`, `14` ruled in the first). Nothing below reopens them,
> and neither should a slice.
>
> Per `DOC-014`, neither `Accepted` nor this revision is a freeze: reopening from *discovery* stays
> encouraged, reopening from *ignorance* stays banned, and the discriminator is whether a precedence
> check ran first.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md), tracks
`B3-REQ`, `B3-MET`, `B4-DIALOGUE-V1`, `B4-CONVOY`, and the recruit/capture delivery line.

## 1. Outcome

Deliver the accepted V1 as one dependency-ordered system without collapsing its distinct domains:

- one atomic conversation runner with profile-selected presenters used by story scenes, map Talk,
  supports, Prison visits, and blocking narrative barks;
- five independent unit-state dimensions and one authoritative transition service for permanent and
  map-end recruitment, custody, roster membership, controller changes, and transition history;
- dynamic Incapacitate and Capture objectives plus latched Extract milestones;
- shared carry/displacement rules, hard target and initiator locks, live captive release when a
  carrier falls, and authored escape/disposition handling;
- FE7-style on-map Trade and designated-provider Convoy access;
- a subject-first Explore/Prison activity using the Prep activity registry and ordinary dialogue,
  requirement, relationship, inventory, and transition actions;
- whole-conversation and whole-map-end atomicity, with saves relaunching from the preceding committed
  checkpoint;
- low-code source data, templates, validation, previews, and fixtures sufficient to author the V1
  without editing GDScript.

This plan does not implement product code. Product slices target `agent/integration` only after plan
review and owner acceptance.

## 2. Current code and stale assumptions

### Reusable foundations already present

- `RegistryManager`, `RegistryCatalog`, and family-specific registries establish the open-registry
  pattern.
- `ActionRequest`, `ActionContext`, `ActionResult`, `ActionPrimitiveRunner`, and
  `ActionEffectRunner` provide typed action validation/commit. They do **not** yet provide a staged
  journal, overlay reads, inverse/rollback, or multi-action atomic commit.
- `ObjectiveConditionRegistry` validates, evaluates, and displays registered objective conditions.
  `TurnManager.check_victory_conditions()` currently evaluates synchronously and immediately sets
  `_map_over`, awards rewards, and emits results.
- `PrepActivityRegistry` and `PrepActivityDef` provide an inert open panel/activity seam.
- `GridManager._tiles_in_range()` plus staff/attack queries and `MapCursorTargeting` provide useful
  geometry, filtering, overlay, and input patterns.
- `PairUpRegistry` provides one attached/off-map identity implementation and Save/Retry coverage.
- `InventoryEntry`, `SaveCodec`, `MapLedger`, `ResourceLedger`, and snapshot tests provide instance,
  transaction, and deterministic persistence seams.

### Assumptions that this work must replace

- `UnitData` has `team` at the scene-unit layer and only `is_incapacitated`; it lacks affiliation,
  tactical side, controller, typed roster status, and typed custody status.
- `SaveCodec.UNIT_SNAPSHOT_KEYS` has no five-dimensional state, carry/custody record, extra stats, or
  stat constraint effect representation.
- `ConditionManager` remains a no-op stub, while capture and displacement decisions require real
  registered conditions and capabilities.
- `CampaignNode` has deployment/rule fields but no campaign-default/cadence/node-patched activity
  list.
- No Dialogue, Talk, Trade, Convoy, Carry, custody roster, Prison panel, relationship runtime, or map
  event runner exists in the current code.
- Older DLG/RCR/RCV/DSP documents treat faction flip as recruitment, sleep as capture, capture as a
  recruited-state path, mid-line conversation state as saveable, or `captured:<id>` as a loose flag.
  The DRC decisions supersede those assumptions.
- `[RCV-4]`'s `recruit(unit)` contract is **gone**, replaced by `[DRC-20]`'s sparse five-dimension
  patch. A single-arity faction flip cannot represent `[DRC-21]`'s ruled `map_end` duration with a
  mandatory expiry outcome at all — that is what foreclosed it, not a preference.
- `[RCR-2]`'s auto-set `recruited:<id>` flag is **retired** in favour of `[REQ-13(b)]` runtime
  unit-state predicates over `roster_status` and recruitment history. (The shape is already
  forbidden below; the specific retirement is named here so a reader of `RCR` finds it.)
- `[RCR-3]` inverted the dependency: it gave the roster a `recruit()`/`capture()` API writing four
  dimensions the roster does not own. The unit-state service owns every dimension write; the roster
  is a consumer that reacts to `roster_status`.

## 3. Architecture and ownership

### 3.1 Unit state and transitions

Persist and expose these independent values:

```text
affiliation_id     narrative identity and aggression-matrix fallback
tactical_side_id   current encounter alliance/hostility participation
controller_id      input/AI authority
roster_status      none | guest | member | unavailable | ...registered values
custody_status     free | carried | removed_to_custody | imprisoned | ...registered values
```

`custody_status` takes `none | carried | restrained_on_tile | removed_to_custody` (`DRC-29`). It is
**authoritative**: `CarryRegistry` keeps the physical carry mechanics — displacement, carrier
penalties, drop-on-carrier-fall — but a captive's carried-ness is *read from this dimension, never
stored twice*.

`UnitTransitionService` is the one unit-state service, and it owns **reads and writes both**:
`apply(transition)` is the only path that mutates the five dimensions (`DRC-19` confirmed, extended
to writes by the transition-ownership ruling). That single path is where the three obligations every
transition owes are hung — `[DRC-17]`'s blocking validation, the `[CAU-4]` `recruitment` /
`custody_change` / `execution` tags, and participation in the staged transaction. Callers do not
write dimensions directly; the roster reacts to `roster_status` rather than driving it.

A request is a **sparse patch, not a before/after pair** (`DRC-20`):

```text
{target_affiliation?, target_tactical_side?, target_controller?, target_roster_status?,
 target_custody_status?, duration, expiration_outcome, target_activation}
```

**An unset dimension means unchanged.** One transition type therefore serves recruitment, defection,
capture, release and expiry: `charm` sets `target_controller` alone, a capture sets
`target_custody_status` alone, `permanent_join` sets affiliation, side and roster together. Building
this as three fields rather than five is the defect `DRC-20` caught: `tactical_side_id` owns turn
group, hostility lookup, targeting and objective presence, so a transition that cannot set it leaves
a recruited enemy **in the enemy turn group**. Do not derive `tactical_side` from `affiliation` —
that collapses the distinction `[DRC-19]` drew, since an allied-AI unit shares the player's side but
not their affiliation.

The patch reaches **the five dimensions and nothing else** (`DRC-23`). HP, progression, statuses,
inventory, relationships, history, identity and role-authored behaviour data all survive untouched.
Behaviour changes — `[AIP]` profile, scripted orders — are ordinary **effects authored alongside**
the transition and bundled into the shipped recruitment presets, so there is one mechanism for
"recruitment also changes X" rather than an in-transition allow-list plus the effect system. Presets
(`permanent_join`, `map_guest`, `turn_control`, `defect_to_third_faction`, and the custody presets)
remain the author-facing interface; a hand-built bare transition that bundles no behaviour effect
correctly leaves the old profile and orders running.

`target_activation` takes `preserve | end | refresh` and defaults to **`preserve`** (`DRC-22`): a
newly controlled unit keeps whatever activation state it had, so one that has already acted stays
done. `refresh` is authorable but emits a `[DLUX-10]` structured author-time warning naming the
double-turn risk; it does not block. `[DRC-21]`'s "expiry never grants a bonus action" pins the
`map_end` expiry transition to `preserve` whatever an author writes elsewhere. Note the split by
subject: `[DRC-13]`'s interaction-policy registry owns the **actor's** cost of interacting; the
transition owns the **target's** arrival. They can never contradict because they describe different
units — and a `turn_reached` recruitment has a transition but no actor and no interaction at all,
which is why the policy cannot live on the registry.

A request also declares cause, actor, target, duration/expiry, custody owner and representation, and
emitted facts/milestones. It validates the full proposed transition, stages it against a supplied
state view, and returns a structured `UnitTransitionResult`. Objective, AI, turn order, roster, UI,
dialogue, ledger, save, and relationship consumers observe that same result. Inventory consequences
are **referenced**, not embedded — see §3.5.

Do not store derived booleans such as `is_recruited` or `captured:<id>` as competing authorities.
Historical facts may be emitted from transition records when authored content needs them. There is
likewise **no `recruitable` truth flag on a unit** (`DRC-25`): the transition attaches to the
opportunity, and the unit supplies identity and default hints only.

### 3.2 Requirements

Extend the shared `[REQ]` registry before Dialogue or Prison gating. Requirements use bounded
`all/any/not` composition and typed subjects such as `actor`, `target`, `visitor`, `prisoner`, `guard`,
`custody_owner`, and `speaker_controller`. Add predicates for the five state dimensions, current and
historical Incapacitate/Capture/Extract, registered conditions/capabilities, spatial relation,
inventory/key-item availability level, relationships, facts/resources, activity/cadence state, and
transition cause. Each returns truth plus a localized unmet-reason descriptor.

`[REQ-13(b)]`'s `is_captured` predates the custody dimension and reads `[STY-6]`'s sleep state;
re-point it at `custody_status` in the same slice that lands the dimension.

**Eligibility disclosure is `[EPUX-02]`'s shared two-value vocabulary** — absent hides, gated shows
disabled with a reason — and **the tactical map is a fifth `EPUX-02` surface** (`DRC-11`). The
proposed `secret | hinted | explicit` policy was rejected: *hinted* is authored content riding
`[EPUX-07]`'s unified localized reason, not a third disclosure state. `REQ`'s single display path is
what supplies that reason string, so it is load-bearing for the map surface and not merely internal.
Disabled entries are **focusable but not activatable**, decided at the shell across all five
surfaces (`[RPD-15]`, 2026-08-13) — Talk/recruit/capture entries **inherit** that focus behaviour
and must not specify their own.

Confirmation authority is **split by origin** (`DRC-14`, closed): an author's confirmation predicate
on a specific action is a floor no player setting can lower, while `[CAU-4]`'s presets govern the
**engine-derived tag set** only. That set now includes `recruitment`, `custody_change` and
`execution` alongside `relocation` and `inventory_mutation`.

### 3.3 The two transaction primitives, and the action journal that consumes one

Examining four ratified staging/rollback mechanisms — `MapLedger`, `[EPUX-24]`'s transaction core,
`[EPUX-06]`'s activity snapshot, and this journal — found them differing only in *policy*
(retention, charging, who may trigger) while sharing every *hard* part (overlay reads, commit
ordering, RNG determinism, save participation). The engine therefore builds **two named primitives**,
and policy is layered on top:

- a **staged transaction** — overlay plus one commit/discard boundary — consumed by the dialogue
  journal, the map-end pipeline, `[EPUX-24]`'s core, and Trade;
- a **snapshot** — capture and restore **including the RNG stream** — consumed by `MapLedger` and
  `[EPUX-06]`'s activity receipt.

`ActionJournal` is a **consumer of the staged transaction, not the primitive itself** (`DLUX` §7.3).
It sits above `ActionPrimitiveRunner`, not inside the dialogue UI, and contains ordered validated
requests, a read-only authoritative base view, the staged overlay, structured results, and the
commit/abort boundary. Handlers must declare whether they support staging and which state families
they read/write. Later requests evaluate against base plus overlay. Commit revalidates the journal
and applies it once; failure applies none.

**Record the nesting, because it is what the two names buy:** a conversation **stages** inside an
activity that is **snapshot**. Prefer staging; snapshot only to undo something already committed.
Two consequences follow and must be built, not re-derived:

- **An open conversation does not count as "a gated activity open"** under `[EPUX-06]`'s
  at-most-one invariant. That invariant bounds *snapshot* cost, and a conversation is a stage. The
  other reading would forbid a conversation inside a gated activity and break Prison outright, whose
  entire purpose is to contain one.
- **A recruitment committed during a prison visit stays reversible** until the `[EPUX-06]` exit
  review receipt is accepted, uniformly with every other consequence of that activity and with no
  carve-out for `recruitment`/`custody_change` (`[EPUX-28]`).

**Word collision, recorded so it is never read as a contradiction:** `TSV`'s *"no cart, no staging,
no holds, no per-receipt undo, no partial commits"* forbids a **user-visible cart accumulating
intent across selections**. The **staged transaction** here is the **internal atomic commit
mechanism for a single operation**. Different senses of one word; neither overrides the other.

V1 Conversation stages the whole conversation as one transaction. V1 map-end resolution stages
provisional victory → events → custody disposition → residual Prison intake → final objective
evaluation → result/reward commit. Both consume the same primitive without making map-end processing
a conversation.

### 3.4 Spatial target queries

Extract a pure `SpatialTargetQuery` from GridManager geometry and the staff-targeting pattern. Inputs
are source tile/entity, min/max range, registered metric/footprint, inclusion of source tile, map
bounds, real occupants, virtual occupants, and a requirement/filter id. Output contains stable target
refs, source/represented tiles, eligibility, and unmet reasons. Staff, aura, Talk, Trade, Rescue,
Capture, Convoy provider, and later interaction modes compose their own filters. Do not depend on
`SkillHandler._manhattan()` or copy heal-specific HP/alliance logic.

### 3.5 Inventory interactions

`InventoryTransferService` owns item-instance slot operations. **Each slot swap quotes and commits as
its own transaction** (`DRC-30`) — the only reading consistent with the `TSV` outcome, and what
`DRC-30`'s own *first committed swap marks the actor as having traded* rule already presupposes. A
session-scoped transaction committing on exit is rejected: it reintroduces the accumulating cart
`TSV` removed. Empty-slot swaps are moves through the same operation. Key/bound restrictions return
structured reasons and forced-effect fallbacks. Convoy transfers use unit↔store movement through the
same ledger, not the two-inventory visual layout.

**Trade consumes `[EPUX-24]`'s shared atomic quote/commit/rollback core and `[EPUX-21]`'s shared
quantity primitive by name**, and must not become a third transaction implementation beside shop and
forge. Its spatial target discovery and `[DRC-12]`'s range predicate are one geometry seam with
several callers (§3.4), not a Trade-local query.

**Captive-trade permission is an authored predicate on `[DRC-12]`'s interaction descriptor** —
*"the actor's side holds this unit in custody"* — not a controller fiction inside Trade. This matters
mechanically: the unit-state service is the only path that mutates dimensions, so a permission rule
must not resemble a dimension write. The same predicate generalizes to the Rescue passenger and Pair
Up partner cases.

This service owns every transfer, so a transition record **references** its ledger entries rather
than copying them (`DRC-33`); see §4.

Trade and Convoy are separate FE7-style partial action marks. Opening/cancelling without a committed
transfer is free. The first transfer commits location; one session may perform multiple transfers;
each interaction may be initiated once per activation; both may occur before a concluding action.
Post-action movement routes through the registered move-again policy.

### 3.6 Dialogue data and presentation

Campaign packs ship validated plain data:

```json
{
  "id": "talk_maro_lena",
  "profile_id": "map_talk",
  "roles": {"actor": "unit:maro", "target": "unit:lena"},
  "requirements": {},
  "entries": [
    {"id":"e001","type":"line","speaker":"actor","text_id":"talk.maro.001"},
    {"id":"e002","type":"choice","decision_owner":"actor_controller","options":[]}
  ]
}
```

A conversation is a **flat ordered sequence of entries with stable line IDs — no runtime node
objects** (`DRC-2`). Jumps, labels and requirements target a line ID directly; there is no second
addressable level to author, validate or migrate, and `[DLUX-11]`'s demand-gated graph view stays a
projection over this same canonical data. The argument for node identity was
nodes-as-resume-boundaries, which `[DRC-9]`'s atomic v1 removed.

**IDs are tool-generated and stable, with an optional author alias** (`DRC-4`). The editor mints an
opaque ID at creation; the author may attach a readable alias, and **the alias is what jumps, exports
and localization keys use**, with the validator enforcing alias uniqueness within the pack. IDs
survive reordering and prose rewrites, satisfying `[DLUX-14]`'s ban on positional or prose keys while
keeping `[DLUX-11]`'s diffable JSON readable. Hand-authored JSON is first-class input and supplies
both fields directly.

V1 entry vocabulary is `line`, `choice`, `label`, and registered presentation/game-action commands.
Presentation cues and game actions live in separate registries with schemas and skip/replay metadata.
V1 profiles are `[DLUX-3]`'s four — `story`, `map_talk`, `support`, `bark` — and own presentation and
interaction policy only. **`prison_visit` is not a profile**: a prison conversation invokes `story`
and keeps attempt limits, cooldowns, visitor eligibility and time cost in its Explore activity and
dialogue actions. A new profile requires a real policy difference, not merely a new dialogue
consumer. Templates such as `recruitable_enemy_talk` expand at authoring time into independent
ordinary interactions, requirements, conversations, and actions; they are not runtime profile types
or dependencies.

**Placement is `UBS-4`'s, at every size class:** a conversation occupies the **canvas region only and
never the control band**, with `story` taking the full canvas and `map_talk` a lower canvas band
whose height shrinks proportionally as the class grows. One presenter and one set of per-profile
defaults, so `[DLUX-15]`'s preview-at-every-size-class obligation stays cheap; a `map_talk` side rail
above Compact was rejected because the tactical map is a canvas, not a list+detail screen. In gamepad
mode the pad reaches history, pause, skip, advance, and **scrolls a line within its line object** —
which is also the answer to `[L10N-7]`'s 1.4× text extent, since a line that fits in English and
overflows in German scrolls rather than clips. Authors are warned through `[DLUX-10]` to break long
sections into smaller advanceable ones; where a wall of text genuinely is right, the sanctioned form
is a larger popup notification window.

**Stage direction, per `[DLUX-16]` under `[L10N-12]`:** the portrait stage is **screen-absolute and
non-mirroring** — its named slots and the idempotent `left|right` facing state do not flip with
locale, so the facing flip stays a pure art flip and an RTL locale preserves the authored
composition. The dialogue box justifies to the locale's reading direction and renders the line as
**one inline run**, `Speaker: words words words.`, with the speaker name as the head of that
paragraph rather than a separately positioned name plate. Per `[L10N-8]` that form is **a single
localizable template** taking `{speaker}` and `{line}` — never `name + ": " + text` assembled in
GDScript, which would stop a locale changing the separator or the order. `[L10N-10]` still applies to
`{speaker}`: a user-authored name renders verbatim and is not grammatically inflected.

The V1 floor is a compact presenter with speaker, text, optional portrait, choices, control/help
disclosure, and input parity. An optional rich presenter adds portrait enter/exit/expression, named
positions, bounded horizontal movement, idempotent left/right facing, deterministic portrait layers,
background, music/SFX requests, and simple fade/slide. Universal Auto and Skip cannot be disabled by
profiles or campaigns; Skip executes the identical journal path and stops at unresolved choices.
Dialogue history projects into the unified chapter combat-log/`MapLedger` Rewind menu. Replay
suppresses game actions.

**The save boundary is structural, not a rule to remember** (`DRC-9`). A conversation **is** a staged
transaction, so a save discards the stage and only committed state was ever serializable: no staged
consequence can leak into a save **by construction**. No cursor, trail, presentation, or journal is
persisted in V1. The save UI still explains, before confirming, that an in-progress conversation
restarts from its beginning on load. `[DLG-11]`'s promise that every completed line is automatically
suspend-safe is **superseded** and banner-ed at the source. Post-v1 option C may still add committed
mid-conversation checkpoints.

### 3.7 Explore and Prison

Explore is a Prep option. It selects a deployable unit or non-deployable camp follower, then resolves
available activities from:

```text
campaign defaults → cadence patches → current CampaignNode add/remove/override patches
```

The Prison activity binds `visitor`, `prisoner`, `guard`, and `custody_owner`, evaluates shared
requirements, and launches a **`story`-profile** conversation (there is no `prison_visit` profile).
It has no universal Recruit/Persuade/etc. buttons and no separate persuasion score. Explicit
conversation actions may change relationships, facts, costs, attempts, cooldowns, recruitment,
release, transfer, or death. Everything committed inside the visit stays reversible until the
`[EPUX-06]` exit review receipt is accepted (§3.3).

**Capture entry is a registry, not an engine `match`** (`DRC-27`). V1 registers two methods:
`non_lethal_carry` (`[STY-6]`'s would-be-kill applying sleep, then carry) and a **first-class
`take_custody` action** invoked directly by dialogue outcomes, surrender and scripted capture.
`take_custody` exists so story capture stops faking a sleep status it does not mean. Direct
capture-attack and objective/script methods are authored later against the same registry with no
engine edit.

**The capture method is a field group on the existing `[DRC-13]` interaction-registry entry, not a
second registry.** That entry already carries `[DRC-12]`'s descriptor — direction
(`directed | bidirectional`), range predicate, allowed phases, permitted initiator — and the
action-economy policy. One entry per interaction: one place to author, one validation pass, and no
failure mode where a method exists with no matching policy.

**Physical eligibility is one validated `incapacitated_and_carryable` profile** (`DRC-28`), composed
entirely from `[REQ]` terms that already exist: `[REQ-13(b)]` status and carry state
(`is_captured`/`asleep`, `NOT is_carried`), `[REQ-12]` HP and equipment, and `[DSP]` carrier
capacity. **The size / carry-capacity term is deferred** — it needs a unit size attribute that does
not exist, and `REQ-12` is author-extensible by ruling, so adding it later needs no new mechanism.
Shipping no default profile was rejected: it would make "any unit can carry any target" an easy
authoring mistake rather than something the default prevents.

**Recruitment opportunities carry their own terms** (`DRC-25`). The transition **opportunity** owns
the authoritative `[REQ]` predicate, the `[DRC-20]` transition, the `[EPUX-02]` disclosure property,
and the actor/target selectors it takes from `[DRC-12]`'s descriptor. One unit may therefore join
several ways on different terms — `map_guest` in one chapter, `permanent_join` in another — without
duplicating unit data or a unit-default-plus-override precedence rule.

## 4. Data and save contracts

### Campaign definitions

- Conversation catalogue entries (flat entries, tool-generated ids plus author aliases), profile
  entries for `story`/`map_talk`/`support`/`bark`, presentation/game-action command entries, text
  ids, portrait/background asset ids, low-code templates, and fixtures.
- Interaction definitions for Talk/Trade/Capture/Extract and convoy-provider policies — **one entry
  per interaction**, carrying `[DRC-12]`'s descriptor, the action-economy policy, the capture-method
  field group, and any permission predicates.
- Transition opportunities: `[REQ]` predicate, `[DRC-20]` transition (or preset), `[EPUX-02]`
  disclosure property, and actor/target selectors.
- Campaign activity defaults, cadence patches, and `CampaignNode.activity_patches`.
- Aggression-matrix prisoner dispositions with optional dimension/predicate overrides and ordered
  affiliation fallback.
- Registered conditions/capabilities, stat constraint effects, objective selectors/quantifiers,
  extraction zones, key-item availability/restriction/fallback policies.

### Durable run state

- Five unit-state dimensions — including `custody_status` as the authoritative custody value — plus
  duration/expiry data and `target_activation`. `[RCR-7]`/`[RCV-6]`'s save reservations predate this
  model and reserve none of it; size the schema from this list, not from theirs.
- The structured transition record: cause, actor, target, **all five dimensions before and after**,
  duration and expiry, `target_activation`, the `[CAU-4]` tag, the milestone
  (`incapacitate`/`capture`/`extract`), emitted facts, and **references to item-instance ledger
  entries rather than copies of them** (`DRC-33`). Pack schema versions for transitions and actions
  are rejected or migrated before activation.
- Typed custody records keyed by stable captive id: owner, carrier/representation, cause, timestamps,
  extraction history, remaining inventory, and transition ids. Carry is derived from `custody_status`
  and is not stored a second time.
- Campaign custody/Prison roster and stable unit snapshots.
- Relationship graph and authored attempt/cooldown facts through their owning systems.
- Transition/event history sufficient for latched milestones; dynamic objective state remains derived.
- Activity/cadence state and node patches through campaign state.
- Trade/Convoy partial-action marks and carry state in mid-map snapshot/ledger only.

Do not persist V1 in-progress conversation state or an in-progress map-end journal — under §3.3
neither is serializable by construction, since both are stages. Saving during either writes the
preceding committed checkpoint. Save/load restarts the complete atomic workflow. Add schema fields
only in the vertical slice that validates, captures, restores, and tests them.

### Inventory and key items

A residual prisoner keeps bound/protected/key items; other eligible equipment moves to the appropriate
controlled-faction convoy at map end through the item ledger. **Overflow goes to `[EPUX-11]`'s
pending-items tray**, resolved before leaving prep: the residual-captive sweep fires automatically
after the event runner, so it is an *unavoidable acquisition*, and the fail-before-commit branch of
`EPUX-11` — which applies to player-initiated transfers — would **halt map-end resolution on a full
convoy** (`DRC-31`). `[EPUX-12]`'s Send All to Convoy supplies the sweep's shape: one item at a time
in order, with non-transferable instances filtered up front rather than halting. Key-item policy independently declares
`present`, `requirement_accessible`, and `player_usable`; prisoner-held default is true/true/false,
pending author testing. Unit/class stat caps limit personal growth only and never clamp effective
effects.

## 5. Dependency-ordered implementation slices

### Slice 0 — Reconciliation and fixtures

- Amend DLG/RCR/RCV/DSP/VIL/STY/PHB/CNV/DTH/F1 sources to point to the DRC rulings. The banners the
  `DRC` walks recorded as owed are paid with this plan's re-derivation, not deferred into this slice:
  `[RCV-4]` and `[RCR-3]` name the unit-state service and the typed transition instead of
  `recruit(unit)`, `[RCR-2]` carries a retirement banner, `[RCR-4]` points at `[REQ]`, and
  `[REQ-13(b)]`'s `is_captured` points at `custody_status`. What remains here is the wider sweep.
- Add representative no-code fixtures before runtime work: atomic branch/recruit conversation,
  temporary guest, capture/release/extract, Trade with captive/passenger, designated Convoy provider,
  map-end Prison intake, relationship-gated prison visit, and contradictory stat floor/cap.
- Update pack/Tier-2 family inventories so extraction does not omit the new definitions.

Exit: validators can load fixture documents as inert data or report explicitly unsupported families;
no stale source claims mid-line save or capture-as-recruit.

### Slice 1 — Requirement foundation

- Implement typed requirement schema, composition limits, subject binding, result/reason type, registry,
  human display, and validator.
- Land core state/fact/resource/inventory/spatial/relationship predicates used by later slices.

Tests: truth tables, missing subjects, nested limits, unknown ids, deterministic display, headless
serialization, hostile/malformed pack fixtures.

### Slice 2 — Unit state dimensions and transition service

- Add runtime/persistent fields and compatibility adapter from legacy team/recruited assumptions.
- Implement the **sparse patch** request over all five dimensions (unset = unchanged), `target_activation`
  with `preserve` as the default, typed result, staging support, duration/expiry, roster commit,
  turn/AI controller refresh, structured events, save/rewind codec, and projection purity.
- **`apply(transition)` is the only writer.** No caller mutates a dimension directly; the roster
  reacts to `roster_status`. The service is where `[DRC-17]` validation, the `[CAU-4]` tags and
  staged-transaction participation attach.
- Keep the patch to the five dimensions. AI-profile and scripted-order changes are **effects bundled
  into the shipped presets** (`permanent_join`, `map_guest`, `turn_control`,
  `defect_to_third_faction`), not transition fields.
- Permanent recruit commits `roster_status=member`; map-end guest requires explicit expiry outcome,
  and the expiry transition is pinned to `target_activation=preserve`.

Tests: every dimension changes independently **including `tactical_side_id` alone** (a recruited enemy
leaves the enemy turn group), unset-means-unchanged, permanent/map-end recruit, `preserve` leaves an
already-acted unit done while `refresh` warns, expiry precedence with death/custody/permanent recruit,
rollback, hotseat controller handoff, save/Retry/Rewind, malformed transition, and a rejected attempt
to patch a non-dimension field.

### Slice 3 — Conditions, stat constraints, and movement capabilities

- Replace ConditionManager stubs with registered conditions/capabilities and lifecycle ticking.
- Extend effective-stat resolver with additive → setter priority → cap → floor. Floors override caps;
  class/unit caps apply only during personal growth.
- Add hard external-movement target lock and separate initiation lock; only explicitly authorized
  story actions bypass them.

Tests: apply/cure/tick; equal-priority setter rejection; multiple setters/floors/caps; floor-over-cap;
growth cap versus effects; skill/condition sources; preview/display parity; story-override audit.

### Slice 4 — Spatial query, carry, custody, and extraction

- Add shared spatial query and virtual occupant adapters for Pair Up, Rescue, and custody.
- Add carry/custody registry and transactional attach/detach/drop/handoff.
- Captor fall releases captive on the vacated carrier tile, preserving sleep/conditions; subsequent
  escape uses authored cause-displacement rules.
- Add Escape-with-captive and Extract-captive tile actions. Extract fires whenever a captured unit is
  removed alive by those actions or map end.

Tests: occupancy invariants, locks, capacity predicates, carrier fall, blocked placement, attached
save/rewind, extraction causes, death exclusion, hostile rescue/transfer, map-edge behavior.

### Slice 5 — Trade and designated-provider Convoy

- Implement general Trade target policy and slot-swap service/panel, **committing one transaction per
  swap** over `[EPUX-24]`'s shared quote/commit/rollback core and `[EPUX-21]`'s quantity primitive.
  Trade is a caller of those, never a third implementation.
- Permit adjacent real units and Pair Up/Rescue/captive occupants in actor or adjacent spaces subject
  to relationship/custody rules, with captive permission expressed as a **predicate on `[DRC-12]`'s
  interaction descriptor** — no controller mutation, since the unit-state service owns every
  dimension write.
- Implement designated Convoy provider queries. V1 default permits friendly Pair Up/Rescue providers
  through lead/carrier tile and denies aggressively captured providers; policy is author-tunable.
- Implement partial action/location commitment and separate Trade/Convoy usage marks.

Tests: swaps/moves/empty slots/capacity, item identity and uses, key restrictions/fallback, captive
permissions without controller mutation, provider attachment matrix, cancel before/after transfer,
concluding actions, move-again, save/rewind, controller/faction convoy ownership.

### Slice 6 — Conversation catalogue, validator, and atomic journal

- Add conversation/profile/command registries over **flat entries**, tool-generated ids with author
  aliases, text/assets, requirement binding, graph validation, cycle/budget checks, skip/replay
  metadata, and fixtures.
- Implement the **staged transaction primitive** and staged StateView support in the primitives V1
  uses; `ActionJournal` is built as its first consumer, not as the primitive.
- Land `[DRC-17]`'s four **blocking** validations: unreachable entries, unsafe cycles, duplicate
  consequences, and recruit/capture target incompatibility. **Authored fixtures are supported, not
  mandatory** — they serve campaign test suites and `[DLUX-15]` editor preview, but requiring them
  would gate the fork-a-public-pack onboarding model (`CSA`) behind writing tests.
- Implement traversal, choices, overlay reads, successful commit, abort/failure, skip, and replay.

Tests: linear/branching traversal, staged reads, all-or-none mutation, duplicate aliases, unreachable
entries, unknown roles/commands/assets/text, loop/budget rejection, skip equivalence, replay
suppression, and a pack that ships no fixtures still activating.

### Slice 7 — Dialogue presenter and checkpoint behavior

- Build the compact presenter, optional bounded rich presenter, and profile-driven interaction
  controller using shared UI state, responsive composition, native focus, controller region
  transitions, menu scale, and touch parity. Project dialogue records into the existing unified
  chapter log/Rewind surface rather than building a dialogue-local history panel.
- Add save warning and restart-from-prior-checkpoint behavior; interruption discards journal.

Tests: presenter state separate from data/runtime, decision ownership, controller/hotseat choice input,
  cancel policy, focus restoration, localization expansion, input parity, Save/Load restart, scene leak.
Windows playtest: keyboard/controller/touch-emulation, 100–200% menu scale, map/special backgrounds,
history, choice confirmation, skip-to-choice, save warning/relaunch.

### Slice 8 — Talk and recruitment integration

- Add registered unit interaction definitions and Talk target query with directed/bidirectional policy.
- Bind dialogue roles and route recruit actions through UnitTransitionService.
- Add player eligibility/disabled-reason previews, action cost, activation outcome, immediate permanent
  roster insertion, and map-end guest expiry.

Tests: initiator direction, relationship/condition gates, hostile/allied/temporary sides, action cost,
  staged recruit rollback, turn-order/controller refresh, roster/save state, survival-dependent guest.

### Slice 9 — Objective milestones and atomic map-end resolver

- Add selector/quantifier objective schema with snapshot default and opt-in disclosed dynamic sets.
- Implement dynamic Incapacitate and Capture, historical variants, latched Extract, and extraction-zone
  satisfiability validation. Extract may be sole victory only with a compatible route.
- Replace immediate TurnManager finalization with named map-end phases staged as **one staged
  transaction** (§3.3), nested correctly: the map-end stage sits outside any conversation stage it
  runs, and prep activities that follow are snapshot, not staged.
- Run authored end-map events, relation-specific dispositions, residual inventory/Prison intake,
  final victory/defeat evaluation, rewards, result signals, and campaign commit atomically. Residual
  equipment that overflows goes to `[EPUX-11]`'s **pending-items tray**; the sweep never halts
  resolution.
- Automatic disposition counting as a captive's death **emits the `[CAU-4]` `execution` tag but fires
  no confirmation prompt** — confirmation attaches to player-initiated actions, and an automatic
  resolution has no decision point. Surface it in the map-end report. A player-chosen execution in a
  prison or dialogue action emits **and** confirms.

Tests: post-action reevaluation only, multi-target atomicity, wake/release revocation, extract routes,
  snapshot/dynamic targets, simultaneous victory/defeat precedence, disposition-caused required-survival
  defeat, event failure rollback, result/reward single emission, Save restart, full-convoy sweep routing
  to the tray rather than failing, and the `execution` tag emitted without a prompt.

### Slice 10 — Explore/Prison

- Add campaign activity defaults, cadence changes, and node add/remove/override patches.
- Add subject-first Explore selection across deployable members and camp followers.
- Add custody roster/Prison panel and a `story`-profile conversation launcher with requirements, availability,
  key-item status, selected visitor, guard role, relationship/fact/resource actions, and activity cost.

Tests: activity merge order, stable ids, missing visitors/prisoners, no passive relationship gains,
  recruit/release/transfer/death outcomes, attempts/cooldowns, key availability, save/load, empty Prison,
  controller/faction privacy. Windows playtest covers navigation, disabled reasons, conversation return,
  roster refresh, and node/cadence changes.

### Slice 11 — Migration, authoring tools, and release review

- Provide import adapters for legacy dialogue/recruit/capture/objective/save data only at boundaries.
- Ship minimal low-code forms/templates, target/requirement pickers, graph validation, conversation
  simulator with staged diff, objective satisfiability preview, and fixture runner.
- Update GDD 01–08 where behavior changes, GDD 10, Feature Index, Control Plane, save manifest, author
  guides, and open-registry guards in the same slices.
- Run full automated suite, export validation, Windows end-to-end campaign, save/reload/rewind, and
  hostile-content fixtures before release promotion.

## 6. Low-code minimum and validation gates

The minimum author tool is schema-driven rather than a bespoke full editor:

- create from validated templates; edit stable ids, roles, lines, choices, requirements, actions,
  activity policies, objectives, and dispositions through pickers/forms;
- inspect resolved campaign/node/activity/provider policies and unmet reasons;
- simulate a conversation with chosen subjects and show staged versus committed changes;
- preview Trade/Talk/Capture/Extract target sets and objective target snapshots;
- validate all references, graph reachability, authority, lifecycle, save fields, localization/assets,
  action staging support, and platform/resource budgets;
- export identical plain data consumed by runtime.

Pack activation/export must fail on unknown runtime vocabulary, unresolved refs, ambiguous transitions,
unsupported staged actions, unsafe story overrides, unsatisfiable sole-extract objectives, illegal key
fallbacks, incompatible schema versions, duplicate line aliases within the pack, and `[DRC-17]`'s four
residue checks — **unreachable entries, unsafe cycles, duplicate consequences, and recruit/capture
target incompatibility**. Authored fixtures are supported but never required to ship a pack. Warnings
cover author-test-sensitive defaults, dynamic objective membership, prisoner-held key accessibility,
unusually broad permissions, and `target_activation=refresh` (`[DLUX-10]`'s structured author-time
warning, naming the double-turn risk).

## 7. Cross-system review and V1 cuts

### Required shared foundations

- `[REQ]` is one system for Dialogue, objectives, activities, items, shops, and events, and one
  display path for every unmet reason across all five `[EPUX-02]` surfaces.
- The **staged transaction** and the **snapshot** are the two transaction primitives; `ActionJournal`,
  the map-end pipeline, `[EPUX-24]`'s core and Trade consume the first, `MapLedger` and `[EPUX-06]`'s
  receipt the second.
- SpatialTargetQuery is one geometry seam for interactions; filters remain domain-owned.
- UnitTransitionService is one authority for recruitment/custody/control/roster changes — reads and
  writes both, with `apply(transition)` the only mutation path.
- InventoryTransferService is one instance ledger for Trade, Convoy, and prisoner disposition;
  transition records reference it rather than duplicating it.
- `[DRC-13]`'s interaction registry is one entry per interaction, carrying descriptor, action-economy
  policy, capture method, and permission predicates — not a family of parallel registries.

### Explicit V1 deferrals

- mid-conversation or phase-boundary committed checkpoints;
- animated portrait/effect tiers beyond the bounded V1 cues, live reflection/copies, arbitrary
  transforms, camera, scene filters, general compositor/timeline, runtime conversation calls, graph
  view without demonstrated demand, and a full dialogue editor beyond the ordered outline/forms;
- free-text intent resolution beyond the abstract decision-provider seam;
- generic persuasion simulation, prison economy, passive prison timers, or systemic prison escape;
- confiscation/escrow/restoration UI beyond Trade and map-end residual disposition;
- arbitrary Trade/Convoy policy combinations without implemented action/AI support;
- stat contests/RNG displacement resistance beyond deterministic V1 locks;
- remote multiplayer authority transport;
- the **size / carry-capacity term** in `incapacitated_and_carryable` (`DRC-28`) — it needs a unit
  size attribute that does not exist, and `[REQ-12]` is author-extensible, so it costs no mechanism
  to add later.

### Plan acceptance gates

Before Slice 1 begins, review this plan against the pack-save, zero-content, formula-registry,
prep/economy, UI architecture, and text-entry plans. The save schema must reserve five-dimensional
state and custody without embedding immutable content; the zero-content catalogue must include every
new authoring family; formula/requirement registries must not duplicate one another; Prep/Convoy must
use shared wallet/inventory ownership; and all dialogue text entry must comply with the minimize-free-
text rule.

**Decision-source gate — met 2026-08-13.** `DRC-1..33` is `RESOLVED` and this plan is re-derived
against it, so the thirteen rows that derive from it (`DRC-V1-S00..S11`, `EPIC-DIALOGUE-CUSTODY-V1`)
are no longer gated on the register. The remaining cross-plan review above is unchanged. Note that
the shared foundations this plan now consumes by name — `[EPUX-24]`'s transaction core, `[EPUX-21]`'s
quantity primitive, `[EPUX-11]`'s pending-items tray, `[EPUX-06]`'s activity snapshot — are owned by
the prep/economy line, so slice sequencing across the two plans is a real dependency, not a
cross-reference.
