import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Setup (Duplicated from coordinator_router_delegate_test.dart)
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }

  @override
  List<Object?> get props => [];
}

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
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
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Profile $id'));
  }

  @override
  List<Object?> get props => [id];
}

class TabLayout extends AppRoute with RouteLayout {
  @override
  StackPath<RouteUnique> resolvePath(TestCoordinator coordinator) =>
      coordinator.tabStack;
}

class HomeTab extends AppRoute {
  @override
  Type? get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/home');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home Tab'));
  }

  @override
  List<Object?> get props => [];
}

class SearchTab extends AppRoute {
  @override
  Type? get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/search');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Search Tab'));
  }

  @override
  List<Object?> get props => [];
}

class SettingsLayout extends AppRoute with RouteLayout {
  @override
  StackPath<RouteUnique> resolvePath(TestCoordinator coordinator) =>
      coordinator.settingsStack;
}

class SettingsPageRoute extends AppRoute {
  @override
  Type? get layout => SettingsLayout;

  @override
  Uri toUri() => Uri.parse('/settings-page');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings Page'));
  }

  @override
  List<Object?> get props => [];
}

class RedirectRoute extends AppRoute with RouteRedirect<AppRoute> {
  RedirectRoute(this.target);
  final AppRoute target;

  @override
  Uri toUri() => Uri.parse('/redirect');

  @override
  FutureOr<AppRoute> redirect() => target;

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const SizedBox();
  }

  @override
  List<Object?> get props => [target];
}

class RedirectNullRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/redirect-null');

  @override
  FutureOr<AppRoute?> redirectWith(Coordinator coordinator) => null;

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const SizedBox();
  }
}

class GuardRoute extends AppRoute with RouteGuard {
  GuardRoute({this.allowPop = true, this.layout});
  final bool allowPop;

  @override
  final Type? layout;

  @override
  Uri toUri() => Uri.parse('/guard');

  @override
  FutureOr<bool> popGuard() => allowPop;

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const SizedBox();
  }

  @override
  List<Object?> get props => [allowPop];
}

class TestCoordinator extends Coordinator<AppRoute> {
  late final IndexedStackPath<AppRoute> tabStack = IndexedStackPath.createWith(
    [HomeTab(), SearchTab()],
    coordinator: this,
    label: 'tabs',
  )..bindLayout(TabLayout.new);

  late final NavigationPath<AppRoute> settingsStack = NavigationPath.createWith(
    coordinator: this,
    label: 'settings',
  )..bindLayout(SettingsLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, tabStack, settingsStack];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return HomeRoute(); // Not used in these tests
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('Coordinator.pushOrMoveToTop', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('pushes new route to root stack', () async {
      final route = SettingsRoute();
      coordinator.pushOrMoveToTop(route);

      // Wait for async operations (redirect resolution, layout resolution)
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, route);
    });

