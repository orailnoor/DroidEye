# DroidEye

Live open-source intelligence on a photorealistic 3D globe, built for Android. Track real flights, satellites, earthquakes, weather and space launches from your phone.

DroidEye is an Android adaptation of [God's Eye View](https://github.com/bilawalsidhu/gods-eye-view) by Bilawal Sidhu, released under the MIT License. It is an independent, non-commercial project and is not affiliated with or endorsed by the original author.

## Overview

DroidEye has two parts:

- **Android app** (`flutter_app/`): a Flutter app. All controls (layers, place search, display settings) are native Flutter widgets.
- **Server** (repository root): a CesiumJS globe built with Vite, plus the `/api` proxies that fetch live data. It is hosted on Render.

Flutter has no photorealistic 3D globe of its own, so the app shows the server's globe in a full-screen web view and controls it through a small JavaScript bridge.

```
Flutter app                                  DroidEye server
native controls  ──DroidEyeBridge.run()──▶   CesiumJS globe
                 ◀──DroidEye channel──────   /api data proxies
```

Phone browsers can also open the server directly. On small screens the globe starts full screen with a single menu button that shows or hides the web controls.

## Features

| Layer | Description | Source |
| --- | --- | --- |
| Flights | Live aircraft positions and recent tracks | OpenSky, adsb.lol |
| Satellites | Active satellite catalogue, colour-coded by class | CelesTrak |
| Earthquakes | Seismic events from the last 24 hours | USGS |
| Space launches | Launches from the last 30 days | Launch Library 2 |
| Weather | Wind, rain radar, satellite clouds, lightning and cyclone tracks | NOAA, ECMWF |
| Active fires | Satellite fire detections (server key required) | NASA FIRMS |
| Ships | Live vessel positions (server key and an always-on server required) | AISStream |
| Public transit | Live vehicle positions in supported cities | City transit agencies |
| Infrastructure | Submarine cables, data centres and dams | TeleGeography, OpenStreetMap |

Most layers work without any API key. The app also offers visual styles (night vision, thermal, CRT and others), a camera overlay with coordinates, and place search by name or by `lat, lon`.

Not included in the app: voice control, camera feeds, licence-plate cameras and military layers.

## Install

1. Open the [Releases](https://github.com/orailnoor/DroidEye/releases) page and download the APK for your phone. Most current phones use `arm64-v8a`.
2. Open the file on your phone and allow installation from unknown sources when prompted.
3. Launch DroidEye. The hosted server sleeps when idle, so the first launch can take up to a minute. If it takes longer, the app shows a retry screen.

Requires Android 7.0 (API 24) or later.

## Development

### Requirements

- Node.js 24.x or 26.x
- Flutter 3.38 or later, with the Android SDK (Android Studio provides it)

### Run the server locally

```bash
npm ci
npm run dev -- --host 0.0.0.0 --port 4173
```

Open `http://localhost:4173` in a browser.

To test the app bridge in a desktop browser, open `http://localhost:4173/?app=flutter`, then run this in the developer console:

```js
window.DroidEye = { postMessage: console.log };
DroidEyeBridge.run(1, 'fly_to_location', { query: 'New Delhi' });
```

### Run the Android app

With a phone connected over USB and USB debugging enabled:

```bash
cd flutter_app
flutter pub get
flutter run
```

The app uses the hosted server by default. To use your local server, pass your computer's local IP address:

```bash
flutter run --dart-define=DROIDEYE_SERVER=http://192.168.1.10:4173
```

Plain `http` addresses are for local testing only. Release builds should use an `https` server.

### Build a release APK

```bash
cd flutter_app
flutter build apk --release --split-per-abi
```

The APKs are written to `flutter_app/build/app/outputs/flutter-apk/`.

### Checks

```bash
npm test
```

```bash
cd flutter_app && flutter analyze && flutter test
```

### Project layout

| Path | Contents |
| --- | --- |
| `flutter_app/lib/globe/` | Web view, bridge client, load timeout and retry |
| `flutter_app/lib/ui/` | Globe screen and the control sheet |
| `flutter_app/lib/app_state.dart` | Saved layers and display settings |
| `flutter_app/lib/catalog.dart` | Layers, styles and quick places offered in the app |
| `src/droideye/` | Web-side bridge, phone browser mode and voice removal |
| `render.yaml` | Render hosting blueprint |

The older Capacitor app (`android/`, `capacitor.config.json`, `droideye/`) has been replaced by the Flutter app and will be removed.

## Hosting

The repository includes a `render.yaml` blueprint for Render's free plan.

1. In Render, choose **New → Blueprint** and select this repository.
2. Apply the blueprint. Render builds the globe and serves it with the data proxies.
3. Build the app with the service URL as `DROIDEYE_SERVER`.

Free-plan limits: the service sleeps after 15 minutes without traffic, and has 512 MB of memory and 5 GB of monthly bandwidth. The ships layer needs a continuously running server and is therefore optional.

## Configuration

No keys are required to start. Optional keys unlock more layers and are set as environment variables on the server (see `.env.example`):

| Variable | Enables |
| --- | --- |
| `CESIUM_ION_TOKEN` | Google Photorealistic 3D tiles and world terrain |
| `FIRMS_MAP_KEY` | Active fires |
| `AISSTREAM_API_KEY` | Live ships |
| `OPENSKY_CLIENT_ID`, `OPENSKY_CLIENT_SECRET` | Higher flight-polling limits |

Never commit keys to the repository. On Render, add them under the service's **Environment** settings.

## Data and licensing

- Data comes from the public providers listed in [DATA_SOURCES.md](DATA_SOURCES.md). Each provider's terms apply.
- OpenSky, the Cesium ion free tier, Google News RSS and TeleGeography data are licensed for non-commercial use only. DroidEye is a non-commercial project.
- Positions and timings come from third-party feeds and may be delayed or incomplete. Do not use DroidEye for navigation or safety-critical decisions.

## Roadmap

- App icon and splash screen
- Signed release builds published automatically to GitHub Releases
- Larger touch targets and sensible default layers
- Tap a flight or satellite to see its details

## Credits

DroidEye is built on [God's Eye View](https://github.com/bilawalsidhu/gods-eye-view) by Bilawal Sidhu. The original project's history is preserved in this repository.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Bilawal Sidhu. Android adaptation by orailnoor.
