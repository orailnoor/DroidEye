import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'globe/globe_controller.dart';

/// What the user has switched on. Saved on the phone and re-applied to the
/// globe every time it loads.
class AppState extends ChangeNotifier {
  AppState(this.globe) {
    globe.onReady = _applyToGlobe;
  }

  final GlobeController globe;

  static const _layersKey = 'layers';
  static const _styleKey = 'style';
  static const _hudKey = 'hud';

  final Set<String> _layers = {};
  String _style = 'normal';
  bool _hud = false;

  /// Layer ids that are currently switching, to show progress in the UI.
  final Set<String> busy = {};

  Set<String> get layers => Set.unmodifiable(_layers);
  String get style => _style;
  bool get hud => _hud;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _layers
      ..clear()
      ..addAll(prefs.getStringList(_layersKey) ?? const []);
    _style = prefs.getString(_styleKey) ?? 'normal';
    _hud = prefs.getBool(_hudKey) ?? false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_layersKey, _layers.toList());
    await prefs.setString(_styleKey, _style);
    await prefs.setBool(_hudKey, _hud);
  }

  Future<void> _applyToGlobe() async {
    await globe.run('set_hud', {'visible': _hud ? 'on' : 'off'});
    if (_style != 'normal') {
      await globe.run('set_visual_style', {'style': _style});
    }
    for (final id in _layers.toList()) {
      await globe.run('set_layer_visibility', {'layerId': id, 'enabled': true});
    }
  }

  /// Turns a layer on or off. Returns an error message, or null on success.
  Future<String?> setLayer(String id, bool enabled) async {
    busy.add(id);
    notifyListeners();
    final result = await globe.run('set_layer_visibility', {
      'layerId': id,
      'enabled': enabled,
    });
    busy.remove(id);
    if (result.ok) {
      enabled ? _layers.add(id) : _layers.remove(id);
      await _save();
    }
    notifyListeners();
    return result.ok ? null : (result.error ?? _message(result.data));
  }

  Future<String?> setStyle(String style) async {
    final result = await globe.run('set_visual_style', {'style': style});
    if (result.ok) {
      _style = style;
      await _save();
      notifyListeners();
    }
    return result.ok ? null : (result.error ?? _message(result.data));
  }

  Future<String?> setHud(bool visible) async {
    final result = await globe.run('set_hud', {
      'visible': visible ? 'on' : 'off',
    });
    if (result.ok) {
      _hud = visible;
      await _save();
      notifyListeners();
    }
    return result.ok ? null : (result.error ?? _message(result.data));
  }

  /// Flies to a place name or "lat, lon". Returns the matched place label.
  Future<({String? label, String? error})> flyTo(String query) async {
    final result = await globe.run('fly_to_location', {'query': query});
    if (!result.ok) {
      return (
        label: null,
        error: result.error ?? _message(result.data) ?? 'Place not found',
      );
    }
    return (label: result.data?['label'] as String?, error: null);
  }

  Future<void> showWholeGlobe() => globe.run('zoom_to_globe');

  static String? _message(Map<String, dynamic>? data) =>
      (data?['error'] ?? data?['message'] ?? data?['say'])?.toString();
}
