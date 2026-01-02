import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Routes
// ============================================================================

abstract class IndexedTestRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

class SimpleIndexedRoute extends IndexedTestRoute {
  SimpleIndexedRoute(this.id);
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

class RedirectNullRoute extends IndexedTestRoute
    with RouteRedirect<IndexedTestRoute> {
  @override
  Type? get layout => IndexedStackLayout;

  @override
  Uri toUri() => Uri.parse('/redirect');

  @override
  IndexedTestRoute? redirectWith(Coordinator coordinator) => null;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [];
}

class GuardedIndexedRoute extends IndexedTestRoute with RouteGuard {
  GuardedIndexedRoute({this.allowPop = false});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded');

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text('Guarded: $allowPop');
  }

  @override
  List<Object?> get props => [allowPop];
}

class RedirectIndexedRoute extends IndexedTestRoute
    with RouteRedirect<IndexedTestRoute> {
  RedirectIndexedRoute({required this.target});
  final IndexedTestRoute target;

  @override
  Uri toUri() => Uri.parse('/redirect');

  @override
  FutureOr<IndexedTestRoute> redirect() => target;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [target];
}

class NullRedirectIndexedRoute extends IndexedTestRoute
    with RouteRedirect<IndexedTestRoute> {
  NullRedirectIndexedRoute({required this.target});
  final IndexedTestRoute target;

  @override
  Uri toUri() => Uri.parse('/redirect');

  @override
  FutureOr<IndexedTestRoute> redirect() => target;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [target];
}

class IndexedStackLayout extends IndexedTestRoute
    with RouteLayout<IndexedTestRoute> {
  @override
  StackPath<RouteUnique> resolvePath(
    covariant IndexedTestCoordinator coordinator,
  ) => coordinator.indexed;
}

class CoordinatorFirstTab extends IndexedTestRoute {
  @override
  Type? get layout => IndexedStackLayout;

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => const Text('First Tab', key: ValueKey('first-tab'));

  @override
  Uri toUri() => Uri.parse('/first-tab');
}

class CoordinatorSecondTab extends IndexedTestRoute
    with RouteRedirect<IndexedTestRoute> {
  @override
  Type? get layout => IndexedStackLayout;

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => const Text('Second Tab', key: ValueKey('second-tab'));

  @override
  Uri toUri() => Uri.parse('/second-tab');

  @override
  IndexedTestRoute? redirectWith(Coordinator<RouteUnique> coordinator) {
    return null;
  }
}

class CoordinatorThirdTab extends IndexedTestRoute
    with RouteRedirect<IndexedTestRoute> {
  @override
  Type? get layout => IndexedStackLayout;

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => const Text('Third Tab', key: ValueKey('third-tab'));

  @override
  Uri toUri() => Uri.parse('/third-tab');

  @override
  IndexedTestRoute redirect() => HomeRoute();
}

class HomeRoute extends IndexedTestRoute with RouteDeepLink {
  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => Text('Home', key: ValueKey('home'));

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  FutureOr<void> deeplinkHandler(IndexedTestCoordinator coordinator, Uri uri) {
    coordinator.navigate(this);
  }
}

