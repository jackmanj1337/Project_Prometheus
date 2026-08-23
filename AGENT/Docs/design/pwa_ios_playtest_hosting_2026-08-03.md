---
Role: dated
Type: design
Status: Implemented (export) - Blocked (hosting)
Last verified: 2026-08-03
---

# Shipping the web build to playtesters as a PWA (2026-08-03)

**Question asked (owner):** what would it take to make a Progressive Web App
available to playtesters, and can it be done now via GitHub Pages, dev-container
port forwarding + Tailscale, or a Cloudflare tunnel?

**Answer in one line:** the *artifact* is done and verified; **hosting is the
blocker**, and the binding constraint is governance, not technology.

Supersedes the "web is a dead end on iOS" premise in
`ios_native_target_feasibility_2026-07-25.md` (§0 of that doc still stands).

---

## 0. What changed since 2026-07-25

That doc concluded native iOS was the only way to reach an iPhone, because
"the web build cannot run on iOS Safari at all (upstream SharedArrayBuffer /
WebGL2 issues)". That reasoning applied to a **threaded** web export.

We do not ship one. The Web preset sets `variant/thread_support=false`, so:

| Blocker in the 2026-07-25 doc | Status on this build |
|---|---|
| SharedArrayBuffer unavailable | **Not used.** `GODOT_THREADS_ENABLED = false` |
| Requires COOP/COEP isolation | **Not required** for single-threaded |
| WebGL2 unsupported on iOS | **Supported** since iOS 15.0; we use GL Compatibility |
| Godot no-threads iOS crashes (#88321) | **Closed** upstream |

Godot's docs now call single-threaded "the preferred and now default way to
export your games on the Web" and note it "works very well on macOS and iOS,
where it always had compatibility issues with multiple threads exports."

**This does not retire native iOS.** A PWA has no App Store presence, no
background execution, and no Files-app-native save location. What it does is
reach an iPhone with no Mac, no Apple Developer Program, and no review cycle —
and every mobile-web fix it needs (touch mode, safe area, UI scale) is work that
native iOS would need anyway.

## 1. What was built and verified

PWA export is enabled and evidence-backed. See the session note
`2026-08-03-05-30-00Z-pwa-playtest-hosting.md` for the numbers; the short list:

- `index.manifest.json` (`name: Project Prometheus`, `display: standalone`,
  144/180/512 icons), `index.service.worker.js`, `index.offline.html` all emit.
- Service worker registers on load 1, controls the page on load 2.
- **39,693,906 bytes across 9 Cache Storage entries.** Precache is only ~350KB;
  `index.wasm` (37.7MB) and `index.pck` are opt-cache, pulled on first load.
- **The game boots with the network fully offline.**
- `CACHE_VERSION` = `unix_time|ticks_usec` at export → every export self-busts.
- `index.wasm` gzip -9 → **9,396,534 bytes**.

### The iOS-specific things the shell had to add

`tools/web/pwa_shell.html` is the stock 4.6.3 `godot.html` plus:

- `viewport-fit=cover` — without it **every** `env(safe-area-inset-*)` resolves
  to `0px` and Safari letterboxes the page in landscape.
- `apple-mobile-web-app-capable` — iOS honours manifest `display:standalone`
  only from 17.4. **iPhone has no Fullscreen API at all** (iPad only), so
  standalone is the sole way to run without a browser bar. Installing to the
  home screen is the product, not optional polish.
- `theme-color` — Godot's generated manifest carries none.
- `window.PrometheusPWA` — safe-area insets and standalone state, for GDScript
  to read via `JavaScriptBridge`. `DisplayServerWeb` implements **no** safe-area
  support, which is exactly why `UI-VIEWPORT-ASPECT-2026-07-31` deferred the
  mobile zoom default ("`get_safe_area_insets()` is hardcoded zero until a
  mobile-web release feeds real values"). A PWA *is* that release.
- `navigator.storage.persist()` — WebKit grants it on heuristics that favour
  home-screen web apps. Eviction is **per origin, all at once**, so without it a
  storage-pressure event takes `user://` (saves, settings, packs) wholesale.
- A portrait rotate notice — iOS ignores the manifest `orientation` field, so
  orientation cannot be locked, and portrait clips Settings labels off both
  edges at 393x852.

**`config/icon` was unset**, so Godot generated the stock engine robot as
`index.apple-touch-icon.png`. On iOS that `<link>` **overrides manifest icons**,
so the home screen would have shown the Godot logo whatever the manifest said.
Placeholder `PP` icons added; final art is an owner call.

## 2. Hosting: what blocks it, and what each path costs

### Blocker A — the distribution freeze (governance, binding)

`FREEZE-WEB-DISTRIBUTION-2026-07-26`: *"NO WEB BUILDS ARE DISTRIBUTED until the
data extraction completes and FE-EXPORT-GUARD lands."* Its gates are
`IMPL-ZERO-CONTENT-BASE-PACK` (planned), `IMPL-ZERO-CONTENT-EXPORT-GATE`
(planned) and `FE-EXPORT-GUARD-2026-07-20` (planned). It explicitly exempts
local export, so everything in §1 was permitted; **publishing is not.**

Facts the owner should weigh, since the freeze predates them:

- Unit art in the build is **222-byte placeholder squares**, not FE art.
- `data/` still carries FE-derived terminology: `master_seal`, `second_seal`,
  `guiding_ring`, `elfire`, `orion_bolt`, and class names (Paladin, Sage,
  Bishop, Great Knight, War Monk).
- **`jackmanj1337/Project_Prometheus` is already a PUBLIC GitHub repo**, so that
  terminology is public today. The freeze's own premise — "a public BUILD
  redistributes FE art just as a public repo does" — cuts both ways here.

This does not lift the freeze. It means the freeze may be aimed at a payload
that has already changed, and that is worth an explicit decision rather than
drift.

### Blocker B — the container cannot open a port to the tailnet

Measured in this container:

- `CapEff: 0000000000000000` — **no capabilities at all**.
- `/dev/net/tun` **does not exist**.
- `docker-compose.yml` declares **no `ports:` mapping**.
- `host.docker.internal` = `192.168.65.254` → Docker Desktop's VM, not the WSL
  distro where tailscaled runs.

So nothing inside here can join a tailnet or expose itself to one. A host-side
step is required and cannot be automated from in here.

### Blocker C — HTTP is not a secure context

`scripts/serve-web-local.sh` runs `python3 -m http.server`, i.e. plain HTTP. Over
a raw tailnet IP (`http://100.x.y.z:8060`) **the service worker will not
register and the PWA cannot be installed** — it degrades to an ordinary web page,
losing offline launch, the home-screen icon, standalone display, and the storage
persistence that protects saves. Secure context is not a nicety here; it is the
whole feature.

### The three routes, compared

| Route | Public? | Secure context | Blocked by | Cost to enable |
|---|---|---|---|---|
| **Tailscale serve** | No — tailnet only | **Yes**, `*.ts.net` cert | B (+C solved by it) | One host command + a compose port |
| **Cloudflare tunnel** | Yes (random URL) unless Access-gated | Yes | A; needs `cloudflared` installed | Download binary; Access needs a CF account |
| **GitHub Pages** | **Yes, fully public** | Yes | **A** | Trivial — repo is already public |

**Recommendation: Tailscale serve.** It is the only route that is both secure
context and non-public, so it does not touch Blocker A; it matches the private
server direction already chosen in `ios_native_target_feasibility_2026-07-25.md`
§3.2 (Tailscale avoids the iOS Local Network Privacy prompt); and the owner
already runs tailscaled on the WSL host.

Its limit: playtesters must be on the tailnet. Fine for the owner's own iPhone
and a small trusted group (Tailscale supports node sharing); not a route to
open playtesting. Open playtesting needs Blocker A resolved.

### Exact steps for the Tailscale route

1. **Publish the port** (needs owner approval — `docker-compose.yml` is on the
   approval list, and applying it recreates the container):

   ```yaml
   services:
     dev:
       ports:
         - "8060:8060"
   ```

   Then `docker compose up -d` from the workspace root.

2. **Serve from the container**, bound so the mapping can reach it:

   ```bash
   bash scripts/serve-web-local.sh --repo Project_Prometheus --port 8060 --bind 0.0.0.0
   ```

3. **Front it with HTTPS from the WSL host** (this is the step that creates the
   secure context, and it must run where tailscaled lives):

   ```bash
   tailscale serve --bg --https 443 http://127.0.0.1:8060
   tailscale serve status
   ```

   Requires MagicDNS + HTTPS certificates enabled in the tailnet admin console.

4. **On the iPhone:** connect the Tailscale app, open
   `https://<machine>.<tailnet>.ts.net/`, then Share → Add to Home Screen.
   Launch from the icon — not the Safari tab — or none of the standalone,
   offline, or storage-persistence behaviour applies.

## 3. What is still unknown, and can only be answered on a device

Nothing in §1 was tested on real WebKit. Chromium is the closest proxy available
on Linux and it is not close enough for these:

1. **Memory ceiling — the one that can kill the idea.** iOS Safari enforces a
   per-tab memory limit and reloads the tab when it is hit
   (godotengine/godot#70621, #104422). A 37.7MB wasm plus heap is the risk. This
   needs a 30+ minute real-play soak before anything is promised to a tester.
2. **Cache Storage limit.** Secondary sources report a fixed ~50MB Cache API cap
   per partition on iOS; WebKit's own Safari 17 storage-policy post describes
   quotas computed from disk space and mentions no such cap. We sit at 39.7MB
   and it grows with the `.pck`. **Measure it; do not trust either number.**
3. Whether `navigator.storage.persist()` is actually granted once installed.
4. Audio after the first gesture, and mute-switch behaviour.
5. Real safe-area inset values, and whether the rotate notice reads correctly.
6. Physical legibility at 852x393. Landscape *renders* correctly, but the UI is
   authored at a 1280x720 floor; the existing `content_scale_factor` /
   `menu_scale` setting is the intended lever, and picking a mobile-web default
   is `MOBILE-WEB-UX-GAPS-2026-08-03`.

Simulators do not reproduce safe-area behaviour reliably, so items 3–6 need
hardware too.

## 4. Known engine-side gap that will bite immediately

`InputModeManager.available_modes_for_platform()` gates `MODE_TOUCH` on
`OS.has_feature("mobile")`, which is **false on web** — Godot exposes
`web_ios` / `web_android` instead (both strings confirmed present in our
4.6.3 `godot.js`). **Touch mode is therefore unavailable on an iPhone PWA
today.** Mouse emulation from touch still delivers taps, so the game is
operable, but touch is not a selectable input mode and nothing is tuned for it.
Tracked as `MOBILE-WEB-UX-GAPS-2026-08-03`.

## 5. Recommendation

1. Take the Tailscale route now for the owner's own device — it needs no freeze
   decision and answers every §3 question.
2. Decide Blocker A explicitly, with §2's payload facts on the table. Wider
   playtesting cannot start until it is decided either way.
3. Land `MOBILE-WEB-UX-GAPS-2026-08-03` before any tester who is not the owner
   sees it, or the first three reports will all be "touch feels wrong".
4. Leave GitHub Pages alone until the freeze lifts. It is trivial to enable and
   irreversible in the sense that matters — a public URL can be indexed and
   archived before anyone reconsiders.

## Related

- `ios_native_target_feasibility_2026-07-25.md` — §0 rules still apply; §"web is
  a dead end" premise corrected here.
- Tracker: `PWA-PLAYTEST-HOSTING-2026-08-03`, `MOBILE-WEB-UX-GAPS-2026-08-03`,
  `PWA-TAILNET-HOSTING-2026-08-03`, `IOS-DEVICE-PWA-VERIFICATION-2026-08-03`,
  `FREEZE-WEB-DISTRIBUTION-2026-07-26`, `VERSION-DRIFT-INTEGRATION-2026-08-03`.
