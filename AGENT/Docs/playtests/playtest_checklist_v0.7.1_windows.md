---
Type: playtest
Status: Awaiting return
Last verified: 2026-08-08
---

# v0.7.1 Windows test checklist

This is a private Windows playtest round, not a public release. Use the executables and
campaign-pack ZIP inside the tester bundle. Return this checklist, the debug log, and
screenshots for every visual failure.

## 1. Identity and launch

- [ ] `sha256sum -c SHA256SUMS.txt` passes before launch.
- [ ] Both startup logs report BUILD STAMP `version=0.7.1`; their commit matches each
  artifact's entry in `BUILD_INFO.json`.
- [ ] The release executable has no DEBUG MODE banner; the debug executable does.
- [ ] Main Menu displays `v0.7.1`.

Stop and return the bundle without testing if any identity check fails.

## 2. Install the supplied pack

- [ ] Begin with no active campaign pack. The game explains that no content is active.
- [ ] Import `campaign-packs/prometheus-v071-playwright-test.zip` without extracting it.
- [ ] Select the imported pack. It activates without registry, item-effect, or duplicate-id
  errors.
- [ ] New Game lists the supplied campaign, maps, and rosters.
- [ ] Launch at least one map and confirm units, enemies, inventories, objective, terrain,
  and turn order are present.
- [ ] Complete one encounter to a result, save, exit, relaunch, and continue.
- [ ] Open an item description and use an applicable item. Report a missing/no-op effect;
  v0.7.1 specifically repairs item-effect fields lost during extraction.

## 3. Pack breadth smoke pass

The automated validator activated 24 classes, 16 weapons, 8 items, 8 maps, 3 rosters,
1 campaign, and 7 terrain records. The display pass should sample the surfaces automation
cannot judge.

- [ ] Open all eight maps far enough to confirm the correct map, roster, and objective load.
- [ ] Confirm weapon names/ranges and item names/effects are plausible rather than blank.
- [ ] Confirm terrain paints at the correct size and atlas region.
- [ ] Confirm promotion offers and class names do not expose namespaced registry ids.

## 4. Windows visual and input pass

- [ ] Review Main Menu, Settings, New Game, Load Game, and Campaign Library at 1280x720,
  1365x768, 1920x1080, 2560x1440, and 3840x2160.
- [ ] At 2x menu/content scale, centered screens remain contained and scroll correctly.
- [ ] Resize slowly across responsive size-class boundaries. The layout settles once and
  retains focus, selection, scroll position, and open More Info state.
- [ ] Keyboard, mouse, and a named controller can navigate menus and gameplay; one list
  item moves per press.
- [ ] Hot-plug the controller and confirm prompts switch keyboard/controller correctly.
- [ ] Complete a representative map without a crash, stuck modal, or transition lockout.

## 5. File dialog and text entry

Use the debug executable and retain its log.

- [ ] With a filename field focused, the first Escape moves focus to the file list rather
  than closing the dialog.
- [ ] Record every `file_dialog_escape_owned` / `escape_consumed_by` line. If none appears,
  say so explicitly.
- [ ] One Escape has one owner; it must not both leave the field and close another screen.
- [ ] The grid keyboard withdraws after leaving the field by click or Tab.
- [ ] Space has a visible label; invalid keys are disabled with an explanation.
- [ ] Confirming the dialog preserves the typed value.

## 6. Known scope and return format

- The Pixel 7 New Game containment defect is already tracked under
  `SMALL-SCREEN-UI-REDESIGN-2026-08-05`; this Windows-only round does not close it.
- Skills and pair-up remain incomplete pack families. Do not report inert extracted skills
  as a new v0.7.1 regression.
- Public/web distribution remains separately gated; do not upload or redistribute this
  private tester bundle.

For every failed or unrun item, write `FAILED` or `UNRUN` beside it. Include reproduction
steps, display resolution/scaling, input device, screenshot, and the debug log timestamp.
