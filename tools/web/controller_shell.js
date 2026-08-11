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
    if (!root.isConnected) {
      document.body.appendChild(root);
    }
    state.root = root;
    return root;
  }

  function styleButton(node, element, payload, pressed) {
    var colors = payload.colors || {};
    var scale = typeof element.scale === "number" ? element.scale : 1;
    var size = Math.round(64 * (scale > 0 ? scale : 1));
    var s = node.style;
    s.position = "absolute";
    s.boxSizing = "border-box";
    s.width = size + "px";
    s.height = size + "px";
    s.marginLeft = -(size / 2) + "px";
    s.marginTop = -(size / 2) + "px";
    s.left = clamp01(element.x) * 100 + "%";
    s.top = clamp01(element.y) * 100 + "%";
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
    if (element.group === "action") {
      var width = Math.round(size * 1.9);
      s.width = width + "px";
      s.marginLeft = -(width / 2) + "px";
      s.fontSize = Math.max(10, Math.round(size / 5)) + "px";
    }
    var opacity = typeof element.opacity === "number" ? element.opacity : 1;
    var global = typeof payload.global_opacity === "number" ? payload.global_opacity : 1;
    s.opacity = String(clamp01(opacity) * clamp01(global));
    s.pointerEvents = "auto";
    s.touchAction = "none";
    s.cursor = "pointer";
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
          return; // The editor owns every pointer while it is open.
        }
        pressPointer(event, elementId);
      },
      { passive: false }
    );

    ["pointerup", "pointercancel", "lostpointercapture"].forEach(function (name) {
      node.addEventListener(
        name,
        function (event) {
          event.preventDefault();
          event.stopPropagation();
          releasePointer(event);
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

  function render(payload) {
    var root = ensureRoot();
    root.textContent = "";
    state.nodes = {};
    state.payload = payload;
    state.editing = payload.editing === true;

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

  window.addEventListener("orientationchange", reportOrientation);
  window.addEventListener("resize", reportOrientation);

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
    },

    orientation: currentOrientation,

    teardown: function () {
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
      };
    },
  };
})();
