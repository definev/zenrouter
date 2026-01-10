import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Routes
// ============================================================================

abstract class MutatablePathRoute extends RouteTarget {
  Widget build();
}

class SimplePathRoute extends MutatablePathRoute {
  SimplePathRoute(this.id);

  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Widget build() => Text('Simple route: $id');
}

class RedirectPathRoute extends MutatablePathRoute
    with RouteRedirect<MutatablePathRoute> {
  RedirectPathRoute(this.target);

  final MutatablePathRoute target;

  @override
  FutureOr<MutatablePathRoute> redirect() => target;

  @override
  Widget build() => SizedBox();
}

class GuardedPathRoute extends MutatablePathRoute with RouteGuard {
  GuardedPathRoute(this.poppable);

  final bool poppable;

  @override
  List<Object?> get props => [poppable];

  @override
  Widget build() => Text('Guarded route: $poppable');

  @override
  FutureOr<bool> popGuard() => poppable;
}

abstract class MutatableTestRoute extends RouteTarget with RouteUnique {}

/// Simple route for basic testing
class SimpleRoute extends MutatableTestRoute {
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

class RedirectNullRoute extends MutatableTestRoute
    with RouteRedirect<MutatableTestRoute> {
  RedirectNullRoute();

  @override
  Uri toUri() => Uri.parse('/redirect-null');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text('RedirectNull');
  }

  @override
  FutureOr<MutatableTestRoute?> redirectWith(
    covariant Coordinator<RouteUnique> coordinator,
  ) => null;
}

/// Route with query parameters for testing parameter updates
class QueryRoute extends MutatableTestRoute with RouteQueryParameters {
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
class GuardedRoute extends MutatableTestRoute with RouteGuard {
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

/// Route with coordinator-aware guard
class CoordinatorGuardedRoute extends MutatableTestRoute with RouteGuard {
  CoordinatorGuardedRoute(this.id, {this.allowPop = false});
  final String id;
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/coord-guarded/$id');

  @override
  Future<bool> popGuardWith(Coordinator coordinator) async {
    // Verify coordinator is passed correctly
    expect(coordinator, isNotNull);
    return allowPop;
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text('CoordGuarded: $id');
  }

  @override
  List<Object?> get props => [id, allowPop];
}

/// Route that redirects to another route
class RedirectRoute extends MutatableTestRoute
    with RouteRedirect<MutatableTestRoute> {
  RedirectRoute(this.id, this.target);
  final String id;
  final MutatableTestRoute target;

  @override
  Uri toUri() => Uri.parse('/redirect/$id');

  @override
  MutatableTestRoute redirect() => target;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [id, target];
}

/// Route that redirects asynchronously
class AsyncRedirectRoute extends MutatableTestRoute
    with RouteRedirect<MutatableTestRoute> {
  AsyncRedirectRoute(this.id, this.target, {this.delay = 10});
  final String id;
  final MutatableTestRoute target;
  final int delay;

  @override
  Uri toUri() => Uri.parse('/async-redirect/$id');

  @override
  Future<MutatableTestRoute> redirect() async {
    await Future.delayed(Duration(milliseconds: delay));
    return target;
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [id, target, delay];
}

/// Custom test coordinator
class MutatableTestCoordinator extends Coordinator<MutatableTestRoute> {
  late final navigation = NavigationPath<MutatableTestRoute>.create(
    coordinator: this,
    label: 'test-navigation',
  );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, navigation];

  @override
  FutureOr<MutatableTestRoute> parseRouteFromUri(Uri uri) {
    return SimpleRoute('fallback');
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('StackMutatable - push()', () {
    test('do nothing when redirectWith return null', () {
      final path = NavigationPath<MutatableTestRoute>.createWith(
        coordinator: MutatableTestCoordinator(),
        label: 'test-navigation',
      );

      path.push(RedirectNullRoute());

      expect(path.stack.isEmpty, true);
    });

    test('pushes a simple route to empty stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, route);
      expect(route.stackPath, path);
      expect(route.isPopByPath, false);
    });

    test('pushes multiple routes to stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 3);
      expect(path.stack[0], route1);
      expect(path.stack[1], route2);
      expect(path.stack[2], route3);
    });

    test('follows redirect when pushing redirect route', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final target = SimpleRoute('target');
      final redirect = RedirectRoute('redirect', target);

      path.push(redirect);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
      expect(path.stack.first, isNot(redirect));
    });

    test('handles async redirect', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final target = SimpleRoute('target');
      final redirect = AsyncRedirectRoute('redirect', target, delay: 50);

      path.push(redirect);
      await Future.delayed(Duration(milliseconds: 100));

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('binds stack path to route', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);
      await Future.delayed(Duration.zero);

      expect(route.stackPath, path);
    });

