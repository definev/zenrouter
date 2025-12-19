part of 'path.dart';

/// Defines how a route should be displayed as a widget and wrapped in a page.
///
/// [StackTransition] separates the route logic from the presentation.
/// It contains:
/// - [builder]: How to build the widget for this route
/// - [pageBuilder]: How to wrap the widget in a Flutter [Page]
/// - [guard]: Optional guard that applies even if the route doesn't have [RouteGuard]
///
/// ## Built-in Factories
///
/// Use these for common patterns:
/// - [StackTransition.material] - Material page transition (Android)
/// - [StackTransition.cupertino] - Cupertino page transition (iOS)
/// - [StackTransition.sheet] - Bottom sheet presentation
/// - [StackTransition.dialog] - Dialog presentation
/// - [StackTransition.none] - No animation (testing/screenshots)
/// - [StackTransition.custom] - Full control over page and transition
///
/// ## Custom Transitions
///
/// For custom animations, use [StackTransition.custom]:
///
/// ```dart
/// // Fade transition example
/// StackTransition.custom<MyRoute>(
///   builder: (context) => MyWidget(),
///   pageBuilder: (context, routeKey, child) => FadePage(
///     key: routeKey,
///     child: child,
///   ),
/// )
/// ```
///
/// To create a custom page with animation:
///
/// ```dart
/// class FadePage<T> extends Page<T> {
///   const FadePage({super.key, required this.child});
///   final Widget child;
///
///   @override
///   Route<T> createRoute(BuildContext context) {
///     return PageRouteBuilder<T>(
///       settings: this,
///       pageBuilder: (context, animation, _) => FadeTransition(
///         opacity: animation,
///         child: child,
///       ),
///       transitionDuration: Duration(milliseconds: 300),
///     );
///   }
/// }
/// ```
class StackTransition<T extends RouteTarget> {
  /// Creates a custom route destination with full control.
  ///
  /// **Parameters:**
  /// - [builder]: Returns the widget for this route
  /// - [pageBuilder]: Wraps the widget in a [Page] for the Navigator
  /// - [guard]: Optional guard (useful for route-agnostic guards)
  ///
  /// **Example - Slide from bottom:**
  /// ```dart
  /// StackTransition.custom<MyRoute>(
  ///   builder: (context) => MySheet(),
  ///   pageBuilder: (context, routeKey, child) => SlideUpPage(
  ///     key: routeKey,
  ///     child: child,
  ///   ),
  /// )
  /// ```
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

  /// Creates a [NoTransitionPage] with instant appearance.
  ///
  /// Routes appear and disappear instantly without animation.
  ///
  /// **Use cases:**
  /// - Widget tests (avoid waiting for animations)
  /// - Screenshot tools
  /// - When custom animations are handled elsewhere
  /// - Performance-sensitive scenarios
  static StackTransition<T> none<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        NoTransitionPage(key: route, child: child),
    guard: guard,
  );

  /// Builds the widget for this route.
  final WidgetBuilder builder;

  /// Wraps the widget in a Flutter [Page].
  final PageCallback<T> pageBuilder;

  /// Optional guard that applies even if the route doesn't have [RouteGuard].
  final RouteGuard? guard;
}

/// Callback that maps routes to their [StackTransition].
///
/// Used by [NavigationStack] to determine how each route should be displayed.
///
/// **Example - Route-based transitions:**
/// ```dart
/// NavigationStack(
///   path: coordinator.root,
///   coordinator: coordinator,
///   resolver: (route) {
///     return switch (route) {
///       // Dialogs use dialog transition
///       ConfirmRoute() => StackTransition.dialog(route.build(coordinator, context)),
///
///       // Sheets use sheet transition
///       ShareRoute() => StackTransition.sheet(route.build(coordinator, context)),
///
///       // iOS gets cupertino, others get material
///       _ when Platform.isIOS => StackTransition.cupertino(
///         route.build(coordinator, context),
///       ),
///       _ => StackTransition.material(route.build(coordinator, context)),
///     };
///   },
/// )
/// ```
///
/// **Example - RouteTransition mixin:**
/// Routes can also define their own transition by mixing in [RouteTransition]:
/// ```dart
/// class SettingsRoute extends RouteTarget with RouteUnique, RouteTransition {
///   @override
///   StackTransition<T> transition<T extends RouteUnique>(Coordinator coordinator) {
///     return StackTransition.cupertino(build(coordinator, context));
///   }
/// }
/// ```
typedef StackTransitionResolver<T extends RouteTarget> =
    StackTransition<T> Function(T route);

/// A page that presents its route as a Cupertino-style bottom sheet.
///
/// Use this for modal overlays that slide up from the bottom of the screen,
/// commonly used for iOS-style action sheets or forms.
///
/// Example:
/// ```dart
///   StackTransition.sheet(MyWidget())
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
///   StackTransition.dialog(AlertWidget())
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

class NoTransitionPage<T> extends Page<T> {
  const NoTransitionPage({super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _NoTransitionRoute<T>(settings: this, child: child);
  }
}

class _NoTransitionRoute<T> extends PageRoute<T> {
  _NoTransitionRoute({super.settings, required this.child});

  final Widget child;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'No transition';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;
}
