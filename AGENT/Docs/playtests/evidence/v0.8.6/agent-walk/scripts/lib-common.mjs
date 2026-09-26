// Shared helpers for the v0.8.6 agent walk scripts. Adapted from
// builds/tester/Project_Prometheus_v0.8.5/agent-walk/live-map-capture.mjs and
// builds/v085-walk-kit/scripts/stateful-journeys-retry-batch-a.mjs.

import * as bridge from "./lib/bridge.mjs";
import { clickableEntries, clickControl, CLIP_AWARE_QUERY, visibleRect } from "./lib/clicks.mjs";
import { settle } from "./lib/harness.mjs";

export const SCREEN_TIMEOUT_MS = 30_000;

export function entryBySuffix(observed, suffix) {
  const matches = clickableEntries(observed).filter(([name]) => name.endsWith(suffix));
  if (matches.length !== 1) {
    throw new Error(`expected exactly one visible control ending ${suffix}, found ${matches.length}`);
  }
  return matches[0];
}

export function entryByPathPart(observed, part, suffix) {
  const matches = clickableEntries(observed).filter(
    ([name]) => name.includes(part) && name.endsWith(suffix),
  );
  if (matches.length !== 1) {
    throw new Error(`expected exactly one ${part}${suffix} control, found ${matches.length}`);
  }
  return matches[0];
}

export async function clickSuffix(page, suffix, options = {}) {
  const observed = await bridge.snapshot(page);
  return clickControl(page, observed, entryBySuffix(observed, suffix)[0], options);
}

export async function clickPathPart(page, part, suffix, options = {}) {
  const observed = await bridge.snapshot(page);
  return clickControl(page, observed, entryByPathPart(observed, part, suffix)[0], options);
}

// Fallback for the checklist's documented "scrolling menus" case at 1280x720/2x etc.
//
// Two distinct failure shapes were found driving this, and they need different fixes:
//   1. A control inside a real ScrollContainer reports `clippedBy` and clickControl
//      throws "is clipped out of view" -- the old behaviour here (Tab, then wheel).
//   2. PrepScreen's Begin button has NO enclosing ScrollContainer at all (confirmed by
//      reading PrepScreen.tscn: Margin is a direct child of the screen root, not wrapped
//      in a Scroll). At 1280x720/2x its VBox overflows the 640x360 logical canvas with
//      nothing to report the clip, so visibleRect() sees no clipping ancestor and
//      clickControl "succeeds" -- but the computed click point (e.g. y=797 in a 720-tall
//      viewport) is OUTSIDE the browser viewport and the click is silently a no-op. This
//      reproduced 1280x720/2x's 1A timeout: BeginButton was "clicked" every time, the
//      live map never loaded, because the mouse event landed off-canvas.
// So this checks the real page viewport bounds FIRST, before ever attempting a mouse
// click, and uses Tab+Enter (works regardless of scroll/visibility) as the primary
// fallback; a genuine ScrollContainer clip additionally gets a wheel-scroll attempt.
export async function clickSuffixWithScrollFallback(page, suffix, options = {}) {
  const viewportSize = page.viewportSize();
  const observed = await bridge.snapshot(page);
  const [path] = entryBySuffix(observed, suffix);
  const resolved = visibleRect(observed, path);
  const center = { x: resolved.visible.x + resolved.visible.w / 2, y: resolved.visible.y + resolved.visible.h / 2 };
  const inBounds = (
    !resolved.fullyClipped && center.x >= 0 && center.y >= 0
    && center.x <= viewportSize.width && center.y <= viewportSize.height
  );
  if (inBounds) {
    try {
      return await clickSuffix(page, suffix, options);
    } catch (error) {
      if (!/is clipped out of view/.test(String(error?.message))) throw error;
      // fall through to the keyboard/wheel fallback below
    }
  } else {
    console.warn(
      `  ${suffix} resolves outside the ${viewportSize.width}x${viewportSize.height} viewport `
      + `(center ${Math.round(center.x)},${Math.round(center.y)}, fullyClipped=${resolved.fullyClipped}); `
      + "trying Tab focus traversal, then scroll wheel",
    );
  }
  for (let presses = 0; presses < 48; presses += 1) {
    await page.keyboard.press("Tab");
    await settle(page);
    const focusObserved = await bridge.snapshot(page);
    const focusPath = focusObserved?.focus?.path ?? "";
    if (focusPath.endsWith(suffix)) {
      await page.keyboard.press("Enter");
      await settle(page);
      return bridge.snapshot(page);
    }
  }
  // Scroll-wheel fallback, for a real ScrollContainer clip Tab traversal didn't resolve
  // (e.g. the target itself isn't focus-reachable in this state).
  const rescan = await bridge.snapshot(page);
  const [rescanPath, rect] = entryBySuffix(rescan, suffix);
  const visible = visibleRect(rescan, rescanPath);
  const point = visible.clippedBy.length
    ? { x: rect.x + rect.w / 2, y: (visible.rect.y ?? rect.y) }
    : { x: rect.x + rect.w / 2, y: rect.y + rect.h / 2 };
  for (let i = 0; i < 10; i += 1) {
    await page.mouse.move(point.x, Math.max(1, Math.min(viewportSize.height - 1, point.y - 40)));
    await page.mouse.wheel(0, 240);
    await settle(page);
    try {
      return await clickSuffix(page, suffix, options);
    } catch (e) {
      if (!/is clipped out of view/.test(String(e?.message))) throw e;
    }
  }
  throw new Error(`${suffix} could not be reached by direct click, Tab traversal, or scroll wheel`);
}

