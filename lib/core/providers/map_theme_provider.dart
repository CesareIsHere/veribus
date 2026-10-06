import 'package:flutter/material.dart' hide Theme;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'package:veribus/styles/minimal_map_style.dart';

part 'map_theme_provider.g.dart';

/// The map style parsed once per brightness: reading it is not free and the layer compares themes by identity.
@Riverpod(keepAlive: true)
Theme mapTheme(Ref ref, Brightness brightness) => ThemeReader().read(minimalMapStyle(brightness));
