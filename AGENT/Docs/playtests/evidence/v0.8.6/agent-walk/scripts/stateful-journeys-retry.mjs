#!/usr/bin/env node
// Stateful, supplemental browser journeys for the tester handoff.
//
// These are deliberately real-input journeys. The bridge only answers where the
// engine is and what it has focused; it never performs an action for the runner.
// Every action leaves a screenshot and a bridge JSON beside the final report so
// a failed state transition is diagnosable without replaying the whole session.

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { access, mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

import * as bridge from "./lib/bridge.mjs";
import { clickControl } from "./lib/clicks.mjs";
import { boot, settle, teardown } from "./lib/harness.mjs";

const SCREEN_TIMEOUT_MS = 30_000;
const VIEWPORT = { width: 1280, height: 720 };
const JOURNEYS = ["load-confirm", "restore-cancel", "prep-return", "interaction-readout", "ch1-equip"];

function parseViewport(value) {
  const match = /^(\d+)x(\d+)$/.exec(value);
  if (!match) throw new Error(`viewport must be WxH, got ${value}`);
  return { width: Number(match[1]), height: Number(match[2]) };
}

export function parseArgs(argv) {
  const options = {
    url: null, out: null, backup: null, save: null, journey: "all",
    campaignSlot: "imported_01", viewport: VIEWPORT, fixture: null,
    contentScale: null, menuScale: null,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--help" || arg === "-h") {
      console.log(
        "Usage: stateful-journeys.mjs --url URL --out DIR " +
          "[--backup ZIP] [--save JSON] [--fixture JSON] " +
          "[--journey all|load-confirm|restore-cancel|prep-return|interaction-readout] " +
          "[--campaign-slot ID] [--viewport WxH]",
      );
      process.exit(0);
    }
    if (!arg.startsWith("--")) throw new Error(`unexpected argument ${arg}`);
    const value = argv[index + 1];
    if (value === undefined || value.startsWith("--")) throw new Error(`${arg} requires a value`);
    index += 1;
    switch (arg) {
      case "--url": options.url = value; break;
      case "--out": options.out = path.resolve(value); break;
      case "--backup": options.backup = path.resolve(value); break;
      case "--save": options.save = path.resolve(value); break;
      case "--journey": options.journey = value; break;
      case "--campaign-slot": options.campaignSlot = value; break;
      case "--fixture": options.fixture = path.resolve(value); break;
      case "--viewport": options.viewport = parseViewport(value); break;
      case "--content-scale": options.contentScale = value; break;
      case "--menu-scale": options.menuScale = value; break;
      default: throw new Error(`unknown argument ${arg}`);
    }
  }
  if (!options.url) throw new Error("--url is required");
  if (!options.out) throw new Error("--out is required");
  if (!JOURNEYS.includes(options.journey) && options.journey !== "all") {
    throw new Error(`--journey must be one of ${JOURNEYS.join(", ")}, got ${options.journey}`);
  }
  const selected = options.journey === "all" ? JOURNEYS : [options.journey];
  if (selected.includes("load-confirm") && !options.save) {
    throw new Error("--save is required for the load-confirm journey");
  }
  if (selected.some((name) => name !== "load-confirm") && !options.backup) {
    throw new Error("--backup is required for restore-cancel, prep-return and interaction-readout");
  }
  // The readout journey drives a board, not a menu, so it has to be told which board:
  // the sidecar written beside the backup by `build_interaction_readout_fixture.gd` names
  // the slot, the two units and their tiles. Requiring it is deliberate — inferring the
  // bearer from the roster would let a journey silently measure some other unit's fight.
  if ((selected.includes("interaction-readout") || selected.includes("ch1-equip")) && !options.fixture) {
    throw new Error("--fixture interaction-readout-fixture.json is required for interaction-readout");
  }
  return options;
}

async function exists(file) {
  try { await access(file); return true; } catch { return false; }
}

async function sha256(file) {
  return createHash("sha256").update(await readFile(file)).digest("hex");
}

function safeName(value) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

function observedFocus(observed) {
  return observed?.focus?.path ?? "";
}

export function entryBySuffix(observed, suffix) {
  const matches = Object.entries(observed?.rects ?? {}).filter(
    ([name, rect]) => name.endsWith(suffix) && rect.w > 0 && rect.h > 0,
  );
  if (matches.length !== 1) {
    throw new Error(`expected exactly one visible control ending ${suffix}, found ${matches.length}`);
  }
  return matches[0];
}

export function rectBySuffix(observed, suffix) {
  return entryBySuffix(observed, suffix)[1];
}

function entryByPathPart(observed, part, suffix) {
  const matches = Object.entries(observed?.rects ?? {}).filter(
    ([name, rect]) => name.includes(part) && name.endsWith(suffix) && rect.w > 0 && rect.h > 0,
  );
  if (matches.length !== 1) {
    throw new Error(`expected exactly one ${part}${suffix} control, found ${matches.length}`);
  }
  return matches[0];
}

