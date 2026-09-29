#!/usr/bin/env node
// Section 5: attempt Export Diagnostics in the browser and report what it produced.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffixWithScrollFallback, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT] = process.argv;

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, {});
  let session;
  const notes = [];
  const consoleLines = [];
  session = await boot({ url, viewport: { width: 1280, height: 720 } });
  session.page.on("console", (msg) => consoleLines.push(msg.text()));
  try {
    const page = session.page;
    await waitForScreen(page, "main-menu");
    await clickSuffixWithScrollFallback(page, "/SettingsButton");
    await waitForScreen(page, "settings");
    await page.screenshot({ path: path.join(OUT, "01-settings.png") });
    let observed = await bridge.snapshot(page);
    const hasExport = Object.keys(observed.rects ?? {}).some((p) => p.endsWith("/BtnExportDiagnostics"));
    notes.push(`BtnExportDiagnostics present in Settings: ${hasExport}`);
    if (hasExport) {
      await page.mouse.move(600, 400);
      for (let i = 0; i < 12; i += 1) { await page.mouse.wheel(0, 500); await settle(page); }
      await clickSuffixWithScrollFallback(page, "/BtnExportDiagnostics");
      await page.waitForTimeout(800);
      await settle(page);
      await page.screenshot({ path: path.join(OUT, "02-after-export-diagnostics.png") });
      observed = await bridge.snapshot(page);
      await writeFile(path.join(OUT, "02-after-export-diagnostics.json"), `${JSON.stringify(observed, null, 2)}\n`);
      const dialogTexts = Object.entries(observed.rects ?? {}).filter(([, r]) => r.text).map(([p, r]) => [p, r.text]);
      notes.push(`Rects/text after clicking Export Diagnostics: ${JSON.stringify(dialogTexts)}`);
    }
    const bundleLine = consoleLines.find((l) => l.includes("DIAGNOSTICS_BUNDLE"));
    notes.push(`Console DIAGNOSTICS_BUNDLE line (only printed in headless mode): ${bundleLine ?? "(none -- browser is not headless from Godot's perspective, so an AcceptDialog is expected instead)"}`);
    notes.push(`Full console capture: ${JSON.stringify(consoleLines.slice(-40))}`);
  } catch (error) {
    notes.push(`FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }
  await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
  console.log(notes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
