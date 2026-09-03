---
Role: dated
---

# Native iOS as a release target — feasibility & impact (2026-07-25)

**Status:** investigation (owner-requested, cloud-sync session 2026-07-25). First
pass. Question asked: *what would it take to add native iOS builds as a release
target, and how would that affect our server options / design / the rest of the
build?*

**OWNER DECISION (2026-07-25): native iOS is an ACCEPTED POST-V1 target.** It does
not block v1 and is not built in v1, but it is a committed future direction — so
**we should proactively avoid choices that make it harder or more restricted
later.** The design rules in §0 below exist to keep that door open cheaply while
we build v1. Treat "would this box iOS in?" as a standing review question for any
pack/scripting/server/purchase decision.

## 0. Design-to-keep-iOS-open rules (apply during v1, don't wait)
These cost ~nothing now and are expensive to retrofit:
1. **Keep pack logic declarative / data-driven.** Interpreters ship inside the
   app; packs supply *data*, not downloaded scripts. This is the single most
   important rule — it keeps guideline 2.5.2 (§4) from ever biting. If the
   minigame/scripting runtime must interpret authored logic, ensure that logic is
   either bundled in the app or expressible as data the in-app interpreter reads.
2. **Keep the app fully functional offline.** Manual export/import is the primary
   backup path and needs no server, so the app stands alone — which is exactly
   what App Review 2.1 (§3) requires. Don't let any feature become server-required.
3. **Keep purchase/hosting out of the client's UI surface.** No "buy packs / buy
   hosting" links inside the app build (avoids IAP guideline 3.1.1, §3). Route
   any commerce out-of-app.
4. **Prefer Tailscale over raw-LAN assumptions** in the private-server design, so
   the iOS Local Network Privacy prompt (§3) is a non-event rather than a redesign.
5. **Don't hard-couple the build to a desktop-only file model.** The manual
   export/import already uses portable files; keep it FileDialog/Files-app-shaped
   rather than assuming a fixed desktop path.

Following §0 means adding iOS later is "stand up a macOS build path + go through
Apple review," not "re-architect packs/saves/server."

**Context that makes this relevant:** the current v1 targets are web + Windows
native + Steam-Deck-as-native-Linux. The **web build cannot run on iOS Safari**
at all (upstream SharedArrayBuffer / WebGL2 issues, and every iOS browser is
WebKit underneath). So today an iPhone player has **no** working path. A **native
iOS build is the clean way to serve iPhone** — not fixing web-on-iOS.

---

## 1. What it takes to ship native iOS at all

- **A Mac + Xcode are mandatory.** Godot's iOS export does **not** produce a
  finished `.ipa` — it generates an **Xcode project** you then build/sign/ship
  from Xcode. This is the single biggest logistical change: our current pipeline
  (Linux/Windows) **cannot** produce the final artifact. Adding iOS means adding
  a **macOS build step** (a Mac, or a macOS cloud CI runner).
- **Apple Developer Program — $99/yr**, plus provisioning profiles, signing
  certificates, device UDIDs for test builds, and App Store Connect. Ongoing.
- **Export config** requires App Store Team ID + bundle identifier set in the iOS
  preset (blank = export error). Standard.
- **Godot 4.6 supports iOS export** and it is documented. Rendering runs on Metal;
  a tactical-RPG is light on GPU so that's not a concern. Touch input already has
  a branch (`InputModeManager` handles `OS.has_feature("mobile")`), but **phone
  form-factor UI scaling is real work** (small screens; ties into the existing
  display-scaling design docs).

**Verdict on feasibility:** technically well-trodden. The cost is not "can Godot
do it" — it's the **ongoing commitment**: a Mac in the build path, the Apple
program, and Apple's review + annual SDK/OS-bump cadence.

## 2. The upside for our backup/transfer story

Native iOS actually *fixes* the thing that's broken today:
- A native iOS app **runs** (unlike the HTML5 build) and has a **real sandboxed
  filesystem** — `user://` is a durable app-container directory, **not** the
  volatile web IndexedDB.
- So the **manual export/import backup path finally works on iPhone**: export a
  save/pack to a file, hand it to the iOS **Files app** / iCloud Drive, move it to
  the Windows machine, import. That's the exact flow that's a dead end on
  web-on-iOS today. This reinforces the v1 decision — manual export/import is the
  primary mechanism and it becomes genuinely usable on iPhone *via native*, not
  via web.
  - Minor plumbing: to make exports visible in the Files app we'll likely set the
    Info.plist flags `LSSupportsOpeningDocumentsInPlace` and
    `UISupportsDocumentBrowser`, and point the export FileDialog at the app's
    Documents dir.

## 3. Impact on the server options / design

The owner's server direction is a **private server** for **home-servers or a
private web-app hosting service** the *user* runs — explicitly **not** an
owner-operated service for everyone. iOS interacts with that in four ways:

