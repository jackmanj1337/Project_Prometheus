---
Role: dated
Type: design
Status: Draft - owner review
Last verified: 2026-07-26
Track IDs: RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26
---

# Naming, Path Entry, and Input Sanitization — Companion to the Text Entry Packet

Companion to `text_entry_strategy_research_and_questions_2026-07-26.md`. That packet
answered *how the player types*. This one answers *what they are allowed to type, and what
we do with it* — naming comparators beyond the avatar, Godot's measured limits, and the
sanitization rules for text that becomes a filename or a rendered label.

Every Godot claim below was **measured on Godot 4.6.3 (`4.6.3.stable.official.7d41c59c4`)**,
the engine this project targets, not read from documentation. Where measurement and
documentation disagree, the measurement is recorded and flagged.

## 1. What the filed packet already settled

- **The platform will not help.** Godot's virtual keyboard is Android/iOS/Web only; on
  Windows and Steam Deck (desktop Linux) `LineEdit.virtual_keyboard_enabled` — default
  `true` — is inert.
- **Deck Verified requires an automatic on-screen keyboard**, and Valve's own OSK satisfies
  it through GodotSteam. Cheapest compliant answer for the Deck is Valve's, not ours.
- **Fire Emblem's lesson is scarcity, not layout** — its entire free-text surface is a short
  avatar name.
- **A daisywheel is ~2 input actions per character** against up to ~12 for the grid QWERTY
  every off-the-shelf Godot addon implements.
- **No surveyed Godot keyboard addon is a safe dependency** (wrong engine version, or
  AGPL-with-bespoke-clause, or 11 commits and no releases).
- Recommendation was three deliverables in order: hold the line on minimising text entry,
  adopt the Steam OSK when Steam is scheduled, then build our own daisywheel-first keyboard
  with a data-driven JSON layout registry.

Nothing below changes any of that. It adds the layer underneath: the **validation contract**.

## 2. Comparator survey — how shipped games let players name things

The filed packet covered avatar naming. This extends it to **units and weapons**, which is
what [EPUX-27] (forge item alias) actually asks for.

| Game | What can be named | Limit | Charset / filtering | Does the name touch the filesystem? |
|---|---|---|---|---|
| **FE: Path of Radiance / Radiant Dawn** | **Forged weapons** — the one FE case of naming an *item* | **7 chars in JP, raised to 12 in localisation** | Console soft keyboard; fixed charset | No |
| **FE: Awakening** | Avatar | ~8 practical (12 absolute, variable-width font) | **Word-filtered**, because StreetPass transmits it | No |
| **FE: Fates / Three Houses / Engage** | Avatar only | 8 chars | System keyboard | No |
| **FE (modern forging)** | Nothing — names are **auto-generated** (`Iron Sword+2`) | n/a | n/a | No |
| **Pokémon (through Scarlet/Violet)** | Unit nickname | **12 chars** | **Aggressive multilingual profanity filter**; rejects with "You can't enter that name." Known false positives across languages (*Pine*, *Lullaby*) | No |
| **Minecraft** | Item rename at an anvil | **35 chars** | Bedrock permits the `§` formatting sign in anvils — i.e. **the rename field is a markup-injection surface by design** | No |
| **Diablo II** | Character name | **2–15 chars** | Letters only; no digits, no spaces; one optional `-`/`_`, not leading/trailing; stored as null-terminated **8-bit ASCII** | **Yes — the name *is* the save file: `<name>.d2s`** |

Four conclusions the comparators agree on:

1. **Naming a weapon is rare and short.** The only FE precedent is 7–12 characters, and
   modern FE removed it in favour of generated names — which is exactly what EPUX-27
   already ratified for v1. The player alias is the *optional* layer, and 12 characters is
   the well-precedented cap.
2. **Filtering appears exactly where text crosses to another player** — Awakening/StreetPass,
   Pokémon/trades. Neither filters offline-only text. This is the same boundary [TEXT-07]
   draws, and it independently confirms the packet's "A for v1, B when sharing is real".
3. **The one game that made a name into a filename responded by shrinking the alphabet to
   near-nothing.** Diablo II did not sanitize a rich name into a safe one; it refused to
   accept anything that was not already safe. That is the allow-list posture
   `SaveManager._SLOT_ID_CHARS` already takes in this codebase, and it is the right one.
4. **A rename field with markup in scope becomes a markup-injection surface.** Minecraft is
   the cautionary case, and §4.3 below shows we have the same exposure today.

