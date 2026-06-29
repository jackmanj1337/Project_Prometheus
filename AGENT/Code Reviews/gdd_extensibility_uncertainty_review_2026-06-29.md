# GDD Extensibility Uncertainty Review (2026-06-29)

**Scope:** code-review-style risk note from the GDD/docs audit. This report records
items that should not be silently decided during a framing-only documentation pass.

## Findings

### Medium — Movement types are documented as future registry data, but enforcement is still a closed list

**Location:** `AGENT/GDD/GDD_03_Units_Classes.md:64`; `scripts/shared/GameConstants.gd:69`; `AGENT/Docs/check_docs.py:614`

**Problem:** The GDD now correctly says movement/vulnerability groups should become
data-driven registries, but the live code and doc checker still mirror a fixed
movement-type set. That is acceptable for the implemented slice, but it will conflict
with `[EXT]` if future content needs a new movement category and the only path is
editing `GameConstants` plus `check_docs.py`.

**Root cause:** V021-11 needed a mechanical guard for today's class data before the
author-registry layer existed.

**Recommended fix:** When `B3-STAT-REGISTRY`/terrain movement migration begins, either
move movement-type ids into a manifest-backed registry that `check_docs.py` reads, or
write an explicit engine-only exception explaining why movement categories stay closed.

### Medium — Stat registry target needs a storage migration decision

**Location:** `AGENT/GDD/GDD_01_Architecture.md:1348`; `scripts/resources/ClassData.gd:44`

**Problem:** The docs now point stat names at `B3-STAT-REGISTRY`, but the implemented
schema still relies on `ClassData.STAT_KEYS` and direct exported fields. That leaves an
open implementation choice: migrate to dictionary-backed stat storage, keep exported
starter fields with a registry compatibility view, or split core stats from extension
stats.

**Root cause:** F14/`[STM]` was ratified after the implemented class/unit schema had
already baked the starter stat set into resources, UI, growths, caps, and tests.

**Recommended fix:** Make the first stat-registry build plan decide storage shape,
save compatibility, missing-stat defaults, and UI/cap behavior before adding Charisma,
Command, or dynamic-pricing stats.

### Medium — EXP curve is now documented as a preset, but the live resolver still owns the table

**Location:** `AGENT/GDD/GDD_02_Core_Mechanics.md:423`; `scripts/core/CombatResolver.gd:57`; `scripts/units/Unit.gd:482`

**Problem:** The GDD reframes combat EXP and staff EXP as preset data targets, but the
current implementation keeps the combat EXP table in `CombatResolver` and staff EXP in
`GameConstants`. That is fine until `B4-PXP`, but it is a likely place for future
hardcoded balance drift.

**Root cause:** EXP was implemented before action-authored `exp_award`, CampaignRules
profiles, and the broader PXP framework were planned.

**Recommended fix:** In `B4-PXP`, move combat EXP curve selection and non-combat action
EXP awards behind data/profile inputs, with the current table and staff value shipped as
developer presets and tests proving the preset matches today's behavior.

## Open Questions

- Should movement categories be part of the stat/class registry family, the terrain
  movement registry, or their own small registry?
- Should core stats remain exported fields for Godot-editor ergonomics while extension
  stats live in dictionaries?
- Should combat EXP curves be CampaignRules profiles, PXP profiles, or a small resource
  type consumed by both?

