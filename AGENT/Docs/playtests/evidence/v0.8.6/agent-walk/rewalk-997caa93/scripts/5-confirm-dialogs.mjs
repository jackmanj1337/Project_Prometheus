#!/usr/bin/env node
// Section 5: verify all four confirmation dialogs (End Turn, Suspend & Quit,
// Quit to Menu, replace-a-save) say what Enter will do, and confirm the default
// by pressing Enter and observing the resulting state.
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import * as bridge from "../../../tools/playwright/lib/bridge.mjs";
import { assertClipAwareBridge } from "../../../tools/playwright/lib/clicks.mjs";
import { boot, settle, teardown } from "../../../tools/playwright/lib/harness.mjs";
import {
  buildUrl, clickSuffix, clickSuffixWithScrollFallback, importPack, mapState,
  openNewGame, selectCampaign, waitForLiveMap, waitForScreen,
} from "./lib-common.mjs";

const [, , URL_BASE, PACK, OUT] = process.argv;

let stepIndex = 0;
async function step(page, label, fn) {
  stepIndex += 1;
  const stem = `${String(stepIndex).padStart(2, "0")}-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}`;
  const result = await fn();
  const observed = await bridge.snapshot(page);
  await page.screenshot({ path: path.join(OUT, `${stem}.png`) });
  await writeFile(path.join(OUT, `${stem}.json`), `${JSON.stringify({ label, result: result ?? null, screen: observed.screen, modal: observed.modal, focus: observed.focus }, null, 2)}\n`);
  console.log(`  [${stem}] ${label} :: focus=${observed.focus?.path} text=${observed.focus?.text}`);
  return { result, observed };
}

async function startLiveMap(page, pack) {
  await importPack(page, pack);
  await openNewGame(page);
  await selectCampaign(page, "proving_grounds");
  await clickSuffixWithScrollFallback(page, "/BtnStart");
  await waitForScreen(page, "prep");
  await clickSuffixWithScrollFallback(page, "/BeginButton");
  await waitForLiveMap(page);
}

