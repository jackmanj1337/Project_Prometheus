---
Type: plan
Status: Active — re-baselined portfolio review; deliverables 1–3
Last verified: 2026-08-21
Tracker: PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Re-baselined accepted-portfolio code-state review (2026-08-21)

Runs the re-scope accepted in
[`accepted_portfolio_review_rescope_2026-08-20.md`](accepted_portfolio_review_rescope_2026-08-20.md)
§2: deliverables 1, 2 and 3, with deliverable 4 dropped and the blanket
"no product-code changes" clause lifted.

## 1. What was reviewed, and how

**Reviewed SHA: `agent/integration` `8c62bf16`.** Not a working checkout, not "current
`main`" — the exact commit this branch forked from. `agent/playtest-release-v0.7.8`
contains it and adds documentation only, so the product code reviewed here is also the
product code in the outstanding tester bundle.

The method is the one instruction the re-scope singled out: **verify a shared contract by
naming its consumers, not by confirming the contract exists.** Every claim below was
measured against the tree. Where a tracker row asserts something about current code, the
assertion was re-run rather than inherited.

**One methodological result belongs up front, because it changes how the rest should be
read.** Name-based consumer tracing produces *both* kinds of error in this codebase:

- **False negatives.** `RequirementSystem` is consumed by `CadenceEngine` — but
  `CadenceEngine.gd` never contains the string `RequirementSystem`. The handle arrives as
  a dictionary entry (`CampaignManager.gd:453`) and is invoked as
  `requirement_system.call("evaluate", …)` (`CadenceEngine.gd:169`). Grep for the class
  name and the consumer is invisible.
- **False positives.** Autoloads are reached by `/root/<Name>` strings and Resource
  subclasses by `script_class` in `.tres`, so a class-name scan reports live contracts as
  dead. A naive scan of 131 contracts returned 11 "inert"; after checking `/root/` lookups,
  `.tres` bindings and the JavaScript seam, **4** survive.

Both directions were checked for every finding in §3. This is worth institutionalising: the
duck-typed handle is also a real coupling defect, because renaming `evaluate` breaks the
cadence engine at runtime rather than at parse time.

## 2. Deliverable 1 — code-state evidence matrix

Verdicts: **already-built** · **confirmed** (slice's starting-state description is accurate
and the work is unbuilt) · **amend** · **reorder** · **investigate**.

Per the re-scope, *already-built* is a first-class verdict, not an anomaly.

### 2.1 UIREC-V1 — shared record-screen UI (6 slices)

None of the named types exist: `RecordScreenState`, `StateView`, action descriptors — no
file, no symbol, no reference anywhere in `scripts/`, `scenes/` or `resources/`.

| Slice | Verdict | Evidence |
|---|---|---|
| S01 pure screen state | **amend** | Type absent as specified, but two shared shells already own this ground — see below. |
| S02 read models / action descriptors | confirmed | Absent. |
| S03 wide/narrow adapters | **amend** | Same defect as `LIB-V1-S02`: "wide/narrow" predates the size-class model. `ResponsiveLayout` ships Compact/Medium/Expanded (`:59-66`); *Medium is the case the wide/narrow framing has no answer for*. |
| S04 list/detail/action components | confirmed | Absent. |
| S05 input/a11y/scale/test contracts | confirmed | Absent. |
| S06 prove through one vertical adopter | **amend** | Its instruction — "adopt vertically in one real screen before general extraction" — has *already happened, twice, unplanned*. |

**The amendment S01 and S06 need.** `ModalScreen` (10 production consumers) and
`FocusNavigator` (4) are the de facto record-screen primitives. They were extracted without
this plan and now carry focus order, region transitions and the gated-entry ruling. Built as
written, UIREC-V1 introduces a **third** shell. The slice must state which of the two it
subsumes.

### 2.2 LIB-V1 — Campaign Library (7 slices)

