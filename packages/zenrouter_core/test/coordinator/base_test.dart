// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

void main() {
  group('CoordinatorCore lifecycle', () {
    test('standalone coordinator throws if treated as a module', () {
      final coordinator = AppCoordinator(initialRoutePath: Uri.parse('/start'));

      expect(coordinator.isRouteModule, isFalse);
      expect(coordinator.rootCoordinator, same(coordinator));
      expect(coordinator.initialRoutePath, Uri.parse('/start'));
      expect(coordinator.routeManifest, same(RouteManifest.empty));
      expect(coordinator.routeManifestFragment.isEmpty, isTrue);
      expect(() => coordinator.coordinator, throwsA(isA<UnimplementedError>()));

      coordinator.defineLayout();
      coordinator.defineConverter();
    });

    test('dispose detaches and disposes owned paths', () async {
      final coordinator = AppCoordinator();
      await coordinator.pushSilently(AppRoute('home'));
      expect(coordinator.root.stack, isNotEmpty);

      coordinator.dispose();

      expect((coordinator.root as AppStackPath).listeners, isEmpty);
    });

    test('currentUri falls back to / when the stack is empty', () {
      expect(AppCoordinator().currentUri, Uri.parse('/'));
    });

    test('active layout queries are empty without a layout on the stack', () {
      final coordinator = AppCoordinator();
      expect(coordinator.activeLayoutParent, isNull);
      expect(coordinator.activeLayoutParentList, isEmpty);
      expect(coordinator.activePaths, [coordinator.root]);
    });
  });

  group('history intent', () {
    test('records, consumes, and ignores automatic intent', () {
      final coordinator = AppCoordinator();

      coordinator.recordHistoryIntent(NavigationHistoryIntent.automatic);
      expect(
        coordinator.consumeHistoryIntent(),
        NavigationHistoryIntent.automatic,
      );

      coordinator.recordHistoryIntent(NavigationHistoryIntent.push);
      expect(coordinator.consumeHistoryIntent(), NavigationHistoryIntent.push);
      expect(
        coordinator.consumeHistoryIntent(),
        NavigationHistoryIntent.automatic,
      );
    });

    test(
      'withHistoryIntent pins the first scope so inner records cannot override',
      () async {
        final coordinator = AppCoordinator();

        await coordinator.withHistoryIntent(
          NavigationHistoryIntent.traverse,
          () {
            coordinator.recordHistoryIntent(NavigationHistoryIntent.push);
            expect(
              coordinator.consumeHistoryIntent(),
              NavigationHistoryIntent.traverse,
            );
          },
        );
      },
    );

    test(
      'withHistoryIntent restores the previous intent when the operation throws',
      () async {
        final coordinator = AppCoordinator();
        coordinator.recordHistoryIntent(NavigationHistoryIntent.replace);

        await expectLater(
          coordinator.withHistoryIntent(NavigationHistoryIntent.traverse, () {
            throw StateError('boom');
          }),
          throwsA(isA<StateError>()),
        );

        expect(
          coordinator.consumeHistoryIntent(),
          NavigationHistoryIntent.replace,
        );
      },
    );

    test('markNeedRebuild publishes a commit outside a transaction', () async {
      final coordinator = AppCoordinator();
      await coordinator.pushSilently(AppRoute('home'));
      var notifications = 0;
      coordinator.addListener(() => notifications++);

      coordinator.markNeedRebuild(
        historyIntent: NavigationHistoryIntent.replace,
      );

      expect(notifications, 1);
      expect(
        coordinator.lastNavigationCommit?.historyIntent,
        NavigationHistoryIntent.replace,
      );
    });

    test(
      'path notifications publish immediately outside a transaction',
      () async {
        final coordinator = AppCoordinator();
        var notifications = 0;
        coordinator.addListener(() => notifications++);

        await (coordinator.root as AppStackPath).pushSilently(
          AppRoute('direct'),
        );

        expect(notifications, 1);
        expect(
          coordinator.lastNavigationCommit?.currentUri,
          Uri.parse('/direct'),
        );
      },
    );

    test(
      'isInNavigationTransaction is true inside runNavigationTransaction',
      () async {
        final coordinator = AppCoordinator();
        var seen = false;

        await coordinator.runNavigationTransaction(() {
          seen = coordinator.isInNavigationTransaction;
        });

        expect(seen, isTrue);
        expect(coordinator.isInNavigationTransaction, isFalse);
      },
    );
  });

  group('route-module delegation', () {
    late NestedCoordinator nested;
    late ModularAppCoordinator root;

    setUp(() {
      root = ModularAppCoordinator(
        modules: (c) {
          nested = NestedCoordinator(c);
          return [nested];
        },
      );
    });

    test(
      'forwards URI, commit, transaction, and history APIs to the root',
      () async {
        await root.pushSilently(AppRoute('home'));

        expect(nested.isRouteModule, isTrue);
        expect(nested.rootCoordinator, same(root));
        expect(nested.currentUri, root.currentUri);
        expect(nested.lastNavigationCommit, same(root.lastNavigationCommit));
        expect(nested.isInNavigationTransaction, isFalse);

        var nestedNotifications = 0;
        root.addListener(() => nestedNotifications++);

        await nested.runNavigationTransaction(() async {
          expect(nested.isInNavigationTransaction, isTrue);
          expect(root.isInNavigationTransaction, isTrue);
          await nested.pushSilently(AppRoute('from-nested'));
        }, historyIntent: NavigationHistoryIntent.push);

        expect(nestedNotifications, 1);
        expect(root.root.activeRoute?.id, 'from-nested');

        nested.recordHistoryIntent(NavigationHistoryIntent.replace);
        expect(root.consumeHistoryIntent(), NavigationHistoryIntent.replace);

        await nested.withHistoryIntent(NavigationHistoryIntent.traverse, () {
          nested.recordHistoryIntent(NavigationHistoryIntent.push);
        });
        expect(root.consumeHistoryIntent(), NavigationHistoryIntent.traverse);

        nested.markNeedRebuild(historyIntent: NavigationHistoryIntent.replace);
        expect(
          root.lastNavigationCommit?.historyIntent,
          NavigationHistoryIntent.replace,
        );
      },
    );
  });
}
