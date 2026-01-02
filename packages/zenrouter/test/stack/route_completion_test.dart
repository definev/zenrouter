import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Coordinator
// ============================================================================

/// Minimal coordinator for testing
class TestCoordinator extends Coordinator<TestRoute> {
  @override
  void defineLayout() {}

  @override
  List<StackPath> get paths => [...super.paths];

  @override
  TestRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [final id] => TestRoute(id),
      _ => TestRoute('default'),
    };
  }
}

// ============================================================================
// Test Route Definitions
// ============================================================================

/// Test route with tracking for result completion
class TestRoute extends RouteTarget with RouteUnique {
  TestRoute(this.id);
  final String id;

  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/$id');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

class TestQueryRoute extends RouteTarget
    with RouteUnique, RouteQueryParameters {
  TestQueryRoute(this.id, {Map<String, String>? queryParameters}) {
    queryNotifier.value = queryParameters ?? {};
  }

  @override
  final ValueNotifier<Map<String, String>> queryNotifier = ValueNotifier({});

  final String id;

  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/$id').replace(queryParameters: queries);

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Test route that redirects to another route
class RedirectRoute extends RouteTarget
    with RouteUnique, RouteRedirect<TestRoute> {
  RedirectRoute({required this.redirectToId});

  final String redirectToId;
  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  FutureOr<TestRoute?> redirect() {
    return TestRoute(redirectToId);
  }

  @override
  List<Object?> get props => [redirectToId];

  @override
  Uri toUri() => Uri.parse('/redirect/$redirectToId');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Test route that chains to another redirect
class ChainedRedirectRoute extends RouteTarget
    with RouteUnique, RouteRedirect<RouteTarget> {
  ChainedRedirectRoute({required this.nextRedirect});

  final RedirectRoute nextRedirect;
  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  FutureOr<RouteTarget?> redirect() => nextRedirect;

  @override
  Uri toUri() => Uri.parse('/chained');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Test route that redirects to null (stays on current route)
class NullRedirectRoute extends RouteTarget
    with RouteUnique, RouteRedirect<TestRoute> {
  NullRedirectRoute();

  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  FutureOr<TestRoute?> redirect() => null;

  @override
  Uri toUri() => Uri.parse('/null-redirect');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Test route that redirects to itself
class SelfRedirectRoute extends RouteTarget
    with RouteUnique, RouteRedirect<SelfRedirectRoute> {
  SelfRedirectRoute();

  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  FutureOr<SelfRedirectRoute?> redirect() => this;

  @override
  Uri toUri() => Uri.parse('/self-redirect');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

class MultiPropsRoute extends RouteTarget with RouteUnique {
  MultiPropsRoute(this.prop1, this.prop2);
  final String prop1;
  final String prop2;

  @override
  List<Object?> get props => [prop1, prop2];

  @override
  Uri toUri() => Uri.parse('/multi-props/$prop1/$prop2');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('Route creation', () {
    test('toString()', () {
      expect(TestRoute('test').toString(), equals('TestRoute[test]'));
      expect(
        MultiPropsRoute('a', 'b').toString(),
        equals('MultiPropsRoute[a,b]'),
      );
    });
  });

  group('pushOrMoveToTop - Route Completion', () {
    test('completes result future when moving existing route to top', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final routeA = TestRoute('a');
      final routeB = TestRoute('b');
      final routeADuplicate = TestRoute('a'); // Same id, equals routeA

      // Push initial routes
      path.push(routeA);
      path.push(routeB);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(path.stack.length, 2);
      expect(routeA.resultCompleted, isFalse);

      // Push or move to top - routeA should be moved, its future should be completed
      await path.pushOrMoveToTop(routeADuplicate);

      expect(path.stack.length, 2);
      expect(path.stack.last.id, 'a');
      expect(routeA.resultCompleted, isTrue);
      expect(routeA.resultValue, isNull);
    });

    test('does not complete result future when pushing new route', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final routeA = TestRoute('a');
      final routeB = TestRoute('b');

      path.push(routeA);
      path.pushOrMoveToTop(routeB);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(path.stack.length, 2);
      expect(routeA.resultCompleted, isFalse);
      expect(routeB.resultCompleted, isFalse);
    });

    test('completes removed route future with null result', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final routeA = TestRoute('a');
      final routeB = TestRoute('b');
      final routeC = TestRoute('c');

      path.push(routeA);
      path.push(routeB);
      path.push(routeC);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(path.stack.length, 3);

      // Move routeB to top
      path.pushOrMoveToTop(TestRoute('b'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(path.stack.length, 3);
      expect(path.stack.map((r) => r.id).toList(), ['a', 'c', 'b']);
      expect(routeB.resultCompleted, isTrue);
    });

    test('handles multiple moveToTop operations correctly', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final routes = [TestRoute('a'), TestRoute('b'), TestRoute('c')];

      for (final route in routes) {
        path.push(route);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      // Move 'a' to top
      path.pushOrMoveToTop(TestRoute('a'));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(routes[0].resultCompleted, isTrue);
      expect(path.stack.map((r) => r.id).toList(), ['b', 'c', 'a']);

      // Move 'b' to top
      path.pushOrMoveToTop(TestRoute('b'));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(routes[1].resultCompleted, isTrue);
      expect(path.stack.map((r) => r.id).toList(), ['c', 'a', 'b']);
    });

    test('pushOrMoveToTop on empty stack adds route', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final route = TestRoute('a');
      path.pushOrMoveToTop(route);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(path.stack.length, 1);
      expect(path.stack.first.id, 'a');
      expect(route.resultCompleted, isFalse);
    });

    test('pushing same route that is already on top still moves it', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final routeA = TestRoute('a');
      path.push(routeA);

      // Push same route again via pushOrMoveToTop
      final newRouteA = TestRoute('a');
      path.pushOrMoveToTop(newRouteA);
      await Future.delayed(const Duration(milliseconds: 100));

      // The orginal route should remain but the new route should be completed
      expect(routeA.resultCompleted, isFalse);
      expect(newRouteA.resultCompleted, isTrue);
      expect(path.stack.length, 1);
    });

    test(
      'pushing RouteQueryParameters will update the existing route',
      () async {
        final path = NavigationPath<TestQueryRoute>.create(label: 'test');

        final routeA = TestQueryRoute('a');
        path.push(routeA);

        // Push same route again via pushOrMoveToTop
        final newRouteA = TestQueryRoute('a', queryParameters: {'a': 'b'});
        path.pushOrMoveToTop(newRouteA);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(routeA.resultCompleted, isFalse);
        expect(path.stack.length, 1);
        expect(routeA.queryNotifier.value, {'a': 'b'});
        // Check the newRouteA queryNotifier is disposed
        expect(newRouteA.resultCompleted, isTrue);
        expect(newRouteA.stackPath, isNull);
        expect(
          () => newRouteA.queryNotifier.addListener(() {}),
          throwsFlutterError,
        );
      },
    );
  });

  group('RouteRedirect.resolve - Route Completion', () {
    test('completes original route when redirect is resolved', () async {
      final redirectRoute = RedirectRoute(redirectToId: 'target');

      // Must use RouteTarget as type parameter since RedirectRoute.redirect()
      // returns TestRoute which is not a subtype of RedirectRoute
      final result = await RouteRedirect.resolve<RouteTarget>(
        redirectRoute,
        null,
      );

      expect(result, isA<TestRoute>());
      expect((result as TestRoute).id, 'target');
      expect(redirectRoute.resultCompleted, isTrue);
      expect(redirectRoute.resultValue, isNull);
    });

    test('does not complete route when redirect returns null', () async {
      final nullRedirect = NullRedirectRoute();

      final result = await RouteRedirect.resolve<RouteTarget>(
        nullRedirect,
        null,
      );

      // Should return original route
      expect(result, null);
      expect(nullRedirect.resultCompleted, isTrue);
    });

    test('does not complete route when redirect returns itself', () async {
      final selfRedirect = SelfRedirectRoute();

      final result = await RouteRedirect.resolve<RouteTarget>(
        selfRedirect,
        null,
      );

      // Should return the same route, no completion
      expect(result, same(selfRedirect));
      expect(selfRedirect.resultCompleted, isFalse);
    });

    test('completes all intermediate routes in redirect chain', () async {
      final innerRedirect = RedirectRoute(redirectToId: 'final');
      final outerRedirect = ChainedRedirectRoute(nextRedirect: innerRedirect);

      final result = await RouteRedirect.resolve<RouteTarget>(
        outerRedirect,
        null,
      );

      expect(result, isA<TestRoute>());
      expect((result as TestRoute).id, 'final');
      expect(outerRedirect.resultCompleted, isTrue);
      expect(innerRedirect.resultCompleted, isTrue);
    });
  });

  group('pushOrMoveToTop with RouteRedirect', () {
    test('handles redirect in pushOrMoveToTop', () async {
      final path = NavigationPath<RouteTarget>.create(label: 'test');

      final routeA = TestRoute('a');
      path.push(routeA);

      // Push redirect that resolves to a new route
      final redirect = RedirectRoute(redirectToId: 'b');
      path.pushOrMoveToTop(redirect);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(path.stack.length, 2);
      expect((path.stack.last as TestRoute).id, 'b');
      expect(redirect.resultCompleted, isTrue);
    });

    test('pushOrMoveToTop with redirect to existing route moves it', () async {
      final path = NavigationPath<RouteTarget>.create(label: 'test');

      final routeA = TestRoute('a');
      final routeB = TestRoute('b');
      path.push(routeA);
      path.push(routeB);
      await Future.delayed(const Duration(milliseconds: 100));

      // Push redirect that resolves to 'a' (already in stack)
      final redirect = RedirectRoute(redirectToId: 'a');
      path.pushOrMoveToTop(redirect);
      await Future.delayed(const Duration(milliseconds: 100));

      // Redirect completes, original 'a' completes, new 'a' on top
      expect(redirect.resultCompleted, isTrue);
      expect(routeA.resultCompleted, isTrue);
      expect(path.stack.length, 2);
      expect((path.stack.last as TestRoute).id, 'a');
    });
  });

  group('NavigationPath.reset - Route Completion', () {
    test('completes all routes when path is reset', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      final routes = [TestRoute('a'), TestRoute('b'), TestRoute('c')];

      for (final route in routes) {
        path.push(route);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      path.reset();

      for (final route in routes) {
        expect(route.resultCompleted, isTrue);
      }
      expect(path.stack, isEmpty);
    });
  });

  group('Memory leak prevention', () {
    testWidgets(
      'route completer does not hold reference after pop with result',
      (tester) async {
        final coordinator = TestCoordinator();
        final route = TestRoute('a');
        final routeTwo = TestRoute('b');

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );

        coordinator.push(route);
        final future = coordinator.push(routeTwo);

        await tester.pumpAndSettle(); // Fast-forwards the push animation

        // Pop the route with result
        coordinator.pop('result');

        // Fast-forwards the pop animation.
        // This ensures the animation completes and the route future resolves.
        await tester.pumpAndSettle();

        // Now the future is guaranteed to be complete in the FakeAsync zone
        final result = await future;

        expect(result, 'result');
        expect(route.resultCompleted, isFalse);
        expect(routeTwo.resultCompleted, isTrue);
      },
    );

    test('pushOrMoveToTop completes old route allowing GC', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');

      // Push route and hold reference to its future
      final route = TestRoute('a');
      final routeFuture = path.push(route);

      // Push another route
      path.push(TestRoute('b'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Move original route to top (creates new instance)
      path.pushOrMoveToTop(TestRoute('a'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Original route's future should be completed
      expect(route.resultCompleted, isTrue);

      // Future should resolve with null (not hang forever)
      final result = await routeFuture;
      expect(result, isNull);
    });

    test('chained redirects complete all intermediate futures', () async {
      // This tests that we don't leak completers in redirect chains
      final innerRedirect = RedirectRoute(redirectToId: 'final');
      final outerRedirect = ChainedRedirectRoute(nextRedirect: innerRedirect);

      final result = await RouteRedirect.resolve<RouteTarget>(
        outerRedirect,
        null,
      );

      // All intermediate routes should have their completers resolved
      expect(outerRedirect.resultCompleted, isTrue);
      expect(innerRedirect.resultCompleted, isTrue);

      // Final route should not be completed (it's the active route)
      expect((result as TestRoute).resultCompleted, isFalse);
    });

    test('remove() completes removed route future', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');
      final route = TestRoute('a');
      final route1 = TestRoute('b');

      path.push(route);
      path.push(route1);
      await Future.delayed(Duration.zero);

      path.remove(route);
      await Future.delayed(Duration.zero);
      path.remove(route1, discard: false);

      expect(path.stack, isEmpty);
      expect(route.resultCompleted, isTrue);
      // route1 is not completed because it explicitly discarded
      expect(route1.resultCompleted, isFalse);
      route1.onDiscard();
    });

    test('stress test: push multiple routes and reset cleans up all', () async {
      final path = NavigationPath<TestRoute>.create(label: 'test');
      final routes = List.generate(50, (i) => TestRoute('route_$i'));

      for (final route in routes) {
        path.push(route);
      }
      await Future.delayed(const Duration(milliseconds: 10)); // minimal delay

      expect(path.stack.length, 50);

      path.reset();

      for (final route in routes) {
        expect(route.resultCompleted, isTrue);
      }
      expect(path.stack, isEmpty);
    });
  });

  group('Route Guards - Edge Cases', () {
    test('pop() with guard rejection does not complete future', () async {
      final path = NavigationPath<RouteTarget>.create(label: 'test');

      // Route that refuses to pop
      final guardRoute = GuardRoute(allowPop: false);

      path.push(guardRoute);
      await Future.delayed(const Duration(milliseconds: 50));

      final popResult = await path.pop('result');

      expect(popResult, isFalse); // Pop rejected
      expect(guardRoute.resultCompleted, isFalse);
      expect(path.stack, contains(guardRoute));

      // Cleanup
      guardRoute.allowPop = true;
      path.pop();
    });
  });
}

class GuardRoute extends RouteTarget with RouteUnique, RouteGuard {
  GuardRoute({this.allowPop = false});
  bool allowPop;

  bool resultCompleted = false;

  @override
  void completeOnResult(
    Object? result,
    Coordinator<RouteUnique>? coordinator, [
    bool failSilent = false,
  ]) {
    resultCompleted = true;
    super.completeOnResult(result, coordinator, failSilent);
  }

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  List<Object?> get props => [allowPop];

  @override
  Uri toUri() => Uri.parse('/guard');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}
