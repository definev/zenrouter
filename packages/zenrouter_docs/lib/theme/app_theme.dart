/// The visual language for the ZenRouter book.
library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Font styles that never trigger a runtime network request.
///
/// Inter ships with Forui, while serif and monospace use platform fonts with
/// deterministic fallbacks. Keeping this here prevents an offline docs visit
/// from waiting on several Google Fonts downloads.
abstract final class AppTypography {
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) => TextStyle(
    fontFamily: 'packages/forui/Inter',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
  );

  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) => TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
  );

  static TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) => TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

/// Forui's platform-agnostic theme, tuned for a warm printed-page interface.
abstract final class AppTheme {
  static const primary = Color(0xFF1976A3);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const paper = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF1EEE8);
  static const ink = Color(0xFF222629);
  static const mutedInk = Color(0xFF687177);
  static const divider = Color(0xFFD8DDE0);
  static const paleBlue = Color(0xFFF1F6F8);
  static const sidebar = Color(0xFFF8FAFB);
  static const codeBackground = Color(0xFFF5F8FA);
  static const bookBlack = Color(0xFF111516);
  static const gold = Color(0xFFF0B743);
  static const success = Color(0xFF2E7D5B);

  static FThemeData get light {
    final base = FTheme.neutral.light.desktop;
    return FThemeData(
      debugLabel: 'ZenRouter paper',
      touch: false,
      colors: base.colors.copyWith(
        background: canvas,
        foreground: ink,
        primary: primary,
        primaryForeground: primaryForeground,
        secondary: paleBlue,
        secondaryForeground: ink,
        muted: codeBackground,
        mutedForeground: mutedInk,
        card: paper,
        border: divider,
      ),
      typography: base.typography,
      icons: base.icons,
      style: base.style.copyWith(
        borderRadius: const FBorderRadius(
          xs2: BorderRadius.zero,
          xs: BorderRadius.zero,
          sm: BorderRadius.zero,
          md: BorderRadius.zero,
          lg: BorderRadius.zero,
          xl: BorderRadius.zero,
          xl2: BorderRadius.zero,
          xl3: BorderRadius.zero,
          pill: BorderRadius.all(Radius.circular(999)),
        ),
      ),
    );
  }
}

/// Reading-specific tokens kept beside the Forui theme.
@immutable
class DocsThemeData {
  const DocsThemeData({
    this.proseMaxWidth = 640,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 72,
    ),
  });

  final double proseMaxWidth;
  final EdgeInsets contentPadding;
}

/// Makes the book's reading tokens available without a Material [ThemeData].
class DocsTheme extends InheritedWidget {
  const DocsTheme({
    super.key,
    this.data = const DocsThemeData(),
    required super.child,
  });

  final DocsThemeData data;

  static DocsThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DocsTheme>();
    assert(scope != null, 'No DocsTheme found in context.');
    return scope!.data;
  }

  @override
  bool updateShouldNotify(DocsTheme oldWidget) => data != oldWidget.data;
}

extension DocsThemeContext on BuildContext {
  DocsThemeData get docsTheme => DocsTheme.of(this);
}
