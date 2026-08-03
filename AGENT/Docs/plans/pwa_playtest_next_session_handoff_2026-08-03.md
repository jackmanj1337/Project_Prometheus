---
Type: plan
Status: Ready to start - two owner decisions gate parts of it
Last verified: 2026-08-03
Tracker: PWA-PLAYTEST-HOSTING-2026-08-03
---

# Next-session handoff — finish the PWA playtest path

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md),
with cross-branch state in `coordination/tasks.json` under the five
`*-2026-08-03` rows listed below.

**Read first:** [`../design/pwa_ios_playtest_hosting_2026-08-03.md`](../design/pwa_ios_playtest_hosting_2026-08-03.md)
— the evidence and the blocker analysis. This file is only the work order.

## Where things stand

The PWA **exists and is verified**. On 2026-08-03 the web export was turned into
an installable Progressive Web App and driven in headless Chromium against the
real artifact: the service worker registers on load 1 and controls load 2,
39,693,666 bytes land in Cache Storage across 9 entries, and **the game boots to
a rendered main menu with the network fully offline**. `index.wasm` is 37.7MB,
9,396,534 bytes at `gzip -9`.

What is *not* done is everything between that artifact and a playtester's phone.

| Row | Status | What it is |
|---|---|---|
| `PWA-PLAYTEST-HOSTING-2026-08-03` | in_review | The export. Built, pushed, needs merge forward. |
| `MOBILE-WEB-UX-GAPS-2026-08-03` | in_progress | **The main build item.** Touch, safe area, portrait, scale. |
| `PWA-TAILNET-HOSTING-2026-08-03` | in_review | Half built; one step is the owner's. |
| `IOS-DEVICE-PWA-VERIFICATION-2026-08-03` | in_progress | Owner action, needs a physical iPhone. |
| `VERSION-DRIFT-INTEGRATION-2026-08-03` | in_progress | Integration says 0.5.8; v0.6.1 shipped. |

Branches pushed on 2026-08-03:

- `Project_Prometheus` → `agent/from-from-integration-web-transfer-and-identity/pwa-playtest-hosting`
  (`7ff46e1c`, `1ef9bf49`, `e248a14e`)
- `Project_Prometheus_Container` → `agent/from-staging-area/pwa-tailnet-hosting` (`494598d`)
- Docs line `agent/integration` → `fde866f0`, `b5101dc7`, `8af645d9`

---

## Step 0 — two owner decisions, ask at session start

Both gate later steps, and both are cheap to ask. Do not start Step 3 or Step 4
without them.

**(a) Does `FREEZE-WEB-DISTRIBUTION-2026-07-26` still fit its payload?**
The freeze forbids distributing any web build until zero-content Slice 3/4 and
`FE-EXPORT-GUARD` land — all still `planned`. Facts that postdate the ruling and
should be on the table when it is revisited:

- Unit art in the build is **222-byte placeholder squares**. There is no FE art.
- `data/` still carries FE-derived terminology: `master_seal`, `second_seal`,
  `guiding_ring`, `elfire`, `orion_bolt`, and class names (Paladin, Sage,
  Bishop, Great Knight, War Monk).
- **`jackmanj1337/Project_Prometheus` is already a PUBLIC GitHub repo**, so that
  terminology is public today. The freeze's own premise — "a public BUILD
  redistributes FE art just as a public repo does" — cuts both ways.

This is not an argument to lift it. It is an argument that it should be decided
rather than left to drift, because it is the only thing blocking open playtesting.
**A tailnet-only build does not need this decision** (see Step 3).

**(b) Approve the `docker-compose.yml` port mapping?**
Required for Step 3. It is on the approval-required list in `AGENTS.md`, *and*
applying it recreates the container — which kills the running agent session. So
the owner both approves it and applies it, and the agent picks up afterwards.

---

## Step 1 — merge the PWA branch forward

`PWA-PLAYTEST-HOSTING-2026-08-03` is `in_review` and everything else builds on it.