export async function waitForScreen(page, expected) {
  await page.waitForFunction(
    ([name, screen]) => {
      try { return JSON.parse(window[name]?.state ?? "{}").screen === screen; }
      catch { return false; }
    },
    [bridge.BRIDGE_GLOBAL, expected],
    { timeout: SCREEN_TIMEOUT_MS },
  );
  await settle(page);
}

export async function waitForLiveMap(page) {
  await page.waitForFunction(
    (name) => {
      try { return (JSON.parse(window[name]?.state ?? "{}").map?.units ?? []).length > 0; }
      catch { return false; }
    },
    bridge.BRIDGE_GLOBAL,
    { timeout: SCREEN_TIMEOUT_MS },
  );
  await settle(page);
}

export function buildUrl(base, params) {
  const target = new URL(base);
  target.searchParams.set("test_bridge", "1");
  for (const [key, value] of Object.entries(CLIP_AWARE_QUERY)) target.searchParams.set(key, value);
  for (const [key, value] of Object.entries(params ?? {})) {
    if (value !== undefined && value !== null) target.searchParams.set(key, String(value));
  }
  return target.href;
}

export async function importPack(page, pack) {
  await waitForScreen(page, "main-menu");
  await clickSuffix(page, "/CampaignLibraryButton");
  await waitForScreen(page, "campaign-library");
  const chooser = page.waitForEvent("filechooser");
  await clickSuffix(page, "/BtnImport", { settleAfter: false });
  await (await chooser).setFiles(pack);
  await page.waitForFunction(
    (name) => {
      try {
        const state = JSON.parse(window[name]?.state ?? "{}");
        return Boolean(state.importResult?.outcome);
      } catch { return false; }
    },
    bridge.BRIDGE_GLOBAL,
    { timeout: SCREEN_TIMEOUT_MS },
  );
  const imported = await bridge.snapshot(page);
  await page.keyboard.press("Enter");
  await settle(page);
  await clickSuffix(page, "/BtnBack");
  await waitForScreen(page, "main-menu");
  return imported.importResult;
}

export async function openCampaignLibraryControl(page, suffix, screen) {
  await waitForScreen(page, "main-menu");
  await clickSuffix(page, "/CampaignLibraryButton");
  await waitForScreen(page, "campaign-library");
  await clickSuffix(page, suffix);
  await waitForScreen(page, screen);
}

export async function openLoadGame(page) {
  await openCampaignLibraryControl(page, "/BtnLoadGame", "load-game");
}

export async function openNewGame(page) {
  await openCampaignLibraryControl(page, "/BtnNewGame", "new-game");
}

export async function readEntries(page) {
  const observed = await bridge.snapshot(page);
  if (!observed.newGameEntries?.offered) throw new Error("New Game selector did not publish campaign entries");
  return observed.newGameEntries;
}

