import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mixin_test_utils.dart';

void main() {
  group('RouteDeeplink Mixin Tests', () {
    testWidgets('Push strategy adds to existing stack', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push some routes first
      coordinator.push(SimpleRoute(id: 'first'));
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Push deeplink
      coordinator.push(PushDeeplinkRoute(path: 'test'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThan(stackLengthBefore));
      expect(find.byKey(const ValueKey('push-deeplink-test')), findsOneWidget);
    });

    testWidgets('Navigate strategy navigates to new stack', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push some routes first
      coordinator.push(SimpleRoute(id: 'first'));
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Push deeplink
      coordinator.recover(NavigateDeeplinkRoute(path: 'test'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThan(stackLengthBefore));
      expect(
        find.byKey(const ValueKey('navigate-deeplink-test')),
        findsOneWidget,
      );
    });

    testWidgets('Replace strategy clears and replaces stack', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push some routes first
      coordinator.push(SimpleRoute(id: 'one'));
      await tester.pumpAndSettle();
      coordinator.push(SimpleRoute(id: 'two'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThan(1));

      // Use recoverRouteFromUri for replace behavior
      await coordinator.recoverRouteFromUri(
        Uri.parse('/deeplink/replace/replaced'),
      );
      await tester.pumpAndSettle();

      // Stack should be cleared
      expect(coordinator.root.stack.length, 1);
      expect(
        find.byKey(const ValueKey('replace-deeplink-replaced')),
        findsOneWidget,
      );
    });

    testWidgets('Custom strategy calls deeplinkHandler', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final customRoute = CustomDeeplinkRoute(path: 'handled');
      coordinator.recover(customRoute);
      await tester.pumpAndSettle();

      // Handler should navigate to custom handled route
      expect(
        find.byKey(const ValueKey('simple-custom-handled-handled')),
        findsOneWidget,
      );
    });

    testWidgets('Async custom handler completes', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final asyncRoute = AsyncCustomDeeplinkRoute(path: 'async');

      await tester.runAsync(() async {
        await coordinator.recover(asyncRoute);

        // The recover method doesn't await async deeplinkHandler,
        // so we need to wait for it manually (50ms delay in handler + buffer)
        await tester.pumpAndSettle();

        expect(asyncRoute.handlerCompleted, isTrue);
        expect(coordinator.root.activeRoute, isA<SimpleRoute>());
        expect(
          (coordinator.root.activeRoute as SimpleRoute).id,
          'async-custom-async',
        );
      });
    });
  });
}
