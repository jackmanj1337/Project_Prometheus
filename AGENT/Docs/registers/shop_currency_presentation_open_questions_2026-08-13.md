---
Type: register
Status: OPEN — CUR-1..7 drafted with recommendations; owner walk pending
Last verified: 2026-08-13
Register: CUR-1..7
Tracker: SHOP-TRANSACTION-WIREFRAMES-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Shop Currency Presentation — Owner Questions

Raised by holding [`SHC-6`](shop_header_condensation_open_questions_2026-08-12.md) on
2026-08-13: a single wallet figure in the app bar assumes gold is accepted at every store.

## The finding: only the UI assumes gold

The engine has never assumed a single universal currency. Verified in code, not inferred:

| Layer | What it already supports |
|---|---|
| `RegistryCatalog.gd:29` | `resource_types` is a **required** registry family — an open registry, so packs add currencies without an engine edit |
| `engine_data/registries/resource_types/` | `party_gold` and `unit_gold` ship as *entries*, not as built-in concepts. Each carries `label_key` (localized), `kind: "wallet"`, `primitive_handler`, `subjects`, `save_fields` |
| `CostSpec.gd` | Every cost carries its own `resource_id` **and** `scope`; `# Positive amounts spend a resource; negative amounts credit it` |
| `ResourceLedger.quote/commit` | Take an **array** of costs, so one operation can spend several resources against several wallets, and validate `scope in entry.subjects` per cost |
| `ResourceTransaction.gd:7` | `wallets_touched: Array[String]` — plural, by construction |
| `SaveData.gd:260-268` | Migrates legacy `party_gold` into `resources["party_gold"]` — the save model is already a **resource map** |
| `[SHP-1b]` (resolved 2026-06-23) | Prices are resource-keyed and extensible to N currencies, with an explicit instruction **not to enumerate the currency set** |

Against that, `MapMenu.gd:75` reads `format_party_gold(int(gs.party_gold))` and renders one
number. **The assumption lives in one UI call site.** This is the inverted-dependency
anti-pattern the project has recorded before: a generic engine capability narrowed by the
surface that presents it.

`multi_owner_economy_implementation_plan_2026-07-23.md` already rules the adjacent axis —
*whose* wallet — with "HUD resolves the locally viewed/acting controller's configured display
wallet" and "do not merge a storage-only state in which UI, rewards, headers or results still
read `party_gold`". That plan is about **owner**; this register is about **resource kind**.
They are orthogonal and both resolve into the same header slot, which is why the shop needs
an explicit answer rather than a default.

## What is not being asked

- Whether prices are resource-keyed. `[SHP-1b]` settled that.
- Which currencies exist. `[SHP-1b]` explicitly forbids enumerating them; that is pack data.
- Whose wallet is displayed. The multi-owner plan owns that.
- Whether v1 ships more than gold. It need not. These questions are about a UI that does not
  *assume* gold, so a pack that authors a second currency is not a redesign.

## Owner questions

### [CUR-1] Which wallets does the shop show?

- **A — All wallets the party holds.** For: complete. Against: unbounded; five currencies
  cannot fit the Compact app bar, and most are irrelevant to this shop.
- **B — Only the resources this shop's stock actually prices in.** Derived as the union of
  `resource_id` across the visible stock's costs and yields. For: bounded by the shop, needs
  no new authoring, cannot drift from the prices. Against: the set changes when the Buy/Sell
  tab or facet changes, so the header can change shape mid-visit.
- **C — One author-declared primary currency per shop.** For: always exactly one figure.
  Against: a new authored field that can disagree with the prices; wrong the moment an item
  costs two resources.
- **Recommendation: B**, computed once per **visit** from the shop's whole stock rather than
  per tab or facet, so the header does not reshape while browsing.

### [CUR-2] Is "accepted here" authored or derived?

- **A — Derived from the stock's costs.** For: no new schema, no validator, no drift; honours
  `[SHP-1b]`'s "do not enumerate". Against: a shop cannot advertise a currency it has nothing
  priced in.
- **B — Authored per shop.** For: explicit, and supports "we take favours" as flavour.
  Against: a second source of truth to validate against the prices it duplicates.
- **Recommendation: A.** A currency with nothing priced in it is not accepted in any sense the
  player can act on.

### [CUR-3] How does a row show a price in more than one resource?

The list shows final price only (`EPUX-17`), and a row is one line.

- **A — Primary term plus a count.** `Sunder … 6,864 g +1`. For: rows stay one shape.
  Against: "+1" is not a price.
