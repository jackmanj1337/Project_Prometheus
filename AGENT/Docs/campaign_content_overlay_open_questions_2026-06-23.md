# Campaign Content Overlay (branch I3) — Open Questions Register

**Started:** 2026-06-23
**Last verified:** 2026-06-23
**Status:** Register RESOLVED 2026-06-23 (`[ICO-1..6]`). **The owner reframed the model from "base +
overlay" to SELF-CONTAINED, everything-user-defined** — so this register *supersedes* the 2026-06-23a
overlay direction (see [ICO-1]) and collapses the `[DMR-4]` `_apply_overlay()` **merge** into a
**replace-load**. Planned design; not yet built.
**Reframed model (owner, 2026-06-23):** each campaign is a **self-contained** bundle of **user-defined
assets**; no runtime inheritance/overlay. Default content ships with the **builder** as a copy-from
palette and is copied to `user://` on first run. Two tiers only: campaign package (complete content +
art, in `user://`) → save (state by id, binds to a campaign id, resolves against **that campaign's own
set**). Art lives in the package, never the save.
**Pattern:** mirrors §1 ICD / §2 CST / DMR. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded, verified 2026-06-23)
- Content is held in **`Dictionary` keyed by `id`**: `DataManager._classes/_weapons/_items/_skills`.
  So **override-by-id = `dict[id] = res`** and **exclude = `dict.erase(id)`** — the data shape already
  supports the overlay; the work is the load path + merge rules + validation.
- Base load: `_load_directory(path, dict)` → `ResourceManifest.load_paths(path)` (an **exported
  manifest**, not a raw dir scan) → `register_loaded_resource`, which makes a **`DUPLICATE_ID` fail
  loud**. ⇒ the overlay's intentional same-id replace must take a path that **bypasses the base
  dup-id guard** (override is the feature, not an error).
- `[DMR-4]` (RESOLVED) gave us the seam: `_load_all(base, overlay := null)`,
  `select_campaign(campaign)`, and an `_apply_overlay()` **stub** this register fills.
- `WeaponData` / `ItemData` carry `id` + `display_name` but **no `icon`** field (items are text-only).
- `_validate_all()` (DMR-1) is the unified cross-reference validator — the overlay must re-run it over
  the **merged** set so excludes/overrides can't leave dangling id refs.

## 2. Open questions register

### [ICO-1] (a) Include model — what a campaign inherits  **[OPEN]**
- **A — Inherit ALL defaults, then add / override / exclude by id.** Campaign starts with the full
  default library; an `exclude` id-list drops what it doesn't want. Friendliest authoring (opt-out).
- **B — Opt-in whitelist.** Campaign declares exactly which default ids it carries; nothing inherited
  unless listed. Tightest control / smallest packs; heaviest authoring.
- **C — Hybrid (inherit-all default, per-campaign flag to switch to whitelist mode).**
- **Rec: A** — matches the direction; the dicts already hold all defaults post base-load, so exclude is
  `erase`. Dangling refs from an exclude are caught by the re-run `_validate_all()` (so a campaign that
  excludes a weapon still referenced by a unit fails loud at load, not silently).
- **Resolution:** **NEITHER — SELF-CONTAINED (owner, 2026-06-23).** Each campaign carries its
  **complete** content set; there is **no runtime inheritance/overlay**. `select_campaign(c)` loads c's
  full content (replace), not `defaults ∪ overlay`. The default content ships with the **builder** as a
  **copy-from palette** (and is itself the "default campaign"). **This reverses the 2026-06-23a "base +
  overlay" direction** to the independent-per-campaign fork. **Costs accepted by the owner:** content
  **duplication / bloat** across campaigns AND **no central patch propagation** (a fix to a default must
  be re-shipped into every campaign that copied it). **Benefit:** maximally portable, self-describing
  packs; trivial runtime (no merge engine, no version coupling).

