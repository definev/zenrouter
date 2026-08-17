import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class TestRoute extends RouteTarget {
  TestRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class TestGuardedRoute extends TestRoute with RouteGuard {
  TestGuardedRoute(
    super.id, {
    this.allowPop = true,
    this.popDelay = Duration.zero,
  });
  final bool allowPop;
  final Duration popDelay;
  final events = <String>[];

  @override
  Future<bool> popGuard() async {
    events.add('popGuard');
    if (popDelay > Duration.zero) {
      await Future.delayed(popDelay);
    }
    events.add('popGuard:done');
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
}

mixin _TestListenable {
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

class _GuardStackPath extends StackPath<TestRoute>
    with _TestListenable, StackMutatable<TestRoute> {
  _GuardStackPath() : super([]);

  @override
  TestRoute? get activeRoute => stack.lastOrNull;

  @override
  PathKey get pathKey => const PathKey('guard-test');

  @override
  void reset() {
    clear();
    notifyListeners();
  }

  @override
  Future<void> activateRoute(TestRoute route) async {
    await pushSilently(route);
  }
}

void main() {
  group('RouteGuard', () {
    test('popGuard defaults to true', () {
      final defaultGuard = _DefaultGuardRoute('default');
      expect(defaultGuard.popGuard(), isTrue);
    });

    test('canPop defaults to false', () {
      final defaultGuard = _DefaultGuardRoute('default');
      expect(defaultGuard.canPop, isFalse);
      expect(defaultGuard.canPopListenable, isNull);
    });

    test('popGuard returns configured value', () async {
      final allowRoute = TestGuardedRoute('1', allowPop: true);
      final denyRoute = TestGuardedRoute('2', allowPop: false);

      expect(await allowRoute.popGuard(), isTrue);
      expect(await denyRoute.popGuard(), isFalse);
    });

    test('popGuard can be async', () async {
      final route = TestGuardedRoute(
        '1',
        allowPop: true,
        popDelay: const Duration(milliseconds: 10),
      );

      final result = route.popGuard();
      expect(result, isA<Future<bool>>());
      expect(await result, isTrue);
    });
  });

  group('RouteGuard vs pop lifecycle', () {
    test('runs popGuard before onDidPop when pop is allowed', () async {
      final path = _GuardStackPath();
      final under = TestRoute('base');
      final guarded = TestGuardedRoute('leave', allowPop: true);
      await path.pushSilently(under);
      await path.pushSilently(guarded);

      final popped = await path.pop('ok');

      expect(popped, isTrue);
      expect(path.stack, [under]);
      expect(guarded.events, [
        'popGuard',
        'popGuard:done',
        'onDidPop',
        'onDiscard',
      ]);
      expect(guarded.onResult.isCompleted, isTrue);
      expect(await guarded.onResult.future, 'ok');
    });

    test('does not tear down the route when popGuard blocks', () async {
      final path = _GuardStackPath();
      final under = TestRoute('base');
      final guarded = TestGuardedRoute('stay', allowPop: false);
      await path.pushSilently(under);
      await path.pushSilently(guarded);

      final popped = await path.pop('unused');

      expect(popped, isFalse);
      expect(path.stack, [under, guarded]);
      expect(guarded.events, ['popGuard', 'popGuard:done']);
      expect(guarded.onResult.isCompleted, isFalse);
      expect(guarded.stackPath, path);
    });

    test('async popGuard still finishes before teardown', () async {
      final path = _GuardStackPath();
      final guarded = TestGuardedRoute(
        'async',
        allowPop: true,
        popDelay: const Duration(milliseconds: 10),
      );
      await path.pushSilently(TestRoute('base'));
      await path.pushSilently(guarded);

      final popped = await path.pop();

      expect(popped, isTrue);
      expect(guarded.events, [
        'popGuard',
        'popGuard:done',
        'onDidPop',
        'onDiscard',
      ]);
    });
  });
}

class _DefaultGuardRoute extends TestRoute with RouteGuard {
  _DefaultGuardRoute(super.id);
}