async function waitForScreen(page, expected) {
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

async function clickSuffix(page, suffix, options = {}) {
  const observed = await bridge.snapshot(page);
  return clickControl(page, observed, entryBySuffix(observed, suffix)[0], options);
}

async function clickPathPart(page, part, suffix, options = {}) {
  const observed = await bridge.snapshot(page);
  return clickControl(page, observed, entryByPathPart(observed, part, suffix)[0], options);
}

function saveSurface(observed) {
  const rows = Object.entries(observed?.rects ?? {})
    .filter(([name]) => name.includes("/Rows/Row_"))
    .map(([name, rect]) => [name, {
      text: rect.text ?? "", semanticId: rect.semanticId ?? "",
      fits: rect.truncation?.fits ?? null,
    }])
    .sort(([a], [b]) => a.localeCompare(b));
  assert.ok(rows.length > 0, "Load Game displayed no save-row controls");
  return rows;
}

function resolveCampaignSlot(observed, requested) {
  const rowIds = Object.keys(observed?.rects ?? {})
    .map((name) => name.match(/\/Rows?\/Row_([^/]+)\/ExportButton$/)?.[1])
    .filter(Boolean);
  if (rowIds.includes(requested)) return requested;
  if (rowIds.length > 0) return rowIds[0];
  throw new Error(`Load Game has no exportable campaign rows for requested slot ${requested}`);
}

function activeCampaignIdentity(observed) {
  const active = observed?.activeCampaign ?? {};
  return {
    campaignId: active.campaignId ?? "",
    currentNodeId: active.currentNodeId ?? "",
    clearedNodeIds: [...(active.clearedNodeIds ?? [])],
  };
}

async function writeJson(file, value) {
  await writeFile(file, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function contextFor(name, options) {
  return { name, options, out: path.join(options.out, name), actions: [], step: "boot", session: null };
}

async function recordAction(context, label, operation) {
  context.step = label;
  const index = context.actions.length + 1;
  const stem = `${String(index).padStart(2, "0")}-${safeName(label)}`;
  try {
    const value = await operation();
    const observed = await bridge.snapshot(context.session.page);
    const screenshot = `${stem}.png`;
    const state = `${stem}.json`;
    await context.session.page.screenshot({ path: path.join(context.out, screenshot) });
    const action = { index, label, screenshot, state, observed, value: value ?? null };
    context.actions.push(action);
    await writeJson(path.join(context.out, state), action);
    return value;
  } catch (error) {
    const screenshot = `${stem}-failure.png`;
    const observed = await bridge.snapshot(context.session.page).catch(() => null);
    await context.session.page.screenshot({ path: path.join(context.out, screenshot) }).catch(() => {});
    await writeJson(path.join(context.out, `${stem}-failure.json`), {
      journey: context.name, action: label, screenshot,
      error: error instanceof Error ? error.message : String(error),
      observed, prior_actions: context.actions,
    });
    throw error;
  }
}

async function openMainMenu(context, query = {}) {
  await recordAction(context, "boot main menu", async () => {
    const target = new URL(context.options.url);
    target.searchParams.set("test_bridge", "1");
    for (const [key, value] of Object.entries(query)) target.searchParams.set(key, value);
    context.session = await boot({ url: target.href, viewport: context.options.viewport });
    await waitForScreen(context.session.page, "main-menu");
  });
}

async function openLoadGame(context) {
  await recordAction(context, "open Load Game", async () => {
    // Load Game is intentionally owned by the Campaign Library hub. Keeping
    // this route explicit catches a stale direct-Main-Menu seam in the harness
    // instead of silently exercising an obsolete control.
    await clickSuffix(context.session.page, "/CampaignLibraryButton");
    await waitForScreen(context.session.page, "campaign-library");
    await clickSuffix(context.session.page, "/BtnLoadGame");
    await waitForScreen(context.session.page, "load-game");
  });
}

async function openCampaignLibrary(context) {
  await recordAction(context, "open Campaign Library", async () => {
    await clickSuffix(context.session.page, "/CampaignLibraryButton");
    await waitForScreen(context.session.page, "campaign-library");
  });
}

async function uploadThrough(page, suffix, file) {
  const chooser = page.waitForEvent("filechooser");
  await clickSuffix(page, suffix, { settleAfter: false });
  const selected = await chooser;
  await selected.setFiles(file);
}

async function restoreBackup(context) {
  await recordAction(context, "choose campaign backup", async () => {
    await uploadThrough(context.session.page, "/BtnRestore", context.options.backup);
    await context.session.page.waitForFunction(
      (name) => {
        try {
          const state = JSON.parse(window[name]?.state ?? "{}");
          return Object.entries(state.rects ?? {}).some(
            ([controlPath, rect]) => controlPath.endsWith("/OptPackage") && Boolean(rect.text),
          );
        } catch { return false; }
      },
      bridge.BRIDGE_GLOBAL,
      { timeout: SCREEN_TIMEOUT_MS },
    );
    await settle(context.session.page);
  });
  await recordAction(context, "dismiss restore result", async () => {
    await context.session.page.keyboard.press("Enter");
    await settle(context.session.page);
  });
}

async function backToMainMenu(context) {
  await recordAction(context, "return to Main Menu", async () => {
    await clickSuffix(context.session.page, "/BtnBack");
    await waitForScreen(context.session.page, "main-menu");
  });
}

async function exportSlot(context, slotId, destination) {
  return recordAction(context, `export ${slotId}`, async () => {
    const downloadReady = context.session.page.waitForEvent("download");
    await clickPathPart(context.session.page, `/Row_${slotId}/`, "/ExportButton");
    const download = await downloadReady;
    await download.saveAs(destination);
    await context.session.page.keyboard.press("Enter");
    await settle(context.session.page);
    return {
      path: path.basename(destination), bytes: (await readFile(destination)).length,
      sha256: await sha256(destination),
    };
  });
}

// A RESTORED SLOT IS NOT IMMEDIATELY LOADABLE. Restore writes the package and the save in
// one pass, but Load Game has already drawn its rows against the library as it was, so the
// row reads "[Needs campaign] ... Campaign package not installed." until it is rescanned.
// Retry is the player's own way to do that, and waiting on the row's TEXT rather than on a
// timeout is what makes the wait mean "the package was found".
async function retryRestoredCampaign(context) {
  await recordAction(context, "retry restored campaign save", async () => {
    await clickPathPart(context.session.page, `/Row_${context.options.campaignSlot}/`, "/RetryButton");
    await context.session.page.waitForTimeout(250);
    await context.session.page.keyboard.press("Enter");
    await context.session.page.waitForFunction(
      ([name, slotId]) => {
        try {
          const state = JSON.parse(window[name]?.state ?? "{}");
          const button = Object.entries(state.rects ?? {}).find(
            ([controlPath]) => controlPath.endsWith(`/Row_${slotId}/LoadButton`),
          );
          return Boolean(button?.[1]?.text) && !button[1].text.includes("[Needs campaign]");
        } catch { return false; }
      },
      [bridge.BRIDGE_GLOBAL, context.options.campaignSlot],
      { timeout: SCREEN_TIMEOUT_MS },
    );
  });
}

async function runLoadConfirm(context) {
  await openMainMenu(context);
  await openLoadGame(context);
  await recordAction(context, "import save into Load Game", async () => {
    await uploadThrough(context.session.page, "/BtnImport", context.options.save);
    await settle(context.session.page);
  });
  await recordAction(context, "observe nested import confirmation", async () => {
    // Godot ConfirmationDialog is a child Window, not part of the Control tree
    // published by WebTestBridge. Its screenshot is the evidence that the nested
    // dialog is visible; the following Escape action is the stateful assertion:
    // if no dialog owns Escape, the Load Game modal itself closes.
    await context.session.page.waitForTimeout(250);
    const observed = await bridge.snapshot(context.session.page);
    assert.equal(observed.screen, "load-game");
    assert.equal(observed.activeCampaign?.mapLive, false);
  });
  await recordAction(context, "cancel nested import confirmation", async () => {
    await context.session.page.keyboard.press("Escape");
    await settle(context.session.page);
    assert.equal(await bridge.screen(context.session.page), "load-game");
  });
  await recordAction(context, "assert Load Game focus restored", async () => {
    const observed = await bridge.snapshot(context.session.page);
    assert.equal(observed.screen, "load-game");
    assert.ok(
      observedFocus(observed).endsWith("Panel/VBox/BtnImport"),
      `focus was ${observedFocus(observed)}, expected Load Game Import Save`,
    );
    assert.deepEqual(observed.modalStack?.map((entry) => entry.id), ["load-game"]);
  });
}

async function runRestoreCancel(context) {
  await openMainMenu(context);
  await openCampaignLibrary(context);
  await restoreBackup(context);
  await backToMainMenu(context);
  await openLoadGame(context);
  context.options.campaignSlot = resolveCampaignSlot(
    await bridge.snapshot(context.session.page), context.options.campaignSlot,
  );
  const before = await recordAction(context, "capture original save surface", async () => ({
    surface: saveSurface(await bridge.snapshot(context.session.page)),
  }));
  const beforeFile = path.join(context.out, "original-save-before.json");
  const beforeDownload = await exportSlot(context, context.options.campaignSlot, beforeFile);
  await recordAction(context, "leave Load Game", async () => {
    await clickSuffix(context.session.page, "/BtnBack");
    await waitForScreen(context.session.page, "campaign-library");
    await clickSuffix(context.session.page, "/BtnBack");
    await waitForScreen(context.session.page, "main-menu");
  });
  await openCampaignLibrary(context);
  await recordAction(context, "open occupied-slot replacement confirmation", async () => {
    await uploadThrough(context.session.page, "/BtnRestore", context.options.backup);
    await context.session.page.waitForTimeout(250);
    const observed = await bridge.snapshot(context.session.page);
    assert.equal(observed.screen, "campaign-library");
  });
  await recordAction(context, "cancel occupied-slot replacement", async () => {
    await context.session.page.keyboard.press("Escape");
    await settle(context.session.page);
  });
  await recordAction(context, "assert Campaign Library focus restored", async () => {
    const observed = await bridge.snapshot(context.session.page);
    assert.equal(observed.screen, "campaign-library");
    assert.ok(
      observedFocus(observed).endsWith("HBoxBackup/BtnRestore"),
      `focus was ${observedFocus(observed)}, expected Restore Backup`,
    );
  });
  await backToMainMenu(context);
  await openLoadGame(context);
  const after = await recordAction(context, "capture save surface after cancel", async () => ({
    surface: saveSurface(await bridge.snapshot(context.session.page)),
  }));
  assert.deepEqual(after.surface, before.surface, "save rows changed after replacement cancel");
  const afterFile = path.join(context.out, "original-save-after.json");
  const afterDownload = await exportSlot(context, context.options.campaignSlot, afterFile);
  assert.equal(afterDownload.sha256, beforeDownload.sha256, "original save bytes changed after replacement cancel");
  await writeJson(path.join(context.out, "replacement-cancel-proof.json"), {
    before: { surface: before.surface, download: beforeDownload },
    after: { surface: after.surface, download: afterDownload }, unchanged: true,
  });
}

async function runPrepReturn(context) {
  await openMainMenu(context);
  await openCampaignLibrary(context);
  await restoreBackup(context);
  await backToMainMenu(context);
  await openLoadGame(context);
  context.options.campaignSlot = resolveCampaignSlot(
    await bridge.snapshot(context.session.page), context.options.campaignSlot,
  );
  await retryRestoredCampaign(context);
  await recordAction(context, `load campaign slot ${context.options.campaignSlot}`, async () => {
    await clickPathPart(context.session.page, `/Row_${context.options.campaignSlot}/`, "/LoadButton");
    await waitForScreen(context.session.page, "prep");
  });
  const before = await recordAction(context, "capture Prep campaign position", async () => {
    const observed = await bridge.snapshot(context.session.page);
    const identity = activeCampaignIdentity(observed);
    assert.ok(identity.campaignId, "Prep has no active campaign");
    assert.ok(identity.currentNodeId, "Prep has no current campaign node");
    assert.equal(observed.screen, "prep");
    return identity;
  });
  await recordAction(context, "return from Prep to campaign map", async () => {
    const observed = await bridge.snapshot(context.session.page);
    if (!Object.keys(observed?.rects ?? {}).some((name) => name.endsWith("/ReturnButton"))) {
      throw new Error(
        `campaign ${before.campaignId} does not expose a Prep return action; ` +
          "prep-return requires a free-roam campaign save loaded from its campaign map",
      );
    }
    await clickSuffix(context.session.page, "/ReturnButton");
    await waitForScreen(context.session.page, "overworld-screen");
  });
  await recordAction(context, "assert same campaign map node", async () => {
    const observed = await bridge.snapshot(context.session.page);
    const after = activeCampaignIdentity(observed);
    assert.equal(observed.screen, "overworld-screen");
    assert.deepEqual(after, before, "campaign identity changed across Prep return");
    assert.equal(observed.activeCampaign?.mapLive, false);
  });
}

// --- the map address, and the two things a harness does with it ---------------------------

// `origin + tile * step`, the arithmetic the bridge's map block exists to permit. Kept in
// one place because every hover below depends on it agreeing exactly with the engine.
function tilePoint(map, tile) {
  if (!map?.origin || !map?.step) throw new Error("bridge published no map address");
  return {
    x: map.origin.x + tile[0] * map.step.x,
    y: map.origin.y + tile[1] * map.step.y,
  };
}

function unitOnMap(map, unitId) {
  const unit = (map?.units ?? []).find((entry) => entry.unitId === unitId);
  if (!unit) {
    throw new Error(`${unitId} is not on the board (saw ${(map?.units ?? []).map((u) => u.unitId).join(", ")})`);
  }
  return unit;
}

async function mapState(page) {
  return (await bridge.snapshot(page)).map ?? {};
}

// WAIT ON THE BOARD, NOT ON THE SCREEN ID. A live battle publishes `screen: "hud"`, because
// the HUD is a visible Control and `SCREEN_NAMES` resolves it ahead of GameMap — so waiting
// for "game-map" waits forever on a map that is already running. The map block is the
// honest signal: it is populated only when a GridManager and a MapCursor are both live.
async function waitForLiveMap(page) {
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

// HOVER, THEN VERIFY, THEN CLICK. The map's `follow` mouse mode moves the cursor to the
// hovered tile, but the cursor also clamps to the visible view — so a tile the camera has
// not scrolled to silently resolves to a different one, and the click that follows lands on
// whatever unit happens to be there. Asserting the cursor arrived turns that into a named
// failure instead of a fight between the wrong two units.
async function hoverTile(page, tile, { expectState = null } = {}) {
  // SONNET PATCH (scratch, not shipped): retry the hover a few times so a camera that
  // pans reactively (deadzone/follow) has a chance to catch up before we give up, at
  // very narrow viewports where the target tile starts outside the visible frame.
  let after = null;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    const before = await mapState(page);
    const point = tilePoint(before, tile);
    await page.mouse.move(point.x, point.y);
    await settle(page);
    after = await mapState(page);
    if (String(after.cursorTile) === String(tile)) break;
  }
  if (String(after.cursorTile) !== String(tile)) {
    throw new Error(`hovering ${tile} left the cursor on ${after.cursorTile}`);
  }
  if (expectState && after.cursorState !== expectState) {
    throw new Error(`cursor is ${after.cursorState} at ${tile}, expected ${expectState}`);
  }
  return after;
}

async function clickTile(page, tile, options = {}) {
  const observed = await hoverTile(page, tile, options);
  const point = tilePoint(observed, tile);
  await page.mouse.click(point.x, point.y);
  await settle(page);
  return mapState(page);
}

// The `[ITR-6]` rows, read off whichever side of the forecast published them. They are
// RichTextLabels the panel creates per matchup, so they have no authored names to match on;
// the container is the stable part of the path and the index is the author's order.
function readoutRows(observed) {
  return Object.entries(observed?.rects ?? {})
    .filter(([name]) => /\/(Atk|Def)Interactions\/./.test(name))
    .map(([name, rect]) => ({
      control: name,
      side: name.includes("/AtkInteractions/") ? "attacker" : "defender",
      text: String(rect.text ?? ""),
    }))
    .filter((row) => row.text !== "")
    .sort((a, b) => a.control.localeCompare(b.control));
}

// THE JOURNEY THE ROW ASKED FOR. It resumes the fixture's board, walks the bearer into
// range of the revenant like a player, and photographs the forecast. What a headless assert
// cannot show is exactly this: that the authored relationship reaches the panel a player
// reads, named in the author's own words.
async function runInteractionReadout(context) {
  const fixture = JSON.parse(await readFile(context.options.fixture, "utf8"));
  context.options.campaignSlot = fixture.campaign_slot;
  // `bridge_rects=all` is REQUIRED here and nowhere else. An interaction row is a
  // RichTextLabel with no focus, and the bridge's default scope is focusable controls plus
  // the frame — so without this the forecast publishes its buttons and not the rows the
  // journey exists to read, and the run would fail claiming no relationship fired.
  const scaleQuery = { bridge_rects: "all" };
  if (context.options.contentScale) scaleQuery.content_scale = context.options.contentScale;
  if (context.options.menuScale) scaleQuery.menu_scale = context.options.menuScale;
  await openMainMenu(context, scaleQuery);
  await openCampaignLibrary(context);
  await restoreBackup(context);
  await backToMainMenu(context);
  await openLoadGame(context);
  await retryRestoredCampaign(context);
  await recordAction(context, `resume the suspended battle ${fixture.campaign_slot}`, async () => {
    await clickPathPart(context.session.page, `/Row_${fixture.campaign_slot}/`, "/LoadButton");
    await waitForLiveMap(context.session.page);
  });

  const board = await recordAction(context, `assert ${fixture.map_id} is the live board`, async () => {
    const map = await mapState(context.session.page);
    const bearer = unitOnMap(map, fixture.bearer.unit_id);
    const target = unitOnMap(map, fixture.target.unit_id);
    assert.deepEqual(bearer.tile, fixture.bearer.tile, "the bearer resumed on a different tile");
    assert.deepEqual(target.tile, fixture.target.tile, "the target resumed on a different tile");
    assert.equal(map.cursorState, "free", `cursor is ${map.cursorState}, expected a free player phase`);
    return { bearer: bearer.tile, target: target.tile };
  });

  // One tile short of the target, on the target's own row: the bearer's movement was
  // asserted sufficient for exactly this step when the fixture was built.
  const approach = [board.target[0] - 1, board.target[1]];
  await recordAction(context, `select the bearer at ${board.bearer}`, async () => {
    // SONNET PATCH (scratch, not shipped): a hover-and-click only works when the bearer's
    // tile is already inside the camera's current view. Far-flung fixtures (a mage staged
    // 25+ tiles from the map's deployment corner) leave the target off-screen, and mouse
    // hover only CLAMPS to the visible view rather than panning the camera toward it. The
    // `next_unit` action (Tab) instead re-centres the camera on an actable unit directly,
    // regardless of distance, so cycle through it as a fallback when the direct click can't
    // even bring the cursor onto the right tile.
    let map;
    try {
      map = await clickTile(context.session.page, board.bearer);
    } catch (error) {
      map = null;
    }
    if (!map || String(map.cursorTile) !== String(board.bearer)) {
      for (let presses = 0; presses < 8; presses += 1) {
        await context.session.page.keyboard.press("Tab");
        await settle(context.session.page);
        const state = await mapState(context.session.page);
        if (String(state.cursorTile) === String(board.bearer)) break;
      }
      map = await clickTile(context.session.page, board.bearer);
    }
    assert.equal(map.cursorState, "unit-selected", `selecting the bearer left the cursor ${map.cursorState}`);
  });
  await recordAction(context, `move the bearer to ${approach}`, async () => {
    await clickTile(context.session.page, approach);
    await waitForScreen(context.session.page, "action-menu");
  });
  await recordAction(context, "choose Attack", async () => {
    await clickSuffix(context.session.page, "/BtnAttack");
    const map = await mapState(context.session.page);
    assert.equal(map.cursorState, "targeting", `Attack left the cursor ${map.cursorState}`);
  });
  // CHOOSING A TARGET IS A SECOND DECISION. `Attack` only opens target selection: the
  // cursor lands on whichever candidate is nearest the pointer -- which, right after
  // clicking a menu button, is wherever that button happened to be. The forecast appears
  // on CONFIRM, so the target has to be named deliberately.
  await recordAction(context, `confirm ${fixture.target.unit_id} at ${board.target}`, async () => {
    await clickTile(context.session.page, board.target, { expectState: "targeting" });
    await waitForScreen(context.session.page, "attack-preview");
  });

  const rows = await recordAction(context, "read the authored interaction rows", async () => {
    const observed = await bridge.snapshot(context.session.page);
    assert.equal(observed.screen, "attack-preview");
    const published = readoutRows(observed);
    // SONNET PATCH (scratch, not shipped): allow a fixture that expects ZERO rows (a
    // neutral/no-relationship matchup) to skip the stock "must publish something" guard.
    const expectsEmpty = (fixture.expected_rows ?? []).length === 0;
    if (!expectsEmpty) {
      assert.ok(
        published.length > 0,
        "the attack forecast published no interaction rows; either no authored relationship " +
          "fired for this matchup, or the run was not started with bridge_rects=all",
      );
    }
    // ASSERT AGAINST WHAT THE ENGINE RESOLVED, recorded by the fixture from the same
    // `preview_combat` call this panel makes. Counting rows catches a suppression that
    // stopped working (an extra row) or a profile that stopped firing (a missing one);
    // matching each label catches a panel that renders a row but has lost the author's
    // name for it, which is the whole of "authored presentation over a generic fallback".
    const expected = fixture.expected_rows ?? [];
    assert.equal(
      published.length, expected.length,
      `the panel shows ${published.length} interaction rows, the engine resolved ${expected.length}`,
    );
    for (const row of expected) {
      const match = published.find((shown) => shown.side === row.side && shown.text.includes(row.label));
      assert.ok(
        match,
        `no ${row.side} row names ${row.profile_id} as "${row.label}"; shown: ` +
          published.map((shown) => `[${shown.side}] ${shown.text}`).join(" | "),
      );
    }
    return published;
  });
  await writeJson(path.join(context.out, "interaction-readout-rows.json"), {
    fixture: {
      map_id: fixture.map_id, node_id: fixture.node_id, campaign_id: fixture.campaign_id,
      package_id: fixture.package_id, seed: fixture.seed,
    },
    attacker: fixture.bearer.unit_id, target: fixture.target.unit_id, rows,
  });
  console.log(`  interaction rows: ${rows.map((row) => `[${row.side}] ${row.text}`).join(" | ")}`);

  // SONNET PATCH (scratch, not shipped): cycle More Info (the `more_info` action, key F)
  // until it lands on an authored interaction row, and record whatever detail text it
  // shows. Section 1 of the v0.8.2 checklist asks specifically whether More Info explains
  // a suppression using the suppressed relationship's player-facing label.
  if (process.env.SONNET_MORE_INFO_CYCLE === "1") {
    const found = await recordAction(context, "cycle more info to an interaction row", async () => {
      for (let presses = 0; presses < 20; presses += 1) {
        await context.session.page.keyboard.press("f");
        await settle(context.session.page);
        const observed = await bridge.snapshot(context.session.page);
        const title = String(observed?.rects?.["Panel/HBox/InfoBox/InfoTitle"]?.text ?? "");
        const desc = String(observed?.rects?.["Panel/HBox/InfoBox/InfoDescription"]?.text ?? "");
        if (/Weapon Triangle|Weapon Effectiveness|Hallowed Rites|Undead Frailty/i.test(title)) {
          return { presses: presses + 1, title, desc };
        }
      }
      throw new Error("More Info never landed on an interaction row after 20 presses");
    });
    console.log(`  more info: title="${found.title}" desc="${found.desc}"`);
  }
  // SONNET PATCH (scratch, not shipped): for a MULTI-row panel, prove the F cycle reaches
  // every published row, not just the first one it lands on -- press well past the row
  // count and record the distinct (side, title, desc) tuples seen.
  if (process.env.SONNET_MORE_INFO_FULL_CYCLE === "1") {
    const seen = await recordAction(context, "cycle more info through every row", async () => {
      const distinct = new Map();
      for (let presses = 0; presses < 30; presses += 1) {
        await context.session.page.keyboard.press("f");
        await settle(context.session.page);
        const observed = await bridge.snapshot(context.session.page);
        const title = String(observed?.rects?.["Panel/HBox/InfoBox/InfoTitle"]?.text ?? "");
        const desc = String(observed?.rects?.["Panel/HBox/InfoBox/InfoDescription"]?.text ?? "");
        if (/Weapon Triangle|Weapon Effectiveness|Hallowed Rites|Undead Frailty/i.test(title)) {
          distinct.set(`${title}::${desc}`, { presses: presses + 1, title, desc });
        }
      }
      return [...distinct.values()];
    });
    console.log(`  more info distinct rows seen: ${seen.length}`);
    for (const row of seen) console.log(`    [${row.presses}] ${row.title}: ${row.desc.replace(/\n/g, " ")}`);
  }
}

// SONNET PATCH (scratch, not shipped): click whichever published control's text contains
// `textSubstring`. Used for the WeaponMenu's dynamically-built Button.new() entries, which
// carry no stable path suffix -- their name is a per-run autoincrement, but their text
// ("   Horseslayer  (∞)") is the only reliable handle.
async function clickByText(page, textSubstring) {
  const observed = await bridge.snapshot(page);
  const matches = Object.entries(observed?.rects ?? {}).filter(
    ([, rect]) => String(rect.text ?? "").includes(textSubstring),
  );
  if (matches.length !== 1) {
    throw new Error(
      `expected exactly one control containing "${textSubstring}", found ${matches.length}` +
        (matches.length ? ` (${matches.map(([name]) => name).join(", ")})` : ""),
    );
  }
  return clickControl(page, observed, matches[0][0]);
}

// SONNET PATCH (scratch, not shipped): the v0.8.1 "Equip trap" (recorded in project
// memory) -- a unit that already carries a usable weapon never fires the OTHER weapon's
// relationship until the player explicitly opens Action Menu -> Equip and picks it. This
// journey drives exactly that: select the bearer (camera-safe via the Tab fallback, since
// this map is the same 25+-tile chapter as ch1-fire-thunder), move adjacent, open Equip,
// choose the named weapon by its button text, THEN attack and read the forecast.
async function runCh1Equip(context) {
  const fixture = JSON.parse(await readFile(context.options.fixture, "utf8"));
  context.options.campaignSlot = fixture.campaign_slot;
  await openMainMenu(context, { bridge_rects: "all" });
  await openCampaignLibrary(context);
  await restoreBackup(context);
  await backToMainMenu(context);
  await openLoadGame(context);
  await retryRestoredCampaign(context);
  await recordAction(context, `resume the suspended battle ${fixture.campaign_slot}`, async () => {
    await clickPathPart(context.session.page, `/Row_${fixture.campaign_slot}/`, "/LoadButton");
    await waitForLiveMap(context.session.page);
  });

  const board = await recordAction(context, `assert ${fixture.map_id} is the live board`, async () => {
    const map = await mapState(context.session.page);
    const bearer = unitOnMap(map, fixture.bearer.unit_id);
    const target = unitOnMap(map, fixture.target.unit_id);
    assert.deepEqual(bearer.tile, fixture.bearer.tile, "the bearer resumed on a different tile");
    assert.deepEqual(target.tile, fixture.target.tile, "the target resumed on a different tile");
    return { bearer: bearer.tile, target: target.tile };
  });
  const approach = [board.target[0] - 1, board.target[1]];

  await recordAction(context, `select the bearer at ${board.bearer}`, async () => {
    let map;
    try { map = await clickTile(context.session.page, board.bearer); } catch { map = null; }
    if (!map || String(map.cursorTile) !== String(board.bearer)) {
      for (let presses = 0; presses < 8; presses += 1) {
        await context.session.page.keyboard.press("Tab");
        await settle(context.session.page);
        const state = await mapState(context.session.page);
        if (String(state.cursorTile) === String(board.bearer)) break;
      }
      map = await clickTile(context.session.page, board.bearer);
    }
    assert.equal(map.cursorState, "unit-selected", `selecting the bearer left the cursor ${map.cursorState}`);
  });
  await recordAction(context, `move the bearer to ${approach}`, async () => {
    await clickTile(context.session.page, approach);
    await waitForScreen(context.session.page, "action-menu");
  });
  await recordAction(context, "open Equip", async () => {
    await clickSuffix(context.session.page, "/BtnEquip");
    await waitForScreen(context.session.page, "weapon-menu");
  });
  await recordAction(context, "choose the Horseslayer", async () => {
    await clickByText(context.session.page, "Horseslayer");
    await waitForScreen(context.session.page, "action-menu");
  });
  await recordAction(context, "choose Attack after equipping", async () => {
    await clickSuffix(context.session.page, "/BtnAttack");
    const map = await mapState(context.session.page);
    assert.equal(map.cursorState, "targeting", `Attack left the cursor ${map.cursorState}`);
  });
  await recordAction(context, `confirm ${fixture.target.unit_id} at ${board.target}`, async () => {
    await clickTile(context.session.page, board.target, { expectState: "targeting" });
    await waitForScreen(context.session.page, "attack-preview");
  });
  const rows = await recordAction(context, "read the interaction rows after Equip", async () => {
    const observed = await bridge.snapshot(context.session.page);
    assert.equal(observed.screen, "attack-preview");
    const published = readoutRows(observed);
    const weapon = String(observed?.rects?.["Panel/HBox/AttackerBox/AtkWeapon"]?.text ?? "");
    const dmg = String(observed?.rects?.["Panel/HBox/AttackerBox/AtkDmg"]?.text ?? "");
    return { published, weapon, dmg };
  });
  await writeJson(path.join(context.out, "ch1-equip-rows.json"), rows);
  console.log(`  equipped weapon: "${rows.weapon}" dmg: "${rows.dmg}"`);
  console.log(`  interaction rows: ${rows.published.map((row) => `[${row.side}] ${row.text}`).join(" | ")}`);
}

async function runJourney(name, options) {
  const context = contextFor(name, options);
  await mkdir(context.out, { recursive: true });
  try {
    if (name === "load-confirm") await runLoadConfirm(context);
    if (name === "restore-cancel") await runRestoreCancel(context);
    if (name === "prep-return") await runPrepReturn(context);
    if (name === "interaction-readout") await runInteractionReadout(context);
    if (name === "ch1-equip") await runCh1Equip(context);
    const report = {
      status: "passed", journey: name, viewport: options.viewport,
      actions: context.actions.map(({ index, label, screenshot, state }) => ({ index, label, screenshot, state })),
      browser: context.session?.log ?? null,
    };
    await writeJson(path.join(context.out, "journey.json"), report);
    if (context.session?.log.pageErrors.length || context.session?.log.requestFailures.length) {
      throw new Error("browser reported page or request errors");
    }
    console.log(`[PASS] stateful ${name} (${context.actions.length} actions)`);
    return report;
  } catch (error) {
    const failure = {
      status: "failed", journey: name, step: context.step,
      error: error instanceof Error ? error.message : String(error),
      browser: context.session?.log ?? null, actions: context.actions,
    };
    await writeJson(path.join(context.out, "journey-failure.json"), failure);
    console.error(`[FAIL] stateful ${name} at ${context.step}: ${failure.error}`);
    return failure;
  } finally {
    await teardown(context.session);
  }
}

export async function run(options) {
  for (const file of [options.backup, options.save, options.fixture].filter(Boolean)) {
    if (!(await exists(file))) throw new Error(`fixture does not exist: ${file}`);
  }
  if (await exists(options.out) && (await readdir(options.out)).length > 0) {
    throw new Error(`${options.out} is not empty; use a fresh output directory`);
  }
  await mkdir(options.out, { recursive: true });
  const names = options.journey === "all" ? JOURNEYS : [options.journey];
  const results = [];
  for (const name of names) results.push(await runJourney(name, options));
  const failed = results.filter((result) => result.status !== "passed");
  const report = {
    schema_version: 1, status: failed.length === 0 ? "passed" : "failed",
    supplemental_only: true, native_windows_evidence_required: true,
    viewport: options.viewport, journeys: results,
  };
  await writeJson(path.join(options.out, "stateful-journeys.json"), report);
  console.log(`\n${results.length - failed.length}/${results.length} stateful journeys passed`);
  return failed.length === 0 ? 0 : 1;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  run(parseArgs(process.argv.slice(2))).then((code) => {
    process.exitCode = code;
  }).catch((error) => {
    console.error(error.stack ?? error.message);
    process.exitCode = 1;
  });
}
