# Session Note - 2026-07-26 (Phase 0: text-entry governance)

Phase 0 of the post-walk implementation order. This branch carries the two
governance rows; the security fix is on `agent/from-integration/bbcode-injection-hardening`
(see `2026-07-26-phase0-bbcode-hardening.md`).

## What was done

### RULE-MINIMISE-FREE-TEXT-2026-07-26 — TEXT-06 ratified

The rule lands in `GDD_07_Input_Cursor.md`, which owns input modes: **no v1 feature
may REQUIRE free text; naming is the single exception.** The section records *why*
the rule exists rather than just an on-screen keyboard — Godot's virtual keyboard is
Android/iOS/Web only, so on Windows and the Steam Deck `LineEdit.virtual_keyboard_enabled`
does nothing at all, and controller text entry measures ~6–7 WPM regardless of
layout. It also states explicitly that the in-game keyboard being built does **not**
reopen the drag/drop, stock-search, or forge-alias cuts.

### DoD#2 enforcement — `check_docs.py` [42]

A prose rule is not mechanically checkable, but *"a new free-text field appeared"*
is. The check scans every `scenes/**/*.tscn` for `LineEdit`/`TextEdit` nodes against
an allow-list holding exactly two today, both in PrepScreen:

- `SlotId` — TEXT-12 ratified that ids become generated, so this field is expected
  to **disappear** rather than grow.
- `SaveLabel` — the naming exception TEXT-06 allows.

Adding a row to that list is the deliberate act the rule exists to force. Two extra
failure modes are covered on purpose: a **stale** allow-list entry fails (the list is
the only record of why each field is permitted, so it must not outlive its field),
and the check fails if `GDD_07_Input_Cursor.md` stops mentioning TEXT-06 — an
allow-list enforcing a rule nothing states is worse than having neither.

**Negative-tested, not assumed.** A temporary `LineEdit` added to `MainMenu.tscn` was
caught with the correct path and line number; the scene was then restored and
verified clean. A check that has only ever passed proves nothing.

### RELEASE-CHECKLIST-DECK-OSK-2026-07-26 — TEXT-04's gate

Recorded in `GDD_00_Overview.md` under Platform Targets, which owns the release
definition.

**There is no standing release checklist in this repo** — only a stale per-version
`v0.4.0_release_checklist_2026-07-13.md`. TEXT-04's ruling was specifically that the
requirement must survive until Steam is actually targeted, so a per-version checklist
written after the fact was the wrong home. The entry records that Deck Verified
requires an automatic on-screen keyboard, that no GodotSteam dependency is taken now,
that the `system` entry mode exists as a seam so adoption is a drop-in, and that
whether a **custom** keyboard alone passes Deck Verified is unsettled by any source
and is a question for Valve rather than more desk research.

## Commits claimed

- `62f849cde9020c4709d1c821b2e3e99a2a0efb1d` — governance: ratify the TEXT-06 free-text rule and record the Deck OSK release gate

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS**, now 42 checks.
- Negative test of check [42] — failed correctly on an injected `LineEdit`, then
  passed again after restore; `git diff --stat scenes/` clean.
- Pre-commit on `62f849c`: gdformat/gdlint PASS (238 files), scene-integrity PASS,
  evidence-matrices PASS. Godot suite skipped — docs-only change.
- Full Godot suite run separately during the push gate: **all suites green**.

## Next

Phase 0 has one item left and it is **not mine to do**: `PACK0-LICENSING-2026-07-19`
and `PACKFE-LICENSING-2026-07-19` are owner decisions, and between them they block
`PACK0-ASSET-EXTRACTION`, `PACK0-LICENSE-V1`, and `FE-EXPORT-GUARD`.

Then Phase 1: `PLAN-PREP-ECONOMY-IMPLEMENTATION-2026-07-26` (unblocks six rows), and
`DISCUSS-DIALOGUE-UX` / `DISCUSS-RECRUIT-CAPTURE-UX` in parallel.

**Tooling defect found, not fixed:** `scripts/agent-start-task.sh` hard-fails on the
**deprecated** `agent-work-registry.py`, which reported an active-work conflict that
the canonical `coordination/check_tasks.py` does not see. It rolled back the branch
it had just created, so branch creation had to be done by hand. That deprecated
subsystem should be removed from the launcher.
