import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'globe/globe_controller.dart';
import 'ui/globe_screen.dart';

/// Server that hosts the globe. Override at build time with
/// `--dart-define=DROIDEYE_SERVER=https://example.com`.
const serverUrl = String.fromEnvironment(
  'DROIDEYE_SERVER',
  defaultValue: 'https://droideye.onrender.com',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final state = AppState(GlobeController(serverUrl: serverUrl));
  await state.restore();
  runApp(DroidEyeApp(state: state));
}

class DroidEyeApp extends StatelessWidget {
  const DroidEyeApp({super.key, required this.state});

  final AppState state;

  static const _accent = Color(0xFF78DCFF);

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
    ).copyWith(primary: _accent, surface: const Color(0xFF0B141C));

    return MaterialApp(
      title: 'DroidEye',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: GlobeScreen(state: state),
    );
  }
}
