import 'package:flutter/material.dart';

import '../app_state.dart';
import '../catalog.dart';

/// The single control surface: layers, places and display settings.
class ControlSheet extends StatelessWidget {
  const ControlSheet({super.key, required this.state});

  final AppState state;

  static Future<void> show(BuildContext context, AppState state) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface
          .withValues(alpha: 0.96),
      builder: (_) => ControlSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.layers_outlined), text: 'Layers'),
                Tab(icon: Icon(Icons.travel_explore), text: 'Places'),
                Tab(icon: Icon(Icons.tune), text: 'Display'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LayersTab(state: state),
                  _PlacesTab(state: state),
                  _DisplayTab(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

class _LayersTab extends StatelessWidget {
  const _LayersTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final group in layerGroups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                group.title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final layer in group.layers)
              SwitchListTile(
                secondary: state.busy.contains(layer.id)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(layer.icon),
                title: Text(layer.label),
                subtitle: layer.note == null ? null : Text(layer.note!),
                value: state.layers.contains(layer.id),
                onChanged: state.busy.contains(layer.id)
                    ? null
                    : (on) async {
                        final error = await state.setLayer(layer.id, on);
                        if (error != null && context.mounted) {
                          _snack(context, '${layer.label}: $error');
                        }
                      },
              ),
          ],
        ],
      ),
    );
  }
}

class _PlacesTab extends StatefulWidget {
  const _PlacesTab({required this.state});

  final AppState state;

  @override
  State<_PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends State<_PlacesTab> {
  final _query = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _go(String query) async {
    final text = query.trim();
    if (text.isEmpty || _searching) return;
    setState(() => _searching = true);
    final result = await widget.state.flyTo(text);
    if (!mounted) return;
    setState(() => _searching = false);
    if (result.error != null) {
      _snack(context, result.error!);
    } else {
      Navigator.of(context).pop();
      _snack(context, 'Flying to ${result.label ?? text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          onSubmitted: _go,
          decoration: InputDecoration(
            hintText: 'City, place or "lat, lon"',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Go',
                    onPressed: () => _go(_query.text),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, query) in quickPlaces)
              ActionChip(label: Text(label), onPressed: () => _go(query)),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          icon: const Icon(Icons.public),
          label: const Text('Show the whole globe'),
          onPressed: () {
            widget.state.showWholeGlobe();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _DisplayTab extends StatelessWidget {
  const _DisplayTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text('Visual style', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (id, label) in visualStyles)
                ChoiceChip(
                  label: Text(label),
                  selected: state.style == id,
                  onSelected: (_) async {
                    final error = await state.setStyle(id);
                    if (error != null && context.mounted) {
                      _snack(context, error);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Camera overlay'),
            subtitle: const Text('Coordinates and readouts over the globe'),
            value: state.hud,
            onChanged: (on) async {
              final error = await state.setHud(on);
              if (error != null && context.mounted) _snack(context, error);
            },
          ),
          const Divider(height: 32),
          Text(
            'Built on God\'s Eye View by Bilawal Sidhu (MIT License). '
            'Data from public sources including OpenSky, CelesTrak, USGS, NOAA and Launch Library 2.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
