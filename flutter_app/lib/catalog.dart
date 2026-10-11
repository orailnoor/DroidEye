import 'package:flutter/material.dart';

/// A data layer the globe can show. [id] matches the globe's layer id.
class LayerInfo {
  const LayerInfo(this.id, this.label, this.icon, {this.note});

  final String id;
  final String label;
  final IconData icon;

  /// Shown under the label, e.g. when a layer needs a server key.
  final String? note;
}

class LayerGroup {
  const LayerGroup(this.title, this.layers);

  final String title;
  final List<LayerInfo> layers;
}

/// Layers offered in the app. Camera, licence-plate and military layers are
/// intentionally left out.
const layerGroups = <LayerGroup>[
  LayerGroup('Movement', [
    LayerInfo('flights', 'Flights', Icons.flight),
    LayerInfo('satellites', 'Satellites', Icons.satellite_alt),
    LayerInfo(
      'ais-live-vessels',
      'Ships',
      Icons.directions_boat,
      note: 'Needs an AISStream key on the server',
    ),
    LayerInfo('transit', 'Public transit', Icons.directions_bus),
  ]),
  LayerGroup('Events', [
    LayerInfo('earthquakes', 'Earthquakes (24h)', Icons.waves),
    LayerInfo('rocket-launches', 'Space launches', Icons.rocket_launch),
    LayerInfo(
      'local-firms',
      'Active fires',
      Icons.local_fire_department,
      note: 'Needs a NASA FIRMS key on the server',
    ),
  ]),
  LayerGroup('Weather', [
    LayerInfo('wind', 'Wind', Icons.air),
    LayerInfo('weather-radar', 'Rain radar', Icons.grain),
    LayerInfo('weather-satellite', 'Satellite clouds', Icons.cloud),
    LayerInfo('weather-lightning', 'Lightning', Icons.bolt),
    LayerInfo('weather-cyclones', 'Cyclones', Icons.cyclone),
  ]),
  LayerGroup('Infrastructure', [
    LayerInfo(
      'telegeography-submarine-cables',
      'Submarine cables',
      Icons.cable,
    ),
    LayerInfo('local-datacenters', 'Data centers', Icons.dns),
    LayerInfo('local-dams', 'Dams', Icons.water),
  ]),
];

/// Visual filters applied to the whole globe.
const visualStyles = <(String id, String label)>[
  ('normal', 'Normal'),
  ('retro', 'CRT'),
  ('surveillance', 'Night vision'),
  ('thermal', 'Thermal'),
  ('anime', 'Anime'),
  ('noir', 'Noir'),
  ('snow', 'Snow'),
];

/// Quick destinations. [query] is passed to the globe's place search.
const quickPlaces = <(String label, String query)>[
  ('New Delhi', 'New Delhi'),
  ('Mumbai', 'Mumbai'),
  ('Dubai', 'Dubai'),
  ('London', 'London'),
  ('New York', 'New York'),
  ('Tokyo', 'Tokyo'),
  ('Paris', 'Paris'),
  ('San Francisco', 'San Francisco'),
];
