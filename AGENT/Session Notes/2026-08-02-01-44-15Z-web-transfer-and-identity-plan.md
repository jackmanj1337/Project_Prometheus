# Session Notes — 2026-08-02-01-44-15Z-web-transfer-and-identity-plan (web-transfer-and-identity-plan)

## What was done

Planning note for the branch. Work lands in later commits, each claimed here.

### Already landed this session (other branches)

- `agent/from-integration/web-export-preset` — added the Web export preset;
  `export_presets.cfg` previously held only Windows Desktop, so no web export
  existed. Pushed. Session note
  `2026-08-02-01-11-37Z-web-export-preset.md`.
- `agent/from-staging-area/web-export-preset-fallback` (container repo) — scoped
  the export-preset fallback to the requested platform, so a `--platform web`
  export can no longer silently run the Windows preset; plus `Incoming/` added
  to `.gitignore`. Pushed.

### The render loop now exists

The web export was served and driven in headless Chromium via Playwright
(pinned `playwright@1.56.0`, Chromium 141, ANGLE/SwiftShader WebGL2). It boots
to a rendered main menu, accepts keyboard input through the canvas, and
screenshots deterministically — cold start to screenshot in under 20 seconds.
This closes candidate 5 of INVESTIGATE-WEB-EXPORT-BLOCKERS, which could not be
settled without a browser.

Owner intent for this loop: use it to help verify and diagnose the returned
v0.6.0 playtest, whose findings are mostly viewport/scale layout problems that
are reproducible by setting viewport size and the scale settings. It does not
replace the Windows pass — SwiftShader is not a real driver, and it cannot see
controllers or native-window behaviour — but it should reduce how many rounds
that pass needs.

## Plan

1. **Transfer seam (this branch).** One platform-aware service behind the five
   `FileDialog` call sites, per the recommendation: the service gives the single
   seam, and its web branch stages bytes through `user://` so the existing
   path-taking consumers are untouched.

   Measured basis: all five handlers are `(path: String)` and every consumer
   (`Preflight.inspect_zip`, `Installer.install_zip`, `Exporter.export_zip`,
   `SaveManager.export_slot` / `import_portable_save`) does its own IO from that
   path. A bytes-level refactor of those services is therefore *not* required —
   which is what the IMPL-WEB-FILEDIALOG-SHIM row assumed.

   **Export half only for now.** `JavaScriptBridge.download_buffer` is
   first-party (verified present in 4.6.3), and export has no filename text
   entry on web because the browser names the file — so it has no interaction
   with the text-entry seam. The **import half is deliberately deferred** until
   `DESIGN-TEXT-ENTRY-SERVICE-2026-07-31` settles, because that is where the
   three screens adopt the text-entry seam together and doing it twice would
   bake in three copies of the current per-call registry construction.

2. **Identity rename (this branch).** `config/name` moves from
   `"Fire Emblem RPG"` to `"Project Prometheus"`.

   This is a migration, not a rename: `config/name` determines
   `OS.get_user_data_dir()`, so changing it orphans `user://saves`,
   `user://settings.cfg`, installed campaign packages, and the log directory on
   every existing install. A one-time legacy-directory migration ships in the
   same change.

## Factual Git state

- Branch: `agent/from-integration/web-transfer-and-identity`
- HEAD: `3bd2d0a186631e26295cba253f174bf9e150679f`
- Task merge base: `06ef326df5caf1847e31683da9363e9becf2dfa8`

## Commits

- `8aee0ec557d9e60da79e43edb96b57d5a6923f70` — Add the platform transfer seam and route web export through the browser
- `1625ccb9fe08cb08a460f77b954a0fdf772bb1fb` — Track the new .uid sidecars and claim the transfer seam commit

## Checks

- `bash run_tests.sh` (full, at `8aee0ec5`): all suites green. New suite
  `test_transfer_file_service` 7 passed; the two suites that exercise the
  rewired call sites stayed green (`test_campaign_library_screen` 4 passed,
  `test_main_menu` 20 passed).

## Decisions and context

- **Why the export half ships alone.** Splitting on the text-entry blocker
  rather than shipping both halves late: export is the half that is unblocked
  today, and it delivers half of the v1-primary backup path
  (2026-07-25 cloud-sync decision) on web immediately.
- **Why not the bytes-first refactor (Option C).** It lands on `SaveManager.gd`,
  which `IMPL-PACK-SAVE-SCHEMA`, `IMPL-PACK-SAVE-LOAD-MIGRATION` and
  `IMPL-PACK-SAVE-EXPORTS` all already own. The tracker already calls reworking
  save identity on top of those reckless; this is the same collision. It also
  makes `IMPL-ASYNC-PROGRESS-CANCEL` mandatory rather than optional.
- **`config/name` was outside every REN scope.** REN-GDD-PASS scopes to GDD
  prose and recorded `data/` as clean; `project.godot` was in neither, so
  REN-BANNED-STRING-CHECK would have passed while every build shipped the FE
  name in its window title and its save path. Worth extending that check to
  `project.godot` when REN-BANNED-STRING-CHECK is built.

## Next session

Verify both changes through the Playwright loop, then turn the loop on the
returned v0.6.0 viewport/scale findings. The returned bundle is untriaged and
deliberately parked — it is the next thing after this branch.
