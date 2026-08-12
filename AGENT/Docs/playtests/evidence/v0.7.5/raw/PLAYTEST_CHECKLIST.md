---
Type: playtest
Status: Awaiting return
Last verified: 2026-08-11
---

# v0.7.5 Windows Campaign Library repair checklist

Return this checklist and the debug log. Mark every item PASS, FAILED, or UNRUN.

## 1. Identity and regression stop gate

- [ ] `sha256sum -c SHA256SUMS.txt` passes.
- [x] BUILD STAMP and Main Menu report `0.7.5` and the commit in `BUILD_INFO.json`.  [completion:: 2026-08-11]
- [x] On a genuinely clean user-data directory, Main Menu visibly contains an enabled  [completion:: 2026-08-11]
  **Campaign Library** button.
- [x] Campaign Library has initial keyboard/controller focus and opens with Confirm.  [completion:: 2026-08-11]
- [x] Back/Escape returns focus to the Campaign Library button.  [completion:: 2026-08-11]

Stop and return the bundle immediately if the button is absent or any identity differs.

## 2. Pack lifecycle

- [x] Import the supplied `replacement-pack.zip` without extracting it.
- [x] Import completes without registry-envelope or `get`-on-String errors.
- [ ] Select the pack; New Game enables without restarting and launches its map.
- [ ] Save, quit, relaunch, and continue the package-backed campaign.
- [x] Export the pack, then import that exported ZIP into a clean user-data directory.
The pack seems to install just fine but does not unlock the new game menu even on reboot. 

## 3. Filename modal and input ownership

- [x] Export/Save opens the game-owned filename modal before the directory picker.
- [ ] Typing replaces selected suggested text; caret movement, Home/End, Backspace, and
  Delete behave correctly.
- [ ] Escape/controller cancel closes only the top modal and restores invoking focus.
- [ ] Confirm preserves the chosen filename through the directory-only picker.
- [ ] Cancelling the native picker creates or overwrites no file.

Shifting focus into the text box on the file system when importing does open up a new screen with a text box but pressing any keyboard button does not put text into the new box, but rather into the old box, now slightly covered up. hitting enter closes the text input and returns you to the main file picker window, but nothing on the keyboard lets you move the focus to the cancel or confirm buttons. pressing enter also leaves the focus on the old text input box with a caret so the focus can't move again. Pressing a single `escape` on either the new text input screen or the old file system screen returns you to the manage campaigns screen. When opening the export menu we do get a new screen, but no text appears on it. when an `enter` is clicked, any text that was entered is placed in the filesystem name box, but grayed out and non editable.

We have been working on this area for a while. I have included an external research packet that we should review and see if any of it can provide some guidance. If it does not, we should seriously consider removing this feature from v1 and relying more heavily on the OS and browser filesystems for import export. I am open to any level of redesign or rebuild to get this feature working smoothly.

## 4. Smoke and return

- [x] Main Menu, Settings, New Game, Load Game, and Campaign Library render at 1280x720
  and 1920x1080 with keyboard, mouse, and a named controller.
- [ ] Complete a representative map without crash, stuck modal, or transition lockout.

For failures include reproduction steps, resolution/scaling, input device, screenshot,
and debug-log timestamp. Do not redistribute this private candidate.
