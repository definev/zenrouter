import 'dart:async';
import 'dart:collection';

import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/routing/manifest.dart';

/// Creates one concrete route from a successful manifest match.
///
/// The match is exposed through the common `Object` ID view so independently
/// typed feature bindings can be composed into one application registry.
typedef RouteBindingFactory<T extends RouteUri> =
    FutureOr<T> Function(RouteManifestMatch<Object> match);

/// Creates an optional route when no manifest pattern matches a URI.
///
/// Return a route mixing in `RouteNotFound` when `CoordinatorCore.resolveRoute`
/// should expose the result with HTTP/not-found status semantics.
typedef RouteNotFoundBinding<T extends RouteUri> =
    FutureOr<T?> Function(Uri uri);

/// Loads a deferred library before a binding factory runs.
typedef RouteLibraryLoader = Future<dynamic> Function();

/// Wraps [create] so [loadLibrary] completes first.
///
/// Use with [RouteBindingFactory] or [RouteNotFoundBinding]:
///
/// ```dart
/// RouteBinding.deferred(
///   id: HomeRouteId.home,
///   loadLibrary: home.loadLibrary,
///   create: (_) => home.HomeRoute(),
/// );
///
/// notFound: deferredRouteNotFoundBinding(
///   loadLibrary: missing.loadLibrary,
///   create: (uri) => missing.NotFoundRoute(uri),
/// );
/// ```
Future<R> Function(A) deferredBindingFactory<A, R>({
  required RouteLibraryLoader loadLibrary,
  required FutureOr<R> Function(A) create,
}) => (argument) async {
  await loadLibrary();
  return await create(argument);
};

/// Deferred [RouteNotFoundBinding] using [deferredBindingFactory].
RouteNotFoundBinding<T> deferredRouteNotFoundBinding<T extends RouteUri>({
  required RouteLibraryLoader loadLibrary,
  required RouteNotFoundBinding<T> create,
}) => deferredBindingFactory(loadLibrary: loadLibrary, create: create);

/// Presentation adapter for one route-manifest ID.
///
/// [I] remains strongly typed for declaration and validation. The factory only
/// consumes ID-agnostic match data, which makes bindings with different ID
/// types safely composable in a `RouteBindingRegistry<Object, T>`.
final class RouteBinding<I extends Object, T extends RouteUri> {
  const RouteBinding({required this.id, required this.create});

  factory RouteBinding.deferred({
    required I id,
    required RouteLibraryLoader loadLibrary,
    required RouteBindingFactory<T> create,
  }) => RouteBinding(
    id: id,
    create: deferredBindingFactory(loadLibrary: loadLibrary, create: create),
  );

  final I id;
  final RouteBindingFactory<T> create;
}

/// Immutable, validated adapter from a [RouteManifest] to concrete routes.
///
/// Construction fails when bindings are duplicated, target a layout or unknown
/// ID, or leave a manifest route unbound. After construction every successful
/// manifest match resolves through exactly one binding.
final class RouteBindingRegistry<I extends Object, T extends RouteUri> {
  factory RouteBindingRegistry({
    required RouteManifest<I> manifest,
    required Iterable<RouteBinding<I, T>> bindings,
    RouteNotFoundBinding<T>? notFound,
  }) {
    final bindingList = List<RouteBinding<I, T>>.unmodifiable(bindings);
    final byId = <I, RouteBinding<I, T>>{};
    for (final binding in bindingList) {
      if (byId.containsKey(binding.id)) {
        throw RouteBindingValidationException<I>(
          'Duplicate route binding ID ${binding.id}',
          routeIds: [binding.id],
        );
      }
      final node = manifest[binding.id];
      if (node == null) {
        throw RouteBindingValidationException<I>(
          'Route binding ${binding.id} is not present in ${manifest.name}',
          routeIds: [binding.id],
        );
      }
      if (node is! RouteManifestRoute<I>) {
        throw RouteBindingValidationException<I>(
          'Route binding ${binding.id} targets a layout instead of a route',
          routeIds: [binding.id],
        );
      }
      byId[binding.id] = binding;
    }

    final missingIds = [
      for (final route in manifest.routes)
        if (!byId.containsKey(route.id)) route.id,
    ];
    if (missingIds.isNotEmpty) {
      throw RouteBindingValidationException<I>(
        'Manifest ${manifest.name} has unbound route IDs: '
        '${missingIds.join(', ')}',
        routeIds: missingIds,
      );
    }

    return RouteBindingRegistry._(
      manifest,
      bindingList,
      UnmodifiableMapView(byId),
      notFound,
    );
  }

  const RouteBindingRegistry._(
    this.manifest,
    this.bindings,
    this._bindingsById,
    this.notFound,
  );

  final RouteManifest<I> manifest;
  final List<RouteBinding<I, T>> bindings;
  final RouteNotFoundBinding<T>? notFound;
  final Map<I, RouteBinding<I, T>> _bindingsById;

  RouteBinding<I, T>? operator [](I id) => _bindingsById[id];

  /// Resolves a URI through manifest matching and its corresponding binding.
  FutureOr<T?> resolve(Uri uri) {
    final match = manifest.match(uri);
    if (match == null) return notFound?.call(uri);
    return bind(match);
  }

  /// Creates a route from a match produced by this registry's manifest.
  FutureOr<T> bind(RouteManifestMatch<I> match) {
    final binding = _bindingsById[match.id];
    if (binding == null) {
      throw StateError(
        'Route match ${match.id} does not belong to binding registry '
        '${manifest.name}',
      );
    }
    return binding.create(match);
  }
}

/// Builds a typed route-binding registry directly from this manifest.
///
/// The manifest supplies [I], so callers only need to specify the concrete
/// route type while preserving the relationship between manifest IDs,
/// bindings, lookups, and matches.
extension RouteManifestBinding<I extends Object> on RouteManifest<I> {
  RouteBindingRegistry<I, T> bind<T extends RouteUri>({
    required Iterable<RouteBinding<I, T>> bindings,
    RouteNotFoundBinding<T>? notFound,
  }) => RouteBindingRegistry<I, T>(
    manifest: this,
    bindings: bindings,
    notFound: notFound,
  );
}

/// Invalid or incomplete manifest-to-route binding configuration.
final class RouteBindingValidationException<I extends Object>
    implements Exception {
  RouteBindingValidationException(
    this.message, {
    Iterable<I> routeIds = const [],
  }) : routeIds = List.unmodifiable(routeIds);

  final String message;
  final List<I> routeIds;

  @override
  String toString() => 'RouteBindingValidationException: $message';
}
