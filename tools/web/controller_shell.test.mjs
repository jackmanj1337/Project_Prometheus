// DOM-level tests for tools/web/controller_shell.js.
//
// Run with:
//   node tools/web/controller_shell.test.mjs
// (set PLAYWRIGHT_HARNESS_MODULES if the harness lives somewhere else).
//
// These run against real Chromium with real pointer events, because the two
// properties that matter most cannot be asserted from unit-test stubs: a touch
// that MISSES a control must still reach the game canvas, and a touch that HITS
// one must not. Both depend on genuine browser hit testing.
//
// The Godot half of the same protocol is covered headlessly by
// scripts/tests/test_controller_service.gd.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const HARNESS =
  process.env.PLAYWRIGHT_HARNESS_MODULES || "/opt/prometheus-web-harness/node_modules";
const { chromium } = await import(join(HARNESS, "playwright/index.mjs"));

const SHELL_SOURCE = readFileSync(join(HERE, "controller_shell.js"), "utf8");

let passed = 0;
let failed = 0;

function ok(condition, message) {
  if (condition) {
    console.log("OK  " + message);
    passed += 1;
  } else {
    console.log("FAIL " + message);
    failed += 1;
  }
}

// A stand-in for the Godot canvas, filling the page underneath the controller
// root, recording every pointer that reaches it.
const PAGE_HTML = `<!doctype html><html><head><meta name="viewport" content="width=device-width"></head>
<body style="margin:0;padding:0;overflow:hidden">
<div id="canvas-stub" style="position:absolute;left:0;top:0;width:100%;height:100%"></div>
</body></html>`;

function payload(overrides = {}) {
  return JSON.stringify(
    Object.assign(
      {
        payload_version: 1,
        schema_version: 1,
        combination_id: "test",
        profile: "labeled_actions",
        theme: "prometheus:minimal_black",
        colors: {
          surface: "#000000",
          button: "#141414",
          button_pressed: "#3c3c3c",
          label: "#f0f0f0",
          outline: "#787878",
        },
        global_opacity: 1,
        viewport: { x: 0, y: 0, width: 1, height: 1, aspect_locked: false },
        editing: false,
        elements: [
          {
            id: "act_confirm",
            action: "confirm",
            label: "Confirm",
            group: "action",
            glyph: "",
            x: 0.9,
            y: 0.9,
            scale: 1,
            opacity: 1,
          },
          {
            id: "act_back",
            action: "cancel",
            label: "Back",
            group: "action",
            glyph: "",
            x: 0.1,
            y: 0.9,
            scale: 1,
            opacity: 1,
          },
        ],
      },
      overrides
    )
  );
}

const browser = await chromium.launch({ args: ["--no-sandbox"] });
const context = await browser.newContext({
  viewport: { width: 800, height: 480 },
  hasTouch: true,
});
const page = await context.newPage();
await page.setContent(PAGE_HTML);

// Install the renderer plus a recording bridge and a canvas listener.
await page.addScriptTag({ content: SHELL_SOURCE });
await page.evaluate(() => {
  window.__messages = [];
  window.__canvasHits = [];
  document.getElementById("canvas-stub").addEventListener("pointerdown", (event) => {
    window.__canvasHits.push(String(event.pointerId));
  });
  window.PrometheusController.setBridge((json) => window.__messages.push(JSON.parse(json)));
});

const messages = () => page.evaluate(() => window.__messages);
const clear = () => page.evaluate(() => (window.__messages = []));
const canvasHits = () => page.evaluate(() => window.__canvasHits);

// setBridge announces the current orientation so the engine can pick the right
// saved combination before the first frame.
ok(
  (await messages()).some((m) => m.type === "orientation" && m.orientation === "landscape"),
  "registering the bridge reports the starting orientation"
);
await clear();

