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
  late final IndexedStackPath<AppRoute> tabStack = IndexedStackPath([
    HomeTab(),
    SearchTab(),
  ], 'tabs');

  @override
  List<StackPath> get paths => [root, tabStack];

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
}
