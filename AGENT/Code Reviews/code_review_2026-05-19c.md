---
Role: dated
---

# Code Review — 2026-05-19c (Session: DEBUG MODE banner + roadmap merge)

**Scope:** the four commits since the previous review's baseline (`f9e4e6d`):

| Commit  | Subject                                                    |
| ------- | ---------------------------------------------------------- |
| 69ed906 | Merge playtest 3 'later milestones' items into roadmap     |
| 51d860b | Add playtest 3 bug review (7 bugs diagnosed)               |
| 3e66f51 | Add red DEBUG MODE banner to the HUD on debug builds       |
| 53eb64a | DEBUG MODE banner now lists active debug aids live         |

Code touched: `scenes/ui/HUD.tscn`, `scripts/autoloads/EventBus.gd`,
`scripts/autoloads/GameState.gd`, `scripts/ui/HUD.gd`, `scripts/tests/test_hud.gd`
(new), `run_tests.sh`. The two doc commits (roadmap + review) are not code; they
are sanity-checked but not severity-rated. Per the code-review instructions, no
code is changed by this document.

---

## 1. Executive Summary

**Overall code quality: 8 / 10.** The session's behaviour-changing surface is
small (8 files, +724/−6, of which ~250 lines are doc), tightly scoped to the
debug aids, and every change shipped with either a new test or coverage by an
existing one (test_combat #10, test_unit_stats #11, new test_hud). The
backing-variable setter pattern correctly defuses the recursion trap the first
attempt fell into, and the signal-based refresh keeps the HUD free of polling.

The defects are nits — a doc checklist that under-enumerates what must be
deleted at release, one misleading test comment, and a small piece of
not-quite-dead text in the banner. No new correctness bugs and no regressions
in the 23-suite, 408-test pre-commit run.

Severity: Medium ×1, Low ×3, Critical/High ×0.

---

## 2. Issues Found

### 2.1 — Pre-Release Cleanup checklist under-enumerates the debug-banner removal surface
**[SEVERITY: Medium]**
- **File & Line:** `AGENT/GDD/GDD_10_Roadmap.md` § Pre-Release Cleanup, the
  bullet added in 3e66f51 ("Remove the debug-mode HUD banner").
- **Problem:** The bullet names only "the `DebugLabel` node in `HUD.tscn` and
  the `HUD._setup_debug_banner` / `_apply_debug_banner` code." The actual
  removal surface is larger:
    - `scenes/ui/HUD.tscn` — `DebugLabel` node ✓ (mentioned)
    - `scripts/ui/HUD.gd` — `@onready _debug_label`, `_setup_debug_banner`,
      `_refresh_debug_banner`, `_collect_active_debug_aids`, `_apply_debug_banner`,
      the call site inside `_ready` (`_setup_debug_banner()`), the section header
      and comment block. (`_apply_debug_banner` is mentioned; the other three
      methods + the `_ready` call site are not.)
    - `scripts/autoloads/EventBus.gd` — `signal debug_flags_changed()` and its
      comment block. **Not mentioned.**
    - `scripts/autoloads/GameState.gd` — `_debug_force_levelup_v`,
      `_debug_growth_boost_v`, both setter/getter blocks, and
      `_emit_debug_flags_changed()`. The bullet already covers the two flags
      themselves but does not call out that backing vars + emitter must go too.
    - `scripts/tests/test_hud.gd` — the live-toggle test block (lines 60–82) is
      tied to GameState debug flags and would either need updating or removal.
    - `run_tests.sh` — `test_hud` is only debug-specific *if* the test_hud file
      is removed; otherwise the suite needs to handle the absence of the banner.

  Future-me, two months from release, will follow the checklist literally,
  leave the EventBus signal + backing variables behind, and Future-me's later
  refactor will be confused by orphans.
- **Root Cause:** The checklist was written in the commit that added only the
  static banner (3e66f51); the follow-up commit (53eb64a) grew the feature into
  a signal-driven multi-file system and did not amend the cleanup bullet.
- **Recommended Fix:** Replace the bullet's "DebugLabel + `_apply_debug_banner`"
  phrasing with an explicit per-file removal list, ideally with grep anchors:
  ```
  Files to clean before release (grep anchors after each):
  - scenes/ui/HUD.tscn        — DebugLabel node                 (grep: "DebugLabel")
  - scripts/ui/HUD.gd         — _debug_label, _setup_debug_banner,
                                _refresh_debug_banner, _collect_active_debug_aids,
                                _apply_debug_banner, _ready call site
                                                                (grep: "_debug_label|debug_banner|debug_aids")
  - scripts/autoloads/EventBus.gd  — signal debug_flags_changed (grep: "debug_flags_changed")
  - scripts/autoloads/GameState.gd — _debug_force_levelup_v,
                                _debug_growth_boost_v, both setter/getter blocks,
                                _emit_debug_flags_changed         (grep: "_debug_force_levelup_v|_debug_growth_boost_v|debug_flags_changed")
  - scripts/tests/test_hud.gd       — live-toggle test block (lines 60–82) and run_tests.sh entry
  ```
- **Tradeoffs:** A more verbose checklist is slightly noisier to read but
  removes the ambiguity. The grep anchors are the cheapest way to make
  "remove every site" mechanically verifiable.

### 2.2 — Misleading cleanup comment in `test_hud.gd`
**[SEVERITY: Low]**
- **File & Line:** `scripts/tests/test_hud.gd:80-82` — "Tidy up so other suites
  aren't affected if they share the autoload."
- **Problem:** `run_tests.sh` invokes each suite as its own `godot --headless
  --script …` process; autoloads are constructed afresh per test and never
  shared between suites. The cleanup writes are harmless (the setter
  short-circuits to no-op on equal values) but the stated rationale is wrong
  and will mislead anyone who edits this test later.
- **Root Cause:** Habit from test frameworks where suites share a process.
- **Recommended Fix:** Either delete the cleanup writes outright, or keep them
  and re-word the comment, e.g.
  ```gdscript
  # Reset the flags after toggling — defensive only; each suite runs in its
  # own godot process under run_tests.sh, so this state never leaks across.
  gs.debug_force_levelup = false
  gs.debug_growth_boost = false
  ```
- **Tradeoffs:** None — comment fidelity only.

### 2.3 — `_apply_debug_banner(false, …)` leaves stale text on the hidden label
**[SEVERITY: Low]**
- **File & Line:** `scripts/ui/HUD.gd:196-203` (`_apply_debug_banner`).
- **Problem:** When `is_debug` is false, the function sets
  `_debug_label.visible = false` and returns immediately, leaving `text`
  whatever it was last set to. In production this is purely theoretical —
  `OS.is_debug_build()` is fixed for the build, so the banner never transitions
  debug→non-debug at runtime. The test exercises the transition (it asserts
  `not label.visible` after `_apply_debug_banner(false, one_aid)`), but never
  re-asserts the text after re-enabling, so the stale text is never observed.
  Still, "clear the text when hiding" is the safer invariant.
- **Root Cause:** Early-return for performance; missed that `text` carries.
- **Recommended Fix:** Clear the text on the hide path:
  ```gdscript
  func _apply_debug_banner(is_debug: bool, active_aids: Array[String] = []) -> void:
      if _debug_label == null:
          return
      _debug_label.visible = is_debug
      if not is_debug:
          _debug_label.text = ""   # don't leave a stale aid list behind
          return
      _debug_label.text = "● DEBUG MODE" if active_aids.is_empty() \
          else "● DEBUG MODE — " + ", ".join(active_aids)
  ```
- **Tradeoffs:** One extra assignment on hide; negligible. If this is preferred
  as-is for the "feels cheaper" reason, document why with a comment.

### 2.4 — EventBus connection is established in release builds too
**[SEVERITY: Low]**
- **File & Line:** `scripts/ui/HUD.gd:160-164` (`_setup_debug_banner`).
- **Problem:** `_setup_debug_banner()` connects `bus.debug_flags_changed →
  _refresh_debug_banner` unconditionally — there is no `if OS.is_debug_build()`
  gate around the connect. In a release build the debug flags can never flip
  (nothing toggles them), the signal never emits, and the banner stays hidden.
  So there is no functional impact — only a useless connection sitting on the
  bus for the lifetime of the HUD.
- **Root Cause:** Symmetry with the unguarded connection style elsewhere in
  HUD; the gate was put on `_apply_debug_banner` (visibility), not the wiring.
- **Recommended Fix:** Either (a) live with it — the whole feature is staged
  for removal at the Pre-Release Cleanup milestone, so this connection vanishes
  with the rest; or (b) wrap the connect in `if OS.is_debug_build():` for
  cleanliness now:
  ```gdscript
  func _setup_debug_banner() -> void:
      if not OS.is_debug_build():
          return  # nothing to do in release; banner stays hidden, no signal needed
      var bus := get_node_or_null("/root/EventBus")
      if bus and bus.has_signal("debug_flags_changed"):
          bus.debug_flags_changed.connect(_refresh_debug_banner)
      _refresh_debug_banner()
  ```
  Option (a) is fine given the planned deletion; option (b) costs three lines.
- **Tradeoffs:** Option (b) makes the dead-in-release path explicit; option (a)
  keeps the diff smaller for the deletion. Either is defensible.

---

## 3. Positive Observations

1. **Setter recursion was caught and properly fixed.** The first attempt at the
   setter used `flag = v` inside its own setter and infinite-looped (godot hung
   at 30+ seconds, kill-9 needed). The fix — backing variables + explicit
   get/set — is the correct GDScript 4 idiom, and the failure mode + fix were
   captured as a persistent memory so they won't be repeated.
2. **Clean three-level split in `HUD.gd`.** `_setup_debug_banner` wires
   (one-shot), `_refresh_debug_banner` re-collects + applies (signal handler +
   startup), `_apply_debug_banner` is pure UI mutation (testable without
   GameState). The test drives the bottom layer directly, which is why
   test_hud.gd doesn't need a custom GameState.
3. **Edge-triggered emit.** Both setters short-circuit on equal values before
   emitting, so the existing flag-toggle tests in `test_combat.gd` /
   `test_unit_stats.gd` (which set true→false symmetrically) don't spam the
   bus. This was a deliberate guard, not an accident.
4. **All defensive null guards in place.** Every access to `bus`,
   `_debug_label`, and `GameState` is null-guarded; the headless `--script` path
   (which loads autoloads but instantiates the HUD without `setup()`) survives.
   The existing test_combat / test_unit_stats suites — which set the debug
   flags directly and would have crashed any setter regression — stayed green
   in the pre-commit run.
5. **The new test exercises the full live-update path.** `test_hud.gd` toggles
   the GameState flag and asserts the HUD label text reflects the change via
   the signal — not just the leaf `_apply_debug_banner` function. That covers
   the regression risk for the wiring as a whole, not just the renderer.

---

## 4. Architectural Observations

- **The debug-aid feature is now an N-file ecosystem.** Two GameState flags +
  one EventBus signal + four HUD methods + one widget + one test file. The
  Pre-Release Cleanup bullet (issue 2.1) must enumerate all of it; "remove the
  banner" as a single sentence is not enough. Consider grouping all of this
  under a single comment marker — e.g. a `# DEBUG-AID-REMOVAL-MARKER` tag in
  each relevant block — so a single `grep` finds every site.
- **Property setters as event triggers are a powerful pattern, but expensive
  to retrofit.** The `var x: bool: get/set` rewrite needed for the signal
  changed *both* the declaration *and* every existing read path's mental model
  (`gs.get("x")` and `gs.x` now both invoke the getter). It worked here
  because the existing reads were already getter-safe, but the next time this
  pattern is reached for, audit the read sites first to avoid surprises.
- **The HUD now has two unrelated reasons to listen on EventBus** — gameplay
  signals (cursor, phase, HP) and the debug-aid signal. That's fine, but
  the section header / grouping in `_ready` makes the gameplay/debug split
  visually clear — keep it. If a third unrelated listener is added the file
  should be re-sliced (perhaps a `HUDDebugBanner` RefCounted, mirroring the
  MapCursor slicing).
- **Save-system note (deferred).** Both new backing vars (`_debug_force_levelup_v`
  / `_debug_growth_boost_v`) are plain `var`s. If/when the save system
  iterates `get_property_list()` to serialize GameState (post-M13), it will
  see them. They're not `@export` so most save layers won't touch them, but
  this is worth a quick check at the M-save milestone — and is another
  reason to delete the whole feature before then, per 2.1.

---

## 5. Prioritized Action Plan

1. **2.1 — expand the Pre-Release Cleanup bullet to enumerate every removal
   site** (with grep anchors). Highest-leverage of the four — prevents
   orphans at release. *(Medium severity, trivial effort.)*
2. **2.2 — fix the misleading "shared autoload" comment in `test_hud.gd`.**
   Two-line edit. *(Low severity, trivial effort.)*
3. **2.3 — clear `_debug_label.text` on the hide path** for hygiene. Defensible
   to leave as-is given production never transitions; pick based on whether you
   prefer the strict invariant. *(Low severity, trivial effort.)*
4. **2.4 — gate the EventBus connect on `OS.is_debug_build()`** OR explicitly
   document that the entire feature is staged for deletion and the dead-in-
   release connection is intentional. *(Low severity, trivial effort.)*

None of the four are blockers for the next playtest. All four can land in a
single small commit if you want them swept now; otherwise they ride out with
the Pre-Release Cleanup deletion.

---

*Review produced 2026-05-19 against branch `main` at commit `53eb64a`. No code
was modified — diagnosis only, per the code review instructions.*
