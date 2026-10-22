import 'package:flutter/material.dart';
import 'package:veribus/core/config.dart';

/// Material 3 theme. Components keep their M3 defaults (sizes, shapes,
/// colors, typography: the system font, Roboto on Android): change `SEED_COLOR`
/// in env/*.json to rebrand and only override here what the brand really needs,
/// never inside widgets. A font downloaded at runtime (google_fonts) is not an
/// option: text is measured with the fallback before it loads and chips clip.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  /// Corner radii (dp): chips and filters, extended FABs, cards, bottom sheets.
  static const double _chip = 8;
  static const double _fab = 16;
  static const double _card = 24;
  static const double _sheet = 28;

  /// The corner radius of a sheet that is drawn by hand (the draggable ones), so it matches the bottom sheets.
  static const double sheetRadius = _sheet;

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(seedColor: AppConfig.seedColor, brightness: brightness);
    final base = ThemeData(colorScheme: colors);
    return base.copyWith(
      // M3 has two text field styles, filled and outlined: pick one app-wide.
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      // Expressive shapes: cards and sheets are soft, chips are rounded squares (the line chips and the filters).
      cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_card))),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(_sheet))),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_chip))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedTextStyle: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fab)),
      ),
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
    required this.bus,
    required this.tram,
    required this.metroA,
    required this.metroB,
    required this.metroC,
    required this.night,
    required this.onTransit,
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
      // Line colors are the same in light and dark: riders know them from the signs. Each has 4.5:1 with white.
      bus: ColorScheme.fromSeed(seedColor: AppConfig.seedColor).primary,
      tram: const Color(0xFF00796B),
      metroA: const Color(0xFFB34700),
      metroB: const Color(0xFF1E56A0),
      metroC: const Color(0xFF2E7D32),
      night: const Color(0xFF2B2A5E),
      onTransit: const Color(0xFFFFFFFF),
    );
  }

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// The device position on a map, and the ring around it (white on any tile, light or dark).
  final Color location;
  final Color onLocation;

  /// The chips of the lines, with the color of what is written on them. The bus is the brand color of the light scheme in
  /// both modes: the primary of the dark scheme is a pastel, and white on it cannot be read.
  final Color bus;
  final Color tram;
  final Color metroA;
  final Color metroB;
  final Color metroC;
  final Color night;
  final Color onTransit;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? location,
    Color? onLocation,
    Color? bus,
    Color? tram,
    Color? metroA,
    Color? metroB,
    Color? metroC,
    Color? night,
    Color? onTransit,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    location: location ?? this.location,
    onLocation: onLocation ?? this.onLocation,
    bus: bus ?? this.bus,
    tram: tram ?? this.tram,
    metroA: metroA ?? this.metroA,
    metroB: metroB ?? this.metroB,
    metroC: metroC ?? this.metroC,
    night: night ?? this.night,
    onTransit: onTransit ?? this.onTransit,
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
          bus: Color.lerp(bus, other.bus, t)!,
          tram: Color.lerp(tram, other.tram, t)!,
          metroA: Color.lerp(metroA, other.metroA, t)!,
          metroB: Color.lerp(metroB, other.metroB, t)!,
          metroC: Color.lerp(metroC, other.metroC, t)!,
          night: Color.lerp(night, other.night, t)!,
          onTransit: Color.lerp(onTransit, other.onTransit, t)!,
        );
}
