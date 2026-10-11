import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:webview_flutter/webview_flutter.dart';

/// Loading state of the embedded globe.
enum GlobeStatus { loading, ready, failed }

/// Result of a globe action.
class GlobeResult {
  const GlobeResult({required this.ok, this.data, this.error});

  final bool ok;
  final Map<String, dynamic>? data;
  final String? error;
}

/// Owns the web view that renders the globe and the message bridge to it.
///
/// The page is loaded with `?app=flutter`, which hides the web UI and exposes
/// `DroidEyeBridge.run(id, action, args)`. Replies arrive on the `DroidEye`
/// JavaScript channel.
class GlobeController extends ChangeNotifier {
  GlobeController({required this.serverUrl}) {
    webView = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel('DroidEye', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _fail('Could not reach the DroidEye server.');
            }
          },
          onHttpError: (error) {
            final uri = error.request?.uri.toString() ?? '';
            if (uri.startsWith(serverUrl) &&
                (error.response?.statusCode ?? 0) >= 500) {
              _fail('The DroidEye server returned an error.');
            }
          },
        ),
      );
  }

  /// Base address of the DroidEye server, without a trailing slash.
  final String serverUrl;

  late final WebViewController webView;

  /// How long the free server may take to wake up before giving up.
  static const loadTimeout = Duration(seconds: 120);

  GlobeStatus _status = GlobeStatus.loading;
  GlobeStatus get status => _status;

  String? _error;
  String? get error => _error;

  int _nextId = 1;
  final Map<int, Completer<GlobeResult>> _pending = {};
  Timer? _timeout;

  /// Called once each time the globe becomes ready, e.g. to restore settings.
  VoidCallback? onReady;

  Uri get _pageUri => Uri.parse('$serverUrl/?app=flutter');

  Future<void> load() async {
    _status = GlobeStatus.loading;
    _error = null;
    notifyListeners();
    _timeout?.cancel();
    _timeout = Timer(loadTimeout, () {
      if (_status == GlobeStatus.loading) {
        _fail('The server is taking too long to respond.');
      }
    });
    await webView.loadRequest(_pageUri);
  }

  void _fail(String message) {
    if (_status == GlobeStatus.ready) return;
    _timeout?.cancel();
    _status = GlobeStatus.failed;
    _error = message;
    _failPending(message);
    notifyListeners();
  }

  void _failPending(String message) {
    for (final completer in _pending.values) {
      completer.complete(GlobeResult(ok: false, error: message));
    }
    _pending.clear();
  }

  void _onMessage(JavaScriptMessage message) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    switch (json['type']) {
      case 'ready':
        _timeout?.cancel();
        _status = GlobeStatus.ready;
        _error = null;
        notifyListeners();
        onReady?.call();
      case 'result':
        final id = json['id'];
        final completer = id is int ? _pending.remove(id) : null;
        completer?.complete(
          GlobeResult(
            ok: json['ok'] == true,
            data: json['result'] is Map<String, dynamic>
                ? json['result'] as Map<String, dynamic>
                : null,
            error: json['error'] as String?,
          ),
        );
    }
  }

  /// Runs a globe action, such as `set_layer_visibility`.
  Future<GlobeResult> run(
    String action, [
    Map<String, dynamic> args = const {},
  ]) {
    if (_status != GlobeStatus.ready) {
      return Future.value(
        const GlobeResult(ok: false, error: 'Globe is not ready'),
      );
    }
    final id = _nextId++;
    final completer = Completer<GlobeResult>();
    _pending[id] = completer;
    final script =
        'window.DroidEyeBridge && DroidEyeBridge.run($id, ${jsonEncode(action)}, ${jsonEncode(args)});';
    webView.runJavaScript(script).catchError((Object e) {
      _pending.remove(id)?.complete(GlobeResult(ok: false, error: '$e'));
    });
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pending.remove(id);
        return const GlobeResult(ok: false, error: 'The globe did not respond');
      },
    );
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _failPending('Closed');
    super.dispose();
  }
}
