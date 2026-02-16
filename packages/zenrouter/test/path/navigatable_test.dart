import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Routes
// ============================================================================

abstract class NavigatableTestRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

/// Simple route for basic testing
class SimpleRoute extends NavigatableTestRoute {
  SimpleRoute(this.id);
  final String id;

  @override
  Uri toUri() => Uri.parse('/simple/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text('Simple: $id');
  }

  @override
  List<Object?> get props => [id];
}

/// Route with query parameters for testing parameter updates
class QueryRoute extends NavigatableTestRoute with RouteQueryParameters {
  QueryRoute(this.id, [Map<String, String>? queries]) {
    if (queries != null) this.queries = queries;
  }
  final String id;

  @override
  final ValueNotifier<Map<String, String>> queryNotifier = ValueNotifier({});

  @override
  Uri toUri() => Uri.parse('/query/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text('Query: $id');
  }

  @override
  List<Object?> get props => [id];
}

/// Route with guard for testing pop protection
class GuardedRoute extends NavigatableTestRoute with RouteGuard {
  GuardedRoute(this.id, {this.allowPop = false});
  final String id;
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded/$id');

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text('Guarded: $id');
  }

  @override
  List<Object?> get props => [id, allowPop];
}

/// Route that redirects to another route
class RedirectRoute extends NavigatableTestRoute
    with RouteRedirect<NavigatableTestRoute> {
  RedirectRoute(this.id, this.target);
  final String id;
  final NavigatableTestRoute target;

  @override
  Uri toUri() => Uri.parse('/redirect/$id');

  @override
  NavigatableTestRoute redirect() => target;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [id, target];
}

// ============================================================================
// Custom StackPath WITHOUT StackNavigatable
// ============================================================================

/// A custom stack path that does NOT implement StackNavigatable
/// to test the debug warning fallback in Coordinator.navigate()
class BasicStackPath<T extends RouteTarget> extends StackPath<T>
    with ChangeNotifier {
  BasicStackPath({super.debugLabel, super.coordinator}) : super([]);

  @override
  T? get activeRoute => stack.isEmpty ? null : stack.last;

  void addRoute(T route) {
    final currentStack = List<T>.from(stack);
    currentStack.add(route);
    bindStack(currentStack);
    notifyListeners();
  }

  @override
  Future<void> activateRoute(T route) async {
    // Just add it for simplicity
    if (!stack.contains(route)) {
      addRoute(route);
    }
  }

  @override
  void reset() {
    clear();
    notifyListeners();
  }

  @override
  PathKey get pathKey => const PathKey('BasicStackPath');
}

class BasicLayout extends NavigatableTestRoute
    with RouteLayout<NavigatableTestRoute> {
  @override
  StackPath<RouteUnique> resolvePath(
    covariant BasicPathCoordinator coordinator,
  ) => coordinator.basic;

  @override
  Widget buildPath(BasicPathCoordinator coordinator) => Builder(
    builder: (context) => Stack(
      children: [
        for (final route in coordinator.basic.stack)
          route.build(coordinator, context),
      ],
    ),
  );
}

class BasicRouteId extends NavigatableTestRoute {
  BasicRouteId(this.id);

  final String id;

  @override
  Type get layout => BasicLayout;

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Text('BasicRouteId: $id');
  }

  @override
  Uri toUri() => Uri.parse('/basic/$id');
}

// ============================================================================
// Test Coordinators
// ============================================================================

/// Coordinator with NavigationPath
class NavigationTestCoordinator extends Coordinator<NavigatableTestRoute> {
  @override
  FutureOr<NavigatableTestRoute> parseRouteFromUri(Uri uri) {
    return SimpleRoute('fallback');
  }
}

/// Coordinator with IndexedStackPath
class IndexedTestCoordinator extends Coordinator<NavigatableTestRoute> {
  late final IndexedStackPath<NavigatableTestRoute> indexed =
      IndexedStackPath.createWith(
        [SimpleRoute('tab1'), SimpleRoute('tab2'), SimpleRoute('tab3')],
        coordinator: this,
        label: 'indexed',
      );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, indexed];

  @override
  FutureOr<NavigatableTestRoute> parseRouteFromUri(Uri uri) {
    return SimpleRoute('fallback');
  }
}

