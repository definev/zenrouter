import 'dart:async';

import 'package:flutter/material.dart';
import 'core.dart';

class FixedNavigationPath<T extends RouteUnique> extends NavigationPath<T> {
  FixedNavigationPath(List<T> stack, {String? debugLabel})
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super(debugLabel, stack);

  int _activePathIndex = 0;
  int get activePathIndex => _activePathIndex;

  T get activeRoute => stack[activePathIndex];

  Future<void> pushIndexed(int index) async {
    if (index >= stack.length) throw StateError('Index out of bounds');
    final oldIndex = _activePathIndex;
    final oldRoute = stack[oldIndex];
    if (oldRoute is RouteGuard) {
      final canPop = await (oldRoute as RouteGuard).popGuard();
      if (!canPop) return;
    }
    var newRoute = stack[index];
    while (newRoute is RouteRedirect<T>) {
      final redirectTo = await (newRoute as RouteRedirect<T>).redirect();
      if (redirectTo == null) return;
      newRoute = redirectTo;
    }

    push(newRoute);
    notifyListeners();
  }

  @override
  Future<dynamic> push(T element) async {
    final index = stack.indexOf(element);
    if (index == -1) {
      throw StateError('You can not push a new route into read-only path');
    }
    _activePathIndex = index;
    notifyListeners();
    return null;
  }

  @override
  Future<void> pushOrMoveToTop(T element) async {
    return push(element);
  }

  @override
  void clear() {
    // Ignore clear
  }

  @override
  Future<void> pop([Object? result]) =>
      throw StateError('You can not pop from read-only path');

  @override
  void replace(List<T> stack) {
    if (stack.length != 1) {
      throw StateError('You can not replace in read-only path');
    }
    push(stack[0]);
  }

  @override
  void remove(T element) =>
      throw StateError('You can not remove from read-only path');
}

mixin RouteUnique on RouteTarget {
  /// URI representation of the [RouteUnique]
  Uri toUri();

  /// The host of this route. If null this route belongs to the root path.
  RouteHost? get host => null;

  /// The build method
  Widget build(covariant Coordinator coordinator, BuildContext context);
}

enum HostType {
  /// A navigation stack that mark host is a navigator
  navigationStack,

  /// A manual shell that mark host is a custom widget
  manualStack;

  static Widget buildNavigationStack<T extends RouteUnique>(
    Coordinator coordinator,
    NavigationPath<T> path, [
    GlobalKey<NavigatorState>? navigationKey,
  ]) => NavigationStack(
    navigatorKey: navigationKey,
    path: path,
    resolver: (route) => switch (route) {
      RouteDestinationMixin() => (route as RouteDestinationMixin).destination(
        coordinator,
      ),
      _ => RouteDestination.material(
        Builder(builder: (context) => route.build(coordinator, context)),
      ),
    },
  );

  static Widget buildIndexedStack<T extends RouteUnique>(
    Coordinator coordinator,
    FixedNavigationPath<T> path,
  ) => ListenableBuilder(
    listenable: path,
    builder: (context, _) => IndexedStack(
      index: path.activePathIndex,
      children: path.stack
          .map(
            (route) => Builder(
              builder: (context) => route.build(coordinator, context),
            ),
          )
          .toList(),
    ),
  );
}

mixin RouteHost<T extends RouteUnique> on RouteUnique {
  /// Type of shell host.
  HostType get hostType;

  /// The navigation path associated with this host.
  ///
  /// This method is called by the coordinator to get the navigation path
  /// for this host. The path is used to manage the navigation stack.
  ///
  /// @param coordinator The coordinator that is managing this host.
  /// @return The navigation path for this host.
  NavigationPath get path;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) =>
      switch (hostType) {
        HostType.navigationStack => HostType.buildNavigationStack(
          coordinator,
          path as NavigationPath<T>,
          host == null && hostType == HostType.navigationStack
              ? coordinator.routerDelegate.navigatorKey
              : null,
        ),
        HostType.manualStack => HostType.buildIndexedStack(
          coordinator,
          path as FixedNavigationPath,
        ),
      };

  @override
  void onDidPop(result) => path.clear();
}

/// Provides custom deep link handling logic.
///
/// Use [RouteDeepLink] when you need more than basic URI-to-route mapping:
/// - Multi-step navigation setup (e.g., ensure parent route exists first)
/// - Analytics tracking for deep links
/// - Complex state restoration from URIs
///
/// The [deeplinkHandler] is called instead of the default push/replace behavior
/// when this route is opened from a deep link.
///
/// Example:
/// ```dart
/// class ProductDetail extends AppRoute with RouteDeepLink {
///   @override
///   FutureOr<void> deeplinkHandler(coordinator, uri) {
///     // Ensure category route is in stack first
///     coordinator.replace(CategoryRoute());
///     coordinator.push(this);
///     analytics.logDeepLink(uri);
///   }
/// }
/// ```
mixin RouteDeepLink on RouteUnique {
  /// Custom handler for when this route is opened via deep link.
  ///
  /// Typically, you'll manually manage the navigation stack in this method.
  FutureOr<void> deeplinkHandler(covariant Coordinator coordinator, Uri uri);
}

