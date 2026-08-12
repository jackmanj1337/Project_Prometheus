# Session Note - 2026-08-06-20-55-09Z

## Branch context

- Branch: `agent/integration` (fix built on `agent/from-integration/suppress-web-os-keyboard`)
- Base branch: `agent/integration`
- Base SHA: `7fcf16cc`
- Coordination Work ID: `SUPPRESS-WEB-OS-KEYBOARD-2026-08-06`

## What was done

The owner ratified every open recommendation on mobile text entry, so this session made them
durable and then executed the one that was unblocked and cheap.

**The unverified risk was not a risk. It was live.** The plan's next step was "verify
`FEATURE_VIRTUAL_KEYBOARD` on the web export". Measured in the exported artifact rather than
recalled:

- `index.js` carries `GodotDisplayVK`, gated on
  `GodotConfig.virtual_keyboard && "ontouchstart" in window`.
- `GodotConfig.virtual_keyboard` comes from `GODOT_CONFIG.experimentalVK` in the generated
  `index.html`. The engine defaults it to **false**.
- But `export_presets.cfg` carried `html/experimental_virtual_keyboard=true`, so the export
  shipped **`"experimentalVK":true`**.

So on every touch device the engine was creating a hidden `<input>` and focusing it — and
because `TextEntryService` focuses a real `LineEdit` whose `virtual_keyboard_enabled`
defaults to `true`, the platform keyboard raised **on top of** the grid keyboard. The thing
the owner decided to suppress was not merely unsuppressed; it was actively shipping.

The fix is one line of export config. It closes the path at the platform level, so no
per-`LineEdit` change is needed — which also matters practically, because
`TextEntryService.gd` is claimed by `V060-TEXT-ENTRY-SERVICE-2026-08-02` and could not have
been touched here. Verified by re-exporting: `index.html` now emits `"experimentalVK":false`.

`scripts/tests/test_web_export_preset.gd` guards it, per DoD#2. The Godot export dialog
rewrites `export_presets.cfg` wholesale, which is precisely how a decision like this gets
silently reverted; the suite also guards the custom PWA shell for the same reason.

**Decisions recorded in the design doc.** All ratified 2026-08-06: the layered 7-column
alphabetical keyboard; the echo strip **scoped Compact-only** (in split landscape the field
stays visible in place, so a strip there would duplicate the real field beside itself);
dropping `system` from the Settings vocabulary while keeping the registry constant; the
landscape **split keyboard** (A–M left pad, N–Z right pad, in the two dead columns, game view
never moves); and the **shrink-the-view fallback** when the dead space is too narrow.

The landscape section records the conditional plainly: columns per side are a direct function
of the aspect the player picked, and **4:3 is the boundary** — at 3:2 and wider a split
keyboard stops fitting. A tactical map is exactly the view a player would widen, so the
fallback is not hypothetical.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`. `6779677c` is the preset fix and its guard,
merged to integration; the docs commit updates the design doc and the programme plan.

## Gates

- `bash run_tests.sh` — **PASS, 131 suites** (130 before; the preset guard is the increment).
- `test_web_export_preset` — 3 passed, 0 failed.
- `python3 AGENT/Docs/check_docs.py` — PASS, 43 checks, after `gen_docs_index.py`.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 304 files.
- Re-exported the web build and grepped the artifact: `"experimentalVK":false`. The claim
  is measured on the shipped output, not inferred from the config.

## Next

**The landscape game-view rectangle**, on `MOBILE-WEB-CONTROLLER-2026-08-04`. Under the
dead-space rule the control region is whatever the game view leaves over, so landscape's
full-bleed `{x:0, y:0, w:1.0, h:1.0}` default leaves nowhere for controls *and* nowhere for
the split keyboard. 4:3 is the widest rectangle that still fits one, which argues for making
it the default rather than a choice. This blocks the landscape keyboard entirely.

Screen conversions remain unblocked and can proceed in parallel: Main Menu → Campaign
Library → New Game → Roster → Unit sheet and More Info → Prep hub.
