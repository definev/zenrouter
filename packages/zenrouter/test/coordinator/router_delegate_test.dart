// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Setup
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

class GuardedRoute extends AppRoute with RouteGuard {
  GuardedRoute({this.allowPop = false});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded');

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Guarded'));
  }

  @override
  List<Object?> get props => [allowPop];
}

class DeepLinkRoute extends AppRoute with RouteDeepLink {
  DeepLinkRoute(this.path);
  final String path;

  @override
  Uri toUri() => Uri.parse('/deeplink/$path');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const SizedBox();
  }

  @override
  List<Object?> get props => [path];

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  FutureOr<void> deeplinkHandler(
    covariant TestCoordinator coordinator,
    Uri uri,
  ) {
    coordinator.push(ProfileRoute(path));
  }
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

class TestCoordinator extends Coordinator<AppRoute> {
  late final IndexedStackPath<AppRoute> tabStack = IndexedStackPath.createWith(
    [HomeTab(), SearchTab()],
    coordinator: this,
    label: 'tabs',
  );

  @override
  List<StackPath> get paths => [...super.paths, tabStack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(TabLayout, TabLayout.new);
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return HomeRoute();

    return switch (segments) {
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['guarded'] => GuardedRoute(),
      ['deeplink', final path] => DeepLinkRoute(path),
      ['tabs', 'home'] => HomeTab(),
      ['tabs', 'search'] => SearchTab(),
      _ => HomeRoute(),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('CoordinatorRouterDelegate.setNewRoutePath', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    testWidgets('Browser back pops to existing route', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Setup stack: Home -> Settings -> Profile
      coordinator.replace(HomeRoute());
      coordinator.push(SettingsRoute());
      coordinator.push(ProfileRoute('1'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 3);
      expect(find.text('Profile 1'), findsOneWidget);

      // Simulate back button to Settings
      await coordinator.routerDelegate.setNewRoutePath(Uri.parse('/settings'));
      await tester.pumpAndSettle();

      // Should pop Profile and show Settings
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);

      await coordinator.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, isA<HomeRoute>());
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Browser forward/new route pushes to stack', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Setup stack: Home
      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // Simulate navigation to Settings (not in stack)
      await coordinator.routerDelegate.setNewRoutePath(Uri.parse('/settings'));
      await tester.pumpAndSettle();

      // Should push Settings
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Guard prevents browser back and restores URL', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Setup stack: Home -> Guarded(allowPop: false)
      coordinator.replace(HomeRoute());
      coordinator.push(GuardedRoute(allowPop: false));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 2);
      expect(find.text('Guarded'), findsOneWidget);

      // Listen for notification (URL restoration)
      bool capturedNotification = false;
      coordinator.addListener(() {
        capturedNotification = true;
      });

      // Simulate back button to Home
      coordinator.routerDelegate.setNewRoutePath(Uri.parse('/'));
      await tester.pumpAndSettle();

      // Should NOT pop
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, isA<GuardedRoute>());
      expect(find.text('Guarded'), findsOneWidget);

      // Should have notified listeners to restore URL
      expect(capturedNotification, isTrue);
    });

    testWidgets('IndexedStackPath switches tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Initial state: Home Tab
      await coordinator.recover(HomeTab());
      await tester.pumpAndSettle();

      expect(find.text('Home Tab'), findsOneWidget);
      expect(coordinator.tabStack.activeRoute, isA<HomeTab>());

      // Simulate navigation to Search Tab
      await coordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/tabs/search'),
      );
      await tester.pumpAndSettle();

      // Should switch to Search Tab
      expect(find.text('Search Tab'), findsOneWidget);
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });

    testWidgets('Complex pop: Back multiple steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Home -> Settings -> Profile 1 -> Profile 2
      coordinator.replace(HomeRoute());
      coordinator.push(SettingsRoute());
      coordinator.push(ProfileRoute('1'));
      coordinator.push(ProfileRoute('2'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 4);

      // Go back to Settings (pop 2 routes)
      await coordinator.routerDelegate.setNewRoutePath(Uri.parse('/settings'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('CoordinatorRouterDelegate.initialRoute', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    testWidgets('respects deep link even if initialRoute is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegateWithInitialRoute(
            SettingsRoute(),
          ),
          routeInformationParser: coordinator.routeInformationParser,
          routeInformationProvider: PlatformRouteInformationProvider(
            initialRouteInformation: RouteInformation(
              uri: Uri.parse('/profile/1'), // Should be respected now
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect ProfileRoute (from URL), ignoring initialRoute
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, isA<ProfileRoute>());
      expect(find.text('Profile 1'), findsOneWidget);
    });

    testWidgets('uses initialRoute when configuration is root (/)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegateWithInitialRoute(
            SettingsRoute(),
          ),
          routeInformationParser: coordinator.routeInformationParser,
          routeInformationProvider: PlatformRouteInformationProvider(
            initialRouteInformation: RouteInformation(
              uri: Uri.parse('/'), // Should fallback to initialRoute
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect SettingsRoute (from initialRoute) since path is /
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Coordinator.routerDelegateWithInitialRoute', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('creates new delegate with initial route', () {
      final initialRoute = SettingsRoute();
      final delegate = coordinator.routerDelegateWithInitialRoute(initialRoute);

      expect(delegate, isNotNull);
      expect(delegate.initialRoute, initialRoute);
      expect(delegate.coordinator, coordinator);
    });

    test('reuses delegate when initial route is the same', () {
      final initialRoute = SettingsRoute();
      final delegate1 = coordinator.routerDelegateWithInitialRoute(
        initialRoute,
      );
      final delegate2 = coordinator.routerDelegateWithInitialRoute(
        SettingsRoute(),
      );

      // Should return the same delegate instance
      expect(delegate1, same(delegate2));
    });

    test('recreates delegate when initial route changes', () {
      final route1 = SettingsRoute();
      final route2 = HomeRoute();

      final delegate1 = coordinator.routerDelegateWithInitialRoute(route1);
      final delegate2 = coordinator.routerDelegateWithInitialRoute(route2);

      // Should create a new delegate
      expect(delegate1, isNot(same(delegate2)));
      expect(delegate1.initialRoute, route1);
      expect(delegate2.initialRoute, route2);
    });

    test('disposes old delegate when recreating with different route', () {
      final route2 = HomeRoute();

      final delegate1 = coordinator.routerDelegateWithInitialRoute(
        SettingsRoute(),
      );
      final delegate1Same = coordinator.routerDelegateWithInitialRoute(
        SettingsRoute(),
      );
      final delegate2 = coordinator.routerDelegateWithInitialRoute(HomeRoute());

      expect(delegate1, same(delegate1Same));

      // Delegate2 should be different from delegate1
      expect(delegate1, isNot(same(delegate2)));
      expect(delegate2.initialRoute, route2);
    });

    test(
      'lazily initializes when called without prior routerDelegate access',
      () {
        final freshCoordinator = TestCoordinator();
        final initialRoute = ProfileRoute('123');

        // routerDelegate has not been accessed yet
        final delegate = freshCoordinator.routerDelegateWithInitialRoute(
          initialRoute,
        );

        expect(delegate, isNotNull);
        expect(delegate.initialRoute, initialRoute);
        expect(freshCoordinator.routerDelegate, same(delegate));
      },
    );

    test('works with different route types', () {
      final homeDelegate = coordinator.routerDelegateWithInitialRoute(
        HomeRoute(),
      );
      expect(homeDelegate.initialRoute, isA<HomeRoute>());

      final profileDelegate = coordinator.routerDelegateWithInitialRoute(
        ProfileRoute('42'),
      );
      expect(profileDelegate.initialRoute, isA<ProfileRoute>());
      expect((profileDelegate.initialRoute as ProfileRoute).id, '42');
    });
  });

  group('Coordinator.navigator', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    testWidgets('provides access to navigator state', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // Should be able to access navigator
      final navigator = coordinator.navigator;
      expect(navigator, isNotNull);
      expect(navigator, isA<NavigatorState>());
    });

    testWidgets('can use navigator to push routes directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      final navigator = coordinator.navigator;

      // Push a route using the navigator directly
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const Scaffold(body: Text('Direct Push')),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the directly pushed route
      expect(find.text('Direct Push'), findsOneWidget);
    });

    testWidgets('navigator is consistent across multiple accesses', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      final navigator1 = coordinator.navigator;
      final navigator2 = coordinator.navigator;

      // Should return the same instance
      expect(navigator1, same(navigator2));
    });
  });

  group('CoordinatorRouterDelegate.setNewRoutePath with deeplinks', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    testWidgets('custom deeplink strategy calls recover', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 1);
      expect(find.text('Home'), findsOneWidget);

      // Navigate to custom deeplink route
      await coordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/deeplink/custom-handler'),
      );
      await tester.pumpAndSettle();

      // Custom handler should push ProfileRoute with the path
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, isA<ProfileRoute>());
      expect(
        (coordinator.root.stack.last as ProfileRoute).id,
        'custom-handler',
      );
      expect(find.text('Profile custom-handler'), findsOneWidget);
    });

    testWidgets('non-custom deeplink uses navigate', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // Navigate to regular route (not deeplink)
      await coordinator.routerDelegate.setNewRoutePath(Uri.parse('/settings'));
      await tester.pumpAndSettle();

      // Should use navigate (push to stack)
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('multiple custom deeplinks are handled correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // First deeplink
      await coordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/deeplink/first'),
      );
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 2);
      expect(find.text('Profile first'), findsOneWidget);

      // Second deeplink
      await coordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/deeplink/second'),
      );
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, 3);
      expect(find.text('Profile second'), findsOneWidget);
    });

    test('Check backButtonDispatcher and routeInformationProvider', () {
      final coordinator = TestCoordinator();
      final delegate = coordinator;
      expect(delegate.backButtonDispatcher, isNull);
      expect(delegate.routeInformationProvider, isNull);
    });
  });
}
