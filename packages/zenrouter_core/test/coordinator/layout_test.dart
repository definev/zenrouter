// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  group('CoordinatorLayoutCore', () {
    test('registers, looks up, overrides, and creates layout parents', () {
      final coordinator = AppCoordinator();
      expect(coordinator.getLayoutParentConstructor('shell'), isNull);
      expect(coordinator.createLayoutParent('shell'), isNull);

      coordinator.defineLayoutParentConstructor(
        'shell',
        (key) => AppLayout('shell', layoutKey: key, path: coordinator.nested),
      );
      expect(coordinator.getLayoutParentConstructor('shell'), isNotNull);
      expect(coordinator.createLayoutParent('shell'), isA<AppLayout>());

      coordinator.defineLayoutParentConstructor(
        'shell',
        (key) => AppLayout('other', layoutKey: key, path: coordinator.nested),
      );
      expect((coordinator.createLayoutParent('shell') as AppLayout).id, 'other');
    });

    test(
      'shares the constructor table with a nested route-module coordinator',
      () {
        late NestedCoordinator nested;
        final coordinator = ModularAppCoordinator(
          modules: (c) {
            nested = NestedCoordinator(c);
            return [nested];
          },
        );

        coordinator.defineLayoutParentConstructor(
          'shell',
          (key) => AppLayout('shell', layoutKey: key, path: coordinator.nested),
        );

        expect(nested.getLayoutParentConstructor('shell'), isNotNull);
        expect(nested.createLayoutParent('shell'), isA<AppLayout>());
      },
    );

    test('push activates a missing parent layout on the root stack', () async {
      final coordinator = AppCoordinator()..registerShell();

      await coordinator.pushSilently(
        AppRoute('inbox', parentLayoutKey: 'shell'),
      );

      expect(coordinator.root.activeRoute, isA<AppLayout>());
      expect(coordinator.nested.activeRoute?.id, 'inbox');
      expect(coordinator.activeLayoutParent?.layoutKey, 'shell');
      expect(coordinator.activeLayoutParentList, hasLength(1));
      expect(coordinator.activePaths, [coordinator.root, coordinator.nested]);
    });

    test(
      'replace overrides the parent layout instead of stacking it',
      () async {
        final coordinator = AppCoordinator()..registerShell();
        await coordinator.pushSilently(AppRoute('home'));

        await coordinator.replace(AppRoute('inbox', parentLayoutKey: 'shell'));

        expect(coordinator.root.stack, hasLength(1));
        expect(coordinator.root.activeRoute, isA<AppLayout>());
        expect(coordinator.nested.activeRoute?.id, 'inbox');
      },
    );

    test('nested layouts activate from the outside in', () async {
      final coordinator = AppCoordinator();
      final innerPath = AppStackPath(
        coordinator: coordinator,
        debugLabel: 'inner',
      );
      coordinator.defineLayoutParentConstructor(
        'app',
        (key) => AppLayout('app', layoutKey: key, path: coordinator.nested),
      );
      coordinator.defineLayoutParentConstructor(
        'shell',
        (key) => AppLayout(
          'shell',
          layoutKey: key,
          path: innerPath,
          parentLayoutKey: 'app',
        ),
      );

      await coordinator.pushSilently(
        AppRoute('thread', parentLayoutKey: 'shell'),
      );

      expect(coordinator.root.activeRoute, isA<AppLayout>());
      expect((coordinator.root.activeRoute as AppLayout).layoutKey, 'app');
      expect(coordinator.nested.activeRoute, isA<AppLayout>());
      expect((coordinator.nested.activeRoute as AppLayout).layoutKey, 'shell');
      expect(innerPath.activeRoute?.id, 'thread');
      expect(
        coordinator.activeLayoutParentList.map((layout) => layout.layoutKey),
        ['app', 'shell'],
      );
      expect(coordinator.activeLayoutParent?.layoutKey, 'shell');
    });

    test('dispose clears registered layout constructors', () {
      final coordinator = AppCoordinator()..registerShell();
      expect(coordinator.getLayoutParentConstructor('shell'), isNotNull);

      coordinator.dispose();
      expect(coordinator.getLayoutParentConstructor('shell'), isNull);
    });
  });
}
