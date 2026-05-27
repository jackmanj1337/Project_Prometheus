# Testing Guide

Use this guide to decide what to run after a change and where to document new
coverage. It centralizes the project's current automated and manual validation
flow.

## Quick start

Run the headless suite with:

```bash
bash run_tests.sh
```

In a fresh clone or CI-style environment, use:

```bash
bash scripts/ci/run_headless_tests.sh
```

If you skip the automated suite after code changes, you risk shipping logic
breakage that manual spot checks will miss.

## What each test layer is for

### Headless GDScript tests

Primary location:

- `scripts/tests/`

Use these for:

- deterministic game logic
- state transitions
- menu/action gating
- progression rules
- save/runtime config behavior

Prefer adding or updating these whenever a change touches runtime logic.

### Manual validation

Primary location:

- `AGENT/GDD/GDD_Manual_Tasks.md`

Use manual validation for:

- live scene wiring
- UI layout and readability
- input flow
- camera behavior
- content authoring correctness
- multi-step gameplay loops that are awkward to cover headlessly

If manual coverage is not updated when the player flow changes, the doc will
teach the wrong regression path and future testing will drift.

## Current validation maps

These maps already carry specific validation roles:

- `Map 001 - Rout`
  - baseline combat, UI, Pair Up, More Info, and normal-roster checks
- `Map 900 - Hotseat Validation`
  - hotseat controller flow, faction turn handoff, selector/roster checks
- `Map 950 - Promotion Validation`
  - promotion, reclass, class-skill, and item-gated progression checks
- `Map 002 - Seize`
  - seize objective flow
- `Map 003 - Defeat Boss`
  - boss-kill objective flow
- `Map 004 - Escape`
  - escape objective flow
- `Map 005 - Defend`
  - survive/defend objective flow

When a new validation map is added, document:

- what behavior it is meant to prove
- what roster policy it uses
- what manual task section should call it out

## Recommended test selection

### If you changed code

Run:

1. `bash run_tests.sh`
2. the smallest relevant manual validation slice
3. the full broad regression sweep if the change touched shared player flow

Examples of shared player flow:

- New Game setup
- map launch routing
- turn flow
- HUD / menus
- hotseat control
- objective resolution

### If you changed only authored content

Usually run:

1. the relevant launch path through New Game
2. the targeted manual validation map or section
3. any nearby automated tests only if the content change exposed a logic gap

### If you changed docs only

No code test is required, but verify:

1. the doc points at the current canonical files
2. commands and paths still exist
3. the documented validation flow matches current maps and options

## When to add a headless test

Add or update a headless test when:

- the change affects logic that can fail deterministically
- a bug fix should stay fixed
- a rule is subtle enough that future edits are likely to regress it
- a menu/action should appear only under certain rules or state

Good examples in this repo:

- campaign-rule toggles gating Pair Up
- `GameState` next-map routing
- promotion / reclass progression behavior
- action-menu entries based on objective or unit state

## When manual coverage is enough

Manual coverage is usually enough when the main risk is:

- visual layout
- focus/camera/cursor behavior
- multi-surface UI flow
- scene hookup
- authored-map setup

If the underlying logic is also new, add both manual and automated coverage.

## Manual task ownership

`AGENT/GDD/GDD_Manual_Tasks.md` is the detailed playbook. Keep it detailed, but
use this file as the entry point.

When updating manual tasks:

1. add or adjust the relevant section
2. note the correct maps and expected roster source
3. state the expected result inline
4. remove stale assumptions instead of layering contradictory notes

Useful sections already in place:

- post-2026-05-19 regression sweep
- class / skill live playtest
- Pair Up pass 1 playtest
- More Info phase 1 live playtest
- hotseat validation playtest

## Common mistakes

- Testing a map by scene override instead of the normal New Game selector
- Forgetting that `fixed_test_roster` maps should not use the default roster
- Running only manual checks after a logic change
- Running only headless checks after a scene/UI wiring change
- Adding a validation map without documenting what it validates
- Leaving `GDD_Manual_Tasks.md` with stale map names or expected outcomes

## Practical workflow

1. Make the change.
2. Run `bash run_tests.sh` if code changed.
3. Launch the relevant map from New Game.
4. Run the smallest manual pass that proves the behavior.
5. Update `GDD_Manual_Tasks.md` if the validation story changed.
6. Record anything noteworthy in the session note.