/// Coordinator with BasicStackPath (no StackNavigatable)
class BasicPathCoordinator extends Coordinator<NavigatableTestRoute> {
  late final BasicStackPath<NavigatableTestRoute> basic = BasicStackPath(
    coordinator: this,
    debugLabel: 'basic',
  );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, basic];

  @override
  void defineLayout() {
    defineRouteLayout(BasicLayout, BasicLayout.new);
  }

  @override
  FutureOr<NavigatableTestRoute> parseRouteFromUri(Uri uri) {
    return SimpleRoute('fallback');
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('NavigationPath (StackMutatable) - navigate()', () {
    test('pushes new route when not in stack', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], route2);
    });

    test('pops to existing route when in stack', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      await Future.delayed(Duration.zero);

      path.navigate(route1);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack[0], route1);
    });

    test('pops multiple routes to reach target route', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');
      final route4 = SimpleRoute('4');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      path.push(route4);
      await Future.delayed(Duration.zero);

      path.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], route2);
    });

    test('updates query parameters when navigating to same route', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = QueryRoute('1', {'key': 'value1'});
      final route2 = QueryRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      final updatedRoute1 = QueryRoute('1', {'key': 'value2', 'new': 'param'});
      path.navigate(updatedRoute1);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(route1.queries['key'], 'value2');
      expect(route1.queries['new'], 'param');
    });

    test('stops navigating when guard blocks pop', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: false);
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(guardedRoute);
      path.push(route3);

      path.navigate(route1);
      await Future.delayed(Duration.zero);

      // Should stop at guarded route because guard blocked further popping
      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], guardedRoute);
    });

    test('follows redirect when navigating', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final target = SimpleRoute('target');
      final redirect = RedirectRoute('redirect', target);

      path.push(route1);
      await Future.delayed(Duration.zero);

      path.navigate(redirect);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[1], target);
      expect(path.stack[1], isNot(redirect));
    });

    test('notifies listeners when route is pushed', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      await Future.delayed(Duration.zero);

      var notified = false;
      path.addListener(() => notified = true);

      path.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(notified, true);
    });

    test('notifies listeners when routes are popped', () async {
      final path = NavigationPath<NavigatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      var notified = false;
      path.addListener(() => notified = true);

      path.navigate(route1);
      await Future.delayed(Duration.zero);

      expect(notified, true);
    });
  });

  group('IndexedStackPath - navigate()', () {
    test('switches to route when found in stack', () async {
      final route1 = SimpleRoute('tab1');
      final route2 = SimpleRoute('tab2');
      final route3 = SimpleRoute('tab3');

      final path = IndexedStackPath<NavigatableTestRoute>.create([
        route1,
        route2,
        route3,
      ]);

      expect(path.activeIndex, 0);

      path.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(path.activeIndex, 1);
      expect(path.activeRoute, route2);
    });

    test('switches to last route when navigating', () async {
      final route1 = SimpleRoute('tab1');
      final route2 = SimpleRoute('tab2');
      final route3 = SimpleRoute('tab3');

      final path = IndexedStackPath<NavigatableTestRoute>.create([
        route1,
        route2,
        route3,
      ]);

      path.navigate(route3);
      await Future.delayed(Duration.zero);

      expect(path.activeIndex, 2);
      expect(path.activeRoute, route3);
    });

    test('does nothing and notifies when route not found', () async {
      final route1 = SimpleRoute('tab1');
      final route2 = SimpleRoute('tab2');
      final routeNotInStack = SimpleRoute('not-in-stack');

      final path = IndexedStackPath<NavigatableTestRoute>.create([
        route1,
        route2,
      ]);

      var notified = false;
      path.addListener(() => notified = true);

      path.navigate(routeNotInStack);
      await Future.delayed(Duration.zero);

      // Should restore URL by calling notifyListeners
      expect(notified, true);
      // Active index should not change
      expect(path.activeIndex, 0);
      expect(path.activeRoute, route1);
    });

    test(
      'updates query parameters when navigating to already active route',
      () async {
        final route1 = QueryRoute('tab1', {'key': 'value1'});
        final route2 = QueryRoute('tab2', {'key': 'value1'});

        final path = IndexedStackPath<NavigatableTestRoute>.create([
          route1,
          route2,
        ]);

        // Navigate to route2 first
        path.navigate(route2);
        await Future.delayed(Duration.zero);

        expect(path.activeIndex, 1);

        // Navigate to same route with updated queries
        final updatedRoute2 = QueryRoute('tab2', {'key': 'value2'});
        path.navigate(updatedRoute2);
        await Future.delayed(Duration.zero);

        // Should update queries on the existing route
        expect(path.activeIndex, 1);
        expect(route2.queries['key'], 'value2');
      },
    );

    test('no change when navigating to already active route', () async {
      final route1 = SimpleRoute('tab1');
      final route2 = SimpleRoute('tab2');

      final path = IndexedStackPath<NavigatableTestRoute>.create([
        route1,
        route2,
      ]);

      var notifyCount = 0;
      path.addListener(() => notifyCount++);

      // Second call should not notify
      path.navigate(route1);
      await Future.delayed(Duration.zero);

      // activateRoute returns early when index matches
      expect(notifyCount, 0);
    });
  });

  group('Coordinator.navigate() - NavigationPath integration', () {
    test('delegates to NavigationPath.navigate() for new route', () async {
      final coordinator = NavigationTestCoordinator();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      coordinator.push(route1);
      coordinator.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack[0], route1);
      expect(coordinator.root.stack[1], route2);
    });

    test('delegates to NavigationPath.navigate() to pop to existing', () async {
      final coordinator = NavigationTestCoordinator();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      coordinator.push(route1);
      coordinator.push(route2);
      coordinator.push(route3);
      await Future.delayed(Duration.zero);

      coordinator.navigate(route1);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack[0], route1);
    });

    test('respects guards during navigation', () async {
      final coordinator = NavigationTestCoordinator();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: false);
      final route3 = SimpleRoute('3');

      coordinator.push(route1);
      coordinator.push(guardedRoute);
      coordinator.push(route3);
      await Future.delayed(Duration.zero);

      coordinator.navigate(route1);
      await Future.delayed(Duration.zero);

      // Guard should block, keeping all routes
      expect(coordinator.root.stack.length, 2);
    });
  });

  group('Coordinator.navigate() - IndexedStackPath integration', () {
    test('handles route not found in indexed stack', () async {
      final coordinator = IndexedTestCoordinator();
      final routeNotInStack = SimpleRoute('not-in-stack');

      var notifyCount = 0;
      coordinator.addListener(() => notifyCount++);

      coordinator.navigate(routeNotInStack);
      await Future.delayed(Duration.zero);

      // Should call notifyListeners to restore URL
      expect(notifyCount, greaterThan(0));
      // Active index should remain 0
      expect(coordinator.indexed.activeIndex, 0);
    });
  });

  group('Coordinator.navigate() - Non-StackNavigatable path', () {
    test('prints debug message when path lacks StackNavigatable', () async {
      final coordinator = BasicPathCoordinator();
      final route2 = BasicRouteId('2');

      // The navigate() call should trigger an assertion error because
      // BasicStackPath does not implement StackNavigatable
      expect(() async {
        await coordinator.navigate(route2);
      }, throwsA(isA<AssertionError>()));
    });

    test('does not throw error for non-navigatable path', () async {
      final coordinator = BasicPathCoordinator();
      final route = SimpleRoute('basic-route');

      coordinator.basic.addRoute(route);
      await Future.delayed(Duration.zero);

      // This should not throw
      expect(
        () => coordinator.navigate(SimpleRoute('basic-route')),
        returnsNormally,
      );
    });

    test('no navigation occurs on non-navigatable path', () async {
      final coordinator = BasicPathCoordinator();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      coordinator.basic.addRoute(route1);
      await Future.delayed(Duration.zero);

      final initialLength = coordinator.basic.stack.length;

      // Navigate should have no effect
      coordinator.navigate(route2);
      await Future.delayed(Duration.zero);

      // Stack should not change
      expect(coordinator.basic.stack.length, initialLength);
      expect(coordinator.basic.activeRoute, route1);
    });
  });

  group('Coordinator.navigate() - Redirects', () {
    test('follows redirects before navigating', () async {
      final coordinator = NavigationTestCoordinator();
      final route1 = SimpleRoute('1');
      final target = SimpleRoute('target');
      final redirect = RedirectRoute('redirect', target);

      coordinator.push(route1);
      await Future.delayed(Duration.zero);

      coordinator.navigate(redirect);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack[1], target);
    });
  });
}
