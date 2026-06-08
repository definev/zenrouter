import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class ProxyTestRoute extends RouteTarget with RouteUnique {}

class TestRoute extends ProxyTestRoute with ProxyRoute<ProxyTestRoute> {
  TestRoute(this.name);

  final String name;
  var activateCount = 0;

  @override
  Uri toUri() => Uri.parse('/$name');

  @override
  FutureOr<void> onActivate(ProxyPath<ProxyTestRoute> path) {
    activateCount++;
  }

  @override
  FutureOr<bool?> onPop(ProxyPath<ProxyTestRoute> path, [Object? result]) =>
      true;

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  List<Object?> get props => [name];
}

class PlainRoute extends ProxyTestRoute {
  PlainRoute(this.name);

  final String name;

  @override
  Uri toUri() => Uri.parse('/$name');

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  List<Object?> get props => [name];
}

class RedirectRoute extends ProxyTestRoute with RouteRedirect<ProxyTestRoute> {
  RedirectRoute(this.target);

  final ProxyTestRoute target;

  @override
  Uri toUri() => Uri.parse('/redirect');

  @override
  FutureOr<ProxyTestRoute> redirect() => target;

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  List<Object?> get props => [target];
}

class RouteHandledRoute extends TestRoute {
  RouteHandledRoute(super.name);

  final actions = <ProxyPathAction<ProxyTestRoute>>[];
  Object? nextResult;
  bool popResult = true;
  VoidCallback? onPopCallback;

  @override
  FutureOr<void> onActivate(ProxyPath<ProxyTestRoute> path) {
    actions.add(ProxyActivate(this));
  }

  @override
  FutureOr<void> onNavigate(ProxyPath<ProxyTestRoute> path) {
    actions.add(ProxyNavigate(this));
  }

  @override
  FutureOr<R?> onPush<R extends Object>(ProxyPath<ProxyTestRoute> path) {
    actions.add(ProxyPush(this));
    return nextResult as R?;
  }

  @override
  FutureOr<R?> onPushReplacement<R extends Object, RO extends Object>(
    ProxyPath<ProxyTestRoute> path, {
    RO? result,
  }) {
    actions.add(ProxyPushReplacement(this, result: result));
    return nextResult as R?;
  }

  @override
  FutureOr<bool?> onPop(ProxyPath<ProxyTestRoute> path, [Object? result]) {
    actions.add(ProxyPop(result));
    onPopCallback?.call();
    return popResult;
  }
}

void main() {
  group('ProxyPath', () {
    test('owns a mirror stack synced from a provider', () {
      final home = TestRoute('home');
      final details = TestRoute('details');
      var externalStack = <ProxyTestRoute>[home];

      final path = ProxyPath<ProxyTestRoute>.create(
        label: 'proxy',
        stack: () => externalStack,
      );

      expect(path.stack, [home]);
      expect(home.stackPath, same(path));

      externalStack = [home, details];
      expect(path.stack, [home]);

      path.notifyListeners();

      expect(path.stack, [home, details]);
      expect(details.stackPath, same(path));
    });

    test('uses the owned mirror stack for active route', () {
      final home = TestRoute('home');
      final active = TestRoute('active');

      final path = ProxyPath<ProxyTestRoute>.create(
        stack: () => [home, active],
      );

      expect(path.stack, [home, active]);
      expect(path.activeRoute, active);
    });

    test('requires mirrored routes to implement ProxyRoute', () {
      expect(
        () =>
            ProxyPath<ProxyTestRoute>.create(stack: () => [PlainRoute('bad')]),
        throwsArgumentError,
      );
    });

    test('resolves redirects before proxying route actions', () async {
      final target = RouteHandledRoute('target');
      final path = ProxyPath<ProxyTestRoute>.create();

      await path.navigate(RedirectRoute(target));

      expect(target.actions.single, isA<ProxyNavigate<ProxyTestRoute>>());
    });

    test(
      'proxies pop result and marks active route as popped by path',
      () async {
        final home = TestRoute('home');
        final details = RouteHandledRoute('details');
        var externalStack = <ProxyTestRoute>[home, details];
        final path = ProxyPath<ProxyTestRoute>.create(
          stack: () => externalStack,
        );
        details.onPopCallback = () {
          externalStack = [home];
        };

        final popped = await path.pop('done');

        expect(popped, true);
        expect(details.isPopByPath, true);
        expect(details.resultValue, 'done');
        expect(details.actions.single, isA<ProxyPop<ProxyTestRoute>>());
        expect(
          (details.actions.single as ProxyPop<ProxyTestRoute>).result,
          'done',
        );
        expect(path.stack, [home]);
      },
    );

    test('notifies listeners when an action is proxied', () async {
      var notifyCount = 0;

      final path = ProxyPath<ProxyTestRoute>.create();
      path.addListener(() => notifyCount++);

      await path.pushOrMoveToTop(TestRoute('home'));

      expect(notifyCount, 1);
    });

    test('defaults navigate to activate for proxy routes', () async {
      final route = TestRoute('home');
      final path = ProxyPath<ProxyTestRoute>.create();

      await path.navigate(route);

      expect(route.activateCount, 1);
    });

    test('lets route mixin handle push result', () async {
      final route = RouteHandledRoute('route-handled')..nextResult = 'route';
      final path = ProxyPath<ProxyTestRoute>.create();

      final result = await path.push<String>(route);

      expect(result, 'route');
      expect(route.actions.single, isA<ProxyPush<ProxyTestRoute>>());
    });

    test('lets route mixin handle push replacement result', () async {
      final route = RouteHandledRoute('replacement')..nextResult = 'next';
      final path = ProxyPath<ProxyTestRoute>.create();

      final result = await path.pushReplacement<String, String>(
        route,
        result: 'previous',
      );

      expect(result, 'next');
      expect(route.actions.single, isA<ProxyPushReplacement<ProxyTestRoute>>());
      expect(
        (route.actions.single as ProxyPushReplacement<ProxyTestRoute>).result,
        'previous',
      );
    });

    test('lets active route mixin handle pop', () async {
      final route = RouteHandledRoute('active');
      final path = ProxyPath<ProxyTestRoute>.create(stack: () => [route]);

      final popped = await path.pop('done');

      expect(popped, true);
      expect(route.isPopByPath, true);
      expect(route.resultValue, 'done');
      expect(route.actions.single, isA<ProxyPop<ProxyTestRoute>>());
    });

    testWidgets('defers notifications while widgets are building', (
      tester,
    ) async {
      final path = ProxyPath<ProxyTestRoute>.create(onAction: (_) => null);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            path.addListener(() => setState(() {}));
            path.reset();

            return const SizedBox.shrink();
          },
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
