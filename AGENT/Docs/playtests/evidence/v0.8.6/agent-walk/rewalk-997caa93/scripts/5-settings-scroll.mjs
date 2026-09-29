#!/usr/bin/env node
// Section 5 gap: Settings below 600px wide, at 0.5x and 2x, try mouse wheel, scroll
// bar drag, AND arrow keys SEPARATELY (fresh Settings open before each method), and
// report which worked, by reading whether Export Diagnostics / Back become reachable.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import { buildUrl, clickSuffix, waitForScreen } from "./lib-common.mjs";

const [, , URL_BASE, OUT, SCALE] = process.argv;
const scale = SCALE || "2.0";

async function capture(page, out, name) {
  const s = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(out, `${name}.png`) });
  await writeFile(path.join(out, `${name}.json`), `${JSON.stringify(s, null, 2)}\n`);
  const bottomControls = Object.entries(s.rects ?? {})
    .filter(([p]) => /Export|BtnBack|Diag/.test(p))
    .map(([p, r]) => ({ path: p, y: r.y, h: r.h, text: r.text }));
  return { screen: s.screen, focus: s.focus, bottomControls };
}

async function openSettings(page) {
  await waitForScreen(page, "main-menu");
  await clickSuffix(page, "/SettingsButton");
  await waitForScreen(page, "settings");
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const url = buildUrl(URL_BASE, { menu_scale: scale, content_scale: scale });
  const notes = [];

  // Method 1: mouse wheel.
  let session;
  try {
    session = await boot({ url, viewport: { width: 560, height: 900 } });
    const page = session.page;
    await openSettings(page);
    const top = await capture(page, OUT, `${scale}-wheel-00-top`);
    await page.mouse.move(280, 450);
    for (let i = 0; i < 10; i += 1) { await page.mouse.wheel(0, 500); await settle(page); }
    const bottom = await capture(page, OUT, `${scale}-wheel-01-bottom`);
    const reachedExport = bottom.bottomControls.some((c) => c.path.includes("Export") && c.y >= 0 && c.y <= 900);
    notes.push(`[${scale}x] Mouse wheel: top bottomControls=${JSON.stringify(top.bottomControls)}; after wheel=${JSON.stringify(bottom.bottomControls)}; reached Export Diagnostics on-screen: ${reachedExport}`);
  } catch (error) {
    notes.push(`[${scale}x] Mouse wheel method FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }

  // Method 2: scroll bar drag (locate the VScrollBar handle and drag it down).
  try {
    session = await boot({ url, viewport: { width: 560, height: 900 } });
    const page = session.page;
    await openSettings(page);
    await capture(page, OUT, `${scale}-scrollbar-00-top`);
    const observed = await bridge.snapshot(page);
    const scrollbar = Object.entries(observed.rects ?? {}).find(([p]) => /VScrollBar|ScrollBar/i.test(p));
    if (scrollbar) {
      const [, rect] = scrollbar;
      const startX = rect.x + rect.w / 2;
      const startY = rect.y + 20;
      await page.mouse.move(startX, startY);
      await page.mouse.down();
      await page.mouse.move(startX, rect.y + rect.h - 5, { steps: 10 });
      await page.mouse.up();
      await settle(page);
      const bottom = await capture(page, OUT, `${scale}-scrollbar-01-bottom`);
      const reachedExport = bottom.bottomControls.some((c) => c.path.includes("Export") && c.y >= 0 && c.y <= 900);
      notes.push(`[${scale}x] Scroll bar drag: scrollbar rect=${JSON.stringify(rect)}; after drag bottomControls=${JSON.stringify(bottom.bottomControls)}; reached Export Diagnostics on-screen: ${reachedExport}`);
    } else {
      notes.push(`[${scale}x] Scroll bar drag: NO VScrollBar/ScrollBar control published by the bridge (rects: ${Object.keys(observed.rects ?? {}).join(", ")}) -- could not attempt this method.`);
    }
  } catch (error) {
    notes.push(`[${scale}x] Scroll bar drag method FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }

  // Method 3: arrow keys (Down repeatedly after focusing a control in the list).
  try {
    session = await boot({ url, viewport: { width: 560, height: 900 } });
    const page = session.page;
    await openSettings(page);
    await capture(page, OUT, `${scale}-arrows-00-top`);
    // Focus the first focusable control, then press Down repeatedly.
    await page.keyboard.press("Tab");
    await settle(page);
    for (let i = 0; i < 40; i += 1) { await page.keyboard.press("ArrowDown"); await settle(page); }
    const bottom = await capture(page, OUT, `${scale}-arrows-01-bottom`);
    const reachedExport = bottom.bottomControls.some((c) => c.path.includes("Export") && c.y >= 0 && c.y <= 900);
    const focusOnExportOrBack = /Export|BtnBack/.test(bottom.focus?.path ?? "");
    notes.push(`[${scale}x] Arrow keys (Tab then Down x40): final focus=${bottom.focus?.path} text=${bottom.focus?.text}; reached Export Diagnostics on-screen: ${reachedExport}; focus landed on Export/Back: ${focusOnExportOrBack}`);
  } catch (error) {
    notes.push(`[${scale}x] Arrow key method FAILED: ${error.stack ?? error.message}`);
  } finally {
    await teardown(session);
  }

  await writeFile(path.join(OUT, `notes-${scale}.json`), `${JSON.stringify(notes, null, 2)}\n`);
  console.log(notes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
