import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Application Setup
// ============================================================================

/// Base route for all test routes
abstract class ErrorTestRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

/// Simple route for basic testing
class SimpleErrorRoute extends ErrorTestRoute {
  SimpleErrorRoute({this.id = 'default'});
  final String id;

  @override
  Uri toUri() => Uri.parse('/simple/$id');

  @override
  Widget build(
    covariant ErrorTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(key: ValueKey('simple-$id'), body: Text('Simple: $id'));
  }

  @override
  List<Object?> get props => [id];
}

// Mock a custom StackPath type by using a fake Type
class FakeStackPathType {}

/// Layout that uses a non-existent path type name for testing
class MockUnregisteredPathLayout extends ErrorTestRoute
    with RouteLayout<ErrorTestRoute> {
  @override
  UnregisteredCustomPath<ErrorTestRoute> resolvePath(
    ErrorTestCoordinator coordinator,
  ) => coordinator.testStack;

  @override
  Uri toUri() => Uri.parse('/mock-unregistered-layout');

  @override
  List<Object?> get props => [];
}

/// Layout type that is NOT defined in defineLayout (for testing constructor error)
class UndefinedLayout extends ErrorTestRoute with RouteLayout<ErrorTestRoute> {
  @override
  UnregisteredCustomPath<ErrorTestRoute> resolvePath(
    ErrorTestCoordinator coordinator,
  ) => coordinator.testStack;

  @override
  Uri toUri() => Uri.parse('/undefined-layout');

  @override
  List<Object?> get props => [];
}

/// Route that requires UndefinedLayout
class RouteWithUndefinedLayout extends ErrorTestRoute {
  @override
  Type get layout => UndefinedLayout;

  @override
  Uri toUri() => Uri.parse('/route-with-undefined-layout');

  @override
  Widget build(
    covariant ErrorTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('route-with-undefined-layout'),
      body: const Text('Should not render'),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Child route that uses MockUnregisteredPathLayout as its layout
class RouteWithMockLayout extends ErrorTestRoute {
  @override
  Type get layout => MockUnregisteredPathLayout;

  @override
  Uri toUri() => Uri.parse('/route-with-mock-layout');

  @override
  Widget build(
    covariant ErrorTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('route-with-mock-layout'),
      body: const Text('Should not render'),
    );
  }

  @override
  List<Object?> get props => [];
}

class NormalIndexedStackLayout extends ErrorTestRoute
    with RouteLayout<ErrorTestRoute> {
  @override
  IndexedStackPath<ErrorTestRoute> resolvePath(
    ErrorTestCoordinator coordinator,
  ) => coordinator.normalIndexedStack;

  @override
  Uri toUri() => Uri.parse('/normal-indexed-stack-layout');

  @override
  List<Object?> get props => [];
}

class NormalNavigationLayout extends ErrorTestRoute
    with RouteLayout<ErrorTestRoute> {
  @override
  NavigationPath<ErrorTestRoute> resolvePath(
    ErrorTestCoordinator coordinator,
  ) => coordinator.normalStack;

  @override
  Uri toUri() => Uri.parse('/normal-layout');

  @override
  List<Object?> get props => [];
}

/// Route that is NOT in the IndexedStackPath but uses the same layout
class MissingTabRoute extends ErrorTestRoute {
  @override
  Type get layout => NormalIndexedStackLayout;

  @override
  Uri toUri() => Uri.parse('/missing-tab');

