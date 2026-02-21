import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/target.dart';
import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/path/base.dart';

/// Base class for route modules that handle a subset of application routes.
///
/// A route module encapsulates a group of related routes, their navigation
/// paths, layouts, and route parsing logic. This enables modular architecture
/// where different parts of the application can be developed independently.
///
/// ## Role in Navigation Flow
///
/// Route modules work with [CoordinatorModular]:
///
/// 1. When [CoordinatorModular.parseRouteFromUri] is called, it iterates through modules
/// 2. Each module's [parseRouteFromUri] is tried in order
/// 3. First non-null route wins - module order matters
/// 4. If all modules return null, [notFoundRoute] is called
///
/// ## Module Responsibilities
///
/// - Parse routes: Implement [parseRouteFromUri] for URI patterns
/// - Define paths: Override [paths] for nested navigation
/// - Register layouts: Override [defineLayout] for layout constructors
/// - Register converters: Override [defineConverter] for restorable converters
abstract class RouteModule<T extends RouteUri> {
  RouteModule._(this.coordinator);

  /// Creates a route module with a reference to its coordinator.
  RouteModule(CoordinatorModular<T> coordinator)
    : this._(coordinator.rootCoordinator as CoordinatorModular<T>);

  /// The coordinator that owns this module.
  ///
  /// Use this to access coordinator methods or other modules via [getModule].
  final CoordinatorModular<T> coordinator;

  /// The navigation paths managed by this module.
  ///
  /// Override to provide paths for nested navigation within this module.
  List<StackPath> get paths => [];

  /// Parses a URI and returns a route if this module handles it.
  ///
  /// Return null if this module doesn't handle the given URI.
  FutureOr<T?> parseRouteFromUri(Uri uri);

  /// Defines layouts for this module.
  ///
  /// Override to register layout constructors using [defineLayoutParent].
  void defineLayout() {}

  /// Defines restorable converters for this module.
  ///
  /// Override to register converters using [defineConverter].
  void defineConverter() {}
}

/// Mixin that enables modular route management by delegating to multiple modules.
///
/// [CoordinatorModular] extends [CoordinatorCore] with the ability to split
/// route management across multiple [RouteModule] instances.
///
/// ## Role in Navigation Flow
///
/// 1. [defineModules]: Returns the set of modules to register
/// 2. Route parsing: Modules are checked in order until one matches
/// 3. Path aggregation: All module paths are combined into coordinator paths
/// 4. Layout/converter delegation: Each module's define methods are called
mixin CoordinatorModular<T extends RouteUri> on CoordinatorCore<T> {
  late final Map<Type, RouteModule<T>> _modules = {
    for (final module in defineModules()) module.runtimeType: module,
  };

  /// Returns the set of route modules for this coordinator.
  ///
  /// The order determines which module is checked first during route parsing.
  Set<RouteModule<T>> defineModules();

  /// Retrieves a module by its type.
  ///
  /// Throws [TypeError] if the module is not registered.
  R getModule<R extends RouteModule<T>>() => _modules[R] as R;

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    for (final module in _modules.values) ...module.paths,
  ];

  /// Returns a route for URIs that don't match any module.
  ///
  /// Called when all modules return null from [parseRouteFromUri].
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
  FutureOr<T?> parseRouteFromUri(Uri uri) async {
    for (final module in _modules.values) {
      final route = await module.parseRouteFromUri(uri);
      if (route != null) return route;
    }

    if (isRouteModule) return null;
    return notFoundRoute(uri);
  }
}
