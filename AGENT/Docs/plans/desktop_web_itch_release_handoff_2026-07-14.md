---
Type: plan
Status: Planned
Last verified: 2026-07-14
---

# Desktop Web / itch.io Release — Next-Session Handoff

## Outcome

Produce and validate a desktop-browser build of the integrated v0.4.0 candidate,
package it for itch.io, publish it to an itch.io HTML-game page when credentials
and the target page are available, and retain enough evidence to reproduce the
release.

This is a **desktop Web release**, not a mobile-Web release. Keyboard/mouse and
gamepad are supported targets. Do not delay this slice to implement dedicated
touch controls, a virtual gamepad, mobile safe-area feeds, portrait layout, or
iOS/Android certification. Record mobile-browser behavior as unsupported for
this release.

## Start Point and Branch

Start from the clean integrated branch:

```text
agent/codex/2026-07-14/v0.4.0-integration
d32715665408539994782d524a10f141e537fa9e
```

Fetch first and confirm that `HEAD` contains the accepted v0.3.6 fixes and the
closed v0.4.0 review gate. Create a new policy-compliant `agent/**` branch; do
not push directly to the integration, v0.4-prep, main, or release branches.

Read first:

1. This handoff.
2. `AGENT/Docs/plans/v0.4.0_release_checklist_2026-07-13.md`.
3. `AGENT/Docs/guides/environment_setup.md`, especially export preparation.
4. `AGENT/GDD/GDD_07_Input_Cursor.md` for supported input-mode boundaries.
5. Godot 4.6 Web export documentation and itch.io's current HTML-game upload
   documentation. Recheck them during the session rather than relying on old
   browser-header or packaging requirements.

## Known Starting State

- Godot `4.6.3.stable` and matching Web export templates are installed.
- The project uses `gl_compatibility`, which is the appropriate renderer family
  for the Web target.
- `SettingsManager.is_display_config_supported()` and `SettingsScreen` already
  suppress desktop window-mode/resolution controls on Web.
- Input-mode detection permits keyboard/mouse and gamepad in Web builds.
- The repository has no Web export preset. `export_presets.cfg` currently
  contains only the Windows v0.3.6 preset.
- Touch-mode vocabulary exists, but no dedicated touch-control or virtual-pad UI
  exists. Touch-only play is out of scope.
- Browser save persistence, audio startup, focus loss, canvas sizing, and itch.io
  iframe behavior have not been release-tested.
- The v0.4.0 metadata/build/smoke/handoff gates remain open. Coordinate the Web
  artifact with the v0.4.0 metadata pass; do not publish a Web build that still
  identifies itself as v0.3.6.

## Authorization Boundary

The session may create the preset, code/tests/docs needed for desktop Web,
export locally, package the artifact, and prepare itch.io page copy and upload
commands.

Publishing changes an external public page. Proceed only when the owner has
identified the itch.io account/project and supplied an authenticated session or
Butler target. If those are unavailable, finish every local gate and hand back a
ready-to-upload ZIP plus exact manual and Butler upload instructions. Never print
or commit credentials, API keys, cookies, or Butler credential files.

## Execution Plan

### 1. Establish a clean baseline

Before editing:

```bash
git status --short --branch
bash run_tests.sh
python3 AGENT/Docs/check_docs.py
bash scripts/ci/check_rng_usage.sh
```

Record the baseline commit and tool versions. Use a writable temporary `HOME`
for editor/import commands if the container's default Godot cache is not
writable. Restore only known Godot-generated import/cache churn; do not delete
tracked `.uid` or `.import` files.

### 2. Add the Web export preset

Adding `export_presets.cfg` changes release/export configuration and therefore
requires explicit owner approval under repository policy. Obtain that approval
before editing the file.

Add a Godot Web preset named for v0.4.0 with an export path under a dedicated
directory such as `builds/web/v0.4.0/index.html`. Prefer the broadest-compatible
non-threaded Web build unless current Godot and itch.io documentation plus a
real hosted test justify threads and the required cross-origin isolation.

Preserve the release-filter contract:

- include all runtime scenes, scripts, assets, data, and registry manifests;
- exclude `AGENT/**`, tests, tools, development logs, and unrelated build
  evidence;
- ensure the exported entry page is `index.html`;
- do not enable PWA/offline caching without a tested update/cache-invalidating
  policy;
- keep desktop Web resizable and landscape-friendly without pretending mobile
  touch support exists.

Update or add release-metadata coverage so the Web preset name, export path, and
version cannot silently drift.

### 3. Close desktop-Web runtime gaps

Export early, serve it over HTTP, and inspect the browser console. Fix only
confirmed desktop-Web blockers. Likely checks:

- boot reaches the main menu with no missing resources or registry errors;
- display-setting rows hidden on Web do not leave focus gaps or inaccessible
  controls;
- keyboard, mouse, wheel, and connected gamepad inputs are recognized;
- canvas resize/fullscreen behavior keeps menus and the tactical map usable;
- first-user-gesture audio starts correctly and tab background/foreground does
  not break audio or input;
- `user://` settings and suspend data survive reload in normal browser storage;
- a failed/denied browser-storage write reports safely instead of corrupting UI;
- browser shortcuts and the browser Back action do not unexpectedly destroy
  progress during ordinary play;
- there are no Web-incompatible native dependencies or runtime filesystem
  assumptions.

