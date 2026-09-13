---
Role: dated
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-09
---

# Non-Schema Registry Slices — Next-Session Handoff

**Track IDs:** `B3-STAT-REGISTRY` (DoD#2 guard + `[STM-5]` policy), `B5-AI-COMPOSITION` (`target_policy`).
**Written:** 2026-07-09 (session `2026-07-09e`), while `v0.3.0.d` is out for playtest.
**Companion:** [`open_registry_conversion_checklist_2026-06-28.md`](../design/open_registry_conversion_checklist_2026-06-28.md),
[`extensible_stat_model_open_questions_2026-06-25.md`](../registers/extensible_stat_model_open_questions_2026-06-25.md),
[`ai_first_build_design_2026-06-22.md`](../design/ai_first_build_design_2026-06-22.md).

## Why this handoff exists

Two open-registry slices landed this session on `v0.3.0-features`: the AISpec
composition seam (`a187783`) and the stat-vocabulary registry (`7221664`). Both
shared one safe shape — **an existing closed `match`/const list → a registry the
engine reads, with zero save-schema change and no front-running of unbuilt
design.** I then swept the whole conversion checklist for the *next* items that
fit that same shape. **Result: most remaining checklist rows do NOT fit** — they
are F1-gated, reference systems that don't exist yet, or are already
single-source-of-truth. Only three genuinely-buildable non-schema slices remain,
captured here so they aren't lost.

**Playtest-gated work stays primary.** These three are the "while waiting"
headless stream, same as the two slices that preceded them.

## What is NOT buildable now (don't re-derive this next session)

- **F1-gated / schema-affecting** (planning-only until the F1 lock): objective
  conditions `[TCV-4]`, MET triggers/actions, resource types & cost scopes,
  proficiency tracks, difficulty bundles, and the *storage* halves of AI
  (`ai_awake`) + stat (`extra_stats`). See GDD_10 "Gated build items".
- **Reference systems not built yet**: dialogue commands/effects, AoE/shape
  generators, F5 conditions, F16 predicates, activities `[SAC]`, and target
  filters (grep found **zero** `target_filter` code — unbuilt). Building the
  registry before the feature is designed = inventing the wrong shape.
- **Already single-source-of-truth**: `GameConstants.VALID_MOVEMENT_TYPES` /
  `VALID_VULNERABILITY_GROUPS` / `VALID_COMBAT_FAMILIES` / `VALID_WEXP_TRACKS`
  are centralized const vocabularies with check_docs validation already. Making
  them *author-extensible* is F1/manifest data — gated.
- **`TileActions`** (`scripts/shared/TileActions.gd`) *looks* like the same shape
  (closed `ACTION_LABELS` + `match action_id`), but only `seize`/`escape` are
  wired; `shop`/`visit`/`activate` are placeholders whose real registry shape
  (per-instance labels, multiple activatables per tile) is driven by `[SAC]`,
  which is not designed. **Hold** — converting now front-runs undesigned
  structure.

---

## Slice 1 — DoD#2 guard for the stat registry *(recommended first; smallest, lowest-risk)*

**Goal.** Stop the "7 hardcoded stat copies" debt that `7221664` just paid down
from silently regrowing. The STM plan explicitly calls for this
(`extensible_stat_model_open_questions_2026-06-25.md` §STM-3 "Gotchas": *"Add a
check_docs/lint guard banning **new** direct base-stat field reads, steer to
`get_effective_stat`"*).

**Scope — confirm with owner BEFORE building (the false-positive risk is real):**
- The guard must ban **new** hardcoded stat-label maps / stat-id list literals
  outside `scripts/core/StatRegistry.gd` (e.g. a fresh `{"strength": "Str", ...}`
  dict or a `["hp","strength",...]` growth list in another file).
- **Open question for the owner:** should it also ban **new** direct base-stat
  field reads (`data.strength`, `unit.data.speed`, …) and steer to
  `get_effective_stat(name)`? The STM plan wants this, BUT legacy base-stat fields
  are intentionally still allowed for the shipped stats, and `SaveCodec`'s field
  allow-list + `PromotionScreen._promotion_preview_text` read `data.get(stat)` /
  `data.<stat>` legitimately. A naive grep will false-positive. Recommended
  narrower v1: **only** guard against re-introducing hardcoded stat *lists/label
  maps* (the exact debt just removed); defer the direct-field-read guard until the
  storage slice (F1) actually makes those reads wrong.

**Where.** `AGENT/Docs/check_docs.py` — add a new numbered check (next after
[26]) following the existing code-scanning checks ([13] class movement types,
[22] danger-mode vocab, [24] gamepad bindings, [25] input modes are the pattern
to copy). It greps `scripts/` (excluding `StatRegistry.gd` and `scripts/tests/`)
for the banned literal shapes.

**DoD (this is itself DoD#2):** land the check in the same change; it must run
green on the current tree and fail on a deliberately-added violation (test the
failure path manually before committing). No GDD behavior change → docs-only
commit path, but bump the register's cross-reference note.

**Effort:** ~1-2 hours incl. the failure-path check.

## Slice 2 — `[STM-5]` referenced-but-unregistered stat = hard load error *(fold in with Slice 1)*

**Goal.** Close the OPEN half of `[STM-5]`
(`extensible_stat_model_open_questions_2026-06-25.md` §STM-5). Policy already
decided there: **registered-but-unset = soft default** (already true via the
read path); **referenced-but-unregistered = hard load-time validation error**,
not a silent runtime `0`.

**Non-schema boundary.** Only the *read/validation policy* is walkable now. The
*storage* side (`extra_stats`, the `CampaignRules` author registry) is F1-gated —
do NOT build it. So "registered" for this slice means
`StatRegistry.GROWTH_STAT_IDS + DISPLAY_ONLY_STAT_IDS` (the engine vocabulary),
not an author registry yet.

**Where.** Extend `DataManager` boot validation (same seam as the
`activation_chance_stat` check that `7221664` already routes through
`StatRegistry.is_growth_stat`). Any authored place that *names* a stat — currently
skill `activation_chance_stat`; audit for others (`[TCV-3]` tag-scoped effects and
`[REQ-16]` stat terms are the future consumers, but check what's implemented
today) — must reject an id not in the registry with a loud `errors.append(...)`.
Note: `activation_chance_stat` is already validated; the new work is auditing for
*other* stat-name reference points and giving them the same hard-fail.

**Watch-out.** Confirm you are not duplicating the existing
`activation_chance_stat` check — this slice is about finding the *other* stat-name
reference sites, not re-doing that one.

**DoD (DoD#1 + #2):** add a test that a resource referencing an unregistered stat
fails validation (mirror `test_data_manager`'s "berserk" AI-profile rejection);
update the register `[STM-5]` from OPEN → RESOLVED with the resolved-in note;
GDD_01 stat-model note gets one line on the reference policy.

**Effort:** ~half a day incl. the reference-site audit + test.

## Slice 3 — AI `target_policy "weakest"` thread *(independent; larger of the three)*

**Goal.** Extend the AISpec engagement axis with the `target_policy` `weakest`
thread flagged non-schema in `2026-07-09d` (`ai_first_build_design_2026-06-22.md`
§9). Today `resolve_ai_spec` sets `engagement: "nearest"` for all three shipped
profiles; add a `weakest` engagement/target-policy that the disposition handlers
honour when selecting a target.

**Non-schema boundary.** `target_policy` is a profile-data axis resolved at
runtime — it does **not** need the `ai_awake` save field, so it is unblocked
(unlike AI build-slice step 3's `territorial`/`tethered`, which are F1-gated). Do
NOT pull in the `ai_awake` dispositions here.

**Where.** `scripts/core/AISpec.gd` (add the axis field if not present) +
`scripts/core/AIProfileRegistry.gd` (a profile that selects it) +
`scripts/core/EnemyAI.gd` (the disposition handlers' target-selection step reads
the engagement/target-policy instead of assuming nearest). **Preserve the RNG
chain** — target-selection order feeds the deterministic combat seam; add a
determinism test proving the chain is unchanged for existing `nearest` profiles
and deterministic for `weakest`.

**Scope caution.** Only open the vocabulary that ships a behavior (same
discipline as AISpec steps 1-2: no `weakest` id registered without the handler
honouring it). Do not register the full MVP preset list — that rides step 3.

**DoD (DoD#1 + #2):** `test_ai_profile_registry` + `test_enemy_ai` extended;
GDD_08 §Architecture updated; register `[AIP]` note; RNG determinism suites green.

**Effort:** ~half to one day (the target-selection refactor + determinism proof
is the bulk).

---

## Recommended order

1. **Slice 1** (guard) — closes out `B3-STAT-REGISTRY` DoD#2, smallest, lowest
   risk. **Confirm the direct-field-read scope question with the owner first.**
2. **Slice 2** (`[STM-5]` policy) — same DataManager/validation area as Slice 1,
   natural to fold in; resolves an OPEN register half.
3. **Slice 3** (`target_policy`) — independent and larger; take it if the stat
   slices are done and playtest is still out.

After these three, the non-schema open-registry stream is **drained** until the
F1 schema-lock unblocks the storage slices (AI `ai_awake`, stat `extra_stats`)
and the `[TCV]`/MET/effect systems. At that point the checklist's remaining rows
become buildable in Band order.
