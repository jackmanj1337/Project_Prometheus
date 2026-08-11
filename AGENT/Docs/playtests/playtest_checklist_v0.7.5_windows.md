---
Type: playtest
Status: Awaiting return
Last verified: 2026-08-11
---

# v0.7.5 Windows Campaign Library repair checklist

Return this checklist and the debug log. Mark every item PASS, FAILED, or UNRUN.

## 1. Identity and regression stop gate

- [ ] `sha256sum -c SHA256SUMS.txt` passes.
- [ ] BUILD STAMP and Main Menu report `0.7.5` and the commit in `BUILD_INFO.json`.
- [ ] On a genuinely clean user-data directory, Main Menu visibly contains an enabled
  **Campaign Library** button.
- [ ] Campaign Library has initial keyboard/controller focus and opens with Confirm.
- [ ] Back/Escape returns focus to the Campaign Library button.

Stop and return the bundle immediately if the button is absent or any identity differs.

## 2. Pack lifecycle

- [ ] Import the supplied `replacement-pack.zip` without extracting it.
- [ ] Import completes without registry-envelope or `get`-on-String errors.
- [ ] Select the pack; New Game enables without restarting and launches its map.
- [ ] Save, quit, relaunch, and continue the package-backed campaign.
- [ ] Export the pack, then import that exported ZIP into a clean user-data directory.

## 3. Filename modal and input ownership

- [ ] Export/Save opens the game-owned filename modal before the directory picker.
- [ ] Typing replaces selected suggested text; caret movement, Home/End, Backspace, and
  Delete behave correctly.
- [ ] Escape/controller cancel closes only the top modal and restores invoking focus.
- [ ] Confirm preserves the chosen filename through the directory-only picker.
- [ ] Cancelling the native picker creates or overwrites no file.

## 4. Smoke and return

- [ ] Main Menu, Settings, New Game, Load Game, and Campaign Library render at 1280x720
  and 1920x1080 with keyboard, mouse, and a named controller.
- [ ] Complete a representative map without crash, stuck modal, or transition lockout.

For failures include reproduction steps, resolution/scaling, input device, screenshot,
and debug-log timestamp. Do not redistribute this private candidate.
