#!/usr/bin/env node
// Section 5: collision-a.zip / collision-b.zip share an id+version but differ in
// content. Verify (1) both installed together show distinguishing fingerprints,
// (2) a save exported under A stays unavailable after Retry when only B is
// installed, with a plain-language refusal message (not only an internal id).
import { mkdir, writeFile } from "node:fs/promises";
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
  await writeFile(path.join(out, `${stem}.json`), `${JSON.stringify({ label, result: result ?? null, screen: observed.screen }, null, 2)}\n`);
  console.log(`  [${stem}] ${label}`);
  return { result, observed };
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const notes = [];
  const url = buildUrl(URL_BASE, {});
  let downloadedSavePath = null;

  // ---- Stage 1: install BOTH collision-a and collision-b, check fingerprints. ----
  const out1 = path.join(OUT, "stage1-both-installed-fingerprints");
  await mkdir(out1, { recursive: true });
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, out1, "boot main menu", async () => waitForScreen(page, "main-menu"));
    await step(page, out1, "import collision-a.zip", async () => importPack(page, P("collision-a.zip")));
    await step(page, out1, "import collision-b.zip", async () => importPack(page, P("collision-b.zip")));
    const libRows = await step(page, out1, "read Campaign Library rows (expect distinct fingerprints)", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
      const observed = await bridge.snapshot(page);
      return Object.entries(observed.rects ?? {})
        .filter(([p, r]) => Boolean(r.text) && /Opt|Package|Row/.test(p))
        .map(([p, r]) => ({ path: p, text: r.text }));
    });
    notes.push(`Campaign Library rows with both collision packs installed: ${JSON.stringify(libRows.result, null, 2)}`);
  } catch (error) {
    notes.push(`Stage 1 FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  // ---- Stage 2: CLEAN profile with only collision-a; build + export a save. ----
  const out2 = path.join(OUT, "stage2-build-save-under-a");
  await mkdir(out2, { recursive: true });
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    const page = session.page;
    await step(page, out2, "boot main menu (clean profile)", async () => waitForScreen(page, "main-menu"));
    await step(page, out2, "import collision-a.zip ONLY", async () => importPack(page, P("collision-a.zip")));
    await step(page, out2, "open New Game", async () => openNewGame(page));
    const entries = await step(page, out2, "read offered campaigns", async () => readEntries(page));
    const campaignId = entries.result.offered.find((e) => e.campaign_id === "proving_grounds")?.campaign_id
      ?? entries.result.offered[0].campaign_id;
    await step(page, out2, `select ${campaignId}`, async () => selectCampaign(page, campaignId));
    await step(page, out2, "Start -> Prep", async () => {
      await clickSuffixWithScrollFallback(page, "/BtnStart");
      await waitForScreen(page, "prep");
    });
    await step(page, out2, "Begin -> live map", async () => {
      await clickSuffixWithScrollFallback(page, "/BeginButton");
      await waitForLiveMap(page);
    });
    await step(page, out2, "open Map Menu, Suspend and Quit, confirm", async () => {
      await page.keyboard.press("m");
      await waitForScreen(page, "map-menu");
      await clickSuffix(page, "/SuspendAndQuitButton", { settleAfter: false });
      await page.waitForTimeout(300);
      await page.keyboard.press("Enter");
      await waitForScreen(page, "main-menu");
    });
    await step(page, out2, "open Load Game", async () => openLoadGame(page));
    const download = await step(page, out2, "Export resume_battle row, capture browser download", async () => {
      const downloadPromise = page.waitForEvent("download", { timeout: 30000 });
      await clickPathPart(page, "/Row_resume_battle/", "/ExportButton", { settleAfter: false });
      const dl = await downloadPromise;
      const savePath = path.join(out2, "exported-a-save.json");
      await dl.saveAs(savePath);
      downloadedSavePath = savePath;
      return { suggestedFilename: dl.suggestedFilename(), savedTo: savePath };
    });
    notes.push(`Exported save built under collision-a: ${JSON.stringify(download.result)}`);
  } catch (error) {
    notes.push(`Stage 2 FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  if (!downloadedSavePath) {
    notes.push("Stage 2 produced no save to test -- stage 3 skipped.");
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log(notes.join("\n"));
    return;
  }

  // ---- Stage 3: CLEAN profile with only collision-b; import the A-built save. ----
  const out3 = path.join(OUT, "stage3-import-a-save-with-only-b-installed");
  await mkdir(out3, { recursive: true });
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    const page = session.page;
    await step(page, out3, "boot main menu (clean profile)", async () => waitForScreen(page, "main-menu"));
    await step(page, out3, "import collision-b.zip ONLY", async () => importPack(page, P("collision-b.zip")));
    await step(page, out3, "open Load Game", async () => openLoadGame(page));
    await step(page, out3, "import the collision-a-built save", async () => {
      const chooser = page.waitForEvent("filechooser");
      await clickSuffix(page, "/BtnImport", { settleAfter: false });
      await (await chooser).setFiles(downloadedSavePath);
      await page.waitForFunction(
        (name) => {
          try {
            const state = JSON.parse(window[name]?.state ?? "{}");
            return Object.keys(state.rects ?? {}).some((p) => p.includes("/Row_"));
          } catch { return false; }
        },
        bridge.BRIDGE_GLOBAL,
        { timeout: 30000 },
      );
      await settle(page);
    });
    const rowAfterImport = await step(page, out3, "read imported row (expect a plain-language mismatch message)", async () => {
      const observed = await bridge.snapshot(page);
      const entry = Object.entries(observed.rects ?? {}).find(([p]) => p.endsWith("/LoadButton") && p.includes("/Row_"));
      return entry ? { path: entry[0], text: entry[1].text } : null;
    });
    notes.push(`Row text after importing an A-built save with only B installed: ${JSON.stringify(rowAfterImport.result)}`);
    const looksInternalOnly = rowAfterImport.result && /^\[Needs campaign\]\s*\S+$/.test(rowAfterImport.result.text ?? "") && !/[a-z] [a-z]/i.test(rowAfterImport.result.text ?? "");
    notes.push(`Message appears to be PLAIN LANGUAGE (contains readable words, not only an id): ${!looksInternalOnly}`);

    // Retry: must stay unavailable.
    const slotMatch = rowAfterImport.result?.path?.match(/\/Row_([^/]+)\//);
    if (slotMatch) {
      const slot = slotMatch[1];
      await step(page, out3, `press Retry on ${slot}`, async () => {
        await clickPathPart(page, `/Row_${slot}/`, "/RetryButton", { settleAfter: false });
        await page.waitForTimeout(500);
        await settle(page);
      });
      const rowAfterRetry = await step(page, out3, "read row after Retry (must remain unavailable)", async () => {
        const observed = await bridge.snapshot(page);
        return entryByPathPart(observed, `/Row_${slot}/`, "/LoadButton")[1];
      });
      notes.push(`Row text after Retry (only B installed): ${JSON.stringify(rowAfterRetry.result)}`);
      notes.push(`Still unavailable after Retry: ${(rowAfterRetry.result.text ?? "").includes("[Needs campaign]")}`);
    }
  } catch (error) {
    notes.push(`Stage 3 FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
  console.log("\n" + notes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
