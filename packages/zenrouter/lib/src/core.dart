import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/src/transition.dart';
import 'package:zenrouter/zenrouter.dart';

/// A mixin that adds guard logic to prevent unwanted navigation away from a route.
///
/// Use [RouteGuard] when you need to:
/// - Confirm before leaving a page with unsaved changes
/// - Validate data before allowing navigation
/// - Show a confirmation dialog before closing
///
/// The [popGuard] method is called before the route is popped. Return `false`
/// to prevent the pop, or `true` to allow it.
///
/// Example:
/// ```dart
/// class FormRoute extends RouteTarget with RouteGuard {
///   bool hasUnsavedChanges = false;
///
///   @override
///   FutureOr<bool> popGuard() async {
///     if (!hasUnsavedChanges) return true;
///     return await showConfirmDialog();
///   }
/// }
/// ```
mixin RouteGuard on RouteTarget {
  /// Called before popping this route from the navigation stack.
  ///
  /// Return `true` to allow the pop, or `false` to prevent it.
  /// Can be synchronous or asynchronous.
  FutureOr<bool> popGuard();
}

/// A mixin that adds redirect logic to route navigation.
///
/// Use [RouteRedirect] when you need to:
/// - Redirect unauthenticated users to login
/// - Perform conditional navigation based on app state
/// - Chain multiple redirects together
///
/// The [redirect] method is called when the route is pushed. It can return
/// a different route to navigate to instead, or `this` to navigate to this route.
/// Redirects can be chained - if the returned route also has [RouteRedirect],
/// it will be followed until a non-redirecting route is reached.
///
/// Example:
/// ```dart
/// class ProtectedRoute extends RouteTarget with RouteRedirect<AppRoute> {
///   @override
///   Future<AppRoute> redirect() async {
///     final isAuth = await checkAuth();
///     return isAuth ? this : LoginRoute();
///   }
/// }
/// ```
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  /// Returns the route to navigate to.
  ///
  /// Return `this` to navigate to this route, or return a different route
  /// to redirect. Can be synchronous or asynchronous.
  FutureOr<T> redirect();
}

/// Strategy for handling deep links.
///
/// - [replace]: Replace the current navigation stack (default)
/// - [push]: Push onto the existing navigation stack
enum DeeplinkStrategy { replace, push }

/// The base class for all routes in the navigation system.
///
/// [RouteTarget] represents a destination in your app's navigation graph.
/// Routes can carry data (as instance fields) and can be composed with mixins
/// to add functionality like guards, redirects, and builders.
///
/// Key features:
/// - Routes are compared by type and navigation path (by default)
/// - Routes can return results when popped (via the Future returned by push)
/// - Routes can be converted to URIs for deep linking
///
/// **IMPORTANT: Routes with parameters must override equality**
///
/// The default equality only checks [runtimeType] and [_path]. If your route
/// has data fields, you MUST override [operator ==] and [hashCode] to include
/// those fields, otherwise operations like [NavigationPath.pushOrMoveToTop],
/// [NavigationPath.remove], and redirects won't work correctly.
///
/// Example:
/// ```dart
/// class ProductRoute extends RouteTarget {
///   final String productId;
///   ProductRoute(this.productId);
///
///   @override
///   bool operator ==(Object other) {
///     if (identical(this, other)) return true;
///     return other is ProductRoute &&
///            other.productId == productId &&
///            other._path == _path;
///   }
///
///   @override
///   int get hashCode => Object.hash(runtimeType, productId, _path);
///
///   @override
///   Uri? toUri() => Uri.parse('/product/$productId');
/// }
/// ```
abstract mixin class RouteTarget extends Object {
  /// Strategy to use when this route is opened from a deep link.
  ///
  /// - [DeeplinkStrategy.replace]: Replaces the current navigation stack (default)
  /// - [DeeplinkStrategy.push]: Pushes onto the existing navigation stack
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.replace;

  /// Completer that is completed when the route is popped.
  final Completer<dynamic> _onResult = Completer();

  /// The navigation path this route belongs to, if any.
  NavigationPath? _path;

  /// The result value to return when the route is popped.
  Object? _resultValue;

  void _completeOnResult(dynamic result) {
    _onResult.complete(result);
    if (_path?.stack.contains(this) == true) {
      _path!.remove(this);
    }
    _resultValue = result;
  }

  /// Checks if this route is equal to another route.
  ///
  /// Two routes are equal if they have the same runtime type and navigation path.
  bool equals(Object other) {
    if (identical(this, other)) return true;
    return (other is RouteTarget) &&
        other.runtimeType == runtimeType &&
        other._path == _path;
  }

  @override
  operator ==(Object other) => equals(other);

  @override
  int get hashCode =>
      runtimeType.hashCode ^ _path.hashCode ^ _onResult.hashCode;

  @override
  String toString() => '$runtimeType';

  /// Converts this route to a [Uri] for deep linking and web navigation.
  ///
  /// Override this method to support deep linking to this route.
  /// Return `null` if this route should not be accessible via deep links.
  ///
  /// If this route has [RouteRedirect], the redirect will be followed first.
  /// [RouteShellHost] routes should return `null`.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Uri? toUri() => Uri.parse('/product/$productId');
  /// ```
  Uri? toUri() {
    if (this case RouteRedirect route) {
      final result = route.redirect();
      if (result is RouteTarget) {
        return result.toUri();
      } else {
        // Fail silent
      }
    }

    if (this is RouteShellHost) return null;

    assert(
      false,
      '[$runtimeType]: If you want to use deeplink for $runtimeType please implement `toUri()` method and put it in [Coordinator]',
    );
    return null;
  }
}

