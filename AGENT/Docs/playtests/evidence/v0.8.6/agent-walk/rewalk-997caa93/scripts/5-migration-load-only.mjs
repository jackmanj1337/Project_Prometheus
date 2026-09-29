#!/usr/bin/env node
// Reuse an already-exported v1 save; clean v2-only profile; import, migrate, then
// LOAD the migrated slot and report whatever screen it actually reaches (no fixed
// expectation), plus confirm the original row stays unchanged.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickPathPart, clickSuffix, importPack, openLoadGame, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, BUNDLE_DIR, SAVE_PATH, OUT] = process.argv;
const P = (name) => path.join(BUNDLE_DIR, name);

let stepIndex = 0;
async function step(page, label, fn) {
  stepIndex += 1;
  const stem = `${String(stepIndex).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  let result;
  try {
    result = await fn();
  } catch (error) {
    await page.screenshot({ path: path.join(OUT, `${stem}-FAILURE.png`) }).catch(() => {});
    throw error;
  }
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${stem}.png`) });
  await writeFile(path.join(OUT, `${stem}.json`), `${JSON.stringify({ label, result: result ?? null, screen: observed.screen, map: observed.map }, null, 2)}\n`);
  console.log(`  [${stem}] ${label} -> screen=${observed.screen} mapLive=${(observed.map?.units ?? []).length > 0}`);
  return { result, observed };
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  const notes = [];
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, "boot main menu (clean profile)", async () => waitForScreen(page, "main-menu"));
    await step(page, "import migration-v2.zip ONLY", async () => importPack(page, P("migration-v2.zip")));
    await step(page, "open Load Game", async () => openLoadGame(page));
    await step(page, "import the exported v1 save", async () => {
      const chooser = page.waitForEvent("filechooser");
      await clickSuffix(page, "/BtnImport", { settleAfter: false });
      await (await chooser).setFiles(SAVE_PATH);
      await page.waitForFunction(
        (name) => Object.keys(JSON.parse(window[name]?.state ?? "{}").rects ?? {}).some((p) => p.includes("/Row_imported_")),
        bridge.BRIDGE_GLOBAL, { timeout: 30000 },
      );
      await settle(page);
    });
    await step(page, "dismiss import result dialog", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(300);
      await settle(page);
    });
    const before = await step(page, "read original row before migrating", async () => {
      const observed = await bridge.snapshot(page);
      const entry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("/Row_imported_01/LoadButton"));
      return entry?.[1]?.text;
    });
    await step(page, "click Import into 2.0.0", async () => {
      await clickPathPart(page, "/Row_imported_01/", "/MigrateButton", { settleAfter: false });
      await page.waitForTimeout(500);
    });
    await step(page, "confirm migration (Enter)", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(800);
      await settle(page);
    });
    await step(page, "dismiss the 'migrated a copy' result dialog", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(500);
      await settle(page);
    });
    const rowsAfter = await step(page, "rows after migration", async () => {
      const observed = await bridge.snapshot(page);
      return Object.entries(observed.rects ?? {})
        .filter(([p]) => p.endsWith("/LoadButton"))
        .map(([p, r]) => ({ path: p, text: r.text }));
    });
    notes.push(`Rows after migration: ${JSON.stringify(rowsAfter.result, null, 2)}`);
    const originalAfter = rowsAfter.result.find((r) => r.path.includes("Row_imported_01/"));
    const migratedAfter = rowsAfter.result.find((r) => !r.path.includes("Row_imported_01/"));
    notes.push(`Original row unchanged: ${before.result === originalAfter?.text}`);
    if (migratedAfter) {
      const slotMatch = migratedAfter.path.match(/\/Row_([^/]+)\//);
      const slot = slotMatch[1];
      await step(page, `scroll to and click LOAD on migrated slot ${slot}`, async () => {
        await page.mouse.move(600, 400);
        await page.mouse.wheel(0, 400);
        await settle(page);
        await clickPathPart(page, `/Row_${slot}/`, "/LoadButton", { settleAfter: false });
        await page.waitForTimeout(2000);
        await settle(page);
      });
      // Report whatever screen resulted, polling for up to 20s, without assuming which one.
      let finalScreen = null;
      for (let i = 0; i < 20; i += 1) {
        const observed = await bridge.snapshot(page);
        finalScreen = { screen: observed.screen, mapLive: (observed.map?.units ?? []).length > 0, modal: observed.modal };
        if (observed.screen !== "load-game") break;
        await page.waitForTimeout(1000);
      }
      await page.screenshot({ path: path.join(OUT, "final-screen-after-load.png") });
      notes.push(`Final screen after clicking LOAD on the migrated slot: ${JSON.stringify(finalScreen)}`);
    } else {
      notes.push("No migrated row appeared -- migration did not create a new row.");
    }
  } catch (error) {
    notes.push(`FAILED: ${error.stack ?? error.message}`);
  } finally {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log("\n" + notes.join("\n"));
    await teardown(session);
  }
}
main();
