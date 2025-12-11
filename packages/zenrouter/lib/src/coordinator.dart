import 'dart:async';

import 'package:flutter/material.dart';
import 'path.dart';

/// The core class that manages navigation state and logic.
///
/// The [Coordinator] is responsible for:
/// - Managing the navigation stack(s) via [paths].
/// - Handling deep links and URL parsing.
/// - coordinating transitions and layouts.
/// - Providing access to the [NavigatorState].
///
/// Subclasses should override [paths] to define their own navigation structure
/// and [parseRouteFromUri] to handle deep linking.
abstract class Coordinator<T extends RouteUnique> with ChangeNotifier {
  Coordinator() {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
    defineLayout();
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
  /// If you add custom paths, make sure to override [paths]
  List<StackPath> get paths => [root];

  /// Defines the layout structure for this coordinator.
  ///
  /// This method is called during initialization. Override this to register
  /// custom layouts using [RouteLayout.defineLayout].
  void defineLayout() {}

  /// Returns the current URI based on the active route.
  Uri get currentUri => activePath.activeRoute?.toUri() ?? Uri.parse('/');

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// This traverses through nested layouts to find the most deeply nested
  /// layout that is currently active. Returns `null` that mean root is active layout.
  RouteLayout? get activeLayout {
    T? current = root.activeRoute;
    if (current == null || current is! RouteLayout) return null;

    RouteLayout? deepestLayout = current;

    // Traverse through nested layouts to find the deepest one
    while (current is RouteLayout) {
      deepestLayout = current;
      final path = current.resolvePath(this);
      current = path.activeRoute as T?;

      // If the next route is not a layout, we've found the deepest layout
      if (current is! RouteLayout) break;
    }

    return deepestLayout;
  }

  /// Returns all active [RouteLayout] instances in the navigation hierarchy.
  ///
  /// This traverses through the active route to collect all layouts from root
  /// to the deepest layout. Returns an empty list if no layouts are active.
  List<RouteLayout> get activeLayouts {
    List<RouteLayout> layouts = [];
    T? current = root.activeRoute;

    // Traverse through the hierarchy and collect all RouteLayout instances
    while (current != null && current is RouteLayout) {
      layouts.add(current);
      final path = current.resolvePath(this);
      current = path.activeRoute as T?;
    }

    return layouts;
  }

  /// Returns the list of active layout paths in the navigation hierarchy.
  ///
  /// This starts from the [root] path and traverses down through active layouts,
  /// collecting the [StackPath] for each level.
  @Deprecated('Use `activeLayoutPaths` insteads')
  List<StackPath> get activeHostPaths => activeLayoutPaths;

  /// Returns the list of active layout paths in the navigation hierarchy.
  ///
  /// This starts from the [root] path and traverses down through active layouts,
  /// collecting the [StackPath] for each level.
  List<StackPath> get activeLayoutPaths {
    List<StackPath> pathSegment = [root];
    StackPath path = root;
    T? current = root.stack.lastOrNull;
    if (current == null) return pathSegment;

    while (current is RouteLayout) {
      final layout = current as RouteLayout;
      path = layout.resolvePath(this);
      pathSegment.add(path);
      current = path.activeRoute as T?;
    }

    return pathSegment;
  }

  /// Returns the currently active [StackPath].
  ///
  /// This is the path that contains the currently active route.
  StackPath<T> get activePath =>
      (activeLayoutPaths.lastOrNull ?? root) as StackPath<T>;

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
  /// Otherwise, [replace] is called.
  FutureOr<void> recoverRouteFromUri(Uri uri) async {
    final route = parseRouteFromUri(uri);
    if (route is RouteDeepLink) {
      switch (route.deeplinkStrategy) {
        case DeeplinkStrategy.push:
          await push(route);
        case DeeplinkStrategy.replace:
          replace(route);
        case DeeplinkStrategy.custom:
          await route.deeplinkHandler(this, uri);
      }
    } else {
      replace(route);
    }
  }

  /// Resolves and activates layouts for a given [layout].
  ///
  /// This ensures that all parent layouts in the hierarchy are properly
  /// activated or pushed onto their respective paths.
  ///
  /// [preferPush] determines whether to push the layout onto the stack
  /// or just activate it if it already exists.
  void _resolveLayouts(RouteLayout? layout, {bool preferPush = false}) {
    List<RouteLayout> layouts = [];
    List<StackPath> layoutPaths = [];
    while (layout != null) {
      layouts.add(layout);
      layoutPaths.add(layout.resolvePath(this));
      layout = layout.resolveLayout(this);
    }
    layoutPaths.add(root);

    for (var i = layoutPaths.length - 1; i >= 1; i--) {
      final layoutOfLayoutPath = layoutPaths[i];
      final layout = layouts[i - 1];
      if (layoutOfLayoutPath is StackMutatable && preferPush) {
        layoutOfLayoutPath.pushOrMoveToTop(layout);
      } else {
        layoutOfLayoutPath.activateRoute(layout);
      }
    }
  }

  /// Manually recover deep link from route
  Future<void> recover(T route) async {
    if (route is RouteDeepLink) {
      switch (route.deeplinkStrategy) {
        case DeeplinkStrategy.push:
          await push(route);
        case DeeplinkStrategy.replace:
          replace(route);
        case DeeplinkStrategy.custom:
          await route.deeplinkHandler(this, route.toUri());
      }
    } else {
      replace(route);
    }
  }

  /// Wipes the current navigation stack and replaces it with the new route.
  void replace(T route) async {
    for (final path in paths) {
      path.reset();
    }
    T target = await RouteRedirect.resolve(route);
    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    _resolveLayouts(layout, preferPush: false);

    path.activateRoute(target);
  }

  /// Pushes a new route onto its navigation path.
  ///
  /// For shell routes, ensures the shell layout exists in the parent path first.
  Future<R?> push<R extends Object>(T route) async {
    T target = await RouteRedirect.resolve(route);
    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    _resolveLayouts(layout, preferPush: true);

    switch (path) {
      case StackMutatable():
        return path.push(target);
      default:
        path.activateRoute(target);
        return null;
    }
  }

  /// Pushes a route or moves it to the top if already present.
  ///
  /// Useful for tab navigation where you don't want duplicates.
  void pushOrMoveToTop(T route) async {
    final target = await RouteRedirect.resolve(route);
    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    _resolveLayouts(layout, preferPush: true);

    switch (path) {
      case StackMutatable():
        path.pushOrMoveToTop(target);
      default:
        path.activateRoute(target);
    }
  }

  /// Pops the last route from the nearest dynamic path.
  void pop([Object? result]) {
    // Get all dynamic paths from the active layout paths
    final dynamicPaths = activeLayoutPaths.whereType<NavigationPath>().toList();

    // Try to pop from the farthest element if stack length >= 2
    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        path.pop(result);
        return;
      }
    }
  }

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget layoutBuilder(BuildContext context) =>
      RouteLayout.buildPrimitivePath(NavigationPath, this, root, null);

  /// Attempts to pop the nearest dynamic path.
  /// The [RouteGuard] logic is handled here.
  ///
  /// Returns:
  /// - `true` if the route can pop
  /// - `false` if the route can't pop
  /// - `null` if the [RouteGuard] want manual control
  Future<bool?> tryPop() async {
    // Get all dynamic paths from the active layout paths
    final dynamicPaths = activeLayoutPaths.whereType<NavigationPath>().toList();

    // Try to pop from the farthest element if stack length >= 2
    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        final last = path.stack.last;
        if (last is RouteGuard) {
          final didPop = await last.popGuard();
          path.pop();
          return didPop;
        }
        path.pop();
        return true;
      }
    }

    return false;
  }

  /// The route information parser for [Router]
  late final CoordinatorRouteParser routeInformationParser =
      CoordinatorRouteParser(coordinator: this);

  /// The router delegate for [Router]
  late final CoordinatorRouterDelegate routerDelegate =
      CoordinatorRouterDelegate(coordinator: this);

  /// Access to the navigator state.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
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
  Widget build(BuildContext context) => coordinator.layoutBuilder(context);

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
