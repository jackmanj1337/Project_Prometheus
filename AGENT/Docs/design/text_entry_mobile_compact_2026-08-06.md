# Text Entry on Mobile in Compact — Design — 2026-08-06

Status: Designed (2026-08-06) — all decisions ratified; OS-keyboard suppression Implemented. Tracker row:
`TEXT-ENTRY-ON-MOBILE-COMPACT-2026-08-06`.
Last verified: 2026-08-06

Wireframes and the measured comparison:
<https://claude.ai/code/artifact/52b44060-565d-4252-8bd4-2f3b220bb37d>

Extends [`responsive_ui_redesign_2026-08-06.md`](responsive_ui_redesign_2026-08-06.md)
into the one surface it did not cover, and revisits the `[TEXT-04]` platform-keyboard
ruling in light of the Compact budget, which did not exist when that ruling was made.

## Problem

Compact is 360×640 logical px with a control band that owner decision says is never
covered. That leaves 240px of content. A keyboard has to come from somewhere.

| | Needs | Has | |
|---|---|---|---|
| Shipped 10×7 grid, touch tokens | 440 × 384 | 344 × 288 | 96 too wide, 96 too tall |
| OS keyboard, band kept | ~256–320 tall | 352 menu region | leaves 32–96px for the field |

The OS keyboard is ruled out by arithmetic, not preference: a keyboard at 40–50% of
viewport height plus a 45% control band leaves 5–15% of the screen for the field being
edited, its label and any validation message.

## Decision — 2026-08-06 (owner)

**Suppress the OS keyboard. During a text-entry session our keyboard takes over the
control band.** Nothing is covered, nothing floats. The 288px the controller occupies is
the same 288px a keyboard needs, and the controller is simply unavailable while typing,
which is acceptable because a text session is modal.

This confirms `[TEXT-04]` (ship `system` as a seam with no backend) and hardens it: there
is no platform keyboard coming, so the seam is not "not yet", it is "not planned".

## Why the OS keyboard's trick does not transfer

Worth settling before choosing a layout, because if it transferred, ten columns would
still be viable.

Google's decoder paper puts raw touchscreen text entry at **8–9% per-letter error**, and
states why nobody notices: autocorrection *"work[s] in the background, silently correcting
our typos and misspellings."* The small keys are not accurate. The software is.

| Mechanism | What it does | Transfers |
|---|---|---|
| Hit area ≠ drawn key | Gaps belong to neighbouring keys; no dead space anywhere | **Yes**, free |
| Spatial model | A tap becomes *"a Gaussian distribution centered on each key center"*, not a hit test | **Yes**, useless alone |
| Language model | Bayes over whole sequences. Measured **1.67–1.87×** fewer errors | **No** |
| Key-target resizing | Likely-next keys get silently larger invisible targets | **No** |

A fifth result reframes the problem: Holz and Baudisch showed **67% of touch inaccuracy is
a systematic per-user, per-posture offset** rather than fat-finger blur. Systematic means
correctable, and that is the headroom the industry has spent for fifteen years.

**The last two do not transfer because almost everything a player types here is a proper
noun** — a save name, a profile name, a campaign or unit name — which is out-of-vocabulary
by definition. Gboard maintains an entire parallel *literal* decoding path specifically so
OOV words can be entered at all, and its authors call balancing that against autocorrection
*"tricky"*. The key-target-resizing work names the same hazard from the other end:
over-eager resizing *"violate[s] basic user expectations"* by making the intended text
untypeable. The mechanism that pays for small keys is the one that is worst at our only job.

### Measured against a real iPhone keyboard

On a 1179×2556 phone at 460 ppi the screen is 65.1 mm across, so one logical px is
0.166 mm and every option converts to millimetres of glass.