**Path overlaps to resolve at merge — these are declared, not accidental.** The
row claims only `tools/web/pwa_shell.html` and `scripts/tools/prepare_build.sh`
outright. It also edits:

- `export_presets.cfg` — claimed by `FIX-WEB-EXPORT-PRESET-2026-07-31` (in_review).
  That row is this branch's ancestor, so merging it first makes this a
  fast-forward rather than a conflict.
- `project.godot` — **one line**, `config/icon`. Claimed by
  `IMPL-VIEWPORT-ANCHORING-2026-07-31` (in_progress), which also claims
  `SettingsManager.gd` along with `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT-2026-07-29`.
  Whoever merges second hits a textual conflict on `project.godot`; the resolution
  is trivial (both add distinct keys) but do not let a merge tool drop one.
- `assets/pwa_icons/` — new directory; `assets/` is claimed by
  `IMPL-ZERO-CONTENT-BASE-PACK` and `LEG-ENGINE-ASSET-PROVENANCE-2026-07-26`.
  The icons are placeholder `PP` monograms generated with ImageMagick, not
  third-party art, so provenance is clean — but say so in the merge, because
  `LEG-ENGINE-ASSET-PROVENANCE` exists precisely to catch unexplained art.

**Final art for the icons is an owner call.** Placeholders are deliberate.

## Step 2 — `MOBILE-WEB-UX-GAPS-2026-08-03` (the main build)

Do this **before any tester who is not the owner sees the build**, or the first
three reports will all be "touch feels wrong". Four sub-items, roughly a day.

**2.1 Touch mode is unavailable by construction.**
`scripts/autoloads/InputModeManager.gd:189-194` —
`available_modes_for_platform()` gates `MODE_TOUCH` on `OS.has_feature("mobile")`,
which is **false on web**. Godot exposes `web_ios` / `web_android` instead; both
strings are confirmed present in our `4.6.3` `godot.js`. Mouse-emulation-from-touch
still delivers taps so the game is *operable* today, but touch is not a selectable
mode and nothing is tuned for it. Extend the platform detection and the existing
`scripts/tests/test_input_mode_manager.gd`.

**2.2 Feed real safe-area insets.**
`platform/web/display_server_web.cpp` has **no** safe-area implementation, so
`get_display_safe_area()` reports the whole window and the game draws under the
Dynamic Island. This is exactly why `UI-VIEWPORT-ASPECT-2026-07-31` decision (3)
deferred the mobile zoom default: *"`get_safe_area_insets()` is hardcoded zero
until a mobile-web release feeds real values."*

The values now exist and nothing consumes them. `tools/web/pwa_shell.html`
publishes:

```js
window.PrometheusPWA.safeArea()          // {top,right,bottom,left} in CSS px
window.PrometheusPWA.isStandalone()      // launched from home screen?
window.PrometheusPWA.devicePixelRatio()
window.PrometheusPWA.isPersisted()       // navigator.storage.persist() granted?
```

Read them with `JavaScriptBridge.eval()` on load and on `orientationchange`.
The Playwright harness already models safe area (`--safe` on
`scripts/playwright-drive.sh`), so this is testable the day it lands.

**2.3 Portrait: replace the stopgap.**
iOS **ignores the manifest `orientation` field**, so orientation cannot be locked.
Screenshot-verified at 393x852: the Settings panel clips labels off the *left* and
values off the *right*. The shell carries a CSS-only rotate notice (portrait +
coarse pointer) as a stopgap. Decide whether the real answer is an in-engine
overlay or a portrait layout, and supersede it.

**2.4 Pick a mobile-web default UI scale.**
Landscape 852x393 *renders correctly* — this is a legibility problem, not a layout
one. The UI is authored to a 1280x720 floor, so text is physically small on a
6-inch screen. The lever already exists: `UI-VIEWPORT-ASPECT` decision (1) made
`content_scale_factor` a persisted user setting. Choose a `web_ios` default.
**This is a settings default, not a UI rebuild** — do not let it become one.

## Step 3 — hosting (`PWA-TAILNET-HOSTING-2026-08-03`)