| Slice | Verdict | Evidence |
|---|---|---|
| S01 read model and controller | confirmed, **naming collision** | `CampaignPackRegistry` supplies package discovery (`refresh/summaries/errors/find/playable_campaign_count`). No campaign, run, or save record model exists. **But `scripts/ui/CampaignLibraryScreen.gd` already exists** — 167 lines, self-described as a "player-facing bridge over the inert campaign archive services". A slice that builds "the Campaign Library" into a file of that name will silently collide. |
| S02 wide/narrow shell | **amend** (already flagged; now measured) | The row's 2026-08-06 respecify note is correct and its premise verified: `ResponsiveLayout` derives its class from **width alone** — zero occurrences of `landscape`, `orientation` or `aspect` in the whole autoload. |
| S03–S07 | confirmed | Lifecycle, profile flow, run/save flow, transfer surfaces and hardening all absent. `CampaignPackInstaller`/`Exporter` exist and are consumed, so S03 starts from real services. |

### 2.3 PREP-V1 — Prep, Explore, economy (8 slices)

| Slice | Verdict | Evidence |
|---|---|---|
| S01 Prep shell and activity resolution | **amend — row text is stale in the reader's favour** | See below. |
| S02 subject-first Explore + record-UI adoption | confirmed | Absent. Also the producer of shared primitive 5 — see §4.3. |
| S03 inventory and Convoy core | confirmed | Verified exactly as claimed: `InventoryEntry` (`scripts/resources/InventoryEntry.gd`) has **no** instance id field; `GameState.party_items` is `Array[String]` (`:158`) and is the whole convoy runtime, with a codec pair at `:771`/`:385`. |
| S04 on-map Trade | closed as superseded | Verified no row depends on it. |
| S05 wallets, Shop, quote/commit | confirmed, **line refs drifted** | `ResourceLedger.reserve()` (`:11`) — zero callers. `CostSpec.allow_partial` (`:12`) — zero callers. Both dead as claimed. `format_party_gold` is at `MapMenu.gd:78` (row says `:75-79`); the autosave trigger registry is at `CampaignManager.gd:75` (row says `:67`). |
| S06 Explore activities and Training | confirmed | Absent. |
| S07 Forge | confirmed | `InventoryEntry.forged_mods` exists (`:15`) and is written by nothing — reserved and unread, as the row states. |
| S08 Prison | confirmed | Absent; correctly last. |

**S01's stale text.** The row's stated blocker — *"zero `req.*` keys exist in any content
file, and TextDB is not an autoload"* — **is no longer true.** `TextDB` is the *first*
autoload in `project.godot` (`:29`), and `engine_data/text/en/core.json` ships 30 keys (25
`req.*`, 3 `overworld.*`, 2 `menu.*`). `UNMET-REASON-TEXT-TABLE-2026-08-20` delivered it;
the row stays `in_review` only pending the round. **The dependency is satisfied in code.**

Two S01 claims that *do* still hold:

- **Finding V070-10 is unrepaired.** `PrepScreen._refresh_rules_summary` still stringifies
  structured rule values with `str(row.get("value", ""))` and the Label is still a sibling
  above the Scroll. Line numbers have drifted: **`:97-110`**, not `:93-106`.
- **`PrepActivityRegistry` is inert** — see §3.1. This is on S01's critical path and is new.

### 2.4 TEXT-V1 — text entry (6 slices)

**This family is the matrix's main correction: four of six slices are already built.**

| Slice | Verdict | Evidence |
|---|---|---|
| S01 request/result/sanitization/escaping | **already-built** | `TextEntryRequest` carries every field the slice names: purpose, initial text, `max_characters`, `max_utf8_bytes`, `allowed_characters`, `normalizer`, `validator`, `multiline`, `private_value`, `allow_empty`. BBCode escaping is `scripts/shared/BBCode.gd`. |
| S02 entry-mode registry and setting | **already-built** | `TextEntryRegistry` + `SettingsManager.text_entry_mode` with auto-detection. `system` is reserved with no backend, exactly as specified. |
| S03 licensed ASCII grid presenter | **already-built** | `GridTextEntryPresenter` + `TextEntryLayout`. |
| S04 hardware keyboard presenter | **already-built** | `HardwareTextEntryPresenter`, wired in `TextEntryService._ready()`. |
| S05 approved naming caller adoption | **confirmed — and this is the whole remaining gap** | **No production code constructs a `TextEntryRequest` or calls `begin()`.** Every reference is inside `scripts/ui/text_entry/` or a test. The only production references to `TextEntryService` at all are two copies of a `_text_entry_owner_active()` guard (`ModalScreen.gd:180`, `FocusNavigator.gd:44`) and the web test bridge. |
| S06 platform seam / deferred modes | confirmed blocked, **scope larger than stated** | The row says remove the `system` row from Settings and keep the registry constant. `system` is in **two** vocabularies: `SettingsManager.VALID_TEXT_ENTRY_MODES` (`:104`) *and* `TextEntryRegistry.VALID_MODES` (`:4`). |

