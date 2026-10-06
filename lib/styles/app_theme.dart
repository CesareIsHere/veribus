import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:veribus/core/config.dart';

/// Material 3 theme. Components keep their M3 defaults (sizes, shapes,
/// colors): change `SEED_COLOR` in env/*.json to rebrand and only override
/// here what the brand really needs, never inside widgets.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(seedColor: AppConfig.seedColor, brightness: brightness);
    final base = ThemeData(colorScheme: colors);
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      // M3 has two text field styles, filled and outlined: pick one app-wide.
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      extensions: [AppColors.from(brightness)],
    );
  }
}

/// M3 "custom colors" the ColorScheme doesn't have (e.g. success for income).
/// Each is a tonal palette like the scheme roles: use `color` on surfaces,
/// `container`/`onContainer` for filled areas. Access with `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.location,
    required this.onLocation,
  });

  factory AppColors.from(Brightness brightness) {
    // Seeded the same way as the scheme, so tones match light/dark.
    final green = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: brightness);
    return AppColors(
      success: green.primary,
      onSuccess: green.onPrimary,
      successContainer: green.primaryContainer,
      onSuccessContainer: green.onPrimaryContainer,
      // The "you are here" blue every map app uses: it has to stand out from the route (primary) and the vehicles.
      location: const Color(0xFF1A73E8),
      onLocation: const Color(0xFFFFFFFF),
    );
  }

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// The device position on a map, and the ring around it (white on any tile, light or dark).
  final Color location;
  final Color onLocation;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? location,
    Color? onLocation,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    location: location ?? this.location,
    onLocation: onLocation ?? this.onLocation,
  );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          success: Color.lerp(success, other.success, t)!,
          onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
          successContainer: Color.lerp(successContainer, other.successContainer, t)!,
          onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
          location: Color.lerp(location, other.location, t)!,
          onLocation: Color.lerp(onLocation, other.onLocation, t)!,
        );
}