## 3. Godot-specific limitations, measured on 4.6.3

### 3.1 There is no character filter on `LineEdit`

Godot has **no built-in charset restriction** on `LineEdit`/`TextEdit`. There are open
proposals ([#11646](https://github.com/godotengine/godot-proposals/issues/11646) for
`restricted_characters`, [#7609](https://github.com/godotengine/godot-proposals/issues/7609)
for inspector toggles) and third-party addons, but nothing shipped. `max_length` is the only
native constraint.

**Consequence:** filtering must be done in a `text_changed` handler that rewrites `text` and
restores `caret_column` by hand — the caret jumps to the end otherwise. This belongs in one
reusable `ValidatedLineEdit`, not copy-pasted per screen.

### 3.2 `is_valid_filename()` is far weaker than its name suggests

Measured — each row is real 4.6.3 output:

| Input | `is_valid_filename()` | `validate_filename()` |
|---|---|---|
| `Ike` | `true` | `Ike` |
| `CON` | **`true`** | `CON` |
| `NUL.json` | **`true`** | `NUL.json` |
| `Ike.` (trailing dot) | **`true`** | `Ike.` |
| `..` | **`true`** | `..` |
| `Ike\nrm -rf` | **`true`** | `Ike\nrm -rf` |
| `Ike\tx` | **`true`** | `Ike\tx` |
| `Ike\u202Edg.txt` (RTL override) | **`true`** | unchanged |
| `I\u200Bke` (zero-width space) | **`true`** | unchanged |
| `Ike😀` | **`true`** | unchanged |
| `e` + 6 combining acutes | **`true`** | unchanged |
| `Іkе` (Cyrillic homoglyphs) | **`true`** | unchanged |
| `Ike ` (trailing space) | `false` | `Ike` |
| `../../etc/passwd` | `false` | `.._.._etc_passwd` |
| `100%save` | `false` | `100_save` |
| `%s %d` | `false` | `_s _d` |

It rejects only the documented set `: / \ ? * " | % < >` plus leading/trailing spaces. It
does **not** reject control characters, NUL, bidi overrides, zero-width characters,
Windows-reserved device names, trailing dots, or `..`.

The reserved-name gap is a **known open engine bug**:
[godotengine/godot#38198](https://github.com/godotengine/godot/issues/38198), confirmed,
`platform:windows`, milestone 4.x, still open.

**`"..".is_valid_filename() == true` is the sharpest edge here.** A validator that trusts
`is_valid_filename` and then joins the result onto a directory has a traversal.

### 3.3 The Linux container will not reproduce the Windows failures

Measured on this container: `FileAccess.open("user://CON.json", WRITE)` **succeeds**, err 0,
and the file exists afterwards. On Windows that name is a reserved device and the write
fails. Same for trailing dots and spaces, which Windows silently strips.

This is a live instance of the workspace's standing hazard — headless Linux CI reports
success for something that fails on the only platform we ship. **Reserved-name rejection
must be tested by asserting the validator's verdict, never by attempting the write.**

Also measured: a 300-character filename fails on Linux (err 12) at `NAME_MAX`; Windows
additionally caps the *whole path* at 260 by default. A 64-char cap (already
`SaveManager`'s) is comfortably inside both.

### 3.4 Path resolution — what Godot actually accepts

| Call | Result |
|---|---|
| `FileAccess.open("/etc/hostname", READ)` | **opens successfully** |
| `FileAccess.open("/etc/../etc/hostname", READ)` | **opens successfully** |
| `FileAccess.open("user://../../../../etc/hostname", READ)` | does not escape `user://` |
| `"user://saves/../../pwned.json".simplify_path()` | `user://pwned.json` |
| `"C:\\Windows\\x".is_absolute_path()` | `true` |
| `"\\\\srv\\share".is_absolute_path()` | `true` (UNC — reaches the network on Windows) |

Two things follow:

- **`user://` is clamped at its own root.** Traversal cannot escape the sandbox, but it
  *can* escape a subdirectory inside it — `user://saves/` + `../../pwned` lands in
  `user://pwned.json`. Confining a write to `user://saves/` requires our own prefix check
  after `simplify_path()`, not faith in the scheme.
- **A free-text path field is an arbitrary-file primitive.** Godot resolves bare OS
  absolute paths with no sandbox. That is correct engine behaviour, and it is the reason
  §5 recommends never accepting a typed path at all.

### 3.5 `String.bbcode_escape()` does not exist in 4.6.3

Godot PR [#78310](https://github.com/godotengine/godot/pull/78310) adds
`String.bbcode_escape()` and `String.strip_bbcode()`, and secondary sources describe it as
the recommended way to prevent BBCode injection. **It is not in 4.6.3** — both calls are a
hard parse error on this engine, verified.

The only in-engine option today is the manual swap:

```gdscript
text.replace("[", "[lb]")  # "]" needs no escaping; an unopened "]" is literal
```

### 3.6 Emoji will not render, before any security argument is made

Godot needs a font with actual emoji coverage (CBDT/CBLC or SVG) plus a configured fallback
chain; flag sequences are
[known broken](https://github.com/godotengine/godot/issues/91111) even with Noto Color
Emoji. **This project configures no custom or fallback font at all** — `project.godot` has
no font override and `assets/` contains no `.ttf`/`.otf` — so it renders with the built-in
default, which has no emoji coverage.

So an emoji in a unit name renders as a missing-glyph box and corrupts the width metrics the
Menu Scale work depends on. *Per project rule, the exact visual result needs a Windows-host
pass; the container cannot validate rendering.*

### 3.7 The engine's real code-execution vector is resource loading, not text

Worth stating explicitly because it is the risk people expect text entry to carry, and it
does not:

- `JSON.parse()` is **safe** — it produces only dictionaries, arrays, and primitives.
  Measured: a bidi override and an embedded NUL both survive a `JSON.stringify` →
  `parse_string` round trip intact and inert. There is no injection through JSON *values*;
  the danger is entirely in what a consumer later does with the string.
- `ResourceLoader.load()` on `.tres`/`.res`/`.tscn`/`.scn` **is** arbitrary code execution:
  those formats can carry an embedded script whose `_init()` runs on load, which can call
  `OS.execute()`. This is documented engine behaviour, not a bug — see
  [godot-proposals#10968](https://github.com/godotengine/godot-proposals/issues/10968) and
  [godot#98168](https://github.com/godotengine/godot/pull/98168).
- `FileAccess.get_var(allow_objects = true)`, `bytes_to_var_with_objects()`, and
  `str_to_var()` on untrusted bytes are the same class of hazard.

**This is already handled correctly.** `CampaignArchivePreflight` parses pack content as
JSON only and rejects any file that is neither an indexed JSON document nor approved Tier-1
media (`png`, `ogg`, `wav`, `ttf`, `otf`). No `.tres` path exists for imported content. The
rule to preserve: **imported packs are data, never resources** — and if anyone ever proposes
`ResourceLoader.load()` on pack content, that is the change that must be refused.

## 4. What this codebase does today

### 4.1 Save slot ids — already correct

`SaveManager` (`scripts/autoloads/SaveManager.gd:60`) allow-lists
`[A-Za-z0-9_-]`, caps at 64, and `get_slot_path()` returns `""` for anything invalid, with
the reasoning written down: *"no id may resolve to a path outside the save dir ('..' and '/'
are simply not in the alphabet)."*

That is the Diablo II posture and it is right. Two gaps against §3.2:

- **`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9` all pass this allow-list** —
  they are pure ASCII letters and digits. `CON.json` still fails to open on Windows. The
  alphabet is safe; the *reserved-name* case is a separate check that is missing.
- A single `-` id, or an id of all `-`, passes. Harmless, but a leading-alphanumeric rule
  costs one line.

### 4.2 Archive paths — already correct, and worth copying

`CampaignArchivePreflight._safe_archive_path()` (`:215`) rejects empty paths, embedded NUL,
backslashes, leading `/`, `user://`, `res://`, drive letters, and any `.`/`..`/empty segment;
`_validate_entry()` additionally rejects case-fold collisions, duplicate normalized paths,
non-file/directory entry types, and enforces per-entry and total size limits. It is a better
validator than anything the engine ships, and **the naming validator should be written in the
same style: an allow-list plus explicit structural rejections.**

### 4.3 The one live gap — free-text label into BBCode

`PrepScreen.gd:223` reads a **free-text save label** (`strip_edges()` only — no length cap,
no charset restriction) and passes it to `write_campaign_slot(id, label)`. That label is
stored in save JSON and shown back to the player.

Separately, `UnitDetailsScreen.gd:609` does:

```gdscript
lines.append("[b]%s[/b]" % w.display_name)
```

into a `RichTextLabel` with `bbcode_enabled = true` (`UnitDetailsScreen.tscn:54` and
following; `HUD.tscn` has three more).

`display_name` today comes from campaign pack data — but **campaign packs are imported from
player-supplied ZIPs**, and `CampaignTier2Validators` only calls `_require_string()` on
`display_name` (`:131`, `:191`). It checks the type, not the content. So an imported pack can
put `[url=http://…]` or `[img]…[/img]` into a weapon's display name and it renders as live
markup in the unit details screen.

This is not remote code execution — BBCode is markup, not script — but `[url]` is a
clickable link and `[img]` loads a resource path, so it is a phishing and UI-defacement
surface, and it is the exact Minecraft-anvil pattern from §2. **It exists today, before any
keyboard is built.** Adding a player-authored alias per EPUX-27 would widen it from
"imported pack content" to "anything the player types".

Fix is one line at each interpolation site, and §3.5 means it must be the manual bracket
swap, not `bbcode_escape()`.

## 5. Recommended validation contract

The organising principle: **classify by destination, not by field.** The same string is
harmless in one place and hostile in another, so the rules attach to where it goes.

### Class A — display-only text (unit alias, forge alias, save label)

Allow-list, applied live in `text_changed`:

- Unicode letters, marks, digits, space, and `' - . ,` — enough for `O'Neill`, `Jean-Luc`,
  `St. Clair`.
- **Length capped in characters, not bytes** — 12 for a unit or weapon alias (the FE forge
  and Pokémon precedent), 32 for a save label.
- Reject, do not silently strip, so the player sees why. `validate_filename()`'s
  strip-and-continue is the wrong behaviour for a name field.

Block, with a reason each:

| Blocked | Why |
|---|---|
| Control characters `U+0000–U+001F`, `U+007F` | Newlines break single-line layout; NUL truncates C-string boundaries; both corrupt log lines |
| Bidi controls `U+202A–U+202E`, `U+2066–U+2069` | [Trojan Source](https://en.wikipedia.org/wiki/Trojan_Source) / [RLO spoofing](https://attack.mitre.org/techniques/T1036/002/) — reorders *surrounding* UI text, not just its own field |
| Zero-width `U+200B–U+200F`, `U+FEFF` | Invisible; produces names that look identical but are not equal, defeating duplicate detection |
| Unassigned / private-use / surrogates | No font coverage; no stable meaning |
| Combining marks beyond ~2 per base | "Zalgo" — overflows the line box and breaks layout |
| Emoji and other astral-plane symbols | §3.6: renders as a missing glyph in this project today, and breaks width metrics |
| Leading/trailing whitespace | Invisible difference between two names |
| `[` and `]` | §4.3 — BBCode. Blocking at input is a *convenience*; escaping at render is the actual fix, because pack-authored names never pass through our input field |

Normalize to **NFC** before storing so `é` and `e´` compare equal.

**Do not word-filter in v1.** The packet's [TEXT-07] recommendation holds, the comparators
confirm it (filtering appears only at a sharing boundary), and Pokémon's false positives are
the cost of getting it wrong.

### Class B — anything that becomes a filename

**Never derive a filename from a display name.** This is the single most important rule
here, and it is the one Diablo II learned the hard way.

Keep the existing split: the **slot id** is the filename and stays on
`SaveManager`'s `[A-Za-z0-9_-]` alphabet; the **label** is display-only Class A text stored
*inside* the JSON. If the player should not have to invent an id, generate it — a timestamp
or counter — and let them name only the label. That removes the entire class of problem
rather than defending against it.

Add to `is_valid_slot_id()`:

- reject Windows reserved device names, case-insensitively, **with or without an
  extension**: `CON PRN AUX NUL COM1–COM9 LPT1–LPT9`;
- require the first character to be alphanumeric;
- keep the 64-char cap.

Then, at every write: `simplify_path()` the joined path and assert it still begins with the
intended directory prefix. §3.4 shows `user://` alone does not guarantee this.

### Class C — import/export paths

**Owner revision 2026-07-30: v1 supports filename and path entry through the file-picker
surface.** Folder navigation remains the controller-first route, but the filename/path
boxes may invoke the same virtual keyboard and hardware users may type or paste a path.

- **Export (revised 2026-08-09 after two failed Windows rounds):** default to a generated
  filename and edit it in a game-owned constrained modal. Confirmation opens FileDialog
  for directory selection with the filename read-only, so Escape has one conventional
  cancel meaning. The modal supplies the filename/path character profile to the fixed
  keyboard; invalid platform characters stay visible but disabled.
- **Import:** use Godot's `FileDialog`/native picker. Navigation is primary; typed/pasted
  paths are accepted by that controlled picker surface and still pass the same extension,
  archive-preflight, and import validation as a clicked file.
- **Raw paths remain privileged input.** A typed path must never bypass the picker or feed
  a write/import operation directly. Normalize it, reject traversal where a sandboxed
  destination is required, and apply the operation's normal validation after selection.

The archive *contents* are already handled by `CampaignArchivePreflight` and need no change.

### Class D — text crossing to another player

Deferred, per [TEXT-07]. Record now that the boundary exists: cloud sync, campaign sharing,
exported runs. When it becomes real, Class A validation is the floor and a filter is the
open question — and Awakening/Pokémon are the precedent for adding one there and only there.

### Where each rule lives

| Layer | Responsibility |
|---|---|
| `ValidatedLineEdit` (new, shared) | Class A allow-list live in `text_changed`, caret preserved, `max_length` set |
| `SaveManager.is_valid_slot_id()` | Class B alphabet + reserved names + leading-alphanumeric |
| Path join helpers | `simplify_path()` + prefix assertion at every write |
| Render sites | Bracket escape at **every** `%s` into a `bbcode_enabled` label |
| `CampaignTier2Validators` | Class A rules applied to imported pack `display_name`s |
| `CampaignArchivePreflight` | Unchanged — already correct |

Input filtering is a UX convenience. **The render-site escape and the storage-site allow-list
are the actual controls**, because pack-authored and hand-edited-save text never passes
through our text field at all.

## 6. Additional owner questions

These extend, and do not modify, [TEXT-01]–[TEXT-08].

### [TEXT-09] Is the alias charset ASCII-only, or Unicode letters?

The packet's [TEXT-03] answers this for the *keyboard* (ASCII layout shipped first). This
asks it for the *validator*, which is a different question: a player pasting from the OS
clipboard, or a pack author writing JSON directly, bypasses the keyboard entirely.

- **A — Validator matches the keyboard: ASCII only.** Simple, total. But a pack author
  cannot write `Café` in a display name, which is a real content limitation.
- **B — Validator accepts Unicode letters/marks/digits; keyboard offers ASCII.** The
  keyboard is an input convenience, the validator is the security boundary, and the two
  legitimately differ.
- **Recommendation: B.** The blocklist in §5 is written in terms of Unicode categories
  precisely so it does not depend on the shipped layout.

### [TEXT-10] Do we fix the BBCode escape gap now, or with the keyboard?

§4.3 is live today via imported packs and is independent of text entry.

- **A — Fix now** as a standalone hardening change: escape at render sites, add Class A
  validation to pack `display_name`s.
- **B — Fold into the keyboard work**, since that is when player-authored aliases appear.
- **Recommendation: A.** It is a small, testable change; the exposure exists whether or not
  a keyboard is ever built; and per DoD#2 the check lands with the rule.

### [TEXT-11] Reserved-name rejection — where does it go?

`SaveManager`'s alphabet is safe but `CON`/`NUL` pass it (§4.1), and the container cannot
reproduce the Windows failure (§3.3).

- **A — In `is_valid_slot_id()`**, with a unit test asserting the *verdict* rather than
  attempting a write.
- **B — Nowhere**, on the grounds that ids are about to become generated anyway.
- **Recommendation: A.** It is roughly five lines, and [TEXT-12] is not yet decided.

### [TEXT-12] Are save slot ids generated or player-typed?

This decides whether Class B ever needs a keyboard at all.

- **A — Generated** (timestamp or counter); the player types only a display label. Removes
  the filename problem entirely and is the strongest form of the packet's [TEXT-06]
  minimise-text-entry rule.
- **B — Player-typed**, validated as today.
- **Recommendation: A.** It converts a security boundary into an implementation detail, and
  it is consistent with EPUX-27 choosing generated canonical names with an optional alias —
  the same shape one level down.

## 7. Decision status

Recommendations above are research recommendations unless marked **OWNER RULING**. The walk
ran 2026-07-26 and is **COMPLETE**; [TEXT-09]–[TEXT-12] are ratified, plus one sub-question
the walk raised.

- **TEXT-09 — ratified (B).** The **validator accepts Unicode letters/marks/digits while the
  keyboard ships ASCII.** They differ deliberately: the keyboard is an input convenience, the
  validator is the security boundary, and clipboard paste or hand-written pack JSON bypasses
  the keyboard entirely. §5's blocklist is written in Unicode categories precisely so it does
  not depend on the shipped layout.
- **TEXT-10 — ratified (A), and the severity is worse than this document first stated.**
  Investigated during the walk against Godot 4.6.3:
  - **`[url]` is inert.** `UnitDetailsScreen._on_entry_clicked` parses `category:key` and only
    moves a selector — no `OS.shell_open()`, no navigation. **The phishing concern in §4.3 is
    withdrawn.**
  - **`[img]` is an arbitrary-code-execution primitive.** `[img]user://evil.tres[/img]` in a
    `bbcode_enabled` RichTextLabel **executed the resource's embedded script `_init()`** —
    verified by marker file. `[img]` resolves through `ResourceLoader.load()`, so it inherits
    the full `.tres` hazard from §3.7.
  - With an asymmetry that removes any reason to keep the tag working: `[img]user://ok.png`
    **fails** ("Resource file not found"), because a raw PNG under `user://` has no `.import`
    file. Legitimate images do not load; malicious resources do.
  - **The chain needs a second foothold that `CampaignArchivePreflight` currently denies** —
    a `.tres` cannot be extracted from a pack, since preflight admits only indexed JSON and
    `png/ogg/wav/ttf/otf`. The realistic attack today is social ("place this file, then import
    my pack"), not pack import alone.
  - **Therefore `_safe_archive_path()` and the approved-extension allow-list are load-bearing
    security controls, not hygiene.** The ruling requires all three of: escape brackets at
    every render site, apply Class A validation to pack `display_name`s, **and add a
    regression test asserting preflight still rejects `.tres`/`.res`/`.tscn`** — so the control
    holding this chain shut cannot be relaxed by someone who does not know what it is doing.
    Per DoD#2 the checks land in the same change.
- **TEXT-11 — ratified: on the import path, not the save path.** Generated ids (see TEXT-12)
  can never produce `CON` or `NUL`, so `is_valid_slot_id()` no longer needs the check. Import
  does, because TEXT-12a rules that externally-renamed files must still resolve. Test by
  asserting the validator's **verdict**, never by attempting the write — §3.3.
- **TEXT-12 — ratified (A), with a second clause the question did not ask.** Slot ids are
  **generated on creation**; the player names only the display label. **And identity comes
  from the file's internal manifest, not its filename**, because a user may rename files
  during external file management. The filename is a container, not an identifier.
- **TEXT-12a — ratified: the manifest-identity rule covers save files too**, not only campaign
  packs — the ratified cloud-sync decision already makes manual export/import the v1 primary,
  so saves get externally managed as well. **Concrete cost, measured against current code:**
  `SaveManager.list_slots()` reads an index keyed by `slot_id` and calls `has_slot()` on
  `<slot_id>.json`, so a renamed save silently vanishes from the list. This needs a directory
  scan that reads each file's internal header, with the index demoted to a **cache rather than
  the truth**.

**Net effect on §5:** Class B shrinks (filenames are generated, so the alphabet is ours), and
Class C is unchanged. Class A and the render-site escape absorb the real work — which §5
already predicted, since pack-authored text never passes through our input field.

## 8. What was not resolved

- **Whether `[img]` in a `RichTextLabel` can reach an imported pack asset path.** §4.3
  establishes the markup renders; the reachable target set was not enumerated. This bounds
  how bad the [TEXT-10] gap is and should be checked before deciding severity.
- **The NUL-byte measurement is inconclusive.** GDScript's *source parser* replaced the
  literal NUL with U+FFFD before the runtime saw it, so §3.2's NUL row describes the parser,
  not `is_valid_filename()`. Re-test by reading bytes from a file. Treat NUL as blocked
  regardless.
- **Emoji rendering was not visually verified** — the container cannot do a visual pass, per
  project rule. §3.6 reasons from the absent font configuration, which is verified, to the
  rendering outcome, which is not.
- **Windows reserved-name and `MAX_PATH` behaviour was not tested on Windows.** All
  filesystem measurements here are Linux. This is the §3.3 hazard applied to this document
  itself.
- **`String.bbcode_escape()` in a future Godot.** Confirmed absent in 4.6.3; PR #78310 is
  merged to a 4.x milestone. Re-check on the next engine bump and replace the manual swap.
