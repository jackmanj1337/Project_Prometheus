#!/usr/bin/env node
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { menu_scale: "2.0", content_scale: "2.0" });
  const notes = [];
  let session;
  try {
    session = await boot({ url, viewport: { width: 560, height: 900 } });
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await clickSuffix(page, "/SettingsButton");
    await waitForScreen(page, "settings");
    await page.screenshot({ path: path.join(OUT, "00-top.png") });

    // Corrected thumb position, read from a pixel crop of the actual screenshot:
    // the gold bar sits at roughly x=513-518, y=61-152 at this window size/scale.
    const dragX = 516;
    await page.mouse.move(dragX, 100);
    await page.mouse.down();
    await settle(page);
    await page.mouse.move(dragX, 400, { steps: 15 });
    await settle(page);
    await page.screenshot({ path: path.join(OUT, "01-mid-drag.png") });
    await page.mouse.move(dragX, 848, { steps: 15 });
    await settle(page);
    await page.mouse.up();
    await settle(page);
    const after = await bridge.snapshot(page);
    await page.screenshot({ path: path.join(OUT, "02-after-drag.png") });
    await writeFile(path.join(OUT, "02-after-drag.json"), `${JSON.stringify(after, null, 2)}\n`);
    const exportEntry = Object.entries(after.rects ?? {}).find(([p]) => p.endsWith("BtnExportDiagnostics"));
    const backEntry = Object.entries(after.rects ?? {}).find(([p]) => p.endsWith("/BtnBack"));
    notes.push(`Export Diagnostics rect after drag: ${JSON.stringify(exportEntry)}`);
    notes.push(`Back rect after drag: ${JSON.stringify(backEntry)}`);
    const visible = exportEntry && exportEntry[1].y >= 0 && exportEntry[1].y <= 900;
    notes.push(`Export Diagnostics visible on-screen after corrected drag: ${visible}`);
  } catch (error) {
    notes.push(`FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log(notes.join("\n"));
    await teardown(session);
  }
}
main();
