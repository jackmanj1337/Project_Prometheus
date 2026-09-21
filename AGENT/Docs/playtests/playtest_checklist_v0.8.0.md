---
Role: dated
Type: playtest
Status: Ready - feature round
Last verified: 2026-09-21
---

# v0.8.0 Windows Tester Checklist

**This round is different from every round before it.** v0.7.x rounds asked you to
confirm that a fixed game still worked on real hardware. This one asks you to judge a
**new player-facing surface**: the game no longer knows what a weapon triangle is, and
every combat relationship you see is now *authored data* that a campaign declares and
the game reads back to you by name.

Container tests and browser gates are supplemental. This pass is for native Windows
display, GPU, window-manager, input, visual, accessibility and playability evidence,
plus the judgement calls in Section 7. Return this checklist, the diagnostics ZIP and
defect screenshots.

**Tuning is out of scope and always will be** (owner ruling 2026-09-05). Do not report
whether +5 damage is too much, whether a chapter is too hard, or how the damage curve
feels. Those variables belong to the campaign author, not the engine. Report whether
the number the game *shows* you is the number it *used*, and whether you could tell
*why* — that is what this round is measuring.

---

## Section 0 — Start in this order

1. Verify `BUILD_INFO.json` and `SHA256SUMS.txt`. Launch the supplied release
   executable once and keep the supplied Godot user-data location unchanged.
2. Confirm the Main Menu version label reads **v0.8.0**. If it reads anything else,
   stop and report — the build stamp and the label are meant to agree.
3. With a clean profile and no saves, use **Main Menu → Manage Library → New Game** to
   confirm the empty state; open **Load Game** and verify its empty state is clear.
4. From **Main Menu → Manage Library**, import `free-roam.zip`. Do not edit or re-zip
   any supplied archive.
5. Read `screenshot-album-reference/README.md` beside this checklist before starting Section
   2. Four labelled reference images are in that folder, captured from this exact build in
   a real browser; the file to compare against is named in each check. The map art in them
   is software-rendered and will not match your build — judge the forecast panel.

---

## Section 1 — What changed since v0.7.19, in plain terms

Read this before testing. It is the round's premise, not a checklist.

**The headline.** The weapon triangle used to be a hardcoded table inside the engine and
a fixed sentence on the attack forecast. Both are **deleted**. In their place, a
campaign authors a list of *interaction profiles*, each naming itself, and the attack
forecast grows **one row per relationship that actually fired**. The shipping Proving
Grounds campaign now authors its own triangle as data — twenty rules — plus weapon
effectiveness. You should be unable to tell from play that anything moved; the numbers
are the same ones v0.7.19 produced. **That is the first thing to check.**

**What is genuinely new to see.**

| Change | Where you meet it |
|---|---|
| Named rows on the attack forecast | Every attack forecast, whenever a relationship applies |
| A magic triangle that actually works | Dark / Fire / Light / Thunder / Wind weapons |
| More Info text generated from the authored data | Click a forecast row |
| Suspend/resume no longer strands a failed save's content | Section 5 |
| New Game remembers the exact *build*, not just the version | Section 5 |
| The campaign editor saves all-or-nothing | Section 6 |

**Numbers the base campaign authors.** Weapon triangle advantage is **+10 Hit, +2 Dmg**
and disadvantage is **-10 Hit, -2 Dmg**. Effectiveness multiplies might by **x3**, and
the `giantkiller` rule by **x4** — but nothing in either pack can trigger effectiveness,
so you will not see it. These match v0.7.19's behaviour exactly; they are just no longer
written in the engine.

**The editor shipped in v0.7.19 and was never opened.** Section 6 exists so that does
not happen twice.

---

## Section 2 — The forecast readout (first-party content)

This section uses only `free-roam.zip` — no internal content. A row reads:

```
<glyph> <Relationship name>  <the terms it contributed>
```

for example `▼ Weapon Triangle  -10 Hit, -2 Dmg`. The glyph is ▲ when the relationship
helps that side's strike, ▼ when it hurts it, ± when it does both at once and ■ when it
applies something with no number attached. Rows are coloured: green helps, red hurts.

**A relationship shows on both sides of the panel.** The same weapon triangle that
penalises the attacker is a bonus for the defender, so one forecast carries two rows —
one under each combatant. That is the first thing to look at.

- [ ] **Compare against `screenshot-album-reference/01-weapon-triangle-both-sides.png`.** On
  Chapter 1 (*The Drill Yard*), attack the Training Dummy with **Unit_02** (Iron Sword).
  The dummy carries an Iron Lance. The panel shows
  **▼ Weapon Triangle  -10 Hit, -2 Dmg** in red under Unit_02, and
  **▲ Weapon Triangle  +10 Hit, +2 Dmg** in green under the dummy.
- [ ] **Compare against `screenshot-album-reference/02-no-relationship.png`.** Attack the same
  dummy with **Unit_01** (Iron Lance) instead. Lance against lance is no relationship:
  **no interaction row appears at all** and the panel is shorter. A row reading "Neutral",
  or an empty line where a row would be, is a defect.
