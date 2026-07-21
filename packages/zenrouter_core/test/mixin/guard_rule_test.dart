import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class TestRoute extends RouteTarget {
  TestRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class RuleGuardedRoute extends TestRoute with RouteGuardRule<TestRoute> {
  RuleGuardedRoute(super.id, {required this.rules});

  final List<GuardRule> rules;

  @override
  List<GuardRule> get guardRules => rules;
}

void main() {
  group('RouteGuardRule', () {
    test('popGuard defaults to true', () {
      final route = RuleGuardedRoute('1', rules: []);
      expect(route.popGuard(), isTrue);
    });

    test('implements RouteGuard', () {
      final route = RuleGuardedRoute('1', rules: []);
      expect(route, isA<RouteGuard>());
    });

    test('canPop is true when every rule allows', () {
      final route = RuleGuardedRoute(
        '1',
        rules: [const _FixedCanPopRule(true), const _FixedCanPopRule(true)],
      );
      expect(route.canPop, isTrue);
    });

    test('canPop is false when any rule requires intercept', () {
      final route = RuleGuardedRoute(
        '1',
        rules: [const _FixedCanPopRule(true), const _FixedCanPopRule(false)],
      );
      expect(route.canPop, isFalse);
    });

    test('canPopListenable is null when no rules expose one', () {
      final route = RuleGuardedRoute(
        '1',
        rules: [const _FixedCanPopRule(true)],
      );
      expect(route.canPopListenable, isNull);
    });

    test('canPopListenable returns single listenable', () {
      final notifier = _TestListenable();
      final route = RuleGuardedRoute('1', rules: [_ListenableRule(notifier)]);
      expect(route.canPopListenable, same(notifier));
    });

    test('canPopListenable merges multiple listenables', () {
      final a = _TestListenable();
      final b = _TestListenable();
      final route = RuleGuardedRoute(
        '1',
        rules: [_ListenableRule(a), _ListenableRule(b)],
      );
      expect(route.canPopListenable, isA<ListenableMixin>());
      expect(route.canPopListenable, isNot(same(a)));
      expect(route.canPopListenable, isNot(same(b)));

      var notified = 0;
      route.canPopListenable!.addListener(() => notified++);
      a.notify();
      b.notify();
      expect(notified, 2);
    });
  });
}

class _TestListenable implements ListenableMixin {
  final _listeners = <void Function()>[];

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

class _FixedCanPopRule extends GuardRule<TestRoute> {
  const _FixedCanPopRule(this._canPop);

  final bool _canPop;

  @override
  bool canPop(covariant TestRoute route) => _canPop;

  @override
  FutureOr<bool?> guard(
    covariant CoordinatorCore coordinator,
    covariant TestRoute route,
  ) => null;
}

class _ListenableRule extends GuardRule<TestRoute> {
  _ListenableRule(this._listenable);

  final ListenableMixin _listenable;

  @override
  ListenableMixin? canPopListenable(covariant TestRoute route) => _listenable;

  @override
  FutureOr<bool?> guard(
    covariant CoordinatorCore coordinator,
    covariant TestRoute route,
  ) => null;
}
