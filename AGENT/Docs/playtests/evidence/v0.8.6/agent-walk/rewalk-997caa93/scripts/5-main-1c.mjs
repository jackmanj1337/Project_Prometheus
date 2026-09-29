#!/usr/bin/env node
// Section 5 main flow + 1C (done at the checklist's specified point):
//   - restore interaction-duration-backup.zip, Retry the resume_battle row (loadable)
//   - restore campaign_backup_v2.zip, do NOT Retry yet
//   - 1C: Load Game at 1280x720/1.0x with mixed rows (readable text, no clip/overlap)
//   - THEN Retry campaign_backup_v2's row, Load it into Prep
//   - record which packs are installed and which font Load Game uses
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import {
  buildUrl, clickPathPart, clickSuffix, entryByPathPart, importPack, openLoadGame, waitForScreen,
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

function rowSnapshot(observed) {
  return Object.entries(observed.rects ?? {})
    .filter(([p]) => /\/Row_[^/]+\/(LoadButton|RetryButton|ManageCampaignsButton|DeleteButton|ExportButton|MigrateButton)$/.test(p))
    .map(([p, r]) => ({ path: p, text: r.text, x: r.x, y: r.y, w: r.w, h: r.h, truncation: r.truncation, theme: r.theme }));
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { content_scale: "1.0", menu_scale: "1.0" });
  const notes = [];
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, "boot main menu", async () => waitForScreen(page, "main-menu"));

    await step(page, "open Manage Library for the 1B backup", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
    });
    await step(page, "restore interaction-duration-backup.zip", async () => {
      await uploadThrough(page, "/BtnRestore", P("interaction-duration-backup.zip"));
      await page.waitForFunction(
        (name) => Object.entries(JSON.parse(window[name]?.state ?? "{}").rects ?? {}).some(([p, r]) => p.endsWith("/OptPackage") && Boolean(r.text)),
        bridge.BRIDGE_GLOBAL, { timeout: 60000 },
      );
      await settle(page);
    });
    await step(page, "dismiss 1B restore result", async () => { await page.keyboard.press("Enter"); await settle(page); });
    await step(page, "back to Main Menu", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });
    await step(page, "open Load Game and Retry the resume_battle row", async () => {
      await openLoadGame(page);
      await clickPathPart(page, "/Row_resume_battle/", "/RetryButton");
      await page.waitForTimeout(300);
      await page.keyboard.press("Enter");
      await page.waitForFunction(
        (name) => {
          const s = JSON.parse(window[name]?.state ?? "{}");
          const b = Object.entries(s.rects ?? {}).find(([p]) => p.endsWith("/Row_resume_battle/LoadButton"));
          return Boolean(b?.[1]?.text) && !b[1].text.includes("[Needs campaign]");
        },
        bridge.BRIDGE_GLOBAL, { timeout: 60000 },
      );
    });
    await step(page, "back to Main Menu with a loadable 1B save", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "campaign-library");
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "main-menu");
    });

    await step(page, "open Manage Library for campaign_backup_v2", async () => {
      await clickSuffix(page, "/CampaignLibraryButton");
      await waitForScreen(page, "campaign-library");
    });
    await step(page, "restore campaign_backup_v2.zip (do NOT Retry yet)", async () => {
      await uploadThrough(page, "/BtnRestore", P("campaign_backup_v2.zip"));
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

    // --- 1C: mixed rows, 1280x720/1.0x. ---
    const before = await step(page, "1C -- open Load Game: mixed rows before Retry (SCREENSHOT)", async () => {
      await openLoadGame(page);
      return rowSnapshot(await bridge.snapshot(page));
    });
    notes.push(`1C rows before Retry: ${JSON.stringify(before.result, null, 2)}`);
    await step(page, "1C -- scroll to confirm lower row is fully reachable", async () => {
      await page.mouse.move(600, 400);
      await page.mouse.wheel(0, 450);
      await settle(page);
      return rowSnapshot(await bridge.snapshot(page));
    });

    // Record installed packages + font in use on this screen.
    const activePkg = await step(page, "1C -- record installed packages / font", async () => {
      const observed = await bridge.snapshot(page);
      return { activePackage: observed.activePackage, theme: observed.rects?.Panel?.theme ?? null };
    });
    notes.push(`1C installed packages / theme provenance: ${JSON.stringify(activePkg.result)}`);

    await step(page, "back to Campaign Library from Load Game", async () => {
      await clickSuffix(page, "/BtnBack");
      await waitForScreen(page, "campaign-library");
    });

    const v2Slot = before.result
      .map((r) => r.path.match(/\/Row_([^/]+)\//)?.[1])
      .find((id) => id && id.startsWith("node-00-drill-prep-") && before.result.some((r) => r.path.includes(`Row_${id}/RetryButton`)));
    await step(page, "open Load Game again", async () => {
      await clickSuffix(page, "/BtnLoadGame");
      await waitForScreen(page, "load-game");
    });
    if (v2Slot) {
      await step(page, `scroll down to reach ${v2Slot} row before Retry`, async () => {
        await page.mouse.move(600, 400);
        for (let i = 0; i < 6; i += 1) { await page.mouse.wheel(0, 300); await settle(page); }
      });
      await step(page, `Retry campaign_backup_v2 row (${v2Slot})`, async () => {
        await clickPathPart(page, `/Row_${v2Slot}/`, "/RetryButton");
        await page.waitForTimeout(300);
        await page.keyboard.press("Enter");
        await settle(page);
      });
      const retried = await step(page, `read ${v2Slot} row after Retry`, async () => {
        const observed = await bridge.snapshot(page);
        return entryByPathPart(observed, `/Row_${v2Slot}/`, "/LoadButton")[1];
      });
      notes.push(`campaign_backup_v2 row after Retry: ${JSON.stringify(retried.result)}`);
      await step(page, `Load campaign_backup_v2 row (${v2Slot}) -> Prep`, async () => {
        await clickPathPart(page, `/Row_${v2Slot}/`, "/LoadButton");
        await waitForScreen(page, "prep");
      });
    } else {
      notes.push("Could not auto-identify the campaign_backup_v2 slot id -- see the 'before' rows dump above.");
    }

    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
    console.log("\n" + notes.join("\n"));
  } catch (error) {
    await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`).catch(() => {});
    console.error("FAILED:", error.stack ?? error.message);
    process.exitCode = 1;
  } finally {
    await teardown(session);
  }
}
main();
