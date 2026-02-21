import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Setup
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant StrictCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }

  @override
  List<Object?> get props => [];
}

class ParentCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {};

  @override
  AppRoute? parseRouteFromUri(Uri uri) => HomeRoute();

  @override
  AppRoute notFoundRoute(Uri uri) => HomeRoute();
}

class StrictCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  StrictCoordinator({required this.parent});
  final CoordinatorModular<AppRoute> parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => parent;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {};

  @override
  AppRoute notFoundRoute(Uri uri) => HomeRoute();

  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  );

  @override
  List<StackPath> get paths => [...super.paths, homeStack];

  @override
  AppRoute? parseRouteFromUri(Uri uri) {
    if (uri.path == '/') return HomeRoute();
    // Intentionally return null for any other route to trigger assertion
    return null;
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  testWidgets(
    'CoordinatorRouterDelegate asserts when parseRouteFromUri returns null for unknown route',
    (tester) async {
      final parent = ParentCoordinator();
      final coordinator = StrictCoordinator(parent: parent);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Initial route
      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // Attempt to navigate to an unknown route
      // This should trigger the assertion because parseRouteFromUri returns null
      final unknownUri = Uri.parse('/unknown');

      expect(
        () async =>
            await coordinator.routerDelegate.setNewRoutePath(unknownUri),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains(
              'You must to provide a parse route for $unknownUri in [parseRouteFromUri] to use deeplink to it',
            ),
          ),
        ),
      );
      expect(
        () async => await coordinator.recoverRouteFromUri(unknownUri),
        throwsA(isA<StateError>()),
      );
    },
  );
}
