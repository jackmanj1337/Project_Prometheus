#!/usr/bin/env node
// Gap 2: standard font on HUD, Map Menu and Prep, no pack-font active.
// migration-v2.zip declares no font of its own (verified: no "font" key anywhere
// in its unzipped manifest), so playing its single-map skirmish shows the game's
// STANDARD font on every screen -- the same precedent the checklist states for
// internal.zip on Load Game in section 1C.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import {
  buildUrl, clickSuffix, clickSuffixWithScrollFallback, importPack,
  openNewGame, readEntries, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

async function shot(page, name) {
  const s = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${name}.png`) });
  await writeFile(path.join(OUT, `${name}.json`), `${JSON.stringify(s, null, 2)}\n`);
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
    await importPack(page, PACK);
    await openNewGame(page);
    const entries = await readEntries(page);
    console.log("offered:", entries.offered.map((e) => e.campaign_id));
    const campaignId = entries.offered[0].campaign_id;
    await selectCampaign(page, campaignId);
    await clickSuffixWithScrollFallback(page, "/BtnStart");
    const afterStart = await bridge.snapshot(page);
    if (afterStart.screen === "prep") {
      await shot(page, "01-prep-standard-font");
      await clickSuffixWithScrollFallback(page, "/BeginButton");
      await waitForLiveMap(page);
    } else {
      console.log("no Prep screen for this pack; screen is", afterStart.screen);
    }
    await shot(page, "02-hud-standard-font");
    await page.keyboard.press("m");
    await waitForScreen(page, "map-menu");
    await shot(page, "03-map-menu-standard-font");

    const active = await bridge.snapshot(page);
    await writeFile(path.join(OUT, "activePackage.json"), `${JSON.stringify(active.activePackage, null, 2)}\n`);
    console.log("activePackage while playing migration-v2:", JSON.stringify(active.activePackage));
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
