/// # The Visual Language of Our Documentation
///
/// A theme, like prose style, communicates before a single word is read.
/// We have chosen a literary aesthetic: serif fonts for our explanatory
/// prose (evoking the printed page), monospace for our code examples
/// (evoking the terminal), and colors that speak of depth and clarity.
///
/// The reader should feel they are learning from a well-crafted book,
/// not merely browsing a technical reference.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The visual identity of ZenRouter Documentation.
abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // Colors: ZenRouter brand colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary: Brand cyan/light blue - the essence of ZenRouter
  static const Color _primaryLight = brandNavy; // Navy blue for light mode
  static const Color _primaryDark = brandCyan; // Cyan for dark mode

  /// Brand colors
  static const Color brandCyan = Color(0xFF5BBFD9);
  static const Color brandNavy = Color(0xFF315D8C);

  /// Surface colors for light mode
  static const Color _surfaceLight = Color(0xFFFAF9F6);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _codeBackgroundLight = Color(0xFFF5F2EB);

  /// Surface colors for dark mode
  static const Color _surfaceDark = Color(0xFF1A1A2E);
  static const Color _cardDark = Color(0xFF16213E);
  static const Color _codeBackgroundDark = Color(0xFF0F0F1A);

  // ─────────────────────────────────────────────────────────────────────────
  // Typography: The voice of our documentation
  // ─────────────────────────────────────────────────────────────────────────

  /// Prose font: Libre Baskerville - a refined serif for extended reading
  static TextTheme _proseTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    final baseTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: baseColor,
        height: 1.2,
        decoration: TextDecoration.none,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: baseColor,
        height: 1.3,
        decoration: TextDecoration.none,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: baseColor,
        height: 1.3,
        decoration: TextDecoration.none,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
        decoration: TextDecoration.none,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
        decoration: TextDecoration.none,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
        decoration: TextDecoration.none,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: baseColor.withValues(alpha: 0.87),
        height: 1.7,
        decoration: TextDecoration.none,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: baseColor.withValues(alpha: 0.87),
        height: 1.7,
        decoration: TextDecoration.none,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: baseColor.withValues(alpha: 0.7),
        height: 1.6,
        decoration: TextDecoration.none,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.5,
        decoration: TextDecoration.none,
      ),
    );

    return GoogleFonts.libreBaskervilleTextTheme(baseTheme);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Theme Data: Light and Dark
  // ─────────────────────────────────────────────────────────────────────────

  /// Light theme: For reading in daylight, as one reads a proper book
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.white,
      secondary: brandCyan,
      surface: _surfaceLight,
      onSurface: Colors.black87,
    ),
    drawerTheme: DrawerThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      endShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ),
    scaffoldBackgroundColor: _surfaceLight,
    cardColor: _cardLight,
    textTheme: _proseTextTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceLight,
      foregroundColor: Colors.black87,
      elevation: 0,
      titleTextStyle: GoogleFonts.libreBaskerville(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _cardLight,
      selectedIconTheme: const IconThemeData(color: _primaryLight),
      unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
      selectedLabelTextStyle: GoogleFonts.libreBaskerville(
        color: _primaryLight,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.libreBaskerville(
        color: Colors.grey.shade600,
      ),
    ),
    dividerColor: Colors.grey.shade300,
    extensions: [
      const DocsThemeExtension(
        codeBackground: _codeBackgroundLight,
        proseMaxWidth: 720,
        contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      ),
    ],
  );

  /// Dark theme: For late-night study, when the mind is most receptive
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: Colors.black,
      secondary: brandNavy,
      surface: _surfaceDark,
      onSurface: Colors.white,
    ),
    drawerTheme: DrawerThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      endShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ),
    scaffoldBackgroundColor: _surfaceDark,
    cardColor: _cardDark,
    textTheme: _proseTextTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.libreBaskerville(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: _cardDark,
      selectedIconTheme: const IconThemeData(color: _primaryDark),
      unselectedIconTheme: IconThemeData(color: Colors.grey.shade400),
      selectedLabelTextStyle: GoogleFonts.libreBaskerville(
        color: _primaryDark,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: GoogleFonts.libreBaskerville(
        color: Colors.grey.shade400,
      ),
    ),
    dividerColor: Colors.grey.shade800,
    extensions: [
      const DocsThemeExtension(
        codeBackground: _codeBackgroundDark,
        proseMaxWidth: 720,
        contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      ),
    ],
  );
}

/// Custom theme extension for documentation-specific styling.
class DocsThemeExtension extends ThemeExtension<DocsThemeExtension> {
  const DocsThemeExtension({
    required this.codeBackground,
    required this.proseMaxWidth,
    required this.contentPadding,
  });

  /// Background color for code blocks
  final Color codeBackground;

  /// Maximum width for prose content (for comfortable reading)
  final double proseMaxWidth;

  /// Standard padding for content sections
  final EdgeInsets contentPadding;

  @override
  ThemeExtension<DocsThemeExtension> copyWith({
    Color? codeBackground,
    double? proseMaxWidth,
    EdgeInsets? contentPadding,
  }) {
    return DocsThemeExtension(
      codeBackground: codeBackground ?? this.codeBackground,
      proseMaxWidth: proseMaxWidth ?? this.proseMaxWidth,
      contentPadding: contentPadding ?? this.contentPadding,
    );
  }

  @override
  ThemeExtension<DocsThemeExtension> lerp(
    covariant ThemeExtension<DocsThemeExtension>? other,
    double t,
  ) {
    if (other is! DocsThemeExtension) return this;
    return DocsThemeExtension(
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      proseMaxWidth: proseMaxWidth + (other.proseMaxWidth - proseMaxWidth) * t,
      contentPadding: EdgeInsets.lerp(contentPadding, other.contentPadding, t)!,
    );
  }
}

/// Extension for convenient access to DocsThemeExtension
extension DocsThemeExtensionGetter on ThemeData {
  DocsThemeExtension get docs => extension<DocsThemeExtension>()!;
}
