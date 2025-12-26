import 'package:flutter_test/flutter_test.dart';

import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

void main() {
  group('RouteTree', () {
    group('build', () {
      test('builds tree with resolved route layouts', () {
        final routes = [
          RouteElement(
            className: 'HomeRoute',
            relativePath: 'index',
            pathSegments: [],
            parameters: [],
          ),
          RouteElement(
            className: 'SettingsIndexRoute',
            relativePath: 'settings/index',
            pathSegments: ['settings'],
            parameters: [],
          ),
          RouteElement(
            className: 'ProfileRoute',
            relativePath: 'settings/profile',
            pathSegments: ['settings', 'profile'],
            parameters: [],
          ),
        ];

        final layouts = [
          LayoutElement(
            className: 'SettingsLayout',
            relativePath: 'settings/_layout',
            pathSegments: ['settings'],
            layoutType: LayoutType.stack,
          ),
        ];

        final tree = RouteTree.build(routes: routes, layouts: layouts);

        // HomeRoute should not have a parent layout
        final homeRoute = tree.routes.firstWhere(
          (r) => r.className == 'HomeRoute',
        );
        expect(homeRoute.parentLayoutType, null);

        // SettingsIndexRoute at the same level as layout doesn't get assigned
        // (prefix matching requires layout to be strictly shorter)
        final settingsRoute = tree.routes.firstWhere(
          (r) => r.className == 'SettingsIndexRoute',
        );
        expect(settingsRoute.parentLayoutType, null);

        // ProfileRoute is nested deeper than SettingsLayout, so it gets assigned
        final profileRoute = tree.routes.firstWhere(
          (r) => r.className == 'ProfileRoute',
        );
        expect(profileRoute.parentLayoutType, 'SettingsLayout');
      });

      test('builds tree with nested layout hierarchy', () {
        final routes = [
          RouteElement(
            className: 'DeepRoute',
            relativePath: 'level1/level2/deep',
            pathSegments: ['level1', 'level2', 'deep'],
            parameters: [],
          ),
        ];

        final layouts = [
          LayoutElement(
            className: 'Level1Layout',
            relativePath: 'level1/_layout',
            pathSegments: ['level1'],
            layoutType: LayoutType.stack,
          ),
          LayoutElement(
            className: 'Level2Layout',
            relativePath: 'level1/level2/_layout',
            pathSegments: ['level1', 'level2'],
            layoutType: LayoutType.stack,
          ),
        ];

        final tree = RouteTree.build(routes: routes, layouts: layouts);

        // DeepRoute should be under Level2Layout (closest match)
        final deepRoute = tree.routes.firstWhere(
          (r) => r.className == 'DeepRoute',
        );
        expect(deepRoute.parentLayoutType, 'Level2Layout');

        // Level2Layout should be under Level1Layout
        final level2Layout = tree.layouts.firstWhere(
          (l) => l.className == 'Level2Layout',
        );
        expect(level2Layout.parentLayoutType, 'Level1Layout');

        // Level1Layout should not have a parent
        final level1Layout = tree.layouts.firstWhere(
          (l) => l.className == 'Level1Layout',
        );
        expect(level1Layout.parentLayoutType, null);
      });

      test('handles routes with dynamic parameters', () {
        final routes = [
          RouteElement(
            className: 'UserRoute',
            relativePath: 'users/[userId]',
            pathSegments: ['users', ':userId'],
            parameters: [RouteParameter(name: 'userId')],
          ),
          RouteElement(
            className: 'UserPostRoute',
            relativePath: 'users/[userId]/posts/[postId]',
            pathSegments: ['users', ':userId', 'posts', ':postId'],
            parameters: [
              RouteParameter(name: 'userId'),
              RouteParameter(name: 'postId'),
            ],
          ),
        ];

        final layouts = [
          LayoutElement(
            className: 'UsersLayout',
            relativePath: 'users/_layout',
            pathSegments: ['users'],
            layoutType: LayoutType.stack,
          ),
        ];

        final tree = RouteTree.build(routes: routes, layouts: layouts);

        // Both routes should be under UsersLayout
        final userRoute = tree.routes.firstWhere(
          (r) => r.className == 'UserRoute',
        );
        expect(userRoute.parentLayoutType, 'UsersLayout');

        final userPostRoute = tree.routes.firstWhere(
          (r) => r.className == 'UserPostRoute',
        );
        expect(userPostRoute.parentLayoutType, 'UsersLayout');
      });

      test('uses default coordinator config when none provided', () {
        final tree = RouteTree.build(routes: [], layouts: []);

        expect(tree.config.name, 'AppCoordinator');
        expect(tree.config.routeBase, 'AppRoute');
      });

      test('uses custom coordinator config when provided', () {
        final config = CoordinatorConfig(
          name: 'CustomCoordinator',
          routeBase: 'CustomRoute',
        );

        final tree = RouteTree.build(routes: [], layouts: [], config: config);

        expect(tree.config.name, 'CustomCoordinator');
        expect(tree.config.routeBase, 'CustomRoute');
      });
    });

    group('routesForLayout', () {
      test('returns routes belonging to specific layout', () {
        final routes = [
          RouteElement(
            className: 'HomeRoute',
            relativePath: 'index',
            pathSegments: [],
            parameters: [],
            parentLayoutType: 'MainLayout',
          ),
          RouteElement(
            className: 'AboutRoute',
            relativePath: 'about',
            pathSegments: ['about'],
            parameters: [],
            parentLayoutType: 'MainLayout',
          ),
          RouteElement(
            className: 'SettingsRoute',
            relativePath: 'settings',
            pathSegments: ['settings'],
            parameters: [],
            parentLayoutType: 'SettingsLayout',
          ),
        ];

        final layouts = [
          LayoutElement(
            className: 'MainLayout',
            relativePath: '_layout',
            pathSegments: [],
            layoutType: LayoutType.stack,
          ),
        ];

        final tree = RouteTree(
          routes: routes,
          layouts: layouts,
          config: const CoordinatorConfig(),
        );

        final mainLayoutRoutes = tree.routesForLayout('MainLayout');
        expect(mainLayoutRoutes.length, 2);
        expect(
          mainLayoutRoutes.map((r) => r.className),
          containsAll(['HomeRoute', 'AboutRoute']),
        );
      });

      test('returns empty list for layout with no routes', () {
        final routes = <RouteElement>[];
        final layouts = [
          LayoutElement(
            className: 'EmptyLayout',
            relativePath: 'empty/_layout',
            pathSegments: ['empty'],
            layoutType: LayoutType.stack,
          ),
        ];

        final tree = RouteTree(
          routes: routes,
          layouts: layouts,
          config: const CoordinatorConfig(),
        );

        final emptyLayoutRoutes = tree.routesForLayout('EmptyLayout');
        expect(emptyLayoutRoutes, isEmpty);
      });
    });

    group('rootLayout', () {
      test('returns root layout when present', () {
        final layouts = [
          LayoutElement(
            className: 'RootLayout',
            relativePath: '_layout',
            pathSegments: [],
            layoutType: LayoutType.stack,
            parentLayoutType: null,
          ),
          LayoutElement(
            className: 'NestedLayout',
            relativePath: 'nested/_layout',
            pathSegments: ['nested'],
            layoutType: LayoutType.stack,
            parentLayoutType: 'RootLayout',
          ),
        ];

        final tree = RouteTree(
          routes: [],
          layouts: layouts,
          config: const CoordinatorConfig(),
        );

        expect(tree.rootLayout, isNotNull);
        expect(tree.rootLayout!.className, 'RootLayout');
      });

      test('returns null when no root layout exists', () {
        final layouts = [
          LayoutElement(
            className: 'NestedLayout',
            relativePath: 'nested/_layout',
            pathSegments: ['nested'],
            layoutType: LayoutType.stack,
          ),
        ];

        final tree = RouteTree(
          routes: [],
          layouts: layouts,
          config: const CoordinatorConfig(),
        );

        expect(tree.rootLayout, null);
      });
    });

    group('topLevelRoutes', () {
      test('returns routes without parent layout', () {
        final routes = [
          RouteElement(
            className: 'HomeRoute',
            relativePath: 'index',
            pathSegments: [],
            parameters: [],
            parentLayoutType: null,
          ),
          RouteElement(
            className: 'AboutRoute',
            relativePath: 'about',
            pathSegments: ['about'],
            parameters: [],
            parentLayoutType: null,
          ),
          RouteElement(
            className: 'SettingsRoute',
            relativePath: 'settings/profile',
            pathSegments: ['settings', 'profile'],
            parameters: [],
            parentLayoutType: 'SettingsLayout',
          ),
        ];

        final tree = RouteTree(
          routes: routes,
          layouts: [],
          config: const CoordinatorConfig(),
        );

        final topLevel = tree.topLevelRoutes;
        expect(topLevel.length, 2);
        expect(
          topLevel.map((r) => r.className),
          containsAll(['HomeRoute', 'AboutRoute']),
        );
      });
    });
  });

  group('RouteTreeNode', () {
    test('creates node with segment', () {
      final node = RouteTreeNode(segment: 'users');

      expect(node.segment, 'users');
      expect(node.isDynamic, false);
      expect(node.parameterName, null);
      expect(node.children, isEmpty);
    });

    test('creates dynamic node', () {
      final node = RouteTreeNode(
        segment: ':userId',
        isDynamic: true,
        parameterName: 'userId',
      );

      expect(node.segment, ':userId');
      expect(node.isDynamic, true);
      expect(node.parameterName, 'userId');
    });

    test('adds child node', () {
      final parent = RouteTreeNode(segment: 'users');
      final child = RouteTreeNode(segment: 'profile');

      parent.addChild(child);

      expect(parent.children, {'profile': child});
    });

    test('stores route element', () {
      final route = RouteElement(
        className: 'AboutRoute',
        relativePath: 'about',
        pathSegments: ['about'],
        parameters: [],
      );

      final node = RouteTreeNode(segment: 'about', route: route);

      expect(node.route, route);
    });

    test('stores layout element', () {
      final layout = LayoutElement(
        className: 'TabsLayout',
        relativePath: 'tabs/_layout',
        pathSegments: ['tabs'],
        layoutType: LayoutType.indexed,
      );

      final node = RouteTreeNode(segment: 'tabs', layout: layout);

      expect(node.layout, layout);
    });
  });

  group('CoordinatorConfig', () {
    test('has default values', () {
      const config = CoordinatorConfig();

      expect(config.name, 'AppCoordinator');
      expect(config.routeBase, 'AppRoute');
    });

    test('accepts custom values', () {
      const config = CoordinatorConfig(
        name: 'MyCoordinator',
        routeBase: 'MyRoute',
      );

      expect(config.name, 'MyCoordinator');
      expect(config.routeBase, 'MyRoute');
    });
  });
}