/// A stack-based container for managing navigation history.
///
/// [NavigationPath] maintains an ordered list of routes and notifies listeners
/// when the stack changes. It's like a browser's back/forward history.
///
/// Key operations:
/// - [push]: Add a route to the top of the stack
/// - [pop]: Remove the top route from the stack
/// - [clear]: Remove all routes from the stack
/// - [replace]: Replace the entire stack with a new one
///
/// The path automatically handles:
/// - Route redirects (via [RouteRedirect])
/// - Route guards (via [RouteGuard])
/// - Result completion (via the Future returned by push)
///
/// Example:
/// ```dart
/// final path = NavigationPath<AppRoute>();
/// final result = await path.push(FormRoute());
/// print('Form returned: $result');
/// ```
class NavigationPath<T extends RouteTarget> extends ChangeNotifier {
  NavigationPath() : _stack = [];

  /// The internal mutable stack.
  final List<T> _stack;

  /// The current navigation stack as an unmodifiable list.
  ///
  /// The first element is the bottom of the stack (first route),
  /// and the last element is the top of the stack (current route).
  List<T> get stack => List.unmodifiable(_stack);

  /// Pushes a route onto the navigation stack.
  ///
  /// If the route has [RouteRedirect], the redirect chain is followed until
  /// a non-redirecting route is reached. That route is then pushed.
  ///
  /// Returns a [Future] that completes when the route is popped, with the
  /// pop result value (if any).
  ///
  /// Example:
  /// ```dart
  /// final result = await path.push(EditRoute());
  /// print('User saved: $result');
  /// ```
  Future<dynamic> push(T element) async {
    T target = element;
    while (target is RouteRedirect<T>) {
      final newTarget = await (target as RouteRedirect<T>).redirect();
      if (newTarget == target) break;
      target = newTarget;
    }
    target._path = this;
    _stack.add(target);
    notifyListeners();
    return target._onResult.future;
  }

  /// Pushes a route to the top of the stack, or moves it if already present.
  ///
  /// If the route is already in the stack, it's moved to the top.
  /// If not, it's added to the top. Follows redirects like [push].
  ///
  /// Useful for tab navigation where you want to switch to a tab
  /// without duplicating it in the stack.
  Future<void> pushOrMoveToTop(T element) async {
    T target = element;
    while (target is RouteRedirect<T>) {
      final newTarget = await (target as RouteRedirect<T>).redirect();
      if (newTarget == target) break;
      target = newTarget;
    }
    target._path = this;
    final index = _stack.indexOf(target);
    if (index != -1) {
      _stack.removeAt(index);
    }
    _stack.add(target);
    notifyListeners();
  }

  /// Removes the top route from the navigation stack.
  ///
  /// If the route has [RouteGuard], the guard is consulted first.
  /// The pop is cancelled if the guard returns `false`.
  ///
  /// The optional [result] is passed back to the Future returned by [push].
  ///
  /// Example:
  /// ```dart
  /// path.pop({'saved': true});
  /// ```
  Future<void> pop([Object? result]) async {
    if (_stack.isEmpty) return;
    final last = _stack.last;
    if (last is RouteGuard) {
      final canPop = await last.popGuard();
      if (!canPop) return;
    }

    final element = _stack.removeLast();
    element._path = null;
    element._resultValue = result;
    notifyListeners();
  }

  /// Removes all routes from the navigation stack.
  ///
  /// This clears the entire navigation history. Guards are NOT consulted.
  void clear() {
    for (final element in _stack) {
      element._path = null;
    }
    _stack.clear();
    notifyListeners();
  }

  /// Replaces the entire navigation stack with a new set of routes.
  ///
  /// Pops all existing routes (respecting guards), then pushes all new routes.
  /// Useful for resetting the navigation state.
  ///
  /// Example:
  /// ```dart
  /// path.replace([HomeRoute(), ProfileRoute()]);
  /// ```
  void replace(List<T> stack) {
    while (_stack.isNotEmpty) {
      pop();
    }
    stack.forEach(push);
    notifyListeners();
  }

  /// Removes a specific route from the stack (at any position).
  ///
  /// Guards are NOT consulted. Use with caution.
  void remove(T element) {
    element._path = null;
    _stack.remove(element);
    notifyListeners();
  }
}

