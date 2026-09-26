#!/usr/bin/env node
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, clickSuffix, clickSuffixWithScrollFallback, importPack,
  openNewGame, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const URL_BASE = process.argv[2];
const PACK = process.argv[3];
const OUT = process.argv[4];

async function shot(page, out, name) {
  await page.screenshot({ path: path.join(out, `${name}.png`) });
  const observed = await bridge.snapshot(page);
  await writeFile(path.join(out, `${name}.json`), `${JSON.stringify(observed, null, 2)}\n`);
  return observed;
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { content_scale: "2.0", menu_scale: "2.0" });
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await importPack(page, PACK);
    await shot(page, OUT, "00-after-import");
    await openNewGame(page);
    await shot(page, OUT, "01-new-game");
    await selectCampaign(page, "proving_grounds");
    await shot(page, OUT, "02-selected");
    await clickSuffixWithScrollFallback(page, "/BtnStart");
    await shot(page, OUT, "03-after-start-click");
    await waitForScreen(page, "prep");
    await shot(page, OUT, "04-prep");
    await clickSuffixWithScrollFallback(page, "/BeginButton");
    await shot(page, OUT, "05-after-begin-click");
    try {
      await waitForLiveMap(page);
      await shot(page, OUT, "06-live-map");
      console.log("LIVE MAP REACHED");
    } catch (e) {
      await shot(page, OUT, "06-live-map-timeout");
      console.log("TIMED OUT WAITING FOR LIVE MAP:", e.message);
    }
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