The portfolio's §7 slice 0 (Windows input ownership / FileDialog) is also built:
`scripts/ui/FileDialogInputGuard.gd`.

**Consequence for sequencing.** `TEXT-V1-S01` is one of four rows gated on this review, and
it is already built. The family's real remaining work is S05's adoption plus S06's
two-vocabulary edit.

### 2.5 DRC-V1 — Dialogue, recruitment, capture, custody (12 slices)

**Nothing exists.** No file matching `*Dialog*`, `*Conversation*`, `*Custody*`, `*Recruit*`,
`*Capture*` or `*Prison*` outside `DisplayConfirmDialog.gd` and `FileDialogInputGuard.gd`,
which are unrelated. All twelve slices: **confirmed** unbuilt with accurate starting state.

Two of the portfolio's §8 mandatory gates are measurably unmet, as expected at this stage —
recorded because both are cheap to check and neither has a test asserting it:

- **`ConditionManager` is still a stub**, and more than the gate claims: 37 lines, 5
  functions, every parameter underscore-prefixed, and **zero references anywhere in the
  repository — not from production, not from a test, not by `/root/ConditionManager`.** It
  is a registered autoload that nothing has ever called.
- **`TurnManager` still emits results directly** (`bus.map_victory.emit()` `:1056`,
  `bus.map_defeat.emit()` `:1039`, `:1058`). Moving this behind the atomic map-end resolver
  is `DRC-V1-S09`'s job and remains correctly ordered.

## 3. Deliverable 2 — architecture collision report

The re-scope's §3 supplied three collisions as a down payment. All three are re-verified
below, and **three more** are added.

### 3.1 Inert foundations — the shape, generalised (NEW: two more instances)

The re-scope found this twice (`RequirementFormulaRegistry`, then `RequirementSystem`
reproducing the property it was built to cure) and asked whether anything else in the
portfolio is inert. Scanning all 131 production `class_name` declarations and autoloads,
then filtering the false positives described in §1:

| Contract | State at `8c62bf16` | Assessment |
|---|---|---|
| `RequirementFormulaRegistry` | 0 production refs; 1 test ref (`test_formula_registries.gd:63`) | **Unchanged.** Rowed as `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`. Deletion is clean. |
| `RequirementSystem` | **No longer inert.** `CadenceEngine.gd:169` calls `evaluate`, `:46` calls `validate` | Cured — but by a duck-typed handle (§1), so the coupling is invisible to every static check. |
| **`PrepActivityRegistry` + `PrepActivityDef`** | `PrepActivityRegistry`'s only non-test reference is a **comment**. `PrepActivityDef` is referenced only by its own test. `PrepScreen.gd` references neither. | **NEW, and the most consequential.** `B3-PHB-REGISTRY-2026-07-19` is `completed` and is a dependency of `PREP-V1-S01` — the slice this whole review exists to unblock. A registry, its resource type, and a green suite, adopted by nothing. Third instance of the shape. |
| **`ControllerService` + `ControllerWebBridge`** | Inert **on `agent/integration`** | **NEW.** See below. |
| every other registry | `CostFormulaRegistry`→`ResourceLedger:76`; `HitFormulaRegistry`→`CombatResolver`; `RangeFormulaRegistry`→`WeaponData`+`EntitySchemaRegistry`; `SkillEffectRegistry`→`SkillHandler`; `ItemEffectRegistry`→`ItemHandler`+`DataManager`; `ObjectiveConditionRegistry`, `RegistryCatalog`, `SavePolicy`, `MapLedger`, `CampaignPack*` all consumed | **Honest negative.** The registry family is healthy. The defect is confined to the cases named above, and that bound is itself worth recording. |

**The controller case, stated precisely, because it is easy to overstate.** On
`agent/integration` the on-screen controller cannot function in a web build: the browser
shell (`tools/web/controller_shell.js`) defines `window.PrometheusController` and waits for
`setBridge(fn)`; the engine side calls `setBridge` only inside `ControllerWebBridge.install()`
(`:115-119`); and **nothing in the repository calls `install()` except the test suite.**
Without it `state.bridge` stays null, so no press reaches the engine, and `publish()` is
never reached, so nothing is drawn.