    test('sets isPopByPath to false', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);

      expect(route.isPopByPath, false);
    });

    test('notifies listeners when route is pushed', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      var notified = false;
      path.addListener(() => notified = true);

      path.push(route);
      await Future.delayed(Duration.zero);

      expect(notified, true);
    });

    test('works with coordinator', () async {
      final coordinator = MutatableTestCoordinator();
      final route = SimpleRoute('1');

      coordinator.push(route);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, route);
    });
  });

  group('StackMutatable - pushReplacement()', () {
    testWidgets('pushes to empty stack', (tester) async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<MutatableTestRoute>(
            path: path,
            resolver: (route) => StackTransition.cupertino(
              Builder(
                builder: (context) =>
                    route.build(MutatableTestCoordinator(), context),
              ),
            ),
          ),
        ),
      );

      // pushReplacement on empty stack should just push
      final future = path.pushReplacement(route);
      await tester.pumpAndSettle();

      expect(path.stack.length, 1);
      expect(path.stack.first, route);
      expect(route.stackPath, path);

      // Complete the route to avoid hanging future
      route.completeOnResult(null, null);
      await future;
    });

    testWidgets('replaces single element stack and completes result', (
      tester,
    ) async {
      final path = NavigationPath<MutatablePathRoute>.create();
      final route1 = SimplePathRoute('1');
      final route2 = SimplePathRoute('2');

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<MutatablePathRoute>(
            path: path,
            resolver: (route) => StackTransition.none(route.build()),
          ),
        ),
      );

      // Push first route and capture its result
      final route1Result = path.push(route1);
      await tester.pumpAndSettle();

      expect(path.stack.length, 1);
      expect(path.stack.first, route1);

      // Push replacement with result
      path.pushReplacement<String, String>(route2, result: 'replaced');
      await tester.pumpAndSettle();

      // Stack should now have only route2
      expect(path.stack.length, 1);
      expect(path.stack.first, route2);

      // route1 should have received the result
      expect(await route1Result, 'replaced');
      expect(route1.onResult.isCompleted, true);
    });

    testWidgets(
      'replaces top route when stack has multiple elements and completes result',
      (tester) async {
        final path = NavigationPath<MutatablePathRoute>.create();
        final route1 = SimplePathRoute('1');
        final route2 = SimplePathRoute('2');
        final route3 = SimplePathRoute('3');

        await tester.pumpWidget(
          MaterialApp(
            home: NavigationStack<MutatablePathRoute>(
              path: path,
              resolver: (route) => StackTransition.none(route.build()),
            ),
          ),
        );

        // Push routes
        path.push(route1);
        await tester.pumpAndSettle();
        final route2Result = path.push(route2);
        await tester.pumpAndSettle();

        expect(path.stack.length, 2);

        // Push replacement - should pop route2 and push route3
        path.pushReplacement<String, String>(route3, result: 'popped');
        await tester.pumpAndSettle();

        // Stack should have route1 and route3
        expect(path.stack.length, 2);
        expect(path.stack[0], route1);
        expect(path.stack[1], route3);

        // route2 should have received the result
        expect(await route2Result, 'popped');
        expect(route2.onResult.isCompleted, true);
      },
    );

    testWidgets('handles redirect and replaces correctly', (tester) async {
      final path = NavigationPath<MutatablePathRoute>.create();
      final route1 = SimplePathRoute('1');
      final target = SimplePathRoute('target');
      final redirect = RedirectPathRoute(target);

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<MutatablePathRoute>(
            path: path,
            resolver: (route) => StackTransition.none(route.build()),
          ),
        ),
      );

      // Push first route
      final route1Result = path.push(route1);
      await tester.pumpAndSettle();

      // Push replacement with redirect - should redirect to target
      path.pushReplacement(redirect);
      await tester.pumpAndSettle();

      // Stack should have only the target (not the redirect)
      expect(path.stack.length, 1);
      expect(path.stack.first, target);
      expect(path.stack.first, isNot(redirect));
      expect(await route1Result, null);
    });

    testWidgets('respects guard that blocks pop during replacement', (
      tester,
    ) async {
      final path = NavigationPath<MutatablePathRoute>.create();
      final route1 = SimplePathRoute('1');
      final guardedRoute = GuardedPathRoute(false);
      final route3 = SimplePathRoute('3');

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<MutatablePathRoute>(
            path: path,
            resolver: (route) => StackTransition.none(route.build()),
          ),
        ),
      );

      // Push routes
      path.push(route1);
      await tester.pumpAndSettle();
      path.push(guardedRoute);
      await tester.pumpAndSettle();

      expect(path.stack.length, 2);

      // Push replacement - should be blocked by guard
      final result = await path.pushReplacement(route3);
      await tester.pumpAndSettle();

      // Guard blocked pop, so replacement should fail
      expect(result, isNull);
      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], guardedRoute);
    });

    testWidgets('respects guard that allows pop during replacement', (
      tester,
    ) async {
      final path = NavigationPath<MutatablePathRoute>.create();
      final route1 = SimplePathRoute('1');
      final guardedRoute = GuardedPathRoute(true);
      final route3 = SimplePathRoute('3');

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<MutatablePathRoute>(
            path: path,
            resolver: (route) => StackTransition.none(route.build()),
          ),
        ),
      );

      // Push routes
      path.push(route1);
      await tester.pumpAndSettle();
      final guardedRouteResult = path.push(guardedRoute);
      await tester.pumpAndSettle();

      expect(path.stack.length, 2);

      // Push replacement - guard should allow pop
      path.pushReplacement(route3, result: 'popped');
      await tester.pumpAndSettle();

      // Guard allowed, replacement should succeed
      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], route3);
      expect(await guardedRouteResult, 'popped');
    });
  });

  group('StackMutatable - pushOrMoveToTop()', () {
    test('do nothing when redirectWith return null', () {
      final path = NavigationPath<MutatableTestRoute>.createWith(
        coordinator: MutatableTestCoordinator(),
        label: 'test-navigation',
      );

      path.pushOrMoveToTop(RedirectNullRoute());

      expect(path.stack.isEmpty, true);
    });

    test('pushes new route to top when not in stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      await path.pushOrMoveToTop(route2);

      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], route2);
    });

    test('moves existing route to top', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);

      await path.pushOrMoveToTop(route1);

      expect(path.stack.length, 3);
      expect(path.stack[0], route2);
      expect(path.stack[1], route3);
      expect(path.stack[2], route1);
    });

    test('does nothing when route is already at top', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      var notifyCount = 0;
      path.addListener(() => notifyCount++);

      await path.pushOrMoveToTop(route2);
      await Future.delayed(Duration.zero);

      // Should not notify because no change occurred
      expect(notifyCount, 0);
      expect(path.stack.length, 2);
      expect(path.stack.last, route2);
    });

    test('updates queries when same route is already at top', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = QueryRoute('1', {'key': 'value1'});

      path.push(route);
      await Future.delayed(Duration.zero);

      final updatedRoute = QueryRoute('1', {'key': 'value2', 'new': 'param'});
      await path.pushOrMoveToTop(updatedRoute);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(route.queries['key'], 'value2');
      expect(route.queries['new'], 'param');
    });

    test('discards incoming route when already at top', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);

      // Create a new instance that equals the existing route
      final duplicateRoute = SimpleRoute('1');

      // We can't directly override onDiscard, but we can verify behavior
      // by checking that the original route is still bound
      await path.pushOrMoveToTop(duplicateRoute);

      expect(route.stackPath, path);
      expect(duplicateRoute.stackPath, isNull);
    });

    test('clears stack path from removed route when moving to top', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      expect(route1.stackPath, path);

      // Move route1 to top - a new instance should be created
      // The old instance should have its stack path cleared
      await path.pushOrMoveToTop(route1);
      await Future.delayed(Duration.zero);

      // After moving, route1 should still be bound
      expect(route1.stackPath, path);
    });

    test('follows redirect', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final target = SimpleRoute('target');
      final redirect = RedirectRoute('redirect', target);

      await path.pushOrMoveToTop(redirect);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('notifies listeners when route is moved', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);

      var notified = false;
      path.addListener(() => notified = true);

      await path.pushOrMoveToTop(route1);

      expect(notified, true);
    });

    test('notifies listeners when new route is pushed', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      var notified = false;
      path.addListener(() => notified = true);

      await path.pushOrMoveToTop(route);

      expect(notified, true);
    });

    test('handles empty stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      await path.pushOrMoveToTop(route);

      expect(path.stack.length, 1);
      expect(path.stack.first, route);
    });
  });

  group('StackMutatable - pop()', () {
    test('pops the last route from stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      final result = await path.pop('result');

      expect(result, true);
      expect(path.stack.length, 1);
      expect(path.stack.first, route1);
      expect(route2.resultValue, 'result');
    });

    test('returns null when stack is empty', () async {
      final path = NavigationPath<MutatableTestRoute>.create();

      final result = await path.pop();

      expect(result, null);
      expect(path.stack.length, 0);
    });

    test('sets isPopByPath to true on popped route', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);
      await Future.delayed(Duration.zero);
      await path.pop();

      expect(route.isPopByPath, true);
    });

    test('respects guard that blocks pop', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: false);

      path.push(route1);
      path.push(guardedRoute);
      await Future.delayed(Duration.zero);

      final result = await path.pop();

      expect(result, false);
      expect(path.stack.length, 2);
      expect(path.stack.last, guardedRoute);
    });

    test('respects guard that allows pop', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: true);

      path.push(route1);
      path.push(guardedRoute);
      await Future.delayed(Duration.zero);

      final result = await path.pop();

      expect(result, true);
      expect(path.stack.length, 1);
      expect(path.stack.first, route1);
    });

    test('calls popGuard when no coordinator', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final guardedRoute = GuardedRoute('1', allowPop: false);

      path.push(guardedRoute);
      await Future.delayed(Duration.zero);

      final result = await path.pop();

      expect(result, false);
    });

    test('calls popGuardWith when coordinator exists', () async {
      final coordinator = MutatableTestCoordinator();
      final guardedRoute = CoordinatorGuardedRoute('1', allowPop: true);

      coordinator.push(guardedRoute);
      await Future.delayed(Duration.zero);

      final result = await coordinator.tryPop();

      /// Cannot pop since the route stack is has only one element
      expect(result, false);
    });

    test('notifies listeners after successful pop', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);

      var notified = false;
      path.addListener(() => notified = true);

      await path.pop();

      expect(notified, true);
    });

    test('does not notify listeners when guard blocks pop', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final guardedRoute = GuardedRoute('1', allowPop: false);

      path.push(SimpleRoute('2'));
      path.push(guardedRoute);
      await Future.delayed(Duration.zero);

      var notified = false;
      path.addListener(() => notified = true);

      await path.pop();

      expect(notified, false);
    });

    test('pops all routes sequentially', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      path.push(SimpleRoute('1'));
      path.push(SimpleRoute('2'));
      path.push(SimpleRoute('3'));
      await Future.delayed(Duration.zero);

      expect(await path.pop(), true);
      expect(path.stack.length, 2);

      expect(await path.pop(), true);
      expect(path.stack.length, 1);

      expect(await path.pop(), true);
      expect(path.stack.length, 0);

      expect(await path.pop(), null);
    });
  });

  group('StackMutatable - remove()', () {
    test('removes route from stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      await Future.delayed(Duration.zero);

      path.remove(route2);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(route2.onResult.isCompleted, isTrue);
      expect(path.stack[0], route1);
      expect(path.stack[1], route3);
    });

    test('removes last route from stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      path.remove(route2);

      expect(path.stack.length, 1);
      expect(path.stack.first, route1);
    });

    test('removes first route from stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);

      path.remove(route1);

      expect(path.stack.length, 1);
      expect(path.stack.first, route2);
    });

    test('bypasses guard', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final guardedRoute = GuardedRoute('1', allowPop: false);

      path.push(guardedRoute);

      path.remove(guardedRoute);

      expect(path.stack.length, 0);
    });

    test('clears stack path from removed route', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);
      await Future.delayed(Duration.zero);

      expect(route.stackPath, path);

      path.remove(route);

      expect(route.stackPath, null);
    });

    test('notifies listeners when route is removed', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.push(route);
      await Future.delayed(Duration.zero);

      var notified = false;
      path.addListener(() => notified = true);

      path.remove(route);

      expect(notified, true);
    });

    test('does not notify listeners when route not in stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      await Future.delayed(Duration.zero);

      var notified = false;
      path.addListener(() => notified = true);

      path.remove(route2);

      expect(notified, false);
    });

    test('handles removing from empty stack gracefully', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      // Should not throw
      path.remove(route);

      expect(path.stack.length, 0);
    });

    test('removes multiple routes', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      await Future.delayed(Duration.zero);

      path.remove(route1);
      path.remove(route3);

      expect(path.stack.length, 1);
      expect(path.stack.first, route2);
    });
  });

  group('StackMutatable - navigate()', () {
    test('do nothing when redirectWith return null', () {
      final path = NavigationPath<MutatableTestRoute>.createWith(
        coordinator: MutatableTestCoordinator(),
        label: 'test-navigation',
      );

      path.navigate(RedirectNullRoute());

      expect(path.stack.isEmpty, true);
    });

    test('pushes new route when not in stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      path.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], route2);
    });

    test('pops to existing route in stack', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      path.navigate(route1);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, route1);
    });

    test('pops multiple routes to reach target', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');
      final route4 = SimpleRoute('4');

      path.push(route1);
      path.push(route2);
      path.push(route3);
      path.push(route4);
      path.navigate(route2);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], route2);
    });

    test('updates query parameters when navigating to same route', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = QueryRoute('1', {'key': 'value1'});
      final route2 = QueryRoute('2');

      path.push(route1);
      path.push(route2);

      final updatedRoute1 = QueryRoute('1', {'key': 'value2', 'new': 'param'});
      await path.navigate(updatedRoute1);

      expect(path.stack.length, 1);
      expect(route1.queries['key'], 'value2');
      expect(route1.queries['new'], 'param');
    });

    test('stops popping when guard blocks', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: false);
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(guardedRoute);
      path.push(route3);

      await path.navigate(route1);

      // Should stop at guarded route due to guard blocking
      expect(path.stack.length, 2);
      expect(path.stack[0], route1);
      expect(path.stack[1], guardedRoute);
    });

    test('notifies listeners after navigation', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');

      path.push(route1);
      await Future.delayed(Duration.zero);

      var notifyCount = 0;
      path.addListener(() => notifyCount++);

      path.navigate(route2);
      await Future.delayed(Duration.zero);

      // Should notify: once for push
      expect(notifyCount, greaterThan(0));
    });

    test('follows redirect before navigating', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final target = SimpleRoute('target');
      final redirect = RedirectRoute('redirect', target);

      path.navigate(redirect);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('discards incoming route when hash differs but equals', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');

      path.push(route1);

      // Create a route that equals route1
      final route1Copy = SimpleRoute('1');

      await path.navigate(route1Copy);

      // Should stay at route1
      expect(path.stack.length, 1);
      expect(path.stack.first, route1);
    });

    test('handles navigating to currently active route', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = QueryRoute('1', {'key': 'value1'});

      path.push(route1);

      final updatedRoute1 = QueryRoute('1', {'key': 'value2'});
      await path.navigate(updatedRoute1);

      expect(path.stack.length, 1);
      expect(route1.queries['key'], 'value2');
    });

    test('notifies listeners when guard blocks during navigate', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: false);

      path.push(route1);
      path.push(guardedRoute);

      var notified = false;
      path.addListener(() => notified = true);

      await path.navigate(route1);

      // Should still notify even when blocked
      expect(notified, true);
    });

    test('handles empty stack during navigate', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      path.navigate(route);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, route);
    });
  });

  group('StackMutatable - Edge Cases', () {
    test('handles rapid push operations', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        futures.add(path.push(SimpleRoute('$i')));
      }

      await Future.delayed(Duration(milliseconds: 10));

      expect(path.stack.length, 10);
    });

    test('handles rapid pop operations', () async {
      final path = NavigationPath<MutatableTestRoute>.create();

      for (int i = 0; i < 5; i++) {
        path.push(SimpleRoute('$i'));
      }
      await Future.delayed(Duration.zero);

      for (int i = 0; i < 3; i++) {
        path.pop();
      }

      expect(path.stack.length, 2);
    });

    test('handles mixed push/pop/remove operations', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');
      final route4 = SimpleRoute('4');

      path.push(route1);
      path.push(route2);
      await Future.delayed(Duration.zero);
      await path.pop();
      path.push(route3);
      await Future.delayed(Duration.zero);
      path.remove(route1);
      path.push(route4);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0], route3);
      expect(path.stack[1], route4);
    });

    test('handles pushOrMoveToTop with redirect', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final target = SimpleRoute('target');
      final redirect = RedirectRoute('redirect', target);

      path.push(SimpleRoute('1'));
      await path.pushOrMoveToTop(redirect);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack.last, target);
    });

    test('handles navigate with async redirect', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final target = SimpleRoute('target');
      final redirect = AsyncRedirectRoute('redirect', target, delay: 50);

      path.navigate(redirect);
      await Future.delayed(Duration(milliseconds: 100));

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('handles removing route while pop is in progress', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final guardedRoute = GuardedRoute('2', allowPop: false);

      path.push(route1);
      path.push(guardedRoute);
      await Future.delayed(Duration.zero);

      // Start pop (will be blocked by guard)
      path.pop();

      // Remove the route instead
      path.remove(guardedRoute);

      await Future.delayed(Duration(milliseconds: 10));

      expect(path.stack.length, 1);
      expect(path.stack.first, route1);
    });

    test('handles concurrent navigate operations', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = SimpleRoute('1');
      final route2 = SimpleRoute('2');
      final route3 = SimpleRoute('3');

      path.push(route1);
      path.push(route2);
      path.push(route3);

      // Concurrent navigate calls
      path.navigate(route1);
      await path.navigate(route2);

      // Last navigation should win
      expect(path.stack.length, 2);
      expect(path.stack.last, route2);
    });

    test('maintains stack integrity with query parameter updates', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route1 = QueryRoute('1', {'a': '1'});
      final route2 = QueryRoute('2', {'b': '2'});

      path.push(route1);
      path.push(route2);

      await path.navigate(QueryRoute('1', {'a': '1-updated', 'c': '3'}));

      expect(path.stack.length, 1);
      expect(route1.queries['a'], '1-updated');
      expect(route1.queries['c'], '3');
    });

    test('handles empty stack pop gracefully', () async {
      final path = NavigationPath<MutatableTestRoute>.create();

      final result = await path.pop();

      expect(result, null);
      expect(path.stack.length, 0);
    });

    test('handles multiple listeners on same path', () async {
      final path = NavigationPath<MutatableTestRoute>.create();
      final route = SimpleRoute('1');

      var listener1Called = 0;
      var listener2Called = 0;
      var listener3Called = 0;

      path.addListener(() => listener1Called++);
      path.addListener(() => listener2Called++);
      path.addListener(() => listener3Called++);

      path.push(route);
      await Future.delayed(Duration.zero);
      await path.pop();

      expect(listener1Called, 2);
      expect(listener2Called, 2);
      expect(listener3Called, 2);
    });

    test('handles large stack operations', () async {
      final path = NavigationPath<MutatableTestRoute>.create();

      // Push 100 routes
      for (int i = 0; i < 100; i++) {
        path.push(SimpleRoute('$i'));
      }
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 100);

      // Pop 50 routes
      for (int i = 0; i < 50; i++) {
        await path.pop();
      }

      expect(path.stack.length, 50);

      // Navigate to first route
      path.navigate(SimpleRoute('0'));
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect((path.stack.first as SimpleRoute).id, '0');
    });

    testWidgets('pushReplacement() should discard RouteQueryParameters', (
      tester,
    ) async {
      final route1 = QueryRoute('1', {'a': '1'});
      final route2 = QueryRoute('2', {'b': '2'});
      final coordinator = MutatableTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(route1);
      coordinator.push(route2);
      await tester.pumpAndSettle();

      coordinator.pushReplacement(QueryRoute('2', {'b': '3'}));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 3);
      expect((coordinator.root.stack[1] as QueryRoute).queries['a'], '1');
      expect((coordinator.root.stack[2] as QueryRoute).queries['b'], '3');
      expect(() => route2.queryNotifier.addListener(() {}), throwsFlutterError);
    });
  });
}