// ── rendering ────────────────────────────────────────────────────────────────
ok(await page.evaluate((p) => window.PrometheusController.apply(p), payload()), "a valid payload applies");
ok(
  (await page.locator("#prometheus-controller [data-element-id]").count()) === 2,
  "every element in the payload is drawn"
);
ok(
  (await page.locator('[data-element-id="act_confirm"]').textContent()) === "Confirm",
  "a labeled action shows its engine-authored label"
);

ok(
  !(await page.evaluate(
    (p) => window.PrometheusController.apply(p),
    payload({ payload_version: 99 })
  )),
  "an unknown payload version is refused instead of half-drawn"
);
await page.evaluate((p) => window.PrometheusController.apply(p), payload());

ok(
  (await page.evaluate(() =>
    window.PrometheusController.apply(
      JSON.stringify({ payload_version: 1, profile: "off", elements: [] })
    )
  )) && (await page.locator("#prometheus-controller [data-element-id]").count()) === 0,
  "the off profile draws no controls"
);
await page.evaluate((p) => window.PrometheusController.apply(p), payload());

// Glyph-driven virtual pad: the engine sends the resolved binding label.
await page.evaluate(
  (p) => window.PrometheusController.apply(p),
  payload({
    profile: "virtual_gamepad",
    elements: [
      {
        id: "pad_south",
        action: "confirm",
        label: "Confirm",
        group: "face",
        glyph: "B",
        x: 0.5,
        y: 0.5,
        scale: 1,
        opacity: 1,
      },
    ],
  })
);
ok(
  (await page.locator('[data-element-id="pad_south"]').textContent()) === "B",
  "the virtual pad shows the bound glyph, not the action name"
);
await page.evaluate((p) => window.PrometheusController.apply(p), payload());
await clear();

// ── pointer routing ──────────────────────────────────────────────────────────
const confirmBox = await page.locator('[data-element-id="act_confirm"]').boundingBox();
const confirmX = confirmBox.x + confirmBox.width / 2;
const confirmY = confirmBox.y + confirmBox.height / 2;

ok(
  (await page.evaluate(
    ([x, y]) => document.elementFromPoint(x, y).getAttribute("data-element-id"),
    [confirmX, confirmY]
  )) === "act_confirm",
  "the browser hit test lands on the control"
);
ok(
  (await page.evaluate(() => document.elementFromPoint(400, 200).id)) === "canvas-stub",
  "a point that misses every control hits the canvas, not the controller root"
);

await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
let seen = await messages();
ok(
  seen.length === 1 && seen[0].type === "press" && seen[0].element === "act_confirm",
  "a pointer down on a control sends exactly one press for that element"
);
ok((await canvasHits()).length === 0, "a press on a control does not also reach the canvas");
await page.mouse.up();
seen = await messages();
ok(
  seen.length === 2 && seen[1].type === "release" && seen[1].pointer === seen[0].pointer,
  "the matching pointer up sends a release"
);
await clear();

await page.mouse.move(400, 200);
await page.mouse.down();
ok((await canvasHits()).length === 1, "a press that misses the controls reaches the canvas");
ok((await messages()).length === 0, "a canvas press sends the engine no controller message");
await page.mouse.up();
await page.evaluate(() => (window.__canvasHits = []));
await clear();

// ── multi-touch ──────────────────────────────────────────────────────────────
// Real touch points through CDP, because simultaneous fingers are the case the
// single-pointer mouse API cannot reproduce.
const cdp = await context.newCDPSession(page);
const backBox = await page.locator('[data-element-id="act_back"]').boundingBox();
const touch = (id, x, y) => ({ x, y, id, radiusX: 8, radiusY: 8, force: 1 });

await cdp.send("Input.dispatchTouchEvent", {
  type: "touchStart",
  touchPoints: [
    touch(1, confirmX, confirmY),
    touch(2, backBox.x + backBox.width / 2, backBox.y + backBox.height / 2),
  ],
});
seen = await messages();
ok(
  seen.filter((m) => m.type === "press").length === 2 &&
    new Set(seen.map((m) => m.element)).size === 2,
  "two fingers on two controls press both, with distinct pointer ids"
);
await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
seen = await messages();
ok(
  seen.filter((m) => m.type === "release").length === 2,
  "lifting both fingers releases both controls"
);
await clear();
await page.evaluate(() => (window.__canvasHits = []));

