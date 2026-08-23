---
Role: dated
Type: plan
Status: Planned
Last verified: 2026-07-15
---

# B6 Campaign Archive Pipeline - Next-Session Handoff

## Resume point

Commit `978c470` provides the two inert inputs this work must consume:

- `PackManifest` validates package identity and format compatibility.
- `Tier2Catalogue` reads the authored Tier-2 index and dispatches registered,
  non-mutating content-family validators.

`AssetResolver` already owns pack-scoped Tier-1 media loading and optional-media
repair reports. None of these components installs, activates, or selects content.

## Next objective

Build archive export/import as a transactional storage pipeline. A successful
import places one fully validated pack directory under the campaign-pack storage
root. It must not replace `DataManager` catalogues, register selector entries,
start a campaign, or mutate save state.

## Implementation sequence

### 1. Concrete Tier-2 validation set

Register validators for the content kinds required by the first fixture pack,
reusing existing resource parsers where their JSON contract already exists.
Validate the entire pack before installation, including cross-document ids and
required Tier-1 asset references. Optional media produces `AssetResolver` repair
rows; missing required structured content rejects the pack.

Keep scope narrow: begin with the smallest self-contained campaign fixture
(manifest, campaign graph, map registry/map data, roster/content dependencies),
then add kinds only when the fixture proves they are required. Do not invent a
second runtime schema beside existing `DataManager` resource contracts.

### 2. Pure archive preflight

Add a non-autoload package service whose inspect operation returns a structured
result/report without writing installed state. Preflight must enforce:

- one package root containing `manifest.json` and the canonical Tier-2 index;
- normalized relative paths only: no absolute paths, `..`, drive prefixes,
  backslash ambiguity, NULs, or entries outside the package root;
- no duplicate normalized paths, case-fold collisions, symlinks, or special
  files;
- bounded entry count and bounded compressed/uncompressed sizes;
- manifest id matches the destination directory identity;
- every catalogue and required asset file is present, while unindexed files are
  either approved Tier-1 media or rejected;
- a save file or save-shaped payload is never accepted as pack content.

Do not trust archive extensions. Inspect the actual format and return actionable
errors without extracting into the final destination.

### 3. Staged transactional install

Extract to a unique staging directory owned by the package service, validate the
staged tree again through `PackManifest`, `Tier2Catalogue`, concrete validators,
and `AssetResolver`, then atomically promote it to the installed-pack directory.
On any failure, remove staging and leave an existing installed version untouched.

Replacement policy for an already-installed `{id, version}` is not yet decided;
default to rejecting it. Do not silently overwrite or merge pack directories.

### 4. Deterministic export

Export only files admitted by the validated manifest/catalogue and approved
Tier-1 directories. Use normalized forward-slash paths and deterministic lexical
archive order. Exclude saves, staging files, editor imports/cache, and unrelated
user files. Re-preflight the produced artifact as the export exit check.

Art-free single-JSON packaging remains optional. Land ZIP round-trip first; do
not complicate the storage transaction to support both formats in one commit.

## Commit slices

1. Concrete validator registry + complete fixture and cross-reference tests.
2. Archive inspection/security limits with malicious-entry fixtures.
3. Staged atomic install and rollback/replacement tests.
4. Deterministic export, save exclusion, and round-trip test.

Each slice must leave all existing direct boot/runtime catalogue behavior
unchanged and the full suite green.

## Required tests

- Valid fixture preflights without disk mutation.
- Traversal, absolute path, duplicate path, case collision, symlink/special file,
  malformed JSON, incompatible manifest, unknown kind, and size-limit cases fail.
- Invalid content never creates or changes an installed pack.
- Failure during replacement preserves the prior installed bytes.
- Missing optional media installs with a structured repair report; missing
  required Tier-2 content does not install.
- Export/import round-trip preserves every admitted file in deterministic order.
- Exported archives contain no campaign slots, suspend data, or other saves.
- Import does not call `DataManager.select_campaign_source`, alter the campaign
  selector, start a campaign, or write a save.

## Explicitly deferred

- installed-pack discovery and summary caching;
- campaign selector UI and `[CST-6]` auto-wrap behavior;
- runtime source activation through `DataManager`;
- selected-pack persistence and last-imported pointers;
- compatibility predicates requiring the unfinished `B3-REQ` system;
- status-record carry-forward;
- signatures, remote downloads, marketplace behavior, and automatic updates.

## Stop conditions

Stop and request an owner decision if implementation requires overwriting an
installed pack, choosing a global size budget with player-facing consequences,
or defining compatibility beyond the already-ratified format version. Do not
solve those questions by attaching runtime selection to installation.

## Definition of done

The archive pipeline is done when a hostile artifact cannot escape staging, a
valid artifact round-trips deterministically, installation is rollback-safe, and
the resulting pack remains inert on disk. Update `GDD_01`, `GDD_10`, the control
plane, and automated documentation enforcement if this work ratifies new
mechanical path/file rules.
