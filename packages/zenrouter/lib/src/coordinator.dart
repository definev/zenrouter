import 'dart:async';

import 'package:flutter/material.dart';
import 'path.dart';

/// Strategy for resolving parent layouts during navigation.
enum _ResolveLayoutStrategy {
  /// Pops items from the stack until the target layout is active.
  ///
  /// Used during browser back/forward navigation to ensure we return
  /// to a previous state rather than creating a duplicate one.
  popUntil,

  /// Pushes the layout to the top of the stack.
  ///
  /// Used when pushing new routes (e.g., [Coordinator.push]) to ensure
  /// the new route's layout is added on top of the current stack.
  pushToTop,

  /// Directly activates the layout, potentially resetting the stack.
  ///
  /// This is the default strategy used for [Coordinator.replace] or
  /// when recovering deep links, where the goal is to set a specific state.
  override,
}

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

  // coverage:ignore-start
  /// Returns the list of active layout paths in the navigation hierarchy.
  ///
  /// This starts from the [root] path and traverses down through active layouts,
  /// collecting the [StackPath] for each level.
  @Deprecated('Use `activeLayoutPaths` insteads')
  List<StackPath> get activeHostPaths => activeLayoutPaths;
  // coverage:ignore-end

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
  FutureOr<T> parseRouteFromUri(Uri uri);

  /// Handles navigation from a deep link URI.
  ///
  /// If the route has [RouteDeepLink], its custom handler is called.
  /// Otherwise, [replace] is called.
  Future<void> recoverRouteFromUri(Uri uri) async {
    final route = await parseRouteFromUri(uri);
    return recover(route);
  }

  /// Resolves and activates layouts for a given [layout].
  ///
  /// This ensures that all parent layouts in the hierarchy are properly
  /// activated or pushed onto their respective paths.
  ///
  /// [preferPush] determines whether to push the layout onto the stack
  /// or just activate it if it already exists.
  Future<bool> _resolveLayouts(
    RouteLayout? layout, {
    _ResolveLayoutStrategy strategy = _ResolveLayoutStrategy.override,
  }) async {
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
      switch (strategy) {
        case _ResolveLayoutStrategy.pushToTop
            when layoutOfLayoutPath is StackMutatable:
          layoutOfLayoutPath.pushOrMoveToTop(layout);
        case _ResolveLayoutStrategy.popUntil
            when layoutOfLayoutPath is StackMutatable:
          final layoutIndex = layoutOfLayoutPath.stack.indexOf(layout);

          /// If layoutIndex exists and not on the top
          if (layoutIndex != -1 &&
              layoutIndex != layoutOfLayoutPath.stack.length - 1) {
            final allowPop = (await layoutOfLayoutPath.pop())!;
            if (!allowPop) return false;
          } else {
            layoutOfLayoutPath.activateRoute(layout);
          }
        default:
          layoutOfLayoutPath.activateRoute(layout);
      }
    }
    return true;
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

  /// Navigates to a specific route, handling history restoration and stack management.
  ///
  /// **Why this exists:**
  /// Standard [push] always adds a new route to the stack, which can lead to
  /// duplicate entries and confusing browser history (e.g., A -> B -> A -> B).
  /// [navigate] is smarter: it checks if the target route already exists in the
  /// stack (e.g., in a browser "Back" scenario) and pops back to it instead of
  /// pushing a new instance. This ensures the navigation stack mirrors the
  /// user's expected history state.
  ///
  /// This method is primarily used by [CoordinatorRouterDelegate.setNewRoutePath]
  /// to handle browser back/forward navigation or direct URL updates.
  ///
  /// **Behavior:**
  /// 1. Resolves the layout and path for the target [route].
  /// 2. If the active path is a [NavigationPath]:
  ///    - **Existing Route:** If the route is already in the stack (back navigation),
  ///      it progressively pops the stack until the target route is reached.
  ///      - Respects [RouteGuard]s during popping.
  ///      - If a guard blocks popping, navigation is aborted and the URL is restored.
  ///    - **New Route:** If the route is not in the stack, it calls [push] to add it.
  /// 3. If the active path is an [IndexedStackPath]:
  ///    - Resolves parent layouts and activates the target route (switching tabs).
  ///
  /// **Failure Handling:**
  /// If layout resolution fails or a guard blocks the navigation, [notifyListeners]
  /// is called to sync the browser URL back to the current application state.
  Future<void> navigate(T route) async {
    final layout = route.resolveLayout(this);
    final routePath = layout?.resolvePath(this) ?? root;
    var routeIndex = routePath.stack.indexOf(route);
    switch (routePath) {
      case NavigationPath():
        if (routeIndex != -1) {
          final popSuccess = await _resolveLayouts(
            layout,
            strategy: _ResolveLayoutStrategy.popUntil,
          );
          if (!popSuccess) {
            // Layout resolution failed - restore the URL to current state
            notifyListeners();
            return;
          }

          // Pop until we reach the target route
          while (routePath.stack.length > routeIndex + 1) {
            final allowPop = await routePath.pop();
            if (allowPop == null || !allowPop) {
              // Guard blocked navigation or stack is empty - restore the URL
              notifyListeners();
              return;
            }
          }
        } else {
          push(route);
        }
      case IndexedStackPath():
        final popSuccess = await _resolveLayouts(
          layout,
          strategy: _ResolveLayoutStrategy.popUntil,
        );
        if (!popSuccess) {
          // Layout resolution failed - restore the URL to current state
          notifyListeners();
          return;
        }
        routePath.activateRoute(route);
    }
  }

  /// Wipes the current navigation stack and replaces it with the new route.
  Future<void> replace(T route) async {
    for (final path in paths) {
      path.reset();
    }
    T target = await RouteRedirect.resolve(route);
    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.override);

    await path.activateRoute(target);
  }

  /// Pushes a new route onto its navigation path.
  ///
  /// For shell routes, ensures the shell layout exists in the parent path first.
  Future<R?> push<R extends Object>(T route) async {
    T target = await RouteRedirect.resolve(route);
    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.pushToTop);

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
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.pushToTop);

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

  bool _initialRouteSet = false;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri? get currentConfiguration => coordinator.currentUri;

  @override
  Widget build(BuildContext context) => coordinator.layoutBuilder(context);

  /// Handles browser navigation events (back/forward buttons, URL changes).
  ///
  /// This method is called by Flutter's Router when the browser URL changes,
  /// either from user action (back/forward buttons) or programmatic navigation.
  ///
  /// **Initial Route Handling:**
  /// On first load ([_initialRouteSet] is false), uses [Coordinator.recover]
  /// to handle deep linking according to the route's [DeeplinkStrategy].
  ///
  /// **Subsequent Navigation:**
  /// For browser back/forward buttons:
  ///
  /// - **NavigationPath**: If the route exists in the stack, pops until
  ///   reaching that route. If not found, pushes it as a new route.
  ///   - Guards are consulted during popping
  ///   - If any guard blocks navigation, the URL is restored via [notifyListeners]
  ///   - Uses a while loop to handle dynamic stack changes during iteration
  ///
  /// - **IndexedStackPath**: Activates the route (switches tab) after ensuring
  ///   parent layouts are properly resolved.
  ///
  /// **URL Synchronization:**
  /// When navigation fails (guard blocks or layout resolution fails),
  /// [notifyListeners] is called to restore the browser URL to match
  /// the current app state, keeping URL and navigation state in sync.
  ///
  /// **Invariants:**
  /// - Routes cannot exist in multiple paths (each route has one path)
  /// - Route layouts are determined at creation and don't change
  /// - Path types (NavigationPath vs IndexedStackPath) are static
  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    final route = await coordinator.parseRouteFromUri(configuration);

    if (_initialRouteSet == false ||
        route is RouteDeepLink &&
            route.deeplinkStrategy == DeeplinkStrategy.custom) {
      _initialRouteSet = true;
      coordinator.recover(route);
    } else {
      coordinator.navigate(route);
    }
  }

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