export async function selectCampaign(page, campaignId) {
  const entries = await readEntries(page);
  const entry = entries.offered.find((candidate) => candidate.campaign_id === campaignId);
  if (!entry) throw new Error(`campaign ${campaignId} was not offered: ${JSON.stringify(entries.offered)}`);
  await clickSuffix(page, "/OptRun", { settleAfter: false });
  await page.waitForFunction(
    (name) => {
      try { return JSON.parse(window[name]?.state ?? "{}").newGameEntries?.popup?.visible === true; } catch { return false; }
    },
    bridge.BRIDGE_GLOBAL,
    { timeout: SCREEN_TIMEOUT_MS },
  );
  const popup = (await readEntries(page)).popup;
  const pitch = popup.rect.h / popup.itemCount;
  await page.mouse.click(
    popup.rect.x + popup.rect.w / 2,
    popup.rect.y + (entry.index + 0.5) * pitch,
  );
  await settle(page);
  const selected = await readEntries(page);
  if (selected.selected !== entry.index) throw new Error(`campaign selector stopped at ${selected.selected}`);
  return entry;
}

// Generic OptionButton picker for Settings-style rows (auto_end_turn, etc). The popup
// is a separate Window the bridge cannot see, so this drives it by keyboard instead of
// guessing pixel offsets: open it with the button's own Enter/click, then use Up/Home to
// reach the first item (works for any item count when itemIndex === 0) and Enter to
// confirm. Verifies by reading the button's own text back afterward.
export async function chooseOptionButtonByLabel(page, suffix, label, itemIndex) {
  const before = await clickSuffix(page, suffix, { settleAfter: false });
  const [path] = entryBySuffix(before, suffix);
  await page.waitForTimeout(200);
  // "Home" is not reliably bound in the popup; force to the boundary by repeating
  // Up/Down past the end (harmless once at the edge), then step to the exact index.
  for (let i = 0; i < 10; i += 1) await page.keyboard.press("ArrowUp");
  for (let i = 0; i < itemIndex; i += 1) await page.keyboard.press("ArrowDown");
  await page.waitForTimeout(100);
  await page.keyboard.press("Enter");
  await settle(page);
  const after = await bridge.snapshot(page);
  const text = after.rects?.[path]?.text ?? "";
  if (!text.includes(label)) {
    throw new Error(`OptionButton ${path} reads "${text}" after selecting index ${itemIndex}, expected to include "${label}"`);
  }
  return after;
}

export function unitOnMap(map, unitId) {
  const unit = (map?.units ?? []).find((entry) => entry.unitId === unitId);
  if (!unit) {
    throw new Error(`${unitId} is not on the board (saw ${(map?.units ?? []).map((u) => u.unitId).join(", ")})`);
  }
  return unit;
}

export async function mapState(page) {
  return (await bridge.snapshot(page)).map ?? {};
}

export function tilePoint(map, tile) {
  if (!map?.origin || !map?.step) throw new Error("bridge published no map address");
  return {
    x: map.origin.x + tile[0] * map.step.x,
    y: map.origin.y + tile[1] * map.step.y,
  };
}

export async function hoverTile(page, tile, { expectState = null } = {}) {
  const before = await mapState(page);
  const point = tilePoint(before, tile);
  await page.mouse.move(point.x, point.y);
  await settle(page);
  const after = await mapState(page);
  if (String(after.cursorTile) !== String(tile)) {
    throw new Error(`hovering ${tile} left the cursor on ${after.cursorTile}`);
  }
  if (expectState && after.cursorState !== expectState) {
    throw new Error(`cursor is ${after.cursorState} at ${tile}, expected ${expectState}`);
  }
  return after;
}

export async function clickTile(page, tile, options = {}) {
  const observed = await hoverTile(page, tile, options);
  const point = tilePoint(observed, tile);
  await page.mouse.click(point.x, point.y);
  await settle(page);
  return mapState(page);
}

// Rect-overlap test in the bridge's window-pixel space.
export function rectsOverlap(a, b) {
  if (!a || !b || a.w <= 0 || a.h <= 0 || b.w <= 0 || b.h <= 0) return false;
  const left = Math.max(a.x, b.x);
  const top = Math.max(a.y, b.y);
  const right = Math.min(a.x + a.w, b.x + b.w);
  const bottom = Math.min(a.y + a.h, b.y + b.h);
  return right > left && bottom > top;
}
