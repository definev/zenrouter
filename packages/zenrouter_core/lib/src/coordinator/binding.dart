import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/coordinator/modular.dart';
import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/routing/binding.dart';
import 'package:zenrouter_core/src/routing/manifest.dart';

/// Gives a coordinator manifest-backed URI parsing through [routeBindings].
///
/// Existing coordinators can keep overriding `parseRouteFromUri`; opt into this
/// adapter when the manifest and bindings should be the routing source of truth.
mixin CoordinatorRouteBinding<T extends RouteUri, I extends Object>
    on CoordinatorCore<T> {
  RouteBindingRegistry<I, T> get routeBindings;

  @override
  RouteManifest<I> get routeManifest => routeBindings.manifest;

  @override
  FutureOr<T?> parseRouteFromUri(Uri uri) => routeBindings.resolve(uri);
}

/// Gives a route module manifest-backed URI parsing through [routeBindings].
mixin RouteModuleBinding<T extends RouteUri, I extends Object>
    on RouteModule<T> {
  RouteBindingRegistry<I, T> get routeBindings;

  @override
  RouteManifest<I> get routeManifest => routeBindings.manifest;

  @override
  FutureOr<T?> parseRouteFromUri(Uri uri) => routeBindings.resolve(uri);
}
