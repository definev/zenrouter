// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

void main() {
  group('CoordinatorMutatable fallbacks', () {
    test('push and pushSilently activate a non-commit parent path', () async {
      final activate = ActivateOnlyPath(debugLabel: 'activate');
      final coordinator = AppCoordinator();
      coordinator.defineLayoutParentConstructor(
        'basic',
        (key) => AppLayout('basic', layoutKey: key, path: activate),
      );

      await coordinator.pushSilently(
        AppRoute('silent', parentLayoutKey: 'basic'),
      );
      expect(activate.activateCalls, 1);
      expect(activate.activeRoute?.id, 'silent');

      unawaited(
        coordinator.push(AppRoute('awaited', parentLayoutKey: 'basic')),
      );
      await pumpEventQueue();
      expect(activate.activeRoute?.id, 'awaited');
    });

    test(
      'pushOrMoveToTop and replace activate a non-commit parent path',
      () async {
        final activate = ActivateOnlyPath(debugLabel: 'activate');
        final coordinator = AppCoordinator();
        coordinator.defineLayoutParentConstructor(
          'basic',
          (key) => AppLayout('basic', layoutKey: key, path: activate),
        );

        await coordinator.pushOrMoveToTop(
          AppRoute('moved', parentLayoutKey: 'basic'),
        );
        expect(activate.activeRoute?.id, 'moved');

        await coordinator.replace(
          AppRoute('replaced', parentLayoutKey: 'basic'),
        );
        expect(activate.stack.last.id, 'replaced');
      },
    );

    test('pushReplacement activates a non-commit parent path', () async {
      final activate = ActivateOnlyPath(debugLabel: 'activate');
      final coordinator = AppCoordinator();
      coordinator.defineLayoutParentConstructor(
        'basic',
        (key) => AppLayout('basic', layoutKey: key, path: activate),
      );
      await coordinator.pushSilently(AppRoute('old'));

      unawaited(
        coordinator.pushReplacement(
          AppRoute('next', parentLayoutKey: 'basic'),
          result: 'done',
        ),
      );
      await pumpEventQueue();

      expect(activate.activeRoute?.id, 'next');
    });

    test('cancelled redirects leave the stack unchanged', () async {
      final coordinator = AppCoordinator();
      await coordinator.pushSilently(AppRoute('home'));

      await coordinator.replace(RedirectAppRoute('x', stop: true));
      await coordinator.pushSilently(RedirectAppRoute('y', stop: true));
      await coordinator.pushOrMoveToTop(RedirectAppRoute('z', stop: true));
      unawaited(coordinator.push(RedirectAppRoute('p', stop: true)));
      unawaited(coordinator.pushReplacement(RedirectAppRoute('r', stop: true)));
      await pumpEventQueue();

      expect(coordinator.root.stack.map((route) => route.id), ['home']);
    });
  });

  group('CoordinatorMutatable.pushReplacement across paths', () {
    test(
      'resets a single-entry source path when replacing onto another path',
      () async {
        final coordinator = AppCoordinator()..registerShell();
        await coordinator.pushSilently(
          AppRoute('inbox', parentLayoutKey: 'shell'),
        );
        expect(coordinator.nested.stack, hasLength(1));

        unawaited(
          coordinator.pushReplacement(AppRoute('home'), result: 'left'),
        );
        await pumpEventQueue();

        expect(coordinator.nested.stack, isEmpty);
        expect(coordinator.root.activeRoute?.id, 'home');
      },
    );

    test(
      'pops a deeper source path when replacing onto another path',
      () async {
        final coordinator = AppCoordinator()..registerShell();
        await coordinator.pushSilently(AppRoute('home'));
        await coordinator.pushSilently(AppRoute('settings'));
        expect(coordinator.root.stack, hasLength(2));

        unawaited(
          coordinator.pushReplacement(
            AppRoute('inbox', parentLayoutKey: 'shell'),
          ),
        );
        await pumpEventQueue();

        expect(coordinator.root.activeRoute, isA<AppLayout>());
        expect(coordinator.nested.activeRoute?.id, 'inbox');
      },
    );

    test('aborts when a guard blocks the source-path pop', () async {
      final coordinator = AppCoordinator()..registerShell();
      await coordinator.pushSilently(AppRoute('home'));
      await coordinator.pushSilently(
        GuardedAppRoute('locked', allowPop: false),
      );

      unawaited(
        coordinator.pushReplacement(
          AppRoute('inbox', parentLayoutKey: 'shell'),
        ),
      );
      await pumpEventQueue();

      expect(coordinator.root.activeRoute?.id, 'locked');
      expect(coordinator.nested.stack, isEmpty);
    });
  });

  group('CoordinatorMutatable.pop / tryPop', () {
    test('pops only the deepest eligible mutatable path', () async {
      final coordinator = AppCoordinator()..registerShell();
      await coordinator.pushSilently(AppRoute('home'));
      await coordinator.pushSilently(
        AppRoute('inbox', parentLayoutKey: 'shell'),
      );
      await coordinator.pushSilently(
        AppRoute('thread', parentLayoutKey: 'shell'),
      );

      await coordinator.pop('back');

      expect(coordinator.nested.activeRoute?.id, 'inbox');
      expect(coordinator.root.activeRoute, isA<AppLayout>());
    });

    test('tryPop returns null, false, or true by eligibility', () async {
      final coordinator = AppCoordinator();

      expect(await coordinator.tryPop(), isNull);

      await coordinator.pushSilently(AppRoute('home'));
      expect(await coordinator.tryPop(), isNull);

      await coordinator.pushSilently(
        GuardedAppRoute('locked', allowPop: false),
      );
      expect(await coordinator.tryPop(), isFalse);
      expect(coordinator.root.stack, hasLength(2));

      await coordinator.pushSilently(AppRoute('open'));
      expect(await coordinator.tryPop('ok'), isTrue);
      expect(coordinator.root.activeRoute?.id, 'locked');
    });
  });

  group('CoordinatorNavigatable', () {
    test('prepareParentLayoutList uses pushOrMoveToTop for navigate', () async {
      final coordinator = AppCoordinator()..registerShell();
      await coordinator.pushSilently(AppRoute('home'));
      await coordinator.navigate(AppRoute('inbox', parentLayoutKey: 'shell'));
      await coordinator.navigate(AppRoute('home'));
      await coordinator.navigate(AppRoute('thread', parentLayoutKey: 'shell'));

      expect(coordinator.root.activeRoute, isA<AppLayout>());
      expect(coordinator.nested.activeRoute?.id, 'thread');
    });

    test('delegates to a navigatable-only parent path', () async {
      final navigateOnly = NavigateOnlyPath(debugLabel: 'nav-only');
      final coordinator = AppCoordinator();
      coordinator.defineLayoutParentConstructor(
        'nav',
        (key) => AppLayout('nav', layoutKey: key, path: navigateOnly),
      );

      await coordinator.navigate(AppRoute('page', parentLayoutKey: 'nav'));

      expect(navigateOnly.navigateCalls, 1);
      expect(navigateOnly.activeRoute?.id, 'page');
    });

    test('asserts when the parent path is not navigatable', () async {
      final activate = ActivateOnlyPath(debugLabel: 'plain');
      final coordinator = AppCoordinator();
      coordinator.defineLayoutParentConstructor(
        'plain',
        (key) => AppLayout('plain', layoutKey: key, path: activate),
      );

      await expectLater(
        coordinator.navigate(AppRoute('page', parentLayoutKey: 'plain')),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('CoordinatorRecoverable remaining strategies', () {
    test(
      'recover uses navigate strategy and ignores custom handler registration',
      () async {
        final coordinator = AppCoordinator();
        await coordinator.pushSilently(AppRoute('home'));

        expect(
          () => coordinator.defineDeeplinkHandler(
            DeeplinkStrategy.custom,
            (c, route) {},
          ),
          throwsA(isA<AssertionError>()),
        );

        final navigated = DeepLinkAppRoute(
          'inbox',
          deeplinkStrategy: DeeplinkStrategy.navigate,
        );
        await coordinator.recover(navigated);
        expect(coordinator.root.activeRoute, navigated);

        final pushed = DeepLinkAppRoute(
          'pushed',
          deeplinkStrategy: DeeplinkStrategy.push,
        );
        await coordinator.recover(pushed);
        expect(coordinator.root.activeRoute, pushed);
      },
    );
  });
}
