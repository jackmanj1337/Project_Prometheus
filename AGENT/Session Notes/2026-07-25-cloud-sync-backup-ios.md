# Session Note - 2026-07-25 (cloud sync / backup + native-iOS research)

## What was done

Owner-led research + debate on cloud syncing/backup for saves and campaign packs,
plus a first-pass investigation of native iOS as a release target. Discussion-only
this session (no game code changed); outputs are two design docs + tracker updates.

### Situation established
- v1 launch targets = **web + Windows-native + Steam-Deck-as-native-Linux** (NOT
  sold through Steam). Goal = **both** disaster-recovery backup AND cross-device
  continue, single-user with possible limited family sharing; full pack
  distribution is out of scope indefinitely.
- Current state audited in-repo: saves are per-slot JSON under `user://saves/`
  (`SaveManager.gd`), export/import already exists via `FileDialog`
  (`LoadGameScreen`/`CampaignLibraryScreen`), packs export as deterministic zips
  (`CampaignPackExporter`), and saves carry a tamper hash (`SaveIntegrity`,
  sha256 of canonical JSON). No browser download/upload bridge is wired, so web
  export writes only into the virtual IndexedDB FS.

### Decisions (owner)
1. **Steam is NOT the backbone** — Steam Cloud only covers a Steam SKU, and we
   aren't shipping through Steam. Dropped as the baseline.
2. **Manual export/import is the PRIMARY backup + transfer path and likely
   sufficient for v1.** It already exists for saves and packs.
3. **Third-party cloud = "a folder the user points at"** (Drive/Dropbox/Syncthing
   sync it) — provider-agnostic file export/import, **no Drive API / OAuth**. The
   truly universal primitive is "a file" (native: chosen folder; web: browser
   download/upload). Actual Drive API integration stays a back-pocket option only
   if automatic web backup becomes a must-have before a server exists.
4. **Server = private / self-hosted only** — a home-server OR a private web-app
   hosting service the *user* runs, explicitly **not** an owner-operated
   first-party service for everyone. Same server software, two hosting modes;
   prefer **Tailscale** (sidesteps LAN issues, works off-LAN, HTTPS certs).
5. **Next backup layer (post-v1) = content-addressed store** so backups don't
   clutter the user's cloud folder with N copies of an untouched pack — write-once
   hash-named blobs + tiny snapshot manifests; safe pruning via refcount/GC.
   Builds directly on the existing deterministic export + SaveIntegrity hashes.
6. **Native iOS = accepted POST-V1 target.** It's the clean way to reach iPhone
   (web can't run on iOS Safari) and it *fixes* manual backup on iPhone (real
   sandboxed FS + Files app). We must **avoid choices that make it harder** —
   above all keep pack logic data-driven so guideline **2.5.2** (no downloaded
   executable/interpreted code) never bites; keep the app offline-functional (App
   Review 2.1); Tailscale over raw-LAN; no in-app IAP links. Standing costs
   accepted as future: a macOS build path + Apple program/review cadence.

### Design docs written (this repo)
- `AGENT/Docs/design/campaign_backup_content_addressed_format_2026-07-25.md`
- `AGENT/Docs/design/ios_native_target_feasibility_2026-07-25.md`
Both registered in the doc role-manifest ownership map.

## Commits claimed

- `0dac727a81a36b4fedf7be3b06b733208b8cda2b` — Design docs: content-addressed backup format + native-iOS post-v1 target

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` → wrote INDEX.md.
- `python3 AGENT/Docs/check_docs.py` → PASS (all 41 documentation checks green).
- pre-commit: GDScript format/lint PASS (238 files unchanged); docs-only, test
  suite skipped.

## Next

Next session: **economy / shop / forging / training-hall / prep-screen bundle**
(or a coherent subset). Anchor tracker rows in the container's `coordination/tasks.json`:
discussion `DISCUSS-CONVOY-SHOP-UX` (131), `DISCUSS-PREP-HUB-UX` (146),
`DISCUSS-PREP-ACTIVITIES-UX` (147, incl. Training Hall), `DISCUSS-FORGING-UX`
(148); implementation `B4-SHOP-ECONOMY` (212), `B7-FORGING` (214),
`B6-PREP-PROGRESSION` (227); underpinnings `B4-IEQ` (210) + `B4-CONVOY` (211);
economy slices `IMPL-ECONOMY-WALLET-CORE` (251) / `IMPL-ECONOMY-PLAYABLE-MIGRATION`
(252). Prior research/plan already done and completed: `RESEARCH-ECONOMY-OWNERSHIP`
(240), `PLAN-CAMPAIGN-DATA-OWNERSHIP` (244) — start from those. Suggested subset:
Prep-hub shell + one or two activity panels (Training Hall + Shop) rather than the
whole bundle at once.
