import 'dart:async';

import 'package:flutter/material.dart';
import 'core.dart';

/// Makes a route identifiable and usable with [Coordinator].
///
/// **Required for all routes** used with the Coordinator pattern.
///
/// [RouteUnique] provides the link between a route and its [NavigationPath]
/// by implementing [getPath], which tells the coordinator which path this
/// route belongs to.
///
/// Example:
/// ```dart
/// class HomeRoute extends RouteTarget with RouteUnique {
///   @override
///   NavigationPath getPath(AppCoordinator coordinator) => coordinator.root;
/// }
/// ```
mixin RouteUnique on RouteTarget {
  /// Returns the navigation path this route belongs to.
  ///
  /// The coordinator uses this to determine where to add the route.
  NavigationPath getPath(covariant Coordinator coordinator);
}

/// Marks a route as part of a nested navigation shell.
///
/// Use [RouteShell] for routes that belong to a nested navigator, such as:
/// - Individual tabs in a tab bar
/// - Drawer menu items with their own navigation
/// - Nested sections of your app
///
/// Every shell route must specify its [shellHost], which is the container
/// that provides the UI framework (like a tab bar or drawer).
///
/// Example:
/// ```dart
/// class HomeTab extends AppRoute with RouteShell {
///   @override
///   TabShellHost get shellHost => TabShellHost();
///
///   @override
///   NavigationPath getPath(coordinator) => coordinator.tabPath;
/// }
/// ```
mixin RouteShell<T extends RouteUnique> on RouteUnique {
  /// The host route that provides the shell container.
  T get shellHost;
}

