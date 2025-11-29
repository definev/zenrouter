import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Test coordinator and routes
class TestCoordinator extends Coordinator<TestAppRoute> {
  @override
  TestAppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeTestRoute(),
      ['page'] => PageTestRoute(),
      _ => HomeTestRoute(),
    };
  }
}

sealed class TestAppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(TestCoordinator coordinator) => coordinator.root;
}

class HomeTestRoute extends TestAppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }
}

class PageTestRoute extends TestAppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/page');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Page'));
  }
}

class RedirectTestRoute extends TestAppRoute with RouteRedirect<TestAppRoute> {
  @override
  Uri toUri() => Uri.parse('/redirect');

  @override
  FutureOr<TestAppRoute> redirect() => HomeTestRoute();
}

class AsyncRedirectRoute extends TestAppRoute with RouteRedirect<TestAppRoute> {
  @override
  Uri toUri() => Uri.parse('/async-redirect');

  @override
  Future<TestAppRoute> redirect() async {
    await Future.delayed(const Duration(milliseconds: 5));
    return PageTestRoute();
  }
}

class DeepLinkTestRoute extends TestAppRoute with RouteBuilder, RouteDeepLink {
  @override
  Uri toUri() => Uri.parse('/deeplink');

  @override
  FutureOr<void> deeplinkHandler(TestCoordinator coordinator, Uri uri) async {
    // Custom deep link handling
    coordinator.replace(HomeTestRoute());
  }

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('DeepLink'));
  }
}

void main() {
  group('CoordinatorRouteParser', () {
    test('parseRouteInformation converts RouteInformation to Uri', () async {
      final coordinator = TestCoordinator();
      final parser = coordinator.parser;

      final routeInfo = RouteInformation(uri: Uri.parse('/page'));
      final result = await parser.parseRouteInformation(routeInfo);

      expect(result, equals(Uri.parse('/page')));
    });

    test('restoreRouteInformation converts Uri to RouteInformation', () {
      final coordinator = TestCoordinator();
      final parser = coordinator.parser;

      final uri = Uri.parse('/page');
      final result = parser.restoreRouteInformation(uri);

      expect(result?.uri, equals(uri));
    });
  });

  group('CoordinatorRouterDelegate', () {
    testWidgets('build returns Navigator with pages', (tester) async {
      final coordinator = TestCoordinator();
      unawaited(coordinator.push(HomeTestRoute()));

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.parser,
        ),
      );

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('setNewRoutePath updates navigation', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.parser,
        ),
      );
      await tester.pumpAndSettle();

      await coordinator.routerDelegate.setNewRoutePath(Uri.parse('/page'));
      await tester.pumpAndSettle();

      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('currentConfiguration returns current URI', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.parser,
        ),
      );
      unawaited(coordinator.push(PageTestRoute()));
      await tester.pumpAndSettle();

      final config = coordinator.routerDelegate.currentConfiguration;
      expect(config?.path, '/page');
    });

    testWidgets('popRoute pops route from coordinator', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.parser,
        ),
      );
      unawaited(coordinator.push(PageTestRoute()));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 2);

      await coordinator.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 1);
    });
  });

  group('Coordinator - Advanced Features', () {
    testWidgets('rootBuilder provides navigator widget', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final widget = coordinator.rootBuilder(context);
              expect(widget, isA<NavigationStack>());
              return Container();
            },
          ),
        ),
      );
    });

    test('recoverRouteFromUri with redirects', () async {
      final coordinator = TestCoordinator();
      final redirect = RedirectTestRoute();

      unawaited(coordinator.push(redirect));
      await Future.delayed(const Duration(milliseconds: 10));

      // Should have redirected to HomeTestRoute
      expect(coordinator.root.stack.last, isA<HomeTestRoute>());
    });

    test('async redirect handling', () async {
      final coordinator = TestCoordinator();
      final asyncRedirect = AsyncRedirectRoute();

      unawaited(coordinator.push(asyncRedirect));
      await Future.delayed(const Duration(milliseconds: 20));

      // Should have redirected to PageTestRoute
      expect(coordinator.root.stack.last, isA<PageTestRoute>());
    });

    test('deep link handler is called', () async {
      final coordinator = TestCoordinator();
      final deepLink = DeepLinkTestRoute();

      // Manually test deeplink handler
      await deepLink.deeplinkHandler(coordinator, Uri.parse('/deeplink'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<HomeTestRoute>());
    });

    test('currentUri reflects active route', () async {
      final coordinator = TestCoordinator();
      unawaited(coordinator.push(PageTestRoute()));
      await Future.delayed(Duration.zero);

      expect(coordinator.currentUri.path, '/page');
    });

    test('currentUri returns / when stack is empty', () {
      final coordinator = TestCoordinator();

      expect(coordinator.currentUri.path, '/');
    });
  });

  group('CoordinatorUtils', () {
    test('extension methods work on coordinator', () {
      final coordinator = TestCoordinator();

      // Test that coordinator can be passed to extension methods
      expect(coordinator.root, isA<NavigationPath>());
      expect(coordinator.paths, contains(coordinator.root));
    });
  });

  group('RouteUnique', () {
    test('getPath returns correct navigation path', () {
      final coordinator = TestCoordinator();
      final route = HomeTestRoute();

      final path = route.getPath(coordinator);
      expect(path, equals(coordinator.root));
    });
  });

  group('RouteBuilder', () {
    test('destination returns RouteDestination', () {
      final coordinator = TestCoordinator();
      final route = HomeTestRoute();

      final dest = route.destination(coordinator);
      expect(dest, isA<RouteDestination>());
    });

    test('builder creates widget', () {
      final coordinator = TestCoordinator();
      final route = HomeTestRoute();

      final widget = route.builder(coordinator);
      expect(widget, isA<Widget>());
    });
  });
}
