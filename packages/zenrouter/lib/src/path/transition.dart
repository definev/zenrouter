import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

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
    String? restorationId,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        MaterialPage(key: route, child: child, restorationId: restorationId),
    guard: guard,
  );

  /// Creates a [CupertinoPage] with a [Widget].
  ///
  /// This uses iOS-style page transitions.
  static StackTransition<T> cupertino<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
    String? restorationId,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        CupertinoPage(key: route, child: child, restorationId: restorationId),
    guard: guard,
  );

  /// Creates a [CupertinoSheetPage] with a [Widget].
  ///
  /// This presents the route as a bottom sheet.
  static StackTransition<T> sheet<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
    String? restorationId,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) => CupertinoSheetPage(
      key: route,
      restorationId: restorationId,
      builder: (context) => child,
    ),
    guard: guard,
  );

  /// Creates a [DialogPage] with a [Widget].
  ///
  /// This presents the route as a dialog overlay.
  static StackTransition<T> dialog<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
    String? restorationId,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        DialogPage(key: route, restorationId: restorationId, child: child),
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
    String? restorationId,
  }) => StackTransition<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) => NoTransitionPage(
      key: route,
      child: child,
      restorationId: restorationId,
    ),
    guard: guard,
  );

  /// Builds the widget for this route.
  final WidgetBuilder builder;

  /// Wraps the widget in a Flutter [Page].
  final PageCallback<T> pageBuilder;

  /// Optional guard that applies even if the route doesn't have [RouteGuard].
  final RouteGuard? guard;
}

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
  const CupertinoSheetPage({
    super.key,
    required this.builder,
    super.restorationId,
  });

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
  const DialogPage({super.key, required this.child, super.restorationId});

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
  const NoTransitionPage({super.key, required this.child, super.restorationId});

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

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}

/// Page with custom transition functionality.
///
/// To be used instead of MaterialPage or CupertinoPage, which provide
/// their own transitions.
class CustomTransitionPage<T> extends Page<T> {
  /// Constructor for a page with custom transition functionality.
  ///
  /// To be used instead of MaterialPage or CupertinoPage, which provide
  /// their own transitions.
  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The content to be shown in the Route created by this page.
  final Widget child;

  /// A duration argument to customize the duration of the custom page
  /// transition.
  ///
  /// Defaults to 300ms.
  final Duration transitionDuration;

  /// A duration argument to customize the duration of the custom page
  /// transition on pop.
  ///
  /// Defaults to 300ms.
  final Duration reverseTransitionDuration;

  /// Whether the route should remain in memory when it is inactive.
  ///
  /// If this is true, then the route is maintained, so that any futures it is
  /// holding from the next route will properly resolve when the next route
  /// pops. If this is not necessary, this can be set to false to allow the
  /// framework to entirely discard the route's widget hierarchy when it is
  /// not visible.
  final bool maintainState;

  /// Whether this page route is a full-screen dialog.
  ///
  /// In Material and Cupertino, being fullscreen has the effects of making the
  /// app bars have a close button instead of a back button. On iOS, dialogs
  /// transitions animate differently and are also not closeable with the
  /// back swipe gesture.
  final bool fullscreenDialog;

  /// Whether the route obscures previous routes when the transition is
  /// complete.
  ///
  /// When an opaque route's entrance transition is complete, the routes
  /// behind the opaque route will not be built to save resources.
  final bool opaque;

  /// Whether you can dismiss this route by tapping the modal barrier.
  final bool barrierDismissible;

  /// The color to use for the modal barrier.
  ///
  /// If this is null, the barrier will be transparent.
  final Color? barrierColor;

  /// The semantic label used for a dismissible barrier.
  ///
  /// If the barrier is dismissible, this label will be read out if
  /// accessibility tools (like VoiceOver on iOS) focus on the barrier.
  final String? barrierLabel;

  /// Override this method to wrap the child with one or more transition
  /// widgets that define how the route arrives on and leaves the screen.
  ///
  /// By default, the child (which contains the widget returned by buildPage) is
  /// not wrapped in any transition widgets.
  ///
  /// The transitionsBuilder method, is called each time the Route's state
  /// changes while it is visible (e.g. if the value of canPop changes on the
  /// active route).
  ///
  /// The transitionsBuilder method is typically used to define transitions
  /// that animate the new topmost route's comings and goings. When the
  /// Navigator pushes a route on the top of its stack, the new route's
  /// primary animation runs from 0.0 to 1.0. When the Navigator pops the
  /// topmost route, e.g. because the use pressed the back button, the primary
  /// animation runs from 1.0 to 0.0.
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )
  transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) =>
      _CustomTransitionPageRoute<T>(this);
}

class _CustomTransitionPageRoute<T> extends PageRoute<T> {
  _CustomTransitionPageRoute(CustomTransitionPage<T> page)
    : super(settings: page);

  CustomTransitionPage<T> get _page => settings as CustomTransitionPage<T>;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.reverseTransitionDuration;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get opaque => _page.opaque;

  /// Builds the page content.
  ///
  /// Should not contain any animations or transitions.
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: _page.child,
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _page.transitionsBuilder(context, animation, secondaryAnimation, child);
}
