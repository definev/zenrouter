import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Setup
// ============================================================================

abstract class LayoutRoute extends RouteTarget with RouteUnique {}

class HomeLayoutRoute extends LayoutRoute with RouteLayout<LayoutRoute> {
  @override
  StackPath<RouteUnique> resolvePath(TestCoordinator coordinator) =>
      coordinator.nestedPath;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('home-layout'),
      body: const Text('Home Layout'),
    );
  }
}

class SettingsLayoutRoute extends LayoutRoute with RouteLayout<LayoutRoute> {
  @override
  StackPath<RouteUnique> resolvePath(TestCoordinator coordinator) =>
      coordinator.settingsPath;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('settings-layout'),
      body: const Text('Settings Layout'),
    );
  }
}

class HomeChildRoute extends LayoutRoute {
  @override
  Type? get layout => HomeLayoutRoute;

  @override
  Uri toUri() => Uri.parse('/home/child');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home Child'));
  }

  @override
  List<Object?> get props => [];
}

class SettingsChildRoute extends LayoutRoute {
  @override
  Type? get layout => SettingsLayoutRoute;

  @override
  Uri toUri() => Uri.parse('/settings/child');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings Child'));
  }

  @override
  List<Object?> get props => [];
}

class TestCoordinator extends Coordinator<LayoutRoute> {
  late final nestedPath = NavigationPath<LayoutRoute>.create(
    label: 'nested',
    coordinator: this,
  );

  late final settingsPath = NavigationPath<LayoutRoute>.create(
    label: 'settings',
    coordinator: this,
  );

  @override
  List<StackPath> get paths => [...super.paths, nestedPath, settingsPath];

  @override
  LayoutRoute parseRouteFromUri(Uri uri) {
    return HomeChildRoute();
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('CoordinatorLayout - defineLayoutParentConstructor', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('registers a layout parent constructor', () {
      expect(coordinator.getLayoutParentConstructor(HomeLayoutRoute), isNull);

      coordinator.defineLayoutParentConstructor(
        HomeLayoutRoute,
        (key) => HomeLayoutRoute(),
      );

      expect(
        coordinator.getLayoutParentConstructor(HomeLayoutRoute),
        isNotNull,
      );
    });

    test('allows overriding existing layout parent constructor', () {
      HomeLayoutRoute originalConstructor(key) => HomeLayoutRoute();
      SettingsLayoutRoute overrideConstructor(key) => SettingsLayoutRoute();

      coordinator.defineLayoutParentConstructor(
        HomeLayoutRoute,
        originalConstructor,
      );
      expect(
        coordinator.getLayoutParentConstructor(HomeLayoutRoute),
        isNotNull,
      );

      coordinator.defineLayoutParentConstructor(
        HomeLayoutRoute,
        overrideConstructor,
      );

      final constructor = coordinator.getLayoutParentConstructor(
        HomeLayoutRoute,
      );
      expect(constructor, isNotNull);
      expect(constructor!(HomeLayoutRoute), isA<SettingsLayoutRoute>());
    });
  });

  group('CoordinatorLayout - getLayoutParentConstructor', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('returns null for unregistered layout key', () {
      expect(coordinator.getLayoutParentConstructor(HomeLayoutRoute), isNull);
    });

    test('returns registered constructor for layout key', () {
      coordinator.defineLayoutParentConstructor(
        HomeLayoutRoute,
        (key) => HomeLayoutRoute(),
      );

      final constructor = coordinator.getLayoutParentConstructor(
        HomeLayoutRoute,
      );
      expect(constructor, isNotNull);
    });
  });

  group('CoordinatorLayout - createLayoutParent', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('creates layout parent instance using registered constructor', () {
      coordinator.defineLayoutParentConstructor(
        HomeLayoutRoute,
        (key) => HomeLayoutRoute(),
      );

      final layoutParent = coordinator.createLayoutParent(HomeLayoutRoute);
      expect(layoutParent, isA<HomeLayoutRoute>());
    });

    test('returns null for unregistered layout key', () {
      final layoutParent = coordinator.createLayoutParent(HomeLayoutRoute);
      expect(layoutParent, isNull);
    });
  });

  group('CoordinatorLayout - defineLayoutBuilder', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('registers a layout builder for a PathKey', () {
      expect(coordinator.getLayoutBuilder(NavigationPath.key), isNotNull);

      SizedBox customBuilder<T extends RouteUnique>(
        Coordinator coordinator,
        StackPath<T> path,
        RouteLayout<T>? layout,
      ) {
        return const SizedBox();
      }

      coordinator.defineLayoutBuilder(NavigationPath.key, customBuilder);

      final builder = coordinator.getLayoutBuilder(NavigationPath.key);
      expect(builder, isNotNull);
    });
  });

  group('CoordinatorLayout - getLayoutBuilder', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('returns default builder for NavigationPath.key', () {
      final builder = coordinator.getLayoutBuilder(NavigationPath.key);
      expect(builder, isNotNull);
    });

    test('returns default builder for IndexedStackPath.key', () {
      final builder = coordinator.getLayoutBuilder(IndexedStackPath.key);
      expect(builder, isNotNull);
    });

    test('returns null for unregistered PathKey', () {
      final customKey = PathKey('custom');
      final builder = coordinator.getLayoutBuilder(customKey);
      expect(builder, isNull);
    });

    test('returns custom builder after being defined', () {
      Widget customBuilder<T extends RouteUnique>(
        Coordinator coordinator,
        StackPath<T> path,
        RouteLayout<T>? layout,
      ) {
        return const SizedBox();
      }

      final customKey = PathKey('customKey');

      coordinator.defineLayoutBuilder(customKey, customBuilder);

      final builder = coordinator.getLayoutBuilder(customKey);
      expect(builder, isNotNull);
    });
  });

  group('CoordinatorLayout - Integration', () {
    testWidgets('layout parent constructor is used during navigation', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      coordinator.defineLayoutParentConstructor(
        HomeLayoutRoute,
        (key) => HomeLayoutRoute(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(HomeChildRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home-layout')), findsOneWidget);
    });

    testWidgets('custom layout builder is used during rendering', (
      tester,
    ) async {
      final coordinator = TestCoordinator();

      bool customBuilderCalled = false;
      Widget customBuilder<T extends RouteUnique>(
        Coordinator coordinator,
        StackPath<T> path,
        RouteLayout<T>? layout,
      ) {
        customBuilderCalled = true;
        return const SizedBox();
      }

      coordinator.defineLayoutBuilder(NavigationPath.key, customBuilder);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      expect(customBuilderCalled, isTrue);
    });
  });
}
