// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

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

    test(
      'popGuardWith delegates after checking the path coordinator',
      () async {
        final coordinator = AppCoordinator();
        final route = TestGuardedRoute('1', allowPop: false);
        route.bindStackPath(coordinator.root);

        expect(await route.popGuardWith(coordinator), isFalse);
      },
    );

    test('popGuardWith asserts when the path coordinator does not match', () {
      final coordinator = AppCoordinator();
      final route = _DefaultGuardRoute('1');
      route.bindStackPath(_ForeignPath());

      expect(
        () => route.popGuardWith(coordinator),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'canPopWith and canPopListenableWith default to the non-coordinator APIs',
      () {
        final coordinator = AppCoordinator();
        final route = _DefaultGuardRoute('1');

        expect(route.canPopWith(coordinator), isFalse);
        expect(route.canPopListenableWith(coordinator), isNull);
      },
    );

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

class _ForeignCoordinator implements CoordinatorCore<RouteUri> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ForeignPath implements StackPath<TestRoute> {
  @override
  CoordinatorCore? get coordinator => _ForeignCoordinator();

  @override
  TestRoute? get activeRoute => null;

  @override
  PathKey get pathKey => const PathKey('foreign');

  @override
  List<TestRoute> get stack => const [];

  @override
  String? get debugLabel => null;

  @override
  CoordinatorCore? get proxyCoordinator => null;

  @override
  void addListener(void Function() listener) {}

  @override
  void removeListener(void Function() listener) {}

  @override
  void notifyListeners() {}

  @override
  void clear() {}

  @override
  void bindStack(List<TestRoute> stack) {}

  @override
  void reset() {}

  @override
  Future<void> activateRoute(TestRoute route) async {}

  @override
  void dispose() {}
}
