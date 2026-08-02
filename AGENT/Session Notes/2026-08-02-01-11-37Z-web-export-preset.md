# Session Notes — 2026-08-02-01-11-37Z-web-export-preset (web-export-preset)

## What was done

Part 1 of FIX-WEB-EXPORT-PRESET: added the Web export preset to
`export_presets.cfg`, which previously held only `preset.0` (Windows Desktop),
so no web export was possible at all. The preset is named exactly `Web` to match
the default `EXPORT_PRESET_WEB`, so the wrapper resolves it by name and never
reaches the fallback path.

Part 2 (the cross-platform preset fallback in `scripts/export-project.py`) is
infrastructure and lives in the container repo on
`agent/from-staging-area/web-export-preset-fallback`.

Two option values are load-bearing, both re-confirmed by this export:

- `vram_texture_compression/for_mobile=false` — with it true, Godot 4.6.3 aborts
  with `Cannot export project with preset "Web" due to configuration errors:`
  and nothing after the colon, because the ETC2/ASTC import check prints no
  message headless. `false` is correct for `gl_compatibility` regardless.
- `variant/thread_support=false` — `serve-web-local.sh` is `python3 -m
  http.server`, which sends no COOP/COEP headers, and a threads build will not
  boot without cross-origin isolation.

The export was then served and driven in headless Chromium through Playwright.
This is the first time the project has been rendered anywhere in the container,
which closes candidate 5 of INVESTIGATE-WEB-EXPORT-BLOCKERS ("rendering — cannot
be settled here").

## Factual Git state

- Branch: `agent/from-integration/web-export-preset`
- HEAD: `c7c1227f4e806312e44b5e55d092e94e8bf1a792`
- Task merge base: `3bd2d0a186631e26295cba253f174bf9e150679f`

## Commits

- `c7c1227f4e806312e44b5e55d092e94e8bf1a792` — Add the Web export preset

## Checks

- No exact-HEAD receipts found
- `bash run_tests.sh` (full, via `agent-commit.sh` at commit time): all suites
  green — receipt `audit/check-receipts/Project_Prometheus-full.json`, tree
  `6cf883a60be3021a228d3551d263d93bcc882e7e`, exit 0.
- Export evidence: `builds/web/Project_Prometheus/artifact-manifest.json` —
  `index.wasm` 37,700,666 B, `index.pck` 1,628,540 B, `index.js` 315,759 B,
  Godot `4.6.3.stable.official.7d41c59c4`, preset `Web`, source
  `3bd2d0a186631e26295cba253f174bf9e150679f`.
- Browser evidence: served at `127.0.0.1:8060` (200 on `index.html` and
  `index.wasm`); booted to a rendered main menu in Chromium 141 with
  ANGLE/SwiftShader WebGL2; canvas 1280x720; zero page errors; keyboard
  navigation into Settings and back confirmed through the canvas.

## Decisions and context

Nothing was ratified this session. Three findings the render produced, none of
them fixed here, all needing an owner call or a row of their own:

1. `project.godot` still carries `config/name="Fire Emblem RPG"`. On web that is
   the browser tab title and the `user://` directory name
   (`/userfs/godot/app_userdata/Fire Emblem RPG`). REN-GDD-PASS scopes itself to
   GDD prose and recorded `data/` as clean; `project.godot` was in neither scope,
   so the REN gate would currently pass with the FE name shipping in the window
   title of every build. Changing it also moves the save directory, so it is a
   migration, not a rename.
2. `FileDialog` on web draws its own dialog over the virtual `user://`
   filesystem: no native file chooser fires and no DOM `<input>` element is
   created. This confirms the IMPL-WEB-FILEDIALOG-SHIM premise empirically
   rather than by inference. Note the scenes never set `use_native_dialog`,
   which defaults to `false`, so this is the Godot-drawn dialog on every
   platform — only `access = ACCESS_FILESYSTEM` differs in what it can reach.
3. `/home/vscode/.cache` being root-owned is not cosmetic, as
   INVESTIGATE-WEB-EXPORT-BLOCKERS recorded it — it hard-blocks
   `playwright install` with `EACCES`. Fixed locally by `chown`; the durable fix
   belongs in the container image.

## Next session

Owner decision on the FileDialog options packet (three shim shapes, prepared this
session). Independently: `config/name` needs a REN row of its own with the
save-directory migration attached, and the container image needs the
`/home/vscode/.cache` ownership fix so the Playwright loop survives a rebuild.
