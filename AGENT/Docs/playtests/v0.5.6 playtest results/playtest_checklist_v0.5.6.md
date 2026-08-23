---
Role: dated
---

# v0.5.6 Windows Verification Checklist

**Status:** Ready for Windows playtest after bundle metadata is filled  
**Date:** 2026-07-24  
**Return the completed checklist and Godot logs together.**

## Bundle integrity

- [x] `Project_Prometheus_v0.5.6_debug.exe` matches `SHA256SUMS.txt`.
- [x] Main Menu shows `v0.5.6`; the startup log BUILD STAMP matches the bundled
      commit and build timestamp in `BUILD_INFO.txt`.
- [x] `two-map-skirmish-1.0.zip` and `branching-skirmish-1.0.zip` are present.

## Release blockers

### Package-owned save restoration

1. Import `two-map-skirmish-1.0.zip`, start its campaign, make a save, return to
   shipped content, then load that save.
2. Repeat after restarting the executable.

- [x] Both loads activate the saved package catalogue before validating its item,
      map, and campaign references; no false missing-content error appears.
- [ ] A missing package still fails clearly and does not partially mutate the run.
	- don't know how to test this

### Long-list focus scrolling

Open Results, Defeat, and Rewind lists with enough rows to overflow. Navigate with
controller/keyboard, including wrap from first to last and reopening Rewind.

- [x] Focus moves exactly one row per press and the focused row remains visible.
- [x] Holding a direction scrolls smoothly without focus leaking behind a popup.
- [ ] Successor dropdown navigation remains inside the dropdown until it closes.

### Retry after Save

Win the first map, Save on Results, then select Retry Battle.

- [x] Retry remains available and shows a warning that the advanced save remains.
- [x] Cancel leaves Results unchanged.
- [x] Confirm returns through Prep to the just-completed map at round zero.
- [x] Loading the earlier saved timeline still resumes the advanced successor.
- [x] Winning the retried map advances exactly once (no skipped/double node).

### FileDialog keyboard/controller behavior

Open every available import/export FileDialog and focus the filename field.

- [x] Z/X and mapped Confirm/Cancel characters type normally in the field.
- [ ] First physical Escape leaves the filename field and focuses the file tree.
- [ ] Second Escape closes the dialog.

first escape just closes the dialog without leaving the text field.

### Trace lifetime

- [ ] New Game navigation produces no `v0.3.0` trace file or `[V030 TRACE]` log.
- [ ] Normal BUILD STAMP and Godot logging still work.

## Campaign fixtures and connected flow

Import and play both bundled packs.

- [x] `two-map-skirmish-1.0.zip`: win map 1, continue through Prep, and launch map 2
      with roster, levels, inventory, gold, and campaign rules intact.
- [ ] `branching-skirmish-1.0.zip`: Results offers River Pass and Ridge Pass in that
      order; each choice launches successfully and persists across Save/Load.
- [ ] Package provenance is visible and remains correct after restart.
	- Unsure how to verify
      
Consider delaying this bug to later UI/campaign data pass, but when the next map selector is opened and the "Choose next chapter" option is picked specifically and then save is clicked, you cannot change the next chapter choice but you can't continue because a choice wasn't made. 

both ridge pass and river pass were selectable, but I could not tell a difference between the maps if different ones were actually loading. Prep screen showed correct name.


## Remaining v0.5.5 visual/input regression pass

- [x] Controller can reach Prep and every Results/Defeat action.
- [ ] Keyboard and controller hotplug/input-mode switching refreshes prompts.
- [ ] HUD phase marker and authored victory actions render correctly at 100% and
      200% UI scale.
- [ ] No clipped text, overlap, stale focus ring, double-step, or focus-behind-modal.
- [x] Quit, Continue, Retry, Rewind, Load, and Main Menu paths each work once.

The HUD Layout editor's complete controller editing scheme is deliberately deferred
to the later UI/UX reuse pass; record observations, but do not reject v0.5.6 solely
because controller-driven panel movement/scaling is not yet implemented.

2x scale vicotry screen overflows. Consider scroling results or placing actions in their own collumn side by side with results.

Look at the settings screen screenshot. The options in the selected dropdown is overlaping with the decorative edge on the dropdown bar texture. either add some padding to the text display or center the text. Also try to change the stretching on that texture so the gold decorations don't look so stretched, possibly using a modified 9 patch.

No game pad available this time. game pad was used extensively last time so if it did not show up in the log then it should be considered broken.
## Return

Record PASS/FAIL beside every item, exact reproduction steps for failures, controller
model, Windows version, display resolution/scaling, and UI scale. Return this file,
the startup/current `godot.log`, any rotated timestamped log, and screenshots or save
artifacts needed to reproduce a failure.