| Keyboard | Grid | Key | Pitch | |
|---|---|---|---|---|
| iPhone system keyboard | 10 × 4 | 6.18 × 7.29 mm | 6.51 mm | with the full decoder |
| **A** shipped 10×7 grid | 10 × 7 | 5.70 × 5.70 mm | 6.03 mm | smaller than Apple's, no correction |
| **B** reflowed 7×5 at 44px | 7 × 5 | 7.29 × 7.29 mm | 7.95 mm | larger than Apple's on both axes |
| **C** Apple's geometry copied | 10 × 4 | 5.40 × 7.29 mm | 5.73 mm | 13% narrower than Apple's |

Two consequences. **Apple does not follow its own 44pt rule on its own keyboard** — the
keys meet it vertically and miss it badly horizontally, because rows are unambiguous and
columns are exactly what the language model disambiguates. And **B is not the cautious
option**: its keys are physically more generous than the platform keyboard's. That is a
better argument for B than citing a guideline.

Option C is what copying Apple honestly looks like, and is rejected on measurement: it
lands *below* the width Apple already needs a decoder to rescue.

## Decisions — all ratified 2026-08-06

1. **Layout: reflow to 7 columns, alphabetical, with `ABC` / `123` / `Symbols` layers.** At
   360 logical px with 8px gutters there are 344px, so 44px targets allow **seven columns
   and no more**. 26 letters in 4 rows of 7 plus one function row is 348 × 236 and fits the
   288px band with 52px to spare. QWERTY does not survive a 7-wide reflow, so it goes
   alphabetical — the console convention, and the one Fire Emblem uses.
2. **Field echo strip: yes, spend the 52px — but Compact only.** The field lives in a
   scrolling list showing ~4 rows in Compact and can be scrolled out of view while its own
   keyboard is open. A strip pinned above the keys carries the field name, live value, caret
   and character count. **Medium and Expanded do not render it**: the landscape split
   keyboard leaves the field visible in place, so a strip there would duplicate the real
   field beside itself. The validation-message contract is therefore *"the strip where one
   exists, the field's own row otherwise."*
3. **Settings vocabulary: drop `system`.** Leaves Automatic / On-screen keyboard / Physical
   keyboard, all of which do something on every platform, with Physical covering a phone
   cast to a display with a Bluetooth keyboard. Keeping it shown-but-disabled spends one of
   only ~4 visible Compact rows on a permanent no and implies a feature now decided against.
   Keep the registry constant; drop only the Settings row, so it is cheap to reinstate.

## Landscape — the same keyboard, split

Landscape follows from the **dead-space rule** ratified the same day (recorded on
`MOBILE-WEB-CONTROLLER-2026-08-04`): the game view is placed at the size and aspect the
player picks, and whatever is left over *is* the control region. A text session puts the
keyboard in that same region, so portrait and landscape are two reflows of one keyboard
rather than two designs.

| | Class | Grid | Block | Occupies |
|---|---|---|---|---|
| Portrait | Compact | 7 × 5 | 348 × 236 | the bottom control band |
| Landscape | Medium | 3 + 3 × 6 | 156 × 284 per side | the two dead columns |

**The keyboard splits down the middle** — A–M on the left pad, N–Z on the right — so each
thumb owns its own half, never crosses the screen, and **the game view never moves**. The
field being named stays on screen for the whole session, which is why the echo strip is
Compact-only. The layers pay for themselves here too: `123` and `#+=` live on the left pad,
so splitting costs no characters.

**Measured** at 852 × 393 with 44px keys, 4px gaps and 8px gutters. Columns per side are a
direct function of the aspect the player chose, so the split is conditional:

| Game view | View width | Dead / side | Cols / side | |
|---|---|---|---|---|
| 2:3 | 262 | 295 | 5 | roomy |
| 1:1 | 393 | 230 | 4 | |
| 4:3 | 524 | 164 | 3 | **workable — the boundary** |
| 3:2 | 590 | 131 | 2 | too narrow |
| 16:9 | 699 | 77 | 1 | no room |

