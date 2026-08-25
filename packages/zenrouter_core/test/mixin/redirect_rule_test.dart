import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

class _RuleRoute extends AppRoute with RouteRedirectRule<AppRoute> {
  _RuleRoute(super.id, {required this.redirectRules});

  @override
  final List<RedirectRule> redirectRules;
}

class _StopRule extends RedirectRule<AppRoute> {
  const _StopRule();

  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    covariant CoordinatorCore coordinator,
    covariant AppRoute route,
  ) => const RedirectResult.stop();
}

class _ContinueRule extends RedirectRule<AppRoute> {
  const _ContinueRule();

  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    covariant CoordinatorCore coordinator,
    covariant AppRoute route,
  ) => const RedirectResult.continueRedirect();
}

class _ToRule extends RedirectRule<AppRoute> {
  const _ToRule(this.target);

  final AppRoute target;

  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    covariant CoordinatorCore coordinator,
    covariant AppRoute route,
  ) => RedirectResult.redirectTo(target);
}

class _AsyncToRule extends RedirectRule<AppRoute> {
  const _AsyncToRule(this.target);

  final AppRoute target;

  @override
  Future<RedirectResult<AppRoute>> redirectResult(
    covariant CoordinatorCore coordinator,
    covariant AppRoute route,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return RedirectResult.redirectTo(target);
  }
}

void main() {
  group('RedirectResult', () {
    test('factories produce the sealed variants', () {
      const stop = RedirectResult<AppRoute>.stop();
      const cont = RedirectResult<AppRoute>.continueRedirect();
      final target = AppRoute('next');
      final redirect = RedirectResult<AppRoute>.redirectTo(target);

      expect(stop, isA<StopRedirect<AppRoute>>());
      expect(cont, isA<ContinueRedirect<AppRoute>>());
      expect(redirect, isA<RedirectTo<AppRoute>>());
      expect((redirect as RedirectTo<AppRoute>).route, target);
      expect(identical(const StopRedirect<AppRoute>(), stop), isTrue);
      expect(identical(const ContinueRedirect<AppRoute>(), cont), isTrue);
    });
  });

  group('RouteRedirectRule', () {
    test('redirect() returns the host route', () {
      final route = _RuleRoute('host', redirectRules: const []);
      expect(route.redirect(), same(route));
    });

    test(
      'empty rules and continue-only chains keep the original route',
      () async {
        final coordinator = AppCoordinator();
        final empty = _RuleRoute('empty', redirectRules: const []);
        final continued = _RuleRoute(
          'continued',
          redirectRules: const [_ContinueRule(), _ContinueRule()],
        );

        expect(await empty.redirectWith(coordinator), same(empty));
        expect(await continued.redirectWith(coordinator), same(continued));
      },
    );

    test('stop cancels navigation', () async {
      final coordinator = AppCoordinator();
      final route = _RuleRoute('blocked', redirectRules: const [_StopRule()]);

      expect(await route.redirectWith(coordinator), isNull);
      expect(await RouteRedirect.resolve(route, coordinator), isNull);
    });

    test('redirectTo short-circuits later rules', () async {
      final coordinator = AppCoordinator();
      final target = AppRoute('login');
      final later = _ToRule(AppRoute('never'));
      final route = _RuleRoute(
        'secure',
        redirectRules: [_ContinueRule(), _ToRule(target), later],
      );

      expect(await route.redirectWith(coordinator), same(target));
    });

    test('awaits asynchronous rules', () async {
      final coordinator = AppCoordinator();
      final target = AppRoute('async-target');
      final route = _RuleRoute('async', redirectRules: [_AsyncToRule(target)]);

      expect(
        await RouteRedirect.resolve<AppRoute>(route, coordinator),
        same(target),
      );
    });
  });
}
