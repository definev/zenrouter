import 'dart:async';

import 'package:zenrouter_core/src/coordinator/modular.dart';
import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/routing/binding.dart';
import 'package:zenrouter_core/src/routing/manifest.dart';

/// Manifest-backed URI parsing through [routeBindings].
///
/// Applies to a [RouteModule], including a coordinator (which implements
/// that type). Opt in when the manifest and bindings should be the routing
/// source of truth; otherwise keep overriding `parseRouteFromUri`.
///
/// A standalone coordinator typically supplies [RouteBindingRegistry.notFound].
/// A child module must omit it so unmatched URIs fall through to siblings.
/// Do not mix this with [CoordinatorModular] on the same class — both
/// override [parseRouteFromUri]. Put bindings on child modules instead.
mixin RouteModuleBinding<T extends RouteUri, I extends Object>
    on RouteModule<T> {
  RouteBindingRegistry<I, T> get routeBindings;

  @override
  RouteManifest<I> get routeManifest => routeBindings.manifest;

  @override
  FutureOr<T?> parseRouteFromUri(Uri uri) => routeBindings.resolve(uri);
}
