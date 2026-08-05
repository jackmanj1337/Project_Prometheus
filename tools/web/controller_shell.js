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
      if (state.editing && event.target === root) {
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
    // worse here: the player cannot even see what they are hitting.
    s.pointerEvents = state.hidden && !state.editing ? "none" : "auto";
    s.touchAction = "none";
    s.cursor = state.editing ? "move" : "pointer";
    if (state.editing && element.id === state.selected) {
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
        if (state.editing) {
          // The editor owns every pointer while it is open: this one drags the
          // control rather than playing the game underneath it.
          beginDrag(event, node, elementId);
          return;
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
    return state.drag !== null || Object.keys(state.active).length > 0;
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
    state.selected = typeof payload.selected === "string" ? payload.selected : "";
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
      };
    },
  };
})();
