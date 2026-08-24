# v0.7.10 Windows playtest return evidence

Preserved from the workspace `Incoming/v0.7.10 return/` drop on 2026-08-24.
The files under `raw/` are unchanged copies of the tester return.

## Disposition

**Rejected as a release candidate.** The focused Windows pass proves that the
authored free-roam pack imports, launches Chapter 1, reaches the campaign map,
enforces later-node prerequisites, and restores campaign state. It also found a
release-blocking navigation failure: selecting cleared Chapter 1 enters its prep
screen with `Begin Battle` disabled and no route back to the campaign map. The
tester had to close the game; the following launch restored at Chapter 2.

The return also confirms that the campaign map has no save or settings surface,
the compact main menu still clips the application title and the disabled New Game
label at the smallest tested widths, Menu Density is absent, and slider tracks and
endcaps remain effectively invisible. These findings predate this focused build
and remain unresolved; v0.7.10 does not close them.

## Evidence summary

- Build identity: `0.7.10`, commit `6aa89069`, Godot 4.6.3, Windows 11.
- Both returned logs contain the expected build stamp and no Godot error or warning
  lines.
- Runtime context records `campaign_started`, Chapter 1 launch/resume/restage, and
  a later restore/launch of Chapter 2.
- `map.png` and `map fullscreen.png` show cleared Chapters 1 and 2, Chapter 3 as
  next, Chapters 4 and 5 gated, and the sentence `Clear Chapter 3 - The Commander
  first.` No internal localization or requirement identifier is visible.
- `chapter 1 revisit.png` shows the dead-end cleared-node prep state and the disabled
  `Begin Battle` control.
- `narrow.png`, `slightly less narrow.png`, and `settings.png` preserve the remaining
  responsive-layout and settings-style findings.

The checklist's return-content boxes were left unchecked, but the packet contains
the completed checklist, all six PNGs present in the drop, and both files from the
returned Godot log directory. The checklist requested the complete log directory;
only these two log files were supplied, so this archive claims no evidence beyond
them.
