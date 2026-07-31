# Session Note - 2026-07-31-04-45-11Z-text-entry-headless-defect-fixes (text entry headless defect fixes)

## Branch context

- Branch: `agent/from-integration/text-entry-implementation`
- Base branch: `agent/integration`
- Base SHA: `8dd24243ad4a34cf78cf9c3e791122effee2d86f`
- Coordination Work ID: `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`

## What was done

Reviewed the headless text-entry implementation and fixed the four defects that
could be reproduced and verified without a Windows host. The branch stays
`in_progress`: nothing here settles the Windows event-order question.

**The Escape fix never did what it was written to do.** `_focus_file_list()`
searched for a `Tree`. Godot 4's `FileDialog` builds its file list from an
`ItemList` and contains no `Tree` anywhere, so the lookup matched nothing and
the deferred focus handoff was a no-op on every platform, not just Windows.
This survived because the existing regression test asserted only that focus
*left* the filename field — which it did. The suite was green and the stated
contract ("first Escape drops focus to the file list") was never met. Measured
in this container: the dialog contains 0 `Tree` nodes and 3 visible `ItemList`
nodes, of which Favorites and Recent sit under a `VSplitContainer` and the file
list does not.

Selecting the file list is therefore structural, not public API — `FileDialog`
exposes `get_line_edit()` and `get_vbox()` but no accessor for the list. The
test now asserts exactly one `ItemList` qualifies, so a Godot upgrade that
reshapes the dialog fails the suite rather than silently focusing Favorites.

Three smaller defects:

- The grid overlay was offered on `focus_entered` with nothing wired to
  `focus_exited`, so leaving the field by click or Tab left the on-screen
  keyboard floating over the dialog. Withdrawal is deferred and skipped while
  focus is still inside the overlay, because `open()` grabs focus and so fires
  `focus_exited` itself. Both directions are tested.
- `TextEntryOverlay` wrote `LineEdit.text` directly, which emits nothing, so a
  caller listening on the target rather than on the overlay would never observe
  grid input. `CampaignLibraryScreen` and `LoadGameScreen` are the next
  adopters and would have hit this silently.
- Physical Escape is hooked at four stages and three call sites discarded the
  result, which made the de-duplication read as accidental. It is not — it is a
  property of the focus check in `TextEntrySession.handle_physical_escape()`.
  All four sites now route through one helper that records the consuming stage
  in `escape_consumed_by`.

## Commits claimed

- `8229d091ff4e2bce8562df21f291d179fe3d05f7` — Fix the headless text-entry defects, incl. an Escape target that never existed

## Gates

- `full`: `bash run_tests.sh` at `8229d091ff4e` — **PASS**, all suites green.
- `test_text_entry` grew 13 → 21 checks; the two new focus assertions failed
  against the pre-fix code and pass after, so they cover real regressions.
- Pre-commit: gdformat/gdlint PASS, scene-integrity PASS, evidence-matrices
  PASS.

## Decisions and context

- **No Escape stage was removed.** Which of the four wins on native Windows is
  still unknown, and that is what `escape_consumed_by` now records. Prune on
  evidence from the Windows pass, and keep the focus check when pruning — it is
  what makes the remaining stages safe.
- The `ItemList` selection is deliberately guarded by a uniqueness assertion
  rather than hardcoded to a node path, because the path is generated
  (`@ItemList@71`) and not stable.

## Next

Unchanged from the prior note: run the FileDialog diagnostic and grid-overlay
visual/navigation pass on Windows. Two additions to that pass now that the
focus target is fixed — confirm first Escape lands on the **file list** rather
than merely leaving the field, and record `escape_consumed_by` so the redundant
Escape stages can be deleted.

Not addressed here, and still open from the same review:
`FileDialogInputGuard._resolved_text_entry_mode()` builds a fresh
`TextEntryRegistry` on every `focus_entered`, so nothing outside that function
can ever register a mode — the `system` backend (Steam, and on web
`DisplayServer.virtual_keyboard_show`) has no seam to register into. That is a
small refactor with a design question attached and was left for a decision.