class IndexedTestCoordinator extends Coordinator<IndexedTestRoute> {
  late final indexed = IndexedStackPath<IndexedTestRoute>.create(
    [
      CoordinatorFirstTab(),
      CoordinatorSecondTab(),
      CoordinatorThirdTab(),
      RedirectNullRoute(),
    ],
    coordinator: this,
    label: 'indexed',
  );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, indexed];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(IndexedStackLayout, IndexedStackLayout.new);
  }

  @override
  FutureOr<IndexedTestRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['first-tab'] => CoordinatorFirstTab(),
      ['second-tab'] => CoordinatorSecondTab(),
      ['third-tab'] => CoordinatorThirdTab(),
      _ => HomeRoute(),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('IndexedStackPath Tests', () {
    test('Initialization with routes', () {
      final routes = [SimpleIndexedRoute('1'), SimpleIndexedRoute('2')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      expect(path.activeIndex, 0);
      expect(path.activeRoute, routes[0]);
    });

    test('goToIndexed switches index', () async {
      final routes = [SimpleIndexedRoute('1'), SimpleIndexedRoute('2')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      await path.goToIndexed(1);

      expect(path.activeIndex, 1);
      expect(path.activeRoute, routes[1]);
    });

    test('activateRoute switches index', () async {
      final routes = [SimpleIndexedRoute('1'), SimpleIndexedRoute('2')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      await path.activateRoute(routes[1]);

      expect(path.activeIndex, 1);
      expect(path.activeRoute, routes[1]);
    });

    test('Guard prevents index change', () async {
      final guardedRoute = GuardedIndexedRoute(allowPop: false);
      final routes = [guardedRoute, SimpleIndexedRoute('2')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      // Verify we are on guarded route
      expect(path.activeIndex, 0);

      // Try to switch index
      await path.goToIndexed(1);

      // Should still be on index 0
      expect(path.activeIndex, 0);
      expect(path.activeRoute, guardedRoute);
    });

    test('Guard allows index change', () async {
      final guardedRoute = GuardedIndexedRoute(allowPop: true);
      final routes = [guardedRoute, SimpleIndexedRoute('2')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      // Try to switch index
      await path.goToIndexed(1);

      // Should switch to index 1
      expect(path.activeIndex, 1);
    });

    test('Redirect works within stack', () async {
      final target = SimpleIndexedRoute('Target');
      final redirectRoute = RedirectIndexedRoute(target: target);

      final routes = [SimpleIndexedRoute('Start'), redirectRoute, target];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      // Switch to redirect route (index 1)
      await path.goToIndexed(1);

      // Should redirect resolved target (index 2)
      expect(path.activeIndex, 2);
      expect(path.activeRoute, target);
    });

    test('Error on invalid index', () {
      final routes = [SimpleIndexedRoute('1')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      expect(() => path.goToIndexed(99), throwsA(isA<StateError>()));
    });

    test('Error on activateRoute with untracked route', () {
      final routes = [SimpleIndexedRoute('1')];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      expect(
        () async => await path.activateRoute(SimpleIndexedRoute('2')),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('Coordinator will do nothing when redirect return null', (
      tester,
    ) async {
      final coordinator = IndexedTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(CoordinatorFirstTab());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('first-tab')), findsOneWidget);

      coordinator.push(CoordinatorSecondTab());
      await tester.pumpAndSettle();

      // Do nothing
      expect(find.byKey(const ValueKey('first-tab')), findsOneWidget);
    });

    testWidgets(
      'Coordinator will switch to resolved route when redirect to outside stack route',
      (tester) async {
        final coordinator = IndexedTestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        coordinator.push(CoordinatorFirstTab());
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('first-tab')), findsOneWidget);

        coordinator.indexed.goToIndexed(2);
        await tester.pumpAndSettle();

        // Do nothing
        expect(find.byKey(const ValueKey('first-tab')), findsOneWidget);
      },
    );

    test('navigate to non-existent route does not throw error', () async {
      final route1 = SimpleIndexedRoute('1');
      final route2 = SimpleIndexedRoute('2');
      final routes = [route1, route2];
      final path = IndexedStackPath<IndexedTestRoute>.create(routes);

      // Set initial state to route1 (index 0)
      expect(path.activeIndex, 0);
      expect(path.activeRoute, route1);

      // Try to navigate to a route that doesn't exist in the stack
      final nonExistentRoute = SimpleIndexedRoute('999');

      // This should not throw an error
      await path.navigate(nonExistentRoute);

      // Should remain on the original route
      expect(path.activeIndex, 0);
      expect(path.activeRoute, route1);
    });

    test('do nothing when redirectWith return null', () async {
      final path = IndexedStackPath<IndexedTestRoute>.createWith(
        [SimpleIndexedRoute('tab1'), RedirectNullRoute()],
        coordinator: IndexedTestCoordinator(),
        label: 'test-navigation',
      );

      path.navigate(RedirectNullRoute());
      await Future.delayed(Duration.zero);

      expect(path.activeIndex, 0);
    });

    test('coordinator do nothing when redirectWith return null', () async {
      final coordinator = IndexedTestCoordinator();

      coordinator.navigate(RedirectNullRoute());
      await Future.delayed(Duration.zero);
      coordinator.recover(RedirectNullRoute());
      await Future.delayed(Duration.zero);
      coordinator.push(RedirectNullRoute());
      await Future.delayed(Duration.zero);
      coordinator.pushOrMoveToTop(RedirectNullRoute());
      await Future.delayed(Duration.zero);
      coordinator.replace(RedirectNullRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.indexed.activeIndex, 0);
    });
  });
}
