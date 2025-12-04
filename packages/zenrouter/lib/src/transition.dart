part of 'path.dart';

/// Defines how a route should be displayed as a widget and wrapped in a page.
///
/// [StackTransition] separates the route logic from the presentation.
/// It contains:
/// - [builder]: How to build the widget for this route
/// - [pageBuilder]: How to wrap the widget in a Flutter [Page]
/// - [guard]: Optional guard that applies even if the route doesn't have [RouteGuard]
///
/// Use the factory methods for common patterns:
/// - [StackTransition.material] - Material page transition
/// - [StackTransition.cupertino] - Cupertino page transition
/// - [StackTransition.sheet] - Bottom sheet presentation
/// - [StackTransition.dialog] - Dialog presentation
/// - [RouteDestination.custom] - Custom page and transition
class StackTransition<T extends RouteTarget> {
  /// Creates a custom route destination.
  const StackTransition.custom({
    required this.builder,
    required this.pageBuilder,
    this.guard,
  });

  /// Creates a [MaterialPage] with a [Widget].
  ///
  /// This uses Material Design page transitions.
  static StackTransition<T> material<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        MaterialPage(key: route, child: child),
    guard: guard,
  );

  /// Creates a [CupertinoPage] with a [Widget].
  ///
  /// This uses iOS-style page transitions.
  static StackTransition<T> cupertino<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        CupertinoPage(key: route, child: child),
    guard: guard,
  );

  /// Creates a [CupertinoSheetPage] with a [Widget].
  ///
  /// This presents the route as a bottom sheet.
  static StackTransition<T> sheet<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        CupertinoSheetPage(key: route, builder: (context) => child),
    guard: guard,
  );

  /// Creates a [DialogPage] with a [Widget].
  ///
  /// This presents the route as a dialog overlay.
  static StackTransition<T> dialog<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        DialogPage(key: route, child: child),
    guard: guard,
  );

  /// Builds the widget for this route.
  final WidgetBuilder builder;

  /// Wraps the widget in a Flutter [Page].
  final PageCallback<T> pageBuilder;

  /// Optional guard that applies even if the route doesn't have [RouteGuard].
  final RouteGuard? guard;
}

/// Callback that resolves a stack transition in [NavigationStack]
typedef StackTransitionResolver<T extends RouteTarget> =
    StackTransition<T> Function(T route);

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
  /// Creates the route for this page.
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
  /// Creates the route for this page.
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      settings: this,
      builder: (context) => child,
    );
  }
}
