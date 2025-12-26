import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

void main() {
  group('DeeplinkStrategyType', () {
    test('has replace value', () {
      expect(DeeplinkStrategyType.replace.name, 'replace');
      expect(DeeplinkStrategyType.replace.index, 0);
    });

    test('has push value', () {
      expect(DeeplinkStrategyType.push.name, 'push');
      expect(DeeplinkStrategyType.push.index, 1);
    });

    test('has custom value', () {
      expect(DeeplinkStrategyType.custom.name, 'custom');
      expect(DeeplinkStrategyType.custom.index, 2);
    });

    test('has all three values', () {
      expect(DeeplinkStrategyType.values.length, 3);
    });
  });

  group('LayoutType', () {
    test('has stack value', () {
      expect(LayoutType.stack.name, 'stack');
      expect(LayoutType.stack.index, 0);
    });

    test('has indexed value', () {
      expect(LayoutType.indexed.name, 'indexed');
      expect(LayoutType.indexed.index, 1);
    });

    test('has both values', () {
      expect(LayoutType.values.length, 2);
    });
  });

  group('ZenRoute', () {
    test('has default values', () {
      const route = ZenRoute();

      expect(route.guard, false);
      expect(route.redirect, false);
      expect(route.deepLink, null);
      expect(route.transition, false);
      expect(route.queries, null);
    });

    test('accepts guard parameter', () {
      const route = ZenRoute(guard: true);

      expect(route.guard, true);
    });

    test('accepts redirect parameter', () {
      const route = ZenRoute(redirect: true);

      expect(route.redirect, true);
    });

    test('accepts deepLink parameter', () {
      const route = ZenRoute(deepLink: DeeplinkStrategyType.push);

      expect(route.deepLink, DeeplinkStrategyType.push);
    });

    test('accepts transition parameter', () {
      const route = ZenRoute(transition: true);

      expect(route.transition, true);
    });

    test('accepts queries parameter', () {
      const route = ZenRoute(queries: ['search', 'page', 'sort']);

      expect(route.queries, ['search', 'page', 'sort']);
    });

    test('accepts all parameters together', () {
      const route = ZenRoute(
        guard: true,
        redirect: true,
        deepLink: DeeplinkStrategyType.custom,
        transition: true,
        queries: ['q'],
      );

      expect(route.guard, true);
      expect(route.redirect, true);
      expect(route.deepLink, DeeplinkStrategyType.custom);
      expect(route.transition, true);
      expect(route.queries, ['q']);
    });
  });

  group('ZenLayout', () {
    test('requires type parameter', () {
      const layout = ZenLayout(type: LayoutType.stack);

      expect(layout.type, LayoutType.stack);
      expect(layout.routes, null);
    });

    test('accepts stack type', () {
      const layout = ZenLayout(type: LayoutType.stack);

      expect(layout.type, LayoutType.stack);
    });

    test('accepts indexed type', () {
      const layout = ZenLayout(type: LayoutType.indexed);

      expect(layout.type, LayoutType.indexed);
    });

    test('accepts routes parameter for indexed layout', () {
      const layout = ZenLayout(
        type: LayoutType.indexed,
        routes: [String, int], // Using built-in types as example
      );

      expect(layout.type, LayoutType.indexed);
      expect(layout.routes, [String, int]);
    });

    test('routes can be null for stack layout', () {
      const layout = ZenLayout(type: LayoutType.stack, routes: null);

      expect(layout.routes, null);
    });
  });

  group('ZenCoordinator', () {
    test('has default values', () {
      const coordinator = ZenCoordinator();

      expect(coordinator.name, 'AppCoordinator');
      expect(coordinator.routeBase, 'AppRoute');
    });

    test('accepts custom name', () {
      const coordinator = ZenCoordinator(name: 'MyCoordinator');

      expect(coordinator.name, 'MyCoordinator');
      expect(coordinator.routeBase, 'AppRoute');
    });

    test('accepts custom routeBase', () {
      const coordinator = ZenCoordinator(routeBase: 'MyRoute');

      expect(coordinator.name, 'AppCoordinator');
      expect(coordinator.routeBase, 'MyRoute');
    });

    test('accepts both custom values', () {
      const coordinator = ZenCoordinator(
        name: 'CustomCoordinator',
        routeBase: 'CustomRoute',
      );

      expect(coordinator.name, 'CustomCoordinator');
      expect(coordinator.routeBase, 'CustomRoute');
    });
  });
}
