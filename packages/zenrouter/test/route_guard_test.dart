import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

class TestRoute extends RouteTarget {}

class GuardedRoute extends RouteTarget with RouteGuard {
  final FutureOr<bool> Function() guardCallback;

  GuardedRoute(this.guardCallback);

  @override
  FutureOr<bool> popGuard() => guardCallback();
}

class AlwaysAllowGuard extends RouteTarget with RouteGuard {
  @override
  FutureOr<bool> popGuard() => true;
}

class AlwaysDenyGuard extends RouteTarget with RouteGuard {
  @override
  FutureOr<bool> popGuard() => false;
}

class AsyncGuard extends RouteTarget with RouteGuard {
  final FutureOr<bool> Function() callback;

  AsyncGuard(this.callback);

  @override
  Future<bool> popGuard() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return callback();
  }
}

void main() {
  group('RouteGuard', () {
    test('guard returning true allows pop', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AlwaysAllowGuard();

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(path.stack, isEmpty);
    });

    test('guard returning false prevents pop', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AlwaysDenyGuard();

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      path.pop();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(path.stack.length, 1);
      expect(path.stack.first, route);
    });

    test('async guard returning true allows pop', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AsyncGuard(() => true);

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      path.pop();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(path.stack, isEmpty);
    });

    test('async guard returning false prevents pop', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AsyncGuard(() => false);

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      path.pop();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(path.stack.length, 1);
    });

    test('guard is consulted before pop', () async {
      final path = NavigationPath<RouteTarget>();
      var guardCalled = false;

      final route = GuardedRoute(() {
        guardCalled = true;
        return true;
      });

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(guardCalled, true);
    });

    test('multiple guarded routes', () async {
      final path = NavigationPath<RouteTarget>();

      final route1 = AlwaysAllowGuard();
      final route2 = AlwaysDenyGuard();

      unawaited(path.push(route1));
      await Future.delayed(Duration.zero);
      unawaited(path.push(route2));
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);

      // Try to pop route2 (denied)
      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(path.stack.length, 2);

      // Remove route2 manually
      path.remove(route2);

      // Now pop route1 (allowed)
      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(path.stack, isEmpty);
    });

    test(
      'guard with result value',
      () async {
        final path = NavigationPath<RouteTarget>();
        final route = AlwaysAllowGuard();

        final resultFuture = path.push(route);
        await Future.delayed(Duration.zero);

        path.pop('test_value');
        final result = await resultFuture;

        expect(result, 'test_value');
      },
      skip:
          'Result completion requires NavigationStack widget - handled by onPopInvokedWithResult',
    );

    test('denied guard does not trigger result Future', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AlwaysDenyGuard();

      final resultFuture = path.push(route);
      await Future.delayed(Duration.zero);

      path.pop('test_value');
      await Future.delayed(const Duration(milliseconds: 20));

      // Result should not complete
      var completed = false;
      resultFuture.then((_) => completed = true);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(completed, false);
    });

    test('guard callback can be stateful', () async {
      final path = NavigationPath<RouteTarget>();
      var allowPop = false;

      final route = GuardedRoute(() => allowPop);

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);

      // First attempt should be denied
      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(path.stack.length, 1);

      // Change state and try again
      allowPop = true;
      path.pop();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(path.stack, isEmpty);
    });

    test('clear bypasses guards', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AlwaysDenyGuard();

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      // Clear should not consult guards
      path.clear();
      expect(path.stack, isEmpty);
    });

    test('remove bypasses guards', () async {
      final path = NavigationPath<RouteTarget>();
      final route = AlwaysDenyGuard();

      unawaited(path.push(route));
      await Future.delayed(Duration.zero);
      expect(path.stack.length, 1);

      // Remove should not consult guards
      path.remove(route);
      expect(path.stack, isEmpty);
    });
  });
}
