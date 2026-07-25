# Session Note - 2026-07-25 (campaign library Branch K)

> Descriptive filename (not the plain `YYYY-MM-DDx` form) intentionally: this design/integration-line
> note shares `AGENT/Session Notes/` with the parallel release line, which already used
> `2026-07-25` / `-a` / `-b` the same day. A slug avoids a same-path collision at merge to `main`.

## What was done

- Continued the owner design discussion over the campaign-library owner-questions packet.
  Opened **Branch K — Author & advanced-user surfaces** and resolved its first item, the
  **editor distribution / integration** question (Branch B's deferred "Copy / Edit + GUI
  campaign-editor integration", and the CL-ADV-04 player/author boundary). Recorded in
  `AGENT/Docs/design/campaign_library_ux_decisions_2026-07-24.md`.
- Research before deciding (prior-art pass): every reference toolset ships the editor as a
  **separate desktop app from the game the player runs** — FEBuilderGBA (standalone Windows ROM
  editor), Lex Talionis / LT-maker (PyQt editor built on top of but separate from the engine),
  Tactile (separate editor generating a C# game), and even SRPG Studio (RPG-Maker-style, yet still
  **exports a standalone game** the player runs without the Studio). The universal invariant is *the
  editor never ships into the player's hands*.
- Owner decision — **revises** Branch B's "separable program" default:
  - **Full integration in v1, gated at RUNTIME not build time.** The editor ships in **all** presets
    (Steam / Deck / web). "Can I edit here?" is a runtime property, not a platform: a **Steam Deck in
    desktop mode** and a **web build on an iPad + Bluetooth keyboard/mouse** are both good editing
    environments a build-time strip would wrongly deny.
  - **Non-blocking editor-entry warning, fired on OR** (owner call): window **below 1920×1080** *or*
    input mode not keyboard+mouse. Each axis degrades editing independently, so OR not AND.
    Dismissible "open anyway" (house non-blocking-warning pattern). **Detect kbm present / recently
    used, never "touch absent"** — an iPad reports touch *and* kbm, so a touch test would mis-warn a
    good iPad+keyboard setup.
  - **Settings declutter row (data-driven `SettingsScreen` schema):** a player may hide the editor
    entry by default and/or auto-hide it below a resolution / on non-kbm input. Default visible
    everywhere; hides the *entry point* only, reversible — never strips the capability.
  - **Superset/subset export presets kept as an escape hatch** (the two-preset model Godot itself and
    SRPG Studio effectively ship) if web download size proves the integration cost too high; recorded
    in the Deferred list, demand/measurement-gated.
  - Reuses Branch I infra: `InputModeManager` (input mode) + window/`MenuScale` (resolution); shared
    resource classes (`PackManifest` / `CampaignTier2Validators` / `CampaignPackRegistry`) mean full
    integration is one project, no forked codebase.
- Then **closed the remaining Branch K items**, resolving the whole packet (A–K):
  - **CL-ADV-01** — unpacked (loose-folder) dev packs load **only under an explicit developer mode**,
    marked as a dev source, never active in a normal player session (net-new; registry today only
    scans installed `user://campaign_packs/<id>/<version>/`).
  - **CL-ADV-02** — player runtime shows only the plain **summary + exportable report** (the
    CL-SAFETY-01 "valid pack" signal); the **deep author validator** is an editor surface (now the
    integrated editor's validation view, no separate download).
  - **CL-ADV-03** — **block** id+version collisions (partly structural at `CampaignPackRegistry.gd:69`),
    **badge** dev / locally-modified, **no "unsigned" language** (nothing signs packs). Owner add: a
    **non-blocking editor note nudging authors to bump the version** between edits when copies may
    coexist (versioning is manual, no migration engine — Branch D).
  - **Editor UX deferred** to a dedicated design pass (own research doc + questions packet); Branch K
    settled only distribution + the author/player boundary.
- Spun out two **cloud-save backup / cross-device sync investigations** (owner ask): third-party
  storage services (Google Drive / iCloud / OneDrive / GitHub) and an optional **first-party server +
  DB** (+ possible campaign-pack distribution). Noted the key constraints (Steam Cloud is the ~free
  baseline for Steam; web is IndexedDB-bound; first-party distribution = moderation + licensing/legal
  exposure). Recorded in the decisions doc's deferred list; tracker rows added in the container repo.
- No runtime, scene, save-schema, or release-line behaviour changed — design and planning only.

## Commits claimed

- `2fe33938cf705ed81161ae881b3d6bfb6c84738e` — Resolve campaign-library Branch K editor distribution: full integration + runtime OR-gated warning
- `f749ef43636c1d98f2fb079ee929e3cf4d04fc25` — Close campaign-library Branch K: CL-ADV-01/02/03 resolved + editor version-bump note + deferrals

## Gates

- Pre-commit hook on the decision commit: documentation checks, RNG-usage guard, analyzer tests,
  scene-integrity, session-claims, evidence-matrices, gdscript style all PASS; docs-only change so the
  Godot suite was skipped by the hook.
- Pre-push full suite: all GUT suites green (check receipt
  `audit/check-receipts/Project_Prometheus-full.json`, tree `c907f931…`, exit 0).

## Next

**All owner-question branches (A–K) are closed.** Next is **implementation planning** for the accepted
campaign-library scope (the `PLAN-CAMPAIGN-DATA-OWNERSHIP` line), turning accepted decisions into
implementation tracker rows. Three new threads were spun out and now have container tracker rows: the
**dedicated editor-design pass** (editor UX, not just distribution), and two **investigations** —
third-party cloud sync/backup services (Google Drive / iCloud / OneDrive / GitHub) and an optional
**first-party server + DB** (cloud-save backup + possible campaign-pack distribution). All three are
post-v1 / research-gated; weigh both sync investigations against the Steam Cloud baseline first.
