// On-screen controller renderer for the web export.
//
// The engine owns the model: this file receives a validated payload and draws
// it. It never decides what an element does — it reports the element id it was
// given and Godot resolves that through its registry allow-list. Nothing here
// reads campaign data, evaluates a string, or loads a remote resource.
//
// Why the controls live in the DOM rather than in a Godot Control: only the
// browser can put them OUTSIDE the game canvas, which is the entire point of
// the mobile layout. The measured 2026-08-04 spike showed a two-finger stream
// splits cleanly — pointer capture plus preventDefault keeps a control's touch
// out of Godot while a second touch continues into the canvas.
//
// CSP: no eval, no inline <style>, no external fetch. Styling is applied
// through CSSOM property assignment, which a strict style-src does not block.

(function () {
  "use strict";

  if (window.PrometheusController) {
    return; // A shell that already loaded the renderer wins; stay idempotent.
  }

  var ROOT_ID = "prometheus-controller";
  var SUPPORTED_PAYLOAD_VERSION = 1;

  var DEFAULT_COLORS = {
    surface: "#000000",
    button: "#141414",
    button_pressed: "#3c3c3c",
    label: "#f0f0f0",
    outline: "#787878",
  };

  // Only #rrggbb reaches CSS. The engine validates too; this is the second
  // gate so a bad payload can never turn into a CSS expression.
  var HEX = /^#[0-9a-fA-F]{6}$/;

  var state = {
    bridge: null,
    root: null,
    payload: null,
    editing: false,
    // Which editor owns the pointers: "none", "controls" or "viewport". `editing`
    // above stays the plain "are pointers mine?" answer every touch path asks.
    editMode: "none",
    // element id -> DOM node, so a press can restyle exactly one control.
    nodes: {},
    // pointerId -> element id, mirroring the engine ledger for local visuals.
    active: {},
    // Last orientation reported to the engine, so a resize that did not flip
    // the device sends nothing.
    orientation: null,
    // Element id the engine says is selected, so the editor can outline it.
    selected: "",
    // The drag in flight while the editor is open: {pointer, id, node, dx, dy}.
    // Null at every other moment, including while the editor is open and idle.
    drag: null,
    // Seconds of no touching before the controls fade out; 0 never hides. The
    // engine owns the value (it is a setting); the countdown lives here, because
    // only the browser sees the touches that keep the controls awake.
    // ── Game View editor (Slice 3) ──────────────────────────────────────────
    // The canvas rectangle as the engine last applied it, in CSS pixels. The
    // shell does not compute this: the engine clamps and aspect-locks it, so the
    // authoritative answer always arrives from Godot.
    canvasRect: null,
    // The ghost outline, its eight handles, and the guide lines. All null while
    // the Game View editor is closed — the editor builds them on entry.
    frame: null,
    handles: {},
    guides: null,
    // The frame gesture in flight: {pointer, handle, origin, start}. The canvas
    // itself is NOT resized until this ends; see `endFrameDrag`.
    frameDrag: null,
    // Smallest canvas the engine will accept, in window pixels, and whether it
    // holds the design aspect. Both come from the payload so the shell cannot
    // disagree with the model about them.
    minViewport: { width: 0, height: 0 },
    aspectLocked: false,
    autoHide: 0,
    // Whether the fade has happened. Faded controls are not merely invisible —
    // they stop taking pointers, so the tap that brings them back reaches the
    // game rather than firing whichever control it happened to land on.
    hidden: false,
    hideTimer: null,
  };

  function color(value, fallback) {
    return typeof value === "string" && HEX.test(value) ? value : fallback;
  }

  function clamp01(value) {
    var n = typeof value === "number" && isFinite(value) ? value : 0.5;
    return n < 0 ? 0 : n > 1 ? 1 : n;
  }

  function send(message) {
    if (typeof state.bridge === "function") {
      state.bridge(JSON.stringify(message));
    }
  }

  function ensureRoot() {
    if (state.root && state.root.isConnected) {
      return state.root;
    }
    var root = document.getElementById(ROOT_ID);
    if (!root) {
      root = document.createElement("div");
      root.id = ROOT_ID;
    }
    var s = root.style;
    s.position = "fixed";
    s.left = "0";
    s.top = "0";
    s.width = "100%";
    s.height = "100%";
    s.zIndex = "20";
    // The root is transparent to pointers so a touch that misses a control
    // still reaches the canvas; only the buttons opt back in.
    s.pointerEvents = "none";
    s.touchAction = "none";
    s.userSelect = "none";
    s.webkitUserSelect = "none";
    // Attached once per root, not per render: the editor backdrop only takes
    // pointers while editing, and a listener added on every payload would stack
    // one deselect per layout change.
    root.addEventListener("pointerdown", function (event) {
      // Controls stop propagation, so reaching here means the backdrop itself
      // was tapped — the gesture for "I am done editing this one".
      if (state.editMode === "controls" && event.target === root) {
        selectElement("");
      }
    });
    if (!root.isConnected) {
      document.body.appendChild(root);
    }
    state.root = root;
    return root;
  }

  // Controls are sized from the screen's SHORT edge, not a fixed pixel count. A
  // fixed 64px control is a comfortable thumb target on a 360px-tall landscape
  // window and an unreachable one on a 412px-wide portrait window — and at the
  // widths the labelled pills need (1.9x), fixed sizing is what pushed the
  // portrait defaults off both edges. Clamped so a tablet does not get slabs and
  // a very small phone does not get targets too small to hit.
  var BASE_SIZE_FRACTION = 0.115;
  var MIN_BUTTON_PX = 38;
  var MAX_BUTTON_PX = 96;

  function baseButtonSize() {
    var shortEdge = Math.min(window.innerWidth, window.innerHeight);
    return Math.min(MAX_BUTTON_PX, Math.max(MIN_BUTTON_PX, Math.round(shortEdge * BASE_SIZE_FRACTION)));
  }

  // Keeps a whole control on screen, given the CENTRE it wants to sit at. Shared
  // by the renderer and the drag so the two cannot disagree: a drag clamped one
  // way and re-rendered the other is a control that visibly jumps on release.
  var EDGE_MARGIN = 4;

  function clampCentre(centreX, centreY, boxWidth, boxHeight) {
    var halfW = boxWidth / 2;
    var halfH = boxHeight / 2;
    var minX = halfW + EDGE_MARGIN;
    var minY = halfH + EDGE_MARGIN;
    return {
      x: Math.min(Math.max(centreX, minX), Math.max(minX, window.innerWidth - minX)),
      y: Math.min(Math.max(centreY, minY), Math.max(minY, window.innerHeight - minY)),
    };
  }

  function styleButton(node, element, payload, pressed) {
    var colors = payload.colors || {};
    var scale = typeof element.scale === "number" ? element.scale : 1;
    var size = Math.round(baseButtonSize() * (scale > 0 ? scale : 1));
    var s = node.style;
    s.position = "absolute";
    s.boxSizing = "border-box";
    s.width = size + "px";
    s.height = size + "px";
    s.marginLeft = -(size / 2) + "px";
    s.marginTop = -(size / 2) + "px";
    s.display = "flex";
    s.alignItems = "center";
    s.justifyContent = "center";
    s.textAlign = "center";
    s.fontFamily = "sans-serif";
    s.fontSize = Math.max(10, Math.round(size / 4)) + "px";
    s.lineHeight = "1.1";
    s.color = color(colors.label, DEFAULT_COLORS.label);
    s.border = "2px solid " + color(colors.outline, DEFAULT_COLORS.outline);
    s.background = pressed
      ? color(colors.button_pressed, DEFAULT_COLORS.button_pressed)
      : color(colors.button, DEFAULT_COLORS.button);
    // Round for the pad's face/D-pad buttons, pill for worded actions.
    s.borderRadius = element.group === "action" ? size / 4 + "px" : "50%";
    var boxWidth = size;
    if (element.group === "action") {
      boxWidth = Math.round(size * 1.9);
      s.width = boxWidth + "px";
      s.marginLeft = -(boxWidth / 2) + "px";
      s.fontSize = Math.max(10, Math.round(size / 5)) + "px";
    }

    // Positioned in pixels, then clamped so the whole control stays on screen.
    // Percentages alone cannot do this: the element's own width is what pushes it
    // past the edge, and a percentage knows nothing about it. `restyle()` re-runs
    // this on resize, which is what keeps pixel positioning responsive.
    var centre = clampCentre(
      clamp01(element.x) * window.innerWidth,
      clamp01(element.y) * window.innerHeight,
      boxWidth,
      size
    );
    s.left = centre.x + "px";
    s.top = centre.y + "px";
    var opacity = typeof element.opacity === "number" ? element.opacity : 1;
    var global = typeof payload.global_opacity === "number" ? payload.global_opacity : 1;
    // The editor deliberately ignores the authored opacity. A control faded to
    // the bottom of its range is exactly the one a player opened the editor to
    // fix, and it cannot be dragged if it cannot be seen.
    s.opacity = state.editing ? "1" : state.hidden ? "0" : String(clamp01(opacity) * clamp01(global));
    // An auto-hidden control must also stop taking touches. Invisible-but-live is
    // the dead zone the model's opacity floor exists to prevent, and it would be
    // worse here: the player cannot even see what they are hitting. Controls go
    // inert in the Game View editor for the neighbouring reason: they are drawn
    // there only so the player can see what the canvas must avoid, and a touch
    // that grabbed one would be a touch stolen from the frame behind it.
    s.pointerEvents =
      (state.hidden && !state.editing) || state.editMode === "viewport" ? "none" : "auto";
    s.touchAction = "none";
    s.cursor = state.editMode === "controls" ? "move" : "pointer";
    if (state.editMode === "controls" && element.id === state.selected) {
      s.border = "3px dashed " + color(colors.label, DEFAULT_COLORS.label);
    }
  }

  function setPressedVisual(elementId, pressed) {
    var node = state.nodes[elementId];
    if (!node || !state.payload) {
      return;
    }
    var colors = state.payload.colors || {};
    node.style.background = pressed
      ? color(colors.button_pressed, DEFAULT_COLORS.button_pressed)
      : color(colors.button, DEFAULT_COLORS.button);
  }

  function pressPointer(event, elementId) {
    var key = String(event.pointerId);
    if (state.active[key] === elementId) {
      return;
    }
    if (state.active[key]) {
      setPressedVisual(state.active[key], false);
    }
    state.active[key] = elementId;
    setPressedVisual(elementId, true);
    send({ type: "press", pointer: key, element: elementId });
  }

  function releasePointer(event) {
    var key = String(event.pointerId);
    var elementId = state.active[key];
    if (!elementId) {
      return;
    }
    delete state.active[key];
    setPressedVisual(elementId, false);
    send({ type: "release", pointer: key });
  }

  // ── Editing: drag a control ───────────────────────────────────────────────
  //
  // The drag happens LOCALLY, in CSS, and is reported ONCE on release. A move
  // reported per pointer event would have the engine re-publish the layout, and
  // every publish rebuilds the DOM — destroying the very node the finger is
  // holding, mid-drag. Position is the one property the shell is allowed to know
  // before the engine does, and only until the finger lifts.
  function beginDrag(event, node, elementId) {
    var rect = node.getBoundingClientRect();
    state.drag = {
      pointer: String(event.pointerId),
      id: elementId,
      node: node,
      // Offset from the control's CENTRE, so grabbing near an edge does not
      // snap the control's middle to the finger the moment it moves.
      dx: rect.left + rect.width / 2 - event.clientX,
      dy: rect.top + rect.height / 2 - event.clientY,
    };
    selectElement(elementId);
  }

  function dragTo(event) {
    var drag = state.drag;
    if (!drag || drag.pointer !== String(event.pointerId)) {
      return false;
    }
    var centre = clampCentre(
      event.clientX + drag.dx,
      event.clientY + drag.dy,
      drag.node.offsetWidth,
      drag.node.offsetHeight
    );
    drag.node.style.left = centre.x + "px";
    drag.node.style.top = centre.y + "px";
    return true;
  }

  function endDrag(event) {
    var drag = state.drag;
    if (!drag || drag.pointer !== String(event.pointerId)) {
      return false;
    }
    state.drag = null;
    var left = parseFloat(drag.node.style.left);
    var top = parseFloat(drag.node.style.top);
    // A zero-sized window means the page is mid-teardown; normalizing against it
    // would divide by zero and report NaN, which the engine rejects anyway.
    if (isFinite(left) && isFinite(top) && window.innerWidth > 0 && window.innerHeight > 0) {
      send({
        type: "move",
        element: drag.id,
        x: left / window.innerWidth,
        y: top / window.innerHeight,
      });
    }
    return true;
  }

  // Local echo first, then the engine. The engine confirms by re-publishing the
  // payload, but a highlight that waited for the round trip would lag the tap.
  function selectElement(elementId) {
    if (state.selected === elementId) {
      return;
    }
    state.selected = elementId;
    send({ type: "select", element: elementId });
    restyle();
  }

  function attachHandlers(node, elementId) {
    node.addEventListener(
      "pointerdown",
      function (event) {
        // Capture first: the control keeps the whole stream even if the finger
        // slides off it, so a drag cannot leak a stray press into the canvas.
        if (node.setPointerCapture) {
          try {
            node.setPointerCapture(event.pointerId);
          } catch (err) {
            /* capture is best-effort; the release paths still fire */
          }
        }
        event.preventDefault();
        event.stopPropagation();
        if (state.editMode === "controls") {
          // The editor owns every pointer while it is open: this one drags the
          // control rather than playing the game underneath it.
          beginDrag(event, node, elementId);
          return;
        }
        if (state.editing) {
          return; // The Game View editor is open; a control is scenery, not a button.
        }
        pressPointer(event, elementId);
      },
      { passive: false }
    );

    node.addEventListener(
      "pointermove",
      function (event) {
        if (dragTo(event)) {
          event.preventDefault();
          event.stopPropagation();
        }
      },
      { passive: false }
    );

    ["pointerup", "pointercancel", "lostpointercapture"].forEach(function (name) {
      node.addEventListener(
        name,
        function (event) {
          event.preventDefault();
          event.stopPropagation();
          // A pointer is either dragging a control or pressing one, never both,
          // so an ended drag must not also report a release the engine never
          // saw a press for.
          if (!endDrag(event)) {
            releasePointer(event);
          }
        },
        { passive: false }
      );
    });

    // A context menu on long-press would swallow the pointerup and strand the
    // action down — the classic stuck-input path on mobile Safari.
    node.addEventListener("contextmenu", function (event) {
      event.preventDefault();
    });
  }

  function releaseAllLocal() {
    var keys = Object.keys(state.active);
    if (keys.length === 0) {
      return;
    }
    keys.forEach(function (key) {
      setPressedVisual(state.active[key], false);
      delete state.active[key];
    });
    send({ type: "release_all" });
  }

  // ── Editing: drag the game canvas ─────────────────────────────────────────
  //
  // Slice 3. Same contract as a control drag, one level up: the gesture happens
  // LOCALLY on a ghost outline and the rectangle is reported ONCE on release. The
  // reason is sharper here than it is for a control. Under
  // `html/canvas_resize_policy=0` the canvas backing store is ours, so applying a
  // rect means reallocating a GPU buffer at the new device-pixel size — doing
  // that per pointer move would reallocate it sixty times a second while the
  // player drags, and the engine would re-render the whole frame into each one.
  //
  // The eight handles and the whole-rectangle drag are the same gesture with
  // different edges locked, so one code path takes a handle name and decides
  // which of the four edges it may move.

  var HANDLE_PX = 30;
  // How close an edge has to come to a guide before it sticks. Roughly a finger's
  // worth of slop: large enough to be reachable on a phone, small enough that a
  // player who means to sit two pixels off a guide still can.
  var SNAP_PX = 14;
  var DESIGN_ASPECT = 16 / 9;

  // Which edges each handle moves. "move" moves all four together.
  var HANDLES = {
    nw: ["left", "top"],
    n: ["top"],
    ne: ["right", "top"],
    e: ["right"],
    se: ["right", "bottom"],
    s: ["bottom"],
    sw: ["left", "bottom"],
    w: ["left"],
  };

  function windowSize() {
    return { width: window.innerWidth, height: window.innerHeight };
  }

  // The engine's minimum, clamped against the window for the same reason the
  // engine clamps it: 640x360 does not fit inside a 412px-wide phone, and a
  // minimum larger than the screen is a canvas that cannot be dragged at all.
  function minCanvasSize() {
    var win = windowSize();
    return {
      width: Math.min(state.minViewport.width || 0, win.width),
      height: Math.min(state.minViewport.height || 0, win.height),
    };
  }

  // Where the canvas is right now. The engine's answer wins; the layout global is
  // the fallback for the moment before the first `canvas` message arrives, and the
  // whole window is the fallback for a page that has neither (the test harness).
  function currentCanvasRect() {
    if (state.canvasRect) {
      return state.canvasRect;
    }
    var layout = window.PrometheusWebLayout;
    if (layout && typeof layout.current === "function") {
      try {
        var parsed = JSON.parse(layout.current());
        if (parsed && isFinite(parsed.width) && parsed.width > 0) {
          return { x: parsed.x, y: parsed.y, width: parsed.width, height: parsed.height };
        }
      } catch (err) {
        /* fall through to the window */
      }
    }
    var win = windowSize();
    return { x: 0, y: 0, width: win.width, height: win.height };
  }

  // CSS-pixel insets the device reserves for a notch or a home indicator. Read
  // through the PWA shell rather than from CSS here: it already owns the
  // `env(safe-area-inset-*)` custom properties, and two readers of one value drift.
  function safeAreaInsets() {
    var pwa = window.PrometheusPWA;
    if (!pwa || typeof pwa.safeArea !== "function") {
      return { top: 0, right: 0, bottom: 0, left: 0 };
    }
    var insets = pwa.safeArea();
    return {
      top: Number(insets.top) || 0,
      right: Number(insets.right) || 0,
      bottom: Number(insets.bottom) || 0,
      left: Number(insets.left) || 0,
    };
  }

  // The box the on-screen controls occupy, or null when none are drawn. This is
  // the collision guide: the whole point of shrinking the canvas is to put the
  // controls somewhere they do not cover the game, so the editor has to show
  // where they are while the player decides where the game goes.
  function controlBounds() {
    var ids = Object.keys(state.nodes);
    if (ids.length === 0) {
      return null;
    }
    var left = Infinity;
    var top = Infinity;
    var right = -Infinity;
    var bottom = -Infinity;
    ids.forEach(function (id) {
      var box = state.nodes[id].getBoundingClientRect();
      left = Math.min(left, box.left);
      top = Math.min(top, box.top);
      right = Math.max(right, box.right);
      bottom = Math.max(bottom, box.bottom);
    });
    return isFinite(left) ? { left: left, top: top, right: right, bottom: bottom } : null;
  }

  // Every line an edge may stick to: the window, the safe area, the middle, and
  // the controls. Returned as two lists of coordinates so a horizontal edge only
  // ever considers horizontal lines.
  function snapLines() {
    var win = windowSize();
    var safe = safeAreaInsets();
    var xs = [0, win.width, win.width / 2, safe.left, win.width - safe.right];
    var ys = [0, win.height, win.height / 2, safe.top, win.height - safe.bottom];
    var bounds = controlBounds();
    if (bounds) {
      xs.push(bounds.left, bounds.right);
      ys.push(bounds.top, bounds.bottom);
    }
    return { x: xs, y: ys };
  }

  function snapTo(value, lines) {
    var best = value;
    var bestDistance = SNAP_PX;
    lines.forEach(function (line) {
      var distance = Math.abs(line - value);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = line;
      }
    });
    return best;
  }

  // Forces the design aspect by SHRINKING, never growing, and about the edges the
  // gesture is not moving. Growing would silently reclaim screen the player just
  // gave to the controls — the same rule the engine's own aspect lock follows.
  function holdAspect(rect, moving) {
    var width = rect.right - rect.left;
    var height = rect.bottom - rect.top;
    if (width <= 0 || height <= 0) {
      return rect;
    }
    var next = { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
    if (width / height > DESIGN_ASPECT) {
      var wantedWidth = height * DESIGN_ASPECT;
      if (moving.indexOf("left") >= 0) {
        next.left = next.right - wantedWidth;
      } else {
        next.right = next.left + wantedWidth;
      }
    } else {
      var wantedHeight = width / DESIGN_ASPECT;
      if (moving.indexOf("top") >= 0) {
        next.top = next.bottom - wantedHeight;
      } else {
        next.bottom = next.top + wantedHeight;
      }
    }
    return next;
  }

  // Applies one pointer delta to the edges a handle owns, then snaps, then
  // enforces the minimum size and the window bounds. Order matters: snapping
  // before the minimum means a snap can never produce a canvas the engine would
  // reject, and clamping last means nothing this returns can be off-screen.
  function resolveFrame(handle, start, dx, dy) {
    var win = windowSize();
    var min = minCanvasSize();
    var lines = snapLines();
    var edges = {
      left: start.x,
      top: start.y,
      right: start.x + start.width,
      bottom: start.y + start.height,
    };

    if (handle === "move") {
      var left = snapTo(edges.left + dx, lines.x);
      var top = snapTo(edges.top + dy, lines.y);
      // The trailing edges get a chance to stick too, so a canvas dragged toward
      // the bottom of the screen lands flush with it rather than one pixel short.
      var right = snapTo(edges.right + dx, lines.x);
      var bottom = snapTo(edges.bottom + dy, lines.y);
      if (Math.abs(right - (edges.right + dx)) < Math.abs(left - (edges.left + dx))) {
        left = right - start.width;
      }
      if (Math.abs(bottom - (edges.bottom + dy)) < Math.abs(top - (edges.top + dy))) {
        top = bottom - start.height;
      }
      left = Math.min(Math.max(left, 0), Math.max(0, win.width - start.width));
      top = Math.min(Math.max(top, 0), Math.max(0, win.height - start.height));
      return { x: left, y: top, width: start.width, height: start.height };
    }

    var moving = HANDLES[handle] || [];
    moving.forEach(function (edge) {
      if (edge === "left") {
        edges.left = snapTo(edges.left + dx, lines.x);
      } else if (edge === "right") {
        edges.right = snapTo(edges.right + dx, lines.x);
      } else if (edge === "top") {
        edges.top = snapTo(edges.top + dy, lines.y);
      } else {
        edges.bottom = snapTo(edges.bottom + dy, lines.y);
      }
    });

    // Keep each moved edge on its own side of the fixed one, and no closer than
    // the minimum. Done per edge rather than on the finished rect so dragging the
    // left handle past the right one stops instead of turning the canvas
    // inside out.
    if (moving.indexOf("left") >= 0) {
      edges.left = Math.min(Math.max(edges.left, 0), edges.right - min.width);
    }
    if (moving.indexOf("right") >= 0) {
      edges.right = Math.max(Math.min(edges.right, win.width), edges.left + min.width);
    }
    if (moving.indexOf("top") >= 0) {
      edges.top = Math.min(Math.max(edges.top, 0), edges.bottom - min.height);
    }
    if (moving.indexOf("bottom") >= 0) {
      edges.bottom = Math.max(Math.min(edges.bottom, win.height), edges.top + min.height);
    }

    var held = state.aspectLocked ? holdAspect(edges, moving) : edges;
    return {
      x: held.left,
      y: held.top,
      width: Math.max(1, held.right - held.left),
      height: Math.max(1, held.bottom - held.top),
    };
  }

  function styleGuideLine(node, colors) {
    var s = node.style;
    s.position = "fixed";
    s.pointerEvents = "none";
    s.borderStyle = "dashed";
    s.borderWidth = "0";
    s.borderColor = color(colors.outline, DEFAULT_COLORS.outline);
    s.opacity = "0.5";
    return node;
  }

  // The static guides: the safe area, the screen's middle, and the box the
  // controls occupy. Drawn once when the editor opens — none of them moves while
  // the canvas does, and redrawing them per pointer move would be pure churn.
  function buildGuides(root, colors) {
    var layer = document.createElement("div");
    layer.setAttribute("data-guides", "true");
    var s = layer.style;
    s.position = "fixed";
    s.left = "0";
    s.top = "0";
    s.width = "100%";
    s.height = "100%";
    s.pointerEvents = "none";

    var win = windowSize();
    var safe = safeAreaInsets();
    if (safe.top || safe.right || safe.bottom || safe.left) {
      var safeBox = styleGuideLine(document.createElement("div"), colors);
      safeBox.setAttribute("data-guide", "safe-area");
      safeBox.style.borderWidth = "1px";
      safeBox.style.left = safe.left + "px";
      safeBox.style.top = safe.top + "px";
      safeBox.style.width = Math.max(0, win.width - safe.left - safe.right) + "px";
      safeBox.style.height = Math.max(0, win.height - safe.top - safe.bottom) + "px";
      layer.appendChild(safeBox);
    }

    var bounds = controlBounds();
    if (bounds) {
      var controlBox = styleGuideLine(document.createElement("div"), colors);
      controlBox.setAttribute("data-guide", "controls");
      controlBox.style.borderWidth = "1px";
      controlBox.style.left = bounds.left + "px";
      controlBox.style.top = bounds.top + "px";
      controlBox.style.width = Math.max(0, bounds.right - bounds.left) + "px";
      controlBox.style.height = Math.max(0, bounds.bottom - bounds.top) + "px";
      layer.appendChild(controlBox);
    }

    root.appendChild(layer);
    state.guides = layer;
    return layer;
  }

  // The guides describe the window and the controls, and a mobile URL bar
  // collapsing changes both — mid-edit, which is exactly when a guide pointing at
  // the wrong place is worst. Rebuilt rather than restyled because there is no
  // state in them: they are four numbers read fresh each time.
  function refreshGuides() {
    if (!state.root || state.editMode !== "viewport") {
      return;
    }
    if (state.guides && state.guides.parentNode) {
      state.guides.parentNode.removeChild(state.guides);
    }
    state.guides = null;
    buildGuides(state.root, (state.payload || {}).colors || {});
    // The layer is appended last, so it would otherwise sit over the frame and
    // eat the handles. It takes no pointers, but the frame still has to be on top
    // for its own handles to be hit-testable.
    if (state.frame && state.frame.parentNode) {
      state.frame.parentNode.appendChild(state.frame);
    }
  }

  function positionFrame(rect) {
    if (!state.frame) {
      return;
    }
    var s = state.frame.style;
    s.left = rect.x + "px";
    s.top = rect.y + "px";
    s.width = Math.max(0, rect.width) + "px";
    s.height = Math.max(0, rect.height) + "px";
    // The collision guide made actionable: the frame reports, live, whether the
    // canvas is currently sitting on top of the controls. Reported and not
    // refused — a full-window canvas with the controls over it is a legitimate
    // landscape arrangement, and only the player knows which one they meant.
    var bounds = controlBounds();
    var overlaps =
      bounds !== null &&
      rect.x < bounds.right &&
      rect.x + rect.width > bounds.left &&
      rect.y < bounds.bottom &&
      rect.y + rect.height > bounds.top;
    state.frame.setAttribute("data-overlaps-controls", overlaps ? "true" : "false");
    state.frame.style.borderStyle = overlaps ? "dashed" : "solid";
  }

  function buildFrame(root, colors) {
    var frame = document.createElement("div");
    frame.setAttribute("data-game-view-frame", "true");
    var s = frame.style;
    s.position = "fixed";
    s.boxSizing = "border-box";
    s.borderWidth = "2px";
    s.borderStyle = "solid";
    s.borderColor = color(colors.label, DEFAULT_COLORS.label);
    s.background = "transparent";
    s.touchAction = "none";
    // The frame's interior drags the whole rectangle, so it takes pointers; the
    // handles sit on top of it and take theirs first.
    s.pointerEvents = "auto";
    s.cursor = "move";
    s.zIndex = "1";
    attachFrameHandlers(frame, "move");

    state.handles = {};
    Object.keys(HANDLES).forEach(function (name) {
      var handle = document.createElement("div");
      handle.setAttribute("data-handle", name);
      var h = handle.style;
      h.position = "absolute";
      h.width = HANDLE_PX + "px";
      h.height = HANDLE_PX + "px";
      h.marginLeft = -(HANDLE_PX / 2) + "px";
      h.marginTop = -(HANDLE_PX / 2) + "px";
      h.background = color(colors.label, DEFAULT_COLORS.label);
      h.opacity = "0.85";
      h.borderRadius = "4px";
      h.touchAction = "none";
      h.pointerEvents = "auto";
      h.left = name.indexOf("w") >= 0 ? "0%" : name.indexOf("e") >= 0 ? "100%" : "50%";
      h.top = name.indexOf("n") >= 0 ? "0%" : name.indexOf("s") >= 0 ? "100%" : "50%";
      attachFrameHandlers(handle, name);
      frame.appendChild(handle);
      state.handles[name] = handle;
    });

    root.appendChild(frame);
    state.frame = frame;
    positionFrame(currentCanvasRect());
    return frame;
  }

  function beginFrameDrag(event, handle) {
    var rect = currentCanvasRect();
    state.frameDrag = {
      pointer: String(event.pointerId),
      handle: handle,
      originX: event.clientX,
      originY: event.clientY,
      start: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
      last: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
    };
  }

  function frameDragTo(event) {
    var drag = state.frameDrag;
    if (!drag || drag.pointer !== String(event.pointerId)) {
      return false;
    }
    drag.last = resolveFrame(
      drag.handle,
      drag.start,
      event.clientX - drag.originX,
      event.clientY - drag.originY
    );
    positionFrame(drag.last);
    return true;
  }

  function endFrameDrag(event) {
    var drag = state.frameDrag;
    if (!drag || drag.pointer !== String(event.pointerId)) {
      return false;
    }
    state.frameDrag = null;
    var win = windowSize();
    if (win.width <= 0 || win.height <= 0) {
      return true; // Mid-teardown; normalizing against it would report NaN.
    }
    send({
      type: "viewport",
      x: drag.last.x / win.width,
      y: drag.last.y / win.height,
      width: drag.last.width / win.width,
      height: drag.last.height / win.height,
    });
    return true;
  }

  function attachFrameHandlers(node, handle) {
    node.addEventListener(
      "pointerdown",
      function (event) {
        if (node.setPointerCapture) {
          try {
            node.setPointerCapture(event.pointerId);
          } catch (err) {
            /* capture is best-effort; the release paths still fire */
          }
        }
        event.preventDefault();
        event.stopPropagation();
        beginFrameDrag(event, handle);
      },
      { passive: false }
    );
    node.addEventListener(
      "pointermove",
      function (event) {
        if (frameDragTo(event)) {
          event.preventDefault();
          event.stopPropagation();
        }
      },
      { passive: false }
    );
    ["pointerup", "pointercancel", "lostpointercapture"].forEach(function (name) {
      node.addEventListener(
        name,
        function (event) {
          if (endFrameDrag(event)) {
            event.preventDefault();
            event.stopPropagation();
          }
        },
        { passive: false }
      );
    });
    node.addEventListener("contextmenu", function (event) {
      event.preventDefault();
    });
  }

  // ── Auto-hide ─────────────────────────────────────────────────────────────
  //
  // Fading is a RESTYLE, never a re-render: rebuilding the DOM to change an
  // opacity would drop whatever is held, and the timer fires at a moment nobody
  // chose — which is precisely when that is least forgivable.

  function cancelHideTimer() {
    if (state.hideTimer !== null) {
      clearTimeout(state.hideTimer);
      state.hideTimer = null;
    }
  }

  function pointerBusy() {
    return (
      state.drag !== null || state.frameDrag !== null || Object.keys(state.active).length > 0
    );
  }

  function hideNow() {
    state.hideTimer = null;
    if (state.editing || state.hidden) {
      return;
    }
    // Never fade out from under a finger. A control that vanished mid-press
    // would take its pointerup with it and strand the action down — the exact
    // stuck-input failure this whole service exists to prevent. Waiting one more
    // full delay is right rather than clever: the player is demonstrably using
    // the controls right now.
    if (pointerBusy()) {
      scheduleHide();
      return;
    }
    state.hidden = true;
    restyle();
  }

  function scheduleHide() {
    cancelHideTimer();
    if (!(state.autoHide > 0) || state.editing) {
      return;
    }
    state.hideTimer = setTimeout(hideNow, state.autoHide * 1000);
  }

  // Any touch anywhere is activity: on a control, or on the game canvas past it.
  // Restarting the countdown on both is what keeps the controls from fading while
  // the player is plainly still playing.
  function wake() {
    if (state.hidden) {
      state.hidden = false;
      restyle();
    }
    scheduleHide();
  }

  // Capture phase, on the document, so it sees the pointer BEFORE any control
  // does — and still sees the ones that never reach a control at all, which is
  // every one of them while the controls are faded out and inert. Passive: this
  // listener only observes, so the tap that wakes the controls goes on to do
  // whatever it would have done anyway.
  document.addEventListener("pointerdown", wake, { capture: true, passive: true });

  function render(payload) {
    var root = ensureRoot();
    root.textContent = "";
    state.nodes = {};
    state.payload = payload;
    state.editing = payload.editing === true;
    state.editMode = typeof payload.edit_mode === "string" ? payload.edit_mode : "none";
    state.selected = typeof payload.selected === "string" ? payload.selected : "";
    // The frame and its handles were children of the root, so `textContent = ""`
    // above has already destroyed them; keeping the references would leave the
    // drag holding a detached node.
    state.frame = null;
    state.handles = {};
    state.guides = null;
    state.frameDrag = null;
    var minimum = payload.min_viewport || {};
    state.minViewport = {
      width: typeof minimum.width === "number" && isFinite(minimum.width) ? minimum.width : 0,
      height: typeof minimum.height === "number" && isFinite(minimum.height) ? minimum.height : 0,
    };
    state.aspectLocked = !!(payload.viewport && payload.viewport.aspect_locked);
    // Every node the drag was holding has just been discarded, so a drag that
    // survived this would move a detached element and report its position.
    state.drag = null;
    // A new layout always arrives visible. It is the answer to something the
    // player just did — changing style, arrangement or a control — and showing
    // them the result is the point; the countdown starts again from here.
    state.autoHide =
      typeof payload.auto_hide_seconds === "number" && isFinite(payload.auto_hide_seconds)
        ? Math.max(0, payload.auto_hide_seconds)
        : 0;
    state.hidden = false;
    scheduleHide();

    // Editing captures every pointer (including misses) so dragging a control
    // never also drives the game underneath it.
    root.style.pointerEvents = state.editing ? "auto" : "none";
    root.style.background = state.editing
      ? color((payload.colors || {}).surface, DEFAULT_COLORS.surface) + "40"
      : "transparent";
    root.setAttribute("data-profile", String(payload.profile || "off"));
    root.setAttribute("data-editing", state.editing ? "true" : "false");
    root.setAttribute("data-edit-mode", state.editMode);

    renderElements(root, payload);

    // Built last and on top: the guides measure the controls, and the frame's
    // handles have to be grabbable through them. Built even with no controls
    // drawn — a canvas can be resized on a profile that shows none.
    if (state.editMode === "viewport") {
      buildGuides(root, payload.colors || {});
      buildFrame(root, payload.colors || {});
    }
  }

  function renderElements(root, payload) {
    if (payload.profile === "off" || !Array.isArray(payload.elements)) {
      return;
    }
    payload.elements.forEach(function (element) {
      if (!element || typeof element.id !== "string") {
        return;
      }
      var node = document.createElement("div");
      node.setAttribute("data-element-id", element.id);
      node.setAttribute("role", "button");
      // Keyboard focus would let a hardware keyboard "click" a touch control
      // and desync the ledger, so the controller DOM stays inert to focus.
      node.setAttribute("tabindex", "-1");
      node.setAttribute("aria-label", String(element.label || element.id));
      // Virtual-gamepad glyphs follow the live binding; labeled actions keep
      // their engine wording. The engine decides which of the two is filled.
      node.textContent = String(element.glyph || element.label || "");
      styleButton(node, element, payload, false);
      attachHandlers(node, element.id);
      root.appendChild(node);
      state.nodes[element.id] = node;
    });
  }

  function onLifecycleLoss() {
    releaseAllLocal();
  }

  window.addEventListener("blur", onLifecycleLoss);
  window.addEventListener("pagehide", onLifecycleLoss);
  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "hidden") {
      onLifecycleLoss();
    }
  });

  function currentOrientation() {
    return window.innerHeight > window.innerWidth ? "portrait" : "landscape";
  }

  // Only a real orientation FLIP replaces the layout. Mobile browsers fire
  // resize continuously as the URL bar collapses and the on-screen keyboard
  // opens; reporting those would drop a held control mid-press every time.
  function reportOrientation() {
    var next = currentOrientation();
    if (next === state.orientation) {
      return;
    }
    state.orientation = next;
    releaseAllLocal();
    send({ type: "orientation", orientation: next });
  }

  // Window metrics, unlike orientation, DO follow every resize: the mobile URL bar
  // collapsing changes the height the canvas has to fit into, and a canvas left at
  // the old height either overlaps the controls or leaves a gap. Debounced because
  // that collapse animates, and each report costs a round trip through the engine.
  // Reporting the WINDOW (never the canvas) is what keeps this from oscillating —
  // Godot's reply resizes the canvas, which cannot change window.innerHeight.
  var metricsTimer = null;

  function reportMetrics() {
    send({
      type: "metrics",
      width: window.innerWidth,
      height: window.innerHeight,
      dpr: window.devicePixelRatio || 1,
    });
  }

  function scheduleMetrics() {
    if (metricsTimer !== null) {
      clearTimeout(metricsTimer);
    }
    metricsTimer = setTimeout(function () {
      metricsTimer = null;
      reportMetrics();
    }, 150);
  }

  // Re-applies geometry to the controls already on screen. Deliberately NOT a
  // re-render: rebuilding the DOM would drop whatever the player is holding, and
  // a resize (the URL bar collapsing mid-press) is exactly when that would hurt.
  function restyle() {
    if (!state.payload || !Array.isArray(state.payload.elements)) {
      return;
    }
    // `state.active` is pointerId -> element id, so held-ness is a value lookup.
    // Restyling must preserve it or a control would visually pop back up while
    // the finger is still down.
    var held = {};
    Object.keys(state.active).forEach(function (pointer) {
      held[state.active[pointer]] = true;
    });
    state.payload.elements.forEach(function (element) {
      var node = state.nodes[element.id];
      if (!node) {
        return;
      }
      // A control being dragged is the one thing whose POSITION the shell knows
      // better than the payload does — the engine is not told until the finger
      // lifts — so its geometry is restored after styling. Everything else
      // (the selection outline above all) still has to be applied, or grabbing
      // a control would leave it unmarked for as long as it was held.
      var dragged = state.drag !== null && state.drag.id === element.id;
      var left = node.style.left;
      var top = node.style.top;
      styleButton(node, element, state.payload, held[element.id] === true);
      if (dragged) {
        node.style.left = left;
        node.style.top = top;
      }
    });
    // The controls have just moved, so the guide drawn around them is stale.
    // The frame is left alone while a handle is held: the engine has not been
    // told where the finger is yet, so its last rect is the older answer.
    refreshGuides();
    if (state.frameDrag === null) {
      positionFrame(currentCanvasRect());
    }
  }

  function onViewportChange() {
    reportOrientation();
    restyle();
    scheduleMetrics();
  }

  window.addEventListener("orientationchange", onViewportChange);
  window.addEventListener("resize", onViewportChange);

  window.PrometheusController = {
    version: SUPPORTED_PAYLOAD_VERSION,

    // Engine → shell. Accepts the JSON string Godot produces.
    apply: function (payloadJson) {
      var payload;
      try {
        payload = typeof payloadJson === "string" ? JSON.parse(payloadJson) : payloadJson;
      } catch (err) {
        return false;
      }
      if (!payload || payload.payload_version !== SUPPORTED_PAYLOAD_VERSION) {
        return false; // Fail closed rather than drawing a half-understood layout.
      }
      releaseAllLocal();
      render(payload);
      return true;
    },

    setBridge: function (fn) {
      state.bridge = fn;
      state.orientation = currentOrientation();
      send({ type: "orientation", orientation: state.orientation });
      // Immediately, not debounced: the engine cannot size the canvas until it
      // knows the window, and until it does the player is looking at the
      // pre-boot full-window rect with controls sitting on top of the game.
      reportMetrics();
    },

    // Engine → shell, selection only. Deliberately NOT part of `apply`: that
    // rebuilds every control, and the tap that selects is the same tap that
    // starts a drag, so a full re-render here throws away the node being dragged.
    select: function (elementId) {
      var next = typeof elementId === "string" ? elementId : "";
      if (state.selected === next) {
        return;
      }
      state.selected = next;
      restyle();
    },

    // Engine → shell, canvas geometry only. The fourth thing split out of `apply`
    // and for the fourth time the same reason: a rebuild drops held controls.
    //
    // This is also how the Game View editor learns what its drag actually
    // produced. The engine clamps the reported rectangle to the model minimum and
    // may aspect-lock it, so the rect that comes back is not always the one the
    // finger dropped — and a frame left where the finger was would be drawn
    // somewhere the canvas is not.
    canvas: function (rectJson) {
      var rect;
      try {
        rect = typeof rectJson === "string" ? JSON.parse(rectJson) : rectJson;
      } catch (err) {
        return false;
      }
      if (!rect || !isFinite(rect.width) || !isFinite(rect.height)) {
        return false;
      }
      state.canvasRect = { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
      // Never while a drag is in flight: the frame is showing where the finger is,
      // which the engine has not been told about yet.
      if (state.frameDrag === null) {
        positionFrame(state.canvasRect);
      }
      return true;
    },

    // Engine → shell, timing only. Deliberately NOT part of `apply` for the same
    // reason as `select`: changing a timeout must not rebuild every control.
    autoHide: function (seconds) {
      state.autoHide =
        typeof seconds === "number" && isFinite(seconds) && seconds > 0 ? seconds : 0;
      // Through `wake()`, so turning auto-hide off brings back controls that are
      // already faded — otherwise the setting would appear not to work until the
      // player happened to touch the screen.
      wake();
    },

    orientation: currentOrientation,

    teardown: function () {
      cancelHideTimer();
      releaseAllLocal();
      if (state.root && state.root.isConnected) {
        state.root.parentNode.removeChild(state.root);
      }
      state.root = null;
      state.nodes = {};
      state.payload = null;
      state.frame = null;
      state.handles = {};
      state.guides = null;
      state.frameDrag = null;
    },

    // Read-only view for the Playwright suite.
    debugState: function () {
      return {
        editing: state.editing,
        profile: state.payload ? state.payload.profile : "off",
        elements: Object.keys(state.nodes),
        active: Object.keys(state.active).length,
        selected: state.selected,
        dragging: state.drag ? state.drag.id : "",
        autoHide: state.autoHide,
        hidden: state.hidden,
        editMode: state.editMode,
        frame: state.frame
          ? {
              x: parseFloat(state.frame.style.left),
              y: parseFloat(state.frame.style.top),
              width: parseFloat(state.frame.style.width),
              height: parseFloat(state.frame.style.height),
              overlapsControls: state.frame.getAttribute("data-overlaps-controls") === "true",
            }
          : null,
        handles: Object.keys(state.handles),
      };
    },
  };
})();
