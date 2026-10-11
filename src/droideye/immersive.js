// DroidEye immersive mode: on phones (and inside the Android app) the globe
// starts full screen with every control hidden. A single round menu button
// brings the controls back and hides them again.
//
// It drives the app's existing "clean view" through its own buttons, so the
// app's state (Clean UI toggle, panel layout) stays in sync.

const PHONE_QUERY = '(max-width: 760px)';
const MENU_ICON =
  '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16"/></svg>';
const CLOSE_ICON =
  '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg>';

function isNativeApp() {
  return Boolean(globalThis.Capacitor?.isNativePlatform?.());
}

export function shouldUseImmersive() {
  return isNativeApp() || globalThis.matchMedia?.(PHONE_QUERY).matches === true;
}

function isClean() {
  return document.body.classList.contains('ui-clean-view');
}

function setClean(enabled) {
  if (isClean() === enabled) return;
  const button = document.getElementById(
    enabled ? 'clean-view-toggle' : 'clean-view-exit',
  );
  if (button) button.click();
  else document.body.classList.toggle('ui-clean-view', enabled);
}

export function installImmersiveMode() {
  if (!shouldUseImmersive() || document.getElementById('droideye-menu-btn'))
    return;

  document.body.classList.add('droideye-immersive');

  const button = document.createElement('button');
  button.id = 'droideye-menu-btn';
  button.type = 'button';
  document.body.append(button);

  const sync = () => {
    const hidden = isClean();
    button.innerHTML = hidden ? MENU_ICON : CLOSE_ICON;
    button.setAttribute(
      'aria-label',
      hidden ? 'Show controls' : 'Hide controls',
    );
    button.title = button.getAttribute('aria-label');
    button.setAttribute('aria-expanded', String(!hidden));
  };

  button.addEventListener('click', () => {
    setClean(!isClean());
    sync();
  });
  new MutationObserver(sync).observe(document.body, {
    attributes: true,
    attributeFilter: ['class'],
  });

  setClean(true);
  sync();
}
