import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

enum _TypedRouteId { root, profile }

void main() {
  group('RoutePattern', () {
    test('parses literal, parameter, and middle rest segments', () {
      final pattern = RoutePattern('/docs/...:slugs/:page');

      expect(pattern.staticSegmentCount, 1);
      expect(pattern.dynamicSegmentCount, 1);
      expect(pattern.hasRestParameter, true);
      expect(pattern.minimumSegmentCount, 2);
      expect(pattern.segments.map((segment) => segment.kind), [
        RoutePatternSegmentKind.literal,
        RoutePatternSegmentKind.rest,
        RoutePatternSegmentKind.parameter,
      ]);
    });

    test('rejects malformed and duplicate parameters', () {
      expect(() => RoutePattern('relative'), throwsArgumentError);
      expect(() => RoutePattern('/users/'), throwsArgumentError);
      expect(() => RoutePattern('/users/:1id'), throwsArgumentError);
      expect(() => RoutePattern('/:id/posts/:id'), throwsArgumentError);
      expect(() => RoutePattern('/...:left/...:right'), throwsArgumentError);
    });
  });

  group('RouteManifest matching', () {
    late RouteManifest<String> manifest;

    setUp(() {
      manifest = RouteManifest(
        name: 'app',
        routes: [
          RouteManifestRoute(id: 'root', path: '/'),
          RouteManifestRoute(id: 'new-user', path: '/users/new'),
          RouteManifestRoute(id: 'user', path: '/users/:userId'),
          RouteManifestRoute(id: 'docs', path: '/docs/...:slugs/:pageId'),
        ],
      );
    });

    test('matches root and prefers static routes', () {
      expect(manifest.match(Uri.parse('/'))?.route.id, 'root');
      expect(manifest.match(Uri.parse('/users/new'))?.route.id, 'new-user');

      final match = manifest.match(Uri.parse('/users/42?tab=posts'))!;
      expect(match.route.id, 'user');
      expect(match.pathParameters, {'userId': '42'});
      expect(match.uri.queryParameters, {'tab': 'posts'});
    });

    test('matches a rest parameter before a suffix', () {
      final match = manifest.match(Uri.parse('/docs/guides/web/start'))!;

      expect(match.route.id, 'docs');
      expect(match.pathParameters, {'pageId': 'start'});
      expect(match.restParameters, {
        'slugs': ['guides', 'web'],
      });
    });

    test('returns null for an unknown URI', () {
      expect(manifest.match(Uri.parse('/unknown/path')), isNull);
    });

    test('match results are immutable', () {
      final match = manifest.match(Uri.parse('/users/42'))!;

      expect(
        () => match.pathParameters['userId'] = '43',
        throwsUnsupportedError,
      );
    });
  });

  group('RouteManifest reverse routing', () {
    final manifest = RouteManifest(
      name: 'app',
      routes: [
        RouteManifestRoute(id: 'root', path: '/'),
        RouteManifestRoute(id: 'doc', path: '/teams/:teamId/docs/...:slugs'),
      ],
    );

    test('builds root URI with query and fragment', () {
      expect(
        manifest.location(
          'root',
          queryParameters: {'search': 'zen router'},
          fragment: 'top',
        ),
        Uri.parse('/?search=zen+router#top'),
      );
    });

    test('builds encoded URI from typed parameter maps', () {
      expect(
        manifest.location(
          'doc',
          pathParameters: {'teamId': 'core team'},
          restParameters: {
            'slugs': ['routing', 'SSR & SPA'],
          },
        ),
        Uri.parse('/teams/core%20team/docs/routing/SSR%20&%20SPA'),
      );
    });

    test('rejects missing and unexpected parameters', () {
      expect(() => manifest.location('doc'), throwsArgumentError);
      expect(
        () => manifest.location('root', pathParameters: {'unused': 'value'}),
        throwsArgumentError,
      );
      expect(() => manifest.location('unknown'), throwsArgumentError);
    });

    test('treats percent signs in static patterns as literal data', () {
      final percentManifest = RouteManifest(
        name: 'percent',
        routes: [RouteManifestRoute(id: 'discount', path: '/discount/100%')],
      );

      final location = percentManifest.location('discount');
      expect(location, Uri.parse('/discount/100%25'));
      expect(percentManifest.match(location)?.route.id, 'discount');
    });
  });

  group('RouteManifest validation', () {
    test('rejects IDs shared by routes and layouts', () {
      expect(
        () => RouteManifest(
          name: 'app',
          routes: [RouteManifestRoute(id: 'shell', path: '/')],
          layouts: [
            RouteManifestLayout(
              id: 'shell',
              path: '/',
              kind: RouteManifestLayoutKind.stack,
            ),
          ],
        ),
        throwsA(isA<RouteManifestValidationException>()),
      );
    });

    test('rejects equivalent dynamic patterns', () {
      expect(
        () => RouteManifest(
          name: 'app',
          routes: [
            RouteManifestRoute(id: 'by-id', path: '/users/:id'),
            RouteManifestRoute(id: 'by-name', path: '/users/:name'),
          ],
        ),
        throwsA(isA<RouteManifestValidationException>()),
      );
    });

    test('rejects overlapping patterns with equal specificity', () {
      expect(
        () => RouteManifest(
          name: 'app',
          routes: [
            RouteManifestRoute(id: 'left', path: '/:scope/settings'),
            RouteManifestRoute(id: 'right', path: '/admin/:section'),
          ],
        ),
        throwsA(isA<RouteManifestValidationException>()),
      );
    });

    test(
      'allows static and dynamic patterns with deterministic precedence',
      () {
        final manifest = RouteManifest(
          name: 'app',
          routes: [
            RouteManifestRoute(id: 'dynamic', path: '/users/:id'),
            RouteManifestRoute(id: 'static', path: '/users/settings'),
          ],
        );

        expect(
          manifest.match(Uri.parse('/users/settings'))?.route.id,
          'static',
        );
      },
    );

    test('rejects unknown parents and layout cycles', () {
      expect(
        () => RouteManifest(
          name: 'app',
          routes: [
            RouteManifestRoute(id: 'home', path: '/', parentId: 'missing'),
          ],
        ),
        throwsA(isA<RouteManifestValidationException>()),
      );

      expect(
        () => RouteManifest(
          name: 'app',
          layouts: [
            RouteManifestLayout(
              id: 'left',
              path: '/left',
              parentId: 'right',
              kind: RouteManifestLayoutKind.stack,
            ),
            RouteManifestLayout(
              id: 'right',
              path: '/right',
              parentId: 'left',
              kind: RouteManifestLayoutKind.stack,
            ),
          ],
        ),
        throwsA(isA<RouteManifestValidationException>()),
      );
    });

    test('validates indexed children and freezes all collections', () {
      final queryParameters = <String>['tab'];
      final indexedChildren = <String>['home'];
      final route = RouteManifestRoute(
        id: 'home',
        path: '/',
        parentId: 'tabs',
        queryParameters: queryParameters,
      );
      final layout = RouteManifestLayout(
        id: 'tabs',
        path: '/',
        kind: RouteManifestLayoutKind.indexed,
        indexedChildIds: indexedChildren,
      );
      final manifest = RouteManifest(
        name: 'app',
        routes: [route],
        layouts: [layout],
      );
      queryParameters.add('changed');
      indexedChildren.add('changed');

      expect(route.queryParameters, ['tab']);
      expect(layout.indexedChildIds, ['home']);
      expect(() => manifest.routes.add(route), throwsUnsupportedError);
      expect(() => manifest.nodes['other'] = route, throwsUnsupportedError);
    });
  });

  group('RouteManifest serialization and composition', () {
    RouteManifest<String> createManifest() => RouteManifest<String>(
      name: 'account',
      routes: [
        RouteManifestRoute(
          id: 'profile',
          path: '/profiles/:id',
          parentId: 'account-layout',
          queryParameters: ['tab'],
          hasGuard: true,
          hasRedirect: true,
          isDeferred: true,
          deepLinkStrategy: DeeplinkStrategy.navigate,
        ),
      ],
      layouts: [
        RouteManifestLayout(
          id: 'account-layout',
          path: '/profiles',
          kind: RouteManifestLayoutKind.stack,
        ),
      ],
    );

    test('round-trips through versioned JSON', () {
      final encoded = createManifest().encode();
      final decoded = RouteManifest<String>.decode(encoded);

      expect(decoded.toJson(), createManifest().toJson());
      expect(decoded.match(Uri.parse('/profiles/42'))?.route.id, 'profile');
    });

    test('rejects unknown schema and version', () {
      final json = createManifest().toJson();
      expect(
        () => RouteManifest<String>.fromJson({...json, 'schema': 'other'}),
        throwsFormatException,
      );
      expect(
        () => RouteManifest<String>.fromJson({...json, 'version': 2}),
        throwsA(isA<UnsupportedRouteManifestVersion>()),
      );
    });

    test('composes independently declared manifests', () {
      final root = RouteManifest(
        name: 'root',
        routes: [RouteManifestRoute(id: 'root-home', path: '/')],
      );
      final feature = RouteManifest(
        name: 'feature',
        routes: [
          RouteManifestRoute(
            id: 'feature-home',
            path: '/feature',
            parentId: 'feature-shell',
          ),
        ],
        layouts: [
          RouteManifestLayout(
            id: 'feature-shell',
            path: '/feature',
            kind: RouteManifestLayoutKind.stack,
          ),
        ],
      );

      final composed = RouteManifest.compose(
        name: 'app',
        manifests: [root, feature],
      );

      expect(composed.match(Uri.parse('/feature'))?.route.id, 'feature-home');
      expect(composed['feature-shell'], isA<RouteManifestLayout<String>>());
    });
  });

  group('typed route IDs', () {
    final idCodec = RouteIdCodec.enumValues(_TypedRouteId.values);
    late RouteManifest<_TypedRouteId> manifest;

    setUp(() {
      manifest = RouteManifest<_TypedRouteId>(
        name: 'typed',
        idCodec: idCodec,
        routes: [
          RouteManifestRoute(id: _TypedRouteId.root, path: '/'),
          RouteManifestRoute(
            id: _TypedRouteId.profile,
            path: '/profiles/:profileId',
          ),
        ],
      );
    });

    test('supports enum lookup, reverse routing, and object patterns', () {
      final location = manifest.location(
        _TypedRouteId.profile,
        pathParameters: {'profileId': 'core team'},
      );

      final profileId = switch (manifest.match(location)) {
        RouteManifestMatch(
          id: _TypedRouteId.profile,
          pathParameters: {'profileId': final profileId},
        ) =>
          profileId,
        _ => fail('Expected a typed profile match'),
      };

      expect(location, Uri.parse('/profiles/core%20team'));
      expect(profileId, 'core team');
      expect(manifest[_TypedRouteId.profile], isA<RouteManifestRoute>());
    });

    test('round-trips enum IDs through an explicit wire codec', () {
      final decoded = RouteManifest<_TypedRouteId>.decode(
        manifest.encode(),
        idCodec: idCodec,
      );

      expect(decoded.toJson(), manifest.toJson());
      expect(decoded.match(Uri.parse('/'))?.id, _TypedRouteId.root);
    });

    test('only requires a codec when crossing the serialization seam', () {
      final inMemoryOnly = RouteManifest<_TypedRouteId>(
        name: 'in-memory',
        routes: [RouteManifestRoute(id: _TypedRouteId.root, path: '/')],
      );

      expect(inMemoryOnly.match(Uri.parse('/'))?.id, _TypedRouteId.root);
      expect(inMemoryOnly.encode, throwsStateError);
    });

    test('rejects codecs that collapse distinct typed IDs', () {
      final invalidCodec = RouteIdCodec<_TypedRouteId>(
        encode: (_) => 'same',
        decode: (_) => _TypedRouteId.root,
      );

      expect(() => manifest.toJson(idCodec: invalidCodec), throwsStateError);
    });
  });
}