mixin RouteDestinationMixin on RouteUnique {
  /// Returns the route destination with page type.
  ///
  /// By default, creates a Material page with [builder] as the child.
  /// Override to customize the page type or transition.
  RouteDestination<T> destination<T extends RouteUnique>(
    covariant Coordinator coordinator,
  ) => RouteDestination.material(
    Builder(builder: (context) => build(coordinator, context)),
  );
}

abstract class Coordinator<T extends RouteUnique> with ChangeNotifier {
  Coordinator() {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final path in paths) {
      path.removeListener(notifyListeners);
    }
  }

  /// The root (primary) navigation path.
  ///
  /// All coordinators have at least this one path.
  final NavigationPath<T> root = NavigationPath('root');

  /// All navigation paths managed by this coordinator.
  ///
  /// Must include at least [root]. Add additional paths for shells.
  List<NavigationPath> get paths => [root];

  /// Returns the current URI based on the active route.
  Uri get currentUri {
    final activePath = nearestPath;

    if (activePath case FixedNavigationPath activePath) {
      return activePath.activeRoute.toUri();
    }
    if (activePath.stack.lastOrNull case RouteUnique route) {
      return route.toUri();
    }

    return Uri.parse('/');
  }

  List<NavigationPath> get pathSegments {
    List<NavigationPath> pathSegment = [root];
    NavigationPath path = root;
    T? current = root.stack.lastOrNull;
    if (current == null) return pathSegment;

    while (true) {
      if (current is RouteHost) {
        final host = current as RouteHost;
        path = host.path;
        pathSegment.add(path);
        switch (host.hostType) {
          case HostType.navigationStack:
            current = path.stack.lastOrNull as T?;
          case HostType.manualStack:
            current = (path as FixedNavigationPath).activeRoute as T;
        }
        continue;
      }

      break;
    }

    return pathSegment;
  }

  NavigationPath get nearestDynamicPath {
    final segments = pathSegments;
    for (var index = segments.length - 1; index >= 0; --index) {
      final path = segments[index];
      if (path is! FixedNavigationPath) return path;
    }

    return root;
  }

  NavigationPath get nearestPath => pathSegments.lastOrNull ?? root;

  /// Parses a [Uri] into a route object.
  ///
  /// **Required override.** This is how deep links and web URLs become routes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// AppRoute parseRouteFromUri(Uri uri) {
  ///   return switch (uri.pathSegments) {
  ///     ['product', final id] => ProductRoute(id),
  ///     _ => HomeRoute(),
  ///   };
  /// }
  /// ```
  T parseRouteFromUri(Uri uri);

  /// Handles navigation from a deep link URI.
  ///
  /// If the route has [RouteDeepLink], its custom handler is called.
  /// Otherwise, uses the route's [deeplinkStrategy] (push or replace).
  FutureOr<void> recoverRouteFromUri(Uri uri) {
    final route = parseRouteFromUri(uri);
    if (route is RouteDeepLink) {
      route.deeplinkHandler(this, uri);
      return null;
    }

    switch (route.deeplinkStrategy) {
      case DeeplinkStrategy.push:
        push(route);
      case DeeplinkStrategy.replace:
        replace(route);
    }
  }

  /// Replaces the current route with a new one.
  ///
  /// Clears the target path and pushes the new route.
  /// For shell routes, ensures the shell host is also in place.
  void replace(T route) async {
    for (final path in paths) {
      path.clear();
    }

    // Handle RouteRedirect logic first
    T target = route;
    while (target is RouteRedirect) {
      final newTarget = await (target as RouteRedirect).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return;
      if (newTarget == target) break;
      if (newTarget is T) target = newTarget;
    }

    RouteHost? host = target.host;
    List<RouteHost> hostSegments = [];
    List<NavigationPath> hostPaths = [];
    while (host != null) {
      hostSegments.add(host);
      hostPaths.add(host.path);
      host = (host as RouteUnique).host;
    }
    hostPaths.add(root);

    for (var i = hostPaths.length - 1; i >= 1; i--) {
      final hostOfHostPath = hostPaths[i];
      final host = hostSegments[i - 1];
      CoordinatorUtils(hostOfHostPath).setRoute(host);
    }

    CoordinatorUtils(hostSegments.firstOrNull?.path ?? root).setRoute(target);
  }

  /// Pushes a new route onto its navigation path.
  ///
  /// For shell routes, ensures the shell host exists in the parent path first.
  Future<dynamic> push(T route) async {
    // Handle RouteRedirect logic first
    T target = route;
    while (target is RouteRedirect) {
      final newTarget = await (target as RouteRedirect).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return;
      if (newTarget == target) break;
      if (newTarget is T) target = newTarget;
    }

    RouteHost? host = target.host;
    List<RouteHost> hostSegments = [];
    List<NavigationPath> hostPaths = [];
    while (host != null) {
      hostSegments.add(host);
      hostPaths.add(host.path);
      host = (host as RouteUnique).host;
    }
    hostPaths.add(root);

    for (var i = hostPaths.length - 1; i >= 1; i--) {
      final hostOfHostPath = hostPaths[i];
      final host = hostSegments[i - 1];
      hostOfHostPath.pushOrMoveToTop(host);
    }

    return (hostSegments.firstOrNull?.path ?? root).push(target);
  }

  /// Pushes a route or moves it to the top if already present.
  ///
  /// Useful for tab navigation where you don't want duplicates.
  void pushOrMoveToTop(T route) async {
    // Handle RouteRedirect logic first
    T target = route;
    while (target is RouteRedirect) {
      final newTarget = await (target as RouteRedirect).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return;
      if (newTarget == target) break;
      if (newTarget is T) target = newTarget;
    }

    RouteHost? host = target.host;
    List<RouteHost> hostSegments = [];
    while (host != null) {
      hostSegments.add(host);
      host = (host as RouteUnique).host;
    }

    for (var i = hostSegments.length - 1; i >= 1; i--) {
      final hostOfHost = hostSegments[i];
      final host = hostSegments[i - 1];
      hostOfHost.path.pushOrMoveToTop(host);
    }

    (hostSegments.firstOrNull?.path ?? root).pushOrMoveToTop(target);
  }

  /// Pops the current route from the nearest `navigationStack` path type.
  void pop() {
    final path = nearestDynamicPath;
    if (path.stack.isNotEmpty) path.pop();
  }

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget rootBuilder(BuildContext context) =>
      HostType.buildNavigationStack(this, root, routerDelegate.navigatorKey);

  /// Attempts to pop the current route, handling guards.
  ///
  /// Returns:
  /// - `true` if a route was popped or a guard was handled
  /// - `false` if there's nothing to pop
  /// - `null` in edge cases
  Future<bool?> tryPop() async {
    final path = nearestDynamicPath;

    // Try to pop active path first
    if (path.stack.isNotEmpty) {
      final last = path.stack.last;
      if (last is RouteGuard) {
        return await last.popGuard();
      }
      path.pop();
      return true;
    }

    // If child didn't pop, try to pop root
    if (root.stack.isNotEmpty) {
      root.pop();
      return true;
    }

    return false;
  }

  /// The route information parser for MaterialApp.router.
  late final CoordinatorRouteParser routeInformationParser =
      CoordinatorRouteParser(coordinator: this);

  /// The router delegate for MaterialApp.router.
  late final CoordinatorRouterDelegate routerDelegate =
      CoordinatorRouterDelegate(coordinator: this);

  /// Access to the navigator state.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
}

