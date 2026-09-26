import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Material 3 layout tokens. Everything sits on the 4dp grid:
/// use these instead of raw numbers so spacing stays consistent.
abstract final class Spacing {
  static const double xs = 4;
  static const double s = 8; // between buttons in a group, chips, icon + label
  static const double m = 12;
  static const double l = 16; // compact page margin, between form fields
  static const double xl = 24; // medium+ page margin, between sections
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// M3 window size classes (https://m3.material.io/foundations/layout/applying-layout/window-size-classes).
enum WindowSize {
  compact,
  medium,
  expanded,
  large;

  static WindowSize of(BuildContext context) => switch (MediaQuery.sizeOf(context).width) {
    < 600 => compact,
    < 840 => medium,
    < 1200 => expanded,
    _ => large,
  };
}

/// Max widths keeping lines and forms readable on large screens.
abstract final class ContentWidth {
  static const double form = 480;
  static const double body = 840;

  /// Multi-column pages (dashboards) on expanded/large windows.
  static const double wide = 1200;
}

extension LayoutContext on BuildContext {
  WindowSize get windowSize => WindowSize.of(this);

  /// 16dp on phones, 24dp from tablets up (M3 margins).
  double get pageMargin => windowSize == WindowSize.compact ? Spacing.l : Spacing.xl;

  /// Padding for scrollable page content: page margin, then centered within [maxWidth].
  EdgeInsets pagePadding({double maxWidth = ContentWidth.body, double top = Spacing.l, double bottom = Spacing.xl}) {
    final width = MediaQuery.sizeOf(this).width;
    final side = math.max(pageMargin, (width - maxWidth) / 2);
    return EdgeInsets.fromLTRB(side, top, side, bottom);
  }

  /// Like [pagePadding] but without the margin, for lists whose tiles already
  /// have their own 16dp inset (ListTile).
  EdgeInsets listPadding({double maxWidth = ContentWidth.body, double bottom = Spacing.xl}) {
    final width = MediaQuery.sizeOf(this).width;
    final side = math.max(0, (width - maxWidth) / 2).toDouble();
    return EdgeInsets.fromLTRB(side, 0, side, bottom);
  }
}
