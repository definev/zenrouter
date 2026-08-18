// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

void main() {
  group('RouteLayoutChild', () {
    test('createParentLayout is null when no parent key is set', () {
      final coordinator = AppCoordinator();
      expect(AppRoute('home').createParentLayout(coordinator), isNull);
      expect(AppRoute('home').resolveParentLayout(coordinator), isNull);
    });

    test('createParentLayout uses the registered constructor', () {
      final coordinator = AppCoordinator()..registerShell();
      final child = AppRoute('inbox', parentLayoutKey: 'shell');

      final created = child.createParentLayout(coordinator);

      expect(created, isA<AppLayout>());
      expect(created!.layoutKey, 'shell');
      expect(created.resolvePath(coordinator), coordinator.nested);
    });

    test('resolveParentLayout reuses an already-active parent', () async {
      final coordinator = AppCoordinator()..registerShell();
      await coordinator.pushSilently(
        AppRoute('inbox', parentLayoutKey: 'shell'),
      );

      final active = coordinator.root.activeRoute as AppLayout;
      final resolved = AppRoute(
        'compose',
        parentLayoutKey: 'shell',
      ).resolveParentLayout(coordinator);

      expect(resolved, same(active));
    });

    test('proxy forwards parentLayoutKey', () {
      final child = AppRoute('inbox', parentLayoutKey: 'shell');
      final proxy = RouteLayoutChild.proxy(child);
      expect(proxy.parentLayoutKey, 'shell');
    });
  });

  group('RouteLayoutParent', () {
    test('equality and hashCode use layout keys', () {
      final path = AppStackPath();
      final left = AppLayout('shell', layoutKey: 'shell', path: path);
      final right = AppLayout('other', layoutKey: 'shell', path: path);
      final nested = AppLayout(
        'shell',
        layoutKey: 'shell',
        path: path,
        parentLayoutKey: 'app',
      );

      expect(left, equals(right));
      expect(left.hashCode, right.hashCode);
      expect(left, isNot(equals(nested)));
    });

    test('onDidPop resets the layout path', () async {
      final coordinator = AppCoordinator()..registerShell();
      await coordinator.pushSilently(AppRoute('home'));
      await coordinator.pushSilently(
        AppRoute('inbox', parentLayoutKey: 'shell'),
      );
      await coordinator.pushSilently(
        AppRoute('thread', parentLayoutKey: 'shell'),
      );
      expect(coordinator.nested.stack, hasLength(2));

      final shell = coordinator.root.activeRoute as AppLayout;
      shell.isPopByPath = true;
      shell.onDidPop(null, coordinator);

      expect(coordinator.nested.stack, isEmpty);
    });

    test('onDidPop asserts when the coordinator is missing', () {
      final layout = AppLayout(
        'shell',
        layoutKey: 'shell',
        path: AppStackPath(),
      );
      expect(() => layout.onDidPop(null, null), throwsA(isA<AssertionError>()));
    });

    test('proxy forwards layout lookup and compares equal to its host', () {
      final coordinator = AppCoordinator();
      final layout = AppLayout(
        'shell',
        layoutKey: 'shell',
        path: coordinator.nested,
      );
      final proxy = RouteLayoutParent.proxy(layout);

      expect(proxy.layoutKey, 'shell');
      expect(proxy.parentLayoutKey, isNull);
      expect(proxy.resolvePath(coordinator), coordinator.nested);
      expect(proxy == layout, isTrue);
      expect(
        proxy == AppLayout('x', layoutKey: 'other', path: AppStackPath()),
        isFalse,
      );
    });
  });
}
