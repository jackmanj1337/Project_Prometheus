#!/usr/bin/env node
// Section 5 gap: follow the checklist's migration steps exactly.
//   1. Fresh profile, import migration-v1.zip only. Start a v1 map, Suspend & Quit.
//   2. Export that save (real browser download).
//   3. A SEPARATE clean profile with only migration-v2.zip installed. Import the v1
//      save, choose "Import into 2.0.0".
//   4. LOAD the migrated slot and confirm it reaches a live screen.
//   5. Confirm the original (unmigrated) row is unchanged.
import { mkdir, writeFile, readFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import {
  buildUrl, clickPathPart, clickSuffix, clickSuffixWithScrollFallback,
  entryByPathPart, importPack, openLoadGame, openNewGame, readEntries, selectCampaign,
  waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, BUNDLE_DIR, OUT] = process.argv;
const P = (name) => path.join(BUNDLE_DIR, name);

let stepIndex = 0;
async function step(page, out, label, fn) {
  stepIndex += 1;
  const stem = `${String(stepIndex).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const result = await fn();
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(out, `${stem}.png`) });
  await writeFile(path.join(out, `${stem}.json`), `${JSON.stringify({ label, result: result ?? null, screen: observed.screen, modal: observed.modal, focus: observed.focus, rects: observed.rects }, null, 2)}\n`);
  console.log(`  [${stem}] ${label}`);
  return { result, observed };
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const notes = [];
  const url = buildUrl(URL_BASE, {});
  let downloadedSavePath = null;

  // ---- Stage 1: build and export a v1 save. ----
  const out1 = path.join(OUT, "stage1-build-v1-save");
  await mkdir(out1, { recursive: true });
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, out1, "boot main menu", async () => waitForScreen(page, "main-menu"));
    await step(page, out1, "import migration-v1.zip", async () => importPack(page, P("migration-v1.zip")));
    await step(page, out1, "open New Game", async () => openNewGame(page));
    const entries = await step(page, out1, "read offered campaigns", async () => readEntries(page));
    notes.push(`v1 offered campaigns: ${JSON.stringify(entries.result.offered.map((e) => e.campaign_id))}`);
    const preferred = process.env.V086_MIGRATION_CAMPAIGN;
    const campaignId = (preferred && entries.result.offered.find((e) => e.campaign_id === preferred)?.campaign_id)
      ?? entries.result.offered[0].campaign_id;
    await step(page, out1, `select campaign ${campaignId}`, async () => selectCampaign(page, campaignId));
    await step(page, out1, "Start -> Prep", async () => {
      await clickSuffixWithScrollFallback(page, "/BtnStart");
      await waitForScreen(page, "prep");
    });
    await step(page, out1, "Begin -> live map", async () => {
      await clickSuffixWithScrollFallback(page, "/BeginButton");
      await waitForLiveMap(page);
    });
    await step(page, out1, "open Map Menu", async () => {
      await page.keyboard.press("m");
      await waitForScreen(page, "map-menu");
    });
    await step(page, out1, "Suspend and Quit, confirm", async () => {
      await clickSuffix(page, "/SuspendAndQuitButton", { settleAfter: false });
      await page.waitForTimeout(300);
      await page.keyboard.press("Enter");
      await waitForScreen(page, "main-menu");
    });
    await step(page, out1, "open Load Game", async () => openLoadGame(page));
    const rowState = await step(page, out1, "read resume_battle row before export", async () => {
      const observed = await bridge.snapshot(page);
      return entryByPathPart(observed, "/Row_resume_battle/", "/LoadButton")[1];
    });
    notes.push(`v1 resume_battle row before export: ${JSON.stringify(rowState.result)}`);

    const download = await step(page, out1, "click Export on resume_battle row, capture browser download", async () => {
      const downloadPromise = page.waitForEvent("download", { timeout: 30000 });
      await clickPathPart(page, "/Row_resume_battle/", "/ExportButton", { settleAfter: false });
      const dl = await downloadPromise;
      const savePath = path.join(out1, "exported-v1-save.json");
      await dl.saveAs(savePath);
      downloadedSavePath = savePath;
      return { suggestedFilename: dl.suggestedFilename(), savedTo: savePath };
    });
    notes.push(`Exported v1 save: ${JSON.stringify(download.result)}`);
  } catch (error) {
    notes.push(`Stage 1 FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  if (!downloadedSavePath) {
    notes.push("Stage 1 did not produce an exported save file -- stage 2 (migration) cannot run.");
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log(notes.join("\n"));
    process.exitCode = 1;
    return;
  }
  const savedBytes = await readFile(downloadedSavePath);
  notes.push(`Exported save file size: ${savedBytes.length} bytes at ${downloadedSavePath}`);

  // ---- Stage 2: CLEAN profile, only v2 installed, import + Import into 2.0.0, LOAD it. ----
  const out2 = path.join(OUT, "stage2-clean-v2-import-migrate-load");
  await mkdir(out2, { recursive: true });
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } }); // fresh browser context == clean profile
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, out2, "boot main menu (clean profile)", async () => waitForScreen(page, "main-menu"));
    await step(page, out2, "import migration-v2.zip ONLY", async () => importPack(page, P("migration-v2.zip")));
    await step(page, out2, "open Load Game (empty)", async () => openLoadGame(page));
    await step(page, out2, "import the exported v1 save via Import Save...", async () => {
      const chooser = page.waitForEvent("filechooser");
      await clickSuffix(page, "/BtnImport", { settleAfter: false });
      await (await chooser).setFiles(downloadedSavePath);
      await page.waitForFunction(
        (name) => {
          try {
            const state = JSON.parse(window[name]?.state ?? "{}");
            return Object.keys(state.rects ?? {}).some((p) => p.includes("/Row_imported_"));
          } catch { return false; }
        },
        bridge.BRIDGE_GLOBAL,
        { timeout: 30000 },
      );
      await settle(page);
    });
    await step(page, out2, "dismiss the 'imported campaign save' result dialog", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(300);
      await settle(page);
    });
    const rowsBefore = await step(page, out2, "rows after import, before migrating", async () => {
      const observed = await bridge.snapshot(page);
      return Object.entries(observed.rects ?? {})
        .filter(([p]) => /\/Row_[^/]+\/(LoadButton|RetryButton|ManageCampaignsButton|DeleteButton|ExportButton|MigrateButton)$/.test(p))
        .map(([p, r]) => ({ path: p, text: r.text }));
    });
    notes.push(`Stage 2 rows after import, before migrate: ${JSON.stringify(rowsBefore.result, null, 2)}`);
    const importedSlot = rowsBefore.result
      .map((r) => r.path.match(/\/Row_(imported_\d+)\//)?.[1])
      .find(Boolean);
    if (!importedSlot) throw new Error("could not find the imported v1 save row");
    const migrateBtn = rowsBefore.result.find((r) => r.path.includes(`Row_${importedSlot}/`) && r.path.endsWith("/MigrateButton"));
    notes.push(`Migrate button text on imported row: ${migrateBtn ? migrateBtn.text : "(none found -- migration may not be offered)"}`);

    if (migrateBtn) {
      await step(page, out2, `click ${migrateBtn.text} on ${importedSlot}`, async () => {
        await clickPathPart(page, `/Row_${importedSlot}/`, "/MigrateButton", { settleAfter: false });
        await page.waitForTimeout(400);
      });
      const preview = await step(page, out2, "migration preview dialog", async () => {
        const observed = await bridge.snapshot(page);
        return { focus: observed.focus, modal: observed.modal };
      });
      notes.push(`Migration preview dialog: ${JSON.stringify(preview.result)}`);
      await step(page, out2, "confirm migration (Enter)", async () => {
        await page.keyboard.press("Enter");
        await page.waitForTimeout(600);
        await settle(page);
      });
      const rowsAfter = await step(page, out2, "rows after migration confirmed", async () => {
        const observed = await bridge.snapshot(page);
        return Object.entries(observed.rects ?? {})
          .filter(([p]) => /\/Row_[^/]+\/(LoadButton|RetryButton|ManageCampaignsButton|DeleteButton|ExportButton|MigrateButton)$/.test(p))
          .map(([p, r]) => ({ path: p, text: r.text }));
      });
      notes.push(`Stage 2 rows after migration: ${JSON.stringify(rowsAfter.result, null, 2)}`);

      // Identify the ORIGINAL row (imported_XX, unchanged) and the NEW migrated row.
      const originalRow = rowsAfter.result.find((r) => r.path.includes(`Row_${importedSlot}/`) && r.path.endsWith("/LoadButton"));
      const migratedRow = rowsAfter.result.find((r) => !r.path.includes(`Row_${importedSlot}/`) && r.path.endsWith("/LoadButton"));
      notes.push(`Original row after migration: ${JSON.stringify(originalRow)}`);
      notes.push(`Migrated row after migration: ${JSON.stringify(migratedRow)}`);

      const originalBeforeText = rowsBefore.result.find((r) => r.path.includes(`Row_${importedSlot}/`) && r.path.endsWith("/LoadButton"))?.text;
      const originalUnchanged = originalBeforeText === originalRow?.text;
      notes.push(`Original row text before migration: "${originalBeforeText}" -- after: "${originalRow?.text}" -- UNCHANGED: ${originalUnchanged}`);

      if (migratedRow && !migratedRow.text.includes("[Needs campaign]")) {
        const migratedSlotMatch = migratedRow.path.match(/\/Row_([^/]+)\//);
        const migratedSlot = migratedSlotMatch ? migratedSlotMatch[1] : null;
        await step(page, out2, `LOAD the migrated slot ${migratedSlot}`, async () => {
          await clickPathPart(page, `/Row_${migratedSlot}/`, "/LoadButton");
          await Promise.race([
            waitForLiveMap(page),
            waitForScreen(page, "prep"),
          ]);
        });
        const reached = await step(page, out2, "confirm the migrated save reached a live screen", async () => {
          const observed = await bridge.snapshot(page);
          return { screen: observed.screen, mapLive: (observed.map?.units ?? []).length > 0 };
        });
        notes.push(`Migrated slot load result: ${JSON.stringify(reached.result)}`);
      } else {
        notes.push(`Migrated row is NOT loadable (text="${migratedRow?.text}") -- could not perform the LOAD step.`);
      }
    }
  } catch (error) {
    notes.push(`Stage 2 FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
  console.log("\n" + notes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