- [ ] **The numbers add up.** In the first check, the Hit and Dmg figures at the top of
  each column already include that side's row. If a row says -2 Dmg and the total did not
  move by 2, that is the most serious defect this round can produce — screenshot the whole
  panel.
- [ ] **Magic triangle.** With mage units, confirm Fire/Thunder/Wind/Light/Dark oppose one
  another and each reads as a **Weapon Triangle** row with the same ±10/±2. Record any
  pairing that produces no row where you expected one, naming both weapons.
- [ ] **More Info.** Click a forecast row. The explanation names the relationship and the
  rule that fired, and describes *this* fight. It must not be a generic sentence about
  weapon triangles in the abstract — the old hardcoded sentence was factually wrong about
  the table it claimed to describe, which is why it was removed.
- [ ] **Keyboard and controller.** Every interaction row is reachable and its More Info
  openable without a mouse. Rows are created at runtime, so focus order is the check.
- [ ] **Scaling and clipping.** Repeat the first check at 1280×720, 1920×1080 and a window
  under 600 px wide, and at menu/content scale 0.5 and 2. The row must not clip, truncate
  mid-number, or overlap the Hit/Dmg/Crit figures. There is no reference image for the
  narrow case — compare against `01` and describe what you see.

**Not in scope this round: weapon effectiveness.** It is authored and it ships, but no
content in either pack can trigger it, so there is nothing to test. See the
`screenshot-album-reference/README.md` for why, and do not record it as a failure.

---

## Section 3 — The authored-relationship proof (internal pack)

⚠️ **`proving-grounds-internal-fe.zip` is INTERNAL-ONLY CONTENT.** It must not be
redistributed, posted, streamed or included in any public build or video. It exists to
prove the system can express a relationship the engine has never heard of. Delete your
copy when the round closes.

Import it through **Manage Library** exactly as any other pack. It installs alongside
`free-roam.zip`; both may be present.

This pack authors **five** relationships, and the interesting one is a weapon that sits
at two places in the hierarchy at once: the **Hallowed Scythe** is an *axe* for weapon
rank, weapon experience and the physical triangle, and *light* for the magic triangle.
The engine has no concept of "hallowed" anywhere in its code.

**The A/B is already set up for you.** The party carries two level-3 fighters with
identical stats — **Hallowed Bearer** (Hallowed Scythe) and **Free Company Axeman**
(Iron Axe). Chapter 6, *The Hallowed Ground*, pins both onto the field. Their only
difference is the weapon.

- [ ] Play the campaign to **Chapter 6**. Both units must be present and deployable;
  record it as blocked if either is missing rather than editing the pack.
- [ ] **Confirm they are still identical.** Open both unit panels and record the figures
  below. They level and take damage across five chapters, so if they have drifted apart,
  say so — the comparison below stops being attributable to the weapon and everything
  after it is void.

  | | Hallowed Bearer | Free Company Axeman |
  |---|---:|---:|
  | Max HP / current HP | | |
  | Str / Skill / Spd | | |
  | Def / Res | | |
  | Level | | |

- [ ] **Compare against `screenshot-album-reference/03-hallowed-rites-bearer.png`.** Attack a
  **Revenant** with the Hallowed Bearer. The panel shows **▲ Hallowed Rites  +5 Dmg** in
  green, and the reference reads **Dmg 15**.
- [ ] **Compare against `screenshot-album-reference/04-undead-frailty-control.png`.** Attack the
  **same Revenant** with the Free Company Axeman. It shows **▲ Undead Frailty  +1 Dmg**
  instead, no Hallowed Rites row, and the reference reads **Dmg 12**.
- [ ] **The suppression.** Notice what the bearer's forecast does *not* say: no **Undead
  Frailty** row, even though the target is undead and the axeman got one. The hallowed
  relationship deliberately suppresses it. **Judgement needed — see 7.3.**
- [ ] **Record both readings.** The bearer's Dmg must be strictly greater than the
  axeman's against the same target.

  | | Hit | Dmg | Crit | Rows shown |
  |---|---:|---:|---:|---|
  | Hallowed Bearer → Revenant | | | | |
  | Free Company Axeman → Revenant | | | | |

- [ ] **The condition outlives the forecast.** Land a hit with the Hallowed Bearer. The
  Revenant gains **Hallowed Sear** (-3 Resistance, 2 phases). Confirm it appears on the
  target's panel, ticks down at phase start, and expires. A combat term dies with the
  forecast that computed it; this one is written into the fight's committed transaction
  and must survive it. There is no reference image for this — describe what you see.
- [ ] **Suspend & Quit mid-chapter, Continue, and re-check.** Hallowed Sear's remaining
  duration and the two units' stats survive the round trip.
- [ ] **The magic side.** The pack also authors a five-way elemental relationship
  (±15 Hit, ±3 Dmg) separate from the base triangle. If a chapter fields mages, confirm a
  row reading **Elemental Magic Triangle** and that it is a *different row* from Weapon
  Triangle rather than replacing it.

## Section 4 — Native diagnostics and window evidence