Already done and pushed: `export-project.py` passes `--mode` through as
`PROMETHEUS_BUILD_MODE`, and `serve-web-local.sh` warns when serving a PWA over a
non-localhost plain-HTTP bind.

Remaining, in order:

1. **Owner** — the compose mapping from Step 0(b), then `docker compose up -d`:
   ```yaml
   services:
     dev:
       ports:
         - "8060:8060"
   ```
2. **In container** —
   `bash scripts/serve-web-local.sh --repo Project_Prometheus --port 8060 --bind 0.0.0.0`
3. **On the WSL host, where tailscaled actually runs** —
   ```bash
   tailscale serve --bg --https 443 http://127.0.0.1:8060
   tailscale serve status
   ```
   Needs MagicDNS **and** HTTPS certificates enabled in the tailnet admin console.
4. **iPhone** — Tailscale app connected, open `https://<machine>.<tailnet>.ts.net/`,
   Share → **Add to Home Screen**, then **launch from the icon**. A Safari tab gets
   none of the standalone, offline, or persistent-storage behaviour.

**Why HTTPS is not optional:** service workers are refused outside a secure
context. Plain HTTP over a tailnet IP silently drops the service worker, offline
launch, install, standalone display and storage persistence — while still
rendering a page that looks completely fine. That failure is invisible unless you
go looking for it.

**Why Tailscale and not the alternatives:** it is the only route that is both
secure-context and non-public, so it does not touch Step 0(a) at all. It also
matches the private-server direction already chosen in
[`../design/ios_native_target_feasibility_2026-07-25.md`](../design/ios_native_target_feasibility_2026-07-25.md)
§3.2 (Tailscale avoids the iOS Local Network Privacy prompt). Its limit is that
testers must be on the tailnet — fine for the owner and a small trusted group via
node sharing, not a route to open playtesting.

Measured in-container 2026-08-03, so nobody re-derives it: `CapEff=0000000000000000`
(no capabilities at all), `/dev/net/tun` absent, no `ports:` in `docker-compose.yml`,
`host.docker.internal=192.168.65.254` (Docker Desktop's VM, **not** the WSL distro
where tailscaled runs). Nothing inside the container can join a tailnet or expose
itself to one. `cloudflared`, `ngrok` and `caddy` are all absent too.

## Step 4 — `IOS-DEVICE-PWA-VERIFICATION-2026-08-03`

Write `AGENT/Docs/playtests/pwa_ios_device_checklist.md`, then the owner runs it
on hardware. **Nothing in Step 1–3 was tested on real WebKit** — Chromium is the
closest proxy available on Linux and is not close enough for any of these.
Ordered by risk:

1. **Memory soak — the one that can kill the whole idea.** iOS Safari enforces a
   per-tab memory ceiling and reloads the tab when it is hit
   (godotengine/godot#70621, #104422). A 37.7MB wasm plus heap is the exposure.
   **30+ minutes of real play before anything is promised to a tester.**
2. **Cache Storage cap.** Secondary sources report a fixed ~50MB Cache API cap per
   partition on iOS; WebKit's own Safari 17 storage-policy post describes
   disk-derived quotas and mentions no such cap. We sit at 39.7MB and it grows
   with the `.pck`. **Measure it — trust neither number.**
3. Whether `navigator.storage.persist()` is actually granted once installed.
   (An installed home-screen app is exempt from Safari's 7-day script-writable
   storage cap and gets browser-equal origin quota, but eviction is still
   **per origin, all at once** — it would take `user://` wholesale.)
4. Audio after the first gesture; mute-switch behaviour.
5. Real `env(safe-area-inset-*)` values in landscape; does the rotate notice read?
6. Physical legibility at 852x393 (feeds 2.4).

Simulators do not reproduce safe-area behaviour reliably, so 3–6 need hardware too.

## Step 5 — `VERSION-DRIFT-INTEGRATION-2026-08-03`

`agent/integration` declares `application/product_version="0.5.8"` and preset.0
name `Project Prometheus v0.5.8`, but **v0.6.1 has already shipped to testers**.
The release-line bump never flowed back, so every development export from
integration or anything forked off it bakes a two-releases-stale BUILD STAMP —
the same class as the v0.6.1 incident where the exporter shipped a v0.6.0 stamp.

**It is not a one-line fix.** A version bump moves six artifacts together:

1. `export_presets.cfg` → `application/product_version`
2. `export_presets.cfg` → preset.0 `name`
3. `export_presets.cfg` → preset.0 `export_path`
4. `scenes/ui/MainMenu.tscn` → the `VersionLabel` `text` literal
5. `AGENT/Docs/playtests/playtest_checklist_v<version>.md` must exist
6. the environment setup guide must name the current build

`scripts/tests/test_release_metadata.gd` asserts all of them — and **hardcodes
`var expected_version := "0.5.8"` in the test body**, making the test itself a
seventh thing to hand-edit. While fixing the drift, consider deriving
`expected_version` from `export_presets.cfg` so it stops being one.

*Do not bump the version casually to satisfy an export guard.* That was tried on
2026-08-03 and reverted; see the session note.

## Step 6 — the guard deadlock

`check_docs.py` check 30 (`active-doc-ownership`) requires every active
`AGENT/Docs/{plans,design}/*.md` to be named in the Project Control Plane, the
Feature Index, or the role manifest — **all three live under `AGENT/Docs/plans/`**
— while `docs-guard` blocks any `AGENT/Docs/plans/**` edit on a feature branch.
So a **new** active design doc is uncommittable on a code branch by construction:
one guard demands exactly the edit the other forbids.

Worked around on 2026-08-03 by putting the design doc on the docs line, which is
where docs-guard wants knowledge artifacts anyway. That is a fine outcome; the
problem is that the failure mode is a confusing two-guard bounce rather than a
message saying "put this on the docs line". Cheapest real fix is for `docs-guard`
to name the docs line in its rejection when the blocked path is a doc-ownership
source, so the next person spends a minute instead of a cycle.

---

## Traps already paid for — do not re-pay them

- **The export staleness guard.** `playwright-drive.sh` refuses to run when
  `builds/web/<repo>` was built from a different commit than HEAD. Re-export
  (`bash scripts/export-web.sh --repo Project_Prometheus --force`), do not reach
  for `--allow-stale` unless driving the older build is the actual point.
- **`[PASS]` is not evidence.** `playwright-drive.sh` prints no screenshots by
  default. Pass `--out DIR` and *look at the PNG*.
- **The harness's Tier-2 navigation needs the instrumented export.** The bridge
  instrumentation is on the v0.6.1 branch lineage, not on
  `web-transfer-and-identity`. A drive against a build from this lineage reports
  "uninstrumented export" and fails navigation — that is **not** a broken build.
  Verify boot with a direct Playwright probe instead; `probe.mjs` / `offline.mjs`
  patterns are described in the session note.
- **`vram_texture_compression/for_mobile` must stay `false`.** With it true,
  Godot 4.6.3 fails the web export with an **empty** error message.
- **`variant/thread_support` must stay `false`.** It is what makes the build run
  on iOS at all, and `serve-web-local.sh` sends no COOP/COEP headers.
- **Do not `pkill -f` a pattern that matches your own shell.** Cost a tool call.

## Related

- [`../design/pwa_ios_playtest_hosting_2026-08-03.md`](../design/pwa_ios_playtest_hosting_2026-08-03.md)
  — evidence and blocker analysis.
- [`../design/ios_native_target_feasibility_2026-07-25.md`](../design/ios_native_target_feasibility_2026-07-25.md)
  — §0 keep-iOS-open rules still stand; its "web is a dead end on iOS" premise is
  corrected by the doc above (it held for a *threaded* export; we ship
  single-threaded).
- Session notes `2026-08-03-05-30-00Z-pwa-playtest-hosting.md` (feature branch)
  and `2026-08-03-06-20-00Z-pwa-hosting-docs-line.md` (docs line).
