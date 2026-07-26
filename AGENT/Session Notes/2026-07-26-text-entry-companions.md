# Session Note - 2026-07-26 (text-entry companion packets)

Continues `2026-07-26-text-entry-research.md`. That session filed the TEXT-01..08
packet; this one answers two questions the owner raised against it and files the
answers as two companion packets on the same research branch
(`agent/from-integration/campaign-data-research`).

## What was done

### Companion 1 — naming, path entry, and sanitization

`AGENT/Docs/design/text_entry_naming_and_sanitization_2026-07-26.md`. Covers what
the player may *type*, where the first packet covered how they type it.

- **Naming comparators beyond the avatar.** FE Path of Radiance/Radiant Dawn is the
  only FE case of naming an *item* — forged weapons, 7 chars JP, raised to 12 in
  localisation; modern FE dropped it for auto-generated names, which is what
  EPUX-27 already ratified. Pokemon: 12 chars + an aggressive multilingual
  profanity filter. Minecraft: 35-char anvil rename that permits the `§`
  formatting sign, i.e. a markup-injection surface by design. **Diablo II is the
  key precedent** — the character name *is* the save file (`<name>.d2s`), and it
  responded by shrinking the alphabet to letters plus one optional `-`/`_`, not by
  sanitizing a rich name into a safe one.
- **Filtering appears only where text crosses to another player** (Awakening
  StreetPass, Pokemon trades). Independently confirms TEXT-07's "A for v1".
- **Godot 4.6.3 measured, not read from docs** (probe scripts in scratchpad):
  `is_valid_filename()` returns **true** for `CON`, `NUL.json`, `Ike.`, **`..`**,
  newlines, tabs, RTL overrides, zero-width chars, emoji and homoglyphs — it only
  rejects the documented `: / \ ? * " | % < >` plus leading/trailing spaces.
  Reserved names are open engine bug godotengine/godot#38198.
- **`user://CON.json` writes successfully on this Linux container and fails on
  Windows** — a live instance of the workspace's headless-Linux-reports-success
  hazard. Reserved-name rejection must be tested by asserting the validator's
  verdict, never by attempting the write.
- `FileAccess.open("/etc/hostname")` **opens** — a free-text path field is an
  arbitrary-file primitive. `user://` clamps at its own root, but traversal can
  still escape a subdirectory inside it (`user://saves/` + `../../x` →
  `user://x`).
- **`String.bbcode_escape()` does not exist in 4.6.3** — hard parse error, verified.
  Secondary sources claim otherwise. The manual `[` → `[lb]` swap is the only
  option on this engine.
- **One live gap recorded, predating any keyboard work.** `UnitDetailsScreen.gd:609`
  interpolates `w.display_name` into `"[b]%s[/b]"` in a `bbcode_enabled`
  RichTextLabel, and `CampaignTier2Validators` only `_require_string()`s that
  field (`:131`, `:191`). Campaign packs are imported from player-supplied ZIPs,
  so an imported pack can inject `[url=…]`/`[img]` markup. Not RCE — markup — but
  a phishing/defacement surface, and the Minecraft-anvil pattern exactly. See
  TEXT-10.
- **Existing code already correct and left alone:** `SaveManager`'s
  `_SLOT_ID_CHARS` allow-list (the Diablo II posture, with its reasoning written
  down) and `CampaignArchivePreflight._safe_archive_path()`. Noted that the slot
  allow-list still admits `CON`/`NUL` since they are pure ASCII — see TEXT-11.
- Proposes a destination-classified validation contract (display text / filename /
  path / cross-machine) and opens **TEXT-09..12**.

### Companion 2 — layouts, and a correction to TEXT-02

`AGENT/Docs/design/text_entry_layout_implementation_research_2026-07-26.md`.

- **Corrects the first packet's headline claim.** TEXT-02 rests on "daisywheel ~2
  actions/char vs up to ~12 for grid QWERTY", taken from DaisywheelJS's own
  comparison. Re-derived with a frequency-weighted action model
  (`scratchpad/actions.py`): grid QWERTY is **4.66** mean actions/char on a 4-way
  d-pad, **4.00** on 8-way, against the daisywheel's 2.00. The 12 is a fair worst
  case (13 with a number row); the mean is what the player experiences. **The
  advantage is ~2x, not ~6x.**
