#!/usr/bin/env node
// Section 5 (+ 1C, done at the point the checklist says to): campaign_backup_v2 restore,
// Load Game with mixed loadable/not-loadable rows, migration and collision packs, the
// four confirmation dialogs, and Settings below 600px / at 0.5x and 2x.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "./lib/bridge.mjs";
import { assertClipAwareBridge } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";
import {
  buildUrl, clickPathPart, clickSuffix, clickSuffixWithScrollFallback,
  entryByPathPart, importPack, openLoadGame, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, BUNDLE_DIR, OUT] = process.argv;
const P = (name) => path.join(BUNDLE_DIR, name);

let stepIndex = 0;
async function step(page, label, fn) {
  stepIndex += 1;
  const stem = `${String(stepIndex).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const result = await fn();
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${stem}.png`) });
  await writeFile(path.join(OUT, `${stem}.json`), `${JSON.stringify({ label, result: result ?? null, screen: observed.screen, modal: observed.modal, focus: observed.focus }, null, 2)}\n`);
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
  const notes = [];
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, "boot main menu", async () => waitForScreen(page, "main-menu"));

    // The checklist needs a loadable 1B row beside the stale campaign_backup_v2
    // row at the 1C screenshot. Build both save families in this browser profile.
    await step(page, "open Campaign Library for the 1B backup", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
    });
    await step(page, "restore interaction-duration-backup.zip", async () => {
      await uploadThrough(page, "/BtnRestore", P("interaction-duration-backup.zip"));
      await page.waitForFunction(
        (name) => {
          try { return Object.entries(JSON.parse(window[name]?.state ?? "{}").rects ?? {})
            .some(([p, r]) => p.endsWith("/OptPackage") && Boolean(r.text)); }
          catch { return false; }
        },
        bridge.BRIDGE_GLOBAL,
        { timeout: 60_000 },
      );
      await settle(page);
    });
    await step(page, "dismiss 1B restore result", async () => { await page.keyboard.press("Enter"); await settle(page); });
    await step(page, "return to Main Menu before retrying 1B", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });
    await step(page, "open Load Game and retry the 1B Resume battle row", async () => {
      await openLoadGame(page);
      await clickPathPart(page, "/Row_resume_battle/", "/RetryButton");
      await page.waitForTimeout(300);
      await page.keyboard.press("Enter");
      await page.waitForFunction(
        (name) => {
          try {
            const state = JSON.parse(window[name]?.state ?? "{}");
            const button = Object.entries(state.rects ?? {}).find(([p]) => p.endsWith("/Row_resume_battle/LoadButton"));
            return Boolean(button?.[1]?.text) && !button[1].text.includes("[Needs campaign]");
          } catch { return false; }
        },
        bridge.BRIDGE_GLOBAL,
        { timeout: 60_000 },
      );
    });
    await step(page, "return to Main Menu with loadable 1B save", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "campaign-library");
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });

    // --- Restore campaign_backup_v2.zip, but do NOT Retry yet: do 1C first. ---
    await step(page, "open Manage Library", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
    });
    await step(page, "restore campaign_backup_v2.zip", async () => {
      await uploadThrough(page, "/BtnRestore", P("campaign_backup_v2.zip"));
      await page.waitForFunction(
        (name) => {
          try {
            const s = JSON.parse(window[name]?.state ?? "{}");
            return Object.entries(s.rects ?? {}).some(([p, r]) => p.endsWith("/OptPackage") && Boolean(r.text));
          } catch { return false; }
        },
        bridge.BRIDGE_GLOBAL, { timeout: 30000 },
      );
    });
    await step(page, "dismiss restore result", async () => { await page.keyboard.press("Enter"); await settle(page); });
    await step(page, "back to Main Menu", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });

    // --- 1C: Load Game at 1280x720/1.0x, mixed loadable/not-loadable rows. ---
    const loadGame1C = await step(page, "1C — open Load Game (mixed rows, before Retry)", async () => {
      await openLoadGame(page);
      const observed = await bridge.snapshot(page);
      const rows = Object.entries(observed.rects ?? {})
        .filter(([p]) => /\/Row_[^/]+\/(LoadButton|RetryButton|ManageCampaignsButton|DeleteButton|ExportButton|MigrateButton)$/.test(p))
        .map(([p, r]) => ({ path: p, text: r.text }));
      return { rows };
    });
    notes.push(`1C Load Game rows before any Retry: ${JSON.stringify(loadGame1C.result.rows, null, 2)}`);
    const rowsAt = async () => {
      const state = await bridge.snapshot(page);
      return Object.entries(state.rects ?? {}).filter(([p]) => p.includes("/Row_") && /\/(LoadButton|RetryButton|ManageCampaignsButton|DeleteButton|ExportButton)$/.test(p))
        .map(([p, r]) => ({path:p, text:r.text, x:r.x, y:r.y, w:r.w, h:r.h, truncation:r.truncation, clip:r.clip}));
    };
    await step(page, "1C upper rows geometry", rowsAt);
    await page.mouse.move(600, 400);
    await page.mouse.wheel(0, 450);
    await settle(page);
    await step(page, "1C lower rows after scroll", rowsAt);
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    return;

    await step(page, "back to Campaign Library from Load Game", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "campaign-library");
    });

    // --- Now Retry the campaign_backup_v2 row (guess slot id from the rows above). ---
    const v2Slot = loadGame1C.result.rows
      .map((r) => r.path.match(/\/Row_([^/]+)\//)?.[1])
      .find((id) => id && id.startsWith("node-00-drill-prep-")
        && loadGame1C.result.rows.some((r) => r.path.includes(`Row_${id}/RetryButton`)));
    await step(page, "open Load Game again from Campaign Library", async () => {
      await clickSuffix(page, "/BtnLoadGame");
      await waitForScreen(page, "load-game");
    });
    if (v2Slot) {
      await step(page, `Retry campaign_backup_v2 row (${v2Slot})`, async () => {
        await clickPathPart(page, `/Row_${v2Slot}/`, "/RetryButton");
        await page.waitForTimeout(300);
        await page.keyboard.press("Enter");
        await settle(page);
      });
      await step(page, `Load campaign_backup_v2 row (${v2Slot})`, async () => {
        await clickPathPart(page, `/Row_${v2Slot}/`, "/LoadButton");
        await waitForScreen(page, "prep");
      });
    } else {
      notes.push("Could not identify the campaign_backup_v2 row's slot id automatically; see 1C screenshot.");
    }
    await step(page, "back to Main Menu from Prep? (skip if not present)", async () => {});

    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log(notes.join("\n"));
  } catch (error) {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`).catch(() => {});
    console.error("FAILED:", error.stack ?? error.message);
    process.exitCode = 1;
  } finally {
    await teardown(session);
  }
}
main();
