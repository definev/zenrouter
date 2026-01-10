import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Setup - Custom Observer for Tracking
// ============================================================================

/// A custom observer that tracks all navigation events
class TrackingNavigatorObserver extends NavigatorObserver {
  final List<String> events = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    events.add('didPush: ${route.settings.name ?? 'unnamed'}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    events.add('didPop: ${route.settings.name ?? 'unnamed'}');
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    events.add('didRemove: ${route.settings.name ?? 'unnamed'}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    events.add(
      'didReplace: ${oldRoute?.settings.name ?? 'unnamed'} -> ${newRoute?.settings.name ?? 'unnamed'}',
    );
  }

  void reset() => events.clear();
}

// ============================================================================
// Test Routes
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }

  @override
  List<Object?> get props => [];
}

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }

  @override
  List<Object?> get props => [];
}

class ProfileRoute extends AppRoute {
  ProfileRoute(this.id);
  final String id;

  @override
  Uri toUri() => Uri.parse('/profile/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Profile $id'));
  }

  @override
  List<Object?> get props => [id];
}

class GuardedRoute extends AppRoute with RouteGuard {
  GuardedRoute({this.allowPop = false});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded');

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Guarded'));
  }

  @override
  List<Object?> get props => [allowPop];
}

// ============================================================================
// Test Coordinators
// ============================================================================

/// Coordinator WITH observer mixin
class CoordinatorWithObservers extends Coordinator<AppRoute>
    with CoordinatorNavigatorObserver {
  CoordinatorWithObservers({this.customObservers = kEmptyObserverList});

  final NavigatorObserverListGetter customObservers;

  @override
  List<NavigatorObserver> get observers => customObservers();

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return HomeRoute();

    return switch (segments) {
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['guarded'] => GuardedRoute(),
      _ => HomeRoute(),
    };
  }
}

