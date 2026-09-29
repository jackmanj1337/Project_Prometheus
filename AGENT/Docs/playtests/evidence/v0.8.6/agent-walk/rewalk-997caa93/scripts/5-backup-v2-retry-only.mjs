#!/usr/bin/env node
// Minimal, isolated: restore campaign_backup_v2.zip alone, Retry its row, Load into Prep.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickPathPart, clickSuffix, entryByPathPart, openLoadGame, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, BACKUP, OUT] = process.argv;

let stepIndex = 0;
async function step(page, label, fn) {
  stepIndex += 1;
  const stem = `${String(stepIndex).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const result = await fn();
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${stem}.png`) });
  await writeFile(path.join(OUT, `${stem}.json`), `${JSON.stringify({ label, result: result ?? null, screen: observed.screen }, null, 2)}\n`);
  console.log(`  [${stem}] ${label}`);
  return { result, observed };
}
async function uploadThrough(page, suffix, file) {
  const chooser = page.waitForEvent("filechooser");
  await clickSuffix(page, suffix, { settleAfter: false });
  await (await chooser).setFiles(file);
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { content_scale: "1.0", menu_scale: "1.0" });
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, "boot main menu", async () => waitForScreen(page, "main-menu"));
    await step(page, "open Manage Library", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
    });
    await step(page, "restore campaign_backup_v2.zip", async () => {
      await uploadThrough(page, "/BtnRestore", BACKUP);
      await page.waitForFunction(
        (name) => Object.entries(JSON.parse(window[name]?.state ?? "{}").rects ?? {}).some(([p, r]) => p.endsWith("/OptPackage") && Boolean(r.text)),
        bridge.BRIDGE_GLOBAL, { timeout: 30000 },
      );
    });
    await step(page, "dismiss restore result", async () => { await page.keyboard.press("Enter"); await settle(page); });
    await step(page, "back to Main Menu", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });
    const before = await step(page, "open Load Game", async () => {
      await openLoadGame(page);
      const observed = await bridge.snapshot(page);
      return Object.entries(observed.rects ?? {}).filter(([p]) => p.endsWith("/LoadButton")).map(([p, r]) => [p, r.text]);
    });
    console.log("rows:", JSON.stringify(before.result));
    const slotMatch = before.result[0]?.[0]?.match(/\/Row_([^/]+)\//);
    const slot = slotMatch ? slotMatch[1] : "node-00-drill-prep-1789157303583";
    await step(page, `Retry ${slot}`, async () => {
      await clickPathPart(page, `/Row_${slot}/`, "/RetryButton");
      await page.waitForTimeout(300);
      await page.keyboard.press("Enter");
      await settle(page);
    });
    const retried = await step(page, `read ${slot} after Retry`, async () => {
      const observed = await bridge.snapshot(page);
      return entryByPathPart(observed, `/Row_${slot}/`, "/LoadButton")[1];
    });
    console.log("after retry:", JSON.stringify(retried.result));
    await step(page, `Load ${slot} -> Prep`, async () => {
      await clickPathPart(page, `/Row_${slot}/`, "/LoadButton");
      await waitForScreen(page, "prep");
    });
  } finally {
    await teardown(session);
  }
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
