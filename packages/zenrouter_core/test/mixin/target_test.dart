// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class TestRoute extends RouteTarget {
  TestRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'TestRoute($id)';
}

void main() {
  group('RouteTarget', () {
    test('has unpopulated stackPath by default', () {
      final route = TestRoute('1');
      expect(route.stackPath, isNull);
    });

    test('bindStackPath sets the stack path', () {
      final route = TestRoute('1');
      final path = _MockStackPath();

      route.bindStackPath(path);

      expect(route.stackPath, path);
    });

    test('clearStackPath clears the stack path', () {
      final route = TestRoute('1');
      final path = _MockStackPath();
      route.bindStackPath(path);

      route.clearStackPath();

      expect(route.stackPath, isNull);
    });

    test('isPopByPath defaults to false', () {
      final route = TestRoute('1');
      expect(route.isPopByPath, isFalse);
    });

    test('isPopByPath can be set', () {
      final route = TestRoute('1');
      route.isPopByPath = true;
      expect(route.isPopByPath, isTrue);
    });

    test('resultValue is null by default', () {
      final route = TestRoute('1');
      expect(route.resultValue, isNull);
    });

    test('bindResultValue sets resultValue', () {
      final route = TestRoute('1');
      route.bindResultValue('test-result');
      expect(route.resultValue, 'test-result');
    });

    test('deepEquals compares hashCode', () {
      final route1 = TestRoute('1');
      final route2 = route1;

      expect(route1.deepEquals(route2), isTrue);
    });

    test('onDiscard completes onResult', () async {
      final route = TestRoute('1');

      route.onDiscard();

      expect(route.onResult.isCompleted, isTrue);
    });

    test('completeOnResult completes onResult', () async {
      final route = TestRoute('1');

      route.completeOnResult('result', null);

      expect(route.onResult.isCompleted, isTrue);
      expect(route.resultValue, 'result');
    });

    test('completeOnResult with failSilent does not double complete', () async {
      final route = TestRoute('1');
      route.completeOnResult('first', null);

      expect(
        () => route.completeOnResult('second', null, true),
        returnsNormally,
      );
    });

    test('onUpdate is callable', () {
      final route1 = TestRoute('1');
      final route2 = TestRoute('2');

      expect(() => route1.onUpdate(route2), returnsNormally);
    });
  });
}

class _MockStackPath implements StackPath<TestRoute> {
  @override
  TestRoute? get activeRoute => null;

  @override
  PathKey get pathKey => const PathKey('mock');

  @override
  List<TestRoute> get stack => [];

  @override
  String? get debugLabel => null;

  @override
  CoordinatorCore? get coordinator => null;

  @override
  CoordinatorCore? get proxyCoordinator => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

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

typedef VoidCallback = void Function();
