import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A page that presents its route as a Cupertino-style bottom sheet.
///
/// Use this for modal overlays that slide up from the bottom of the screen,
/// commonly used for iOS-style action sheets or forms.
///
/// Example:
/// ```dart
/// RouteDestination.sheet(MyWidget())
/// ```
class CupertinoSheetPage<T extends Object> extends Page<T> {
  const CupertinoSheetPage({super.key, required this.builder});

  /// Builder for the sheet content.
  final WidgetBuilder builder;

  @override
  Route<T> createRoute(BuildContext context) {
    return CupertinoSheetRoute(settings: this, builder: builder);
  }
}

/// A page that presents its route as a dialog overlay.
///
/// Use this for modal dialogs that appear on top of the current screen,
/// typically with a backdrop. Common for alerts, confirmations, or forms.
///
/// Example:
/// ```dart
/// RouteDestination.dialog(AlertWidget())
/// ```
class DialogPage<T> extends Page<T> {
  const DialogPage({super.key, required this.child});

  /// The widget to display in the dialog.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      settings: this,
      builder: (context) => child,
    );
  }
}
