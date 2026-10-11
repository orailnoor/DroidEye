import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_state.dart';
import '../globe/globe_controller.dart';
import 'control_sheet.dart';

/// Full-screen globe with a single menu button.
class GlobeScreen extends StatefulWidget {
  const GlobeScreen({super.key, required this.state});

  final AppState state;

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> {
  GlobeController get globe => widget.state.globe;

  @override
  void initState() {
    super.initState();
    globe.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: globe,
        builder: (context, _) {
          final status = globe.status;
          return Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: globe.webView),
              if (status == GlobeStatus.loading) const _LoadingOverlay(),
              if (status == GlobeStatus.failed)
                _ErrorOverlay(message: globe.error, onRetry: globe.load),
              if (status == GlobeStatus.ready)
                Positioned(
                  right: 16,
                  bottom: 16 + MediaQuery.paddingOf(context).bottom,
                  child: FloatingActionButton(
                    tooltip: 'Controls',
                    onPressed: () => ControlSheet.show(context, widget.state),
                    child: const Icon(Icons.menu),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('DroidEye', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              const SizedBox(width: 160, child: LinearProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                'Connecting to the globe. The first start can take up to a minute.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                message ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
