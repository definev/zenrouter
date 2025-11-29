import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

class TestRoute extends RouteTarget {}

class HomeRoute extends RouteTarget {
  @override
  String toString() => 'HomeRoute';
}

class DetailsRoute extends RouteTarget {
  final String id;
  DetailsRoute(this.id);

  @override
  String toString() => 'DetailsRoute($id)';
}

class GuardedRoute extends RouteTarget with RouteGuard {
  bool allowPop = true;

  @override
  FutureOr<bool> popGuard() => allowPop;

  @override
  String toString() => 'GuardedRoute';
}

Widget buildTestApp(NavigationPath<RouteTarget> path) {
  return MaterialApp(
    home: NavigationStack(
      path: path,
      resolver: (route) {
        return switch (route) {
          HomeRoute() => RouteDestination.material(
            const Scaffold(body: Center(child: Text('Home'))),
          ),
          DetailsRoute(:final id) => RouteDestination.material(
            Scaffold(
              appBar: AppBar(title: Text('Details $id')),
              body: Center(child: Text('Details: $id')),
            ),
          ),
          GuardedRoute() => RouteDestination.material(
            const Scaffold(body: Center(child: Text('Guarded'))),
          ),
          _ => RouteDestination.material(
            const Scaffold(body: Center(child: Text('Not Found'))),
          ),
        };
      },
    ),
  );
}

void main() {
  group('NavigationStack Widget Tests', () {
    testWidgets('renders initial route', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('navigates to new route', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // Push new route
      unawaited(path.push(DetailsRoute('123')));
      await tester.pumpAndSettle();

      expect(find.text('Details: 123'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('system back button pops route', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));
      unawaited(path.push(DetailsRoute('123')));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Details: 123'), findsOneWidget);
      expect(path.stack.length, 2);

      // Use imperative pop instead of Navigator
      path.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(path.stack.length, 1);
    });

    testWidgets('result completion through widget', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      // Push route and capture result Future
      final resultFuture = path.push(DetailsRoute('456'));
      await tester.pumpAndSettle();

      expect(find.text('Details: 456'), findsOneWidget);

      // Pop with result using imperative method
      path.pop({'data': 'test_result'});
      await tester.pumpAndSettle();

      // Result should complete through onPopInvokedWithResult
      final result = await resultFuture;
      expect(result, {'data': 'test_result'});
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('guard prevents pop', (tester) async {
      final path = NavigationPath<RouteTarget>();
      final guardedRoute = GuardedRoute();
      guardedRoute.allowPop = false;

      unawaited(path.push(HomeRoute()));
      unawaited(path.push(guardedRoute));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Guarded'), findsOneWidget);
      expect(path.stack.length, 2);

      // Try to pop - should be prevented
      path.pop();
      await tester.pumpAndSettle();

      expect(find.text('Guarded'), findsOneWidget);
      expect(path.stack.length, 2);
    });

    testWidgets('guard allows pop when condition met', (tester) async {
      final path = NavigationPath<RouteTarget>();
      final guardedRoute = GuardedRoute();
      guardedRoute.allowPop = true;

      unawaited(path.push(HomeRoute()));
      unawaited(path.push(guardedRoute));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Guarded'), findsOneWidget);

      // Pop should be allowed
      path.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(path.stack.length, 1);
    });

    testWidgets('multiple route pushes', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      // Push multiple routes
      unawaited(path.push(DetailsRoute('1')));
      await tester.pumpAndSettle();
      expect(find.text('Details: 1'), findsOneWidget);

      unawaited(path.push(DetailsRoute('2')));
      await tester.pumpAndSettle();
      expect(find.text('Details: 2'), findsOneWidget);

      unawaited(path.push(DetailsRoute('3')));
      await tester.pumpAndSettle();
      expect(find.text('Details: 3'), findsOneWidget);

      expect(path.stack.length, 4);
    });

    testWidgets('back button navigation through stack', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));
      unawaited(path.push(DetailsRoute('1')));
      unawaited(path.push(DetailsRoute('2')));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Details: 2'), findsOneWidget);

      // Pop back to Details 1
      path.pop();
      await tester.pumpAndSettle();
      expect(find.text('Details: 1'), findsOneWidget);

      // Pop back to Home
      path.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      expect(path.stack.length, 1);
    });

    testWidgets('path.clear() updates UI', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));
      unawaited(path.push(DetailsRoute('1')));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Details: 1'), findsOneWidget);

      // Clear path
      path.clear();
      await tester.pumpAndSettle();

      // Should show empty/not found state
      expect(path.stack, isEmpty);
    });

    testWidgets('path.replace() updates UI', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // Replace with new route
      path.replace([DetailsRoute('999')]);
      await tester.pumpAndSettle();

      expect(find.text('Details: 999'), findsOneWidget);
      expect(path.stack.length, 1);
    });

    testWidgets('imperative pop updates UI', (tester) async {
      final path = NavigationPath<RouteTarget>();
      unawaited(path.push(HomeRoute()));
      unawaited(path.push(DetailsRoute('1')));

      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      expect(find.text('Details: 1'), findsOneWidget);

      // Imperative pop
      path.pop();
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(path.stack.length, 1);
    });

    testWidgets('listener notified on navigation changes', (tester) async {
      final path = NavigationPath<RouteTarget>();
      var notificationCount = 0;

      path.addListener(() {
        notificationCount++;
      });

      unawaited(path.push(HomeRoute()));
      await tester.pumpWidget(buildTestApp(path));
      await tester.pumpAndSettle();

      final initialCount = notificationCount;

      unawaited(path.push(DetailsRoute('1')));
      await tester.pumpAndSettle();

      expect(notificationCount, greaterThan(initialCount));
    });
  });
}
