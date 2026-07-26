---
Type: design
Status: Draft - owner review
Last verified: 2026-07-26
Track IDs: RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26
---

# Keyboard Layouts — Implementation Research and a Correction to [TEXT-02]

Second companion to `text_entry_strategy_research_and_questions_2026-07-26.md`. The first
companion (`text_entry_naming_and_sanitization_2026-07-26.md`) covered *what the player may
type*. This one covers *how they type it*: daisywheel, 12-key (T9/multi-tap), and grid
QWERTY — implementation references, and whether to ship more than one and let the player
choose.

**It corrects a headline claim in the filed packet.** [TEXT-02] rests on "a daisywheel is
~2 input actions per character against up to ~12 for the grid QWERTY". The 12 is a fair
*worst case*; the frequency-weighted *mean* is about 4. The daisywheel's real advantage is
roughly **2×, not 6×** — and the strongest counter-evidence is that Valve, who invented the
daisywheel, replaced it with a QWERTY grid.

## 1. The action-count claim, re-derived

The packet cited DaisywheelJS's own comparison. I modelled it instead
(`scratchpad/actions.py`): mean input actions per character, weighted by English letter
frequency, where an "action" is one d-pad press, stick tilt, or button press, and cursor
travel is measured from a frequency-weighted random previous key.

| Scheme | Mean actions/char | 12-char alias |
|---|---|---|
| Grid QWERTY, 4-way d-pad | **4.66** | 56 |
| Grid QWERTY, 8-way d-pad | **4.00** | 48 |
| 12-key multi-tap, 4-way | 3.94 | 47 |
| 12-key multi-tap, 8-way | 3.41 | 41 |
| 12-key predictive, 8-way | 2.23 | 27 |
| **Daisywheel, 8×4** | **2.00** | **24** |
| Theoretical floor (direct select) | 1.00 | 12 |

Worst case for the grid is 9 actions (4-way, `q`→`m`) on the 3-row letter block; with a
number row it reaches 13, so the packet's "~12" is defensible as a worst case. But a text
field is not typed worst-case-repeatedly, and **the mean is what the player experiences.**

This is a geometric model, not a user study. It counts effort, not time — and it explicitly
assumes the daisywheel's stick tilt costs the same as a d-pad press, which flatters the
daisywheel, since an analog tilt-and-settle is slower and less certain than a discrete press.

### What measured throughput actually says

Two studies, both on gamepads:

- **Wilson & Agrawala (Microsoft Research), *Text Entry Using a Dual Joystick Game
  Controller*** — a mean of **6.75 WPM** with under an hour of practice.
- The same work as reported by *Game Developer* — participants went from **5.8 WPM**
  single-stick hunt-and-peck QWERTY to **6.4 WPM** dual-stick split QWERTY: **a ~10% gain**
  for a scheme that doubles the input hardware in play.
- **Sandnes & Aubert, *Bimanual text entry using game controllers*** — same family of result,
  built explicitly on users' existing spatial familiarity with QWERTY.

*(The 6.75 and 5.8→6.4 figures come from different conditions in the literature and I did not
reconcile them; both are cited as reported.)*

The pattern that matters: **gamepad text entry clusters around 6–7 WPM no matter what you
do.** A scheme that halves the action count does not double the throughput, because the cost
is dominated by visual search and target acquisition, not by button presses. This is the
single most important correction to how [TEXT-02] is currently framed — it argues that
**familiarity is worth more than theoretical efficiency**, which is exactly the instinct
behind asking this question.

The *Game Developer* survey states the tension directly: schemes leveraging existing QWERTY
knowledge have a lower learning curve but suboptimal performance, and its author's own
optimised layout provoked user "ire" even while those users typed faster.

## 2. Valve abandoned the daisywheel

The packet treats Steam Big Picture's daisywheel as the reference implementation. It is no
longer Valve's: **Big Picture's daisywheel was replaced by a QWERTY grid**, and the Steam
Deck's OSK is a QWERTY grid too. Community threads from that transition are full of users
asking for the daisywheel back and complaining the QWERTY keypad "seriously takes forever to
type anything" with a controller.