  @override
  Widget build(
    covariant ErrorTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const Scaffold(
      key: ValueKey('missing-tab'),
      body: Text('Missing Tab'),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Test coordinator
class ErrorTestCoordinator extends Coordinator<ErrorTestRoute> {
  late final UnregisteredCustomPath<ErrorTestRoute> testStack =
      UnregisteredCustomPath(coordinator: this, label: 'test');
  late final NavigationPath<ErrorTestRoute> normalStack =
      NavigationPath.createWith(coordinator: this, label: 'root');
  late final IndexedStackPath<ErrorTestRoute> normalIndexedStack =
      IndexedStackPath.createWith(
        [SimpleErrorRoute(id: 'home')],
        coordinator: this,
        label: 'root',
      );

  @override
  void defineLayout() {
    // Intentionally NOT defining UndefinedLayout to test the error
    // But DO define MockUnregisteredPathLayout so we can test the path builder error
    defineLayoutParent(MockUnregisteredPathLayout.new);
    defineLayoutParent(NormalIndexedStackLayout.new);
  }

  @override
  List<StackPath> get paths => [...super.paths, testStack];

  @override
  ErrorTestRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return SimpleErrorRoute(id: 'home');

    return switch (segments) {
      ['simple', final id] => SimpleErrorRoute(id: id),
      ['mock-unregistered-layout'] => MockUnregisteredPathLayout(),
      ['route-with-mock-layout'] => RouteWithMockLayout(),
      ['undefined-layout'] => UndefinedLayout(),
      ['route-with-undefined-layout'] => RouteWithUndefinedLayout(),
      _ => SimpleErrorRoute(id: 'home'),
    };
  }
}

// Custom StackPath that will not have a registered builder
class UnregisteredCustomPath<T extends RouteUnique> extends StackPath<T>
    with ChangeNotifier {
  final List<T> _internalStack;
  UnregisteredCustomPath({
    required Coordinator coordinator,
    required String label,
  }) : _internalStack = <T>[],
       super(<T>[], debugLabel: label, coordinator: coordinator);

  @override
  PathKey get pathKey => const PathKey('FakeStackPathType');

  @override
  T? get activeRoute => _internalStack.isEmpty ? null : _internalStack.last;

  @override
  Future<void> activateRoute(T route) async {
    if (!_internalStack.contains(route)) {
      _internalStack.add(route);
    }
    notifyListeners();
  }

  @override
  void reset() {
    _internalStack.clear();
    notifyListeners();
  }

  @override
  List<T> get stack => List.unmodifiable(_internalStack);
}

class LayoutWithUnregisteredPath extends ErrorTestRoute
    with RouteLayout<ErrorTestRoute> {
  final UnregisteredCustomPath<ErrorTestRoute> customPath;

  LayoutWithUnregisteredPath(this.customPath);

  @override
  StackPath<RouteUnique> resolvePath(ErrorTestCoordinator coordinator) =>
      customPath;

  @override
  Uri toUri() => Uri.parse('/layout-unregistered-path');

  @override
  List<Object?> get props => [];
}

class GuardedTestRoute extends ErrorTestRoute with RouteGuard {
  GuardedTestRoute({this.allowPop = true});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/guarded');

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(
    covariant ErrorTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const Scaffold(body: Text('Guarded'));
  }

  @override
  List<Object?> get props => [allowPop];
}

class SecondCoordinator extends Coordinator<ErrorTestRoute> {
  @override
  void defineLayout() {}

  @override
  ErrorTestRoute parseRouteFromUri(Uri uri) {
    return SimpleErrorRoute(id: 'second');
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('IndexedStackPath Error Tests', () {
    test(
      'goToIndexed throws StateError with meaningful message for out of bounds index',
      () {
        final stack = IndexedStackPath<ErrorTestRoute>.create([
          SimpleErrorRoute(id: 'tab1'),
          SimpleErrorRoute(id: 'tab2'),
          SimpleErrorRoute(id: 'tab3'),
        ], label: 'test-tabs');

        // Test index too high
        expect(
          () => stack.goToIndexed(3),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Index out of bounds',
            ),
          ),
        );

        expect(
          () => stack.goToIndexed(99),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Index out of bounds',
            ),
          ),
        );
      },
    );

    test('goToIndexed allows valid indices', () {
      final stack = IndexedStackPath<ErrorTestRoute>.create([
        SimpleErrorRoute(id: 'tab1'),
        SimpleErrorRoute(id: 'tab2'),
        SimpleErrorRoute(id: 'tab3'),
      ], label: 'test-tabs');

      // These should not throw
      expect(() => stack.goToIndexed(0), returnsNormally);
      expect(() => stack.goToIndexed(1), returnsNormally);
      expect(() => stack.goToIndexed(2), returnsNormally);
    });

    test(
      'activateRoute throws StateError with meaningful message for route not in stack',
      () {
        final stack = IndexedStackPath<ErrorTestRoute>.create([
          SimpleErrorRoute(id: 'tab1'),
          SimpleErrorRoute(id: 'tab2'),
        ], label: 'test-tabs');

        final missingRoute = SimpleErrorRoute(id: 'not-in-stack');

        expect(
          () => stack.activateRoute(missingRoute),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Route not found',
            ),
          ),
        );
      },
    );

