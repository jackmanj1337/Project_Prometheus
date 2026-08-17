---
Type: register
Status: RESOLVED 2026-07-26 — TEXT-01..15 all ratified (TEXT-03 revised by owner 2026-07-30)
Last verified: 2026-08-17
Register: TEXT-01..15
Track IDs: RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26
---

> **Filed as the `TEXT-01..15` register 2026-08-17 by `R1`** (§6.4 of
> [`r1_plan_corpus_precedence_diff_2026-08-17.md`](r1_plan_corpus_precedence_diff_2026-08-17.md)).
> This packet holds the `[TEXT-nn]` question headings and the per-ID ratifications in
> *Decision status* below, so it is the decision source. `REGISTERS.md` previously listed
> `TEXT-4..15` against `text_entry_mobile_compact_2026-08-06.md`, which is a later **design**
> document that merely mentions `TEXT-04` and `TEXT-15` — the range was fabricated from the
> minimum and maximum of two scattered IDs. Its **two companions** are
> [`text_entry_layout_implementation_research_2026-07-26.md`](text_entry_layout_implementation_research_2026-07-26.md)
> (the `[TEXT-02]` correction and the `[TEXT-03]` revision) and
> [`text_entry_naming_and_sanitization_2026-07-26.md`](text_entry_naming_and_sanitization_2026-07-26.md).
> Nothing below is changed by the re-filing.

# Text Entry Strategy — Comparative Research and Owner Questions

## Scope and conclusion

Three v1 cuts share one root cause: text entry and pointer input are not available on
every input method. Drag/drop [EPUX-09], stock free-text search [EPUX-15], and forge item
alias [EPUX-27] were each cut separately for the same reason. This packet decides the
underlying capability once, as an **input-layer** concern rather than a forge or shop
feature.

The optional naming/search/alias surfaces do not block v1. One shipped defect now does:
the Windows FileDialog closes on the first physical Escape while its filename field is
focused. The text-entry layer owns that repair because it needs one cancel-arbitration
contract rather than another FileDialog-local interception point. This does not reopen the
three deferred features.

**Headline finding — the platform will not do this for us.** The task row asked whether an
adequate built-in affordance would shrink the question set to a settings policy. It would
not. Godot's virtual keyboard is implemented on Android, iOS, and Web only; the desktop
display servers reject the call outright with *"Virtual keyboard not supported by this
display server"*. Our only shipping target today is Windows Desktop, and the Steam Deck is
also a desktop Linux target. On both, `LineEdit.virtual_keyboard_enabled` — which defaults
to `true` — does nothing at all. There is no Godot-level fallback to configure.

**Recommended shape:** treat this as **three separate deliverables, not one**, and do not
build a keyboard first.

1. **Reduce the requirement before satisfying it.** Fire Emblem's actual lesson is not how
   it draws a keyboard — it is how little text it ever asks for. Adopt a hard rule that no
   v1 feature requires free text, with a single narrow exception (naming), and every other
   candidate uses selection, filters, or generated identifiers.
2. **Adopt the Steam on-screen keyboard for the Deck**, because Deck Verified *requires* an
   automatic on-screen keyboard for text input and Valve's own OSK satisfies it for free.
   This is a packaging decision, not a UI one.
3. **Only then** build an in-game keyboard, and build it **daisywheel-first**, because the
   grid QWERTY that every available Godot addon implements is the slowest controller text
   entry pattern measured.

The v1 keyboard ships the complete printable US-ASCII set behind `ABC`, `123`, and
`Symbols` layers. Each input request supplies an allowed-character profile. Keys outside
that profile remain visible in fixed positions but are disabled; a caller never removes
or rearranges keys to express validation.

## Evidence and comparator findings

### Godot's own support

