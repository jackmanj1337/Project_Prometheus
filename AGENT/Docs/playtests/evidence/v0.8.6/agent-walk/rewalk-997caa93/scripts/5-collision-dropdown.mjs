#!/usr/bin/env node
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
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
    await page.waitForTimeout(400);
    await importPack(page, P("collision-b.zip"));
    await page.waitForTimeout(400);
    await clickSuffix(page, "/CampaignLibraryButton");
    await waitForScreen(page, "campaign-library");
    await page.waitForTimeout(600);
    // Open the OptPackage dropdown to reveal both entries.
    let observed = await bridge.snapshot(page);
    const opt = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("/OptPackage"));
    if (opt) {
      const [, rect] = opt;
      await page.mouse.click(rect.x + rect.w / 2, rect.y + rect.h / 2);
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(OUT, "dropdown-open.png") });
      observed = await bridge.snapshot(page);
      await writeFile(path.join(OUT, "dropdown-open.json"), `${JSON.stringify(observed, null, 2)}\n`);
      console.log("after opening dropdown:", JSON.stringify(
        Object.entries(observed.rects ?? {}).filter(([, r]) => r.text).map(([p, r]) => [p, r.text]),
        null, 2,
      ));
    } else {
      console.log("OptPackage control not found");
    }
  } catch (error) {
    console.error("FAILED:", error.stack ?? error.message);
    process.exitCode = 1;
  } finally {
    await teardown(session);
  }
}
main();
