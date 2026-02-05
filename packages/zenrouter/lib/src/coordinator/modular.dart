import 'dart:async';

import 'package:zenrouter/zenrouter.dart';

/// Base class for route modules that handle a subset of application routes.
///
/// A [RouteModule] encapsulates a group of related routes, their navigation
/// paths, layouts, and route parsing logic. This enables modular architecture
/// where different parts of your application can be developed independently.
///
/// ## Architecture Overview
///
/// The modular coordinator pattern allows you to split route management across
/// multiple modules:
///
/// - **RouteModule**: Handles a specific domain of routes (e.g., auth, shop, settings)
/// - **CoordinatorModular**: Aggregates multiple modules and delegates route parsing
/// - **Module Isolation**: Each module manages its own paths and layouts independently
///
/// ## Benefits
///
/// - **Separation of Concerns**: Each module handles its own routes and logic
/// - **Team Collaboration**: Different teams can work on different modules
/// - **Code Organization**: Large applications become more maintainable
/// - **Reusability**: Modules can be reused across different applications
///
/// ## Creating a Route Module
///
/// ```dart
/// class AuthModule extends RouteModule<AppRoute> {
///   AuthModule(super.coordinator);
///
///   @override
///   FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
///     return switch (uri.pathSegments) {
///       ['auth', 'login'] => LoginRoute(),
///       ['auth', 'register'] => RegisterRoute(),
///       _ => null, // Not handled by this module
///     };
///   }
///
///   @override
///   void defineLayout() {
///     // Register layouts specific to auth module
///     RouteLayout.defineLayout(AuthLayout, AuthLayout.new);
///   }
/// }
/// ```
///
/// ## Module Responsibilities
///
/// Each module can:
/// - **Parse Routes**: Implement [parseRouteFromUri] to handle specific URI patterns
/// - **Define Paths**: Override [paths] to provide navigation paths for nested routes
/// - **Register Layouts**: Override [defineLayout] to register layout constructors
/// - **Register Converters**: Override [defineConverter] to register restorable converters
///
/// ## Route Parsing Strategy
///
/// When [CoordinatorModular.parseRouteFromUri] is called, it iterates through
/// all registered modules in order. The first module that returns a non-null
/// route wins. If all modules return null, [CoordinatorModular.notFoundRoute]
/// is called.
abstract class RouteModule<T extends RouteUnique> {
  /// Creates a route module with a reference to its coordinator.
  RouteModule(this.coordinator);

  /// The coordinator that owns this module.
  ///
  /// Use this to access coordinator methods or other modules via
  /// [CoordinatorModular.getModule].
  final CoordinatorModular<T> coordinator;

  /// The navigation paths managed by this module.
  ///
  /// Override this to provide paths for nested navigation within this module.
  /// These paths will be automatically aggregated by [CoordinatorModular].
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// List<StackPath> get paths => [shopPath, cartPath];
  /// ```
  List<StackPath> get paths => [];

  /// Parses a URI and returns a route if this module handles it.
  ///
  /// Return `null` if this module doesn't handle the given URI. The coordinator
  /// will continue checking other modules.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
  ///   return switch (uri.pathSegments) {
  ///     ['shop'] => ShopHomeRoute(),
  ///     ['shop', 'products', final id] => ProductRoute(id: id),
  ///     _ => null, // Let other modules handle it
  ///   };
  /// }
  /// ```
  FutureOr<T?> parseRouteFromUri(Uri uri);

  /// Defines layouts for this module.
  ///
  /// Override this to register layout constructors using
  /// [RouteLayout.defineLayout]. This is called automatically during
  /// coordinator initialization.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// void defineLayout() {
  ///   RouteLayout.defineLayout(ShopLayout, ShopLayout.new);
  /// }
  /// ```
  void defineLayout() {}

  /// Defines restorable converters for this module.
  ///
  /// Override this to register converters using
  /// [RestorableConverter.defineConverter]. This is called automatically
  /// during coordinator initialization.
  void defineConverter() {}
}

