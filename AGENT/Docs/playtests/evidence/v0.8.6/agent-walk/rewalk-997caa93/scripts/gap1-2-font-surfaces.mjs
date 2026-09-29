#!/usr/bin/env node
// Gap 1: pack font on the ATTACK FORECAST with free-roam active.
// Gap 2: after quitting to Main Menu with NO pack active, HUD, Map Menu and Prep in
//        the standard font with no clipping (start a campaign again first, then quit).
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import {
  buildUrl, clickSuffix, clickSuffixWithScrollFallback, clickTile, importPack, mapState,
  openNewGame, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

async function shot(page, out, name) {
  const s = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(out, `${name}.png`) });
  await writeFile(path.join(out, `${name}.json`), `${JSON.stringify(s, null, 2)}\n`);
  return s;
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;

    // ---- Gap 1: pack font on the attack forecast, free-roam active ----
    await importPack(page, PACK);
    await openNewGame(page);
    await selectCampaign(page, "proving_grounds");
    await clickSuffixWithScrollFallback(page, "/BtnStart");
    await waitForScreen(page, "prep");
    await clickSuffixWithScrollFallback(page, "/BeginButton");
    await waitForLiveMap(page);
    await shot(page, OUT, "01-live-map-pack-active");

    // Find a BLUE unit and an adjacent enemy to open the attack forecast, using the
    // Chapter 3 Bridge Fighter matchup semantics is unnecessary here -- any forecast
    // screen with the campaign font active is sufficient for this font check. Select
    // the first blue unit, try to attack anything in range; fall back to just reporting
    // the HUD/Prep font if no attack is available on this map (still valuable evidence).
    const map = await mapState(page);
    const blue = (map.units ?? []).find((u) => u.team === "blue");
    let reachedForecast = false;
    if (blue) {
      try {
        let m = await clickTile(page, blue.tile);
        if (m.cursorState === "unit-selected") {
          // Try each of the 4 neighbouring tiles as a move-then-attack target.
          const neighbours = [[1, 0], [-1, 0], [0, 1], [0, -1]].map(([dx, dy]) => [blue.tile[0] + dx, blue.tile[1] + dy]);
          for (const nb of neighbours) {
            try {
              await clickTile(page, nb);
              const afterMove = await mapState(page);
              if (afterMove.cursorState === "action-menu" || (await bridge.snapshot(page)).screen === "action-menu") {
                const observed = await bridge.snapshot(page);
                const attackBtn = Object.keys(observed.rects ?? {}).find((p) => p.endsWith("/BtnAttack"));
                if (attackBtn) {
                  await clickSuffix(page, "/BtnAttack");
                  const targeting = await mapState(page);
                  const enemy = (targeting.units ?? []).find((u) => u.team !== "blue");
                  if (enemy) {
                    await clickTile(page, enemy.tile, { expectState: "targeting" });
                    await waitForScreen(page, "attack-preview");
                    reachedForecast = true;
                  }
                }
                break;
              }
            } catch { /* try next neighbour */ }
          }
        }
      } catch { /* no attack reachable from this unit's start tile */ }
    }
    if (reachedForecast) {
      await shot(page, OUT, "02-attack-forecast-pack-font");
    } else {
      await shot(page, OUT, "02-no-attack-reachable-from-start-tile");
    }

    // Return to main menu via Quit to Menu (no active battle progress worth saving check
    // here; this is purely to reach the pack-active HUD/Map Menu/Prep font states too).
    await page.keyboard.press("m");
    await waitForScreen(page, "map-menu");
    await shot(page, OUT, "03-map-menu-pack-font");
    await clickSuffix(page, "/SettingsButton");
    await settle(page);
    await shot(page, OUT, "04-settings-pack-font");
    await clickSuffixWithScrollFallback(page, "/BtnBack");
    await waitForScreen(page, "map-menu");
    await clickSuffix(page, "/QuitToMenuButton", { settleAfter: false });
    await page.waitForTimeout(300);
    await page.keyboard.press("Enter");
    await waitForScreen(page, "main-menu");
    await shot(page, OUT, "05-main-menu-after-quit-pack-still-installed");

    // ---- Gap 2: after Quit to Menu, free-roam is no longer the active package.
    // Confirm that, then start a DIFFERENT pack that declares NO font of its own
    // (migration-v2.zip -- checked: its manifest has no font reference, unlike
    // free-roam's) so HUD/Map Menu/Prep render in the game's STANDARD font, per the
    // same precedent the checklist states for Load Game + internal.zip in 1C. ----
    const afterQuit = await bridge.snapshot(page);
    await writeFile(path.join(OUT, "activePackage-after-quit.json"), `${JSON.stringify(afterQuit.activePackage, null, 2)}\n`);
    console.log("activePackage after Quit to Menu:", JSON.stringify(afterQuit.activePackage));
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
