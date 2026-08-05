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
// A non-flipping resize DOES report metrics now — the canvas has to follow the
// window when the mobile URL bar collapses. What it must still never do is report
// an orientation change or release the press the player is holding.
seen = await messages();
ok(
  seen.length > 0 && seen.every((m) => m.type === "metrics"),
  "a resize that does not flip orientation reports metrics and nothing else"
);
ok(
  seen.some((m) => m.width === 780 && m.height === 480),
  "the reported metrics are the window, not the canvas"
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

// ── editing: dragging a control ──────────────────────────────────────────────
//
// The drag is local CSS and is reported ONCE, on release. Reporting per pointer
// event would have the engine re-publish the layout, and every publish rebuilds
// the DOM — destroying the node the finger is holding, mid-drag.
//
// Re-applied first so the selection starts empty: the press-while-editing check
// above already grabbed this control, and selecting the same one twice is
// deliberately silent.
await page.evaluate((p) => window.PrometheusController.apply(p), payload({ editing: true }));
await clear();
await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
ok(
  (await messages()).filter((m) => m.type === "select" && m.element === "act_confirm").length === 1,
  "grabbing a control in the editor selects it, which is what the size sliders act on"
);
ok(
  (await page.evaluate(() => window.PrometheusController.debugState().dragging)) === "act_confirm",
  "the shell knows a drag is in flight"
);
await page.mouse.move(400, 240);
ok(
  (await messages()).filter((m) => m.type === "move").length === 0,
  "a drag in progress reports nothing, so the engine cannot rebuild the DOM under the finger"
);
const draggedBox = await page.locator('[data-element-id="act_confirm"]').boundingBox();
ok(
  Math.abs(draggedBox.x + draggedBox.width / 2 - 400) < 2 &&
    Math.abs(draggedBox.y + draggedBox.height / 2 - 240) < 2,
  "the control follows the pointer while it is held"
);
ok(
  (await page.evaluate(
    () => document.querySelector('[data-element-id="act_confirm"]').style.border
  )).includes("dashed"),
  "the selected control is outlined so the player can see which one the sliders edit"
);
await page.mouse.up();
const dropped = (await messages()).filter((m) => m.type === "move");
ok(dropped.length === 1, "the finger lifting reports the drag exactly once");
ok(
  Math.abs(dropped[0].x - 400 / 800) < 0.01 &&
    Math.abs(dropped[0].y - 240 / 480) < 0.01 &&
    dropped[0].element === "act_confirm",
  "...normalized to the window, which is what survives a rotation or a new device"
);
ok(
  (await page.evaluate(() => window.PrometheusController.debugState().dragging)) === "",
  "the drag is over once the pointer is up"
);
await clear();

// A control dropped past the edge would be unreachable, and nothing but another
// drag could bring it back — which needs the control the player just lost.
await page.mouse.move(400, 240);
await page.mouse.down();
await page.mouse.move(5000, 5000);
await page.mouse.up();
const offscreen = (await messages()).filter((m) => m.type === "move")[0];
const clampedBox = await page.locator('[data-element-id="act_confirm"]').boundingBox();
ok(
  offscreen.x < 1 && offscreen.y < 1 && clampedBox.x + clampedBox.width <= 800,
  "a control dragged off the screen is clamped back onto it, not lost"
);
await clear();

// The backdrop is the "done with this one" gesture; it must not also drag.
await page.mouse.click(400, 100);
ok(
  (await messages()).filter((m) => m.type === "select" && m.element === "").length === 1,
  "tapping the editor backdrop clears the selection"
);
ok(
  (await messages()).filter((m) => m.type === "move" || m.type === "press").length === 0,
  "...and moves nothing"
);
await clear();

// The engine confirms a selection through select(), not through a new payload:
// apply() rebuilds every control, and the tap that selects is the same tap that
// begins a drag, so confirming with a payload would throw away the node being
// dragged. Measured against a real export before this split existed — the drag
// died on its first frame every time while this file stayed green.
await page.evaluate((p) => window.PrometheusController.apply(p), payload({ editing: true }));
const nodeIdentity = () =>
  page.evaluate(() => {
    const node = document.querySelector('[data-element-id="act_back"]');
    node.dataset.probe = node.dataset.probe || String(Math.random());
    return node.dataset.probe;
  });
const identityBefore = await nodeIdentity();
await page.evaluate(() => window.PrometheusController.select("act_back"));
ok(
  (await page.evaluate(() => window.PrometheusController.debugState().selected)) === "act_back" &&
    (await nodeIdentity()) === identityBefore,
  "an engine-confirmed selection restyles the existing control instead of rebuilding it"
);
await page.evaluate(() => window.PrometheusController.select(""));
ok(
  !(await page.evaluate(
    () => document.querySelector('[data-element-id="act_back"]').style.border
  )).includes("dashed"),
  "deselecting through the same call clears the outline"
);
await clear();

// The engine is authoritative: what it publishes as selected is what is outlined.
await page.evaluate(
  (p) => window.PrometheusController.apply(p),
  payload({ editing: true, selected: "act_back" })
);
ok(
  (await page.evaluate(() => window.PrometheusController.debugState().selected)) === "act_back" &&
    (await page.evaluate(
      () => document.querySelector('[data-element-id="act_back"]').style.border
    )).includes("dashed"),
  "a selection published by the engine outlines that control"
);
ok(
  !(await page.evaluate(
    () => document.querySelector('[data-element-id="act_confirm"]').style.border
  )).includes("dashed"),
  "...and only that one"
);
await clear();

await page.evaluate((p) => window.PrometheusController.apply(p), payload());
ok(
  (await page.evaluate(
    () => document.getElementById("prometheus-controller").style.pointerEvents
  )) === "none",
  "leaving editing mode hands unrelated pointers back to the canvas"
);
ok(
  (await page.evaluate(() => window.PrometheusController.debugState().dragging)) === "",
  "a layout published mid-drag drops the drag rather than moving a detached node"
);

// ── auto-hide ────────────────────────────────────────────────────────────────
//
// The delay is a setting the engine owns; the countdown lives here, because only
// the browser sees the touches that keep the controls awake. A control that lands
// on the DOM never reaches Godot as an input event at all.
//
// 0.15s stands in for the offered 3–30s so the suite does not sleep; nothing in
// the shell treats a short delay differently from a long one.
const debug = () => page.evaluate(() => window.PrometheusController.debugState());
const backStyle = (prop) =>
  page.evaluate(
    (p) => document.querySelector('[data-element-id="act_back"]').style[p],
    prop
  );

await page.evaluate((p) => window.PrometheusController.apply(p), payload({ auto_hide_seconds: 0.15 }));
ok((await debug()).hidden === false, "a freshly published layout is visible, whatever the delay");
await page.waitForTimeout(400);
ok((await debug()).hidden === true, "the controls fade out once nothing has touched them");
ok((await backStyle("opacity")) === "0", "...to nothing, not to a dim ghost");
// The property that makes auto-hide worth having, and the one that keeps it from
// being the invisible dead zone the opacity floor exists to prevent: a faded
// control does not take touches, so the game gets them instead.
ok(
  (await page.evaluate(
    ([x, y]) => document.elementFromPoint(x, y).id,
    [confirmX, confirmY]
  )) === "canvas-stub",
  "a faded control takes no touches — the tap goes to the game underneath it"
);

await clear();
await page.mouse.click(400, 200);
ok((await debug()).hidden === false, "a tap anywhere brings them back");
ok(
  !(await messages()).some((m) => m.type === "press"),
  "...and the tap that brought them back pressed nothing, because it never hit a control"
);

// A control must never vanish under a finger. Its pointerup would go with it and
// strand the action down — the stuck input this whole service exists to prevent.
await page.mouse.move(confirmX, confirmY);
await page.mouse.down();
await page.waitForTimeout(400);
ok((await debug()).hidden === false, "the delay does not expire under a held control");
await page.mouse.up();
await page.waitForTimeout(400);
ok((await debug()).hidden === true, "...and expires once the finger lifts");

// Retiming must not rebuild: `autoHide` is split from `apply` for the same reason
// `select` is, and a rebuild here would drop whatever is held.
const hiddenIdentity = await nodeIdentity();
await page.evaluate(() => window.PrometheusController.autoHide(0));
ok(
  (await debug()).hidden === false && (await debug()).autoHide === 0,
  "turning auto-hide off brings back controls that already faded"
);
ok(
  (await nodeIdentity()) === hiddenIdentity,
  "...by restyling the existing controls rather than rebuilding them"
);
await page.waitForTimeout(300);
ok((await debug()).hidden === false, "and with no delay set, they never fade again");

// Editing is exempt: a control cannot be dragged after it has faded away, and the
// editor is exactly where the player is not touching anything for long stretches.
await page.evaluate(
  (p) => window.PrometheusController.apply(p),
  payload({ editing: true, auto_hide_seconds: 0.15 })
);
await page.waitForTimeout(400);
ok((await debug()).hidden === false, "the arrangement editor never fades its own controls");
await page.evaluate((p) => window.PrometheusController.apply(p), payload());

await browser.close();

console.log(`\n=== Results: ${passed} passed, ${failed} failed ===`);
process.exit(failed === 0 ? 0 : 1);
