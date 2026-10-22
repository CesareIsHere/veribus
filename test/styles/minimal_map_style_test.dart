import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:veribus/styles/minimal_map_style.dart';

void main() {
  test('the light and the dark map are two themes for the renderer: it tells them apart by their id', () {
    // Without an id both are "default" and the map keeps the tiles of the first one after the app changes mode.
    final light = vtr.ThemeReader().read(minimalMapStyle(Brightness.light));
    final dark = vtr.ThemeReader().read(minimalMapStyle(Brightness.dark));
    expect(light.id, isNot(dark.id));
    expect(light.id, 'veribus-minimal-light');
  });
}
