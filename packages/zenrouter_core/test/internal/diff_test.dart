// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

void main() {
  group('DiffOp', () {
    test('Keep, Insert, and Delete expose indices and toString', () {
      const keep = Keep<String>(5, 3);
      const insert = Insert<String>('test', 2);
      const delete = Delete<String>(7);

      expect(keep.oldIndex, 5);
      expect(keep.newIndex, 3);
      expect(keep.toString(), 'Keep(old: 5, new: 3)');

      expect(insert.element, 'test');
      expect(insert.newIndex, 2);
      expect(insert.toString(), 'Insert(test at 2)');

      expect(delete.oldIndex, 7);
      expect(delete.toString(), 'Delete(at 7)');
    });
  });

  group('myersDiff', () {
    test('returns no operations for two empty lists', () {
      expect(myersDiff<String>([], []), isEmpty);
    });

    test('inserts every item when the old list is empty', () {
      final ops = myersDiff<String>([], ['a', 'b', 'c']);

      expect(ops, [
        isA<Insert<String>>().having((op) => op.element, 'element', 'a'),
        isA<Insert<String>>().having((op) => op.element, 'element', 'b'),
        isA<Insert<String>>().having((op) => op.element, 'element', 'c'),
      ]);
      expect((ops[0] as Insert<String>).newIndex, 0);
    });

    test('deletes every item when the new list is empty', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], []);

      expect(ops.map((op) => (op as Delete<String>).oldIndex), [0, 1, 2]);
    });

    test('keeps identical lists', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['a', 'b', 'c']);
      expect(ops, everyElement(isA<Keep<String>>()));
      expect(ops, hasLength(3));
    });

    test('inserts a single middle item', () {
      final ops = myersDiff<String>(['a', 'c'], ['a', 'b', 'c']);

      expect(ops[0], isA<Keep<String>>());
      expect((ops[1] as Insert<String>).element, 'b');
      expect((ops[1] as Insert<String>).newIndex, 1);
      expect(ops[2], isA<Keep<String>>());
    });

    test('deletes a single middle item', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['a', 'c']);

      expect(ops[0], isA<Keep<String>>());
      expect((ops[1] as Delete<String>).oldIndex, 1);
      expect(ops[2], isA<Keep<String>>());
    });

    test('replaces an item as a delete plus insert', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['a', 'd', 'c']);

      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Delete<String>>());
      expect((ops[2] as Insert<String>).element, 'd');
      expect(ops[3], isA<Keep<String>>());
    });

    test('appends, prepends, and removes from either end', () {
      expect(
        myersDiff<String>(
          ['a', 'b'],
          ['a', 'b', 'c', 'd'],
        ).map((op) => op.runtimeType),
        [Keep<String>, Keep<String>, Insert<String>, Insert<String>],
      );
      expect(
        myersDiff<String>(
          ['c', 'd'],
          ['a', 'b', 'c', 'd'],
        ).map((op) => op.runtimeType),
        [Insert<String>, Insert<String>, Keep<String>, Keep<String>],
      );
      expect(
        myersDiff<String>(
          ['a', 'b', 'c', 'd'],
          ['a', 'b'],
        ).map((op) => op.runtimeType),
        [Keep<String>, Keep<String>, Delete<String>, Delete<String>],
      );
      expect(
        myersDiff<String>(
          ['a', 'b', 'c', 'd'],
          ['c', 'd'],
        ).map((op) => op.runtimeType),
        [Delete<String>, Delete<String>, Keep<String>, Keep<String>],
      );
    });

    test('handles interleaved edits, reorder, and total replacement', () {
      final interleaved = myersDiff<String>(
        ['a', 'b', 'c', 'd'],
        ['a', 'x', 'c', 'y'],
      );
      expect(interleaved.any((op) => op is Keep), isTrue);
      expect(interleaved.any((op) => op is Delete), isTrue);
      expect(interleaved.any((op) => op is Insert), isTrue);

      final replaced = myersDiff<String>(['a', 'b', 'c'], ['x', 'y', 'z']);
      expect(replaced.whereType<Delete<String>>(), hasLength(3));
      expect(replaced.whereType<Insert<String>>(), hasLength(3));

      final reordered = myersDiff<String>(['a', 'b', 'c'], ['c', 'b', 'a']);
      expect(reordered.any((op) => op is Delete || op is Insert), isTrue);
    });

    test('uses a custom equality function', () {
      final ops = myersDiff<int>(
        [1, 2, 3],
        [11, 12, 13],
        equals: (a, b) => a % 10 == b % 10,
      );

      expect(ops, everyElement(isA<Keep<int>>()));
    });

    test('uses == when no custom equality is provided', () {
      final ops = myersDiff<AppRoute>([AppRoute('a')], [AppRoute('a')]);
      expect(ops, everyElement(isA<Keep<AppRoute>>()));
    });

    test('scales to a 50-item list with a single replacement', () {
      final old = List.generate(50, (i) => 'item_$i');
      final next = [
        for (var i = 0; i < 50; i++) i == 25 ? 'modified_$i' : 'item_$i',
      ];

      final same = myersDiff<String>(old, old);
      expect(same, everyElement(isA<Keep<String>>()));

      final changed = myersDiff<String>(old, next);
      expect(changed.whereType<Keep<String>>().length, greaterThan(40));
    });
  });

  group('applyDiff', () {
    AppStackPath pathWith(List<String> ids) {
      final path = AppStackPath();
      path.seed(ids.map(AppRoute.new));
      return path;
    }

    test('is a no-op for an empty operation list or keep-only ops', () {
      final path = pathWith(['a', 'b']);
      applyDiff(path, <DiffOp<AppRoute>>[]);
      applyDiff(path, const [Keep<AppRoute>(0, 0), Keep<AppRoute>(1, 1)]);
      expect(path.stack.map((route) => route.id), ['a', 'b']);
    });

    test('applies deletes from highest index to lowest', () {
      final path = pathWith(['a', 'b', 'c', 'd']);
      applyDiff(path, const [
        Keep<AppRoute>(0, 0),
        Delete<AppRoute>(1),
        Delete<AppRoute>(2),
        Keep<AppRoute>(3, 1),
      ]);
      expect(path.stack.map((route) => route.id), ['a', 'd']);
    });

    test('applies inserts as one atomic replacement', () {
      final retainedA = AppRoute('a');
      final retainedC = AppRoute('c');
      final path = AppStackPath()..seed([retainedA, retainedC]);
      var notifications = 0;
      path.addListener(() => notifications++);

      applyDiff(path, [
        const Keep<AppRoute>(0, 0),
        Insert<AppRoute>(AppRoute('b'), 1),
        const Keep<AppRoute>(1, 2),
      ]);

      expect(path.stack.map((route) => route.id), ['a', 'b', 'c']);
      expect(path.stack[0], same(retainedA));
      expect(path.stack[2], same(retainedC));
      expect(retainedA.onResult.isCompleted, isFalse);
      expect(notifications, 1);
    });

    test('applies mixed deletes and inserts in one replaceAll', () {
      final path = pathWith(['a', 'b', 'c']);
      applyDiff(path, [
        const Keep<AppRoute>(0, 0),
        const Delete<AppRoute>(1),
        Insert<AppRoute>(AppRoute('x'), 1),
        const Keep<AppRoute>(2, 2),
      ]);
      expect(path.stack.map((route) => route.id), ['a', 'x', 'c']);
    });

    test('replaces the whole stack when every item changes', () {
      final path = pathWith(['a', 'b']);
      applyDiff(path, [
        const Delete<AppRoute>(0),
        const Delete<AppRoute>(1),
        Insert<AppRoute>(AppRoute('x'), 0),
        Insert<AppRoute>(AppRoute('y'), 1),
      ]);
      expect(path.stack.map((route) => route.id), ['x', 'y']);
    });

    test('ignores out-of-bounds deletes and appends out-of-range inserts', () {
      final path = pathWith(['a']);
      applyDiff(path, const [Delete<AppRoute>(5)]);
      expect(path.stack.map((route) => route.id), ['a']);

      applyDiff(path, [Insert<AppRoute>(AppRoute('b'), 10)]);
      expect(path.stack.map((route) => route.id), ['a', 'b']);
    });

    test('round-trips myersDiff into the destination stack', () {
      final oldRoutes = [
        'home',
        'profile',
        'settings',
      ].map(AppRoute.new).toList();
      final newRoutes = [
        'home',
        'about',
        'settings',
      ].map(AppRoute.new).toList();
      final path = AppStackPath()..seed(oldRoutes);

      applyDiff(path, myersDiff(oldRoutes, newRoutes));

      expect(path.stack.map((route) => route.id), [
        'home',
        'about',
        'settings',
      ]);
    });

    test('transforms empty to populated and populated to empty', () {
      final empty = AppStackPath();
      applyDiff(empty, myersDiff<AppRoute>([], [AppRoute('a'), AppRoute('b')]));
      expect(empty.stack.map((route) => route.id), ['a', 'b']);

      applyDiff(empty, myersDiff(empty.stack.toList(), <AppRoute>[]));
      expect(empty.stack, isEmpty);
    });
  });
}
