# Content-Addressed Backup Format — design sketch (2026-07-25)

**Status:** design sketch, POST-V1. Not scheduled. Captured during the cloud
sync/backup research session so the shape is on record for when whole-library
backup/restore is actually built.

**v1 decision (owner, 2026-07-25):** the existing **manual export/import**
(`FileDialog` → `.json` save / `.zip` pack) is the **primary** backup + transfer
mechanism and is **likely sufficient for v1**. Everything below is the *next*
layer — a tidy on-disk backup format that avoids clutter — and the foundation a
future private server reuses. It is not required for v1.

---

## Problem this solves

Two things the naive "write a dated copy of everything on each backup" approach
gets wrong:

1. **Clutter / duplication.** A pack the player installed 5 months ago and hasn't
   touched — but doesn't want to delete — would get copied into every backup.
   Fifteen backups → fifteen identical copies of that pack sitting in the user's
   Drive, re-uploaded every time.
2. **Safe pruning.** The player wants to delete *old backups* without any risk of
   losing a pack that only old backups happened to reference.

The fix is the same one restic / borg / git / Time Machine use:
**content-addressed storage** — store each distinct blob exactly once, name it by
its hash, and make "a backup" a tiny manifest that *points at* blobs rather than
copying them.

## We are ~80% there already

The repo already emits the primitives this needs:

- **Saves already carry a content hash.** `SaveIntegrity.stamp()` embeds
  `payload_hash` = `sha256` of the canonical JSON projection
  (`scripts/save/SaveIntegrity.gd:11-14`, `:73`). Hash the *canonical form*, not
  raw file bytes, so formatting jitter never defeats dedup.
- **Pack export is already deterministic.** `CampaignPackExporter` admits a
  *sorted, validated* set ("never an unrestricted recursive copy of the source
  directory", `scripts/resources/CampaignPackExporter.gd`), so the same pack →
  the same `.zip` bytes → a **stable content hash**.
- **Packs already have identity.** `package_id` + `version`
  (`scripts/resources/CampaignPackRegistry.gd:25`) give a coarse dedup key even
  before hashing.

Determinism is the load-bearing property. Keep pack export byte-stable or the
hash-dedup silently degrades to "copy every time."

## The two-layer format

```
Backup/                         # whatever folder the user points at (Drive, USB, NAS…)
  content/                      # write-once, hash-named blobs — the actual bytes
    a1b2c3….zip                 #   pack "Foo v1.2"  → exists exactly once, ever
    9f8e7d….json                #   a save snapshot
    …
  snapshots/                    # tiny manifests: "this backup = these hashes"
    2026-07-25T0930.json
    2026-08-30T2210.json
  index.json                    # optional: refcounts / catalogue for fast GC + listing
```

A snapshot manifest is just:

```json
{
  "created_at": "2026-07-25T09:30:00Z",
  "schema": 1,
  "saves":  [ { "slot": "campaign_03", "hash": "9f8e7d…", "payload_hash": "…" } ],
  "packs":  [ { "id": "Foo", "version": "1.2", "hash": "a1b2c3…" },
              { "id": "Bar", "version": "0.4", "hash": "…" } ]
}
```

### Write path (backup)
1. For each pack to include: run `CampaignPackExporter.export_zip(...)`, hash the
   result. **If `content/<hash>` already exists, skip the write entirely.** The
   untouched 5-month-old pack hashes identically every time → copy #2 is never
   created.
2. For each save: `SaveIntegrity.stamp()` (already done by `export_slot`), hash
   the canonical payload, write to `content/<hash>` if absent.
3. Write one small `snapshots/<timestamp>.json` referencing those hashes.

### The anti-clutter win, concretely
`content/` is **write-once and hash-named**, so the Drive/Dropbox/Syncthing
client sees each blob *once* and never re-uploads it. Unchanged packs never
re-transfer. Fifteen "backups" are fifteen kilobyte-sized manifests all pointing
at the same one `content/a1b2c3….zip`. This directly answers the owner's
"fifteen copies of a pack" concern.

### Safe pruning / GC
A blob is owned by *no single* snapshot — it is shared. Deleting old snapshots
can never orphan a pack a newer snapshot still references. Garbage-collect a blob
only when **no** snapshot references it (refcount in `index.json`, or a
mark-sweep pass). Optional retention policy (keep last N + monthly) rides on top;
because content is deduped, retention is cheap.

### Restore
Read a chosen snapshot manifest → for each referenced hash, materialize the blob
back into `user://saves/<slot>.json` (via `import_portable_save`, which keeps the
existing tamper check) and installed-pack roots. Hash mismatch on read = corrupt
blob → surface, don't silently import.

## Saves vs packs — expected behaviour
- **Saves change every session** → they won't dedup much. That's fine: saves are
  small JSON. Keeping many historical save-snapshots *is* the backup feature.
- **Packs are the bulk and dedup beautifully** — they change rarely, so the
  content store holds one copy per distinct `(id, version, bytes)`.

## Platform notes
- **Native (Windows / Deck / iOS):** the target is a real folder; the two-layer
  layout drops straight in. Vendor sync clients (Drive/Dropbox/Syncthing) handle
  the upload; we never touch their API. See the third-party-as-a-folder decision.
- **Web:** there is **no** device folder and (today) **no browser download/upload
  bridge** wired (`export_slot` just does `_write_json_absolute`,
  `scripts/autoloads/SaveManager.gd:198`; no `JavaScriptBridge` file I/O in the
  project). A web build would need either a download/upload bridge (export → blob
  download, import → file picker) or the future server. The content-addressed
  scheme is unchanged; only the transport differs.

## Why this isn't throwaway — it feeds the private server
The future **private/self-hosted server** (owner decision: home-server or
private web-app hosting, *not* an owner-run service for everyone) reuses this
exact scheme: the client asks the server "which of these hashes do you already
have?" and uploads only the missing blobs. Same deterministic export, same
`content/` store, same manifests — the folder backend and the server backend are
two transports over one format. Building the content-addressed layer first makes
the server cheap later.

## Open questions (for when this is scheduled)
- Hash choice: reuse `sha256_text()` of canonical JSON for saves; for pack zips,
  hash the zip bytes vs. re-hash the canonical admitted set (the latter is
  archiver-independent — safer if the zip writer ever changes).
- `index.json` refcounts vs. stateless mark-sweep GC (simpler, no drift).
- Whether restore offers per-item selection (restore just this pack / just this
  save) — the manifest already makes that trivial.
- Encryption-at-rest for the user's Drive folder (probably out of scope; the user
  chose the destination).

## Related
- Tracker: `INVESTIGATE-CLOUD-SYNC-THIRD-PARTY-2026-07-25`,
  `BACKLOG-FULL-LIBRARY-BACKUP-2026-07-24`, "Pack-save Slice 3: portable save".
- iOS impacts on the pack side (2.5.2 downloadable-code): see
  `ios_native_target_feasibility_2026-07-25.md`.
