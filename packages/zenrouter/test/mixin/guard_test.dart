import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        final popScope = element.findAncestorWidgetOfExactType<PopScope<Object>>();
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
  });
}
