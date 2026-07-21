import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  group('RouteGuardRule Tests', () {
    testWidgets('empty rules allow pop', (tester) async {
      final coordinator = GuardRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(RuleGuardedRoute(id: '1', rules: []));
      await tester.pumpAndSettle();

      expect(find.text('Rule Guarded: 1'), findsOneWidget);

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('null-only rules allow pop', (tester) async {
      final coordinator = GuardRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        RuleGuardedRoute(id: '2', rules: [const ContinueGuardRule()]),
      );
      await tester.pumpAndSettle();

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('false blocks pop', (tester) async {
      final coordinator = GuardRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        RuleGuardedRoute(id: '3', rules: [const BlockGuardRule()]),
      );
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Rule Guarded: 3'), findsOneWidget);
      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('true allows pop and skips later rules', (tester) async {
      final coordinator = GuardRuleTestCoordinator();
      final later = CountingGuardRule(false);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        RuleGuardedRoute(id: '4', rules: [const AllowGuardRule(), later]),
      );
      await tester.pumpAndSettle();

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(later.callCount, 0);
    });

    testWidgets('null continues to next rule which can block', (tester) async {
      final coordinator = GuardRuleTestCoordinator();
      final second = CountingGuardRule(false);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        RuleGuardedRoute(id: '5', rules: [const ContinueGuardRule(), second]),
      );
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Rule Guarded: 5'), findsOneWidget);
      expect(coordinator.root.stack.length, stackLengthBefore);
      expect(second.callCount, 1);
    });

    testWidgets('false short-circuits and skips later rules', (tester) async {
      final coordinator = GuardRuleTestCoordinator();
      final later = CountingGuardRule(true);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        RuleGuardedRoute(id: '6', rules: [const BlockGuardRule(), later]),
      );
      await tester.pumpAndSettle();

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Rule Guarded: 6'), findsOneWidget);
      expect(later.callCount, 0);
    });

    testWidgets('async guard rules work correctly', (tester) async {
      final coordinator = GuardRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        RuleGuardedRoute(
          id: '7',
          rules: [
            AsyncGuardRule(true, delay: const Duration(milliseconds: 50)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      coordinator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('IndexedStack tab leave respects guard rules', (tester) async {
      final coordinator = GuardRuleTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(FirstTab());
      await tester.pumpAndSettle();

      expect(coordinator.indexedStackPath.activeIndex, 0);

      // Leaving FirstTab is blocked by BlockGuardRule
      await coordinator.indexedStackPath.goToIndexed(1);
      await tester.pumpAndSettle();

      expect(coordinator.indexedStackPath.activeIndex, 0);
    });
  });
}

// ============================================================================
// Test Routes
// ============================================================================

abstract class GuardRuleTestRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends GuardRuleTestRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return const Scaffold(body: Center(child: Text('Home')));
  }
}

class RuleGuardedRoute extends GuardRuleTestRoute
    with RouteGuardRule<GuardRuleTestRoute> {
  RuleGuardedRoute({required this.id, required this.rules});

  final String id;
  final List<GuardRule> rules;

  @override
  List<GuardRule> get guardRules => rules;

  @override
  Uri toUri() => Uri.parse('/rule-guarded/$id');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Scaffold(body: Center(child: Text('Rule Guarded: $id')));
  }

  @override
  List<Object?> get props => [id, ...rules];
}

class TestIndexedStackLayout extends GuardRuleTestRoute with RouteLayout {
  @override
  StackPath<RouteUnique> resolvePath(
    covariant GuardRuleTestCoordinator coordinator,
  ) => coordinator.indexedStackPath;
}

class FirstTab extends GuardRuleTestRoute
    with RouteGuardRule<GuardRuleTestRoute> {
  @override
  Type get layout => TestIndexedStackLayout;

  @override
  List<GuardRule> get guardRules => [const BlockGuardRule()];

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Center(child: Text('First Tab'));
  }

  @override
  Uri toUri() => Uri.parse('/first-tab');
}

class SecondTab extends GuardRuleTestRoute {
  @override
  Type get layout => TestIndexedStackLayout;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Center(child: Text('Second Tab'));
  }

  @override
  Uri toUri() => Uri.parse('/second-tab');
}

// ============================================================================
// Test Guard Rules
// ============================================================================

class ContinueGuardRule extends GuardRule<GuardRuleTestRoute> {
  const ContinueGuardRule();

  @override
  FutureOr<bool?> guard(
    covariant Coordinator coordinator,
    covariant GuardRuleTestRoute route,
  ) => null;
}

class AllowGuardRule extends GuardRule<GuardRuleTestRoute> {
  const AllowGuardRule();

  @override
  FutureOr<bool?> guard(
    covariant Coordinator coordinator,
    covariant GuardRuleTestRoute route,
  ) => true;
}

class BlockGuardRule extends GuardRule<GuardRuleTestRoute> {
  const BlockGuardRule();

  @override
  FutureOr<bool?> guard(
    covariant Coordinator coordinator,
    covariant GuardRuleTestRoute route,
  ) => false;
}

class CountingGuardRule extends GuardRule<GuardRuleTestRoute> {
  CountingGuardRule(this.result);

  final bool? result;
  int callCount = 0;

  @override
  FutureOr<bool?> guard(
    covariant Coordinator coordinator,
    covariant GuardRuleTestRoute route,
  ) {
    callCount++;
    return result;
  }
}

class AsyncGuardRule extends GuardRule<GuardRuleTestRoute> {
  const AsyncGuardRule(this.result, {required this.delay});

  final bool? result;
  final Duration delay;

  @override
  Future<bool?> guard(
    covariant Coordinator coordinator,
    covariant GuardRuleTestRoute route,
  ) async {
    await Future.delayed(delay);
    return result;
  }
}

// ============================================================================
// Test Coordinator
// ============================================================================

class GuardRuleTestCoordinator extends Coordinator<GuardRuleTestRoute> {
  late final indexedStackPath = IndexedStackPath.createWith(
    [FirstTab(), SecondTab()],
    coordinator: this,
    label: 'IndexedStackPath',
  )..bindLayout(TestIndexedStackLayout.new);

  @override
  Uri? get initialRoutePath => Uri.parse('/');

  @override
  List<StackPath> get paths => [...super.paths, indexedStackPath];

  @override
  GuardRuleTestRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['rule-guarded', final id] => RuleGuardedRoute(id: id, rules: []),
      _ => HomeRoute(),
    };
  }
}