async function main() {
  await mkdir(OUT, { recursive: true });
  const notes = [];
  const url = buildUrl(URL_BASE, {});

  // ---- Session 1: End Turn confirm (units unacted), then Suspend & Quit confirm ----
  let session;
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    assertClipAwareBridge(await bridge.snapshot(session.page));
    const page = session.page;
    await step(page, "boot + import + start live map (Proving Grounds)", async () => startLiveMap(page, PACK));

    await step(page, "open Map Menu", async () => {
      await page.keyboard.press("m");
      await waitForScreen(page, "map-menu");
    });
    const dlg1 = await step(page, "click End Turn with units unacted -- confirmation dialog appears", async () => {
      await clickSuffix(page, "/EndTurnButton", { settleAfter: false });
      await page.waitForTimeout(300);
      const observed = await bridge.snapshot(page);
      return { dialogFocusText: observed.focus?.text, dialogFocusPath: observed.focus?.path };
    });
    notes.push(`End Turn dialog: focus="${dlg1.result.dialogFocusText}" (expect the OK/"End Turn" button, meaning Enter confirms ending the phase)`);
    const beforeEnd = await mapState(page);
    await step(page, "press Enter on End Turn dialog", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(500);
      await settle(page);
    });
    const afterEnd = await mapState(page);
    notes.push(`End Turn Enter result: cursorState before=${beforeEnd.cursorState} after=${afterEnd.cursorState} (phase should have advanced / AI is now playing or BLUE turn incremented)`);

    // Give the AI phase a moment, then reopen Map Menu for Suspend & Quit.
    await page.waitForTimeout(1500);
    await settle(page);
    await step(page, "reopen Map Menu for Suspend and Quit", async () => {
      await page.keyboard.press("m");
      await waitForScreen(page, "map-menu");
    });
    const dlg2 = await step(page, "click Suspend and Quit -- confirmation dialog appears", async () => {
      await clickSuffix(page, "/SuspendAndQuitButton", { settleAfter: false });
      await page.waitForTimeout(300);
      const observed = await bridge.snapshot(page);
      return { dialogFocusText: observed.focus?.text, dialogFocusPath: observed.focus?.path };
    });
    notes.push(`Suspend & Quit dialog: focus="${dlg2.result.dialogFocusText}" (expect the OK/"Suspend & Quit" button, meaning Enter confirms suspending)`);
    await step(page, "press Enter on Suspend and Quit dialog", async () => {
      await page.keyboard.press("Enter");
      await waitForScreen(page, "main-menu");
    });
    notes.push("Suspend & Quit Enter result: returned to main menu (confirmed the suspend), matching the dialog's stated default.");
  } catch (error) {
    notes.push(`Session 1 (End Turn / Suspend & Quit) FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  // ---- Session 2: Quit to Menu confirm (default keeps progress) ----
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    const page = session.page;
    await step(page, "session2: boot + import + start live map", async () => startLiveMap(page, PACK));
    await step(page, "session2: open Map Menu", async () => {
      await page.keyboard.press("m");
      await waitForScreen(page, "map-menu");
    });
    const dlg3 = await step(page, "click Quit to Menu -- confirmation dialog appears", async () => {
      await clickSuffix(page, "/QuitToMenuButton", { settleAfter: false });
      await page.waitForTimeout(300);
      const observed = await bridge.snapshot(page);
      return { dialogFocusText: observed.focus?.text, dialogFocusPath: observed.focus?.path };
    });
    notes.push(`Quit to Menu dialog: focus="${dlg3.result.dialogFocusText}" (expect the Cancel/"Stay in Battle" button, meaning Enter KEEPS progress)`);
    const beforeQuit = await bridge.snapshot(page);
    await step(page, "press Enter on Quit to Menu dialog", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(500);
      await settle(page);
    });
    const afterQuit = await bridge.snapshot(page);
    notes.push(`Quit to Menu Enter result: screen before=${beforeQuit.screen} after=${afterQuit.screen} (expect UNCHANGED -- still on the map/hud, progress kept)`);
  } catch (error) {
    notes.push(`Session 2 (Quit to Menu) FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  // ---- Session 3: replace-a-save confirm (default keeps existing save) ----
  try {
    session = await boot({ url, viewport: { width: 1280, height: 720 } });
    const page = session.page;
    await step(page, "session3: boot + import free-roam", async () => { await importPack(page, PACK); });
    await step(page, "session3: New Game -> Proving Grounds -> Start -> Prep", async () => {
      await openNewGame(page);
      await selectCampaign(page, "proving_grounds");
      await clickSuffixWithScrollFallback(page, "/BtnStart");
      await waitForScreen(page, "prep");
    });
    await step(page, "session3: first manual Save at Prep (creates the slot)", async () => {
      await clickSuffixWithScrollFallback(page, "/SaveButton");
      await page.waitForTimeout(500);
      await settle(page);
    });
    const dlg4 = await step(page, "session3: second Save with the same label -- overwrite confirmation appears", async () => {
      await clickSuffixWithScrollFallback(page, "/SaveButton");
      await page.waitForTimeout(400);
      const observed = await bridge.snapshot(page);
      return { dialogFocusText: observed.focus?.text, dialogFocusPath: observed.focus?.path, modal: observed.modal };
    });
    notes.push(`Replace-a-save dialog: focus="${dlg4.result.dialogFocusText}" modal="${dlg4.result.modal}" (expect the Cancel/"Keep Saves" or "Keep Save" button, meaning Enter KEEPS the existing save)`);
    const beforeReplace = await bridge.snapshot(page);
    await step(page, "session3: press Enter on the replace-a-save dialog", async () => {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(400);
      await settle(page);
    });
    const afterReplace = await bridge.snapshot(page);
    notes.push(`Replace-a-save Enter result: modal before=${beforeReplace.modal} after=${afterReplace.modal} (expect the dialog closed with NO new overwrite -- existing save kept)`);
  } catch (error) {
    notes.push(`Session 3 (replace-a-save) FAILED: ${error.stack ?? error.message}`);
    console.error(error);
  } finally {
    await teardown(session);
  }

  await writeFile(path.join(OUT, "notes.json"), `${JSON.stringify(notes, null, 2)}\n`);
  console.log("\n" + notes.join("\n"));
}
main().catch((e) => { console.error(e.stack ?? e.message); process.exit(1); });