### [ICO-2] (b) Override granularity — how a campaign modifies a default  **[OPEN]**
- **A — Whole-resource replace by id.** The overlay `.tres` for an id fully replaces the default. Dead
  simple (`dict[id] = res`), robust, no merge engine. Relabel/re-art = copy the default, change the
  field(s), ship the whole resource (the GUI editor does this copy for the author).
- **B — Field-level patch.** Overlay declares only changed fields (e.g. just `display_name`/`icon`);
  a merge applies them onto the default. Ergonomic for pure relabels by hand; needs a patch format +
  merge/precedence rules + per-field validation.
- **C — Both (whole-resource v1, field-patch later).**
- **Rec: A for v1** (C as the natural evolution). The headline use case (relabel a sword) is one field,
  but the **GUI editor is the intended authoring surface** (loads default → tweak → writes the full
  resource), so whole-resource replace costs the author nothing and keeps the engine trivial.
  Field-patch is the follow-on if hand-authoring ergonomics demand it.
- **Resolution:** **A (2026-06-23) — but trivial under self-contained.** Campaigns store **whole
  resources**; there is no runtime merge to have a granularity. The GUI editor copies a default,
  the author edits, the full resource is written into the campaign. (Field-level patch is moot — there
  is nothing to patch *against* at runtime; it would only ever be a builder-internal authoring nicety.)