If behavior changes, update the affected `GDD_01`-`08` contract and
`GDD_10_Roadmap.md` status in the same commit. Add focused automated seams where
reasonable, but treat actual browser execution as required evidence.

### 4. Export and validate locally

Run the release preparation path, then export the Web build. Do not open
`index.html` directly from disk; serve its directory over HTTP. Use the workspace
Web server helper if suitable.

Validate at minimum in current desktop Chrome/Chromium and Firefox. Safari is a
useful additional check when a host is available, but it is not a blocker unless
the release claims Safari support.

Desktop-Web smoke checklist:

- [ ] Page loads from a clean browser profile with no fatal console error.
- [ ] Main menu displays `v0.4.0` and the expected build stamp.
- [ ] New Game starts and a map becomes playable.
- [ ] Keyboard navigation, mouse cursor/click behavior, wheel scrolling, and
      required action bindings work.
- [ ] A gamepad can navigate menus and complete a tactical action when browser
      gamepad access is available.
- [ ] Attack Preview opens and one combat completes.
- [ ] Victory gold is awarded through the ledger path.
- [ ] Settings open; unsupported display rows are absent; remaining rows work.
- [ ] Suspend, return to menu, Continue, and browser reload preserve the suspend.
- [ ] Resizing the browser across representative desktop sizes keeps required UI
      reachable.
- [ ] Audio begins after user interaction and survives tab focus loss/return.
- [ ] Browser console and Godot log contain no release-blocking error.

Retain browser/version, OS, viewport sizes, build commit, console output, and
the smoke result in a Web build manifest or playtest handoff.

### 5. Package for itch.io

Create a ZIP whose root contains `index.html` and every generated companion
file. Do not wrap the site in an extra top-level directory. Inspect the archive
listing before upload and record:

- source commit and dirty/clean state;
- Godot version and preset name;
- uncompressed and ZIP sizes;
- SHA-256 of the ZIP;
- the root file listing;
- whether the export is threaded or non-threaded and why.

Name the artifact unambiguously, for example
`Project_Prometheus_v0.4.0_web.zip`. Keep generated builds outside Git unless an
existing release-evidence convention explicitly requires a small manifest.

### 6. Configure and test itch.io

Use the existing owner-designated itch.io project if one exists; otherwise stop
before creating a public project and ask for the account, project slug, title,
visibility, and pricing decision. Recommended first publication is
Draft/Restricted until the hosted smoke passes.

Configure the upload as an HTML game that runs in the browser. Choose an embed
size/aspect suitable for the project's desktop landscape baseline and allow
fullscreen. Add concise page notes:

- desktop browser release;
- keyboard/mouse and gamepad supported;
- touch-only mobile play not supported in this build;
- saves use browser-local storage and can be lost if site data is cleared;
- recommended browsers and any verified limitations.

After upload, repeat the complete smoke checklist in the actual itch.io iframe,
not merely on the direct file or local server. Also test fullscreen exit, page
reload, and returning to the page. Inspect the hosted response/browser console
for WebAssembly, MIME, isolation, mixed-content, and storage errors.

If Butler is available, use a stable channel such as `web` and record the exact
non-secret command. Otherwise document the manual dashboard upload sequence.
Do not make the page Public until the hosted smoke is green and the owner has
approved visibility.

### 7. Release evidence and closeout

Create/update the appropriate active documentation with:

- Web build manifest and checksum;
- local and itch-hosted smoke evidence;
- supported browsers/input modes and explicit exclusions;
- itch.io project URL and visibility at handoff time;
- known issues and rollback/re-upload steps;
- exact source commit and upload channel/file.

Update the v0.4.0 release checklist only for gates actually proven by this
artifact. A Web smoke does not substitute for an unperformed Windows smoke if
the checklist claims both. Regenerate `AGENT/Docs/INDEX.md` after adding docs,
run all checks, write a session note, and add it to
`AGENT/Session Notes/INDEX.md`.

## Commit Boundaries

Recommended commits:

1. Add the approved Web preset, export filtering, and metadata tests/docs.
2. Fix confirmed desktop-Web runtime issues with focused tests and GDD updates.
3. Record the reproducible export/package workflow and local smoke evidence.
4. Record itch.io hosted smoke, page/channel details, and release handoff.

Do not commit generated Web binaries or ZIP files unless the owner explicitly
requests artifacts in Git. Push only the policy-compliant agent branch.

## Exit Conditions

The desktop-Web release is ready when:

- [ ] v0.4.0 metadata is consistent in-game and in the Web preset.
- [ ] Full tests, documentation checks, RNG guard, and headless import pass.
- [ ] The Web export completes from a clean source commit.
- [ ] The upload ZIP is root-correct, hashed, and reproducible.
- [ ] Local Chrome/Chromium and Firefox smoke checks pass.
- [ ] The itch.io-hosted iframe smoke passes with no release-blocking console
      error.
- [ ] Browser-local settings and suspend persistence pass reload testing.
- [ ] Supported controls/browsers and the no-touch boundary are documented.
- [ ] Build manifest, hosted URL/channel, rollback path, and session note exist.
- [ ] Owner approval is recorded before changing the page from Draft/Restricted
      to Public.

If itch.io access or owner page decisions are unavailable, the acceptable
partial exit is a green, hashed, ready-to-upload ZIP plus exact upload settings
and a clearly identified external-publication blocker.