/// Callback that builds a [Page] from a route and child widget.
typedef PageCallback<T extends RouteTarget> =
    Page<void> Function(BuildContext context, ValueKey<T> route, Widget child);

/// Callback for handling imperative pop requests.
typedef ImperativePopCalledCallback = FutureOr<bool> Function();

/// Defines how a route should be displayed as a widget and wrapped in a page.
///
/// [RouteDestination] separates the route logic from the presentation.
/// It contains:
/// - [builder]: How to build the widget for this route
/// - [pageBuilder]: How to wrap the widget in a Flutter [Page]
/// - [guard]: Optional guard that applies even if the route doesn't have [RouteGuard]
///
/// Use the factory methods for common patterns:
/// - [RouteDestination.material] - Material page transition
/// - [RouteDestination.cupertino] - Cupertino page transition
/// - [RouteDestination.sheet] - Bottom sheet presentation
/// - [RouteDestination.dialog] - Dialog presentation
/// - [RouteDestination.custom] - Custom page and transition
class RouteDestination<T extends RouteTarget> {
  /// Creates a custom route destination.
  const RouteDestination.custom({
    required this.builder,
    required this.pageBuilder,
    this.guard,
  });

  /// Creates a [MaterialPage] with a [Widget].
  ///
  /// This uses Material Design page transitions.
  static RouteDestination<T> material<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => RouteDestination<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        MaterialPage(key: route, child: child),
    guard: guard,
  );

  /// Creates a [CupertinoPage] with a [Widget].
  ///
  /// This uses iOS-style page transitions.
  static RouteDestination<T> cupertino<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => RouteDestination<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        CupertinoPage(key: route, child: child),
    guard: guard,
  );

  /// Creates a [CupertinoSheetPage] with a [Widget].
  ///
  /// This presents the route as a bottom sheet.
  static RouteDestination<T> sheet<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => RouteDestination<T>.custom(
    builder: (context) => child,
    pageBuilder: (context, route, child) =>
        CupertinoSheetPage(key: route, builder: (context) => child),
    guard: guard,
  );

  /// Creates a [DialogPage] with a [Widget].
  ///
  /// This presents the route as a dialog overlay.
  static RouteDestination<T> dialog<T extends RouteTarget>(
    Widget child, {
    RouteGuard? guard,
  }) => RouteDestination<T>.custom(
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

/// Callback that resolves a route to its visual representation.
typedef RouteDestinationResolver<T extends RouteTarget> =
    RouteDestination<T> Function(T route);

/// A widget that renders a [NavigationPath] as a Flutter [Navigator].
///
/// [NavigationStack] keeps the UI in sync with a [NavigationPath].
/// When routes are added/removed from the path, the navigator updates automatically.
///
/// Features:
/// - Automatically creates pages from routes using the [resolver]
/// - Handles [RouteGuard] integration with [PopScope]
/// - Sets a default route on initialization if provided
/// - Provides access to the navigator via [navigatorKey]
///
/// Example:
/// ```dart
/// NavigationStack(
///   path: coordinator.root,
///   resolver: (route) => RouteDestination.material(MyWidget()),
///   defaultRoute: HomeRoute(),
/// )
/// ```
class NavigationStack<T extends RouteTarget> extends StatefulWidget {
  const NavigationStack({
    super.key,
    required this.path,
    required this.resolver,
    this.defaultRoute,
    this.navigatorKey,
  });

  /// Optional key for accessing the navigator state.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The navigation path to render.
  final NavigationPath<T> path;

  /// Callback that converts routes to destinations.
  final RouteDestinationResolver<T> resolver;

  /// Optional route to push when the stack initializes.
  final T? defaultRoute;

  @override
  State<NavigationStack<T>> createState() => _NavigationStackState<T>();
}

class _NavigationStackState<T extends RouteTarget>
    extends State<NavigationStack<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.defaultRoute != null) {
      widget.path.pushOrMoveToTop(widget.defaultRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.path,
      builder: (context, _) {
        final pages = widget.path.stack.map((route) {
          final destination = widget.resolver(route);
          return destination.pageBuilder(
            context,
            ValueKey(route),
            PopScope(
              canPop: switch (route) {
                RouteGuard() => false,
                _ when destination.guard != null => false,
                _ => true,
              },
              onPopInvokedWithResult: (didPop, result) async {
                switch (didPop) {
                  case true when result != null:
                    route._completeOnResult(result);
                  case true:
                    route._completeOnResult(route._resultValue);
                  case false when route is RouteGuard:
                    widget.path.pop();
                  case false when destination.guard != null:
                    final processed = await destination.guard?.popGuard();
                    if (processed == true) widget.path.pop();
                  case false:
                }
              },
              child: destination.builder(context),
            ),
          );
        }).toList();

        if (pages.isEmpty) return const SizedBox.shrink();
        return Navigator(
          key: widget.navigatorKey,
          pages: pages,
          onDidRemovePage: (page) {},
        );
      },
    );
  }
}
