// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('StackMutatable.replaceAll', () {
    test('retains identity matches and discards removed routes', () {
      final path = AppStackPath();
      final keep = TrackingRoute('keep');
      final drop = TrackingRoute('drop');
      final incoming = TrackingRoute('new');
      path.seed([keep, drop]);

      path.replaceAll([keep, incoming]);

      expect(path.stack, [keep, incoming]);
      expect(drop.events, contains('onDiscard'));
      expect(drop.stackPath, isNull);
      expect(keep.stackPath, path);
      expect(incoming.stackPath, path);
      expect(keep.onResult.isCompleted, isFalse);
    });
  });

  group('StackMutatable.push', () {
    test('resolves redirects, pushes, and completes the pop result', () async {
      final path = AppStackPath();
      final target = AppRoute('target');
      final redirect = RedirectAppRoute('alias', to: target);

      final result = path.push<String>(redirect);
      await pumpEventQueue();
      expect(path.activeRoute, target);

      await path.pop('ok');
      expect(await result, 'ok');
    });

    test('returns null when redirect cancels', () async {
      final path = AppCoordinator().root as AppStackPath;
      expect(await path.push(RedirectAppRoute('x', stop: true)), isNull);
      expect(path.stack, isEmpty);
    });
  });

  group('StackMutatable.pushReplacement', () {
    test('pushes onto an empty stack', () async {
      final path = AppStackPath();
      final future = path.pushReplacement<String, Object>(AppRoute('first'));
      await pumpEventQueue();
      expect(path.activeRoute?.id, 'first');
      await path.pop('done');
      expect(await future, 'done');
    });

    test('resets a single-entry stack then commits the replacement', () async {
      final path = AppStackPath();
      final old = TrackingRoute('old');
      path.seed([old]);

      final future = path.pushReplacement<String, String>(
        AppRoute('next'),
        result: 'replaced',
      );
      await pumpEventQueue();

      expect(path.stack.map((route) => route.id), ['next']);
      expect(old.events, contains('onDiscard'));
      expect(await old.onResult.future, 'replaced');
      path.reset();
      await future;
    });

    test('pops a deeper stack then commits the replacement', () async {
      final path = AppStackPath();
      path.seed([AppRoute('base'), AppRoute('old')]);

      unawaited(path.pushReplacement(AppRoute('next'), result: 'done'));
      await pumpEventQueue();

      expect(path.stack.map((route) => route.id), ['base', 'next']);
    });

    test('returns null when a guard blocks the current route', () async {
      final path = AppStackPath();
      path.seed([AppRoute('base'), GuardedAppRoute('locked', allowPop: false)]);

      expect(await path.pushReplacement(AppRoute('next')), isNull);
      expect(path.activeRoute?.id, 'locked');
    });

    test('returns null when redirect cancels', () async {
      final path = AppCoordinator().root as AppStackPath;
      path.seed([AppRoute('old')]);
      expect(
        await path.pushReplacement(RedirectAppRoute('x', stop: true)),
        isNull,
      );
      expect(path.activeRoute?.id, 'old');
    });
  });

  group('StackMutatable.pushOrMoveToTop', () {
    test(
      'updates an already-top same instance without notifying twice',
      () async {
        final path = AppStackPath();
        final route = TrackingRoute('same');
        path.seed([route]);
        var notifications = 0;
        path.addListener(() => notifications++);

        await path.pushOrMoveToTop(route);

        expect(path.stack, [route]);
        expect(route.events, ['onUpdate:same']);
        expect(notifications, 0);
      },
    );

    test('discards a new equal instance already on top', () async {
      final path = AppStackPath();
      final current = TrackingRoute('same');
      final incoming = TrackingRoute('same');
      path.seed([current]);

      await path.pushOrMoveToTop(incoming);

      expect(path.stack, [current]);
      expect(current.events, ['onUpdate:same']);
      expect(incoming.events, contains('onDiscard'));
    });

    test(
      'moves an existing equal route to the top and discards the occupant',
      () async {
        final path = AppStackPath();
        final first = TrackingRoute('first');
        final second = TrackingRoute('second');
        path.seed([first, second]);

        await path.pushOrMoveToTop(TrackingRoute('first'));

        expect(path.stack.map((route) => route.id), ['second', 'first']);
        expect(first.events, contains('onDiscard'));
      },
    );

    test('appends a route that is not already in the stack', () async {
      final path = AppStackPath();
      path.seed([AppRoute('a')]);
      await path.pushOrMoveToTop(AppRoute('b'));
      expect(path.stack.map((route) => route.id), ['a', 'b']);
    });

    test('is a no-op when redirect cancels', () async {
      final path = AppCoordinator().root as AppStackPath;
      await path.pushOrMoveToTop(RedirectAppRoute('x', stop: true));
      expect(path.stack, isEmpty);
    });
  });

  group('StackMutatable.navigate', () {
    test('pops back to the same lifecycle instance', () async {
      final path = AppStackPath();
      final first = AppRoute('first');
      path.seed([first, AppRoute('second'), AppRoute('third')]);

      await path.navigate(first);

      expect(path.stack, [first]);
    });

    test('merges an equal new instance after popping back', () async {
      final path = AppStackPath();
      final first = TrackingRoute('first');
      path.seed([first, AppRoute('second')]);
      final incoming = TrackingRoute('first');

      await path.navigate(incoming);

      expect(path.stack, [first]);
      expect(first.events, contains('onUpdate:first'));
      expect(incoming.events, contains('onDiscard'));
    });

    test('stops when a guard blocks a pop-back', () async {
      final path = AppStackPath();
      final first = AppRoute('first');
      path.seed([
        first,
        GuardedAppRoute('locked', allowPop: false),
        AppRoute('third'),
      ]);

      await path.navigate(first);

      expect(path.stack.map((route) => route.id), ['first', 'locked']);
    });

    test('commits a new route when it is not in the stack', () async {
      final path = AppStackPath();
      path.seed([AppRoute('a')]);
      await path.navigate(AppRoute('b'));
      expect(path.stack.map((route) => route.id), ['a', 'b']);
    });

    test('is a no-op when redirect cancels', () async {
      final path = AppCoordinator().root as AppStackPath;
      await path.navigate(RedirectAppRoute('x', stop: true));
      expect(path.stack, isEmpty);
    });
  });

  group('StackMutatable.pop with a coordinator', () {
    test('consults popGuardWith when the path has a coordinator', () async {
      final coordinator = AppCoordinator();
      final path = coordinator.root as AppStackPath;
      final guarded = GuardedAppRoute('locked', allowPop: false);
      path.seed([AppRoute('base'), guarded]);

      expect(await path.pop(), isFalse);
      expect(path.activeRoute, guarded);
    });
  });
}