/// Mixin that enables modular route management by delegating to multiple modules.
///
/// [CoordinatorModular] extends [Coordinator] with the ability to split route
/// management across multiple [RouteModule] instances. This is ideal for
/// large applications where you want to organize routes by domain or feature.
///
/// ## How It Works
///
/// 1. **Module Registration**: Implement [defineModules] to return a set of modules
/// 2. **Route Parsing**: Routes are parsed by modules in order until one matches
/// 3. **Path Aggregation**: All module paths are combined into the coordinator's paths
/// 4. **Layout/Converter Delegation**: Each module's `defineLayout` and `defineConverter`
///    are called automatically
///
/// ## Quick Start
///
/// ```dart
/// abstract class AppRoute extends RouteTarget with RouteUnique {}
///
/// class AppCoordinator extends Coordinator<AppRoute>
///     with CoordinatorModular<AppRoute> {
///   @override
///   Set<RouteModule<AppRoute>> defineModules(
///     CoordinatorModular<AppRoute> coordinator,
///   ) {
///     return {
///       AuthModule(coordinator),
///       ShopModule(coordinator),
///       SettingsModule(coordinator),
///     };
///   }
///
///   @override
///   AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
/// }
/// ```
///
/// ## Module Order Matters
///
/// Modules are checked in the order they appear in the [Set] returned by
/// [defineModules]. The first module that returns a non-null route wins.
/// This allows you to prioritize certain modules or handle route conflicts.
///
/// **Example:**
/// ```dart
/// @override
/// Set<RouteModule<AppRoute>> defineModules(
///   CoordinatorModular<AppRoute> coordinator,
/// ) {
///   return {
///     AdminModule(coordinator),    // Checked first
///     PublicModule(coordinator),  // Checked second
///   };
/// }
/// ```
///
/// ## Accessing Modules
///
/// Use [getModule] to access a specific module by type. This is useful when
/// you need module-specific functionality or paths.
///
/// **Example:**
/// ```dart
/// final shopModule = coordinator.getModule<ShopModule>();
/// shopModule.shopPath.push(ProductRoute(id: '123'));
/// ```
mixin CoordinatorModular<T extends RouteUnique> on Coordinator<T> {
  late final Map<Type, RouteModule<T>> _modules = {
    for (final module in defineModules()) ...{module.runtimeType: module},
  };

  /// Defines the set of route modules for this coordinator.
  ///
  /// This method is called during coordinator initialization. Return a set
  /// containing all modules that should handle routes for this coordinator.
  ///
  /// **Important:** The order of modules in the set determines the order
  /// in which they are checked during route parsing. The first module that
  /// returns a non-null route wins.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// Set<RouteModule<AppRoute>> defineModules(
  ///   CoordinatorModular<AppRoute> coordinator,
  /// ) {
  ///   return {
  ///     AuthModule(coordinator),
  ///     ShopModule(coordinator),
  ///     SettingsModule(coordinator),
  ///   };
  /// }
  /// ```
  Set<RouteModule<T>> defineModules();

  /// Retrieves a module by its type.
  ///
  /// Use this to access module-specific functionality or paths.
  ///
  /// **Example:**
  /// ```dart
  /// final shopModule = coordinator.getModule<ShopModule>();
  /// final productPath = shopModule.shopPath;
  /// ```
  ///
  /// **Throws:** [TypeError] if the requested module type is not registered.
  R getModule<R extends RouteModule<T>>() => _modules[R] as R;

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    for (final module in _modules.values) ...module.paths,
  ];

  /// Returns a route for URIs that don't match any module.
  ///
  /// This is called when all modules return `null` from their
  /// [RouteModule.parseRouteFromUri] methods. Typically, this should return
  /// a "not found" or "404" route.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// AppRoute notFoundRoute(Uri uri) {
  ///   return NotFoundRoute(uri: uri);
  /// }
  /// ```
  T notFoundRoute(Uri uri);

  @override
  void defineLayout() {
    super.defineLayout();
    for (final module in _modules.values) {
      module.defineLayout();
    }
  }

  @override
  void defineConverter() {
    super.defineConverter();
    for (final module in _modules.values) {
      module.defineConverter();
    }
  }

  @override
  FutureOr<T> parseRouteFromUri(Uri uri) async {
    for (final module in _modules.values) {
      final route = await module.parseRouteFromUri(uri);
      if (route != null) return route;
    }
    return notFoundRoute(uri);
  }
}
