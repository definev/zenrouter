import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter/src/transition.dart';

class TestRoute extends RouteTarget {}

class TestRouteWithData extends RouteTarget {
  final String data;
  TestRouteWithData(this.data);
}

void main() {
  group('NavigationPath', () {
    test('starts empty', () {
      final path = NavigationPath<TestRoute>();
      expect(path.stack, isEmpty);
    });

    test('push adds route to stack', () async {
      final path = NavigationPath<TestRoute>();
      final route = TestRoute();
      unawaited(path.push(route));

      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);
      expect(path.stack.first, route);
    });

    test(
      'push returns Future that completes on pop',
      () async {
        final path = NavigationPath<TestRoute>();
        final route = TestRoute();

        final resultFuture = path.push(route);
        await Future.delayed(Duration.zero);

        path.pop('test_result');
        final result = await resultFuture;

        expect(result, 'test_result');
      },
      skip:
          'Result completion requires NavigationStack widget - handled by onPopInvokedWithResult',
    );

    test('pop removes route from stack', () async {
      final path = NavigationPath<TestRoute>();
      final route = TestRoute();

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(path.stack, isEmpty);
    });

    test(
      'pop with result passes value to push Future',
      () async {
        final path = NavigationPath<TestRoute>();
        final route = TestRoute();

        final resultFuture = path.push(route);
        await Future.delayed(Duration.zero);

        path.pop({'key': 'value'});
        final result = await resultFuture;

        expect(result, {'key': 'value'});
      },
      skip:
          'Result completion requires NavigationStack widget - handled by onPopInvokedWithResult',
    );

    test('clear removes all routes', () async {
      final path = NavigationPath<TestRoute>();

      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);
      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);
      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 3);

      path.clear();
      expect(path.stack, isEmpty);
    });

    test('replace replaces entire stack', () async {
      final path = NavigationPath<TestRoute>();

      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);
      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);

      final newRoutes = [TestRoute(), TestRoute(), TestRoute()];
      path.replace(newRoutes);

      await Future.delayed(Duration.zero);
      expect(path.stack.length, 3);
    });

    test('remove removes specific route', () async {
      final path = NavigationPath<TestRoute>();

      final route1 = TestRoute();
      final route2 = TestRoute();
      final route3 = TestRoute();

      unawaited(path.push(route1));
      await Future.delayed(Duration.zero);
      unawaited(path.push(route2));
      await Future.delayed(Duration.zero);
      unawaited(path.push(route3));
      await Future.delayed(Duration.zero);

      path.remove(route2);

      expect(path.stack.length, 2);
      expect(path.stack.contains(route2), false);
      expect(path.stack.contains(route1), true);
      expect(path.stack.contains(route3), true);
    });

    test('pushOrMoveToTop adds route if not present', () async {
      final path = NavigationPath<TestRoute>();
      final route = TestRoute();

      await path.pushOrMoveToTop(route);

      expect(path.stack.length, 1);
      expect(path.stack.first, route);
    });

    test('pushOrMoveToTop moves route to top if already present', () async {
      final path = NavigationPath<TestRoute>();

      final route1 = TestRoute();
      final route2 = TestRoute();
      final route3 = TestRoute();

      unawaited(path.push(route1));
      await Future.delayed(Duration.zero);
      unawaited(path.push(route2));
      await Future.delayed(Duration.zero);
      unawaited(path.push(route3));
      await Future.delayed(Duration.zero);

      await path.pushOrMoveToTop(route1);

      expect(path.stack.length, 3);
      expect(path.stack.last, route1);
    });

    test('notifies listeners on push', () async {
      final path = NavigationPath<TestRoute>();
      var notified = false;

      path.addListener(() {
        notified = true;
      });

      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);

      expect(notified, true);
    });

    test('notifies listeners on pop', () async {
      final path = NavigationPath<TestRoute>();
      var notified = false;

      unawaited(path.push(TestRoute()));
      await Future.delayed(Duration.zero);

      path.addListener(() {
        notified = true;
      });

      path.pop();

      expect(notified, true);
    });

    test('notifies listeners on clear', () {
      final path = NavigationPath<TestRoute>();
      var notified = false;

      path.addListener(() {
        notified = true;
      });

      path.clear();

      expect(notified, true);
    });

    test('notifies listeners on replace', () async {
      final path = NavigationPath<TestRoute>();
      var notificationCount = 0;

      path.addListener(() {
        notificationCount++;
      });

      path.replace([TestRoute()]);
      await Future.delayed(Duration.zero);

      expect(notificationCount, greaterThan(0));
    });

    test('stack is unmodifiable', () {
      final path = NavigationPath<TestRoute>();
      expect(
        () => (path.stack as List).add(TestRoute()),
        throwsUnsupportedError,
      );
    });

    test('pop on empty stack does nothing', () {
      final path = NavigationPath<TestRoute>();
      expect(() => path.pop(), returnsNormally);
      expect(path.stack, isEmpty);
    });
  });

  group('RouteTarget', () {
    test('equality based on runtime type and path', () {
      final route1 = TestRoute();
      final route2 = TestRoute();

      expect(route1, equals(route2));
    });

    test('different types are not equal', () {
      final route1 = TestRoute();
      final route2 = TestRouteWithData('test');

      expect(route1, isNot(equals(route2)));
    });

    test('toUri returns throw error by default', () {
      final route = TestRoute();
      expect(() => route.toUri(), throwsAssertionError);
    });

    test('default deeplink strategy is replace', () {
      final route = TestRoute();
      expect(route.deeplinkStrategy, DeeplinkStrategy.replace);
    });
  });

  group('RouteDestination', () {
    testWidgets('material creates MaterialPage', (tester) async {
      final destination = RouteDestination.material(const Text('Test'));
      final page = destination.pageBuilder(
        tester.element(find.byType(Container)),
        ValueKey(TestRoute()),
        const Text('Test'),
      );

      expect(page, isA<MaterialPage>());
    });

    testWidgets('cupertino creates CupertinoPage', (tester) async {
      final destination = RouteDestination.cupertino(const Text('Test'));
      final page = destination.pageBuilder(
        tester.element(find.byType(Container)),
        ValueKey(TestRoute()),
        const Text('Test'),
      );

      expect(page, isA<CupertinoPage>());
    });

    testWidgets('dialog creates DialogPage', (tester) async {
      final destination = RouteDestination.dialog(const Text('Test'));
      final page = destination.pageBuilder(
        tester.element(find.byType(Container)),
        ValueKey(TestRoute()),
        const Text('Test'),
      );

      expect(page, isA<DialogPage>());
    });

    testWidgets('sheet creates CupertinoSheetPage', (tester) async {
      final destination = RouteDestination.sheet(const Text('Test'));
      final page = destination.pageBuilder(
        tester.element(find.byType(Container)),
        ValueKey(TestRoute()),
        const Text('Test'),
      );

      expect(page, isA<CupertinoSheetPage>());
    });
  });
}
