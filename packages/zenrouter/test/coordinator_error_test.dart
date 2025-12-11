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
  NavigationPath<ErrorTestRoute> resolvePath(
    ErrorTestCoordinator coordinator,
  ) => coordinator.testStack;

  @override
  Uri toUri() => Uri.parse('/mock-unregistered-layout');

  // Override build to manually test buildPrimitivePath with fake type
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    final testCoordinator = coordinator as ErrorTestCoordinator;
    // This will trigger the error when called
    return RouteLayout.buildPrimitivePath(
      FakeStackPathType,
      testCoordinator,
      testCoordinator.testStack,
      this,
    );
  }

  @override
  List<Object?> get props => [];
}

/// Layout type that is NOT defined in defineLayout (for testing constructor error)
class UndefinedLayout extends ErrorTestRoute with RouteLayout<ErrorTestRoute> {
  @override
  NavigationPath<ErrorTestRoute> resolvePath(
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

/// Test coordinator
class ErrorTestCoordinator extends Coordinator<ErrorTestRoute> {
  final NavigationPath<ErrorTestRoute> testStack = NavigationPath('test');

  @override
  void defineLayout() {
    // Intentionally NOT defining UndefinedLayout to test the error
    // But DO define MockUnregisteredPathLayout so we can test the path builder error
    RouteLayout.defineLayout(
      MockUnregisteredPathLayout,
      () => MockUnregisteredPathLayout(),
    );
  }

  @override
  List<StackPath> get paths => [root, testStack];

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

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('IndexedStackPath Error Tests', () {
    test(
      'goToIndexed throws StateError with meaningful message for out of bounds index',
      () {
        final stack = IndexedStackPath<ErrorTestRoute>([
          SimpleErrorRoute(id: 'tab1'),
          SimpleErrorRoute(id: 'tab2'),
          SimpleErrorRoute(id: 'tab3'),
        ], 'test-tabs');

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
      final stack = IndexedStackPath<ErrorTestRoute>([
        SimpleErrorRoute(id: 'tab1'),
        SimpleErrorRoute(id: 'tab2'),
        SimpleErrorRoute(id: 'tab3'),
      ], 'test-tabs');

      // These should not throw
      expect(() => stack.goToIndexed(0), returnsNormally);
      expect(() => stack.goToIndexed(1), returnsNormally);
      expect(() => stack.goToIndexed(2), returnsNormally);
    });

    test(
      'activateRoute throws StateError with meaningful message for route not in stack',
      () {
        final stack = IndexedStackPath<ErrorTestRoute>([
          SimpleErrorRoute(id: 'tab1'),
          SimpleErrorRoute(id: 'tab2'),
        ], 'test-tabs');

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

      final stack = IndexedStackPath<ErrorTestRoute>([
        route1,
        route2,
      ], 'test-tabs');

      // Should not throw
      expect(() => stack.activateRoute(route1), returnsNormally);
      expect(() => stack.activateRoute(route2), returnsNormally);
    });
  });

  group('RouteLayout Error Tests', () {
    test(
      'buildPrimitivePath throws UnimplementedError with helpful message for unregistered StackPath type',
      () {
        final coordinator = ErrorTestCoordinator();

        expect(
          () => RouteLayout.buildPrimitivePath(
            FakeStackPathType,
            coordinator,
            coordinator.testStack,
            null,
          ),
          throwsA(
            isA<UnimplementedError>()
                .having(
                  (e) => e.message,
                  'message',
                  contains(
                    'You are not provide layout builder for [FakeStackPathType] yet',
                  ),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains(
                    'If you extends [StackPath] class you must register it',
                  ),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('[RouteLayout.layoutBuilderTable]'),
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
          contains(
            'You are not provide layout builder for [FakeStackPathType] yet',
          ),
        );
      },
    );

    test(
      'createLayout throws UnimplementedError with helpful message when layout constructor not defined',
      () {
        final coordinator = ErrorTestCoordinator();
        final route = RouteWithUndefinedLayout();

        expect(
          () => route.createLayout(coordinator),
          throwsA(
            isA<UnimplementedError>()
                .having(
                  (e) => e.message,
                  'message',
                  contains(
                    'Layout constructor for [UndefinedLayout] must define',
                  ),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('[RouteLayout.layoutConstructorTable]'),
                )
                .having(
                  (e) => e.message,
                  'message',
                  contains('[defineLayout] function'),
                )
                .having((e) => e.message, 'message', contains('[Coordinator]')),
          ),
        );
      },
    );
  });

  group('Error Message Quality Tests', () {
    test('StateError messages are concise and clear', () async {
      final stack = IndexedStackPath<ErrorTestRoute>([
        SimpleErrorRoute(id: 'tab1'),
      ], 'test');

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

      // Test buildPrimitivePath error
      try {
        RouteLayout.buildPrimitivePath(
          FakeStackPathType,
          coordinator,
          coordinator.testStack,
          null,
        );
        fail('Should have thrown UnimplementedError');
      } on UnimplementedError catch (e) {
        // Should mention the type name
        expect(e.message, contains('FakeStackPathType'));
        // Should tell where to register
        expect(e.message, contains('RouteLayout.layoutBuilderTable'));
        // Should explain the condition
        expect(e.message, contains('extends [StackPath]'));
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
        // Should mention the table
        expect(e.message, contains('layoutConstructorTable'));
        // Should reference coordinator
        expect(e.message, contains('Coordinator'));
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
        expect(message, contains('UndefinedLayout'));

        // Where: mentions where to register
        expect(message, contains('layoutConstructorTable'));
        expect(message, contains('defineLayout'));
        expect(message, contains('Coordinator'));

        // How: uses action words like "define" and "must"
        expect(message, contains('must define'));
      }
    });
  });

  group('Error Prevention Tests', () {
    test('IndexedStackPath prevents invalid construction', () {
      // Empty stack should be caught by assertion
      expect(
        () => IndexedStackPath<ErrorTestRoute>([], 'test'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Registered types do not throw errors', () {
      final coordinator = ErrorTestCoordinator();

      // NavigationPath is registered by default
      expect(
        () => RouteLayout.buildPrimitivePath(
          NavigationPath,
          coordinator,
          coordinator.root,
          null,
        ),
        returnsNormally,
      );

      // IndexedStackPath is registered by default
      final indexedStack = IndexedStackPath<ErrorTestRoute>([
        SimpleErrorRoute(id: 'test'),
      ], 'test');
      expect(
        () => RouteLayout.buildPrimitivePath(
          IndexedStackPath,
          coordinator,
          indexedStack,
          null,
        ),
        returnsNormally,
      );
    });
  });
}