    test('activateRoute works for routes that are in stack', () {
      final route1 = SimpleErrorRoute(id: 'tab1');
      final route2 = SimpleErrorRoute(id: 'tab2');

      final stack = IndexedStackPath<ErrorTestRoute>.create([
        route1,
        route2,
      ], label: 'test-tabs');

      // Should not throw
      expect(() => stack.activateRoute(route1), returnsNormally);
      expect(() => stack.activateRoute(route2), returnsNormally);
    });
  });

  group('RouteLayout Error Tests', () {
    test(
      'buildPath throws UnimplementedError with helpful message for unregistered StackPath type',
      () {
        final coordinator = ErrorTestCoordinator();

        final errorLayout = MockUnregisteredPathLayout();

        expect(
          () => errorLayout.buildPath(coordinator),
          throwsA(
            isA<UnimplementedError>()
                .having(
                  (e) => e.message,
                  'message',
                  contains(
                    'No layout builder provided for [FakeStackPathType]',
                  ),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains(
                    'If you extend the [StackPath] class, you must register it',
                  ),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('[RouteLayout.definePath]'),
                ),
          ),
        );
      },
    );

    testWidgets(
      'RouteLayout.build throws UnimplementedError when path layout not registered',
      (tester) async {
        final coordinator = ErrorTestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Push a child route that HAS MockUnregisteredPathLayout as its layout
        // Don't await push -it returns a future that completes when route is popped
        coordinator.push(RouteWithMockLayout());

        // Try to build - this will trigger the error during the build phase
        await tester.pumpAndSettle();

        // Flutter catches build errors, so we need to retrieve it using takeException
        final exception = tester.takeException();
        expect(exception, isA<UnimplementedError>());
        expect(
          (exception as UnimplementedError).message,
          contains('No layout builder provided for [FakeStackPathType]'),
        );
      },
    );
  });

  group('Error Message Quality Tests', () {
    test('StateError messages are concise and clear', () async {
      final stack = IndexedStackPath<ErrorTestRoute>.create([
        SimpleErrorRoute(id: 'tab1'),
      ], label: 'test');

      try {
        await stack.goToIndexed(5);
        fail('Should have thrown StateError');
      } on StateError catch (e) {
        // Verify message is concise and actionable
        expect(e.message, 'Index out of bounds');
        expect(e.message.length, lessThan(50)); // Keep it short
      }

      try {
        await stack.activateRoute(SimpleErrorRoute(id: 'missing'));
        fail('Should have thrown StateError');
      } on StateError catch (e) {
        // Verify message is concise and actionable
        expect(e.message, 'Route not found');
        expect(e.message.length, lessThan(50)); // Keep it short
      }
    });

    test('UnimplementedError messages contain actionable information', () {
      final coordinator = ErrorTestCoordinator();

      final errorLayout = MockUnregisteredPathLayout();

      // Test buildPath error
      try {
        errorLayout.buildPath(coordinator);
        fail('Should have thrown UnimplementedError');
      } on UnimplementedError catch (e) {
        // Should mention the type name
        expect(e.message, contains('FakeStackPathType'));
        // Should tell where to register
        expect(e.message, contains('RouteLayout.definePath'));
        // Should explain the condition
        expect(e.message, contains('extend the [StackPath]'));
      }

      // Test createLayout error
      try {
        RouteWithUndefinedLayout().createLayout(coordinator);
        fail('Should have thrown UnimplementedError');
      } on UnimplementedError catch (e) {
        // Should mention the layout type
        expect(e.message, contains('UndefinedLayout'));
        // Should tell where to define
        expect(e.message, contains('defineLayout'));
        // Should mention how to define
        expect(e.message, contains('bindLayout'));
        expect(e.message, contains('defineRouteLayout'));
        // Should reference your coordinator
        expect(e.message, contains('ErrorTestCoordinator'));
      }
    });

    test('Error messages guide developers to the solution', () {
      // Test that error messages include:
      // 1. What went wrong (the type/value that caused the issue)
      // 2. Where to fix it (the class/table/method)
      // 3. How to fix it (register/define/add)

      final coordinator = ErrorTestCoordinator();

      try {
        RouteWithUndefinedLayout().createLayout(coordinator);
        fail('Should have thrown');
      } on UnimplementedError catch (e) {
        final message = e.message ?? '';

        // What: mentions the specific layout type
        expect(message, contains('Missing'));
        expect(message, contains('UndefinedLayout'));

        // Where: mentions where to register
        expect(message, contains('bindLayout'));
        expect(message, contains('defineRouteLayout'));
        expect(message, contains('defineLayout'));
        expect(message, contains('ErrorTestCoordinator'));
      }
    });
  });

  group('Error Prevention Tests', () {
    test('IndexedStackPath prevents invalid construction', () {
      // Empty stack should be caught by assertion
      expect(
        () => IndexedStackPath<ErrorTestRoute>.create([], label: 'test'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Registered types do not throw errors', () {
      final coordinator = ErrorTestCoordinator();

      final normalLayout = NormalNavigationLayout();

      // NavigationPath is registered by default
      expect(() => normalLayout.buildPath(coordinator), returnsNormally);

      // IndexedStackPath is registered by default
      final indexedStackLayout = NormalIndexedStackLayout();
      expect(() => indexedStackLayout.buildPath(coordinator), returnsNormally);
    });
  });

  group('RouteLayout.build Error Tests', () {
    testWidgets(
      'RouteLayout.build throws UnimplementedError when builder is null',
      (tester) async {
        final coordinator = ErrorTestCoordinator();
        final customPath = UnregisteredCustomPath<ErrorTestRoute>(
          coordinator: coordinator,
          label: 'custom',
        );
        final layout = LayoutWithUnregisteredPath(customPath);

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Push the layout which will trigger RouteLayout.build
        coordinator.push(layout);
        await tester.pumpAndSettle();

        // Flutter catches build errors
        final exception = tester.takeException();
        expect(exception, isA<UnimplementedError>());
        expect(
          (exception as UnimplementedError).message,
          contains('If you extend the [StackPath] class, you must register it'),
        );
      },
    );

    test('RouteLayout.build error message is helpful', () {
      final coordinator = ErrorTestCoordinator();
      final customPath = UnregisteredCustomPath<ErrorTestRoute>(
        coordinator: coordinator,
        label: 'custom',
      );
      final layout = LayoutWithUnregisteredPath(customPath);

      // Verify that attempting to build will throw an error
      // by checking that buildPath fails for this type
      expect(
        () => layout.buildPath(coordinator),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            contains('definePath'),
          ),
        ),
      );
    });
  });

  group('RouteGuard.popGuardWith Assertion Tests', () {
    test('popGuardWith asserts when coordinator mismatch', () async {
      final coordinator1 = ErrorTestCoordinator();
      final coordinator2 = SecondCoordinator();

      final route = GuardedTestRoute();

      // Push the route to coordinator1
      coordinator1.push(route);

      // Try to call popGuardWith with coordinator2 (wrong coordinator)
      expect(
        () => route.popGuardWith(coordinator2),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'popGuardWith assertion message contains helpful information',
      () async {
        final coordinator1 = ErrorTestCoordinator();
        final coordinator2 = SecondCoordinator();

        final route = GuardedTestRoute();

        // Push the route to coordinator1
        coordinator1.push(route);

        // Try to call popGuardWith with coordinator2
        try {
          route.popGuardWith(coordinator2);
          fail('Should have thrown AssertionError');
        } on AssertionError catch (e) {
          final message = e.message.toString();
          // Should mention RouteGuard
          expect(message, contains('RouteGuard'));
          // Should mention the expected coordinator
          expect(message, contains('Expected coordinator'));
          // Should mention path's coordinator
          expect(message, contains('Path\'s coordinator'));
          // Should guide on using createWith
          expect(message, contains('.createWith()'));
        }
      },
    );

    test('popGuardWith works correctly when coordinators match', () async {
      final coordinator = ErrorTestCoordinator();
      final route = GuardedTestRoute(allowPop: true);

      coordinator.push(route);
      await Future.delayed(Duration.zero);

      // Should not throw when using the correct coordinator
      final result = await route.popGuardWith(coordinator);
      expect(result, isTrue);
    });

    test('popGuardWith respects popGuard return value', () async {
      final coordinator = ErrorTestCoordinator();

      // Test with allowPop = false
      final blockedRoute = GuardedTestRoute(allowPop: false);
      coordinator.push(blockedRoute);
      await Future.delayed(Duration.zero);

      final blockedResult = await blockedRoute.popGuardWith(coordinator);
      expect(blockedResult, isFalse);

      // Clear the stack
      coordinator.root.reset();

      // Test with allowPop = true
      final allowedRoute = GuardedTestRoute(allowPop: true);
      coordinator.push(allowedRoute);
      await Future.delayed(Duration.zero);

      final allowedResult = await allowedRoute.popGuardWith(coordinator);
      expect(allowedResult, isTrue);
    });

    testWidgets(
      'popGuardWith assertion prevents incorrect coordinator usage in navigation',
      (tester) async {
        final coordinator1 = ErrorTestCoordinator();
        final coordinator2 = SecondCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator1.routerDelegate,
            routeInformationParser: coordinator1.routeInformationParser,
          ),
        );

        final route = GuardedTestRoute();
        coordinator1.push(route);
        await tester.pumpAndSettle();

        // Attempting to use the wrong coordinator should trigger the assertion
        expect(
          () => route.popGuardWith(coordinator2),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('IndexedStackPath Missing Route Tests', () {
    test(
      'resolveLayout throws AssertionError when route not in IndexedStackPath',
      () {
        final coordinator = ErrorTestCoordinator();
        final missingRoute = MissingTabRoute();

        // Attempting to resolve layout for a route that's not in the IndexedStackPath
        // should trigger an assertion error
        expect(
          () => missingRoute.resolveParentLayout(coordinator),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message.toString(),
              'message',
              allOf([
                contains('MissingTabRoute'),
                contains('IndexedStackPath'),
                contains('not present in the initial stack'),
                contains('root'), // The label of the indexed stack
                contains('Fix:'),
                contains('IndexedStackPath.createWith'),
              ]),
            ),
          ),
        );
      },
    );

    testWidgets(
      'navigate fails gracefully when route not in IndexedStackPath (production mode)',
      (tester) async {
        final coordinator = ErrorTestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        // Test the guard in navigate() that prevents crashes when route is not in IndexedStackPath
        // Even if the assertion in resolveLayout is bypassed, navigate should handle this gracefully

        // First establish the IndexedStackPath layout
        coordinator.push(NormalIndexedStackLayout());
        await tester.pumpAndSettle();

        // Now directly call navigate with a route not in the stack
        final missingRoute = MissingTabRoute();

        // Create the layout manually to verify route is not in the stack
        final layout = NormalIndexedStackLayout();
        final path = layout.resolvePath(coordinator);

        // Verify the route is not in the stack
        expect(
          path.stack.any((r) => r.runtimeType == MissingTabRoute),
          isFalse,
        );

        try {
          // The navigate method should handle this gracefully and not crash
          await coordinator.navigate(missingRoute);
          await tester.pumpAndSettle();
        } on AssertionError catch (e) {
          final message = e.message.toString();

          // Should mention the route type
          expect(message, contains('MissingTabRoute'));

          // Should mention IndexedStackPath
          expect(message, contains('IndexedStackPath'));

          // Should show the path label
          expect(message, contains('root'));

          // Should explain the problem
          expect(message, contains('not present in the initial stack'));

          // Should show current stack contents
          expect(message, contains('Current stack'));
          expect(message, contains('SimpleErrorRoute'));

          // Should provide a fix with code example
          expect(message, contains('Fix:'));
          expect(message, contains('IndexedStackPath.createWith'));
          expect(message, contains('MissingTabRoute()'));
        }
      },
    );

    test('assertion message includes helpful information', () {
      final coordinator = ErrorTestCoordinator();
      final missingRoute = MissingTabRoute();

      try {
        missingRoute.resolveParentLayout(coordinator);
        fail('Should have thrown AssertionError');
      } on AssertionError catch (e) {
        final message = e.message.toString();

        // Should mention the route type
        expect(message, contains('MissingTabRoute'));

        // Should mention IndexedStackPath
        expect(message, contains('IndexedStackPath'));

        // Should show the path label
        expect(message, contains('root'));

        // Should explain the problem
        expect(message, contains('not present in the initial stack'));

        // Should show current stack contents
        expect(message, contains('Current stack'));
        expect(message, contains('SimpleErrorRoute'));

        // Should provide a fix with code example
        expect(message, contains('Fix:'));
        expect(message, contains('IndexedStackPath.createWith'));
        expect(message, contains('MissingTabRoute()'));
      }
    });
  });
}
