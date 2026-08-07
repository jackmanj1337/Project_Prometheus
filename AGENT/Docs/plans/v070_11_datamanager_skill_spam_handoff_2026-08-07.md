---
Type: plan
Status: In progress
Last verified: 2026-08-07
Tracker: V070-11-SKILL-ID-SPAM-2026-08-07
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Next-session handoff — V070-11: unresolved skill ids spam `push_error`

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under `V070-11-SKILL-ID-SPAM-2026-08-07`.

Branch: `agent/from-integration/v070-11-skill-id-spam`, cut from `agent/integration`
at `487dafaf`.

## Why this is the next thing

Two reasons, and the second is the one that decides the ordering.

1. **It is a real defect from the v0.7.0 Windows return.** Finding V070-11: the
   returned logs carry roughly 3,200 `ERROR:` lines from unresolved skill ids. The
   volume is the problem, not the individual message — it makes the log expensive to
   grep and trains whoever triages the next return to skim past `ERROR:` lines. That
   is exactly where every v0.7.0 finding came from.

2. **`scripts/autoloads/DataManager.gd` is the last claim collision blocking the
   implementation backlog.** After the 2026-08-07 claim audit, 8 of the 12 band
   implementation plans can be cut onto their own branch cleanly. The remaining four
   — `B4-IEQ-ITEMS-EQUIPMENT`, `B5-AI-PROFILES-VALUATION`, `B5-SKILLS-CONDITIONS`,
   `B5-SOURCE-STYLE-COMBAT` — collide on this one file and nothing else. Landing this
   fix and releasing the claim takes the backlog from 8/12 to 12/12.

## The defect, precisely

`DataManager.get_skill()` — `scripts/autoloads/DataManager.gd:1633-1637`:

```gdscript
func get_skill(id: String) -> SkillData:
	if not _skills.has(id):
		push_error("DataManager: unknown skill id '%s'" % id)
		return null
	return _skills[id]
```

It pushes an error **per call**, and the callers are hot:

| Caller | Line | Frequency |
|---|---|---|
| `scripts/skills/SkillHandler.gd` | 168, 447 | per combat exchange, per unit, per equipped skill |
| `scripts/ui/LevelUpScreen.gd` | 158 | per level-up |
| `scripts/ui/ReclassScreen.gd` | 164 | per screen build |
| `scripts/ui/PromotionScreen.gd` | 175 | per screen build |

One authored typo in a pack therefore produces thousands of identical lines over a
session. The message itself is correct; its cardinality is wrong.

## Why the one-line "just delete the push_error" fix is wrong

The missing id is **still a content-authoring fact that must be reported** — silently
returning `null` is how the other five silent-default failures in this codebase were
born (see `AGENT/Code Reviews/playtest_v0.7.0_root_cause_review_2026-08-07.md`).

The good news is that the reporting already exists and is already once-per-activation.
`_check_class_refs()` (`DataManager.gd:472-482`) already walks every class's
`skill_unlocks` and appends

```
DataManager: class '%s' skill_unlocks[%s] '%s' not found
```

into the `errors` array that `collect_validation_errors()` (`:159`) builds and that
lands in `_activation_errors` (`:206`). `_activation_errors` is exposed through
`content_status()["errors"]` (`:360`), and as of the V070-05 fix on
`agent/from-integration/v070-blocker-fixes`, `NewGameScreen` renders that list to the
player instead of failing silently.

**So the diagnostic path is built. `get_skill()` is duplicating it per call.**

## Fix order

1. **Establish coverage first.** `_check_class_refs` covers skill ids reached via
   `ClassData.skill_unlocks`. Confirm whether every unresolved-id call site is
   reachable from a document the activation validator already walks — in particular
   check unit-level and item-level skill references, since the return's spam volume
   suggests a path the validator does not cover. If a path is uncovered, extend the
   activation-time validator to cover it. **Do this before touching `get_skill()`**,
   or the change trades noise for silence.
2. **Demote the per-call report.** `get_skill()` stops calling `push_error` for a
   miss. Returning `null` stays — callers already null-check.
3. **Record the fact once per content activation** in `_activation_errors`, matching
   the existing message style so `content_status()["errors"]` reads consistently.
4. **`get_item()` has the identical shape** (`DataManager.gd:1622-1626`). Fix it in
   the same change — it is the same defect, one lookup over.

## Tests

Add to `scripts/tests/test_data_manager.gd`:

- activating a pack whose class references an unknown skill id yields **exactly one**
  entry in `content_status()["errors"]` naming that id;
- calling `get_skill("nonexistent")` N times adds **no** further entries and still
  returns `null`;
- the equivalent pair for `get_item()`.

The second assertion is the regression that matters — it is the one that fails against
today's source, and the one that keeps the spam from coming back.

Full suite: `bash run_tests.sh`. In a fresh clone use
`bash scripts/ci/run_headless_tests.sh` — `--quit` alone rebuilds neither the import
nor the class cache, and a cold checkout will fake several red suites.

## Claim state — read before starting

`scripts/autoloads/DataManager.gd` is claimed by `IMPL-ZERO-CONTENT-FAMILIES`, which
was narrowed from 41 paths to 6 on 2026-08-07. The claim transfer to this row is
recorded in the tracker.

`IMPL-ZERO-CONTENT-FAMILIES` retains `scripts/data/EntitySchemaRegistry.gd` and
`scripts/resources/CampaignTier2Validators.gd` for **V070-02** (the `uses_mag`
extractor bug where every tome deals STR−DEF). That is separate work with a separate
branch — do not fold it into this one. V070-02 spans both pack repos and requires
re-cutting both Proving Grounds branches; this row is engine-only and self-contained.

## Definition of done

- Both `get_skill` and `get_item` report a miss once per content activation, not per
  call.
- Every previously-spamming path is still reported somewhere a player and a triager
  can see.
- New regression assertions present and green; full suite green.
- `scripts/autoloads/DataManager.gd` released back to the pool, and the four blocked
  band rows noted as unblocked.