- **Measured throughput closes it further.** Wilson & Agrawala (MSR) report 6.75
  WPM; the same line of work reports 5.8 → 6.4 WPM moving single-stick to
  dual-stick QWERTY — ~10% for doubling the input hardware. Gamepad text entry
  clusters at 6-7 WPM regardless of scheme, because the cost is visual search and
  target acquisition, not button presses. **Familiarity is worth more than
  theoretical efficiency.**
- **Valve replaced its own Big Picture daisywheel with a QWERTY grid**, and no
  shipping platform defaults to a wheel. Users who had learned it did mourn it, so
  the efficiency claim is real — but platform holders optimise for first contact.
  (Community-sourced; fact well-attested, date approximate.)
- **T9 splits in two and neither is recommended.** Patents expired but **"T9" is a
  live Nuance trademark** — must not name a mode or class. Prediction needs a
  per-locale corpus (SCOWL is the permissive option; Aspell/Hunspell are commonly
  GPL). **The killer: T9 predicts dictionary words, and unit/weapon names are
  invented proper nouns**, so on a name field every entry degrades to multi-tap
  (3.41 actions/char, barely better than the grid's 4.00) while being far less
  familiar. Counter-evidence that the *choice* model has precedent: the **PS3
  shipped both** a full QWERTY and a phone-style multi-tap mini keyboard,
  switchable, with a predictive toggle.
- **A better daisywheel starting point than the first packet found.** A daisywheel
  is a radial menu plus a face-button layer; searching that way finds
  `jesuisse/godot-radial-menu-control` — **MIT, Godot 4, 106 stars**, with explicit
  `setup_gamepad(device, x_axis, y_axis)` and a deadzone. Changes TEXT-08's
  calculus for the wheel specifically.
- **Godot build trap recorded:** `GridContainer` injects its own focus handling
  onto children even with `focus_neighbor_*` cleared (godot#77729), and default
  focus navigation is spatial (godot#98445). Drive focus from an explicit
  `(row, col)` model.
- **Recommendation:** grid QWERTY first *as the default on the merits*, daisywheel
  second as opt-in, **do not build the keypad**; player picks via the override
  setting TEXT-05 already proposes (one more enum value, not a new system);
  architecture is **one layout registry, three registered presenters** per [EXT],
  mirroring the EPUX-20/EPUX-26 sections-plus-presenters resolution. Opens
  **TEXT-13..15**.

Neither packet changes a ratified decision or implements anything. TEXT-01..08
remain open and unanswered; TEXT-09..15 join them for the owner walk.

## Commits claimed

- `3ba5e8050cd5dea5d61b312e0bb12f56812dfb80` — docs: file two text-entry companion packets (naming/sanitization, layouts)

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated INDEX.md; both companions
  registered in `doc_role_manifest_2026-06-29.md` against
  `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26` (check 30 fails without this).
- `python3 AGENT/Docs/check_docs.py` — **PASS**, all 41 checks green.
- Pre-commit hook run on `3ba5e80`: unit suite 12 tests OK, scene-integrity PASS
  (22 scripts), session-claims PASS, evidence-matrices PASS, gdformat/gdlint PASS
  (238 files). Godot test suite skipped — docs-only change.
- Engine probes run against `godot --headless` on **4.6.3.stable.official.7d41c59c4**,
  the shipping target. Probe scripts are in the session scratchpad, not committed.

## Next

Owner walk of **TEXT-01..15**, in the EPUX style. Order matters: TEXT-06 (ratify a
minimise-text-entry rule) and TEXT-01 (the v1 capability) still gate the layout
questions; TEXT-13 should be taken knowing the 6x figure was wrong.

**TEXT-10 is separable and should probably not wait for the walk** — the BBCode gap
is live today through imported packs, is independent of whether a keyboard is ever
built, and is a small change (escape at render sites + Class A validation on pack
`display_name`s). Per DoD#2 its check lands in the same change.

Still not on the v1 critical path: every dependent feature (EPUX-09, EPUX-15,
EPUX-27) was already cut, so this unblocks future work, not current work.

Two things were deliberately left unverified and are recorded in both packets:
no study measures a daisywheel against a grid *on a controller* (the 2x is
modelled, the throughput difference is unmeasured in either direction), and no
Windows-host pass was possible for the reserved-name, `MAX_PATH`, or emoji-glyph
behaviour — all filesystem measurements here are Linux.