This is **not** a defect to fix here. The call exists —
`ControllerService.gd:144`, on `agent/from-integration/mobile-controller-web-wiring`, which
owns the `in_progress` row. The finding is about the *integration line*: that branch is **27
ahead and 502 behind**, so anything cutting a build from `agent/integration` today ships an
inert on-screen controller, and the gap widens every week the branch stays out.

### 3.2 Duplicate machinery — three lazy `TextDB` resolvers (NEW)

`RequirementSystem.render_reason` (`:199`), `MainMenu._menu_text` (`:206`) and
`CampaignManager._overworld_text` (`:357`) each independently resolve
`get_node_or_null("/root/TextDB")`, check `has_method("tr_key")`, and **fall back to
returning the raw key**. Two of the three carry a comment saying they do it "the same way
`RequirementSystem.render_reason` does" — the duplication is known and was written down
instead of removed.

The sharper half is the **coverage asymmetry**. `test_text_db.gd:55` asserts the shipped
table covers the whole vocabulary — driven by `RequirementSystem.all_text_keys()`, which
enumerates *predicates only*. The 3 `overworld.*` and 2 `menu.*` keys were authored by hand
into the same table with no registry to enumerate them, so **nothing asserts they exist**.
Its own comment states the principle it cannot reach: *"nothing else notices if they go
unauthored — the player just reads the key id."*

That is the seventh instance of the silent-default shape, and it generalises exactly like
§3.3 does: **a future non-predicate key family inherits nothing and fails nothing.**

### 3.3 Ownership — the shell ruling is not inheritable (re-verified, with counts)

Confirmed unchanged, and now quantified: `ModalScreen` has **10** production consumers,
`FocusNavigator` **4**, and **`OverworldScreen` uses neither** — it contains no reference to
either class. The two shells also duplicate `_text_entry_owner_active()` verbatim
(`ModalScreen.gd:180`, `FocusNavigator.gd:44`), which is the same defect one level down: no
single availability/ownership authority, so each surface reimplements the helper.

**This is now the third independent confirmation of one structural argument** — §3.2's key
families, §3.3's availability surfaces, and the pack-freshness case in
`PACK-SCHEMA-FRESHNESS-CHECK-2026-08-21`. Each is "a new instance of a category inherits
nothing and fails nothing." That is direct evidence for the design answer already recorded
on `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20`: **prefer a test-time check over shipped
surfaces to a shared builder**, because a builder only helps surfaces written after it lands.

### 3.4 Duplicate machinery — two formula evaluators (re-verified)

Unchanged from the re-scope. `RequirementFormulaRegistry` (38 lines) beside
`FormulaEvaluator` (272 lines, consumed by `RequirementSystem.gd:7`). One test reference, no
production caller. `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20` remains a deletion plus a test
edit.

## 4. Deliverable 3 — dependency edges and plan text

### 4.1 The graph is mechanically clean

Computed over all 451 rows: **no cycles**, **no dangling dependency ids**, and the
superseded `REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` has **no remaining dependents**
— its four edges (`UIREC-V1-S01`, `PREP-V1-S01`, `TEXT-V1-S01`, `DRC-V1-S00`) are correctly
repointed at this row.

### 4.2 Every previously flagged inversion is paid

R1 and the prep/economy plan flagged four producer/consumer inversions. All verified fixed
by transitive-path check, not by reading the prose that claims they were fixed:

| Primitive | Producer | Consumer | Ordered? |
|---|---|---|---|
| `[EPUX-24]` transaction core | `PREP-V1-S05` | `DRC-V1-S05`, `PREP-V1-S07` | yes |
| `[EPUX-21]` quantity primitive | `PREP-V1-S05` | `DRC-V1-S05` | yes |
| `[EPUX-11]` pending-items tray | `PREP-V1-S03` | `DRC-V1-S09` | yes |
| `[EPUX-06]` activity snapshot/receipt | `PREP-V1-S05` | `DRC-V1-S10`, `PREP-V1-S06` | yes |

### 4.3 A fifth inversion, one layer out — and it is live