1. **Local Network Privacy prompt.** iOS gates LAN access behind a permission
   prompt; connecting to a home server on the LAN needs
   `NSLocalNetworkUsageDescription`, and mDNS/Bonjour discovery is restricted.
   Expect a first-run "allow local network" dialog for the LAN case.
2. **Tailscale sidesteps that.** Traffic over Tailscale rides a VPN interface, not
   "the local network," so it avoids the LAN-privacy prompt and works off-LAN
   too. Tailscale has a first-class iOS app. **This further favors the
   Tailscale-based private-server path over raw LAN on iOS** (and Tailscale's
   `*.ts.net` HTTPS certs also solve secure-context for any embedded web view).
3. **App Review 2.1 (self-host-only is hard to review).** A reviewer has no home
   server to point the app at. Apple can reject an app that is non-functional
   without user-supplied infrastructure. **Mitigation: the app must be fully
   functional offline by default** — which it is, because manual export/import is
   the primary path and needs no server. The "server" is a power-user add-on, not
   a requirement. Keep it that way and review risk stays low. (Apple's own
   guidance: apps may connect to a user-owned host on the local network, but the
   app must still stand on its own for review.)
4. **IAP / guideline 3.1.1.** If we ever *sell* hosting or packs **through the iOS
   app**, Apple mandates In-App Purchase and takes its cut. Since distribution is
   out of scope and the server is user-hosted (not a service we sell), this is
   mostly avoided — **but do not put "buy hosting / buy packs" links in the iOS
   build**, or that triggers IAP rules.

## 4. The pack-architecture constraint: guideline 2.5.2 (downloadable code)

This is the most consequential cross-impact and it touches the content model, not
just distribution:

> *An app may not download or install executable code. Interpreted code may only
> be used if all scripts, code, and interpreters are packaged in the app and not
> downloaded.*

- **Data-only packs are fine** — stats, maps, items, terrain, approved media
  (`png/ogg/wav/ttf/otf`, per `CampaignPackExporter`). Downloading/importing those
  on iOS is not "executable code."
- **Packs carrying interpreted scripting are a rejection risk on iOS.** We have an
  active scripting-runtime line of work (`minigame_scripting_runtime_research_2026-06-28.md`,
  `minigame_activity_type_initial_specs_2026-06-28.md`). If minigame/pack logic is
  *interpreted script downloaded at runtime* (via import, a future server, or
  distribution), that collides with 2.5.2 **on iOS specifically**.
- **Design implications (pick one, per feature):** keep pack logic **declarative /
  data-driven** (interpreter ships in the app, packs only supply data — the clean
  answer); OR **bundle scripted content in the app binary** (not downloaded); OR
  **gate scripted packs off on iOS** (import them as data-only, disable the
  scripted behavior on that platform). This should feed directly into the
  scripting-runtime design so we don't paint iOS into a corner later.

## 5. Other build impacts (summary)
- **Build pipeline:** add a macOS step (Mac or cloud runner) — biggest change.
- **Save durability:** *better* on iOS than web — sandboxed FS, not IndexedDB.
- **Files app integration:** Info.plist flags + export dir choice (minor).
- **UI / input:** touch is partly handled; phone-screen layout/scaling is real work.
- **Steam:** irrelevant (already dropped as a platform).
- **Maintenance cadence:** Apple's annual program renewal, forced min-OS/SDK bumps,
  and review latency become a recurring cost the other targets don't impose.

## 6. Recommendation
- **Native iOS is the right way to reach iPhone** (web-on-iOS is a dead end), and
  it *improves* the manual-backup story (real FS + Files app). It does **not**
  block v1 and shouldn't be pulled into it.
- **It is a committed post-v1 target** (owner, 2026-07-25). The three standing
  costs are accepted as *future* costs: (a) a macOS build path, (b) the Apple
  program + review cadence, (c) the **2.5.2 data-only-pack constraint**. Per §0,
  we pay none of them in v1 but avoid decisions that would inflate them — above
  all, keep pack logic data-driven so (c) is free.
- **When we do it**, prefer the **Tailscale** private-server path on iOS (avoids
  LAN-privacy friction), and keep the app **fully functional offline** (manual
  export/import primary) so App Review 2.1 is a non-issue.

## Open questions
- macOS build: buy a Mac mini for the pipeline vs. a macOS cloud CI (cost/latency
  trade)?
- Is the minigame scripting runtime interpreted-at-runtime, or compiled/declarative?
  (Decides whether 2.5.2 bites at all.) → route into the scripting-runtime design.
- Do we want iPad as a distinct layout target, or iPhone-only first?
- Minimum iOS version / device floor (affects Metal feature set + audience).

## Related
- `campaign_backup_content_addressed_format_2026-07-25.md` (backup format).
- Tracker: `INVESTIGATE-CLOUD-SYNC-THIRD-PARTY-2026-07-25`,
  `INVESTIGATE-FIRST-PARTY-SYNC-SERVER-2026-07-25`.
- Scripting: `minigame_scripting_runtime_research_2026-06-28.md`.
