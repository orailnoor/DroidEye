# DroidEye Android app

The Flutter app for DroidEye. It shows the DroidEye server's 3D globe in a full-screen web view and provides native controls for layers, places and display settings.

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=DROIDEYE_SERVER=http://192.168.1.10:4173
```

Without `DROIDEYE_SERVER`, the app uses https://droideye.onrender.com.

See the [main README](../README.md) for setup, building and hosting.
