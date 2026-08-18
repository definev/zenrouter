// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class HydrationRoute extends RouteUri {
  HydrationRoute(this.uri);

  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  List<Object?> get props => [uri];
}

void main() {
  group('RouteHydrationPayload', () {
    test('round-trips a versioned JSON payload', () {
      final payload = RouteHydrationPayload(
        routeUri: Uri.parse('/products/42?tab=details'),
        data: {
          'product': {'id': 42, 'name': 'Router'},
          'permissions': ['read', 'share'],
          'cached': true,
        },
      );

      final decoded = RouteHydrationPayload.decode(payload.encode());

      expect(decoded.version, RouteHydrationPayload.currentVersion);
      expect(decoded.routeUri, payload.routeUri);
      expect(decoded.toJson(), payload.toJson());
    });

    test('deep-freezes source collections', () {
      final permissions = <Object?>['read'];
      final source = <String, Object?>{'permissions': permissions};
      final payload = RouteHydrationPayload(
        routeUri: Uri.parse('/account'),
        data: source,
      );

      permissions.add('write');
      source['other'] = true;

      final data = payload.data! as Map<String, Object?>;
      expect(data, {
        'permissions': ['read'],
      });
      expect(() => data['other'] = true, throwsUnsupportedError);
      expect(
        () => (data['permissions']! as List<Object?>).add('write'),
        throwsUnsupportedError,
      );
    });

    test('rejects values that JSON cannot represent safely', () {
      for (final value in [
        DateTime(2026),
        {1, 2},
        double.nan,
        double.infinity,
        <Object, Object?>{1: 'non-string key'},
      ]) {
        expect(
          () => RouteHydrationPayload(
            routeUri: Uri.parse('/invalid'),
            data: value,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects a non-positive version', () {
      expect(
        () => RouteHydrationPayload(routeUri: Uri.parse('/'), version: 0),
        throwsArgumentError,
      );
    });

    test('describes an unsupported version', () {
      const error = UnsupportedHydrationVersion(
        version: 9,
        supportedVersion: 1,
      );
      expect(
        error.toString(),
        'Unsupported hydration version 9; supported version is 1',
      );
    });

    test('rejects unknown schemas and versions', () {
      expect(
        () => RouteHydrationPayload.fromJson(const {
          'schema': 'other',
          'version': 1,
          'route': '/',
          'data': null,
        }),
        throwsFormatException,
      );
      expect(
        () => RouteHydrationPayload.fromJson(const {
          'schema': RouteHydrationPayload.schema,
          'version': 2,
          'route': '/',
          'data': null,
        }),
        throwsA(isA<UnsupportedHydrationVersion>()),
      );
    });

    test('decode requires a JSON object', () {
      expect(
        () => RouteHydrationPayload.decode('[1, 2, 3]'),
        throwsFormatException,
      );
    });
  });

  group('RouteResolution hydration', () {
    test('carries an explicit payload', () {
      final request = RouteRequest.navigation(Uri.parse('/product/42'));
      final payload = RouteHydrationPayload(
        routeUri: request.uri,
        data: const {'id': 42},
      );
      final resolution = MatchedRouteResolution<HydrationRoute>(
        request: request,
        route: HydrationRoute(request.uri),
        hydration: payload,
      );

      expect(resolution.hydration, same(payload));
      expect(resolution.hydration!.data, const {'id': 42});
    });
  });
}
