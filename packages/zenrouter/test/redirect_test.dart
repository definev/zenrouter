import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

class MyRoute extends RouteTarget {}

class TargetRoute extends MyRoute {}

class RedirectRoute extends MyRoute with RouteRedirect<MyRoute> {
  final MyRoute target;
  RedirectRoute(this.target);

  @override
  FutureOr<MyRoute> redirect() => target;

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RedirectRoute && other.target == target;
  }

  @override
  int get hashCode => target.hashCode;
}

class AsyncRedirectRoute extends MyRoute with RouteRedirect<MyRoute> {
  final MyRoute target;
  AsyncRedirectRoute(this.target);

  @override
  Future<MyRoute> redirect() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return target;
  }
}

void main() {
  group('NavigationPath Redirect', () {
    test('push redirects correctly', () async {
      final path = NavigationPath<MyRoute>();
      final target = TargetRoute();
      final redirect = RedirectRoute(target);

      unawaited(path.push(redirect));
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('push async redirects correctly', () async {
      final path = NavigationPath<MyRoute>();
      final target = TargetRoute();
      final redirect = AsyncRedirectRoute(target);

      unawaited(path.push(redirect));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('pushOrMoveToTop redirects correctly', () async {
      final path = NavigationPath<MyRoute>();
      final target = TargetRoute();
      final redirect = RedirectRoute(target);

      await path.pushOrMoveToTop(redirect);

      expect(path.stack.length, 1);
      expect(path.stack.first, target);
    });

    test('chained redirects', () async {
      final path = NavigationPath<MyRoute>();
      final finalTarget = TargetRoute();
      final intermediate = RedirectRoute(finalTarget);
      final start = RedirectRoute(intermediate);

      unawaited(path.push(start));
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 1);
      expect(path.stack.first, finalTarget);
    });
  });
}
