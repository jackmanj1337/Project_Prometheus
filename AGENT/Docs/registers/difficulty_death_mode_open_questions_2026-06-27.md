---
Role: dated
Type: register
Status: RESOLVED — DIF-1..7 ruled 2026-06-27; DUX-1..8 ruled 2026-08-28
Last verified: 2026-08-28
Register: DIF-1..7; DUX-1..8
Resolved-in: 2026-06-27d; owner walk 2026-08-28
---

# Difficulty & Death-Handling Modes (#12, A5) — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). **Second A5 sub-item** (after the `[DTH]` death-inventory
disposition keystone). Covers **Casual/Phoenix #12** + the **Difficulty** axis. Walked end-shape-first.
Branch `docs-reorg-2026-06-23`. Design-capture only. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## Substrate reality (verified in code this session)
- **Death handling is a single binary today:** `CampaignRules.permadeath_enabled` (mirrored on
  `GameState`, per-save, picked on the New Game screen, `NewGameScreen.gd`). **On** → dead unit flagged
  `data.is_incapacitated`, skipped in future deployment (`GameMap.gd:191`). **Off** → unit returns next
  map with full data. So **"permadeath off" already is a crude Casual mode; Phoenix doesn't exist.**
- **No difficulty tiers** exist. But the **AIP register already designed a "difficulty overlay"** on the
  AI composition engine — difficulty must compose that, not fork a parallel AI-scaling system.
- `CampaignRules` already holds sibling rule knobs (`leveling_method`, `max_skills`, `max_inventory`,
  `exp_gaining_factions`) — the natural home for the new ones.

**End-shape frame:** #12 is **two orthogonal axes** — a **death-handling mode** and a **difficulty** axis.

---

## [DIF-1] Death-handling mode = `death_mode` enum {classic, casual, phoenix} — **RESOLVED**
**Owner:** replace the binary `permadeath_enabled` with a **`death_mode` enum** on `CampaignRules` + save:
- **`classic`** — permadeath; dead unit flagged `is_incapacitated`, never redeploys (today's "On").
- **`casual`** — unit retreats on defeat, **returns at the next map** (prep/deploy), alive.
- **`phoenix`** — unit **returns the next turn** (mid-map), alive.
`permadeath_enabled` **derives** (`== classic`) for back-compat / the existing `GameMap` deploy gate.
*Migration:* old saves with `permadeath_enabled=false` map to `casual`, `true` to `classic`.

## [DIF-2] Casual & Phoenix inventory = return EMPTY (closes the `[DTH-1]` scope) — **RESOLVED**
The `[DTH-1]` revision (revived units return empty; items disperse via the disposition chain) applies to
**both casual and phoenix** (owner — closes the scope DTH-1 deferred). **Consequence noted:** a
**phoenix** unit returns **mid-map empty**, so re-equip waits for convoy access (prep / a convoy unit) —
an accepted consequence of the empty-on-revive rule, not a blocker. PvP/skirmish (#7) is moot (fresh
loadout per match).

## [DIF-3] Difficulty = authored content VARIANTS ("palettes"), not a stat-scaling formula — **RESOLVED (direction)**
**Owner:** a "difficulty mode" is **essentially a variant campaign assembled from shared content
palettes** — harder/easier maps with **more/fewer enemies, different terrain or on-map weapons, harder
dialogue checks, less money, stricter loss conditions**, etc. Engine side = a **difficulty/variant
selector** that picks which authored content set loads; it is **not** a built-in enemy-stat formula.
*Composes* the **campaign content model** (self-contained per-campaign packs) + **map authoring** + the
**AIP difficulty overlay** (the AI-side knob). A difficulty selection **may also preset `[TCV]` tuning
variables** (DIF-5) — so difficulty = (content-variant selection) + (a bundle of tuning presets).

## [DIF-4] Selection = player picks from an author-allowed set — **RESOLVED**
`CampaignRules` **declares which death-modes and difficulty variants are offered** (an author may force
`classic`-only, or offer all three modes; may offer one or many difficulty variants). The **player picks
per-save** at new-game (extends the existing `NewGameScreen` permadeath/leveling pickers). Author intent
+ player accessibility choice both preserved. This is the **death-mode/difficulty slice** of the broader
author-exposed-tunable mechanism that `[TCV-2]` generalizes.

## [DIF-5] Tunable knobs + custom variables + parametric effects → FOLDED INTO `[TCV]` — **RESOLVED (sequencing)**
The owner's difficulty answer expanded into a real subsystem (layers 2+4 of the 2026-06-27d
decomposition): **(2)** every rule knob declarable **author-locked vs player-exposed** (settable at
campaign-start and/or mid-run, within author bounds), and **(4)** **author-defined typed variables** that
drive **tag-scoped parametric effects** ("+x to all enemy stats", "+n levels to tagged enemies"), money
rates, etc. **These two are one mechanism** and hinge on **F6 becoming a *typed* variable store.** Owner
call: **fold them into one consolidated pre-F1 "typed campaign-variable store" walk** = the new register
**`[TCV]`** (which also absorbs the objective-extensibility / flag-driven win-loss pin). DIF owns only the
death-mode + difficulty-variant selection that sits *on top of* that store.

