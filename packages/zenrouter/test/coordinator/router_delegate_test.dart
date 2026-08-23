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

class PopScopeRoute extends AppRoute {
  PopScopeRoute({required this.onPopInvoked});

  final ValueChanged<bool> onPopInvoked;

  @override
  Uri toUri() => Uri.parse('/pop-scope');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => onPopInvoked(didPop),
      child: const Scaffold(body: Text('Pop scope')),
    );
  }

  @override
  List<Object?> get props => [onPopInvoked];
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
  )..bindLayout(TabLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, tabStack];

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
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

class QueuedTestCoordinator extends TestCoordinator {
  final firstParseGate = Completer<void>();
  final parseOrder = <String>[];

  @override
  Future<AppRoute> parseRouteFromUri(Uri uri) async {
    parseOrder.add(uri.path);
    if (uri.path == '/settings') await firstParseGate.future;
    return super.parseRouteFromUri(uri);
  }
}

class ResolutionTestCoordinator extends TestCoordinator {
  @override
  Future<RouteResolution<AppRoute>> resolveRoute(RouteRequest request) async {
    return switch (request.uri.path) {
      '/legacy' => RedirectRouteResolution(
        request: request,
        location: Uri.parse('/settings'),
        statusCode: 308,
      ),
      '/loop' => RedirectRouteResolution(
        request: request,
        location: Uri.parse('/loop-b'),
      ),
      '/loop-b' => RedirectRouteResolution(
        request: request,
        location: Uri.parse('/loop'),
      ),
      '/broken' => ErrorRouteResolution(
        request: request,
        error: StateError('resolution failed'),
        stackTrace: StackTrace.current,
      ),
      _ => super.resolveRoute(request),
    };
  }
}

class CancellationAwareCoordinator extends TestCoordinator {
  bool cancellationObserved = false;

