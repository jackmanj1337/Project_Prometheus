# Display & Settings Guide

**Last verified:** 2026-07-10

Explains how the game's **window mode**, **resolution**, **OS display scaling**, and
the on-disk **settings.cfg** interact — so window sizing that looks surprising (e.g. a
4K windowed request that leaves desktop visible around the window) reads as intended
behavior, not a bug. Written to answer the recurring v0.2.5 playtest questions
(V025-06 windowed clamp, V025-09 settings.cfg).

## Window modes

Three modes, chosen in Settings → Window Mode (`SettingsManager.window_mode`):

- **Windowed** — a titled, movable window at the chosen **Resolution**. The one mode
  where the Resolution dropdown matters.
- **Borderless** — Godot's "windowed fullscreen": a borderless window filling the
  current monitor at its native size. Resolution is ignored.
- **Fullscreen** — exclusive fullscreen at the native screen mode. Resolution is
  ignored.

Fullscreen/Borderless always match the monitor, so the Resolution setting only takes
effect in Windowed mode. To make that self-evident in-game, the Resolution dropdown is
**grayed out outside Windowed mode** and the readout beside it shows the **native
display size** (`native WxH`); the saved request is preserved underneath and the row
re-enables intact on switching back to Windowed (V027-05c, Q6).

## The windowed clamp (why a 4K window is smaller than the screen)

In Windowed mode the requested Resolution is **clamped into the screen's usable rect**
before the window is sized (`SettingsManager.windowed_client_size_for_screen`). The
usable rect is the monitor minus a decoration margin (title bar + taskbar), so:

- A window's **client area** (the game view) must fit *inside* the usable rect, leaving
  room for the OS title bar and taskbar. A request equal to the full monitor size can't
  fit once you add the title bar, so it is reduced — while preserving the 16:9 contract.
- Result: on a 3840×2160 monitor, a "3840 × 2160 (4K)" **windowed** request yields a
  window smaller than the full screen, with **desktop visible around it**. That is the
  clamp working as designed — the title bar stays reachable and the aspect stays 16:9.
- To fill the whole monitor, use **Borderless** or **Fullscreen** instead.

### What the size numbers mean (V028-02)

The readout beside the Resolution dropdown speaks a small vocabulary, so it is worth
being precise about which size is which (the app reads these from
`SettingsManager.windowed_size_status()`):

- **preset request** — a size you pick from the Resolution dropdown. It is a *request*:
  in Windowed mode the usable-rect clamp may shrink it, so the readout shows
  `→ applied WxH` **only when the clamp actually changed it** (e.g.
  `3840x2160 → applied 1904x1071`).
- **client size** — the actual windowed client area (the game view) the OS gave you. A
  size written back from an OS resize is *already* a client size, so it shows as
  `client WxH` and is **never** re-run through the 16:9 request clamp. (Before v0.2.9
  this was mistakenly compared against the clamp, producing nonsense like
  `Custom (3840x2071) → applied 3563x2004`; that is fixed.)
- **native display size** — your monitor's full size, shown as `native WxH` while
  Borderless/Fullscreen have the Resolution row grayed out.
- **viewport / canvas size** — the fixed 16:9 logical resolution the game renders into.
  The stretch system letterboxes it into whichever client size is active; these controls
  never change it.

The `→ applied` label is meant for preset **requests** only,
not for custom sizes written back from the OS. The window is re-centred on its screen
after each **setting-driven** resize - a Resolution/Window Mode apply
(`window_centre_position`) - clamped so a larger-than-screen window never centres its
title bar off the top/left. An **OS drag-resize never re-centres** the window: you just
placed it, moving it out from under you would be hostile. (An earlier playtest handbook
claimed drag-resizes re-centre - that was wrong and is corrected here; V027-04b.)

## OS drag-resize write-back (V027-04b, Q5 owner decision 2026-07-05)

In Windowed mode, resizing the window **by dragging an edge** **writes the new client
size back into the saved Resolution setting** — the setting follows reality rather than
remembering a request the window no longer honours:

- The write-back persists immediately (`SettingsManager.apply_resize_write_back`) and the
  readout follows, showing the new size as a **`client WxH`** value. Deliberate
  consequence (owner decision Q5→B): a drag **overwrites** the previously chosen preset.
- If the dragged size isn't one of the presets, the Resolution dropdown shows a trailing
  display-only **`Custom (WxH)`** entry as the selected value. Picking any preset drops
  the Custom entry again; selecting the Custom entry itself changes nothing (it *is* the
  current value).
- Programmatic resizes (applying the dropdown value) are excluded — the write-back only
  fires when the size differs from what `_apply_display` itself requested, so a clamped
  4K request does not overwrite itself with the clamped result.
- Detection rides both viewport and root-Window `size_changed` hooks, coalesced to one
  pass per settled frame. The root-Window hook exists because one-axis edge drags under
  the kept 16:9 viewport can change the OS client size without changing the viewport.