Both halves of that are evidence, and they point in opposite directions:

- Users who learned the daisywheel strongly preferred it — the efficiency claim is real.
- **Valve still removed it**, and every shipping platform — Xbox, PlayStation, Switch,
  Steam Deck — now presents QWERTY by default. Nobody defaults to a wheel.

The reasonable reading is that the daisywheel wins on throughput for a committed user and
loses on first-contact discoverability, and that platform holders optimise for first contact.
A game shipping its own keyboard is not a platform holder and can make the opposite call —
but it should make it knowingly, and it should not make the wheel the *only* option.

**Source-quality caveat:** the removal is documented in Steam community discussions, not in
an official Valve changelog. Treat the fact as well-attested and the date as approximate.

## 3. 12-key: T9 and multi-tap are not the same proposal

This is the part the filed packet does not cover at all, and it splits in two.

### The name is a trademark; the patents are not a problem

"T9" (Text on 9 keys) was developed by Tegic Communications, later Nuance. **The underlying
patents have expired** — the technique is free to implement. **"T9" remains a Nuance
trademark**, so it must not be the user-facing name of a mode or a class in our code. Call it
*Keypad* or *Predictive keypad*. Given how this project handles third-party licensing, that
is worth writing down now rather than renaming later.

### Prediction needs a dictionary, and a dictionary needs a licence

T9 proper is a trie over a word list, ordered by frequency — the algorithm is textbook and
there are many reference implementations; **the code is not the cost, the corpus is.** Two
things follow:

- **Licensing.** Aspell/Hunspell dictionaries are commonly GPL, which this project cannot
  vendor. **SCOWL** is the permissive option — its core 12Dicts component is public domain,
  with some parts under Kuenning's BSD licence, and it ships frequency levels. That is the
  list to use if prediction is ever built.
- **[EXT].** A per-locale word list is a large data dependency that grows with localisation.
  It belongs in the same data-driven registry as the layouts, not compiled in.

### For a *name* field, prediction is structurally useless

T9 predicts words that are in the dictionary. Unit names, weapon aliases, and save labels are
**proper nouns and invented words — precisely the strings no dictionary contains.** On a name
field every entry falls through to multi-tap disambiguation, so the 2.23 actions/char row in
§1 is unreachable and the real figure is the 3.41 multi-tap row.

That guts the case for prediction *for the features we actually have*. Prediction only pays
off if a free-text **search** field returns — and [EPUX-15] cut search on interaction-cost
grounds independent of input, with [TEXT-06] recommending we keep it cut.

**So the honest proposal is multi-tap on a 12-key pad, dictionary-free.** At 3.41
actions/char it is barely better than the 8-way grid's 4.00, while being far less familiar
to anyone under about thirty-five. **I do not recommend building it.**

### The console precedent, which cuts the other way on "let the user pick"

The **PS3** offers *both* a full-size QWERTY keyboard and a **mini keyboard where multiple
characters are assigned to a single key** — phone-style multi-tap, cycling with repeated
Cross presses — switchable via an "Input mode" key, with a **predictive mode that can be
toggled on or off**. Sony shipped exactly the "several layouts, player chooses" model, on a
controller-only console, and kept it for the platform's life.

So the precedent for *offering a choice* is strong. The precedent for *the third option being
a keypad* is weak, because the PS3's keypad was designed when its audience typed on phones
that way daily.

## 4. Implementation references

### Daisywheel — a materially better option than the packet found

The packet's survey concluded no daisywheel implementation was usable, because the only one
found (HauntedBees) is Godot 3.4 under AGPL-3.0 with a bespoke commercial clause. A
daisywheel is a **radial menu with a face-button selection layer**, and searching that way
finds a much better starting point:

| Resource | Engine | Licence | Notes |
|---|---|---|---|
| [jesuisse/godot-radial-menu-control](https://github.com/jesuisse/godot-radial-menu-control) | **Godot 4** | **MIT** | 106★, 36 commits. Explicit gamepad support via `setup_gamepad(device, x_axis, y_axis)` with a 0.2 default deadzone — the exact primitive a daisywheel needs. Submenus supported. Themable. Font is Noto Sans under OFL (attribution required). |
| [KidsCanCode Godot 4 Recipes — Radial Popup Menu](https://kidscancode.org/godot_recipes/4.x/ui/radial_menu/index.html) | Godot 4 | tutorial | Build-it-yourself walkthrough; good for understanding the angle→segment maths without a dependency. |
| [tavurth Godot Radial Menu](https://godotassetlibrary.com/asset/D1NE28/godot-radial-menu) | Godot 4 | open source | Shader-based rendering; performance-oriented. |
| HauntedBees (from the packet) | 3.4 | AGPL + bespoke clause | **Pattern only — do not vendor.** Still the only reference for the 8 petals × 4 face buttons scheme with trigger-switched sets and its ~32-char-per-set cap. |

Known limitations of the radial-menu-control addon, from its own documentation: stacked
radial submenus "don't quite work", and it mis-positions when parented directly to a `Control`
container (workaround: interpose a plain `Node`). Neither blocks a single-ring daisywheel.

This changes [TEXT-08]'s calculus for the wheel specifically: there is now a maintained,
MIT, Godot 4, gamepad-aware radial control to build on, rather than nothing.

### Grid QWERTY — unchanged, plus a Godot focus trap

The packet's survey stands: **greenpixels-onscreen-keyboard** (MIT, Godot 4, controller +
touch) for the signal API shape, **martinfuchs Godot-Onscreen-Keyboard** for the JSON layout
model.

One implementation gotcha worth knowing before the grid is built: **`GridContainer` injects
its own focus handling onto its children even when `focus_neighbor_*` are all explicitly
cleared** ([godot#77729](https://github.com/godotengine/godot/issues/77729)), and Godot's
default focus navigation is *spatial* — nearest focusable control in the pressed direction —
which also misbehaves inside scroll containers
([godot#98445](https://github.com/godotengine/godot/issues/98445)). A keyboard needs exact,
predictable wrapping, so plan on driving focus manually from an `(row, col)` model rather
than leaning on container auto-navigation. The official
[GUI navigation docs](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html)
are the reference. This also interacts with the known
`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND` defect the packet already flagged.

### 12-key — code is trivial, data is not

Trie-based T9 reference implementations are widely available and small
([example](https://github.com/jisooj/T9-Predictive-Text)). If prediction is ever built, the
work is sourcing and shipping a licence-clean frequency list per locale (§3), not writing the
trie.

## 5. The architecture: one registry, three presenters

This is where the answer to "implement all of them?" actually lives, and the project has
already ratified the pattern twice.

The [EXT] open-registry principle says a vocabulary that grows with content must be
data-driven, not a hardcoded `match`. [EPUX-20] and [EPUX-26] resolved the analogous UI
question as **sections plus registered presenters**. A keyboard is the same shape:

- **A layout is data.** A set of key definitions — each with an emitted string or an action
  (`backspace`, `shift`, `switch_layout`, `submit`, `cancel`) — plus grouping metadata:
  `rows` for a grid, `petals` for a wheel, `groups` for a keypad. martinfuchs' JSON model,
  extended with the grouping field, covers all three.
- **A presenter is registered code.** It reads the layout and owns geometry and input
  mapping. `GridPresenter` walks rows with a focus cursor; `WheelPresenter` maps stick angle
  to petal and face button to member; `KeypadPresenter` is `GridPresenter` plus a
  cycle-on-repeat-press key behaviour.
- **The seam between them is one interface** — `character_entered`, `action_invoked`,
  `submitted`, `cancelled` — which is greenpixels' signal shape, and it is what the text
  field binds to. The field never knows which presenter is active.

The payoff is that **adding a third layout is a presenter plus a JSON file, not a rewrite** —
so the decision of *how many to ship* becomes a scheduling decision rather than an
architectural one, and can be deferred without cost. That is the strongest argument for
building this seam even if only the grid ever ships.

The cost is real but bounded: every presenter needs its own Menu Scale 200% pass (a keyboard
is the worst case for UI scaling — the packet already flags this), its own focus/confirm/cancel
verification, and its own localisation story.

## 6. Recommendation

**Ship a choice, but not three, and not at once.**

1. **Grid QWERTY first, as the default.** Every platform defaults to it, the measured
   throughput gap to the alternatives is ~10%, and it is the only layout that works with
   mouse, touch, and the web build. Familiarity is worth more than the model's 2×, because
   §1's literature says the 2× does not convert into 2× throughput.
2. **Daisywheel second, as an opt-in.** The efficiency claim is real for a committed user,
   the Big Picture users who lost it genuinely mourned it, and it is now cheap to build on
   an MIT Godot 4 radial control. It is the reason to have our own keyboard rather than
   shipping only the Steam OSK.
3. **Do not build the keypad.** T9's prediction is structurally useless on a name field
   (§3), and dictionary-free multi-tap saves 0.6 actions/char over the grid while being
   markedly less familiar. Revisit only if free-text *search* is ever restored — and
   [TEXT-06] recommends it should not be.
4. **The player picks, via the setting [TEXT-05] already proposes.** This is the part that
   costs almost nothing: [TEXT-05]'s recommended override is already a three-way
   *in-game / system / assume-hardware* enum. Widening the in-game branch to
   *grid / wheel* is one more enum value and one presenter lookup — **not a new system.**
   Default to auto-detection (grid for mouse/touch, and grid on gamepad too until the wheel
   has shipped and been playtested), with the explicit override.

This keeps [TEXT-02]'s recommendation — both, sequenced, grid first — but replaces its
*reasoning*. The packet recommends the grid first as the "safe default" and treats the
daisywheel as the real prize. The evidence here says the grid is not merely safe, it is
**probably the better default on the merits**, and the daisywheel is a power-user option that
earns its place through preference rather than measured speed.

## 7. Additional owner questions

Extending, not modifying, [TEXT-01]–[TEXT-12].

### [TEXT-13] Does the corrected action model change [TEXT-02]?

- **A — No.** Ship grid then wheel as already recommended; the correction changes only the
  justification.
- **B — Yes, drop the daisywheel.** If the gain is 2× actions and ~10% throughput, and Valve
  removed theirs, the wheel is a lot of work and a second Menu-Scale surface for a preference.
- **C — Yes, invert it** — build the wheel first as the differentiator, grid second.
- **Recommendation: A.** The correction weakens the wheel's *urgency*, not its value, and the
  sequencing already puts the cheap, universal option first. But the owner should decide
  knowing the 6× figure was wrong.

### [TEXT-14] Is the layout registry built now, or when the second layout lands?

- **A — Now**, per [EXT] and §5: one registry, one presenter, one JSON file. Costs a seam we
  would otherwise retrofit.
- **B — Later**: build the grid concretely, extract the registry when the wheel arrives.
- **Recommendation: A.** [EXT] is ratified and this is the textbook case for it, the seam is
  small, and §5's presenter split is what makes "let the player pick" nearly free. B risks the
  hardcoded `match` the principle exists to prevent.

### [TEXT-15] Do we ever ship prediction?

- **A — No, ever.** Rule it out; it saves a per-locale corpus, a licence review, and a
  trademark hazard.
- **B — Not now, but keep the key-action vocabulary able to express it.**
- **Recommendation: B**, at zero cost — the registry's action list simply needs a
  `candidate_select` action reserved. If [EPUX-15]'s search is ever restored, that is the
  trigger to revisit; if it never is, nothing was spent.

## 8. Decision status

Recommendations above are research recommendations unless marked **OWNER RULING**. The walk
ran 2026-07-26 and is **COMPLETE**; [TEXT-13]–[TEXT-15] are ratified, plus one sub-question.

- **TEXT-13 — ratified (A), and merged into [TEXT-02].** The corrected action model changes
  the *justification*, not the sequencing: grid first, wheel second. But the grid is now the
  default **on the merits** rather than as the safe choice, and the wheel is a power-user
  opt-in that earns its place through preference rather than measured speed. The two questions
  were ruled once, as "[TEXT-02] as revised by [TEXT-13]".
- **TEXT-14 — ratified (A: build the registry now), with a scope the question did not ask
  for.** The registry's unit is an **entry mode, not a layout**. `hardware` — draws nothing,
  consumes physical key events — is a **first-class registered presenter**, not the absence of
  one, sitting alongside `grid`, `wheel`, and `system`. This settles "now or later" on merit
  rather than on principle: the registry is not speculative structure for a second layout that
  might never ship, it is **required on day one**, because [TEXT-01] and [TEXT-05] both already
  commit to swapping between in-game, system, and assume-hardware.
- **TEXT-14a — ratified, and folded into [TEXT-05]'s existing setting** rather than becoming a
  second control. One setting, defaulting to input-device detection, where **touch and gamepad
  route to our native keyboard**. That default is also what keeps Deck Verified answerable
  without special-casing the Deck.
- **TEXT-15 — ratified (B).** No prediction now; **reserve a `candidate_select` action** in the
  registry's key-action vocabulary and spend nothing else. If [EPUX-15]'s free-text search is
  ever restored, that is the trigger to revisit; if it never is, nothing was spent. The keypad
  presenter is **not built** — §3's reasoning stands unrebutted.
- **[TEXT-04]'s seam clause lands here too:** the `system` presenter exists in the registry
  from day one with no Steam backend behind it, so the Steam OSK is a drop-in later. Ruled to
  "keep the seam strong and avoid making it harder than it has to be."

### The resulting build

Four presenters behind one signal interface, of which two are near-empty and one is deferred:

| Presenter | Status at v1 | Notes |
|---|---|---|
| `grid` | **Built** | Written by us. Manual `(row, col)` focus model — do not rely on `GridContainer` auto-navigation (§4). |
| `hardware` | **Built** | Draws nothing; consumes physical key events. |
| `system` | **Seam only** | No backend. Steam OSK drops in per [TEXT-04]. |
| `wheel` | **Deferred** | On the MIT radial control per [TEXT-08]. |

Plus: one JSON ASCII layout, one setting defaulting to detection, and a Menu Scale 200% pass
per shipped presenter.

## 9. What was not resolved

- **No independent measurement of the daisywheel on a gamepad.** §1 is my geometric model
  and §1's WPM figures are all QWERTY-variant studies. I found no study measuring a
  daisywheel against a grid on a controller; the closest is a Daisy Wheel evaluation for
  *touch-free* (gesture) interfaces, a different input channel. **The 2× action-count
  advantage is modelled; the throughput advantage is unmeasured in either direction.**
- **The Big Picture daisywheel removal is community-sourced**, not an official Valve
  statement (§2). The fact is well-attested; the date is approximate.
- **The two WPM figures (6.75 vs 5.8→6.4) were not reconciled** — different conditions in the
  literature, reported as found.
- **`jesuisse/godot-radial-menu-control` was not built or run against 4.6.3.** It states
  Godot 4 support and the repo's most recent activity was not established from the page
  fetched. Verify before depending on it.
- **The "T9" trademark status was not verified against a trademark register** — the patents
  are reported expired and Nuance's mark is reported live. Both should be confirmed before
  the name appears in any user-facing string, which is the reason to just not use it.
- **SCOWL's licence was read from its own documentation, not reviewed** against this
  project's ratified licensing decisions. Only matters if [TEXT-15] resolves to A.
