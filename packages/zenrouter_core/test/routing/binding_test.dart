import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

enum _ShellId { home }

enum _AccountId { profile }

final class _TestRoute extends RouteUri {
  _TestRoute(this.name, this.uri);

  final String name;
  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  List<Object?> get props => [name, uri];
}

void main() {
  group('RouteManifestBinding', () {
    test('infers the registry ID type from the manifest', () {
      final manifest = RouteManifest<_ShellId>(
        name: 'typed-app',
        routes: [RouteManifestRoute(id: _ShellId.home, path: '/')],
      );

      final RouteBindingRegistry<_ShellId, _TestRoute> registry = manifest
          .bind<_TestRoute>(
            bindings: [
              RouteBinding(
                id: _ShellId.home,
                create: (match) => _TestRoute('home', match.uri),
              ),
            ],
          );

      expect((registry.resolve(Uri.parse('/')) as _TestRoute).name, 'home');
      expect(registry[_ShellId.home]?.id, _ShellId.home);
    });

    test('forwards the optional not-found binding', () async {
      final manifest = RouteManifest<_ShellId>(
        name: 'typed-app',
        routes: [RouteManifestRoute(id: _ShellId.home, path: '/')],
      );
      final registry = manifest.bind<_TestRoute>(
        bindings: [
          RouteBinding(
            id: _ShellId.home,
            create: (match) => _TestRoute('home', match.uri),
          ),
        ],
        notFound: (uri) => _TestRoute('not-found', uri),
      );

      expect(
        (await registry.resolve(Uri.parse('/missing')))?.name,
        'not-found',
      );
    });
  });

  group('RouteBindingRegistry', () {
    late RouteManifest<Object> manifest;

    setUp(() {
      manifest = RouteManifest<Object>.fromFragments(
        name: 'app',
        fragments: [
          RouteManifestFragment<_ShellId>(
            name: 'shell',
            routes: [RouteManifestRoute(id: _ShellId.home, path: '/')],
          ),
          RouteManifestFragment<_AccountId>(
            name: 'account',
            routes: [
              RouteManifestRoute(
                id: _AccountId.profile,
                path: '/profiles/:profileId',
              ),
            ],
          ),
        ],
      );
    });

    test('resolves heterogeneous typed bindings through one Object graph', () {
      final registry = RouteBindingRegistry<Object, _TestRoute>(
        manifest: manifest,
        bindings: <RouteBinding<Object, _TestRoute>>[
          RouteBinding<_ShellId, _TestRoute>(
            id: _ShellId.home,
            create: (match) => _TestRoute('home', match.uri),
          ),
          RouteBinding<_AccountId, _TestRoute>(
            id: _AccountId.profile,
            create: (match) =>
                _TestRoute(match.pathParameters['profileId']!, match.uri),
          ),
        ],
      );

      expect((registry.resolve(Uri.parse('/')) as _TestRoute).name, 'home');
      expect(
        (registry.resolve(Uri.parse('/profiles/core')) as _TestRoute).name,
        'core',
      );
      expect(registry[_AccountId.profile]?.id, _AccountId.profile);
    });

    test('supports asynchronous factories', () async {
      final registry = RouteBindingRegistry<Object, _TestRoute>(
        manifest: manifest,
        bindings: [
          RouteBinding(
            id: _ShellId.home,
            create: (match) async => _TestRoute('home', match.uri),
          ),
          RouteBinding(
            id: _AccountId.profile,
            create: (match) => _TestRoute('profile', match.uri),
          ),
        ],
      );

      expect((await registry.resolve(Uri.parse('/')))?.name, 'home');
    });

    test('loads a deferred library before creating its route', () async {
      final loadGate = Completer<void>();
      final events = <String>[];
      final registry = RouteBindingRegistry<Object, _TestRoute>(
        manifest: manifest,
        bindings: [
          RouteBinding.deferred(
            id: _ShellId.home,
            loadLibrary: () async {
              events.add('load');
              await loadGate.future;
            },
            create: (match) {
              events.add('create');
              return _TestRoute('home', match.uri);
            },
          ),
          RouteBinding(
            id: _AccountId.profile,
            create: (match) => _TestRoute('profile', match.uri),
          ),
        ],
      );

      final resolution = registry.resolve(Uri.parse('/'));
      await pumpEventQueue();
      expect(events, ['load']);

      loadGate.complete();
      expect((await resolution)?.name, 'home');
      expect(events, ['load', 'create']);
    });

    test('uses an optional not-found binding', () async {
      final registry = RouteBindingRegistry<Object, _TestRoute>(
        manifest: manifest,
        bindings: [
          RouteBinding(
            id: _ShellId.home,
            create: (match) => _TestRoute('home', match.uri),
          ),
          RouteBinding(
            id: _AccountId.profile,
            create: (match) => _TestRoute('profile', match.uri),
          ),
        ],
        notFound: (uri) => _TestRoute('not-found', uri),
      );

      expect(
        (await registry.resolve(Uri.parse('/missing')))?.name,
        'not-found',
      );
    });

    test('returns null for an unmatched URI without a not-found binding', () {
      final registry = RouteBindingRegistry<Object, _TestRoute>(
        manifest: manifest,
        bindings: [
          RouteBinding(
            id: _ShellId.home,
            create: (match) => _TestRoute('home', match.uri),
          ),
          RouteBinding(
            id: _AccountId.profile,
            create: (match) => _TestRoute('profile', match.uri),
          ),
        ],
      );

      expect(registry.resolve(Uri.parse('/missing')), isNull);
    });

    test('snapshots the binding list', () {
      final bindings = <RouteBinding<Object, _TestRoute>>[
        RouteBinding(
          id: _ShellId.home,
          create: (match) => _TestRoute('home', match.uri),
        ),
        RouteBinding(
          id: _AccountId.profile,
          create: (match) => _TestRoute('profile', match.uri),
        ),
      ];
      final registry = RouteBindingRegistry<Object, _TestRoute>(
        manifest: manifest,
        bindings: bindings,
      );
      bindings.clear();

      expect(registry.bindings.length, 2);
      expect(
        () => registry.bindings.add(registry.bindings.first),
        throwsUnsupportedError,
      );
    });
  });

  group('RouteBindingRegistry validation', () {
    late RouteManifest<String> manifest;

    setUp(() {
      manifest = RouteManifest(
        name: 'validation',
        routes: [
          RouteManifestRoute(id: 'home', path: '/'),
          RouteManifestRoute(id: 'profile', path: '/profile'),
        ],
        layouts: [RouteManifestLayout.stack(id: 'shell', path: '/')],
      );
    });

    RouteBinding<String, _TestRoute> binding(String id) =>
        RouteBinding(id: id, create: (match) => _TestRoute(id, match.uri));

    test('rejects duplicate binding IDs', () {
      expect(
        () => RouteBindingRegistry(
          manifest: manifest,
          bindings: [binding('home'), binding('home')],
        ),
        throwsA(isA<RouteBindingValidationException<String>>()),
      );
    });

    test('rejects unknown and layout IDs', () {
      expect(
        () => RouteBindingRegistry(
          manifest: manifest,
          bindings: [binding('home'), binding('profile'), binding('unknown')],
        ),
        throwsA(isA<RouteBindingValidationException<String>>()),
      );
      expect(
        () => RouteBindingRegistry(
          manifest: manifest,
          bindings: [binding('home'), binding('profile'), binding('shell')],
        ),
        throwsA(isA<RouteBindingValidationException<String>>()),
      );
    });

    test('rejects incomplete registries', () {
      expect(
        () => RouteBindingRegistry(
          manifest: manifest,
          bindings: [binding('home')],
        ),
        throwsA(
          isA<RouteBindingValidationException<String>>().having(
            (error) => error.routeIds,
            'routeIds',
            ['profile'],
          ),
        ),
      );
    });
  });
}
