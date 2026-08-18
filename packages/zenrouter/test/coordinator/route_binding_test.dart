import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

enum _AppRouteId { home, profile }

enum _ModuleRouteId { detail }

abstract class _AppRoute extends RouteTarget with RouteUnique {
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) =>
      const SizedBox();
}

final class _HomeRoute extends _AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  List<Object?> get props => const [];
}

final class _ProfileRoute extends _AppRoute {
  _ProfileRoute(this.profileId);

  final String profileId;

  @override
  Uri toUri() => Uri.parse('/profiles/$profileId');

  @override
  List<Object?> get props => [profileId];
}

final class _ModuleDetailRoute extends _AppRoute {
  _ModuleDetailRoute(this.detailId);

  final String detailId;

  @override
  Uri toUri() => Uri.parse('/module/$detailId');

  @override
  List<Object?> get props => [detailId];
}

final class _NotFoundRoute extends _AppRoute with RouteNotFound {
  _NotFoundRoute(this.uri);

  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  List<Object?> get props => [uri];
}

class _BoundCoordinator extends Coordinator<_AppRoute>
    with RouteModuleBinding<_AppRoute, _AppRouteId> {
  static final manifest = RouteManifest<_AppRouteId>(
    name: 'bound-coordinator',
    idCodec: RouteIdCodec.enumValues(_AppRouteId.values),
    routes: [
      RouteManifestRoute(id: _AppRouteId.home, path: '/'),
      RouteManifestRoute(id: _AppRouteId.profile, path: '/profiles/:profileId'),
    ],
  );

  @override
  late final routeBindings = RouteBindingRegistry<_AppRouteId, _AppRoute>(
    manifest: manifest,
    bindings: [
      RouteBinding(id: _AppRouteId.home, create: (_) => _HomeRoute()),
      RouteBinding(
        id: _AppRouteId.profile,
        create: (match) => _ProfileRoute(match.pathParameters['profileId']!),
      ),
    ],
    notFound: _NotFoundRoute.new,
  );
}

class _BoundModule extends RouteModule<_AppRoute>
    with RouteModuleBinding<_AppRoute, _ModuleRouteId> {
  _BoundModule(super.coordinator);

  static final manifest = RouteManifest<_ModuleRouteId>(
    name: 'bound-module',
    idCodec: RouteIdCodec.enumValues(_ModuleRouteId.values),
    routes: [
      RouteManifestRoute(id: _ModuleRouteId.detail, path: '/module/:detailId'),
    ],
  );

  @override
  late final routeBindings = RouteBindingRegistry<_ModuleRouteId, _AppRoute>(
    manifest: manifest,
    bindings: [
      RouteBinding(
        id: _ModuleRouteId.detail,
        create: (match) =>
            _ModuleDetailRoute(match.pathParameters['detailId']!),
      ),
    ],
  );
}

class _ModularCoordinator extends Coordinator<_AppRoute>
    with CoordinatorModular<_AppRoute> {
  @override
  Iterable<RouteModule<_AppRoute>> defineModules() => [_BoundModule(this)];

  @override
  _AppRoute notFoundRoute(Uri uri) => _NotFoundRoute(uri);
}

void main() {
  group('RouteModuleBinding on Coordinator', () {
    test(
      'provides manifest-backed parsing without a parser override',
      () async {
        final coordinator = _BoundCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/profiles/core'),
        );

        expect(route, isA<_ProfileRoute>());
        expect((route as _ProfileRoute).profileId, 'core');
        expect(coordinator.routeManifest, same(_BoundCoordinator.manifest));
      },
    );

    test('flows through the existing typed request resolver', () async {
      final coordinator = _BoundCoordinator();

      final matched = await coordinator.resolveRoute(
        RouteRequest.navigation(Uri.parse('/')),
      );
      final notFound = await coordinator.resolveRoute(
        RouteRequest.navigation(Uri.parse('/missing')),
      );

      expect(matched, isA<MatchedRouteResolution<_AppRoute>>());
      expect(notFound, isA<NotFoundRouteResolution<_AppRoute>>());
    });
  });

  test(
    'RouteModuleBinding participates in modular parsing and composition',
    () async {
      final coordinator = _ModularCoordinator();

      final route = await coordinator.parseRouteFromUri(
        Uri.parse('/module/42'),
      );

      expect(route, isA<_ModuleDetailRoute>());
      expect((route as _ModuleDetailRoute).detailId, '42');
      expect(
        coordinator.routeManifest.match(Uri.parse('/module/42'))?.id,
        _ModuleRouteId.detail,
      );
    },
  );
}