**The Windows maximize button is treated as a window STATE, not a resolution (V028-03,
owner decision Q2 2026-07-07).** Maximizing no longer overwrites your saved Resolution
with the maximized client size (which used to produce a stray `Custom (3840x2071)`);
`SettingsManager.resize_write_back_action` ignores the maximized state, and **un-maximizing
restores your chosen windowed size**. Settings still refreshes its live readout from the
settled display-size notification, so a maximized Windowed window shows `Maximized (WxH)`
without persisting that size. The old symptom where the Settings panel drifted
off-center after maximizing (and only re-centered after another size/scale change) is
fixed at the cause: each menu panel now re-centers reactively from its own `resized`
signal the instant the engine settles the new size, instead of guessing the settle frame
with a deferred re-apply (see `GDD_07_UI_UX.md` §Accessibility).

## OS display scaling / DPI

Godot sizes the window in **physical pixels of the current desktop mode**. If the OS
runs the desktop at a scaled/virtual resolution (e.g. a 3840×2160 panel driven at a
1920×1080 desktop, or Windows display scaling at 150%), the "screen size" the clamp
sees is that *effective* desktop size, not the panel's native pixel count. This is why
the same Resolution choice can produce different window sizes on two machines with the
same physical monitor but different OS scaling — it is expected, and the applied-size
readout reflects what actually happened.

## settings.cfg (where settings live)

All settings persist to a `ConfigFile` at `user://settings.cfg`
(`SettingsManager.SETTINGS_PATH`). With no custom user dir set and
`config/name = "Project Prometheus"`, the `user://` root resolves per-OS to:

- Windows: `%APPDATA%\Godot\app_userdata\Project Prometheus\settings.cfg`
- Linux: `~/.local/share/godot/app_userdata/Project Prometheus/settings.cfg`
- macOS: `~/Library/Application Support/Godot/app_userdata/Project Prometheus/settings.cfg`

**Renamed from "Fire Emblem RPG".** `config/name` used to be `Fire Emblem RPG`, so
builds before this change resolved `user://` to an `app_userdata\Fire Emblem RPG`
directory instead. Because `config/name` is what determines
`OS.get_user_data_dir()`, that rename moves every `user://` path at once.
`UserDataMigration` (run from `SettingsManager._ready()`, before settings are read)
carries `saves/`, `campaign_packs/`, `campaign_status/` and `settings.cfg` over from
the old directory on first launch, skipping anything the new location already has and
recording a `user://.legacy_user_data_migrated` marker so it runs once. Old `logs/`
are not carried over — the engine has already opened a log in the new location by
then — and the legacy directory is left on disk rather than deleted.

Notes:

- The file is written on every settings change (each `set` is followed by a `save`),
  except risky display changes (window mode / resolution) which apply live but only
  **save after you confirm** in the 15-second confirm-or-revert dialog — so a setting
  that blanks the screen auto-reverts without being persisted.
- **First run has no settings.cfg** — the defaults in `SettingsManager` apply and the
  file is created on the first save. A missing file is normal, not an error.
- **Schema migration:** when a setting's stored shape changes between versions (e.g. the
  Menu Scale index gained a 0.5× slot), `SettingsManager` migrates the old value on load
  so a pre-existing settings.cfg keeps the player's intended value. Deleting settings.cfg
  is always a safe hard reset to defaults.

## godot.log (the engine log — where to find it)

`godot.log` is Godot's **built-in file log**, not something this project writes by hand.
The engine mirrors everything printed to stdout/stderr — `print()`, `push_error()`,
`push_warning()`, and engine errors/warnings — into it. It is controlled by the project
setting `debug/file_logging/enable_file_logging`, which **defaults to on for desktop**
(off on web/mobile); this project doesn't override it, so desktop builds log and web
builds don't.

- **The log lives in the OS user-data dir (`%APPDATA%`), for both exported and dev/editor
  runs.** Godot's self-contained (`._sc_`) marker is an editor/tools feature and is
  ignored by exported projects, so `user://` — including `logs/godot.log` and
  `settings.cfg` — resolves to the OS location, NOT next to the exe:
  - Windows: `%APPDATA%\Godot\app_userdata\Project Prometheus\logs\godot.log`
  - Linux: `~/.local/share/godot/app_userdata/Project Prometheus/logs/godot.log`
- **The log tells you where it is.** Every launch writes a `=== BUILD STAMP ===` block at
  the top of `godot.log` with `user_data_dir=` and `log=` lines giving the exact resolved
  paths, plus the build's version + git commit + a fresh `started_at` timestamp. The
  `log=` line is authoritative — a tester copies the exact path straight from it.
  - macOS: `~/Library/Application Support/Godot/app_userdata/Project Prometheus/logs/godot.log`
- **Rotation:** a fresh log starts each launch. Up to `max_log_files` (default **5**) are
  kept — the current run is `godot.log`, earlier runs are timestamped beside it in the
  same `logs/` folder. Grab `godot.log` right after reproducing the issue (before the
  next launch rotates it out), or send the timestamped copy from that run.
- **In the editor** the same content also appears live in the **Output** panel.
- The log can be large (a v0.1.4 return was ~9 MB) because repeated errors accumulate —
  zipping it is fine; the repeat counts are the useful signal.

## For playtesters

If a windowed size looks "too small," check: (1) you're in **Windowed** mode — switch to
Borderless/Fullscreen to fill the monitor; (2) the **applied** size shown next to
Resolution — that's the clamped result; (3) your **OS display scaling**, which changes
the effective screen size the clamp uses.

When reporting any issue, attach **`godot.log`** from the `logs/` path above (see the
godot.log section) — it captures resolved window sizes and any DisplayServer warnings
that explain what the window actually did.
