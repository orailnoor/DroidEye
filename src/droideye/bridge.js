// Bridge between the DroidEye Flutter app and the globe.
//
// The Flutter app loads this page with ?app=flutter. In that mode the web UI is
// hidden for good and Flutter draws every control natively. Flutter calls
//   DroidEyeBridge.run(requestId, actionName, args)
// and receives results through the `DroidEye` JavaScript channel as JSON:
//   { type: 'ready', version }
//   { type: 'result', id, ok, result?, error? }

const BRIDGE_VERSION = 1;

// Actions the app is allowed to call. Names match the globe's action catalog.
const ALLOWED_ACTIONS = new Set([
  'fly_to_location',
  'zoom_to_globe',
  'adjust_camera_zoom',
  'set_layer_visibility',
  'set_visual_style',
  'set_map_stack',
  'set_hud',
  'set_context_mode',
  'get_current_view_state',
]);

export function isFlutterApp() {
  try {
    return new URLSearchParams(location.search).get('app') === 'flutter';
  } catch {
    return false;
  }
}

function post(message) {
  const channel = globalThis.DroidEye;
  if (channel && typeof channel.postMessage === 'function')
    channel.postMessage(JSON.stringify(message));
}

function keepCleanView() {
  const enable = () => {
    if (document.body.classList.contains('ui-clean-view')) return;
    const toggle = document.getElementById('clean-view-toggle');
    if (toggle) toggle.click();
    else document.body.classList.add('ui-clean-view');
  };
  enable();
  // Keyboard shortcuts or app code must never bring the web UI back.
  new MutationObserver(enable).observe(document.body, {
    attributes: true,
    attributeFilter: ['class'],
  });
}

export function installFlutterBridge() {
  if (!isFlutterApp()) return false;
  document.body.classList.add('droideye-embedded');
  keepCleanView();

  const runner = () => globalThis.__godsEyeView?.voiceCommands?.runner;

  globalThis.DroidEyeBridge = {
    version: BRIDGE_VERSION,
    async run(id, name, args = {}) {
      try {
        if (!ALLOWED_ACTIONS.has(name))
          throw new Error(`Action not allowed: ${name}`);
        const run = runner();
        if (typeof run !== 'function') throw new Error('Globe is not ready');
        const result = await run(name, args ?? {});
        const ok = result?.ok !== false && !result?.error;
        post({ type: 'result', id, ok, result: result ?? null });
      } catch (error) {
        post({
          type: 'result',
          id,
          ok: false,
          error: String(error?.message ?? error),
        });
      }
    },
  };

  post({ type: 'ready', version: BRIDGE_VERSION });
  return true;
}
