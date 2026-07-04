# Display & Settings Guide

**Last verified:** 2026-07-04

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
effect in Windowed mode.

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

Settings shows the actually-applied size next to the Resolution dropdown (e.g.
`3840x2160 → applied 1904x1071`) so the clamp is self-explaining in-game
(`SettingsManager.applied_windowed_size`). The window is re-centred on its screen after
each resize (`window_centre_position`), clamped so a larger-than-screen window never
centres its title bar off the top/left.

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
(`SettingsManager.SETTINGS_PATH`). The `user://` path resolves per-OS:

- Windows: `%APPDATA%\Godot\app_userdata\<project>\settings.cfg`
- Linux: `~/.local/share/godot/app_userdata/<project>/settings.cfg`
- macOS: `~/Library/Application Support/Godot/app_userdata/<project>/settings.cfg`

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

## For playtesters

If a windowed size looks "too small," check: (1) you're in **Windowed** mode — switch to
Borderless/Fullscreen to fill the monitor; (2) the **applied** size shown next to
Resolution — that's the clamped result; (3) your **OS display scaling**, which changes
the effective screen size the clamp uses.

When reporting a display issue, please attach `godot.log` from the `user://` directory
above (same folder as settings.cfg) — it captures the resolved sizes and any
DisplayServer warnings that explain what the window actually did.
