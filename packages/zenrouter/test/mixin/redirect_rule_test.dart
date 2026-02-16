import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  group('RedirectResult Classes Tests', () {
    test('StopRedirect factory creates correct instance', () {
      const result = StopRedirect<RouteTarget>();
      expect(result, isA<StopRedirect<RouteTarget>>());
      expect(result, isA<RedirectResult<RouteTarget>>());
    });

    test('ContinueRedirect factory creates correct instance', () {
      const result = ContinueRedirect<RouteTarget>();
      expect(result, isA<ContinueRedirect<RouteTarget>>());
      expect(result, isA<RedirectResult<RouteTarget>>());
    });

    test('RedirectTo factory creates correct instance with route', () {
      final testRoute = SimpleRoute(id: 'test');
      final result = RedirectResult<RedirectRuleTestRoute>.redirectTo(
        testRoute,
      );
      expect(result, isA<RedirectTo<RedirectRuleTestRoute>>());
      expect(result, isA<RedirectResult<RedirectRuleTestRoute>>());
      expect((result as RedirectTo).route, equals(testRoute));
    });

    test('StopRedirect is const and can be reused', () {
      const result1 = StopRedirect<RouteTarget>();
      const result2 = StopRedirect<RouteTarget>();
      expect(identical(result1, result2), isTrue);
    });

    test('ContinueRedirect is const and can be reused', () {
      const result1 = ContinueRedirect<RouteTarget>();
      const result2 = ContinueRedirect<RouteTarget>();
      expect(identical(result1, result2), isTrue);
    });

    test('RedirectTo stores the route correctly', () {
      final route1 = SimpleRoute(id: 'route1');
      final route2 = SimpleRoute(id: 'route2');

      final result1 = RedirectTo(route1);
      final result2 = RedirectTo(route2);

      expect(result1.route, equals(route1));
      expect(result2.route, equals(route2));
      expect(result1.route, isNot(equals(result2.route)));
    });

    test('All RedirectResult types are sealed class variants', () {
      const stop = RedirectResult<RouteTarget>.stop();
      const continueResult = RedirectResult<RouteTarget>.continueRedirect();
      final redirect = RedirectResult<RedirectRuleTestRoute>.redirectTo(
        SimpleRoute(id: 'test'),
      );

      expect(stop, isA<RedirectResult<RouteTarget>>());
      expect(continueResult, isA<RedirectResult<RouteTarget>>());
      expect(redirect, isA<RedirectResult<RedirectRuleTestRoute>>());
    });
  });

  group('RouteRedirectRule Tests', () {
    testWidgets('Redirect rule can stop navigation', (tester) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // StopRule will prevent navigation
      coordinator.push(RuleRoute(id: '1', rules: [StopRule()]));
      await tester.pumpAndSettle();

      // Should not navigate, still on initial route
      expect(find.text('Rule Route: 1'), findsNothing);
    });

    testWidgets('Redirect rule can continue to next rule', (tester) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // ContinueRule will pass through, final rule returns the route itself
      coordinator.push(RuleRoute(id: '2', rules: [ContinueRule()]));
      await tester.pumpAndSettle();

      // Should navigate successfully
      expect(find.text('Rule Route: 2'), findsOneWidget);
    });

    testWidgets('Redirect rule can redirect to another route', (tester) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // RedirectToTargetRule will redirect to target route
      coordinator.push(
        RuleRoute(
          id: '3',
          rules: [RedirectToTargetRule(targetId: 'redirected')],
        ),
      );
      await tester.pumpAndSettle();

      // Should show redirected route, not original
      expect(find.text('Rule Route: 3'), findsNothing);
      expect(find.text('Simple: redirected'), findsOneWidget);
    });

    testWidgets('Multiple redirect rules are processed in sequence', (
      tester,
    ) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // First rule continues, second rule redirects
      coordinator.push(
        RuleRoute(
          id: '4',
          rules: [
            ContinueRule(),
            ContinueRule(),
            RedirectToTargetRule(targetId: 'final'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rule Route: 4'), findsNothing);
      expect(find.text('Simple: final'), findsOneWidget);
    });

    testWidgets('Stop rule prevents subsequent rules from running', (
      tester,
    ) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Stop rule prevents redirect rule from running
      coordinator.push(
        RuleRoute(
          id: '5',
          rules: [
            ContinueRule(),
            StopRule(),
            RedirectToTargetRule(targetId: 'should-not-reach'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Should not navigate at all
      expect(find.text('Rule Route: 5'), findsNothing);
      expect(find.text('Simple: should-not-reach'), findsNothing);
    });

    testWidgets('Auth redirect rule blocks unauthenticated access', (
      tester,
    ) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Unauthenticated user redirected to login
      coordinator.push(
        RuleRoute(id: '6', rules: [AuthRedirectRule(isAuthenticated: false)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rule Route: 6'), findsNothing);
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Auth redirect rule allows authenticated access', (
      tester,
    ) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Authenticated user proceeds
      coordinator.push(
        RuleRoute(id: '7', rules: [AuthRedirectRule(isAuthenticated: true)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rule Route: 7'), findsOneWidget);
    });

    testWidgets('Async redirect rules work correctly', (tester) async {
      final coordinator = RedirectRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Async rule that redirects after delay
      coordinator.push(
        RuleRoute(
          id: '8',
          rules: [
            AsyncRedirectRule(
              targetId: 'async-result',
              delay: const Duration(milliseconds: 50),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rule Route: 8'), findsNothing);
      expect(find.text('Simple: async-result'), findsOneWidget);
    });

    testWidgets(
      'Indexed stack should not redirect if redirect rule route return itself',
      (tester) async {
        final coordinator = RedirectRuleTestCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        coordinator.push(FirstTab());
        await tester.pumpAndSettle();

        coordinator.indexedStackPath.goToIndexed(1);
        final second = coordinator.indexedStackPath.stack[1] as SecondTab;

        expect(second.redirectRules.first is RedirectCountingRule, true);
        expect((second.redirectRules.first as RedirectCountingRule).count, 1);
      },
    );
  });
}

// ============================================================================
// Test Routes
// ============================================================================

abstract class RedirectRuleTestRoute extends RouteTarget with RouteUnique {}

class RuleRoute extends RedirectRuleTestRoute
    with RouteRedirect, RouteRedirectRule {
  RuleRoute({required this.id, required this.rules});

  final String id;
  final List<RedirectRule> rules;

  @override
  List<RedirectRule> get redirectRules => rules;

  @override
  Uri toUri() => Uri.parse('/rule/$id');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Scaffold(body: Center(child: Text('Rule Route: $id')));
  }

  @override
  List<Object?> get props => [id, ...rules];
}

class SimpleRoute extends RedirectRuleTestRoute {
  SimpleRoute({required this.id});

  final String id;

  @override
  Uri toUri() => Uri.parse('/simple/$id');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Scaffold(body: Center(child: Text('Simple: $id')));
  }

  @override
  List<Object?> get props => [id];
}

class LoginRoute extends RedirectRuleTestRoute {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Scaffold(body: Center(child: Text('Login Page')));
  }
}

// ============================================================================
// Test Redirect Rules
// ============================================================================

class StopRule extends RedirectRule<RedirectRuleTestRoute> {
  @override
  FutureOr<RedirectResult<RedirectRuleTestRoute>> redirectResult(
    covariant Coordinator coordinator,
    covariant RedirectRuleTestRoute route,
  ) {
    return const RedirectResult.stop();
  }
}

class ContinueRule extends RedirectRule<RedirectRuleTestRoute> {
  @override
  FutureOr<RedirectResult<RedirectRuleTestRoute>> redirectResult(
    covariant Coordinator coordinator,
    covariant RedirectRuleTestRoute route,
  ) {
    return const RedirectResult.continueRedirect();
  }
}

class RedirectToTargetRule extends RedirectRule<RedirectRuleTestRoute> {
  RedirectToTargetRule({required this.targetId});

  final String targetId;

  @override
  FutureOr<RedirectResult<RedirectRuleTestRoute>> redirectResult(
    covariant Coordinator coordinator,
    covariant RedirectRuleTestRoute route,
  ) {
    return RedirectResult.redirectTo(SimpleRoute(id: targetId));
  }
}

class AuthRedirectRule extends RedirectRule<RedirectRuleTestRoute> {
  AuthRedirectRule({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  FutureOr<RedirectResult<RedirectRuleTestRoute>> redirectResult(
    covariant Coordinator coordinator,
    covariant RedirectRuleTestRoute route,
  ) {
    if (!isAuthenticated) {
      return RedirectResult.redirectTo(LoginRoute());
    }
    return const RedirectResult.continueRedirect();
  }
}

class RedirectCountingRule extends RedirectRule<RedirectRuleTestRoute> {
  RedirectCountingRule();

  int count = 0;

  @override
  FutureOr<RedirectResult<RedirectRuleTestRoute>> redirectResult(
    covariant Coordinator coordinator,
    covariant RedirectRuleTestRoute route,
  ) {
    count += 1;
    return RedirectResult.continueRedirect();
  }
}

class AsyncRedirectRule extends RedirectRule<RedirectRuleTestRoute> {
  AsyncRedirectRule({required this.targetId, required this.delay});

  final String targetId;
  final Duration delay;

  @override
  FutureOr<RedirectResult<RedirectRuleTestRoute>> redirectResult(
    covariant Coordinator coordinator,
    covariant RedirectRuleTestRoute route,
  ) async {
    await Future.delayed(delay);
    return RedirectResult.redirectTo(SimpleRoute(id: targetId));
  }
}

class TestIndexedStackLayout extends RedirectRuleTestRoute with RouteLayout {
  @override
  StackPath<RouteUnique> resolvePath(
    covariant RedirectRuleTestCoordinator coordinator,
  ) => coordinator.indexedStackPath;
}

class FirstTab extends RedirectRuleTestRoute {
  @override
  Type get layout => TestIndexedStackLayout;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Center(child: Text('First Tab'));
  }

  @override
  Uri toUri() => Uri.parse('/first-tab');
}

class SecondTab extends RedirectRuleTestRoute
    with RouteRedirect, RouteRedirectRule {
  @override
  Type get layout => TestIndexedStackLayout;

  @override
  final List<RedirectRule> redirectRules = [RedirectCountingRule()];

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Center(child: Text('Second Tab'));
  }

  @override
  Uri toUri() => Uri.parse('/second-tab');
}

// ============================================================================
// Test Coordinator
// ============================================================================

class RedirectRuleTestCoordinator extends Coordinator<RedirectRuleTestRoute> {
  late final indexedStackPath = IndexedStackPath.createWith(
    [FirstTab(), SecondTab()],
    coordinator: this,
    label: 'IndexedStackPath',
  )..bindLayout(TestIndexedStackLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, indexedStackPath];

  @override
  RedirectRuleTestRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['rule', final id] => RuleRoute(id: id, rules: []),
      ['simple', final id] => SimpleRoute(id: id),
      ['login'] => LoginRoute(),
      _ => SimpleRoute(id: 'not-found'),
    };
  }
}
