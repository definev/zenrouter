import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class ProxyTestRoute extends RouteTarget with RouteUnique {}

enum ProxyInvocation { activate, navigate, push, pushReplacement, pop }

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

class LifecycleRoute extends RouteHandledRoute {
  LifecycleRoute(super.name);

  var discardCount = 0;
  var updateCount = 0;

  @override
  void onDiscard() {
    discardCount++;
    super.onDiscard();
  }

  @override
  void onUpdate(covariant RouteTarget newRoute) {
    updateCount++;
    super.onUpdate(newRoute);
  }
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

  final invocations = <ProxyInvocation>[];
  Object? nextResult;
  Object? lastReplacementResult;
  Object? lastPopResult;
  bool popResult = true;

  @override
  FutureOr<void> onActivate(ProxyPath<ProxyTestRoute> path) {
    invocations.add(ProxyInvocation.activate);
  }

  @override
  FutureOr<void> onNavigate(ProxyPath<ProxyTestRoute> path) {
    invocations.add(ProxyInvocation.navigate);
  }

  @override
  FutureOr<R?> onPush<R extends Object>(ProxyPath<ProxyTestRoute> path) {
    invocations.add(ProxyInvocation.push);
    return nextResult as R?;
  }

  @override
  FutureOr<R?> onPushReplacement<R extends Object, RO extends Object>(
    ProxyPath<ProxyTestRoute> path, {
    RO? result,
  }) {
    invocations.add(ProxyInvocation.pushReplacement);
    lastReplacementResult = result;
    return nextResult as R?;
  }

  @override
  FutureOr<bool?> onPop(ProxyPath<ProxyTestRoute> path, [Object? result]) {
    invocations.add(ProxyInvocation.pop);
    lastPopResult = result;
    return popResult;
  }
}

void main() {
  group('ProxyPath', () {
    test('owns route stack state', () async {
      final home = TestRoute('home');
      final details = TestRoute('details');

      final path = ProxyPath<ProxyTestRoute>.create(label: 'proxy');

      await path.push(home);
      await path.push(details);

      expect(path.stack, [home, details]);
      expect(home.stackPath, same(path));
      expect(details.stackPath, same(path));
    });

    test('uses the owned stack for active route', () async {
      final home = TestRoute('home');
      final active = TestRoute('active');

      final path = ProxyPath<ProxyTestRoute>.create();
      await path.activateRoute(home);
      await path.push(active);

      expect(path.stack, [home, active]);
      expect(path.activeRoute, active);
    });

    test('requires routes to implement ProxyRoute', () {
      expect(
        ProxyPath<ProxyTestRoute>.create().push(PlainRoute('bad')),
        throwsArgumentError,
      );
    });

    test('resolves redirects before proxying route actions', () async {
      final target = RouteHandledRoute('target');
      final path = ProxyPath<ProxyTestRoute>.create();

      await path.navigate(RedirectRoute(target));

      expect(target.invocations, [ProxyInvocation.navigate]);
    });

    test(
      'proxies pop result and marks active route as popped by path',
      () async {
        final home = TestRoute('home');
        final details = RouteHandledRoute('details');
        final path = ProxyPath<ProxyTestRoute>.create();
        await path.push(home);
        await path.push(details);

        final popped = await path.pop('done');

        expect(popped, true);
        expect(details.isPopByPath, true);
        expect(details.resultValue, 'done');
        expect(details.invocations.last, ProxyInvocation.pop);
        expect(details.lastPopResult, 'done');
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

    test(
      'navigate updates existing route and discards incoming replacement',
      () async {
        final existing = LifecycleRoute('home');
        final incoming = LifecycleRoute('home');
        final path = ProxyPath<ProxyTestRoute>.create();
        await path.push(existing);

        await path.navigate(incoming);

        expect(path.stack, [existing]);
        expect(existing.updateCount, 1);
        expect(incoming.discardCount, 1);
        expect(incoming.stackPath, isNull);
        expect(incoming.invocations, isEmpty);
      },
    );

    test('navigate pops and removes routes above existing route', () async {
      final home = LifecycleRoute('home');
      final details = LifecycleRoute('details');
      final path = ProxyPath<ProxyTestRoute>.create();
      await path.push(home);
      await path.push(details);

      await path.navigate(LifecycleRoute('home'));

      expect(path.stack, [home]);
      expect(details.invocations.last, ProxyInvocation.pop);
      expect(details.stackPath, isNull);
    });

    test('lets route mixin handle push result', () async {
      final route = RouteHandledRoute('route-handled')..nextResult = 'route';
      final path = ProxyPath<ProxyTestRoute>.create();

      final result = await path.push<String>(route);

      expect(result, 'route');
      expect(route.invocations, [ProxyInvocation.push]);
    });

    test('lets route mixin handle push replacement result', () async {
      final route = RouteHandledRoute('replacement')..nextResult = 'next';
      final path = ProxyPath<ProxyTestRoute>.create();

      final result = await path.pushReplacement<String, String>(
        route,
        result: 'previous',
      );

      expect(result, 'next');
      expect(route.invocations, [ProxyInvocation.pushReplacement]);
      expect(route.lastReplacementResult, 'previous');
    });

    test('lets active route mixin handle pop', () async {
      final route = RouteHandledRoute('active');
      final path = ProxyPath<ProxyTestRoute>.create();
      await path.push(route);

      final popped = await path.pop('done');

      expect(popped, true);
      expect(route.isPopByPath, true);
      expect(route.resultValue, 'done');
      expect(route.invocations, [ProxyInvocation.push, ProxyInvocation.pop]);
      expect(route.lastPopResult, 'done');
    });

    test('invokes onReset callback when reset', () {
      var resetCount = 0;
      final path = ProxyPath<ProxyTestRoute>.create(
        onReset: () => resetCount++,
      );

      path.reset();

      expect(resetCount, 1);
      expect(path.stack, isEmpty);
    });

    testWidgets('defers notifications while widgets are building', (
      tester,
    ) async {
      final path = ProxyPath<ProxyTestRoute>.create(onReset: () {});

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