**Fallback when the dead space is too narrow (ratified): shrink the game view for the
duration of the session.** A text session is already modal, and this is the only option that
keeps strict separation true at every aspect. The alternative — letting the keyboard overlay
the view — would break the rule the whole model rests on. This is not hypothetical: a
tactical map is exactly the view a player would widen past 4:3.

**Split point:** A–M / N–Z, the even cut. Frequency-balancing the halves is worth exploring
only if the even cut tests badly.

## Two free wins, whichever way those go

Both are borrowed directly from how OS keyboards work and neither needs a language model.

- **Claim the gaps.** Draw 44px keys but hit-test 48px so the 4px gutters belong to their
  neighbours. The grid presenter currently leaves them dead space.
- **Correct the systematic offset.** People hit low, and that is a fixed bias rather than
  noise, so a small constant upward nudge on the hit point helps everyone.

## Where a lexicon genuinely applies

**The active campaign pack is an enumerable vocabulary.** Unit names, class names and item
names are all known, and one pack is active at a time. For any field that names one of
those, a filtered candidate list beats a keyboard outright.

This does **not** contradict `[TEXT-15]`'s ruling to spend nothing on prediction: that
ruling was about predicting free text. A closed candidate list over pack content is a
different mechanism, and it is the only form of prediction worth building here.

## OS-keyboard suppression — measured and fixed 2026-08-06

This was recorded as an unverified risk. It was not a risk; it was **live**, and the
mechanism turned out to be one line of export config rather than anything in GDScript.

Measured in the exported artifact, not recalled. `index.js` carries `GodotDisplayVK`, gated
on:

    GodotConfig.virtual_keyboard && "ontouchstart" in window

`GodotConfig.virtual_keyboard` comes from `GODOT_CONFIG.experimentalVK` in the generated
`index.html`. The engine defaults that to `false` — but `export_presets.cfg` set
`html/experimental_virtual_keyboard=true`, so **the export shipped `experimentalVK:true`**.
On any touch device the engine therefore creates a hidden `<input>` and focuses it; because
`TextEntryService` focuses a real `LineEdit` and `LineEdit.virtual_keyboard_enabled`
defaults to `true`, the platform keyboard raised *on top of* the grid keyboard.

Setting the preset to `false` closes the path at the platform level, so no per-`LineEdit`
change is needed — which also matters practically, since `TextEntryService.gd` is claimed by
`V060-TEXT-ENTRY-SERVICE-2026-08-02`. Confirmed by re-exporting: `index.html` now emits
`"experimentalVK":false`. `scripts/tests/test_web_export_preset.gd` guards it, because the
Godot export dialog rewrites that file wholesale and would silently revert the decision.

## Consequences to record deliberately

- **The touch density tokens do not survive the keyboard intact.** 7 columns at 44px with
  the authored gap 8 and gutter 16 is 388px and overflows 360; it needs gap 4 and gutter 8.
  Either the keyboard is a named exception to the touch token set or the tokens gain a
  compact variant. It must not land as an undocumented local override — which is the thing
  the token system exists to prevent.
- **Landscape is not a different answer.** At 852×393 the band is 177px, which takes three
  44px rows: enough for 26 letters at 13 wide plus a function row. It needs its own
  arrangement, not a different decision.

## Sources

- Goodman, Venolia, Steury & Parker, *Language Modeling for Soft Keyboards*, IUI 2002 —
  the 1.67–1.87× figure.
- Hellsten et al., *Mobile Keyboard Input Decoding with Finite-State Transducers*,
  arXiv:1704.03987 — the 8–9% per-letter error rate, the per-key Gaussian spatial model,
  and the literal/OOV path.
- Gunawardana, Paek & Meek, *Usability Guided Key-Target Resizing for Soft Keyboards*,
  IUI 2010 — anchored key targets and the over-resizing failure mode.
- Holz & Baudisch, *The Generalized Perceived Input Point Model*, CHI 2010 — the 67%
  systematic-offset result.