await cdp.send("Input.dispatchTouchEvent", {
  type: "touchStart",
  touchPoints: [touch(1, confirmX, confirmY), touch(2, 400, 200)],
});
seen = await messages();
ok(
  seen.filter((m) => m.type === "press").length === 1 && (await canvasHits()).length === 1,
  "a control touch and a canvas touch at the same time each go to their own target"
);
await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
await clear();
await page.evaluate(() => (window.__canvasHits = []));

// ── lifecycle cleanup ────────────────────────────────────────────────────────
await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
await clear();
await page.evaluate(() => window.dispatchEvent(new Event("blur")));
seen = await messages();
ok(
  seen.length === 1 && seen[0].type === "release_all",
  "losing window focus while held tells the engine to release everything"
);
ok(
  (await page.evaluate(() => window.PrometheusController.debugState().active)) === 0,
  "the shell forgets its held pointers too, so the next press is not swallowed"
);
await page.mouse.up();
await clear();

await page.mouse.down();
await clear();
await page.evaluate(() => document.dispatchEvent(new Event("visibilitychange")));
// visibilityState is "visible" in a foreground page, so this must NOT fire.
ok((await messages()).length === 0, "a visibility event while still visible releases nothing");
await page.evaluate(() => window.dispatchEvent(new Event("pagehide")));
ok(
  (await messages()).some((m) => m.type === "release_all"),
  "pagehide releases everything, covering the iOS tab-eviction path"
);
await page.mouse.up();
await clear();

// Re-applying a layout must not leave the previous press held.
await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
await clear();
await page.evaluate((p) => window.PrometheusController.apply(p), payload());
seen = await messages();
ok(
  seen.some((m) => m.type === "release_all"),
  "applying a new layout releases what the old one was holding"
);
await page.mouse.up();
await clear();

// ── orientation ──────────────────────────────────────────────────────────────
await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
await clear();
// The resize event is asynchronous, so give it a moment before reading.
await page.setViewportSize({ width: 780, height: 480 });
await page.waitForTimeout(200);
ok(
  (await messages()).length === 0,
  "a resize that does not flip orientation reports nothing and keeps the press held"
);
await page.setViewportSize({ width: 480, height: 800 });
await page.waitForTimeout(200);
seen = await messages();
ok(
  seen.some((m) => m.type === "orientation" && m.orientation === "portrait") &&
    seen.some((m) => m.type === "release_all"),
  "an actual flip to portrait releases held actions and reports the new orientation"
);
await page.mouse.up();
await page.setViewportSize({ width: 800, height: 480 });
await clear();

// ── editing mode ─────────────────────────────────────────────────────────────
await page.evaluate((p) => window.PrometheusController.apply(p), payload({ editing: true }));
ok(
  (await page.evaluate(
    () => document.getElementById("prometheus-controller").style.pointerEvents
  )) === "auto",
  "editing mode captures every pointer, including ones that miss a control"
);
ok(
  (await page.evaluate(() => document.elementFromPoint(400, 200).id)) === "prometheus-controller",
  "while editing, a canvas-bound touch is intercepted by the editor surface"
);
await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
ok(
  (await messages()).filter((m) => m.type === "press").length === 0,
  "pressing a control while editing does not play the game"
);
await page.mouse.up();
await clear();

await page.evaluate((p) => window.PrometheusController.apply(p), payload());
ok(
  (await page.evaluate(
    () => document.getElementById("prometheus-controller").style.pointerEvents
  )) === "none",
  "leaving editing mode hands unrelated pointers back to the canvas"
);

await browser.close();

console.log(`\n=== Results: ${passed} passed, ${failed} failed ===`);
process.exit(failed === 0 ? 0 : 1);