`PREP-V1-S02` builds **shared primitive 5**, the `[DSX-S1..S3]` distribution shell, and its
own row states: *"Nine consumers, four of them outside this epic (loadout, skills,
techniques, battalions)."* Those four are named in prose. **None of them is ordered after
`PREP-V1-S02`:**

| Named consumer | Row | Status | Deps | Ordered after `PREP-V1-S02`? |
|---|---|---|---|---|
| loadout | `B4-IEQ-ITEMS-EQUIPMENT-2026-07-23` | **`in_progress`** | **none** | **no** |
| battalions | `SYS-BATTALIONS-2026-07-23` | planned | none | no |
| skills | `B5-SKILLS-CONDITIONS-2026-07-23` | planned | 1 (unrelated) | no |
| (dependent-choice layer, also a consumer) | `B4-PREP-MAP-DEPLOYMENT-2026-07-22` | planned | 3 | no |

This is the same failure the re-scope diagnosed one level up — *the ordering was recorded in
prose and not in the graph, and the graph is what anyone actually reads* — and it is not
hypothetical: **`B4-IEQ-ITEMS-EQUIPMENT` is `in_progress` with zero dependencies**, so it can
build a loadout surface today, before the shell it is supposed to adopt exists. That is how
`B3-REQ`/F16 built ahead of a gate no edge expressed.

All four edges were checked for cycle-safety: **none of the four is upstream of
`PREP-V1-S02`, so all four are safe to add.**

**Applied here (three planned rows):** `SYS-BATTALIONS`, `B5-SKILLS-CONDITIONS` and
`B4-PREP-MAP-DEPLOYMENT` now depend on `PREP-V1-S02`.

**Held for the owner (one row):** `B4-IEQ-ITEMS-EQUIPMENT-2026-07-23` is `in_progress`.
Adding the edge is correct on the evidence but would place active work behind an unbuilt
slice, which is a scheduling decision rather than a mechanical correction. Recorded in §6.

### 4.4 A named consumer with no row

`DISTRIBUTION-SURFACE-2026-08-15` (`completed`) names nine consumers in its title, including
**techniques** — and no row anywhere has a techniques surface as its build subject. Either
`B5-SKILLS-CONDITIONS` covers it and should say so, or a row is missing. Flagged rather than
created, because inventing a row for a surface nobody has scoped would be worse than the gap.

## 5. What this review did not do

- **No product-code changes.** The re-scope permits evidenced in-scope fixes, and three are
  now clearly warranted — the `PrepActivityRegistry` adoption question, the duplicated
  `TextDB` resolvers, and V070-10's one-line reparent. None was made, because each belongs
  to an owning row and the round is outstanding. They are findings, not fixes.
- **No first-tranche readiness verdict** — deliverable 4, dropped by the re-scope.
- **`ControllerWebBridge` was not wired up.** The fix exists on its own branch and that
  branch's row is `in_progress`; merging 27 commits that are 502 behind is its own job.
- **No slice re-write.** Four slices are marked **amend** (§2.1 S01/S03/S06, §2.2 S02) and
  one **already-built** family needs its rows re-statused. Both are edits to rows and plans
  that other work depends on, and are listed in §6 rather than applied silently.

## 6. What the next session should pick up

1. **Re-status `TEXT-V1-S01..S04` as built** and reduce the family to S05 (caller adoption,
   which has zero callers today) and S06 (a two-vocabulary edit). `TEXT-V1-S01` is one of the
   four rows this review gates and it needs no build.
2. **Owner call: `B4-IEQ-ITEMS-EQUIPMENT` → `PREP-V1-S02`** (§4.3). It is `in_progress` and
   unordered against the shell it must adopt.
3. **`PrepActivityRegistry` adoption** (§3.1) — decide whether `PREP-V1-S01` adopts it or
   whether `B3-PHB-REGISTRY` shipped the wrong shape. Do this *before* S01 starts, or S01
   builds activity resolution a second time.
4. **`UIREC-V1-S01`/`S06` amendment** (§2.1) — name which of `ModalScreen`/`FocusNavigator`
   the record-screen foundation subsumes, before it becomes a third shell.
5. **`AVAILABILITY-SURFACE-GATE-GUARD`** now has a third evidenced instance behind it (§3.3)
   and, in §3.2, a second surface a check could cover: text-key families with no registry to
   enumerate them.