    test('moves existing route to top of root stack', () async {
      final home = HomeRoute();
      final settings = SettingsRoute();

      coordinator.push(home);
      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.map((r) => r.runtimeType), [
        HomeRoute,
        SettingsRoute,
      ]);

      // Move Home to top
      coordinator.pushOrMoveToTop(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.map((r) => r.runtimeType), [
        SettingsRoute,
        HomeRoute,
      ]);
    });

    test('resolves redirects before pushing', () async {
      final target = SettingsRoute();
      final redirect = RedirectRoute(target);

      coordinator.pushOrMoveToTop(redirect);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
    });

    test('activates route in IndexedStackPath (switching tabs)', () async {
      // Initial state: HomeTab is active (index 0)
      expect(coordinator.tabStack.activeRoute, isA<HomeTab>());

      // Push SearchTab (index 1) via coordinator
      coordinator.pushOrMoveToTop(SearchTab());
      await Future.delayed(Duration.zero);

      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
      expect(coordinator.tabStack.activeIndex, 1);
    });

    test('resolves layout before pushing (implicit path selection)', () async {
      // Pushing a tab route should target the tabStack, not root
      final searchTab = SearchTab();

      coordinator.pushOrMoveToTop(searchTab);
      await Future.delayed(Duration.zero);

      // Root should contain the layout (TabLayout)
      expect(coordinator.root.stack.last, isA<TabLayout>());

      // But Root should NOT contain the SearchTab
      expect(coordinator.root.stack.whereType<SearchTab>(), isEmpty);

      // Tab stack should have switched
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });

    test(
      'pushOrMoveToTop works with same route on top (idempotent-ish)',
      () async {
        final route = SettingsRoute();
        coordinator.push(route);
        await Future.delayed(Duration.zero);

        expect(coordinator.root.stack.length, 1);

        coordinator.pushOrMoveToTop(SettingsRoute());
        await Future.delayed(Duration.zero);

        expect(coordinator.root.stack.length, 1);
        expect(coordinator.root.stack.last, isA<SettingsRoute>());
      },
    );
  });

  group('Coordinator.push', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('pushes new route to stack', () async {
      final route = SettingsRoute();
      coordinator.push(route);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, route);
    });

    test('pushes duplicate route to stack (unlike pushOrMoveToTop)', () async {
      final home = HomeRoute();
      coordinator.push(home);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);

      // Push another HomeRoute
      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack[0], isA<HomeRoute>());
      expect(coordinator.root.stack[1], isA<HomeRoute>());
    });

    test('resolves layout and pushes to correct path', () async {
      final searchTab = SearchTab();
      coordinator.push(searchTab);
      await Future.delayed(Duration.zero);

      // Root should imply the layout exists
      expect(coordinator.root.stack.last, isA<TabLayout>());

      // Tab stack should be active on the correct tab
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });
  });

  group('Coordinator.replace', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('replaces entire stack with new route', () async {
      // Setup initial stack
      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);
      coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);

      // Replace with Profile
      final profile = ProfileRoute('1');
      coordinator.replace(profile);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, profile);
    });

    test('resets all paths (including tabs) when replacing', () async {
      // 1. Go to Search Tab (index 1)
      coordinator.push(SearchTab());
      await Future.delayed(Duration.zero);
      expect(coordinator.tabStack.activeIndex, 1);

      // 2. Replace with HomeRoute (root path)
      coordinator.replace(HomeRoute());
      await Future.delayed(Duration.zero);

      // Root should have HomeRoute
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, isA<HomeRoute>());

      // Tab stack should be reset (index 0)
      expect(coordinator.tabStack.activeIndex, 0);
    });
  });

  group('Coordinator.tryPop', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('pops correctly when RouteGuard allows pop', () async {
      // Setup: Home -> GuardRoute(allowPop: true)
      final home = HomeRoute();
      final guard = GuardRoute(allowPop: true);

      coordinator.push(home);
      coordinator.push(guard);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, guard);

      // tryPop should work
      final result = await coordinator.tryPop();

      expect(result, isTrue);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, home);
    });

    test('blocks pop when RouteGuard rejects pop', () async {
      // Setup: Home -> GuardRoute(allowPop: false)
      final home = HomeRoute();
      final guard = GuardRoute(allowPop: false);

      coordinator.push(home);
      coordinator.push(guard);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, guard);

      // tryPop should fail
      final result = await coordinator.tryPop();

      expect(result, isFalse);
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, guard);
    });

    test('pops normally when no RouteGuard is present', () async {
      // Setup: Home -> Settings
      final home = HomeRoute();
      final settings = SettingsRoute();

      coordinator.push(home);
      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);

      // tryPop should work
      final result = await coordinator.tryPop();

      expect(result, isTrue);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, home);
    });

    test('returns false when stack cannot be popped (length 1)', () async {
      // Setup: Home only
      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);

      // tryPop should return false (nothing to pop)
      final result = await coordinator.tryPop();

      expect(result, isFalse);
      expect(coordinator.root.stack.length, 1);
    });
  });

  group('Coordinator.pushReplacement', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    testWidgets('pushes to empty stack', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push replacement on empty stack should just push
      final route = SettingsRoute();
      coordinator.pushReplacement(route);
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, route);
    });

    testWidgets('replaces single element stack and completes result', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push first route
      final home = coordinator.root.stack.first;
      final homeResult = home.onResult.future;
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, home);

      // Push replacement with result
      final settings = SettingsRoute();
      coordinator.pushReplacement<String, String>(settings, result: 'replaced');
      await tester.pumpAndSettle();

      // Stack should now have only settings
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, settings);

      // home should have received the result
      expect(await homeResult, 'replaced');
      expect(home.onResult.isCompleted, true);
    });

    testWidgets(
      'replaces top route when stack has multiple elements and completes result',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Push routes
        final settings = SettingsRoute();
        final settingsResult = coordinator.push(settings);
        await tester.pumpAndSettle();

        expect(coordinator.root.stack.length, 2);

        // Push replacement - should pop settings and push profile
        final profile = ProfileRoute('1');
        coordinator.pushReplacement<String, String>(profile, result: 'popped');
        await tester.pumpAndSettle();

        // Stack should have home and profile
        expect(coordinator.root.stack.length, 2);
        expect(coordinator.root.stack[1], profile);

        // settings should have received the result
        expect(await settingsResult, 'popped');
        expect(settings.onResult.isCompleted, true);
      },
    );

    testWidgets('handles redirect and replaces correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push first route
      final home = coordinator.root.stack.first;
      final homeResult = home.onResult.future;
      await tester.pumpAndSettle();

      // Push replacement with redirect - should redirect to target
      final target = SettingsRoute();
      final redirect = RedirectRoute(target);
      coordinator.pushReplacement(redirect);
      await tester.pumpAndSettle();

      // Stack should have only the target (not the redirect)
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<SettingsRoute>());
      expect(coordinator.root.stack.first, isNot(isA<RedirectRoute>()));
      expect(await homeResult, null);
    });

    testWidgets('respects guard that blocks pop during replacement', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push routes
      final home = coordinator.root.stack.first;
      final guard = GuardRoute(allowPop: false);
      coordinator.push(guard);
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 2);

      // Push replacement - should be blocked by guard
      final settings = SettingsRoute();
      final result = await coordinator.pushReplacement(settings);
      await tester.pumpAndSettle();

      // Guard blocked pop, so replacement should fail
      expect(result, isNull);
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack[0], home);
      expect(coordinator.root.stack[1], guard);
    });

    testWidgets('respects guard that allows pop during replacement', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push routes
      final home = coordinator.root.stack.first;

      final guard = GuardRoute(allowPop: true);
      final guardResult = coordinator.push(guard);
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 2);

      // Push replacement - guard should allow pop
      final settings = SettingsRoute();
      coordinator.pushReplacement<String, String>(settings, result: 'popped');
      await tester.pumpAndSettle();

      // Guard allowed, replacement should succeed
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack[0], home);
      expect(coordinator.root.stack[1], settings);
      expect(await guardResult, 'popped');
    });

    testWidgets('pushReplacement with Redirect to null should do nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push routes
      final home = coordinator.root.stack.first;

      final redirectNull = RedirectNullRoute();
      final guardResult = await coordinator.pushReplacement(redirectNull);
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack[0], home);
      expect(guardResult, isNull);
    });

    testWidgets(
      'pushReplacement with Redirect to null should do nothing if called in path',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Push routes
        final home = coordinator.root.stack.first;

        final redirectNull = RedirectNullRoute();
        final guardResult = await coordinator.root.pushReplacement(
          redirectNull,
        );
        await tester.pumpAndSettle();

        expect(coordinator.root.stack.length, 1);
        expect(coordinator.root.stack[0], home);
        expect(guardResult, isNull);
      },
    );

    testWidgets('pushReplacement with different layout replaces correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push a root route (SettingsRoute)
      final settingRootPage = SettingsRoute();
      final result = coordinator.push(settingRootPage);
      await tester.pumpAndSettle();

      // Verify initial state: SettingsRoute is active
      expect(coordinator.root.stack.last, isA<SettingsRoute>());

      // Push replacement with a route that has different layout (SettingsLayout)
      final settingsPage = SettingsPageRoute();
      final result2 = coordinator.pushReplacement(settingsPage, result: 'test');
      await tester.pumpAndSettle();

      // Stack should have the new layout and route
      expect(await result, 'test');
      expect(coordinator.root.stack.last, isA<SettingsLayout>());
      expect(coordinator.settingsStack.activeRoute, isA<SettingsPageRoute>());

      final settingsPage2 = SettingsRoute();
      coordinator.pushReplacement(settingsPage2, result: 'test');
      await tester.pumpAndSettle();

      expect(await result2, 'test');
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
      expect(coordinator.settingsStack.stack.isEmpty, true);

      final guardPage = GuardRoute(allowPop: false);
      coordinator.push(guardPage);
      await tester.pumpAndSettle();
      expect(coordinator.root.stack.last, isA<GuardRoute>());

      final settingRoot2Page = SettingsPageRoute();
      coordinator.pushReplacement(settingRoot2Page, result: 'test');
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.last, isA<GuardRoute>());
      expect(coordinator.settingsStack.stack.isEmpty, true);
    });
  });
}
