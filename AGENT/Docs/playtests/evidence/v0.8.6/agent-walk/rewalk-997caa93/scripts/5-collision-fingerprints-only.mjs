#!/usr/bin/env node
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, importPack, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, BUNDLE_DIR, OUT] = process.argv;
const P = (name) => path.join(BUNDLE_DIR, name);

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await importPack(page, P("collision-a.zip"));
    await page.waitForTimeout(500);
    await importPack(page, P("collision-b.zip"));
    await page.waitForTimeout(500);
    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    await page.waitForTimeout(800);
    const observed = await bridge.snapshot(page);
    await page.screenshot({ path: path.join(OUT, "both-installed.png") });
    await writeFile(path.join(OUT, "both-installed.json"), `${JSON.stringify(observed, null, 2)}\n`);
    const rows = Object.entries(observed.rects ?? {}).filter(([, r]) => r.text).map(([p, r]) => [p, r.text]);
    console.log(JSON.stringify(rows, null, 2));
  } catch (error) {
    console.error("FAILED:", error.stack ?? error.message);
    process.exitCode = 1;
  } finally {
    await teardown(session);
  }
}
main();
