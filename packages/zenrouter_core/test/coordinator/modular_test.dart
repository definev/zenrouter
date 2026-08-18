// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

enum _AppId { home }

enum _AuthId { login }

void main() {
  group('RouteModule', () {
    test('stores the root coordinator and default empty topology', () {
      final coordinator = ModularAppCoordinator(
        modules: (c) => [FeatureModule(c)],
      );
      final module = coordinator.getModule<FeatureModule>();

      expect(module.coordinator, same(coordinator));
      expect(module.paths, isEmpty);
      expect(module.routeManifest.nodes, isEmpty);
      expect(module.routeManifestFragment.isEmpty, isTrue);

      final layouts = module.layoutCalls;
      final converters = module.converterCalls;
      module.defineLayout();
      module.defineConverter();
      expect(module.layoutCalls, layouts + 1);
      expect(module.converterCalls, converters + 1);
    });
  });

  group('CoordinatorModular', () {
    test('registers each module type once and rejects duplicates', () {
      final coordinator = ModularAppCoordinator(
        modules: (c) => [
          FeatureModule(c, prefix: 'auth'),
          AsyncFeatureModule(c, prefix: 'shop'),
        ],
      );

      expect(
        () => ModularAppCoordinator(
          modules: (c) => [FeatureModule(c), FeatureModule(c)],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Duplicate route module type'),
          ),
        ),
      );

      final first = coordinator.getModule<FeatureModule>();
      expect(identical(first, coordinator.getModule<FeatureModule>()), isTrue);
      expect(
        coordinator.getModule<AsyncFeatureModule>(),
        isA<AsyncFeatureModule>(),
      );
      expect(() => coordinator.getModule<FeatureModule>(), returnsNormally);
    });

    test('throws when a module type was never registered', () {
      final coordinator = ModularAppCoordinator(
        modules: (c) => [FeatureModule(c)],
      );

      expect(
        () => coordinator.getModule<AsyncFeatureModule>(),
        throwsA(isA<TypeError>()),
      );
    });

    test(
      'parses the first matching module and falls back to notFound',
      () async {
        final coordinator = ModularAppCoordinator(
          modules: (c) => [
            FeatureModule(c, prefix: 'auth'),
            AsyncFeatureModule(c, prefix: 'shop'),
          ],
        );

        expect(
          (await coordinator.parseRouteFromUri(Uri.parse('/auth/login')))?.id,
          'auth/login',
        );
        expect(
          (await coordinator.parseRouteFromUri(Uri.parse('/shop')))?.id,
          'shop',
        );
        expect(
          (await coordinator.parseRouteFromUri(Uri.parse('/missing')))?.id,
          'not-found',
        );
      },
    );

    test('aggregates module paths and disposes nested coordinators', () {
      late NestedCoordinator nested;
      final coordinator = ModularAppCoordinator(
        modules: (c) {
          nested = NestedCoordinator(
            c,
            childModules: [FeatureModule(c, prefix: 'leaf', hasPath: true)],
          );
          return [nested, FeatureModule(c, prefix: 'shop', hasPath: true)];
        },
      );

      expect(coordinator.paths, contains(coordinator.root));
      expect(coordinator.paths, contains(nested.extra));
      expect(
        coordinator.paths.any((path) => path.debugLabel == 'shop'),
        isTrue,
      );
      expect(coordinator.getModule<FeatureModule>(), isA<FeatureModule>());

      coordinator.dispose();
      expect(coordinator.listeners, isEmpty);
    });

    test('composes local and module fragments, including nested modulars', () {
      final coordinator = ModularAppCoordinator(
        manifestName: 'app',
        localFragment: RouteManifestFragment<_AppId>(
          name: 'local',
          idCodec: RouteIdCodec.enumValues(_AppId.values),
          routes: [RouteManifestRoute(id: _AppId.home, path: '/')],
        ),
        modules: (c) => [
          NestedCoordinator(
            c,
            childModules: [
              FeatureModule(
                c,
                prefix: 'auth',
                fragment: RouteManifestFragment<_AuthId>(
                  name: 'auth',
                  idCodec: RouteIdCodec.enumValues(_AuthId.values),
                  routes: [
                    RouteManifestRoute(id: _AuthId.login, path: '/auth/login'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );

      expect(coordinator.routeManifestName, 'app');
      expect(coordinator.routeManifest.match(Uri.parse('/'))?.id, _AppId.home);
      expect(
        coordinator.routeManifest.match(Uri.parse('/auth/login'))?.id,
        _AuthId.login,
      );
    });

    test('skips empty fragments when composing', () {
      final coordinator = ModularAppCoordinator(
        modules: (c) => [FeatureModule(c)],
      );

      expect(coordinator.routeManifest.nodes, isEmpty);
      expect(coordinator.localRouteManifestFragment.isEmpty, isTrue);
    });

    test(
      'forwards deprecated defineLayout/defineConverter to leaf modules',
      () {
        final coordinator = ModularAppCoordinator(
          modules: (c) => [FeatureModule(c)],
        );
        final module = coordinator.getModule<FeatureModule>();

        coordinator.defineLayout();
        coordinator.defineConverter();

        expect(module.layoutCalls, greaterThan(0));
        expect(module.converterCalls, greaterThan(0));
      },
    );

    test('nested modular parse returns null so the root can 404', () async {
      late NestedCoordinator nested;
      final coordinator = ModularAppCoordinator(
        modules: (c) {
          nested = NestedCoordinator(c);
          return [nested];
        },
      );

      expect(await nested.parseRouteFromUri(Uri.parse('/missing')), isNull);
      expect(
        (await coordinator.parseRouteFromUri(Uri.parse('/missing')))?.id,
        'not-found',
      );
    });
  });
}
