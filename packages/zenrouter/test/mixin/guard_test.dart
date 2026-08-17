import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'mixin_test_utils.dart';

void main() {
  group('RouteGuard Mixin Tests', () {
    testWidgets('Guard prevents pop when allowPop is false', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(GuardedPopRoute(allowPop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Try to pop
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should still be on guarded page
      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);
      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('Guard allows pop when allowPop is true', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(GuardedPopRoute(allowPop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);

      // Try to pop
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should be back to home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('Guard is called during pop', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final guardRoute = ConfirmationGuardRoute(showConfirmation: true);
      coordinator.push(guardRoute);
      await tester.pumpAndSettle();

      expect(guardRoute.wasConfirmationShown, isFalse);

      // Try to pop - this will trigger the guard
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(guardRoute.wasConfirmationShown, isTrue);
    });

    testWidgets('Async guard waits for completion', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push guard with delay
      coordinator.push(
        GuardedPopRoute(
          allowPop: true,
          popDelay: const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);

      // Pop - await the guard
      coordinator.pop();
      await tester.pumpAndSettle();

      // Should eventually return to home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('reactive canPop updates PopScope without recreating page', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();
      final route = ReactiveCanPopRoute();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(route);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('reactive-can-pop')), findsOneWidget);

      PopScope<Object> popScopeOf(Finder content) {
        final element = tester.element(content);
        final popScope = element
            .findAncestorWidgetOfExactType<PopScope<Object>>();
        expect(popScope, isNotNull);
        return popScope!;
      }

      expect(
        popScopeOf(find.byKey(const ValueKey('reactive-can-pop'))).canPop,
        isTrue,
      );

      route.dirty.value = true;
      await tester.pump();

      expect(
        popScopeOf(find.byKey(const ValueKey('reactive-can-pop'))).canPop,
        isFalse,
      );
    });

    testWidgets('blocked pop does not complete the route or call onDidPop', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();
      final route = _LifecycleGuardRoute(allowPop: false);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      unawaited(coordinator.push(route));
      await tester.pumpAndSettle();

      final popped = await coordinator.tryPop();

      expect(popped, isFalse);
      expect(coordinator.root.stack.last, route);
      expect(route.events, ['popGuard']);
      expect(route.onResult.isCompleted, isFalse);
      expect(find.byKey(const ValueKey('lifecycle-guard')), findsOneWidget);
    });

    testWidgets('allowed pop runs popGuard before onDidPop', (tester) async {
      final coordinator = MixinTestCoordinator();
      final route = _LifecycleGuardRoute(allowPop: true);

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      unawaited(coordinator.push(route));
      await tester.pumpAndSettle();

      final popped = await coordinator.tryPop();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      // PopScope may invoke onDidPop again after the page is removed; the
      // base implementation is idempotent, so only the first teardown counts.
      expect(route.events.take(3), ['popGuard', 'onDidPop', 'onDiscard']);
      expect(route.events.first, 'popGuard');
      expect(route.onResult.isCompleted, isTrue);
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets(
      'allowed pop does not throw after onDiscard disposes canPopListenable',
      (tester) async {
        final coordinator = MixinTestCoordinator();
        final route = _DisposingCanPopListenableRoute();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );
        await tester.pumpAndSettle();

        unawaited(coordinator.push(route));
        await tester.pumpAndSettle();

        await coordinator.tryPop();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(route.onResult.isCompleted, isTrue);
        expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
      },
    );
  });
}

class _LifecycleGuardRoute extends TestAppRoute with RouteGuard {
  _LifecycleGuardRoute({required this.allowPop});

  final bool allowPop;
  final events = <String>[];

  @override
  Future<bool> popGuard() async {
    events.add('popGuard');
    return allowPop;
  }

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    events.add('onDidPop');
    super.onDidPop(result, coordinator);
  }

  @override
  void onDiscard() {
    events.add('onDiscard');
    super.onDiscard();
  }

  @override
  Uri toUri() => Uri.parse('/lifecycle-guard');

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const Scaffold(
      key: ValueKey('lifecycle-guard'),
      body: Text('Lifecycle Guard'),
    );
  }

  @override
  List<Object?> get props => [allowPop];
}

class _DisposingCanPopListenableRoute extends TestAppRoute with RouteGuard {
  final dirty = ValueNotifier(true);

  @override
  bool get canPop => !dirty.value;

  @override
  ListenableMixin? get canPopListenable => dirty.toListenableMixin();

  @override
  Future<bool> popGuard() async => true;

  @override
  void onDiscard() {
    dirty.dispose();
    super.onDiscard();
  }

  @override
  Uri toUri() => Uri.parse('/disposing-can-pop');

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const Scaffold(
      key: ValueKey('disposing-can-pop'),
      body: Text('Disposing CanPop'),
    );
  }
}
