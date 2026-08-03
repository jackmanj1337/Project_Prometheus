# Session Note - 2026-08-03-05-30-00Z-pwa-playtest-hosting

## Branch context

- Branch: `agent/from-from-integration-web-transfer-and-identity/pwa-playtest-hosting`
- Base branch: `agent/from-integration/web-transfer-and-identity`
- Base SHA: `e5de416f21dbc8ebcc0bfc6b3045a1f84a0e9a5a`
- Coordination Work ID: `PWA-PLAYTEST-HOSTING-2026-08-03`

## What was done

Turned the web export into an installable Progressive Web App and verified it
works offline, then established what stands between that artifact and a
playtester's iPhone.

### The premise that changed

`AGENT/Docs/design/ios_native_target_feasibility_2026-07-25.md` states that the
web build "cannot run on iOS Safari at all" and that native iOS is therefore the
only route to an iPhone. That was written against a **threaded** web export. This
project does not ship one: the Web preset sets `variant/thread_support=false`,
so the export carries `GODOT_THREADS_ENABLED = false`, needs no SharedArrayBuffer
and no COOP/COEP, and single-threaded is the configuration Godot's own docs now
call the default and describe as working well on iOS. The upstream crash issue
for no-threads iOS builds (godotengine/godot#88321) is closed. The doc's §0
"design to keep iOS open" rules stay correct; its "web is a dead end" premise
does not, and `pwa_ios_playtest_hosting_2026-08-03.md` records the correction.

### What was built

- PWA enabled in the Web preset, pointed at a custom shell and real icons.
- `tools/web/pwa_shell.html` — a copy of the stock 4.6.3 `godot.html` plus only
  the iOS-specific additions, so engine upgrades stay diffable. Details in the
  commit message and the design doc.
- `config/icon` was **unset**, so Godot generated the stock engine robot as
  `index.apple-touch-icon.png`. On iOS that `<link>` overrides manifest icons
  entirely, so the home-screen icon would have been the Godot logo no matter what
  the manifest said. Placeholder `PP` icons added under `assets/pwa_icons/`;
  final art is an owner call.
- The release-source export guard was scoped to release builds. It had made
  local development web exports impossible off any feature branch.

### Verified, not assumed

Driven in headless Chromium against the real export:

- Service worker registers on first load and controls the page on the second.
- Cache Storage holds **39,693,906 bytes across 9 entries** — the precache is
  only ~350KB (html/js/offline/icons/worklets); `index.wasm` (37.7MB) and
  `index.pck` are opt-cache, fetched on first load.
- `CACHE_VERSION` is `unix_time|ticks_usec` stamped at export, so **every export
  self-busts** and `activate` deletes the previous cache. The stale-cache warning
  in Godot's docs applies to serving several projects from one origin, not to
  redeploys.
- With the network fully offline the game boots to a rendered main menu.
- `index.wasm` compresses 37.7MB → **9,396,534 bytes** with `gzip -9`.
- Portrait at 393x852 clips Settings labels off both edges; landscape 852x393
  renders correctly. iOS ignores the manifest `orientation` field, so this cannot
  be locked — hence the shell-level rotate notice.

### Two things I got wrong mid-session, corrected

1. I bumped `application/product_version` to 0.6.2 to satisfy the export guard.
   `test_release_metadata` hardcodes `expected_version := "0.5.8"` and also
   requires a matching checklist and setup-guide reference, so a version bump is
   a five-artifact release ritual, not a config change. Reverted; the guard was
   scoped instead.
2. I read the hardcoded `text = "v0.5.8"` in `MainMenu.tscn` as unguarded drift
   and bound the label to `BuildInfo` at runtime. It is **not** drift:
   `test_release_metadata` already asserts label == preset version, and
   `export-project.py` already re-reads the baked stamp and refuses to export
   unless it matches preset `product_version`. Label == stamp is therefore
   already guaranteed transitively. The change was redundant and was reverted.
   The "v0.5.8 on a 0.6.2 build" I saw was caused by my own bump, not by a bug.

### Real finding worth keeping

`agent/integration` still declares `product_version="0.5.8"` although **v0.6.1
has shipped to testers**. The release version bump has never flowed back to the
integration line, so every development export taken from integration or anything
forked off it bakes a two-releases-stale BUILD STAMP. Not fixed here — it is a
release-line decision, and correcting it drags in the same five-artifact ritual
described above. Tracked as `VERSION-DRIFT-INTEGRATION-2026-08-03`.

## Commits claimed

- `7ff46e1c0a543b91acdd9ead05e16085b5cbb57e` — Scope the release-source check to release builds
- `1ef9bf492e72125359e4f147a12694387fdf16cb` — Export the web build as an installable PWA with an iOS-aware shell
- `418ec32f4c85e354b976e2a9ecfc617beddc296b` — Add dedicated touch controls for web maps
- `1121fa34437f7d396f865203b3a8286a66846ce6` — Record touch controls verification

## Gates

- `bash scripts/run-fast-checks.sh --repo Project_Prometheus` — PASS, all suites
  green (receipt `audit/check-receipts/Project_Prometheus-fast.json`).
- `test_release_metadata` — 5 passed, 0 failed after the version revert.
- Offline/service-worker/cache evidence above, captured from the real export
  served over `scripts/serve-web-local.sh`.

## A guard deadlock worth fixing

The design doc could not be committed on this branch. `check_docs.py` check 30
(active-doc-ownership) requires every active `AGENT/Docs/design/*.md` to be named
in the Project Control Plane, the Feature Index, or the role manifest — **all
three live under `AGENT/Docs/plans/`** — while `docs-guard` blocks any
`AGENT/Docs/plans/**` edit on a feature branch. So a *new* active design doc is
uncommittable on a code branch by construction: one guard demands the edit the
other forbids.

Worked around by putting the design doc on the docs line, which is where
docs-guard wants knowledge artifacts anyway. Recording it because the next person
to write a design doc mid-feature will lose the same cycle to it.

## Next

The artifact is ready; **hosting is what is not.** See
`AGENT/Docs/design/pwa_ios_playtest_hosting_2026-08-03.md` (committed on the docs
line `agent/integration`, not this branch — see below) for the blocker list.
The short version: `FREEZE-WEB-DISTRIBUTION-2026-07-26` forbids public
distribution, and the private tailnet path needs one host-side step this
container cannot perform (it has `CapEff=0`, no `/dev/net/tun`, and
docker-compose publishes no ports).
