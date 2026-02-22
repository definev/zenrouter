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

class UndefinedTabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  StackPath<RouteUnique> resolvePath(TestCoordinator coordinator) =>
      coordinator.undefinedTabStack;
}

class UndefinedHomeTab extends AppRoute {
  @override
  Type? get layout => UndefinedTabLayout;

  @override
  Uri toUri() => Uri.parse('/undefined-home-tab');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return const Scaffold(body: Text('Undefined Home Tab'));
  }
}

class UndefinedSearchTab extends AppRoute {
  @override
  Type? get layout => UndefinedTabLayout;

  @override
  Uri toUri() => Uri.parse('/undefined-search-tab');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return const Scaffold(body: Text('Undefined Search Tab'));
  }
}

// Route with custom restoration converter
class BookmarkRoute extends AppRoute with RouteRestorable<BookmarkRoute> {
  BookmarkRoute({required this.id, this.customData});

  final String id;
  final String? customData;

  @override
  String get restorationId => 'bookmark_$id';

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.converter;

  @override
  RestorableConverter<BookmarkRoute> get converter => const BookmarkConverter();

  @override
  Uri toUri() => Uri.parse('/bookmark/$id');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Bookmark $id: $customData'));
  }

  @override
  List<Object?> get props => [id, customData];
}

class BookmarkConverter extends RestorableConverter<BookmarkRoute> {
  const BookmarkConverter();

  @override
  String get key => 'test_bookmark';

  @override
  Map<String, dynamic> serialize(BookmarkRoute route) {
    return {'id': route.id, 'customData': route.customData};
  }

  @override
  BookmarkRoute deserialize(Map<String, dynamic> data) {
    return BookmarkRoute(
      id: data['id'] as String,
      customData: data['customData'] as String?,
    );
  }
}

