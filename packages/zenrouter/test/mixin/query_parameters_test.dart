import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Use a simple concrete implementation for testing
class TestRoute extends RouteTarget with RouteUnique, RouteQueryParameters {
  TestRoute({Map<String, String>? initialQueries})
    : queryNotifier = ValueNotifier(initialQueries ?? {});

  @override
  final ValueNotifier<Map<String, String>> queryNotifier;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: queryNotifier,
      builder: (context, queries, _) {
        return Text('Queries: ${queries.toString()}');
      },
    );
  }

  @override
  Uri toUri() {
    return Uri(path: '/test', queryParameters: queries);
  }

  @override
  List<Object?> get props => [];
}

class TabLayout extends TestRoute with RouteLayout {
  @override
  IndexedStackPath<TestRoute> resolvePath(
    covariant TestCoordinator coordinator,
  ) => coordinator.tabIndexed;
}

class FirstTab extends TestRoute {
  FirstTab({super.initialQueries});

  @override
  Type? get layout => TabLayout;

  @override
  Uri toUri() => Uri(path: '/test', queryParameters: queries);

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return ValueListenableBuilder(
      valueListenable: queryNotifier,
      builder: (context, queries, _) => Column(
        children: [Text('FirstTab'), Text('Queries: ${queries.toString()}')],
      ),
    );
  }
}

class SecondTab extends TestRoute {
  @override
  Type? get layout => TabLayout;
}

class TestCoordinator extends Coordinator<RouteUnique> {
  RouteUnique? _parsedRoute;

  late final tabIndexed = IndexedStackPath.createWith(
    [FirstTab(), SecondTab()],
    coordinator: this,
    label: 'tab',
  );

  void setParsedRoute(RouteUnique route) {
    _parsedRoute = route;
  }

  @override
  void defineLayout() {
    defineLayoutParent(TabLayout.new);
  }

  @override
  RouteUnique parseRouteFromUri(Uri uri) {
    return _parsedRoute ?? TestRoute(initialQueries: uri.queryParameters);
  }
}

void main() {
  group('RouteQueryParameters Mixin', () {
    late TestRoute route;
    late TestCoordinator coordinator;

    setUp(() {
      route = TestRoute();
      coordinator = TestCoordinator();
    });

    test('initializes with empty queries', () {
      expect(route.queries, isEmpty);
      expect(route.queryNotifier.value, isEmpty);
    });

    test('update queries via property setter', () {
      route.queries = {'foo': 'bar'};
      expect(route.queries, {'foo': 'bar'});
      expect(route.queryNotifier.value, {'foo': 'bar'});
      expect(route.query('foo'), 'bar');
    });

    test('query() returns value or null', () {
      route.queries = {'a': '1', 'b': '2'};
      expect(route.query('a'), '1');
      expect(route.query('b'), '2');
      expect(route.query('c'), isNull);
    });

    test('updateQueries updates notifier', () {
      route.updateQueries(coordinator, queries: {'x': 'y'});
      expect(route.queries, {'x': 'y'});
    });

    testWidgets('active route does not trigger navigation on updateQueries', (
      tester,
    ) async {
      // Setup coordinator with the route active
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.root.push(route);
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Queries: {}'), findsOneWidget);

      // Update queries
      route.updateQueries(coordinator, queries: {'updated': 'true'});
      await tester.pump(); // Rebuild from ValueListenable

      // Verify updated state
      expect(find.text('Queries: {updated: true}'), findsOneWidget);
    });

    testWidgets('Route identity remains same when queries change', (
      tester,
    ) async {
      final route1 = TestRoute();
      final route2 = TestRoute(initialQueries: {'a': 'b'});

      // Since props excludes queries, they should be equal if props are empty
      expect(route1, route2);

      route1.queries = {'c': 'd'};
      expect(route1, route2);
    });

    testWidgets('selectorBuilder rebuilds only when selected value changes', (
      tester,
    ) async {
      final route = TestRoute(initialQueries: {'page': '1', 'sort': 'asc'});
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: route.selectorBuilder<String>(
            selector: (queries) => queries['page'] ?? '',
            builder: (context, page) {
              buildCount++;
              return Text('Page: $page');
            },
          ),
        ),
      );

      expect(find.text('Page: 1'), findsOneWidget);
      expect(buildCount, 1);

      // Update unrelated query
      route.queries = {'page': '1', 'sort': 'desc'};
      await tester.pump();

      expect(buildCount, 1);
      expect(find.text('Page: 1'), findsOneWidget);

      // Update related query
      route.queries = {'page': '2', 'sort': 'desc'};
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Page: 2'), findsOneWidget);
    });

    testWidgets('updateQueries calls navigate if route is not active', (
      tester,
    ) async {
      final routeA = TestRoute()..queries = {'id': 'A'};

      // Need a second route type or property to distinguish them for navigation stack
      // Since props implies equality, we need to distinct them?
      // No, we can just push two instances. If they are equal, `navigate` is tricky.
      // Let's make TestRoute have an ID in props for this test.

      final routeB = TestRoute2(); // Different type or ID

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.root.push(routeA);
      await tester.pumpAndSettle();

      coordinator.root.push(routeB);
      await tester.pumpAndSettle();

      // Now RouteB is active. RouteA is in stack but inactive.
      expect(find.text('RouteB'), findsOneWidget);
      expect(coordinator.activePath.activeRoute, routeB);

      // Update queries on RouteA
      routeA.updateQueries(coordinator, queries: {'id': 'A', 'updated': 'yes'});

      await tester.pumpAndSettle();

      // Should have navigated to RouteA and updated text
      expect(find.text('Queries: {id: A, updated: yes}'), findsOneWidget);
      expect(coordinator.activePath.activeRoute, routeA);
    });

    testWidgets('updateQueries work in IndexedStackPath with navigate', (
      tester,
    ) async {
      final route = FirstTab(initialQueries: {'id': 'A'});

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(route);
      await tester.pumpAndSettle();

      expect(find.text('FirstTab'), findsOneWidget);
      expect(coordinator.activePath.activeRoute, route);
      expect(
        (coordinator.activePath.activeRoute as TestRoute).queryNotifier.value,
        {'id': 'A'},
      );

      final newRoute = FirstTab(initialQueries: {'id': 'A', 'updated': 'yes'});
      expect(newRoute.queryNotifier.value, {'id': 'A', 'updated': 'yes'});
      coordinator.navigate(newRoute);
      await tester.pumpAndSettle();

      expect(find.text('FirstTab'), findsOneWidget);
      expect(coordinator.activePath.activeRoute, route);
      expect(
        (coordinator.activePath.activeRoute as TestRoute).queryNotifier.value,
        {'id': 'A', 'updated': 'yes'},
      );
      // Completed the previous route
      expect(newRoute.onResult.isCompleted, true);
      expect(
        () => newRoute.queryNotifier.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });

    test('disposes notifier on didPop', () {
      route.onDidPop(null, coordinator);
      expect(
        () => route.queryNotifier.addListener(() {}),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.message,
            'message',
            contains('disposed'),
          ),
        ),
      );
    });
  });
}

class TestRoute2 extends RouteTarget with RouteUnique {
  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return const Text('RouteB');
  }

  @override
  List<Object?> get props => ['B'];

  @override
  Uri toUri() => Uri(path: '/b');
}