- [ ] The session header identifies v0.8.0, the executable, Windows platform, GPU,
  displays, DPI/refresh, live window mode/size and content scale.
- [ ] **Export Diagnostics** or `Ctrl+Shift+F12` produces a readable diagnostics ZIP
  containing logs, settings, pack manifests, save-slot documents and its contents
  manifest. Return it with this checklist.
- [ ] The diagnostics log records the resolved interaction rows for fights you ran.
  Do not transcribe them into this checklist — the build measures, you judge.
- [ ] A popup/confirmation dialog is fully visible and usable with keyboard or
  controller; fullscreen/normal-size recovery leaves no stale clipping or lost focus.
- [ ] Below 600 px wide, Settings labels stack above controls without clipping; slider
  trough, fill, endcaps and thumb remain visible at 0%, 50% and 100%.

---

## Section 5 — Saves, packs and identity

Two fixes here are about *two builds of the same pack version* being installed at once,
which the Campaign Library has allowed since the fingerprint change.

- [ ] **Suspend/resume rollback.** Suspend & Quit inside a battle, then Continue.
  Content, party and node all return. Previously, a resume that activated a save's
  content and *then* refused could leave the failed save's pack active over your
  previous session — if any refusal message appears, record what was active afterwards.
- [ ] **New Game remembers the build.** Import `free-roam.zip`, start a New Game,
  return to the Library, and confirm the campaign it pre-selects next time is the one
  you actually used. Where two builds share an id and version, the rows show a short
  fingerprint to tell them apart.
- [ ] Empty-profile Load Game is clear; the changed-save confirmation restores focus,
  cancel preserves the original row and bytes, and import stays reachable.
- [ ] Restore `campaign_backup_v2.zip`. Its slots revalidate, share the expected pack
  identity and return to the correct campaign/Prep node.
- [ ] Import migration v1/v2 and exercise the supplied saves. Refusals name missing or
  mismatched content in player-facing language, not only an internal id.
- [ ] A save carrying a condition (Hallowed Sear is the easy one) reloads with that
  condition intact; a save naming a condition the active pack does not define is
  refused with a readable message rather than loading half-formed.

---

## Section 6 — The campaign editor (shipped in v0.7.19, never opened)

The editor has never been in front of a human. Do not audit it feature by feature —
**open it, try to author something small, and report what stopped you.** Thirty minutes
is enough.

- [ ] The editor opens from the Main Menu and its workspaces (tree, inspector, map
  canvas, graph, assets, test) are reachable.
- [ ] Create or open a pack, change one value, and save. Confirm the tab shows unsaved
  state until the save actually lands — a clean tab over bytes the disk never took is
  the specific defect this round fixed.
- [ ] Force a failure if you can (read-only folder, disk full, invalid value) and
  confirm the pack on disk is either fully updated or fully unchanged, never partial,
  and that Undo still works afterwards.
- [ ] Author an interaction profile if the editor exposes one, and report plainly
  whether you could work out how to without reading any documentation.

---

## Section 7 — Judgement calls

These are the questions only a person can answer. **Answer in prose. There are no right
answers, and "I could not tell" is a real and useful result.** None of them is about
tuning.

**7.1 — Did you notice the rows at all?** Play normally for a while before hunting for
them. Did the named relationship rows register as information you used to make a
decision, or as decoration you scrolled past? Say honestly if you ignored them.

**7.2 — Could you tell *why* a number changed?** When Hit or Dmg differed from what you
expected, did the panel tell you the reason without you clicking anything? If you had
to click More Info to understand, say so — the row is supposed to carry the answer.

**7.3 — Is a *missing* row readable?** The bearer's forecast omits Undead Frailty
because Hallowed Rites suppresses it. Nothing on screen says so. Did that read as
correct, as a bug, or did you simply not notice? This is the single design question
this round most needs answered.

**7.4 — Do the names carry their meaning?** "Weapon Triangle", "Weapon Effectiveness",
"Undead Frailty", "Hallowed Rites", "Elemental Magic Triangle" are all author-chosen and
can be anything. Did they read as the game's own language, or as internal labels leaking
onto the screen?

**7.5 — How many rows is too many?** The panel grows one row per relationship, and the
internal pack authors five. At what point did the forecast stop being scannable? Name
the number of rows where it turned.

**7.6 — Is the game any good right now?** The standing question every round. Answer it
about playability, feel, clarity and polish — not difficulty.

---

## Section 8 — Return package and closeout

- [ ] Return the completed checklist, the diagnostics ZIP, screenshots for every
  defect, and any save or fixture needed to explain a failure.
- [ ] State Windows version, GPU/display, build stamp, which sections you ran, where
  you stopped, and anything you could not reproduce.
- [ ] Confirm you have deleted your copy of the internal FE pack.
- [ ] Native acceptance stays pending until this evidence is reviewed. Do not mark it
  passed from the automated gates — those are supplemental and prove nothing about a
  real display.

**If you run out of time, do Sections 2, 3 and 7 and skip the rest.** Those three are
the reason this round exists.
