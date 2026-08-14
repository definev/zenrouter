import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/target.dart';
import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/path/base.dart';
import 'package:zenrouter_core/src/routing/manifest.dart';

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
/// - Contribute topology: Override [routeManifest] or [routeManifestFragment]
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

  /// Declarative topology exposed by this module.
  ///
  /// Hand-written modules may remain parser-only during migration. Generated
  /// modules override this getter with their immutable route manifest.
  RouteManifest<Object> get routeManifest => RouteManifest.empty;

  /// Declarative topology contributed to an owning modular coordinator.
  ///
  /// Complete module manifests are exposed as fragments automatically.
  /// Override this getter directly when the contribution references layouts or
  /// indexed children declared by another module; the owning coordinator will
  /// validate those relationships after composing the application graph.
  RouteManifestFragment<Object> get routeManifestFragment =>
      routeManifest.fragment;

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
/// 1. [defineModules]: Returns modules in deterministic matching order
/// 2. Route parsing: Modules are checked in order until one matches
/// 3. Path aggregation: All module paths are combined into coordinator paths
/// 4. Layout/converter delegation: Each module's define methods are called
/// 5. Manifest composition: Nested fragments are flattened and validated once
mixin CoordinatorModular<T extends RouteUri> on CoordinatorCore<T> {
  late final List<RouteModule<T>> _moduleList = List.unmodifiable(
    defineModules(),
  );

  late final Map<Type, RouteModule<T>> _modules = _indexModules(_moduleList);

  /// Stable diagnostic name for the composed application manifest.
  ///
  /// Override when a specific name is required in serialized tooling output.
  String get routeManifestName => runtimeType.toString();

  /// Topology owned directly by this coordinator, excluding child modules.
  ///
  /// Modular coordinators should override this seam instead of
  /// [routeManifest], which is the fully composed graph.
  RouteManifestFragment<Object> get localRouteManifestFragment =>
      super.routeManifest.fragment;

  Iterable<RouteManifestFragment<Object>> get _routeManifestFragments sync* {
    final local = localRouteManifestFragment;
    if (!local.isEmpty) yield local;
    for (final module in _moduleList) {
      if (module case CoordinatorModular modular) {
        yield* modular._routeManifestFragments.cast();
      } else {
        final fragment = module.routeManifestFragment;
        if (!fragment.isEmpty) yield fragment;
      }
    }
  }

  /// Fully composed route topology for this coordinator and all nested
  /// modules. Graph relationships and ambiguous paths are validated here.
  @override
  late final RouteManifest<Object> routeManifest =
      RouteManifest<Object>.fromFragments(
        name: routeManifestName,
        fragments: _routeManifestFragments,
      );

  Map<Type, RouteModule<T>> _indexModules(Iterable<RouteModule<T>> modules) {
    final indexed = <Type, RouteModule<T>>{};
    for (final module in modules) {
      final type = module.runtimeType;
      if (indexed.containsKey(type)) {
        throw StateError(
          'Duplicate route module type $type. '
          'Each module type may be registered only once.',
        );
      }
      indexed[type] = module;
    }
    return indexed;
  }

  late final Map<Type, RouteModule<T>> _allModules = {
    runtimeType: this,
    ..._modules,
    for (final module in _modules.values)
      if (module case CoordinatorModular modular) ...modular._allModules.cast(),
  };

  @override
  void dispose() {
    for (final module in _modules.values.whereType<CoordinatorCore>()) {
      module.dispose();
    }
    _modules.clear();
    _allModules.clear();
    super.dispose();
  }

  /// Returns route modules in deterministic matching order.
  ///
  /// The order determines which module is checked first during route parsing.
  /// The iterable is snapshotted once during initialization.
  Iterable<RouteModule<T>> defineModules();

  /// Retrieves a module by its type.
  ///
  /// Throws [TypeError] if the module is not registered.
  R getModule<R extends RouteModule<T>>() => _allModules[R] as R;

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
      if (module is! CoordinatorCore) {
        module.defineLayout();
      }
    }
  }

  @override
  void defineConverter() {
    super.defineConverter();
    for (final module in _modules.values) {
      if (module is! CoordinatorCore) {
        module.defineConverter();
      }
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