- `DisplayServer.virtual_keyboard_show()` exists in Godot 4 (it replaced Godot 3's
  `OS.show_virtual_keyboard()`; the API was renamed, not removed). `LineEdit` calls it
  internally when a field gains focus. Source: [godot-proposals discussion
  #5885](https://github.com/godotengine/godot-proposals/discussions/5885).
- `LineEdit.virtual_keyboard_enabled` defaults to `true` and is documented only as
  enabling the native keyboard *"on platforms that support it"* — the docs never enumerate
  which. `virtual_keyboard_type` offers DEFAULT/MULTILINE/NUMBER/DECIMAL/PHONE/EMAIL/
  PASSWORD/URL, with the note that PASSWORD *"is not supported on Web"* and degrades to
  DEFAULT. Source: [LineEdit class
  reference](https://docs.godotengine.org/en/stable/classes/class_lineedit.html).
- Godot's authoritative `DisplayServer` feature table limits
  `FEATURE_VIRTUAL_KEYBOARD` to Android, iOS, and Web, and the
  `virtual_keyboard_show()` contract repeats that implementation list. Windows and Linux
  desktop are absent, so `LineEdit.virtual_keyboard_enabled` cannot provide the requested
  desktop fallback. Source: [Godot stable `DisplayServer` class
  reference](https://docs.godotengine.org/en/stable/classes/class_displayserver.html).
- The **Web** path is explicitly experimental and buggy. The experimental virtual keyboard
  draws *over* the app and hides the input, and `text_submitted` is not emitted
  ([#76215](https://github.com/godotengine/godot/issues/76215)); it does not work with
  `LineEdit`/`TextEdit` inside a `SubViewport`
  ([#108355](https://github.com/godotengine/godot/issues/108355)). Web support works by
  proxying a hidden HTML input, clearing and rewriting the Godot control on every
  insertion. Source: [Godot Web progress report
  #7](https://godotengine.org/article/godot-web-progress-report-7/). **This matters to us:**
  the campaign-library work assumes a web build, and `SubViewport` is exactly how a scaled
  game viewport is usually composed.
- Godot 4.5 integrated **AccessKit**, adding screen-reader support to `Control` nodes and
  exposing bindings to customise accessibility for any node. It is still described as
  experimental. Any custom keyboard we build is made of `Control`s and therefore inherits
  this — a bespoke keyboard is *not* an accessibility regression by construction, but it
  must be authored with accessible names. Source: [Godot 4.5 release
  notes](https://godotengine.org/releases/4.5/).

**Conclusion:** on Windows and Steam Deck, Godot contributes nothing. On web it contributes
something unreliable. The engine is not the answer.

### Steam Deck — a hard certification requirement

- Steam **requires** that a game *"automatically display an on-screen keyboard when
  requiring the user to input text"* to earn Deck Verified. This is a certification gate,
  not a recommendation. Source: [Steamworks — Getting your game ready for Steam
  Deck](https://partner.steamgames.com/doc/steamdeck/recommendations).
- Two APIs are offered: **`ShowFloatingGamepadTextInput`** (floats over game content and
  sends key inputs directly, so the game needs no callback plumbing) and
  **`ShowGamepadTextInput`** (callback-based; the game reads the result with
  `GetEnteredGamepadTextInput`). The floating variant takes the text field's screen rect so
  the keyboard positions itself without covering the field.
- Valve's current `ISteamUtils` reference confirms that the floating form sends OS key
  events directly to the game and reports whether it could be shown; the full-screen form
  returns submitted text through `GetEnteredGamepadTextInput`. Source: [Steamworks
  `ISteamUtils`](https://partner.steamgames.com/doc/api/isteamutils?l=english).
- Both are exposed to Godot 4 through **GodotSteam**'s `Utils` class as
  `showFloatingGamepadTextInput()` / `showGamepadTextInput()`, with dismissal signals.
  Source: [GodotSteam Utils documentation](https://godotsteam.com/classes/utils/) (the page
  returned 403 to automated fetch; the API surface above is corroborated by the
  Playgama write-up below and by search indexing of that page).
- Practical guidance from shipped implementations: detect Big Picture / Deck mode and force
  the Steam keyboard only there, keeping native OS text input on desktop, so the player does
  not get two keyboards. Source: [Playgama — implementing an on-screen keyboard for Steam
  Deck](https://playgama.com/blog/general/how-can-i-implement-an-on-screen-keyboard-feature-for-my-game-running-on-steam-deck/).

**Conclusion:** for the Deck specifically, the cheapest compliant answer is Valve's
keyboard, not ours. It costs a GodotSteam dependency and only works inside Steam.

### Fire Emblem — the real lesson is scarcity, not layout

The series has needed free text in exactly one place for its entire modern run: naming the
player avatar. Everything else — unit selection, shop, forge, convoy, supports — is
selection from authored data.

- **Awakening (3DS)** lets the player name the avatar during creation. The field is
  effectively **~8 characters** in practice (12 absolute, but the variable-width font only
  fits 12 with thin glyphs like `I`). Source: [Fire Emblem Wiki —
  Robin](https://fireemblemwiki.org/wiki/Robin).
- **Awakening additionally runs a word filter** on the chosen name, because names are
  transmitted over StreetPass. Source: as above. This is the only place in the series where
  text crosses a trust boundary, and it is filtered.
- **Three Houses (Switch)** restricts avatar customisation to form, birthday, and an
  **eight-character name**. **Engage** is the same shape — name, gender, birthday. Source:
  [Fire Emblem Wiki — Player character](https://fireemblemwiki.org/wiki/Avatar).
- **Fates** rebuilt avatar creation around a **graph/slider system** — features plotted on
  axes rather than typed. Source: [Serenes Forest — Fates avatar
  creation](https://serenesforest.net/fire-emblem-fates/avatar-creation/). This is direct
  evidence for replacing text with bounded selection wherever the data allows.
- On Switch, naming uses the **system software keyboard** (`nn::swkbd`), not a bespoke
  in-game one. That keyboard translates controller input into on-screen keyboard navigation
  — stick/d-pad moves a hover cursor, `A` commits the highlighted key, `B` is backspace,
  `L`/`R` move the text cursor — and simply stops accepting input at the length cap. Source:
  [Switchbrew — Software Keyboard](https://switchbrew.org/wiki/Software_Keyboard).

**Conclusion:** the series answer to "controller text entry is expensive" is *ask for less
text*. Where a console offered a system keyboard, Fire Emblem used it rather than building
one. Neither Windows nor the Deck offers us that (outside Steam), which is why our
equivalent of "use the system keyboard" is the Steam OSK.

### Controller text-entry patterns — grid versus daisywheel

- The **daisywheel** (Steam Big Picture's original text entry) groups characters into eight
  petals of four. The left stick tilts to a petal; a face button picks one of its four
  characters. Any character is therefore **2 actions** (one stick tilt, one button press).
- A **grid QWERTY** navigated by d-pad or stick requires stepping to each key — reported at
  **up to 12 actions** per character across a full layout.
- Sources: [DaisywheelJS](https://likethemammal.github.io/daisywheeljs/) and its
  [README](https://github.com/likethemammal/daisywheeljs/blob/master/README.md), a port of
  the Big Picture layout that documents the 8×4 petal scheme and the action-count
  comparison.

**Conclusion:** a daisywheel is roughly an order of magnitude fewer input actions per
character than the grid layout that every off-the-shelf Godot addon implements. Its costs
are discoverability (it must be taught) and that it is genuinely awkward with a mouse or
touch — so it complements a grid layout rather than replacing it.

### Open-source Godot implementations surveyed

Four were examined. **None is a safe drop-in dependency**; all are small, and the most
featureful is the wrong engine version and the wrong licence.

| Project | Godot | Licence | Input | Notes |
|---|---|---|---|---|
| [greenpixels-onscreen-keyboard](https://github.com/greenpixels/greenpixels-onscreen-keyboard) | **4** | MIT | controller + touch | Closest fit. Clean signal API (`on_text_changed`, `on_submit_pressed`, `on_cancel_pressed`), inspector toggles for number-only, space, shift, backspace, symbols, and character filtering. Very small: 8 stars, 11 commits, no releases. |
| [HauntedBees Virtual Keyboard **and Daisywheel**](https://github.com/HauntedBees/Godot-Virtual-Keyboard-and-Daisywheel) | 3.4 | **AGPL-3.0** + bespoke clause | daisywheel (gamepad); keyboard (gamepad + mouse) | The only daisywheel implementation found. 8 petals × 4 face buttons; triggers switch sets (R2 capitals, L2 numbers); **max 32 characters per set**; sets configurable in the inspector. Font Ulagadi Sans (SIL OFL). |
| [martinfuchs Onscreen-Keyboard](https://github.com/martinfuchs/Godot-Onscreen-Keyboard) | unstated | MIT | mouse/touch; **controller not mentioned** | Most popular (67 stars, 24 commits, 6 open issues). Best *architecture* idea: **JSON-defined layouts** with key types `char` / `special` / `special-shift` / `switch-layout`, per-key `stretch-ratio` and icons. Auto-shows on `LineEdit`/`TextEdit` focus. |
| [Cevantime godot-virtual-keyboard](https://github.com/Cevantime/godot-virtual-keyboard) | unstated | MIT | gamepad | Effectively a stub: 2 commits, 6 stars, no documentation. Not viable. |

**The licence point is decisive for one of them.** HauntedBees is **AGPL-3.0** with a
non-standard exception (projects earning under $1,000 may use it in a proprietary game with
credit; larger projects must open-source compatible code, remove it, or pay $10). That is
not an OSI-standard grant and it is incompatible with how this project treats third-party
code under the ratified licensing decisions. **Read its daisywheel for the pattern; do not
vendor its code.** The 2-action-per-character scheme is a UI design, not copyrightable
expression, and can be implemented independently.

**Conclusion:** adopt *ideas* — greenpixels' signal shape, martinfuchs' JSON layout
model, HauntedBees' daisywheel geometry — and write our own against Godot 4.6. None of
these is maintained enough to depend on.

## Existing decisions this must respect

- **[EXT] author-extensibility / open-registry principle.** A keyboard layout is exactly the
  kind of vocabulary that grows with content and locale. It must be **data-driven**, not a
  hardcoded `match` over key names. martinfuchs' JSON layout model is the shape the
  architecture principle already demands.
- **[EPUX-09 / EPUX-15 / EPUX-27]** are the three cut features waiting on this.
- **Menu Scale and 200% stress** (campaign-library Branch I) apply: a keyboard is a dense
  grid of small targets and is the worst case for UI scaling.
- **Input-map confirm/cancel double-bind defect** (`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND`)
  is directly relevant — a keyboard needs unambiguous confirm/cancel/backspace bindings.
- **Cloud sync / campaign sharing**: any text that leaves the machine inherits the
  Awakening word-filter problem. See [TEXT-07].

## Owner questions

### [TEXT-01] What is the v1 text-entry capability?

- **A — In-game keyboard only.** One implementation, identical everywhere, no platform
  dependency. For: total control, works on Windows/Deck/web/future console alike; testable
  headlessly. Against: we build and maintain it; it is the most work.
- **B — Platform keyboard where one exists, in-game keyboard as fallback.** Steam OSK on
  Deck/Big Picture, OS keyboard on touch web/mobile, ours elsewhere. For: satisfies Deck
  Verified for free; native feel per platform. Against: several code paths, each needing
  real-hardware verification; the Steam path only exists inside Steam.
- **C — Assume a hardware keyboard.** For: zero work. Against: forfeits Deck Verified the
  moment any v1 feature needs text, and strands controller-only players.
- **Recommendation: B, with the in-game keyboard built first and the Steam path added as a
  packaging step.** B is what the Deck requirement forces and what Fire Emblem does on
  Switch (use the system keyboard when there is one). Building ours first keeps the Steam
  SDK off the critical path and guarantees a working fallback everywhere.

### [TEXT-02] Which entry layout?

- **A — Grid QWERTY only.** For: universally understood; usable with mouse, touch, and
  stick; what every Godot addon ships. Against: up to ~12 input actions per character on a
  controller — the slowest option measured.
- **B — Daisywheel only.** For: ~2 actions per character; dramatically faster on a pad.
  Against: must be taught; poor with mouse/touch; unfamiliar.
- **C — Both, selected by active input method.** Grid for mouse/touch, daisywheel for
  gamepad. For: each input device gets its best pattern. Against: two layouts to build,
  test, and localise.
- **Recommendation: C, but sequenced — ship the grid first, add the daisywheel second.**
  The grid is the safe default and covers mouse/touch/web; the daisywheel is the reason to
  bother having our own keyboard at all. If only one ever ships, the evidence favours the
  grid for breadth and the daisywheel for the controller-first identity this project has.

### [TEXT-03] How is the character set presented and restricted?

The task row already accepts a limited set. The question is *how* limited.

- **A — ASCII letters + digits + a short symbol list.** For: one layout, no font work,
  trivially validated. Against: no non-English player names; a de facto English-only game.
- **B — ASCII + Latin-1 accents via a modifier/long-press.** For: covers most European
  names at modest cost. Against: needs a second layer and font coverage.
- **C — Data-driven layouts per locale, ASCII shipped first.** For: matches [EXT]; a
  locale can add its layer without an engine edit. Against: most up-front design.
- **Recommendation: C as the architecture, with complete printable US-ASCII as shipped
  content.** Build the JSON layout registry now and populate `ABC`, `123`, and `Symbols`
  layers covering characters U+0020 through U+007E. Every request supplies an allowed-
  character profile. Non-allowed characters stay in their normal positions and render
  disabled rather than disappearing or causing layout shifts. Note the daisywheel's
  structural cap of ~32 characters per set constrains later wheel layers, not the grid.

### [TEXT-04] Do we commit to the Steam OSK, and therefore to GodotSteam?

- **A — Yes, add GodotSteam and use the Steam OSK on Deck/Big Picture.** For: the documented
  route to Deck Verified; Valve maintains the keyboard. Against: a native GDExtension
  dependency affecting build and export, for one feature.
- **B — No, use our keyboard everywhere including the Deck.** For: no dependency, one code
  path. Against: **unverified whether our own keyboard satisfies Deck Verified** — the
  requirement says "automatically display an on-screen keyboard", which ours arguably does,
  but Valve's wording recommends their APIs and this has not been tested against a real
  review.
- **C — Defer until Steam is an actual target.** For: we ship Windows Desktop today; there
  is no Steam build. Against: retrofitting later is when it gets forgotten.
- **Recommendation: C now, A when a Steam build is scheduled** — and record the requirement
  on the release checklist rather than in this document, so it cannot be lost. **Flagging an
  open factual question:** whether a custom in-game keyboard alone passes Deck Verified is
  not settled by the sources; if the owner wants certainty, that is a question for Valve,
  not further desk research.

### [TEXT-05] What does the player control?

- **A — Fully automatic.** Detect the active input device and show the matching keyboard.
  For: nothing to configure; correct by default. Against: detection is wrong sometimes
  (a Deck in desktop mode with a Bluetooth keyboard; a PC with a controller plugged in but
  unused).
- **B — Automatic with an override setting** offering *in-game keyboard* / *system keyboard*
  / *assume hardware keyboard*. For: the row's three options, with a sane default. Against:
  one more setting to explain and test.
- **C — Explicit setting only.** For: predictable. Against: punishes everyone for an edge case.
- **Recommendation: B.** Auto-detect by last-used input device, with the three-way override.
  Note the existing detection precedent: campaign-library Branch K ruled that we
  **detect keyboard-present, never touch-absent** — the same asymmetry applies here and the
  override exists precisely because detection is not reliable.

### [TEXT-06] Do we hold the line on minimising text entry?

This is the question the research most strongly recommends asking.

- **A — Yes, ratify a rule.** No v1 feature may *require* free text except naming; anything
  else uses selection, filters, or generated identifiers. For: this is the Fire Emblem
  answer, and it makes the keyboard a convenience rather than a dependency. Against:
  constrains future design; some features are genuinely worse without search.
- **B — No, treat the keyboard as unlocking the deferred tranche** and restore drag/drop
  search, forge alias, etc. once it exists. For: recovers three cut features. Against:
  re-litigates three settled cuts, and each restored feature then needs its own controller
  design anyway.
- **Recommendation: A, with the keyboard built anyway.** The cuts were correct for reasons
  beyond text entry (EPUX-15 chose filters over search on interaction-cost grounds, not
  just input). A keyboard should not silently reopen them. If it lands as a rule, DoD#2
  applies — land its check in the same change.

### [TEXT-07] What happens to text that leaves the machine?

Awakening word-filters the avatar name because StreetPass transmits it. Our equivalents are
campaign sharing, cloud sync, and exported runs.

- **A — Validate length/charset only.** For: cheap, no policy. Against: user-authored text
  reaches other people unfiltered.
- **B — Validate, plus a filter on anything crossing a sharing boundary.** For: matches the
  one real precedent. Against: word filters are culturally fraught, need maintenance, and
  generate false positives on legitimate names.
- **C — Validate, and never transmit user free text** — strip or replace names on export.
  For: removes the problem entirely. Against: names are what make a shared run personal.
- **Recommendation: A for v1 with the boundary documented**, deferring B until sharing is
  real. There is no transmission path in v1, so a filter would guard nothing — but the
  decision should be recorded now so the sharing work inherits it rather than rediscovering
  it. Relates to the redaction scrubber already ruled in campaign-library Branch J.

### [TEXT-08] Build or adopt?

- **A — Vendor an existing addon.** For: fastest. Against: the only Godot 4 + permissive +
  controller option (greenpixels) is 11 commits with no releases; the featureful one is
  Godot 3.4 and AGPL with a bespoke clause we should not accept.
- **B — Write our own, informed by all four.** For: Godot 4.6, our input map, our Menu
  Scale, our accessibility, our data-driven layout registry per [EXT]. Against: most work.
- **C — Fork greenpixels and extend it.** For: a working Godot 4 starting point under MIT.
  Against: inherits an unfamiliar structure for a component we will heavily modify.
- **Recommendation: B, reading all four for patterns.** Specifically: greenpixels' signal
  API shape, martinfuchs' JSON layout model, HauntedBees' daisywheel geometry
  (pattern only — **not** its code, per the licence). The component is a `Control` grid with
  a focus model; the value is in the layout registry and the input mapping, both of which
  are ours regardless.

## 2026-07-30 implementation-readiness addendum: FileDialog Escape

The v0.5.8 Windows return changes implementation order, not the accepted product shape.
All five FileDialogs already use `FileDialogInputGuard.gd`; an in-tree FileDialog is its
own viewport; its filename `LineEdit` is the measured focus owner; and subwindows are
embedded. Those facts rule out a missing-script or wrong-viewport repair.

The remaining uncertainty is event ordering on Windows. The guard currently intercepts
the same physical Escape at `window_input`, `_input`, and `_shortcut_input`, yet the built-in
FileDialog closes first. The regression test calls `_on_window_input()` directly, so it
proves the handler body but bypasses the event route that fails in the exported build.

The first implementation slice must therefore:

1. instrument a Windows diagnostic build to record focus owner and the arrival order of
   `window_input`, `_input`, `_shortcut_input`, built-in cancel, and close-request handling;
2. reproduce with a dispatched physical Escape rather than a direct handler call;
3. introduce one text-entry session/coordinator that owns printable input and physical
   Escape before callers translate cancel into dismissal;
4. make FileDialog the first adopter: first Escape ends filename editing and focuses the
   file list; a later Escape may close the dialog; and
5. keep ordinary mapped Cancel behavior separate from physical Escape so controller Back
   and printable mapped characters do not inherit filename-editor policy accidentally.

This diagnostic pass requires a real Windows run. Headless tests can lock the resulting
event contract after the platform order is measured; they cannot establish that order by
calling the desired handler directly.

## What was not resolved

- Whether a **custom** in-game keyboard alone satisfies Steam Deck Verified. Sources state
  the requirement and recommend Valve's APIs, but do not say a bespoke keyboard fails. See
  [TEXT-04].
- The Godot version targeted by martinfuchs' and Cevantime's addons is undocumented in both
  repositories; neither was verified against 4.6.
- The GodotSteam `Utils` documentation page returned HTTP 403 to automated retrieval. The
  API names and behaviour above are corroborated from two independent sources but the exact
  current signatures should be read from GodotSteam directly before implementation.
- No measurement of daisywheel versus grid was performed *by us*; the action-count
  comparison is DaisywheelJS's own claim, and is consistent with the geometry but is not an
  independent study.

## Decision status

Recommendations above are research recommendations unless marked **OWNER RULING**. The walk
ran 2026-07-26 and is **COMPLETE — TEXT-01..TEXT-15 are all ratified**, across this packet
and its two companions. Nothing here awaits an owner decision.

- **TEXT-01 — ratified (B).** Platform keyboard where one exists, ours as the fallback, with
  **ours built first** and the Steam path added later as a packaging step.
- **TEXT-02 — ratified (A), as revised by [TEXT-13].** Grid QWERTY first **as the default on
  the merits**, daisywheel second as an opt-in. TEXT-13 replaced this question's *reasoning*:
  the daisywheel's action-count advantage is ~2×, not ~6×, so the grid is not merely the safe
  option. **[TEXT-02] and [TEXT-13] were merged during the walk** and ruled once.
- **TEXT-03 — revised by owner 2026-07-30 (C architecture; complete printable ASCII
  content).** Build the data-driven layout registry now and ship fixed `ABC`, `123`, and
  `Symbols` layers covering U+0020..U+007E. An input request disables non-allowed keys in
  place; it never removes or rearranges them. Hardware typing and paste use the same
  allowed-character validator.
- **TEXT-04 — ratified (C now, A when Steam is scheduled)** **+ keep the seam strong**: the
  `system` presenter slot exists in the registry from day one with no Steam backend behind
  it, so adopting GodotSteam later is a drop-in rather than a retrofit. Record the Deck
  Verified requirement on the **release checklist**, not only here.
- **TEXT-05 — ratified (B)**, and **[TEXT-14a] folds into this same setting** rather than
  adding a second one. One control, defaulting to input-device detection, where **touch and
  gamepad route to our native keyboard** and a physical keyboard does not. That default is
  what keeps Deck Verified answerable, since a Deck is gamepad/touch and therefore gets the
  on-screen keyboard automatically.
- **TEXT-06 — revised by owner 2026-07-30.** V1 may require text entry for naming and for
  file/path entry. Other features still use bounded selection, filters, or generated ids
  unless separately approved. The keyboard's existence does not
  reopen [EPUX-09], [EPUX-15], or [EPUX-27] — those were cut on their own merits. **DoD#2
  applies: the rule's check lands in the same change as the rule.**
- **TEXT-07 — ratified (A).** Validate length and charset for v1 and record the boundary; no
  word filter, because v1 has no transmission path for one to guard. Revisit when sharing is
  real.
- **TEXT-08 — ratified as a split answer**, departing from the packet's single-option B.
  Write the **grid** ourselves (no addon is a safe dependency). Build the **wheel** on
  [jesuisse/godot-radial-menu-control](https://github.com/jesuisse/godot-radial-menu-control)
  — MIT, Godot 4, gamepad-aware — which this packet's original survey missed. The two layouts
  genuinely have different best answers.

The [TEXT-09]–[TEXT-12] rulings live in
`text_entry_naming_and_sanitization_2026-07-26.md`; [TEXT-13]–[TEXT-15] in
`text_entry_layout_implementation_research_2026-07-26.md`.

### The one question the walk reordered

The packet proposed taking [TEXT-06] first, as the gate. The owner **deferred it to the end**
so it could be ruled with the keyboard's real build cost visible rather than in the abstract.
That ordering was better and should be the template: decide what a capability costs before
deciding whether features may depend on it.