/// Coordinator WITHOUT observer mixin
class CoordinatorWithoutObservers extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return HomeRoute();

    return switch (segments) {
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['guarded'] => GuardedRoute(),
      _ => HomeRoute(),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('CoordinatorNavigatorObserver Mixin', () {
    testWidgets('coordinator observers are passed to NavigationStack', (
      tester,
    ) async {
      final coordinatorObserver = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [coordinatorObserver],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // Coordinator observer should receive events
      expect(coordinatorObserver.events.isNotEmpty, isTrue);
    });

    testWidgets(
      'coordinator observers combine with NavigationStack observers',
      (tester) async {
        final coordinatorObserver = TrackingNavigatorObserver();
        final stackObserver = TrackingNavigatorObserver();
        final coordinator = CoordinatorWithObservers(
          customObservers: () => [coordinatorObserver],
        );

        // Create a custom NavigationStack with its own observer
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return NavigationStack<AppRoute>(
                  path: coordinator.root,
                  coordinator: coordinator,
                  observers: [stackObserver],
                  resolver: (route) => StackTransition.material(
                    route.build(coordinator, context),
                  ),
                );
              },
            ),
          ),
        );

        coordinator.root.push(HomeRoute());
        await tester.pumpAndSettle();

        // Both observers should receive events
        expect(coordinatorObserver.events.isNotEmpty, isTrue);
        expect(stackObserver.events.isNotEmpty, isTrue);

        // Verify they received the same events
        expect(coordinatorObserver.events.length, stackObserver.events.length);
      },
    );

    testWidgets('multiple coordinator observers receive notifications', (
      tester,
    ) async {
      final observer1 = TrackingNavigatorObserver();
      final observer2 = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer1, observer2],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      // Both observers should receive the same events
      expect(observer1.events.isNotEmpty, isTrue);
      expect(observer2.events.isNotEmpty, isTrue);
      expect(observer1.events, equals(observer2.events));
    });

    testWidgets('observers track push operations', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      observer.reset();

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      // Should have didPush events
      final pushEvents = observer.events.where((e) => e.startsWith('didPush'));
      expect(pushEvents.isNotEmpty, isTrue);
    });

    testWidgets('observers track pop operations', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      observer.reset();

      coordinator.pop();
      await tester.pumpAndSettle();

      // Should have didPop events
      final popEvents = observer.events.where((e) => e.startsWith('didPop'));
      expect(popEvents.isNotEmpty, isTrue);
    });

    testWidgets('observers work with RouteGuard', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      coordinator.push(GuardedRoute(allowPop: false));
      await tester.pumpAndSettle();

      observer.reset();

      // Try to pop - should be blocked by guard
      await coordinator.tryPop();
      await tester.pumpAndSettle();

      // Should NOT have didPop events since guard blocked it
      final popEvents = observer.events.where((e) => e.startsWith('didPop'));
      expect(popEvents.isEmpty, isTrue);
    });

    testWidgets('empty observers list works correctly', (tester) async {
      final coordinator = CoordinatorWithObservers();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      // Should not throw, navigation should work normally
      expect(coordinator.root.stack.length, 2);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('NavigationStack Observer Integration', () {
    testWidgets('uses coordinator observers when coordinator has mixin', (
      tester,
    ) async {
      final coordinatorObserver = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [coordinatorObserver],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return NavigationStack<AppRoute>(
                path: coordinator.root,
                coordinator: coordinator,
                resolver: (route) =>
                    StackTransition.material(route.build(coordinator, context)),
              );
            },
          ),
        ),
      );

      coordinator.root.push(HomeRoute());
      await tester.pumpAndSettle();

      // Coordinator observer should receive events
      expect(coordinatorObserver.events.isNotEmpty, isTrue);
    });

    testWidgets('uses only local observers when coordinator lacks mixin', (
      tester,
    ) async {
      final stackObserver = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithoutObservers();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return NavigationStack<AppRoute>(
                path: coordinator.root,
                coordinator: coordinator,
                observers: [stackObserver],
                resolver: (route) =>
                    StackTransition.material(route.build(coordinator, context)),
              );
            },
          ),
        ),
      );

      coordinator.root.push(HomeRoute());
      await tester.pumpAndSettle();

      // Stack observer should receive events
      expect(stackObserver.events.isNotEmpty, isTrue);
    });

    testWidgets('observers update when coordinator changes', (tester) async {
      final observer1 = TrackingNavigatorObserver();
      final coordinator1 = CoordinatorWithObservers(
        customObservers: () => [observer1],
      );

      // Start with coordinator1
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return NavigationStack<AppRoute>(
                path: coordinator1.root,
                coordinator: coordinator1,
                resolver: (route) => StackTransition.material(
                  route.build(coordinator1, context),
                ),
              );
            },
          ),
        ),
      );

      final initialEventsCount = observer1.events.length;

      coordinator1.root.push(HomeRoute());
      await tester.pumpAndSettle();
      coordinator1.root.push(SettingsRoute());
      await tester.pumpAndSettle();
      coordinator1.root.pop();
      await tester.pumpAndSettle();

      expect(observer1.events.length - initialEventsCount, 3);
    });

    testWidgets('observers update when local observers list changes', (
      tester,
    ) async {
      final observer1 = TrackingNavigatorObserver();
      final observer2 = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithoutObservers();

      // Start with observer1
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return NavigationStack<AppRoute>(
                path: coordinator.root,
                coordinator: coordinator,
                observers: [observer1],
                resolver: (route) =>
                    StackTransition.material(route.build(coordinator, context)),
              );
            },
          ),
        ),
      );

      coordinator.root.push(HomeRoute());
      await tester.pumpAndSettle();

      expect(observer1.events.isNotEmpty, isTrue);
      expect(observer2.events.isEmpty, isTrue);

      observer1.reset();
      observer2.reset();

      // Switch to observer2
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return NavigationStack<AppRoute>(
                path: coordinator.root,
                coordinator: coordinator,
                observers: [observer2],
                resolver: (route) =>
                    StackTransition.material(route.build(coordinator, context)),
              );
            },
          ),
        ),
      );

      coordinator.root.push(SettingsRoute());
      await tester.pumpAndSettle();

      // Now observer2 should receive events, not observer1
      expect(observer1.events.isEmpty, isTrue);
      expect(observer2.events.isNotEmpty, isTrue);
    });

    testWidgets(
      'NavigationStack without coordinator uses only local observers',
      (tester) async {
        final stackObserver = TrackingNavigatorObserver();
        final path = NavigationPath<AppRoute>.create();

        await tester.pumpWidget(
          MaterialApp(
            home: NavigationStack<AppRoute>(
              path: path,
              observers: [stackObserver],
              resolver: (route) =>
                  StackTransition.material(const Scaffold(body: Text('Test'))),
            ),
          ),
        );

        path.push(HomeRoute());
        await tester.pumpAndSettle();

        // Stack observer should receive events
        expect(stackObserver.events.isNotEmpty, isTrue);
      },
    );
  });

  group('Observer Lifecycle with Complex Navigation', () {
    testWidgets('observers track multiple push/pop operations', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      observer.reset();

      // Build a stack: Home -> Settings -> Profile
      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      coordinator.push(ProfileRoute('1'));
      await tester.pumpAndSettle();

      final pushCount = observer.events
          .where((e) => e.startsWith('didPush'))
          .length;
      expect(pushCount, greaterThan(0));

      observer.reset();

      // Pop back to Settings
      coordinator.pop();
      await tester.pumpAndSettle();

      final popCount = observer.events
          .where((e) => e.startsWith('didPop'))
          .length;
      expect(popCount, greaterThan(0));
    });

    testWidgets('observers track navigation with replace', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      observer.reset();

      // Replace with a different route
      coordinator.replace(SettingsRoute());
      await tester.pumpAndSettle();

      // Should have events from the replace operation
      expect(observer.events.isNotEmpty, isTrue);
    });

    testWidgets('observers work correctly with pushOrMoveToTop', (
      tester,
    ) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      final homeRoute = HomeRoute();
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      observer.reset();

      // Push or move to top - should move existing route
      coordinator.pushOrMoveToTop(homeRoute);
      await tester.pumpAndSettle();

      // Observer should track this operation
      expect(observer.events.isNotEmpty, isTrue);
    });
  });

  group('Observer Edge Cases', () {
    testWidgets('observers handle rapid navigation changes', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      observer.reset();

      // Rapid navigation
      coordinator.push(SettingsRoute());
      coordinator.push(ProfileRoute('1'));
      coordinator.push(ProfileRoute('2'));
      await tester.pumpAndSettle();

      // All events should be tracked
      expect(observer.events.isNotEmpty, isTrue);
      final pushCount = observer.events
          .where((e) => e.startsWith('didPush'))
          .length;
      expect(pushCount, greaterThanOrEqualTo(3));
    });

    testWidgets('observers work with nested navigation', (tester) async {
      final observer = TrackingNavigatorObserver();
      final coordinator = CoordinatorWithObservers(
        customObservers: () => [observer],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      observer.reset();

      // Push multiple routes
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      coordinator.push(ProfileRoute('1'));
      await tester.pumpAndSettle();

      // Observer should track all navigation
      expect(observer.events.isNotEmpty, isTrue);
    });
  });
}
