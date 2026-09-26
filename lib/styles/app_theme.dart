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
  });

  factory AppColors.from(Brightness brightness) {
    // Seeded the same way as the scheme, so tones match light/dark.
    final green = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: brightness);
    return AppColors(
      success: green.primary,
      onSuccess: green.onPrimary,
      successContainer: green.primaryContainer,
      onSuccessContainer: green.onPrimaryContainer,
    );
  }

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  @override
  AppColors copyWith({Color? success, Color? onSuccess, Color? successContainer, Color? onSuccessContainer}) =>
      AppColors(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          success: Color.lerp(success, other.success, t)!,
          onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
          successContainer: Color.lerp(successContainer, other.successContainer, t)!,
          onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
        );
}