### [ICO-3] (c) ID namespacing + override intent  **[OPEN]**
Shared namespace is required for override-by-id to work (same id = the thing you're replacing). The
real sub-question is how much **intent** the author declares, so an *accidental* override (meant to add
new, reused an existing id) is caught.
- **A — Shared namespace, implicit intent.** Overlay entry whose id exists in base = override; new id
  = add; `exclude` list = remove. No add/override tagging. Simplest; an accidental id-reuse silently
  overrides (the load log lists what got overridden, but it's not an error).
- **B — Shared namespace, explicit intent.** Overlay manifest tags each entry `add` / `override` /
  `exclude`; a mismatch (override an id that doesn't exist in base; add an id that already exists) is a
  **load error**. Safer, more structure to author/validate; the GUI editor sets the tag for free.
- **Rec: B** — slightly more structure, but it turns the one genuinely dangerous mistake (silent
  accidental override) into a loud validation error, and the GUI editor populates the tag with zero
  author effort. Within-overlay duplicate ids are an error in both options.
- **Resolution:** **B's tag retained as AUTHORING-TIME PROVENANCE only (2026-06-23) — its runtime
  validation role is removed by self-contained (ICO-1).** There is no runtime base to override, so the
  load-time "override an id absent from base" error no longer exists. The builder keeps a per-resource
  **`forked_from`** provenance note ("copied from default `iron_sword`") for editor UX + a future
  "resync from new defaults" tool — informational, not a load gate. **Within-a-campaign duplicate ids
  remain a hard error** (the existing `register_loaded_resource` `DUPLICATE_ID` guard still applies
  per-campaign). Owner accepted this downgrade when confirming self-contained.

### [ICO-4] (d) Default-content versioning  **[OPEN]**
A pack overlays a specific snapshot of the defaults; a later defaults change could silently shift a
pack's meaning.
- **A — Pack stamps `default_content_version` (int, sibling of `format_version`); on load, a mismatch
  is a warn-and-continue** (consistent with I4's tamper / I2's version stance). No migration pre-1.0.
- **B — No stamp; rely on `format_version` only.** Cheapest; loses defaults-drift detection.
- **C — Hard-block on mismatch.** Safest, but contradicts the homebrew warn-and-continue posture.
- **Rec: A** — cheap insurance that mirrors the save's `format_version` + warn-and-continue (I4); the
  author/player is told "this pack was built against an older default set" without being locked out.
- **Resolution:** **PROVENANCE STAMP ONLY (2026-06-23).** A self-contained pack is not coupled to a
  live default set, so the runtime version **compare is dropped**. Keep only an **informational
  `builder_content_version`** recording which starter palette the campaign forked — no load gate; it
  feeds a future "resync from updated defaults" tool. (Save `format_version` still governs save-schema
  compat per I5.)

### [ICO-5] (e) Pack location (`res://` vs `user://`) + art loading  **[OPEN]**
Shipped campaigns live in `res://` (in the export + manifest); user/GUI-authored + imported packs live
in `user://` (NOT in the manifest). **Art wrinkle (load-bearing):** Godot's `.import` pipeline runs at
edit time over `res://` only — a `user://` PNG can't be `load()`-ed as an imported `Texture2D`; it must
be read as a raw `Image` (`Image.load_from_file`) → `ImageTexture`.
- **A — Support both; res:// via the manifest (as today), user:// via directory enumeration + runtime
  load; user:// art loads as raw Image→ImageTexture (not the .import pipeline).** Full homebrew path.
  MVP may land res:// shipped campaigns first and stand up the user:// import path as the seam.
- **B — res:// shipped campaigns only for MVP; defer user:// authoring/import entirely.** Smallest now;
  but the homebrew/GUI-editor goal (the whole point of I3) is deferred.
- **Rec: A** — design for both now (it's the branch's reason for existing), but it's fine to **build
  res:// first** and land the user:// enumeration + raw-image art loader as the immediately-following
  slice. Locking the art-as-String-path decision (ICO-6) is what keeps user:// art possible.
- **Resolution:** **EVERYTHING USER-DEFINED — COPY TO `user://` ON FIRST RUN (owner, 2026-06-23).**
  All content (incl. the base game's) is a **user-defined asset**. On first launch, the shipped default
  content is **copied from `res://` into `user://`** (as the "default campaign"), and from then on the
  uniform loader **enumerates `user://` campaign dirs** — one load path for shipped and authored
  campaigns alike. **All content art is raw-loaded** (`Image.load_from_file` → `ImageTexture`); the
  `res://` `.import` pipeline + `ResourceManifest` become seed-only/legacy. **New build scope this
  creates:** (1) a first-run **seed-copy** step (res:// → user://); (2) a **reset-to-default / repair**
  path (re-copy a campaign or the defaults if user:// is deleted/corrupted); (3) uniform `user://`
  enumeration replacing manifest loading. Ties the art-pipeline memory (raw-load = no engine
  compression/mipmaps; fine for the pixel-art target, note it).

### [ICO-6] (f) Item `icon` field — net-new schema  **[OPEN]**
No `icon` on `WeaponData`/`ItemData` today. Adding it makes per-campaign art free via the overlay. The
type choice is load-bearing because of the ICO-5 art wrinkle.
- **A — `@export var icon: String = ""` (a path/id), resolved through a loader that branches res://
  (`load`) vs user:// (raw `Image`).** Empty default = text-only stays valid. Works for user:// packs.
- **B — `@export var icon: Texture2D`.** Cleanest in the editor for res:// art, but **cannot reference
  user:// runtime art** (not imported) → breaks the homebrew art path.
- **Scope sub-question:** land the **field + loader seam now** (so the overlay can carry art + per-
  campaign relabel-with-art works) and **defer the actual UI icon rendering** (items are text-only in
  the UI today) to when art exists / a polish pass? **Rec: yes** — reserve the schema + resolver now,
  render later (mirrors how other forward fields were reserved).
- **Rec: A + field-and-seam-now / render-later.** String path + a `resolve_icon(path)` helper keeps
  user:// art possible; a `Texture2D` export would foreclose it.
- **Resolution:** **A — String path + raw-`Image` resolver; field + seam now, render later (2026-06-23).
  Reinforced by ICO-5** (everything user-defined ⇒ all art raw-loaded, so a `Texture2D` `@export` is
  ruled out — it can't reference `user://` runtime art). Add `@export var icon: String = ""` to
  **`WeaponData` AND `ItemData`** (empty default = text-only stays valid) + a shared `resolve_icon(path)`
  helper (`user://` raw-Image; tolerant of empty/missing). **In-UI icon rendering is deferred** (items
  are text-only in the UI today) — reserve the schema + resolver now, render when art exists.

## 3. Derived load contract — REPLACE-LOAD (supersedes the [DMR-4] `_apply_overlay()` merge)
Self-contained (ICO-1) collapses the merge: `select_campaign()` loads a campaign's **complete** content
set, **replacing** the dicts — there is no `defaults ∪ overlay`. The `[DMR-4]` `_apply_overlay()` *merge*
stub is **retired**; the seam it stood up (`_load_all(source)`, `select_campaign()`) stays.
```
# first run only:
seed_user_content():                 # ICO-5: copy res:// defaults -> user:// "default campaign"

select_campaign(campaign):           # campaign.dir is a user:// path (ICO-5)
    _clear_content()                 # drop previous campaign's dicts
    _load_all(campaign.dir)          # enumerate user:// dir; whole resources (ICO-2)
    _report(_validate_all())         # DMR-1 channel, over THIS campaign's set
    # builder_content_version (ICO-4) read for provenance only — no gate
    # icons resolved lazily via resolve_icon() (ICO-6); art raw-loaded (ICO-5)
```
**Net:** runtime is *simpler* than the overlay design — a clear + per-campaign load + the existing
validation, no merge / intent-check / version-gate. The real new engine work moves to **ICO-5**: the
first-run seed-copy, `user://` enumeration replacing manifest loading, raw-image art loading, and a
reset/repair path.

## 4. Notes
- **DoD#1 (when built):** GDD content/data chapter (GDD_03/04) gains the **self-contained per-campaign
  content model** + the `icon` field; GDD_10 status flip. **DoD#2:** validator guards owed by this
  branch shift with the model — (1) per-campaign **duplicate-id** guard (existing `DUPLICATE_ID`, now
  scoped per campaign), (2) **`icon` path-resolves-or-empty** validator (ICO-6), (3) `_validate_all()`
  runs over each loaded campaign's set. The dropped overlay-era guards (namespace-collision/intent-
  mismatch, `default_content_version` compare) are **no longer owed** (ICO-3/ICO-4 reframed).
- **Sequencing:** design now (not gated by Package A); the build rides §2 (campaign-select wires
  `select_campaign()`). **The first-run seed-copy + `user://` enumeration + reset/repair path (ICO-5)
  are the heaviest new build work** and want their own slice.
- **Deferred:** in-UI icon rendering (ICO-6), the "resync from updated defaults" tool (uses
  `builder_content_version` + `forked_from`), the full GUI editor.
- **Ripples recorded elsewhere (this register reversed the 2026-06-23a direction):** project memory
  `project_campaign_content_model.md`, `planning_backlog_2026-06-20.md` §2b branch I3, the framing doc
  `campaign_save_expectations_and_foundations_2026-06-23.md` (core insight + L3 + index), and the DMR
  register's `[DMR-4]` note (merge → replace-load) all updated 2026-06-23.

---

# Resolution Log
(newest first)

- **2026-06-23 — Register RESOLVED (`[ICO-1..6]`); owner REFRAMED the model to SELF-CONTAINED.**
  [ICO-1] **self-contained** (neither overlay option — each campaign carries complete content; defaults
  = builder copy-from palette; **reverses 2026-06-23a**; accepts duplication + no central patch
  propagation). [ICO-2] **A** whole-resource (trivial — no merge). [ICO-3] tags kept as **authoring-time
  provenance `forked_from`** only (runtime override-validation role removed by self-contained). [ICO-4]
  **provenance stamp only** (`builder_content_version`, informational, no gate). [ICO-5] **everything
  user-defined — copy res:// → `user://` on first run**, uniform `user://` enumeration, all art
  raw-loaded; new scope = seed-copy + reset/repair. [ICO-6] **A** `icon: String` on WeaponData+ItemData
  + `resolve_icon()` raw-Image; field+seam now, render later. **Consequence:** `[DMR-4]`'s
  `_apply_overlay()` merge → **replace-load** (§3); runtime simpler, build weight moves to ICO-5.
- **2026-06-23 — Register drafted** (a–e + icon + apply-contract) grounded in DataManager id-keyed
  dicts, `_load_directory`/`ResourceManifest`, the `DUPLICATE_ID` guard, and the missing `icon` field.
