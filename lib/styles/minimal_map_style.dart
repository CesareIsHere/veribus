import 'package:flutter/material.dart';

/// The map the app draws: roads, water, green areas and the names of streets and districts, nothing else. No
/// buildings, shops, house numbers, rail or borders: a navigation-style base that leaves the lines, stops and vehicles
/// as the only things to look at. Mapbox GL style for the OpenMapTiles schema (the source layers of OpenFreeMap).
Map<String, dynamic> minimalMapStyle(Brightness brightness) {
  final p = brightness == Brightness.dark ? _Palette.dark : _Palette.light;
  return {
    'version': 8,
    'name': 'veribus-minimal-${brightness.name}',
    'sources': {
      'openmaptiles': {'type': 'vector'},
    },
    'layers': [
      {
        'id': 'background',
        'type': 'background',
        'paint': {'background-color': p.land},
      },
      {
        'id': 'landcover',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'landcover',
        'filter': ['in', 'class', 'wood', 'grass'],
        'paint': {'fill-color': p.green, 'fill-opacity': 0.7},
      },
      {
        'id': 'park',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'park',
        'paint': {'fill-color': p.green, 'fill-opacity': 0.9},
      },
      {
        'id': 'water',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'water',
        'paint': {'fill-color': p.water},
      },
      {
        'id': 'waterway',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'waterway',
        'paint': {
          'line-color': p.water,
          'line-width': _stops([
            [10, 0.5],
            [14, 2],
            [18, 6],
          ]),
        },
      },
      // Footpaths, only when close enough to walk to a stop.
      {
        'id': 'path',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
        'minzoom': 17,
        'filter': ['==', 'class', 'path'],
        'layout': {'line-join': 'round'},
        'paint': {
          'line-color': p.casing,
          'line-dasharray': [2, 2],
          'line-width': _stops([
            [16, 0.8],
            [19, 2],
          ]),
        },
      },
      for (final tier in p.roads) _road(tier, casing: true),
      for (final tier in p.roads) _road(tier, casing: false),
      {
        'id': 'road_name',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'transportation_name',
        'minzoom': 14,
        'filter': ['in', 'class', 'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'minor'],
        'layout': {
          'text-field': '{name}',
          'text-font': ['Roboto'],
          'text-size': _stops([
            [14, 10],
            [18, 13],
          ]),
          'symbol-placement': 'line',
        },
        'paint': {'text-color': p.roadLabel, 'text-halo-color': p.halo, 'text-halo-width': 1.5},
      },
      {
        'id': 'water_name',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'water_name',
        'filter': ['==', r'$type', 'Point'],
        'layout': {
          'text-field': '{name}',
          'text-font': ['Roboto Italic'],
          'text-size': 12,
          'text-max-width': 10,
        },
        'paint': {'text-color': p.waterLabel, 'text-halo-color': p.halo, 'text-halo-width': 1.5},
      },
      {
        'id': 'place_district',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'place',
        'minzoom': 12,
        'maxzoom': 17,
        'filter': ['in', 'class', 'suburb', 'quarter', 'neighbourhood'],
        'layout': {
          'text-field': '{name}',
          'text-font': ['Roboto'],
          'text-size': _stops([
            [12, 11],
            [16, 14],
          ]),
          'text-transform': 'uppercase',
          'text-letter-spacing': 0.08,
          'text-max-width': 8,
        },
        'paint': {'text-color': p.placeLabel, 'text-halo-color': p.halo, 'text-halo-width': 1.5},
      },
      {
        'id': 'place_city',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'place',
        'maxzoom': 14,
        'filter': ['in', 'class', 'city', 'town', 'village'],
        'layout': {
          'text-field': '{name}',
          'text-font': ['Roboto'],
          'text-size': _stops([
            [8, 12],
            [13, 18],
          ]),
          'text-max-width': 8,
        },
        'paint': {'text-color': p.cityLabel, 'text-halo-color': p.halo, 'text-halo-width': 2},
      },
    ],
  };
}

/// The color of the land: what the map shows while its tiles load.
Color minimalMapLand(Brightness brightness) => Color(
  int.parse((brightness == Brightness.dark ? _Palette.dark : _Palette.light).land.substring(1), radix: 16) | 0xFF000000,
);

Map<String, dynamic> _stops(List<List<num>> stops) => {'base': 1.2, 'stops': stops};

/// One road class group: a casing (the outline, drawn under every road so crossings read cleanly) and the fill.
Map<String, dynamic> _road(_Road r, {required bool casing}) {
  // The casing is the same road, a bit wider.
  final outline = casing ? 1.4 : 0.0;
  return {
    'id': 'road_${r.id}${casing ? '_casing' : ''}',
    'type': 'line',
    'source': 'openmaptiles',
    'source-layer': 'transportation',
    'minzoom': r.minZoom,
    'filter': ['in', 'class', ...r.classes],
    'layout': {'line-join': 'round', 'line-cap': 'round'},
    'paint': {
      'line-color': casing ? r.casing : r.fill,
      'line-width': _stops([
        for (final [zoom, width] in r.widths) [zoom, width + outline],
      ]),
    },
  };
}

class _Road {
  const _Road(this.id, this.classes, this.fill, this.casing, this.minZoom, this.widths);

  final String id;
  final List<String> classes;
  final String fill;
  final String casing;
  final int minZoom;

  /// Zoom → width in pixels.
  final List<List<num>> widths;
}

enum _Palette {
  light(
    land: '#F1F3F4',
    water: '#BBD9F5',
    green: '#D5EAD2',
    casing: '#D5D8DC',
    roadLabel: '#5F6368',
    placeLabel: '#80868B',
    cityLabel: '#3C4043',
    waterLabel: '#4F83BD',
    halo: '#F1F3F4',
    roads: [
      _Road(
        'service',
        ['service', 'track'],
        '#FFFFFF',
        '#DADCE0',
        16,
        [
          [16, 0.6],
          [17, 3],
          [19, 8],
        ],
      ),
      _Road(
        'minor',
        ['minor'],
        '#FFFFFF',
        '#D5D8DC',
        14,
        [
          [14, 0.8],
          [15, 3],
          [17, 7],
          [19, 16],
        ],
      ),
      _Road(
        'tertiary',
        ['tertiary'],
        '#FFFFFF',
        '#C9CDD2',
        12,
        [
          [12, 0.6],
          [13, 2],
          [15, 4.5],
          [17, 9],
          [19, 20],
        ],
      ),
      _Road(
        'secondary',
        ['secondary'],
        '#FFFFFF',
        '#BEC3C9',
        9,
        [
          [9, 0.6],
          [12, 2],
          [14, 4],
          [16, 8],
          [18, 15],
          [19, 22],
        ],
      ),
      _Road(
        'primary',
        ['primary'],
        '#FFF3C9',
        '#E3CF8D',
        7,
        [
          [7, 0.6],
          [11, 2],
          [14, 4.5],
          [16, 9],
          [18, 16],
          [19, 24],
        ],
      ),
      _Road(
        'motorway',
        ['trunk', 'motorway'],
        '#FCDE8C',
        '#E0B54C',
        5,
        [
          [5, 0.6],
          [10, 2],
          [13, 4.5],
          [16, 10],
          [18, 17],
          [19, 26],
        ],
      ),
    ],
  ),
  dark(
    land: '#1F2227',
    water: '#1B3047',
    green: '#223326',
    casing: '#2B2F35',
    roadLabel: '#AEB3B9',
    placeLabel: '#8F959C',
    cityLabel: '#D5D8DC',
    waterLabel: '#6F9BCB',
    halo: '#1F2227',
    roads: [
      _Road(
        'service',
        ['service', 'track'],
        '#33373D',
        '#272A2F',
        16,
        [
          [16, 0.6],
          [17, 3],
          [19, 8],
        ],
      ),
      _Road(
        'minor',
        ['minor'],
        '#3A3F46',
        '#2A2D33',
        14,
        [
          [14, 0.8],
          [15, 3],
          [17, 7],
          [19, 16],
        ],
      ),
      _Road(
        'tertiary',
        ['tertiary'],
        '#444A52',
        '#2A2D33',
        12,
        [
          [12, 0.6],
          [13, 2],
          [15, 4.5],
          [17, 9],
          [19, 20],
        ],
      ),
      _Road(
        'secondary',
        ['secondary'],
        '#4E555E',
        '#2A2D33',
        9,
        [
          [9, 0.6],
          [12, 2],
          [14, 4],
          [16, 8],
          [18, 15],
          [19, 22],
        ],
      ),
      _Road(
        'primary',
        ['primary'],
        '#6B5F3C',
        '#3A3524',
        7,
        [
          [7, 0.6],
          [11, 2],
          [14, 4.5],
          [16, 9],
          [18, 16],
          [19, 24],
        ],
      ),
      _Road(
        'motorway',
        ['trunk', 'motorway'],
        '#8A7440',
        '#3E3520',
        5,
        [
          [5, 0.6],
          [10, 2],
          [13, 4.5],
          [16, 10],
          [18, 17],
          [19, 26],
        ],
      ),
    ],
  );

  _Palette({
    required this.land,
    required this.water,
    required this.green,
    required this.casing,
    required this.roadLabel,
    required this.placeLabel,
    required this.cityLabel,
    required this.waterLabel,
    required this.halo,
    required this.roads,
  });

  final String land;
  final String water;
  final String green;
  final String casing;
  final String roadLabel;
  final String placeLabel;
  final String cityLabel;
  final String waterLabel;
  final String halo;

  /// From the smallest to the biggest road: the biggest are drawn on top.
  final List<_Road> roads;
}
