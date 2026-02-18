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

  @override
  Future<bool> popGuard() async {
    if (popDelay > Duration.zero) {
      await Future.delayed(popDelay);
    }
    return allowPop;
  }
}

void main() {
  group('RouteGuard', () {
    test('popGuard defaults to true', () {
      final defaultGuard = _DefaultGuardRoute('default');
      expect(defaultGuard.popGuard(), isTrue);
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
}

class _DefaultGuardRoute extends TestRoute with RouteGuard {
  _DefaultGuardRoute(super.id);
}