/// Extension type that provides utility methods for [NavigationPath].
extension type CoordinatorUtils<T extends RouteTarget>(NavigationPath<T> path) {
  /// Clears the path and sets a single route.
  void setRoute(T route) {
    path.clear();
    path.push(route);
  }
}

// ==============================================================================
// ROUTER IMPLEMENTATION (URL Handling)
// ==============================================================================

/// Parses [RouteInformation] to and from [Uri].
///
/// This is used by Flutter's Router widget to handle URL changes.
class CoordinatorRouteParser extends RouteInformationParser<Uri> {
  CoordinatorRouteParser({required this.coordinator});

  final Coordinator coordinator;

  /// Converts [RouteInformation] to a [Uri] configuration.
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri;
  }

  /// Converts a [Uri] configuration back to [RouteInformation].
  @override
  RouteInformation? restoreRouteInformation(Uri configuration) {
    return RouteInformation(uri: configuration);
  }
}

/// Router delegate that connects the [Coordinator] to Flutter's Router.
///
/// Manages the navigator stack and handles system navigation events.
class CoordinatorRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  CoordinatorRouterDelegate({required this.coordinator}) {
    coordinator.addListener(notifyListeners);
  }

  final Coordinator coordinator;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri? get currentConfiguration => coordinator.currentUri;

  @override
  Widget build(BuildContext context) => coordinator.rootBuilder(context);

  @override
  Future<void> setNewRoutePath(Uri configuration) async =>
      await coordinator.recoverRouteFromUri(configuration);

  @override
  Future<bool> popRoute() async {
    final result = await coordinator.tryPop();
    return result ?? false;
  }

  @override
  void dispose() {
    coordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
