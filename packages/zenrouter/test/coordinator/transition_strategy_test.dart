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

class TestCoordinator extends Coordinator<AppRoute> {
  TestCoordinator({this.strategy = DefaultTransitionStrategy.material});

  final DefaultTransitionStrategy strategy;

  @override
  DefaultTransitionStrategy get transitionStrategy => strategy;

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.path) {
      '/settings' => SettingsRoute(),
      _ => HomeRoute(),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('DefaultTransitionStrategy enum', () {
    test('has correct values', () {
      expect(DefaultTransitionStrategy.values, [
        DefaultTransitionStrategy.material,
        DefaultTransitionStrategy.cupertino,
        DefaultTransitionStrategy.none,
      ]);
    });

    test('material is the first value', () {
      expect(
        DefaultTransitionStrategy.values.first,
        DefaultTransitionStrategy.material,
      );
    });
  });

  group('Coordinator.transitionStrategy', () {
    test('defaults to material', () {
      final coordinator = TestCoordinator();
      expect(
        coordinator.transitionStrategy,
        DefaultTransitionStrategy.material,
      );
    });

    test('can be overridden to cupertino', () {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.cupertino,
      );
      expect(
        coordinator.transitionStrategy,
        DefaultTransitionStrategy.cupertino,
      );
    });

    test('can be overridden to none', () {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.none,
      );
      expect(coordinator.transitionStrategy, DefaultTransitionStrategy.none);
    });

    test('maintains strategy throughout navigation', () async {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.cupertino,
      );

      // Push multiple routes
      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);
      coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);

      // Strategy should remain consistent
      expect(
        coordinator.transitionStrategy,
        DefaultTransitionStrategy.cupertino,
      );
    });

    test('different coordinators can have different strategies', () {
      final materialCoordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.material,
      );
      final cupertinoCoordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.cupertino,
      );
      final noneCoordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.none,
      );

      expect(
        materialCoordinator.transitionStrategy,
        DefaultTransitionStrategy.material,
      );
      expect(
        cupertinoCoordinator.transitionStrategy,
        DefaultTransitionStrategy.cupertino,
      );
      expect(
        noneCoordinator.transitionStrategy,
        DefaultTransitionStrategy.none,
      );
    });
  });

  group('Transition strategy integration', () {
    testWidgets('material strategy is used in navigation stack', (
      tester,
    ) async {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.material,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      // Initial route
      coordinator.push(HomeRoute());
      await tester.pumpAndSettle();

      expect(
        coordinator.transitionStrategy,
        DefaultTransitionStrategy.material,
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('cupertino strategy is used in navigation stack', (
      tester,
    ) async {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.cupertino,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.push(HomeRoute());
      await tester.pumpAndSettle();

      expect(
        coordinator.transitionStrategy,
        DefaultTransitionStrategy.cupertino,
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('none strategy is used in navigation stack', (tester) async {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.none,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.push(HomeRoute());
      await tester.pumpAndSettle();

      expect(coordinator.transitionStrategy, DefaultTransitionStrategy.none);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('transition between routes respects strategy', (tester) async {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.none,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );

      coordinator.push(HomeRoute());
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      coordinator.push(SettingsRoute());
      await tester.pumpAndSettle();

      // With 'none' strategy, transition should be instant
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });
  });

  group('DefaultTransitionStrategy edge cases', () {
    test('strategy is read-only per coordinator instance', () {
      final coordinator = TestCoordinator(
        strategy: DefaultTransitionStrategy.cupertino,
      );

      // Strategy should not change after initialization
      final initialStrategy = coordinator.transitionStrategy;
      expect(initialStrategy, DefaultTransitionStrategy.cupertino);

      // After multiple operations
      coordinator.push(HomeRoute());
      expect(coordinator.transitionStrategy, initialStrategy);
    });

    test('strategy can be different for each coordinator instance', () {
      final instances = <TestCoordinator>[
        TestCoordinator(strategy: DefaultTransitionStrategy.material),
        TestCoordinator(strategy: DefaultTransitionStrategy.cupertino),
        TestCoordinator(strategy: DefaultTransitionStrategy.none),
      ];

      expect(
        instances[0].transitionStrategy,
        DefaultTransitionStrategy.material,
      );
      expect(
        instances[1].transitionStrategy,
        DefaultTransitionStrategy.cupertino,
      );
      expect(instances[2].transitionStrategy, DefaultTransitionStrategy.none);
    });
  });
}