## [DIF-6] Composition with Bonus-EXP (#18) + Arena (#14) — **RESOLVED 2026-06-27d → `[BEA]`**
Difficulty variants/variables can **scale Bonus-EXP pools** (classic FE: harder = more bonus EXP to
compensate) and **Arena death-risk** (under casual/phoenix, arena death isn't permanent — rides DIF-1).
Detail deferred to the #18 (`[AGT §6]`/Bonus-EXP) and #14 (Arena) walks; recorded here so they wire to
`death_mode` + the difficulty selector rather than re-deriving them.

## [DIF-7] Save / F1 schema reserve — **forward to Phase B (F1 lock)**
Reserve: **(a)** `death_mode` enum on the save (replaces the `permadeath_enabled` bool; keep a derived
getter); **(b)** the **difficulty/variant selection** on the save; **(c)** the player's **tunable-variable
picks** ride `[TCV]` / the typed F6 store (not a separate field). Migration mapping in DIF-1.

---

## Cross-refs
- **`[DTH-1]`** revived-empty rule → DIF-2 (this closes its Casual/PvP scope question).
- **`[TCV]`** typed campaign-variable store → DIF-5 (the tuning/custom-variable layers live there).
- **`[AIP]`** difficulty overlay → DIF-3 (the AI-side difficulty knob).
- **Campaign content model** (per-campaign packs) → DIF-3 (difficulty = content variants).
- **`[AGT §6]`/#18** Bonus-EXP, **#14** Arena → DIF-6. **`[VAL]`** AI → reads difficulty via AIP.

---

## Difficulty/death presentation rulings (DUX)

This section closes the presentation residue tracked by
`DISCUSS-DIFFICULTY-DEATH-UX-2026-07-23`. It does not reopen the mechanical
`DIF` or `DTH` rulings above. Corrected in place 2026-08-28 after the settings
persistence walk established the shared campaign/device/seat ownership model.

### [DUX-1] New Game owns initial selection — **RESOLVED 2026-08-28**

Difficulty, Death Mode and the other campaign rules appear after campaign
selection on New Game. Changing the campaign repopulates the surface from that
campaign's authored offerings. Difficulty appears first, Death Mode second,
and remaining campaign rules follow under **Advanced Rules**. They are campaign
rules, not ordinary device preferences.

An author chooses which options to offer. An option the author does not offer
is absent. An offered option that is temporarily incompatible with another
selection remains visible but disabled and states why.

### [DUX-2] Labels, summaries and selected-option detail — **RESOLVED 2026-08-28**

Every offered option has a label and short summary and may add localizable,
hand-written detail text. When selected, that detail appears immediately below
the option's selector. It supplements rather than replaces the stable rule
meaning and is available to campaigns that need to explain fiction, downstream
effects, or unusual combinations.

Difficulty text describes the effects the authored profile actually applies;
the engine never assumes that a name such as Easy or Hard means stat scaling.

The engine's default Death Mode description covers return timing only:

- **Classic:** defeated units do not return.
- **Casual:** defeated units return for the next map.
- **Phoenix:** defeated units return next turn.

It does not mention item or inventory disposition. Those are separate rules and
appear only through their own option text or author-written additional detail.

### [DUX-3] Defaults and locked offerings — **RESOLVED 2026-08-28**

A sole offered option is selected automatically. Where several options are
offered, the pack-authored default is selected. A production pack with a
missing or invalid default fails validation rather than silently taking the
first list entry. Legacy content without the new contract migrates the old
`permadeath_enabled=false` value to Casual and `true` to Classic.

An author-locked value remains readable and is labelled **Set by campaign**; it
is not presented as an unexplained disabled control.

### [DUX-4] Declarative cross-rule constraints — **RESOLVED 2026-08-28**

Offered rule options may declare requirements and exclusions against stable
rule and option IDs. This supports dependencies such as a mode requiring
Convoy Access and restrictions such as Ironman excluding Casual. Constraints
are declarative and deterministic, not campaign-authored scripts.

After each selection the surface recalculates compatibility. It never silently
replaces a player's selection. If a change invalidates another selected value,
that row is marked for attention and Start remains disabled until the player
chooses a legal replacement. A constraint may carry author-written explanatory
text; otherwise the engine generates a reason from the referenced labels.

### [DUX-5] Validation and development projects — **RESOLVED 2026-08-28**

Production validation rejects nonexistent constraint targets, offered options
that can never become valid, invalid defaults, unsatisfiable dependency cycles,
and offered rule groups with no reachable option. It also requires at least one
legal complete configuration.

Development projects receive the same findings as visible diagnostics, but the
findings do not block saving, previewing or launching incomplete work. Runtime
constraint evaluation still has its normal meaning. Release/export validation
promotes the findings to blocking errors; a production pack cannot use an
authored development flag to bypass that gate.

### [DUX-6] Mutability classes — **RESOLVED 2026-08-28**

Each rule group declares one of three mutability classes:

- `start_only` — fixed once the campaign begins;
- `between_maps` — editable only at a safe campaign boundary;
- `anytime` — editable while no modal or action is active.

The same offered-option and constraint rules apply after campaign start.
Changes are prospective: they never resurrect units, restore disposed
resources, or otherwise reverse consequences already resolved. A difficulty
change takes effect at the next node/map boundary. A Death Mode change affects
future defeats only.

### [DUX-7] Notices and confirmations — **RESOLVED 2026-08-28**

An option may declare `none`, `notice`, or `confirm`. A notice adds explanation;
a confirmation requires explicit acknowledgement when starting or changing to
the option. Classic has an engine-required confirmation because defeated units
do not return. Authors may strengthen an option's warning but cannot downgrade
an engine-required warning. Separate consequential rules, including inventory
rules, own their own notices or confirmations.

### [DUX-8] Post-start Campaign Rules surface — **RESOLVED 2026-08-28**

Settings links to a dedicated **Campaign Rules** section after a campaign has
started. It shows every selected rule and current option:

- `start_only` rows are read-only and say **Fixed when campaign began**;
- `between_maps` rows remain readable during battle and say **Changeable
  between maps**;
- `anytime` rows remain editable when the surface is safe to use.

Unoffered options remain absent. Offered but incompatible options remain
visible, disabled and explained. Selected author detail updates immediately,
and consequential changes use DUX-7's notice/confirmation behavior.