/// Marks a route as the host/container for a shell's nested navigation.
///
/// Use [RouteShellHost] to create the container that holds shell routes.
/// This is typically a scaffold with a tab bar, drawer, or bottom navigation.
///
/// The host is responsible for:
/// - Providing the UI framework (tab bar, drawer, etc.)
/// - Embedding a [NavigationStack] for the shell's routes
/// - Defining which path it belongs to ([getHostPath])
///
/// Example:
/// ```dart
/// class TabShellHost extends AppRoute with RouteShellHost, RouteBuilder {
///   @override
///   TabShellHost get shellHost => this;
///
///   @override
///   NavigationPath getHostPath(coordinator) => coordinator.root;
///
///   @override
///   Widget build(coordinator, context) {
///     return Scaffold(
///       body: NavigationStack(path: coordinator.tabPath, ...),
///       bottomNavigationBar: BottomNavigationBar(...),
///     );
///   }
/// }
/// ```
mixin RouteShellHost<T extends RouteUnique> on RouteShell<T> {
  /// Resolves shell routes to their destinations.
  ///
  /// Defaults to [Coordinator.defaultResolver].
  RouteDestination<T> resolver(covariant Coordinator coordinator, T route) =>
      Coordinator.defaultResolver(coordinator, route);

  /// Returns the navigation path that hosts this shell.
  ///
  /// This is different from [getPath] - it's where the shell host itself lives,
  /// not where its children live.
  NavigationPath getHostPath(covariant Coordinator coordinator);
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

/// Provides declarative widget building for routes.
///
/// Use [RouteBuilder] to define the UI inline with your route class.
/// This is the most common way to create simple routes.
///
/// Methods:
/// - [build]: Build the route's widget (required)
/// - [builder]: Wraps [build] with a Builder widget (optional override)
/// - [destination]: Returns the RouteDestination (optional override)
///
/// Example:
/// ```dart
/// class SettingsRoute extends AppRoute with RouteBuilder {
///   @override
///   Widget build(coordinator, context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Settings')),
///       body: SettingsContent(),
///     );
///   }
/// }
/// ```
mixin RouteBuilder on RouteUnique {
  /// Returns the route destination with page type.
  ///
  /// By default, creates a Material page with [builder] as the child.
  /// Override to customize the page type or transition.
  RouteDestination<T> destination<T extends RouteUnique>(
    covariant Coordinator coordinator,
  ) => RouteDestination.material(builder(coordinator));

  /// Creates a Builder widget that calls [build].
  ///
  /// Override if you need custom widget wrapping logic.
  Widget builder(covariant Coordinator coordinator) =>
      Builder(builder: (context) => build(coordinator, context));

  /// Builds the widget for this route.
  ///
  /// This is where you return your Scaffold, page content, etc.
  Widget build(covariant Coordinator coordinator, BuildContext context);
}

/// The central coordinator that manages all navigation for your app.
///
/// [Coordinator] is the brain of ZenRouter. It:
/// - Manages multiple [NavigationPath]s (root, shells, etc.)
/// - Parses URIs into routes
/// - Resolves routes to widgets
/// - Handles deep linking
/// - Provides navigation methods (push, pop, replace)
///
/// To use, extend [Coordinator] and:
/// 1. Define your navigation paths
/// 2. Implement [parseRouteFromUri]
/// 3. Optionally override [pathResolver] for custom path routing
///
/// Example:
/// ```dart
/// class AppCoordinator extends Coordinator<AppRoute> {
///   final shellPath = NavigationPath<ShellRoute>();
///
///   @override
///   List<NavigationPath> get paths => [root, shellPath];
///
///   @override
///   AppRoute parseRouteFromUri(Uri uri) {
///     return switch (uri.pathSegments) {
///       [] => HomeRoute(),
///       ['settings'] => SettingsRoute(),
///       _ => HomeRoute(),
///     };
///   }
/// }
/// ```
abstract class Coordinator<T extends RouteUnique> with ChangeNotifier {
  Coordinator() {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
  }

  /// All navigation paths managed by this coordinator.
  ///
  /// Must include at least [root]. Add additional paths for shells.
  List<NavigationPath> get paths => [root];
  @override
  void dispose() {
    super.dispose();
    for (final path in paths) {
      path.removeListener(notifyListeners);
    }
  }

  /// Default resolver that handles [RouteBuilder] routes.
  ///
  /// Override if you need custom resolution logic.
  static RouteDestination<T> defaultResolver<T extends RouteUnique>(
    Coordinator coordinator,
    T route,
  ) => switch (route) {
    /// Host shell must be handled by [NavigationStack]
    // RouteShellHost() => throw UnimplementedError(),
    RouteBuilder() => (route as RouteBuilder).destination(coordinator),
    _ => throw UnimplementedError(),
  };

  /// The root (primary) navigation path.
  ///
  /// All coordinators have at least this one path.
  final NavigationPath<T> root = NavigationPath();

  /// Resolver for routes in the [root] path.
  ///
  /// Override for custom resolution logic.
  RouteDestination<T> rootResolver(T route) => defaultResolver(this, route);

  /// The currently active navigation path.
  ///
  /// Returns the deepest nested path that has routes, or [root] if none.
  NavigationPath get activePath => root.stack.lastOrNull?.getPath(this) ?? root;

  /// Resolves which [NavigationPath] a route belongs to.
  ///
  /// Override to customize path routing logic.
  NavigationPath pathResolver(T route) => switch (route) {
    RouteShellHost() => (route as RouteShellHost).getHostPath(this),
    _ => route.getPath(this),
  };

  /// Returns the current URI based on the active route.
  Uri get currentUri => activePath.stack.lastOrNull?.toUri() ?? Uri.parse('/');

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
  void replace(T route) {
    final path = pathResolver(route);
    T? hostRoute = route;
    while (hostRoute != null) {
      if (hostRoute is RouteShell<T> && hostRoute is! RouteShellHost) {
        hostRoute = (hostRoute as RouteShell<T>).shellHost;
        CoordinatorUtils(pathResolver(hostRoute)).setRoute(hostRoute);
      } else {
        hostRoute = null;
      }
    }
    CoordinatorUtils(path).setRoute(route);
  }

  /// Pushes a new route onto its navigation path.
  ///
  /// For shell routes, ensures the shell host exists in the parent path first.
  Future<dynamic> push(T route) {
    final path = pathResolver(route);
    T? hostRoute = route;
    while (hostRoute != null) {
      if (hostRoute is RouteShell<T> && hostRoute is! RouteShellHost) {
        hostRoute = (hostRoute as RouteShell<T>).shellHost;
        pathResolver(hostRoute).pushOrMoveToTop(hostRoute);
      } else {
        hostRoute = null;
      }
    }
    return path.push(route);
  }

  /// Pushes a route or moves it to the top if already present.
  ///
  /// Useful for tab navigation where you don't want duplicates.
  void pushOrMoveToTop(T route) {
    final path = pathResolver(route);
    T? hostRoute = route;
    while (hostRoute != null) {
      if (hostRoute is RouteShell<T> && hostRoute is! RouteShellHost) {
        hostRoute = (hostRoute as RouteShell<T>).shellHost;
        pathResolver(hostRoute).pushOrMoveToTop(hostRoute);
      } else {
        hostRoute = null;
      }
    }
    path.pushOrMoveToTop(route);
  }

  /// Pops the current route from the active path.
  void pop() {
    if (activePath.stack.isNotEmpty) {
      activePath.pop();
    }
  }

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget rootBuilder(BuildContext context) {
    return NavigationStack(
      navigatorKey: routerDelegate.navigatorKey,
      path: root,
      resolver: rootResolver,
    );
  }

  /// Attempts to pop the current route, handling guards.
  ///
  /// Returns:
  /// - `true` if a route was popped or a guard was handled
  /// - `false` if there's nothing to pop
  /// - `null` in edge cases
  Future<bool?> tryPop() async {
    final path = activePath;

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
  late final CoordinatorRouteParser parser = CoordinatorRouteParser(
    coordinator: this,
  );

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
  Future<void> setNewRoutePath(Uri configuration) async {
    await coordinator.recoverRouteFromUri(configuration);
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