// Route with RouteRestorable using unique strategy (for testing)
class RestorableProfileRoute extends AppRoute
    with RouteRestorable<RestorableProfileRoute> {
  RestorableProfileRoute(this.id);
  final String id;

  @override
  String get restorationId => 'profile_$id';

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.unique;

  @override
  RestorableConverter<RestorableProfileRoute> get converter =>
      throw UnimplementedError(); // Not used with unique strategy

  @override
  Uri toUri() => Uri.parse('/restorable-profile/$id');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Restorable Profile $id'));
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

class TestCoordinatorModular extends Coordinator<AppRoute>
    with CoordinatorModular {
  TestCoordinatorModular({super.initialRoutePath, required this.modules});

  final List<RouteModule<AppRoute> Function(CoordinatorModular<AppRoute>)>
  modules;

  @override
  Set<RouteModule<AppRoute>> defineModules() {
    return modules.map((e) => e(this)).toSet();
  }

  @override
  AppRoute notFoundRoute(Uri uri) => throw UnimplementedError();
}

class TestCoordinator extends Coordinator<AppRoute> {
  TestCoordinator({super.initialRoutePath, this.parentCoordinator});

  final CoordinatorModular<AppRoute>? parentCoordinator;

  @override
  CoordinatorModular<AppRoute> get coordinator =>
      parentCoordinator != null ? parentCoordinator! : super.coordinator;

  late final tabStack = IndexedStackPath.createWith(
    [HomeTab(), SearchTab()],
    coordinator: this,
    label: 'tabs',
  )..bindLayout(TabLayout.new);
  late final undefinedTabStack = IndexedStackPath.createWith(
    [UndefinedHomeTab(), UndefinedSearchTab()],
    coordinator: this,
    label: 'undefined_tabs',
  );

  @override
  List<StackPath> get paths => [...super.paths, tabStack, undefinedTabStack];

  @override
  void defineConverter() {
    defineRestorableConverter('test_bookmark', () => const BookmarkConverter());
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['bookmark', final id] => BookmarkRoute(id: id),
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
  group('NavigationPath Restoration', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('serializes simple route stack correctly', () async {
      // Build initial stack
      coordinator.root.push(HomeRoute());
      coordinator.root.push(SettingsRoute());
      await Future.delayed(Duration.zero); // Wait for async operations

      // Serialize
      final serialized = coordinator.root.serialize();

      expect(serialized, hasLength(2));
      expect(serialized[0], equals('/'));
      expect(serialized[1], equals('/settings'));
    });

    test('deserializes simple route stack correctly', () {
      // Prepare serialized data
      final serialized = ['/', '/settings'];

      // Deserialize
      final deserialized = coordinator.root.deserialize(
        serialized,
        coordinator.parseRouteFromUriSync,
      );

      expect(deserialized, hasLength(2));
      expect(deserialized[0], isA<HomeRoute>());
      expect(deserialized[1], isA<SettingsRoute>());
    });

    test('restores navigation stack from serialized data', () async {
      // Build initial stack
      coordinator.root.push(HomeRoute());
      coordinator.root.push(SettingsRoute());
      coordinator.root.push(ProfileRoute('123'));
      await Future.delayed(Duration.zero);

      // Serialize
      final serialized = coordinator.root.serialize();

      // Clear stack
      coordinator.root.reset();
      expect(coordinator.root.stack, isEmpty);

      // Restore
      final deserialized = coordinator.root.deserialize(
        serialized,
        coordinator.parseRouteFromUriSync,
      );
      coordinator.root.restore(deserialized);

      // Verify
      expect(coordinator.root.stack.length, 3);
      expect(coordinator.root.stack[0], isA<HomeRoute>());
      expect(coordinator.root.stack[1], isA<SettingsRoute>());
      expect(coordinator.root.stack[2], isA<ProfileRoute>());
      expect((coordinator.root.stack[2] as ProfileRoute).id, equals('123'));
    });

    test('serializes routes with custom converters', () async {
      final bookmark = BookmarkRoute(id: '456', customData: 'test data');
      coordinator.root.push(bookmark);
      await Future.delayed(Duration.zero);

      final serialized = coordinator.root.serialize();

      expect(serialized, hasLength(1));
      expect(serialized[0], isA<Map>());

      final bookmarkData = serialized[0] as Map;
      expect(bookmarkData['strategy'], equals('converter'));
      expect(bookmarkData['converter'], equals('test_bookmark'));
      expect(bookmarkData['value']['id'], equals('456'));
      expect(bookmarkData['value']['customData'], equals('test data'));
    });

    test('deserializes routes with custom converters', () {
      final serialized = [
        {
          'strategy': 'converter',
          'converter': 'test_bookmark',
          'value': {'id': '789', 'customData': 'restored data'},
        },
      ];

      final deserialized = coordinator.root.deserialize(
        serialized,
        coordinator.parseRouteFromUriSync,
      );

      expect(deserialized, hasLength(1));
      expect(deserialized[0], isA<BookmarkRoute>());
      final bookmark = deserialized[0] as BookmarkRoute;
      expect(bookmark.id, equals('789'));
      expect(bookmark.customData, equals('restored data'));
    });

    test('round-trip: serialize then deserialize maintains state', () async {
      // Build complex stack
      coordinator.root.push(HomeRoute());
      coordinator.root.push(BookmarkRoute(id: '123', customData: 'data'));
      coordinator.root.push(SettingsRoute());
      await Future.delayed(Duration.zero);

      // Serialize
      final serialized = coordinator.root.serialize();

      // Deserialize
      final deserialized = coordinator.root.deserialize(
        serialized,
        coordinator.parseRouteFromUriSync,
      );

      // Verify
      expect(deserialized.length, 3);
      expect(deserialized[0], isA<HomeRoute>());
      expect(deserialized[1], isA<BookmarkRoute>());
      expect((deserialized[1] as BookmarkRoute).customData, equals('data'));
      expect(deserialized[2], isA<SettingsRoute>());
    });

    test('throws error when deserializing undefined layout', () {
      final serialized = [
        {'type': 'layout', 'value': 'UndefinedTabLayout'},
      ];

      expect(
        () => coordinator.root.deserialize(serialized),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            contains('UndefinedTabLayout'),
          ),
        ),
      );
    });
  });

  group('IndexedStackPath Restoration', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('serializes active index', () {
      // Change to tab 1
      coordinator.tabStack.goToIndexed(1);

      final serialized = coordinator.tabStack.serialize();

      expect(serialized, equals(1));
    });

    test('deserializes active index', () {
      final deserialized = coordinator.tabStack.deserialize(1);

      expect(deserialized, equals(1));
    });

    test('restores active index correctly', () {
      // Set to tab 1
      coordinator.tabStack.goToIndexed(1);
      expect(coordinator.tabStack.activeIndex, equals(1));

      // Serialize
      final serialized = coordinator.tabStack.serialize();

      // Reset
      coordinator.tabStack.reset();
      expect(coordinator.tabStack.activeIndex, equals(0));

      // Restore
      final deserialized = coordinator.tabStack.deserialize(serialized);
      coordinator.tabStack.restore(deserialized);

      expect(coordinator.tabStack.activeIndex, equals(1));
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });

    test('asserts when restoring out-of-bounds index', () {
      expect(() => coordinator.tabStack.restore(5), throwsAssertionError);
    });
  });

  group('RouteRestorable Mixin', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('serialize creates correct map structure for converter strategy', () {
      final route = BookmarkRoute(id: '123', customData: 'test');

      final serialized = route.serialize();

      expect(serialized['strategy'], equals('converter'));
      expect(serialized['converter'], equals('test_bookmark'));
      expect(serialized['value']['id'], equals('123'));
      expect(serialized['value']['customData'], equals('test'));
    });

    test('serialize creates URI string for unique strategy', () {
      final route = RestorableProfileRoute('456');

      final serialized = route.serialize();

      expect(serialized['strategy'], equals('unique'));
      expect(serialized['value'], equals('/restorable-profile/456'));
    });

    test('deserialize reconstructs route from converter strategy', () {
      final data = {
        'strategy': 'converter',
        'converter': 'test_bookmark',
        'value': {'id': '999', 'customData': 'deserialized'},
      };

      final route = RouteRestorable.deserialize<AppRoute>(
        data,
        parseRouteFromUri: coordinator.parseRouteFromUriSync,
        getRestorableConverter: coordinator.getRestorableConverter,
      );

      expect(route, isA<BookmarkRoute>());
      expect((route as BookmarkRoute).id, equals('999'));
      expect(route.customData, equals('deserialized'));
    });

    test('deserialize reconstructs route from unique strategy', () {
      final data = {'strategy': 'unique', 'value': '/profile/777'};

      final route = RouteRestorable.deserialize<AppRoute>(
        data,
        parseRouteFromUri: coordinator.parseRouteFromUriSync,
        getRestorableConverter: coordinator.getRestorableConverter,
      );

      expect(route, isA<ProfileRoute>());
      expect((route as ProfileRoute).id, equals('777'));
    });

    test('throws on invalid strategy', () {
      final data = {'strategy': null, 'value': '/test'};

      expect(
        () => RouteRestorable.deserialize<AppRoute>(
          data,
          parseRouteFromUri: coordinator.parseRouteFromUriSync,
          getRestorableConverter: coordinator.getRestorableConverter,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('Multi-Path Restoration Integration', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('restores complex coordinator state with multiple paths', () async {
      // Setup complex state
      coordinator.root.push(HomeRoute());
      coordinator.root.push(SettingsRoute());
      coordinator.tabStack.goToIndexed(1);
      await Future.delayed(Duration.zero);

      // Serialize all paths
      final rootData = coordinator.root.serialize();
      final tabData = coordinator.tabStack.serialize();

      // Clear all state
      coordinator.root.reset();
      coordinator.tabStack.reset();

      expect(coordinator.root.stack, isEmpty);
      expect(coordinator.tabStack.activeIndex, equals(0));

      // Restore all paths
      final restoredRoot = coordinator.root.deserialize(
        rootData,
        coordinator.parseRouteFromUriSync,
      );
      coordinator.root.restore(restoredRoot);

      final restoredTab = coordinator.tabStack.deserialize(tabData);
      coordinator.tabStack.restore(restoredTab);

      // Verify all paths restored correctly
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack[0], isA<HomeRoute>());
      expect(coordinator.root.stack[1], isA<SettingsRoute>());

      expect(coordinator.tabStack.activeIndex, equals(1));
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());
    });
  });

  group('CoordinatorRestorable - Listener Management', () {
    testWidgets('updates listeners when coordinator changes', (tester) async {
      final coordinator1 = TestCoordinator();
      final coordinator2 = TestCoordinator();

      // Track listener calls
      var coordinator1Notified = 0;
      var coordinator2Notified = 0;

      coordinator1.addListener(() {
        coordinator1Notified++;
      });

      coordinator2.addListener(() {
        coordinator2Notified++;
      });

      // Create widget with first coordinator
      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'test',
          home: CoordinatorRestorable(
            restorationId: 'coordinator',
            coordinator: coordinator1,
            child: const SizedBox(),
          ),
        ),
      );

      // Make a change to coordinator1 - should trigger save
      coordinator1.push(HomeRoute());
      await tester.pump();

      expect(coordinator1Notified, greaterThan(0));
      expect(coordinator2Notified, equals(0));

      // Update to coordinator2
      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'test',
          home: CoordinatorRestorable(
            restorationId: 'coordinator',
            coordinator: coordinator2,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Make a change to coordinator2 - SHOULD trigger notifications
      // because listeners should have been added
      coordinator2.push(HomeRoute());
      await tester.pump();

      expect(coordinator2Notified, greaterThan(0));
    });

    testWidgets('restores coordinator state correctly after restart', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      // Build app with restoration enabled
      await tester.pumpWidget(
        MaterialApp.router(
          restorationScopeId: 'app',
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      await tester.pumpAndSettle();

      // Set up some navigation state
      coordinator.push(SettingsRoute());
      coordinator.push(ProfileRoute('user123'));
      await tester.pumpAndSettle();

      coordinator.push(SearchTab());

      await tester.pumpAndSettle();

      // Verify initial state
      expect(coordinator.root.stack.length, equals(4));
      expect(coordinator.root.stack[2], isA<ProfileRoute>());
      expect((coordinator.root.stack[2] as ProfileRoute).id, equals('user123'));
      expect(coordinator.root.stack[3], isA<TabLayout>());
      expect(coordinator.tabStack.activeIndex, 1);
      expect(coordinator.tabStack.activeRoute, isA<SearchTab>());

      // Simulate app restart with restoration
      final future = tester.restartAndRestore();
      for (final path in coordinator.paths) {
        path.reset();
      }
      await future;

      // State should be restored
      expect(coordinator.root.stack.length, equals(4));
      expect(coordinator.root.stack[0], isA<HomeRoute>());
      expect(coordinator.root.stack[1], isA<SettingsRoute>());
      expect(coordinator.root.stack[2], isA<ProfileRoute>());
      expect(coordinator.root.stack[3], isA<TabLayout>());
      expect((coordinator.root.stack[2] as ProfileRoute).id, equals('user123'));
      expect(coordinator.tabStack.activeIndex, 1);
    });

    testWidgets('restores RouteRestorable with custom data', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          restorationScopeId: 'app',
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      await tester.pumpAndSettle();

      // Push a route with custom data
      const customData = 'My Bookmark Data';
      coordinator.push(
        BookmarkRoute(id: 'bookmark123', customData: customData),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(coordinator.root.stack.length, equals(2));
      final originalRoute = coordinator.root.stack[1] as BookmarkRoute;
      expect(originalRoute.id, equals('bookmark123'));
      expect(originalRoute.customData, equals(customData));

      // Restart and restore
      // Simulate app restart with restoration
      final future = tester.restartAndRestore();
      for (final path in coordinator.paths) {
        path.reset();
      }
      await future;

      // Verify restored data
      expect(coordinator.root.stack.length, equals(2));
      final restoredRoute = coordinator.root.stack[1] as BookmarkRoute;
      expect(restoredRoute.id, equals('bookmark123'));
      expect(restoredRoute.customData, equals(customData));
    });

    testWidgets('handles empty state restoration', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          restorationScopeId: 'app',
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      await tester.pumpAndSettle();

      // Don't push any routes - test empty state
      expect(coordinator.root.stack.length, equals(1));

      // Restart and restore
      // Simulate app restart with restoration
      final future = tester.restartAndRestore();
      for (final path in coordinator.paths) {
        path.reset();
      }
      await future;

      // Should still be empty
      expect(coordinator.root.stack.length, equals(1));
      expect(coordinator.tabStack.activeIndex, equals(0));
    });

    testWidgets('handles multiple coordinator updates', (tester) async {
      final coordinators = [
        TestCoordinator(),
        TestCoordinator(),
        TestCoordinator(),
      ];

      var currentCoordinatorIndex = 0;

      // Start with first coordinator
      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'test',
          home: CoordinatorRestorable(
            restorationId: 'coordinator',
            coordinator: coordinators[currentCoordinatorIndex],
            child: const SizedBox(),
          ),
        ),
      );

      // Update through all coordinators
      for (var i = 1; i < coordinators.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            restorationScopeId: 'test',
            home: CoordinatorRestorable(
              restorationId: 'coordinator',
              coordinator: coordinators[i],
              child: const SizedBox(),
            ),
          ),
        );

        // Verify widget is still mounted and working
        expect(find.byType(CoordinatorRestorable), findsOneWidget);
      }

      // No exceptions should be thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('no-op when coordinator remains the same', (tester) async {
      final coordinator = TestCoordinator();

      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'test',
          home: CoordinatorRestorable(
            restorationId: 'coordinator',
            coordinator: coordinator,
            child: const SizedBox(),
          ),
        ),
      );

      // Trigger rebuild with same coordinator
      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'test',
          home: CoordinatorRestorable(
            restorationId: 'coordinator',
            coordinator: coordinator, // Same instance
            child: const SizedBox(),
          ),
        ),
      );

      // Should not throw and should continue working
      coordinator.push(HomeRoute());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('CoordinatorRestorable with asRouterConfig', () {
    testWidgets(
      'sets initial route path when useAsRouterConfig is true and no active route',
      (tester) async {
        final coordinator = TestCoordinator();
        final config = coordinator;

        await tester.pumpWidget(MaterialApp.router(routerConfig: config));

        await tester.pumpAndSettle();

        // Should have initial route set
        expect(coordinator.root.stack.length, equals(1));
        expect(coordinator.root.stack[0], isA<HomeRoute>());
      },
    );

    testWidgets('respects custom initialRoutePath when using asRouterConfig', (
      tester,
    ) async {
      final coordinator = TestCoordinator(
        initialRoutePath: Uri.parse('/settings'),
      );
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));

      await tester.pumpAndSettle();

      // Should have custom initial route set
      expect(coordinator.root.stack.length, equals(1));
      expect(coordinator.root.stack[0], isA<SettingsRoute>());
    });

    testWidgets('navigation push works after asRouterConfig initialization', (
      tester,
    ) async {
      final coordinator = TestCoordinator();
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();

      // Reset to known state
      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      // Push a route
      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, equals(2));
      expect(coordinator.root.stack[1], isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('navigation pop works with asRouterConfig', (tester) async {
      final coordinator = TestCoordinator();
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();

      // Reset to known state and push routes
      coordinator.replace(HomeRoute());
      coordinator.push(SettingsRoute());
      coordinator.push(ProfileRoute('123'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, equals(3));
      expect(find.text('Profile 123'), findsOneWidget);

      // Pop
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, equals(2));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tab navigation works with asRouterConfig', (tester) async {
      final coordinator = TestCoordinator();
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();

      // Navigate to tab layout
      await coordinator.recover(HomeTab());
      await tester.pumpAndSettle();

      expect(find.text('Home Tab'), findsOneWidget);

      // Switch tabs
      coordinator.tabStack.activateRoute(SearchTab());
      await tester.pumpAndSettle();

      expect(find.text('Search Tab'), findsOneWidget);
      expect(coordinator.tabStack.activeIndex, equals(1));
    });

    testWidgets('setNewRoutePath works with asRouterConfig', (tester) async {
      final coordinator = TestCoordinator();
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();

      // Reset to known state
      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // Simulate URL change
      await coordinator.routerDelegate.setNewRoutePath(Uri.parse('/settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(coordinator.root.stack.length, equals(2));
    });

    testWidgets('URL updates correctly with asRouterConfig', (tester) async {
      final coordinator = TestCoordinator();
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();

      expect(coordinator.currentUri.toString(), '/');

      coordinator.push(ProfileRoute('user456'));
      await tester.pumpAndSettle();

      expect(coordinator.currentUri.toString(), '/profile/user456');
    });

    testWidgets('replace navigation works with asRouterConfig', (tester) async {
      final coordinator = TestCoordinator();
      final config = coordinator;

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();

      // Reset to known state and push some routes
      coordinator.replace(HomeRoute());
      coordinator.push(SettingsRoute());
      coordinator.push(ProfileRoute('123'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, equals(3));

      // Replace clears the stack
      coordinator.replace(HomeRoute());
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, equals(1));
      expect(coordinator.root.stack[0], isA<HomeRoute>());
    });
  });

  group('isRouteModule cases', () {
    test(
      'shares layoutKeyTable and converterTable with parent coordinator',
      () {
        final parentCoordinator = TestCoordinatorModular(
          modules: [(parent) => TestCoordinator(parentCoordinator: parent)],
        );

        final childCoordinator = parentCoordinator.getModule<TestCoordinator>();

        expect(childCoordinator.isRouteModule, isTrue);

        // Verify layoutKeyTable is shared
        parentCoordinator.encodeLayoutKey('test_layout');
        expect(
          childCoordinator.layoutKeyTable.containsKey('test_layout'),
          isTrue,
        );

        childCoordinator.encodeLayoutKey('child_layout');
        expect(
          parentCoordinator.layoutKeyTable.containsKey('child_layout'),
          isTrue,
        );

        // Verify converterTable is shared
        parentCoordinator.defineRestorableConverter(
          'parent_conv',
          () => const BookmarkConverter(),
        );
        expect(
          childCoordinator.converterTable.containsKey('parent_conv'),
          isTrue,
        );

        childCoordinator.defineRestorableConverter(
          'child_conv',
          () => const BookmarkConverter(),
        );
        expect(
          parentCoordinator.converterTable.containsKey('child_conv'),
          isTrue,
        );
      },
    );

    test(
      'uses own layoutKeyTable and converterTable when isRouteModule is false',
      () {
        final coordinator = TestCoordinator();

        expect(coordinator.isRouteModule, isFalse);

        coordinator.encodeLayoutKey('test_layout');
        expect(coordinator.layoutKeyTable.containsKey('test_layout'), isTrue);

        coordinator.defineRestorableConverter(
          'test_conv',
          () => const BookmarkConverter(),
        );
        expect(coordinator.converterTable.containsKey('test_conv'), isTrue);
      },
    );
  });
}
