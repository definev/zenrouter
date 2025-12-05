import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_generator/src/annotations.dart';
import 'package:zenrouter_file_generator/src/analyzer/path_parser.dart';
import 'package:zenrouter_file_generator/src/generators/coordinator_generator.dart';

void main() {
  group('CoordinatorGenerator', () {
    late CoordinatorGenerator generator;

    setUp(() {
      generator = CoordinatorGenerator();
    });

    group('buildExtensions', () {
      test('outputs to routes/routes.zen.dart', () {
        expect(generator.buildExtensions, {
          r'$lib$': ['routes/routes.zen.dart'],
        });
      });
    });
  });

  group('RouteInfo', () {
    group('hasQueries', () {
      test('returns false when queries is null', () {
        final route = RouteInfo(
          className: 'HomeRoute',
          pathSegments: [],
          parameters: [],
          queries: null,
        );

        expect(route.hasQueries, false);
      });

      test('returns false when queries is empty', () {
        final route = RouteInfo(
          className: 'HomeRoute',
          pathSegments: [],
          parameters: [],
          queries: [],
        );

        expect(route.hasQueries, false);
      });

      test('returns true when queries has values', () {
        final route = RouteInfo(
          className: 'SearchRoute',
          pathSegments: ['search'],
          parameters: [],
          queries: ['q', 'page'],
        );

        expect(route.hasQueries, true);
      });
    });

    test('stores all route properties', () {
      final params = [ParamInfo(name: 'userId')];
      final route = RouteInfo(
        className: 'UserRoute',
        pathSegments: ['users', ':userId'],
        parameters: params,
        hasGuard: true,
        hasRedirect: true,
        deepLinkStrategy: DeeplinkStrategyType.push,
        hasTransition: true,
        isIndexFile: false,
        originalFileName: '[userId]',
        queries: ['tab'],
        parentLayoutType: 'UsersLayout',
        filePath: 'lib/routes/users/[userId].dart',
      );

      expect(route.className, 'UserRoute');
      expect(route.pathSegments, ['users', ':userId']);
      expect(route.parameters, params);
      expect(route.hasGuard, true);
      expect(route.hasRedirect, true);
      expect(route.deepLinkStrategy, DeeplinkStrategyType.push);
      expect(route.hasTransition, true);
      expect(route.isIndexFile, false);
      expect(route.originalFileName, '[userId]');
      expect(route.queries, ['tab']);
      expect(route.parentLayoutType, 'UsersLayout');
      expect(route.filePath, 'lib/routes/users/[userId].dart');
    });

    test('allows mutable parentLayoutType', () {
      final route = RouteInfo(
        className: 'HomeRoute',
        pathSegments: [],
        parameters: [],
      );

      expect(route.parentLayoutType, null);
      route.parentLayoutType = 'MainLayout';
      expect(route.parentLayoutType, 'MainLayout');
    });
  });

  group('LayoutInfo', () {
    test('stores all layout properties', () {
      final layout = LayoutInfo(
        className: 'TabsLayout',
        pathSegments: ['tabs'],
        layoutType: LayoutType.indexed,
        indexedRouteTypes: ['HomeRoute', 'ProfileRoute', 'SettingsRoute'],
        parentLayoutType: 'RootLayout',
      );

      expect(layout.className, 'TabsLayout');
      expect(layout.pathSegments, ['tabs']);
      expect(layout.layoutType, LayoutType.indexed);
      expect(layout.indexedRouteTypes, [
        'HomeRoute',
        'ProfileRoute',
        'SettingsRoute',
      ]);
      expect(layout.parentLayoutType, 'RootLayout');
    });

    test('defaults indexedRouteTypes to empty', () {
      final layout = LayoutInfo(
        className: 'StackLayout',
        pathSegments: ['stack'],
        layoutType: LayoutType.stack,
      );

      expect(layout.indexedRouteTypes, isEmpty);
    });

    test('allows mutable parentLayoutType', () {
      final layout = LayoutInfo(
        className: 'ChildLayout',
        pathSegments: ['child'],
        layoutType: LayoutType.stack,
      );

      expect(layout.parentLayoutType, null);
      layout.parentLayoutType = 'ParentLayout';
      expect(layout.parentLayoutType, 'ParentLayout');
    });
  });

  group('RouteTreeInfo', () {
    test('stores routes and layouts', () {
      final routes = [
        RouteInfo(className: 'HomeRoute', pathSegments: [], parameters: []),
      ];

      final layouts = [
        LayoutInfo(
          className: 'MainLayout',
          pathSegments: [],
          layoutType: LayoutType.stack,
        ),
      ];

      final tree = RouteTreeInfo(routes: routes, layouts: layouts);

      expect(tree.routes, routes);
      expect(tree.layouts, layouts);
    });
  });

  group('ParamInfo', () {
    test('stores parameter name', () {
      final param = ParamInfo(name: 'userId');

      expect(param.name, 'userId');
    });
  });
}