- **B — Two terms inline, overflow to a count.** `6,864 g + 2 ◆`, and `6,864 g +2 more` at
  three or more. For: the common two-resource case is fully readable in the row.
  Against: row width at 360 px, where a long name plus two terms will truncate the name.
- **C — Kind count only, full breakdown in the detail.** `Sunder … 3 costs`. For: never
  truncates. Against: makes the list unscannable, which is what `EPUX-17` optimised for.
- **Recommendation: B.** The detail pane carries the full breakdown either way; the row needs
  to support comparison, and two terms covers the realistic authored case.

### [CUR-4] What does the Compact app bar show when the accepted set is larger than it?

`SHC-1` already put the subject in that bar.

- **A — Fixed count, then overflow.** Show up to two figures, then `+N`. For: predictable bar.
  Against: the hidden one may be the one that matters.
- **B — Show the resources the focused/selected item needs.** For: always the relevant
  figures. Against: the bar changes as focus moves, which is exactly the reflow `SHC-5`'s
  collapse already asks the bar to survive.
- **C — Wallet strip below the bar, present only when the set exceeds one.** For: single
  currency (the common case) costs nothing; multi-currency pays 37 px only when real.
  Against: reintroduces a band the walk just removed — though conditionally.
- **Recommendation: C**, with A's `+N` overflow inside the strip. It keeps the ruled
  single-currency layout untouched and makes the cost proportional to the pack's complexity
  rather than charged to every pack in advance.

### [CUR-5] What does the shortfall reason say when several resources are short?

`SHC-7` put affordability on the rows as disabled-with-reason.

- **A — Generic "cannot afford".** Against: with N currencies the player cannot tell which.
- **B — Name the first shortfall.** `Short 2,266 g`. For: fits a row. Against: fixing it
  reveals a second failure, which reads as the shop moving the goalposts.
- **C — Name every shortfall in the detail, the largest in the row.** For: the row stays one
  line and the detail is complete. Against: "largest" needs a comparison rule across
  resources that have no exchange rate.
- **Recommendation: C**, with "largest" meaning *most short relative to what is held*, and
  every shortfall listed in the detail. `ResourceTransaction` already returns resource-keyed
  `shortfalls`, so this is presentation over data that exists.

### [CUR-6] Is exchange or conversion between currencies a feature?

- **A — Yes, a money-changer surface with rates.** Against: a new system, new authoring, new
  balance surface, and a rate table nobody has asked for.
- **B — No engine feature; it is already expressible.** `CostSpec` credits on negative
  amounts, so "trade 3 ore for 500 gold" is one offer costing `+3 ore` and `−500 gold`. It
  appears in a normal shop list, quotes, commits and reverses like any other transaction.
- **C — No, and forbid it.** Against: nothing to forbid; the primitive is already general.
- **Recommendation: B.** Record it as a known-expressible pattern so nobody builds a
  conversion system for it. Worth one authored example in a demo pack.

### [CUR-7] What happens when a cost is unit-scoped rather than party-scoped?

`unit_gold` ships today with `subjects = ["unit"]`.

- **A — Header always shows party wallets.** Against: an item priced in `unit_gold` is then
  affordable or not for reasons the header never shows.
- **B — Header shows the wallets the visible prices actually draw from**, resolved through
  the current subject, so a unit-scoped price displays that unit's wallet and switching
  shopper changes the figure. For: falls out of `CUR-1(B)` with no extra rule.
  Against: the figure changing on shopper switch needs to be legible as *whose* it is.
- **C — Suppress unit-scoped prices in shops.** Against: removes a shipped capability.
- **Recommendation: B**, with the wallet labelled by owner when it is not the party's —
  which is also what the multi-owner plan requires of every wallet display.

## Consequences if these are taken as recommended

1. `SHC-6` resolves as: **persistent and unabbreviated**, but the slot is a *set* sized by
   `CUR-1(B)`, not a single gold figure — with `CUR-4(C)`'s conditional strip appearing only
   when a pack authors more than one accepted currency.
2. `MapMenu.gd`'s `format_party_gold` becomes a resource-list renderer reading `label_key`
   from the registry entry. That call site is the whole of the gold assumption.
3. No new authoring obligation. Everything above is derived from prices packs already write.

## Next step

Walk `CUR-1..7`, re-ask `SHC-6`, then redraw the album's Compact frames — including a
two-currency case, which the album currently has no frame for.
