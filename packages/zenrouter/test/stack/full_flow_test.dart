import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Application Setup
// ============================================================================

/// Comprehensive test route hierarchy
abstract class AppRoute extends RouteTarget with RouteUnique {}

/// Home route - simple route
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('home'),
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const Text('Home Page'),
          ElevatedButton(
            key: const ValueKey('go-to-profile'),
            onPressed: () => coordinator.push(ProfileRoute(userId: '123')),
            child: const Text('Go to Profile'),
          ),
          ElevatedButton(
            key: const ValueKey('go-to-settings'),
            onPressed: () => coordinator.push(SettingsRoute()),
            child: const Text('Go to Settings'),
          ),
          ElevatedButton(
            key: const ValueKey('go-to-guarded'),
            onPressed: () => coordinator.push(GuardedRoute()),
            child: const Text('Go to Guarded'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Profile route with parameter
class ProfileRoute extends AppRoute {
  ProfileRoute({required this.userId});
  final String userId;

  @override
  Uri toUri() => Uri.parse('/profile/$userId');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('profile-$userId'),
      appBar: AppBar(title: Text('Profile $userId')),
      body: Column(
        children: [
          Text('Profile Page: $userId'),
          ElevatedButton(
            key: const ValueKey('go-to-edit'),
            onPressed: () => coordinator.push(EditProfileRoute(userId: userId)),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [userId];
}

/// Edit profile route - returns a result
class EditProfileRoute extends AppRoute {
  EditProfileRoute({required this.userId});
  final String userId;

  @override
  Uri toUri() => Uri.parse('/profile/$userId/edit');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('edit-profile-$userId'),
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Column(
        children: [
          const Text('Edit Profile Page'),
          ElevatedButton(
            key: const ValueKey('save-button'),
            onPressed: () {
              coordinator.pop({'saved': true, 'name': 'Updated Name'});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [userId];
}

/// Settings route
class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('settings'),
      appBar: AppBar(title: const Text('Settings')),
      body: const Text('Settings Page'),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Guarded route - prevents navigation
class GuardedRoute extends AppRoute with RouteGuard {
  GuardedRoute({this.allowPop = false});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded');

  @override
  Future<bool> popGuard() async {
    return allowPop;
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('guarded'),
      appBar: AppBar(title: const Text('Guarded Page')),
      body: Column(
        children: [
          const Text('This page has a pop guard'),
          ElevatedButton(
            key: const ValueKey('try-pop'),
            onPressed: () => coordinator.pop(),
            child: const Text('Try to Pop'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [allowPop];
}

/// Redirect route - redirects to another route
class RedirectRoute extends AppRoute with RouteRedirect {
  RedirectRoute({required this.targetUserId});
  final String targetUserId;

  @override
  Uri toUri() => Uri.parse('/redirect/$targetUserId');

  @override
  FutureOr<RouteTarget> redirect() async {
    // Simulate async redirect (e.g., checking auth)
    await Future.delayed(const Duration(milliseconds: 100));
    return ProfileRoute(userId: targetUserId);
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const SizedBox.shrink(); // Should never be shown
  }

  @override
  List<Object?> get props => [targetUserId];
}

/// Deep link route
class DeepLinkRoute extends AppRoute with RouteDeepLink {
  DeepLinkRoute({required this.path, this.strategy = DeeplinkStrategy.push});
  final String path;
  final DeeplinkStrategy strategy;

  @override
  DeeplinkStrategy get deeplinkStrategy => strategy;

  @override
  Uri toUri() => Uri.parse('/deeplink/$path?strategy=$strategy');

  @override
  void deeplinkHandler(covariant TestCoordinator coordinator, Uri uri) {
    // Custom handling - navigate based on path
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'deeplink') {
      coordinator.push(ProfileRoute(userId: path));
    }
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('deeplink-$path'),
      body: Text('DeepLink: $path'),
    );
  }

  @override
  List<Object?> get props => [path, strategy];
}

/// Shell/Layout route
class ShellLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.shellStack;

  @override
  Uri toUri() => Uri.parse('/shell');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('shell'),
      appBar: AppBar(title: const Text('Shell Layout')),
      body: Column(
        children: [
          const Text('Shell Container'),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Route within shell
class ShellChildRoute extends AppRoute {
  ShellChildRoute({required this.id});
  final String id;

  @override
  Type get layout => ShellLayout;

  @override
  Uri toUri() => Uri.parse('/shell/$id');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('shell-child-$id'),
      body: Text('Shell Child: $id'),
    );
  }

  @override
  List<Object?> get props => [id];
}

/// Tab routes for IndexedStackPath testing
class HomeTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/tabs/home');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('home-tab'),
      appBar: AppBar(title: const Text('Home Tab')),
      body: Column(
        children: [
          const Text('Home Tab Content'),
          ElevatedButton(
            key: const ValueKey('goto-search-tab'),
            onPressed: () => coordinator.tabStack.goToIndexed(1),
            child: const Text('Go to Search Tab'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

class SearchTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/tabs/search');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('search-tab'),
      appBar: AppBar(title: const Text('Search Tab')),
      body: Column(
        children: [
          const Text('Search Tab Content'),
          ElevatedButton(
            key: const ValueKey('goto-profile-tab'),
            onPressed: () => coordinator.tabStack.goToIndexed(2),
            child: const Text('Go to Profile Tab'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

class ProfileTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/tabs/profile');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('profile-tab'),
      appBar: AppBar(title: const Text('Profile Tab')),
      body: Column(
        children: [
          const Text('Profile Tab Content'),
          ElevatedButton(
            key: const ValueKey('goto-home-tab'),
            onPressed: () => coordinator.tabStack.goToIndexed(0),
            child: const Text('Go to Home Tab'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Profile layout for nested navigation (no build override - tests automatic build)
class ProfileLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.profileStack;

  @override
  Uri toUri() => Uri.parse('/profile-layout');

  // NOTE: No build() override - testing automatic build from RouteLayout

  @override
  List<Object?> get props => [];
}

/// Route within profile layout
class ProfileChildRoute extends AppRoute {
  ProfileChildRoute({required this.section});
  final String section;

  @override
  Type get layout => ProfileLayout;

  @override
  Uri toUri() => Uri.parse('/profile-layout/$section');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('profile-child-$section'),
      appBar: AppBar(title: Text('Profile: $section')),
      body: Column(
        children: [
          Text('Profile section: $section'),
          ElevatedButton(
            key: ValueKey(
              'navigate-to-${section == "edit" ? "settings" : "edit"}',
            ),
            onPressed: () => coordinator.push(
              ProfileChildRoute(
                section: section == 'edit' ? 'settings' : 'edit',
              ),
            ),
            child: Text('Go to ${section == "edit" ? "Settings" : "Edit"}'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [section];
}

/// Test coordinator
class TestCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> shellStack = NavigationPath.createWith(
    coordinator: this,
    label: 'shell',
  );
  late final IndexedStackPath<AppRoute> tabStack = IndexedStackPath.createWith(
    [HomeTab(), SearchTab(), ProfileTab()],
    coordinator: this,
    label: 'tabs',
  );
  late final NavigationPath<AppRoute> profileStack = NavigationPath.createWith(
    coordinator: this,
    label: 'profile',
  );

  late final IndexedStackPath<AppRoute> advancedTabStack =
      IndexedStackPath.createWith(
        [FirstTab(), SecondTab(), ThirdTab()],
        coordinator: this,
        label: 'advanced-tabs',
      );

  @override
  void defineLayout() {
    defineLayoutParent(ShellLayout.new);
    defineLayoutParent(ProfileLayout.new);
    defineLayoutParent(AdvancedTabLayout.new);
  }

  @override
  List<StackPath> get paths => [
    ...super.paths,
    shellStack,
    tabStack,
    profileStack,
    advancedTabStack,
  ];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return HomeRoute();

    return switch (segments) {
      ['profile', final userId] => ProfileRoute(userId: userId),
      ['profile', final userId, 'edit'] => EditProfileRoute(userId: userId),
      ['settings'] => SettingsRoute(),
      ['guarded'] => GuardedRoute(),
      ['redirect', final userId] => RedirectRoute(targetUserId: userId),
      ['deeplink', final path] => DeepLinkRoute(
        path: path,
        strategy: switch (uri.queryParameters['strategy']) {
          'push' => DeeplinkStrategy.push,
          'replace' => DeeplinkStrategy.replace,
          'custom' => DeeplinkStrategy.custom,
          _ => DeeplinkStrategy.custom,
        },
      ),
      ['shell'] => ShellLayout(),
      ['shell', final id] => ShellChildRoute(id: id),
      ['tabs', 'home'] => HomeTab(),
      ['tabs', 'search'] => SearchTab(),
      ['tabs', 'profile'] => ProfileTab(),
      ['profile-layout'] => ProfileLayout(),
      ['profile-layout', final section] => ProfileChildRoute(section: section),
      ['tabs', 'advanced'] => AdvancedTabLayout(),
      _ => HomeRoute(),
    };
  }
}

/// Advanced Tab Layout
class AdvancedTabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.advancedTabStack; // Not used for IndexedStackPath directly in this test

  @override
  Uri toUri() => Uri.parse('/tabs/advanced');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('advanced-tab-layout'),
      body: buildPath(coordinator),
    );
  }

  @override
  List<Object?> get props => [];
}

class FirstTab extends AppRoute with RouteGuard {
  @override
  Type? get layout => AdvancedTabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/first');

  @override
  Future<bool> popGuardWith(TestCoordinator coordinator) async {
    final context = coordinator.routerDelegate.navigatorKey.currentContext;
    if (context == null) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Allow switch?'),
        actions: [
          TextButton(
            key: const ValueKey('confirm-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
          TextButton(
            key: const ValueKey('confirm-no'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(
      key: ValueKey('first-tab'),
      body: Text('First Tab Content'),
    );
  }

  @override
  List<Object?> get props => [];
}

class SecondTab extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Type? get layout => AdvancedTabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/second');

  @override
  AppRoute redirect() => ThirdTab();

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(key: ValueKey('second-tab'), body: Text('Redirects'));
  }

  @override
  List<Object?> get props => [];
}

class ThirdTab extends AppRoute {
  @override
  Type? get layout => AdvancedTabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/third');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(
      key: ValueKey('third-tab'),
      body: Text('Third Tab Content'),
    );
  }

  @override
  List<Object?> get props => [];
}

class FourthTab extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Type? get layout => AdvancedTabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/fourth');

  @override
  AppRoute redirect() => HomeRoute();

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(
      key: ValueKey('fourth-tab'),
      body: Text('Fourth Tab Content'),
    );
  }

  @override
  List<Object?> get props => [];
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('Full Flow Widget Tests - Coordinator', () {
    group('Basic Information', () {
      test('activeLayout returns null when no layout is active', () async {
        final coordinator = TestCoordinator();
        await coordinator.replace(HomeRoute());

        expect(coordinator.activeLayout, isNull);
      });

      test('activeLayout returns the deepest active layout', () async {
        final coordinator = TestCoordinator();

        // Push a route with ShellRoute layout
        await coordinator.replace(ShellChildRoute(id: 'test'));

        final activeLayout = coordinator.activeLayout;
        expect(activeLayout, isNotNull);
        expect(activeLayout, isA<ShellLayout>());
      });

      test('activeLayout returns deepest layout in nested hierarchy', () async {
        final coordinator = TestCoordinator();

        // Push a route with ProfileLayout
        await coordinator.replace(ProfileChildRoute(section: 'edit'));

        final activeLayout = coordinator.activeLayout;
        expect(activeLayout, isNotNull);
        expect(activeLayout, isA<ProfileLayout>());
      });

      test('activeLayouts returns all active layouts in hierarchy', () async {
        final coordinator = TestCoordinator();

        // Simple route - no layouts
        await coordinator.replace(HomeRoute());
        expect(coordinator.activeLayouts, isEmpty);

        // Route with one layout
        await coordinator.replace(ShellChildRoute(id: 'test'));
        expect(coordinator.activeLayouts.length, 1);
        expect(coordinator.activeLayouts.first, isA<ShellLayout>());

        // Route with layout
        await coordinator.replace(ProfileChildRoute(section: 'settings'));
        expect(coordinator.activeLayouts.length, 1);
        expect(coordinator.activeLayouts.first, isA<ProfileLayout>());
      });

      test('activePath returns root when no layouts are active', () async {
        final coordinator = TestCoordinator();
        await coordinator.replace(HomeRoute());

        expect(coordinator.activePath, coordinator.root);
      });

      test('activePath returns the deepest active path', () async {
        final coordinator = TestCoordinator();

        // Push shell child route
        await coordinator.replace(ShellChildRoute(id: 'test'));

        expect(coordinator.activePath, coordinator.shellStack);
      });

      test('activeLayoutPaths returns correct path hierarchy', () async {
        final coordinator = TestCoordinator();

        // Simple route - only root
        await coordinator.replace(HomeRoute());
        expect(coordinator.activePaths.length, 1);
        expect(coordinator.activePaths.first, coordinator.root);

        // Route with shell layout
        await coordinator.replace(ShellChildRoute(id: 'test'));
        expect(coordinator.activePaths.length, 2);
        expect(coordinator.activePaths[0], coordinator.root);
        expect(coordinator.activePaths[1], coordinator.shellStack);
      });

      test('currentUri returns correct URI for active route', () async {
        final coordinator = TestCoordinator();

        await coordinator.replace(HomeRoute());
        expect(coordinator.currentUri.toString(), '/');

        await coordinator.replace(ProfileRoute(userId: '123'));
        expect(coordinator.currentUri.toString(), '/profile/123');

        await coordinator.replace(SettingsRoute());
        expect(coordinator.currentUri.toString(), '/settings');
      });
    });

    group('Recover Method', () {
      testWidgets('recover with push strategy pushes route onto stack', (
        tester,
      ) async {
        final coordinator = TestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to create initial stack
        coordinator.push(SettingsRoute());
        await tester.pumpAndSettle();

        final stackLengthBefore = coordinator.root.stack.length;

        // Recover with push strategy
        coordinator.recover(
          DeepLinkRoute(path: 'user1', strategy: DeeplinkStrategy.push),
        );
        await tester.pumpAndSettle();

        // Should push onto existing stack
        expect(coordinator.root.stack.length, stackLengthBefore + 1);
        expect(find.byKey(const ValueKey('deeplink-user1')), findsOneWidget);
      });

      testWidgets('recover with replace strategy replaces entire stack', (
        tester,
      ) async {
        final coordinator = TestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to create initial stack
        coordinator.push(SettingsRoute());
        coordinator.push(ProfileRoute(userId: '456'));
        await tester.pumpAndSettle();

        expect(coordinator.root.stack.length, 3); // Home + Settings + Profile

        // Recover with replace strategy
        await coordinator.recover(
          DeepLinkRoute(path: 'user2', strategy: DeeplinkStrategy.replace),
        );
        await tester.pumpAndSettle();

        // Should replace entire stack
        expect(coordinator.root.stack.length, 1);
        expect(find.byKey(const ValueKey('deeplink-user2')), findsOneWidget);
      });

      testWidgets('recover with custom strategy invokes custom handler', (
        tester,
      ) async {
        final coordinator = TestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Recover with custom strategy
        await coordinator.recover(
          DeepLinkRoute(path: 'customUser', strategy: DeeplinkStrategy.custom),
        );
        await tester.pumpAndSettle();

        // Custom handler should navigate to profile with the path as userId
        expect(
          find.byKey(const ValueKey('profile-customUser')),
          findsOneWidget,
        );
      });

      testWidgets('recover with non-deeplink route uses replace', (
        tester,
      ) async {
        final coordinator = TestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to create initial stack
        coordinator.push(SettingsRoute());
        coordinator.push(ProfileRoute(userId: '789'));
        await tester.pumpAndSettle();

        expect(coordinator.root.stack.length, 3);

        // Recover with non-deeplink route
        await coordinator.recover(HomeRoute());
        await tester.pumpAndSettle();

        // Should replace stack (default behavior)
        expect(coordinator.root.stack.length, 1);
        expect(find.byKey(const ValueKey('home')), findsOneWidget);
      });
    });
  });
  group('Full Flow Widget Tests - Basic Navigation', () {
    testWidgets('Home screen renders correctly', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Should show home page
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Navigate from home to profile', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Tap profile button
      await tester.tap(find.byKey(const ValueKey('go-to-profile')));
      await tester.pumpAndSettle();

      // Should show profile page
      expect(find.byKey(const ValueKey('profile-123')), findsOneWidget);
      expect(find.text('Profile Page: 123'), findsOneWidget);
    });

    testWidgets('Navigate to settings and back', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.byKey(const ValueKey('go-to-settings')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings')), findsOneWidget);

      // Pop back
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home')), findsOneWidget);
    });

    testWidgets('Deep navigation stack', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Home -> Profile -> Edit
      await tester.tap(find.byKey(const ValueKey('go-to-profile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('go-to-edit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('edit-profile-123')), findsOneWidget);
      expect(coordinator.root.stack.length, 3);
    });
  });

  group('Full Flow Widget Tests - Route Results', () {
    testWidgets('Route returns result on pop', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to profile then edit
      coordinator.push(ProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      final resultFuture = coordinator.push(EditProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      // Save (which pops with result)
      await tester.tap(find.byKey(const ValueKey('save-button')));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      expect(result, isA<Map>());
      final resultMap = result as Map;
      expect(resultMap['saved'], true);
      expect(resultMap['name'], 'Updated Name');

      // Should be back on profile page
      expect(find.byKey(const ValueKey('profile-123')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Route Guards', () {
    testWidgets('RouteGuard prevents pop when guard returns false', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Go to guarded page
      await tester.tap(find.byKey(const ValueKey('go-to-guarded')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded')), findsOneWidget);

      final stackLengthBefore = coordinator.root.stack.length;

      // Try to pop (should be prevented)
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should still be on guarded page
      expect(find.byKey(const ValueKey('guarded')), findsOneWidget);
      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('RouteGuard allows pop when guard returns true', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push a guarded route that allows popping
      coordinator.push(GuardedRoute(allowPop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded')), findsOneWidget);

      // Try to pop (should succeed)
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should be back on home
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Route Redirects', () {
    testWidgets('RedirectRoute redirects to target route', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push redirect route
      coordinator.push(RedirectRoute(targetUserId: '456'));
      await tester.pumpAndSettle();

      // Should show profile page (not redirect page)
      expect(find.byKey(const ValueKey('profile-456')), findsOneWidget);
      expect(find.text('Profile Page: 456'), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Deep Linking', () {
    testWidgets('Deep link with push strategy', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create initial stack
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Trigger deep link
      coordinator.push(
        DeepLinkRoute(path: 'custom', strategy: DeeplinkStrategy.push),
      );
      await tester.pumpAndSettle();

      // Should push onto existing stack
      expect(coordinator.root.stack.length, greaterThan(stackLengthBefore));
    });

    testWidgets('Deep link with replace strategy', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to create initial stack
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      // Trigger deep link with replace
      await coordinator.recoverRouteFromUri(
        Uri.parse('/deeplink/789?strategy=replace'),
      );
      await tester.pumpAndSettle();

      // Should replace stack
      expect(coordinator.root.stack.length, 1);
    });

    testWidgets('Deep link with custom strategy invokes handler', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push deep link with custom strategy
      coordinator.recover(
        DeepLinkRoute(path: 'test', strategy: DeeplinkStrategy.custom),
      );
      await tester.pumpAndSettle();

      // Custom handler should navigate to profile
      expect(find.byKey(const ValueKey('profile-test')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Layout/Shell Routes', () {
    testWidgets('Shell route creates nested navigation', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to shell child
      coordinator.push(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Should show shell layout and child
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child1')), findsOneWidget);
      expect(find.text('Shell Container'), findsOneWidget);
      expect(find.text('Shell Child: child1'), findsOneWidget);
    });

    testWidgets('Navigate within shell preserves shell layout', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to first shell child
      coordinator.push(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Navigate to second shell child
      coordinator.push(ShellChildRoute(id: 'child2'));
      await tester.pumpAndSettle();

      // Shell should still be visible
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child2')), findsOneWidget);

      // Both children should be in shell stack
      expect(coordinator.shellStack.stack.length, 2);
    });

    testWidgets('Pop from shell child returns to previous route', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure we start at home
      expect(find.byKey(const ValueKey('home')), findsOneWidget);

      // Navigate to shell child
      coordinator.push(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Verify we are at shell child
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child1')), findsOneWidget);

      // Pop
      coordinator.pop();
      await tester.pumpAndSettle();

      // Verify we are back at home and shell is gone
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell')), findsNothing);
    });

    testWidgets('Navigate back home from shell child', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure we start at home
      expect(find.byKey(const ValueKey('home')), findsOneWidget);

      // Navigate to shell child
      coordinator.navigate(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Verify we are at shell child
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child1')), findsOneWidget);

      // Pop
      coordinator.navigate(HomeRoute());
      await tester.pumpAndSettle();

      // Verify we are back at home and shell is gone
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell')), findsNothing);
      expect(coordinator.root.stack.length, 1);

      // Pop
      coordinator.navigate(ProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      // Verify we are back at home and shell is gone
      expect(find.byKey(const ValueKey('home')), findsNothing);
      expect(coordinator.root.stack.length, 2);

      // Navigate to shell child
      coordinator.navigate(ShellChildRoute(id: 'child1'));
      await tester.pumpAndSettle();

      // Verify we are at shell child
      expect(find.byKey(const ValueKey('shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('shell-child-child1')), findsOneWidget);
      expect(coordinator.root.stack.length, 3);
    });
  });

  group('Full Flow Widget Tests - URI Handling', () {
    testWidgets('parseRouteFromUri creates correct routes', (tester) async {
      final coordinator = TestCoordinator();

      expect(coordinator.parseRouteFromUri(Uri.parse('/')), isA<HomeRoute>());
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/profile/123')),
        isA<ProfileRoute>(),
      );
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/settings')),
        isA<SettingsRoute>(),
      );
    });

    testWidgets('recoverRouteFromUri navigates to parsed route', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      await coordinator.recoverRouteFromUri(Uri.parse('/profile/999'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('profile-999')), findsOneWidget);
      expect(find.text('Profile Page: 999'), findsOneWidget);
    });

    testWidgets('currentUri reflects active route', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(ProfileRoute(userId: '123'));
      await tester.pumpAndSettle();

      expect(coordinator.currentUri.path, '/profile/123');
    });
  });

  group('Full Flow Widget Tests - Replace Operation', () {
    testWidgets('replace clears stack and navigates to new route', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Build a stack
      coordinator.push(ProfileRoute(userId: '1'));
      await tester.pumpAndSettle();
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThanOrEqualTo(2));

      // Replace with new route
      coordinator.replace(ProfileRoute(userId: '999'));
      await tester.pumpAndSettle();

      // Stack should be cleared
      expect(coordinator.root.stack.length, 1);
      expect(find.byKey(const ValueKey('profile-999')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - Complex Scenarios', () {
    testWidgets('Navigate, edit, save, and verify result', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Full user flow
      await tester.tap(find.byKey(const ValueKey('go-to-profile')));
      await tester.pumpAndSettle();

      final resultFuture = coordinator.push(EditProfileRoute(userId: '123'));

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-button')));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      final resultMap = result as Map;
      expect(resultMap['saved'], true);

      // Should be back on profile
      expect(find.byKey(const ValueKey('profile-123')), findsOneWidget);
    });

    testWidgets('Multiple navigation operations in sequence', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Complex navigation sequence
      coordinator.push(ProfileRoute(userId: '1'));
      await tester.pumpAndSettle();

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      coordinator.push(ProfileRoute(userId: '2'));
      await tester.pumpAndSettle();

      // Verify stack
      expect(coordinator.root.stack.length, 4); // home + 3 pushes

      // Pop twice
      coordinator.pop();
      await tester.pumpAndSettle();
      coordinator.pop();
      await tester.pumpAndSettle();

      // Should be back at ProfileRoute('1')
      expect(find.byKey(const ValueKey('profile-1')), findsOneWidget);
    });
  });

  group('Full Flow Widget Tests - IndexedStackPath Tab Navigation', () {
    testWidgets('Tab stack initializes with first tab active', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Verify tab stack is initialized
      expect(coordinator.tabStack.stack.length, 3);
      expect(coordinator.tabStack.activeIndex, 0);
      expect(coordinator.tabStack.activeRoute, isA<HomeTab>());
    });

    testWidgets('Switching tabs updates active index', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Test switching tabs via goToIndexed
      expect(coordinator.tabStack.activeIndex, 0);

      coordinator.tabStack.goToIndexed(1);
      await tester.pumpAndSettle();

      expect(coordinator.tabStack.activeIndex, 1);
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });

    testWidgets('Can navigate between all tabs', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Test direct index navigation
      coordinator.tabStack.goToIndexed(0);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 0);
      expect(coordinator.tabStack.activeRoute, isA<HomeTab>());

      coordinator.tabStack.goToIndexed(1);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 1);
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());

      coordinator.tabStack.goToIndexed(2);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 2);
      expect(coordinator.tabStack.activeRoute, isA<ProfileTab>());

      coordinator.tabStack.goToIndexed(0);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 0);
      expect(coordinator.tabStack.activeRoute, isA<HomeTab>());
    });

    testWidgets('Tab stack maintains state between switches', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Switch between tabs multiple times
      coordinator.tabStack.goToIndexed(0);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 0);

      coordinator.tabStack.goToIndexed(2);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 2);

      coordinator.tabStack.goToIndexed(1);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 1);

      // Verify all tabs still exist
      expect(coordinator.tabStack.stack.length, 3);
    });

    testWidgets('activateRoute switches to correct tab', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Start at home tab
      expect(coordinator.tabStack.activeIndex, 0);

      // Activate search tab
      await coordinator.tabStack.activateRoute(SearchTab());
      await tester.pumpAndSettle();

      expect(coordinator.tabStack.activeIndex, 1);
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });

    testWidgets('Tab stack resets to first tab', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to profile tab
      coordinator.tabStack.goToIndexed(2);
      await tester.pumpAndSettle();
      expect(coordinator.tabStack.activeIndex, 2);

      // Reset
      coordinator.tabStack.reset();
      await tester.pumpAndSettle();

      // Should be back to first tab
      expect(coordinator.tabStack.activeIndex, 0);
    });

    testWidgets('parseRouteFromUri creates correct tab routes', (tester) async {
      final coordinator = TestCoordinator();

      expect(
        coordinator.parseRouteFromUri(Uri.parse('/tabs/home')),
        isA<HomeTab>(),
      );
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/tabs/search')),
        isA<SearchTab>(),
      );
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/tabs/profile')),
        isA<ProfileTab>(),
      );
    });

    testWidgets('guard and redirect work with IndexedStackPath', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push a profile child route which should trigger layout creation
      coordinator.push(FirstTab());
      await tester.pumpAndSettle();

      expect(coordinator.advancedTabStack.activeIndex, 0);

      coordinator.advancedTabStack.goToIndexed(1);
      await tester.pumpAndSettle();
      // Still in first tab
      expect(coordinator.advancedTabStack.activeIndex, 0);
      expect(find.byKey(const ValueKey('confirm-yes')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm-yes')));
      await tester.pumpAndSettle();

      /// Since the second tab is redirect to third
      expect(coordinator.advancedTabStack.activeIndex, 2);
    });

    testWidgets('redirect to other route not in tab', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(FourthTab());
      await tester.pumpAndSettle();

      // Should be redirected to home
      expect(coordinator.currentUri, Uri.parse('/'));
    });
  });

  group('Full Flow Widget Tests - ProfileLayout Automatic Build', () {
    testWidgets('ProfileLayout uses automatic build', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push a profile child route which should trigger layout creation
      coordinator.push(ProfileChildRoute(section: 'edit'));
      await tester.pumpAndSettle();

      // Should render the layout and child
      expect(find.byKey(const ValueKey('profile-child-edit')), findsOneWidget);
      expect(find.text('Profile section: edit'), findsOneWidget);
    });

    testWidgets('Navigate within profile layout', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Start with edit section
      coordinator.push(ProfileChildRoute(section: 'edit'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('profile-child-edit')), findsOneWidget);

      // Navigate to settings within profile layout
      await tester.tap(find.byKey(const ValueKey('navigate-to-settings')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profile-child-settings')),
        findsOneWidget,
      );
      expect(find.text('Profile section: settings'), findsOneWidget);

      // Should have both routes in profile stack
      expect(coordinator.profileStack.stack.length, 2);
    });

    testWidgets('Profile layout resolves correct path', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final layout = ProfileLayout();
      final path = layout.resolvePath(coordinator);

      expect(path, equals(coordinator.profileStack));
      expect(path.debugLabel, 'profile');
    });

    testWidgets('Navigate back and forth in profile layout', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push edit section
      coordinator.push(ProfileChildRoute(section: 'edit'));
      await tester.pumpAndSettle();

      // Go to settings
      await tester.tap(find.byKey(const ValueKey('navigate-to-settings')));
      await tester.pumpAndSettle();

      expect(coordinator.profileStack.stack.length, 2);

      // Go back to edit
      await tester.tap(find.byKey(const ValueKey('navigate-to-edit')));
      await tester.pumpAndSettle();

      expect(coordinator.profileStack.stack.length, 3);
      expect(find.byKey(const ValueKey('profile-child-edit')), findsOneWidget);
    });

    testWidgets('parseRouteFromUri creates correct profile routes', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      expect(
        coordinator.parseRouteFromUri(Uri.parse('/profile-layout')),
        isA<ProfileLayout>(),
      );
      expect(
        coordinator.parseRouteFromUri(Uri.parse('/profile-layout/edit')),
        isA<ProfileChildRoute>(),
      );
      final route =
          coordinator.parseRouteFromUri(Uri.parse('/profile-layout/settings'))
              as ProfileChildRoute;
      expect(route.section, 'settings');
    });
  });
}
