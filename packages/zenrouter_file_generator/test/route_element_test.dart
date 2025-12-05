import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_generator/src/analyzer/route_element.dart';
import 'package:zenrouter_file_generator/src/annotations.dart';

void main() {
  group('RouteElement', () {
    group('uriPattern', () {
      test('returns / for empty path segments', () {
        final route = RouteElement(
          className: 'HomeRoute',
          relativePath: 'index',
          pathSegments: [],
          parameters: [],
        );

        expect(route.uriPattern, '/');
      });

      test('returns correct pattern for static segments', () {
        final route = RouteElement(
          className: 'AboutRoute',
          relativePath: 'about',
          pathSegments: ['about'],
          parameters: [],
        );

        expect(route.uriPattern, '/about');
      });

      test('returns correct pattern for nested static segments', () {
        final route = RouteElement(
          className: 'ProfileSettingsRoute',
          relativePath: 'profile/settings',
          pathSegments: ['profile', 'settings'],
          parameters: [],
        );

        expect(route.uriPattern, '/profile/settings');
      });

      test('returns correct pattern with dynamic segments', () {
        final route = RouteElement(
          className: 'ProfileIdRoute',
          relativePath: 'profile/[id]',
          pathSegments: ['profile', ':id'],
          parameters: [RouteParameter(name: 'id')],
        );

        expect(route.uriPattern, '/profile/:id');
      });

      test('returns correct pattern with multiple dynamic segments', () {
        final route = RouteElement(
          className: 'CollectionItemRoute',
          relativePath: 'profile/[profileId]/collections/[collectionId]',
          pathSegments: [
            'profile',
            ':profileId',
            'collections',
            ':collectionId',
          ],
          parameters: [
            RouteParameter(name: 'profileId'),
            RouteParameter(name: 'collectionId'),
          ],
        );

        expect(
          route.uriPattern,
          '/profile/:profileId/collections/:collectionId',
        );
      });
    });

    group('generatedBaseClassName', () {
      test('returns prefixed class name', () {
        final route = RouteElement(
          className: 'AboutRoute',
          relativePath: 'about',
          pathSegments: ['about'],
          parameters: [],
        );

        expect(route.generatedBaseClassName, r'_$AboutRoute');
      });
    });

    group('hasDynamicParameters', () {
      test('returns false when no parameters', () {
        final route = RouteElement(
          className: 'AboutRoute',
          relativePath: 'about',
          pathSegments: ['about'],
          parameters: [],
        );

        expect(route.hasDynamicParameters, false);
      });

      test('returns true when has parameters', () {
        final route = RouteElement(
          className: 'ProfileIdRoute',
          relativePath: 'profile/[id]',
          pathSegments: ['profile', ':id'],
          parameters: [RouteParameter(name: 'id')],
        );

        expect(route.hasDynamicParameters, true);
      });
    });

    group('hasQueries', () {
      test('returns false when queries is null', () {
        final route = RouteElement(
          className: 'AboutRoute',
          relativePath: 'about',
          pathSegments: ['about'],
          parameters: [],
          queries: null,
        );

        expect(route.hasQueries, false);
      });

      test('returns false when queries is empty', () {
        final route = RouteElement(
          className: 'AboutRoute',
          relativePath: 'about',
          pathSegments: ['about'],
          parameters: [],
          queries: [],
        );

        expect(route.hasQueries, false);
      });

      test('returns true when queries has values', () {
        final route = RouteElement(
          className: 'SearchRoute',
          relativePath: 'search',
          pathSegments: ['search'],
          parameters: [],
          queries: ['query', 'page'],
        );

        expect(route.hasQueries, true);
      });
    });

    group('copyWith', () {
      test('copies with new parentLayoutType', () {
        final route = RouteElement(
          className: 'AboutRoute',
          relativePath: 'about',
          pathSegments: ['about'],
          parameters: [],
          parentLayoutType: null,
        );

        final copied = route.copyWith(parentLayoutType: 'MainLayout');

        expect(copied.className, 'AboutRoute');
        expect(copied.relativePath, 'about');
        expect(copied.parentLayoutType, 'MainLayout');
      });

      test('preserves other properties when copying', () {
        final route = RouteElement(
          className: 'SearchRoute',
          relativePath: 'search',
          pathSegments: ['search'],
          parameters: [RouteParameter(name: 'id')],
          hasGuard: true,
          hasRedirect: true,
          deepLinkStrategy: DeeplinkStrategyType.push,
          hasTransition: true,
          queries: ['q'],
        );

        final copied = route.copyWith(parentLayoutType: 'MainLayout');

        expect(copied.hasGuard, true);
        expect(copied.hasRedirect, true);
        expect(copied.deepLinkStrategy, DeeplinkStrategyType.push);
        expect(copied.hasTransition, true);
        expect(copied.queries, ['q']);
        expect(copied.parameters.length, 1);
      });
    });

    group('mixins and features', () {
      test('stores guard configuration', () {
        final route = RouteElement(
          className: 'CheckoutRoute',
          relativePath: 'checkout',
          pathSegments: ['checkout'],
          parameters: [],
          hasGuard: true,
        );

        expect(route.hasGuard, true);
      });

      test('stores redirect configuration', () {
        final route = RouteElement(
          className: 'DashboardRoute',
          relativePath: 'dashboard',
          pathSegments: ['dashboard'],
          parameters: [],
          hasRedirect: true,
        );

        expect(route.hasRedirect, true);
      });

      test('stores deepLink strategy', () {
        final route = RouteElement(
          className: 'ProductRoute',
          relativePath: 'product/[id]',
          pathSegments: ['product', ':id'],
          parameters: [RouteParameter(name: 'id')],
          deepLinkStrategy: DeeplinkStrategyType.custom,
        );

        expect(route.deepLinkStrategy, DeeplinkStrategyType.custom);
      });

      test('stores transition configuration', () {
        final route = RouteElement(
          className: 'ModalRoute',
          relativePath: 'modal',
          pathSegments: ['modal'],
          parameters: [],
          hasTransition: true,
        );

        expect(route.hasTransition, true);
      });
    });
  });

  group('RouteParameter', () {
    test('creates with required name', () {
      final param = RouteParameter(name: 'userId');

      expect(param.name, 'userId');
      expect(param.type, 'String');
      expect(param.isOptional, false);
      expect(param.defaultValue, null);
    });

    test('creates with custom type', () {
      final param = RouteParameter(name: 'count', type: 'int');

      expect(param.name, 'count');
      expect(param.type, 'int');
    });

    test('creates optional parameter with default', () {
      final param = RouteParameter(
        name: 'page',
        isOptional: true,
        defaultValue: '1',
      );

      expect(param.name, 'page');
      expect(param.isOptional, true);
      expect(param.defaultValue, '1');
    });
  });
}