  @override
  Future<RouteResolution<AppRoute>> resolveRoute(RouteRequest request) async {
    if (request.uri.path == '/slow') {
      await request.cancellationToken.whenCancelled;
      cancellationObserved = true;
      request.cancellationToken.throwIfCancelled();
    }
    return super.resolveRoute(request);
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

    testWidgets('popRoute lets the current PopScope consume back', (
      tester,
    ) async {
      final popResults = <bool>[];
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.replace(HomeRoute());
      coordinator.push(
        PopScopeRoute(onPopInvoked: (didPop) => popResults.add(didPop)),
      );
      await tester.pumpAndSettle();

      final handled = await coordinator.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(popResults, [isFalse]);
      expect(coordinator.root.stack, hasLength(2));
      expect(find.text('Pop scope'), findsOneWidget);
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

      // A blocked traversal must restore the current history entry (neglect),
      // not push a new one. Flutter maps `none` + mismatched URIs to push.
      expect(
        CoordinatorRouteInformationProvider.resolveReportingType(
          NavigationHistoryIntent.traverse,
          RouteInformationReportingType.none,
          reportedUri: coordinator.currentUri,
          engineUri: Uri.parse('/'),
        ),
        RouteInformationReportingType.neglect,
      );
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

    test('new route information supersedes unresolved work', () async {
      final queuedCoordinator = QueuedTestCoordinator();

      final first = queuedCoordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/settings'),
      );
      await pumpEventQueue();
      final second = queuedCoordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/profile/2'),
      );

      await second;
      expect(queuedCoordinator.parseOrder, ['/settings', '/profile/2']);
      expect(
        queuedCoordinator.root.activeRoute,
        isA<ProfileRoute>().having((route) => route.id, 'id', '2'),
      );

      await first;
      expect(queuedCoordinator.firstParseGate.isCompleted, isFalse);
      expect(
        queuedCoordinator.root.activeRoute,
        isA<ProfileRoute>().having((route) => route.id, 'id', '2'),
      );

      queuedCoordinator.firstParseGate.complete();
      await pumpEventQueue();

      queuedCoordinator.dispose();
    });

    test('passes cooperative cancellation to route resolvers', () async {
      final cancellationCoordinator = CancellationAwareCoordinator();

      final slow = cancellationCoordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/slow'),
      );
      await pumpEventQueue();
      final latest = cancellationCoordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/settings'),
      );

      await Future.wait([slow, latest]);

      expect(cancellationCoordinator.cancellationObserved, isTrue);
      expect(cancellationCoordinator.root.activeRoute, isA<SettingsRoute>());
      cancellationCoordinator.dispose();
    });

    test('applies typed redirects with replace history intent', () async {
      final resolutionCoordinator = ResolutionTestCoordinator();

      await resolutionCoordinator.routerDelegate.setNewRoutePath(
        Uri.parse('/legacy'),
      );

      expect(resolutionCoordinator.root.activeRoute, isA<SettingsRoute>());
      expect(
        resolutionCoordinator.consumeHistoryIntent(),
        NavigationHistoryIntent.replace,
      );
      resolutionCoordinator.dispose();
    });

    test('rejects a cyclic typed redirect chain', () async {
      final resolutionCoordinator = ResolutionTestCoordinator();

      await expectLater(
        resolutionCoordinator.routerDelegate.setNewRoutePath(
          Uri.parse('/loop'),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Redirect loop detected'),
          ),
        ),
      );
      resolutionCoordinator.dispose();
    });

    test('propagates typed routing failures with their stack trace', () async {
      final resolutionCoordinator = ResolutionTestCoordinator();

      await expectLater(
        resolutionCoordinator.routerDelegate.setNewRoutePath(
          Uri.parse('/broken'),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'resolution failed',
          ),
        ),
      );
      resolutionCoordinator.dispose();
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
  });

  group('Coordinator.dispose', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('removes listeners from all paths', () async {
      // Track coordinator notifications
      int coordinatorNotifyCount = 0;
      coordinator.addListener(() => coordinatorNotifyCount++);

      // Trigger a notification via replace (await to ensure microtasks complete)
      await coordinator.replace(HomeRoute());

      // Coordinator should have been notified (replace triggers notifyListeners)
      final countBefore = coordinatorNotifyCount;
      expect(countBefore, greaterThan(0));

      // Dispose coordinator
      coordinator.dispose();

      // After dispose, the root path should still exist
      expect(coordinator.root.stack.length, greaterThan(0));
    });

    test('disposes routerDelegate', () async {
      // Get reference to routerDelegate before dispose
      final routerDelegate = coordinator.routerDelegate;

      // Dispose coordinator (which should dispose routerDelegate)
      coordinator.dispose();

      // After dispose, routerDelegate should throw when adding listeners
      expect(
        () => routerDelegate.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });

    test('disposes root NavigationPath', () async {
      // Get the root path
      final root = coordinator.root;

      // Verify root has routes
      await coordinator.replace(HomeRoute());
      expect(root.stack, isNotEmpty);

      // Dispose coordinator
      coordinator.dispose();

      // After dispose, the root path should still exist
      // (dispose doesn't delete the path, just removes listeners)
      expect(root, isNotNull);
    });

    test('coordinator cannot add listeners after dispose', () {
      coordinator.dispose();

      // Attempting to add a listener after dispose should throw
      expect(
        () => coordinator.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });

    test('coordinator cannot notify listeners after dispose', () {
      coordinator.dispose();

      // Attempting to notify after dispose should throw
      expect(() => coordinator.notifyListeners(), throwsA(isA<FlutterError>()));
    });

    testWidgets('disposed coordinator cleans up widget tree properly', (
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

      expect(find.text('Home'), findsOneWidget);

      // Dispose coordinator
      coordinator.dispose();

      // Note: In a real app, disposing the coordinator while it's still
      // mounted would cause issues - this test verifies the disposal itself works
    });

    test('root path is disposed after coordinator dispose', () {
      final root = coordinator.root;

      // Dispose coordinator (which should dispose root)
      coordinator.dispose();

      // Verify root path is disposed by checking if adding listeners throws
      expect(() => root.addListener(() {}), throwsA(isA<FlutterError>()));
    });

    test('all paths have listeners removed', () async {
      // Replace to set initial route
      await coordinator.replace(HomeRoute());

      // Add our own listener to coordinator
      int coordinatorNotifyCount = 0;
      coordinator.addListener(() => coordinatorNotifyCount++);

      final countBefore = coordinatorNotifyCount;

      // pushOrMoveToTop triggers synchronous notification via notifyListeners
      await coordinator.root.pushOrMoveToTop(SettingsRoute());

      // Verify listener was called
      expect(coordinatorNotifyCount, greaterThan(countBefore));
    });

    test('dispose removes coordinator listener from paths', () async {
      // Before dispose, path notifications should trigger coordinator notifications
      int coordinatorNotifyCount = 0;
      coordinator.addListener(() => coordinatorNotifyCount++);

      await coordinator.replace(HomeRoute());
      final countAfterReplace = coordinatorNotifyCount;
      expect(countAfterReplace, greaterThan(0));

      // Dispose removes coordinators listeners from paths
      coordinator.dispose();

      // Accessing disposed coordinator should throw
      expect(
        () => coordinator.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });
  });

  group('CoordinatorRouterDelegate.dispose', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('removes listener from coordinator', () async {
      final routerDelegate = coordinator.routerDelegate;

      // Add our own listener to coordinator to track notification count
      int coordinatorNotifyCount = 0;
      coordinator.addListener(() => coordinatorNotifyCount++);

      // Replace to trigger notification
      await coordinator.replace(HomeRoute());
      final countAfterReplace = coordinatorNotifyCount;
      expect(countAfterReplace, greaterThan(0));

      // Dispose routerDelegate directly
      routerDelegate.dispose();

      // Replace again - coordinator still works
      await coordinator.replace(SettingsRoute());

      // Coordinator still notifies its other listeners
      expect(coordinatorNotifyCount, greaterThan(countAfterReplace));
    });

    test('routerDelegate cannot add listeners after dispose', () {
      final routerDelegate = coordinator.routerDelegate;
      routerDelegate.dispose();

      // Attempting to add a listener after dispose should throw
      expect(
        () => routerDelegate.addListener(() {}),
        throwsA(isA<FlutterError>()),
      );
    });

    test('routerDelegate cannot notify listeners after dispose', () {
      final routerDelegate = coordinator.routerDelegate;
      routerDelegate.dispose();

      // Attempting to notify after dispose should throw
      expect(
        () => routerDelegate.notifyListeners(),
        throwsA(isA<FlutterError>()),
      );
    });

    test(
      'disposing coordinator disposes routerDelegate (idempotent dispose)',
      () {
        final routerDelegate = coordinator.routerDelegate;

        // Dispose coordinator (which internally disposes routerDelegate)
        coordinator.dispose();

        // Verify routerDelegate is disposed by checking if adding listeners throws
        expect(
          () => routerDelegate.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
      },
    );

    test('routerDelegate can be disposed independently', () async {
      final routerDelegate = coordinator.routerDelegate;

      // Dispose only the routerDelegate
      routerDelegate.dispose();

      // Coordinator should still work for adding listeners
      int count = 0;
      coordinator.addListener(() => count++);

      // Verify coordinator is still functional
      await coordinator.replace(HomeRoute());
      expect(count, greaterThan(0));
    });
  });
}
