# Session Note - 2026-07-26 (Phase 0: BBCode injection hardening)

Phase 0 of the post-walk implementation order. This branch carries
`HARDEN-BBCODE-INJECTION-2026-07-26`; the two governance rows are on
`agent/from-integration/text-entry-governance` (see
`2026-07-26-phase0-text-entry-governance.md`).

## What was done

### The vulnerability

Campaign packs are imported from player-supplied ZIPs, and their `display_name`
values were interpolated **unescaped** into RichTextLabels with `bbcode_enabled`.
That is not a formatting bug. Measured on Godot 4.6.3:

- `[img]user://evil.tres[/img]` in a bbcode label **executed the resource's embedded
  script `_init()`** — `[img]` resolves through `ResourceLoader.load()`.
- A raw PNG under `user://` does **not** load (no `.import` sidecar), so legitimate
  images fail while malicious resources succeed. There was no legitimate `[img]` use
  with pack content to preserve.
- `[url]` is **inert** in this codebase: `_on_entry_clicked` parses `category:key`
  and only moves a selector. The earlier phishing concern is withdrawn.

### The fix

`scripts/shared/BBCode.gd` provides two helpers, because the two positions in markup
need genuinely different treatment:

- `escape()` — swaps `[` for `[lb]` for **body text**. Only the opening bracket needs
  it; an unmatched `]` is already literal.
- `escape_meta()` — **removes** both brackets for values inside a tag, e.g. the id in
  `[url=id]`. `[lb]` is not expanded there, and the dangerous character is `]`, which
  closes the tag early and hands the remainder to the parser. No escape sequence
  exists for that case.

`String.bbcode_escape()` does **not** exist in 4.6.3 (verified parse error) despite
being merged upstream, so the manual swap is the only option on this engine.

Applied to `UnitDetailsScreen` (class, stat, inventory, skill and wexp links, plus
the weapon more-info heading) and `AttackPreview` (unit names, weapon names, and the
side-panel full name).

### Two things that were easy to get wrong

- **Escape after fitting, not before.** `AttackPreview._fit_name_to_column` measures
  against the label font; escaping first would let `[lb]` count toward the column
  width and could truncate the escape sequence in half.
- **The needles must match.** `_section_label_for_entry` and `_refresh_highlight`
  locate an entry by searching the rendered text for its own `[url=...]` tag. Escaping
  the meta at the render site without applying the same `escape_meta` to those needles
  would have made entry selection silently stop finding its own rows. The full suite
  passing (`test_unit_details_screen` 32 passed) is what confirms this held.

Markup this code builds itself — the `[color=...]` value wrappers — is deliberately
**not** escaped. HUD is untouched on purpose: its RichTextLabels receive only
`MoreInfoContent` and `TileActions` copy, and every unit/terrain field it writes is a
plain `Label`.

### The other half of the chain, now pinned

Executing needs a `.tres` on disk, which `CampaignArchivePreflight` denies by
admitting only indexed JSON and `png/ogg/wav/ttf/otf`. **That allow-list was
load-bearing security with nothing in the code recording the fact.**
`test_campaign_archive_preflight` now asserts all four resource formats are refused
and that `APPROVED_MEDIA_EXTENSIONS` contains no resource or script format, so
widening it cannot silently reopen the chain.

## Commits claimed

- `d3c5cec3ea6017037fff9e80423e4f2172f203ed` — security: escape pack-authored text at every BBCode render site

## Gates

- `bash run_tests.sh` — **PASS: all suites green**, including
  `test_unit_details_screen` (32) and the new `test_bbcode_escape` (17).
- New `test_bbcode_escape.gd` covers both helpers, the legitimate names that must
  survive untouched, and the concrete measured `[img]` payload.
- `test_campaign_archive_preflight` — 14 passed, up from 9.
- Pre-commit on `d3c5cec`: gdformat/gdlint PASS (238 files), scene-integrity PASS,
  full Godot suite green.

## Next

`HARDEN-PACK-DISPLAYNAME-VALIDATION-2026-07-26` is the deliberately split-out third
deliverable — Class A content validation on pack `display_name` fields. It is
**defence in depth only**: the render-site escaping here closes the exploitable path.
It was split because `CampaignTier2Validators.gd` is already claimed by
`IMPL-ZERO-CONTENT-FAMILIES` (which claims all of `scripts/resources/`) and
`IMPL-RULE-PROFILES`, so it must follow them rather than race them.

**Not committed on purpose:** `.godot/global_script_class_cache.cfg` picks up the new
`BBCode` global class when the cache is warmed. It is a generated artifact that
`run_tests.sh` and the check-receipt worktree both regenerate, so leaving it out
keeps a machine-local artifact out of a security commit.

**Left unverified:** no Windows-host visual pass was possible for the escaped strings.
The escaping is covered by headless tests, but how an escaped name renders in the
real UI has not been seen.
