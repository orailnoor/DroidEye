import { createStandaloneApplication } from './standalone/application.js';
import { describeError } from './standalone/errors.js';
import { installImmersiveMode } from './droideye/immersive.js';
import { disableVoiceUi } from './droideye/voice.js';
import { installFlutterBridge } from './droideye/bridge.js';
import './droideye/immersive.css';

const application = createStandaloneApplication({
  googleApiKey: import.meta.env.GOOGLE_MAPS_API_KEY,
  cesiumToken: import.meta.env.CESIUM_ION_TOKEN,
  allowQaRegistration: import.meta.env.DEV,
});

application
  .start()
  .then(() => {
    disableVoiceUi();
    if (!installFlutterBridge()) installImmersiveMode();
  })
  .catch((error) => {
    console.error('DroidEye initialization failed:', error);
    const loaderStatus = document.querySelector(
      '#loading-screen .loader-status',
    );
    loaderStatus.textContent = `Error: ${describeError(error)}`;
    loaderStatus.style.color = '#ff4444';
  });

export { application };
