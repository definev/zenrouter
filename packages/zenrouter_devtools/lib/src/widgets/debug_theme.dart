import 'package:flutter/material.dart';

/// Theme constants for the debug overlay UI.
///
/// Centralizes all color and style constants to ensure consistency
/// across the debug overlay components.
abstract final class DebugTheme {
  // Background colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundDark = Color(0xFF111111);
  static const Color backgroundLight = Color(0xFF1A1A1A);

  // Border colors
  static const Color border = Color(0xFF333333);
  static const Color borderDark = Color(0xFF222222);
  static const Color borderLight = Color(0xFF2A2A2A);

  // Text colors
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textMuted = Color(0xFF888888);
  static const Color textDisabled = Color(0xFF666666);
  static const Color textPlaceholder = Color(0xFF444444);

  // Font sizes
  static const double fontSizeXs = 8.0;
  static const double fontSizeSm = 10.0;
  static const double fontSize = 11.0;
  static const double fontSizeMd = 12.0;
  static const double fontSizeLg = 13.0;
  static const double fontSizeXl = 14.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 6.0;
  static const double spacing = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radius = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusFull = 100.0;

  // See-through panel surfaces (background alpha only; text stays opaque)
  static const double seeThroughAlpha = 0.47;
  static const double seeThroughBlurSigma = 14.0;

  /// Returns [color] unchanged, or with [seeThroughAlpha] when [seeThrough].
  static Color surface(Color color, {required bool seeThrough}) {
    if (!seeThrough) return color;
    return color.withValues(alpha: seeThroughAlpha);
  }
}

/// Propagates DevTools panel appearance (e.g. see-through) to tab content.
class DebugPanelAppearance extends InheritedWidget {
  const DebugPanelAppearance({
    super.key,
    required this.seeThrough,
    required super.child,
  });

  final bool seeThrough;

  static bool seeThroughOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<DebugPanelAppearance>()
            ?.seeThrough ??
        false;
  }

  @override
  bool updateShouldNotify(DebugPanelAppearance oldWidget) {
    return seeThrough != oldWidget.seeThrough;
  }
}
