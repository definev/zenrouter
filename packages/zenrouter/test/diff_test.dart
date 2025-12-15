import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/src/diff.dart';
import 'package:zenrouter/src/path.dart';

// Test route implementations
class TestRoute extends RouteTarget {
  TestRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class CustomEqualsRoute extends RouteTarget {
  CustomEqualsRoute(this.value);
  final int value;
}

void main() {
  group('DiffOp classes', () {
    test('Keep has correct properties', () {
      const keep = Keep<String>(5, 3);
      expect(keep.oldIndex, 5);
      expect(keep.newIndex, 3);
      expect(keep.toString(), 'Keep(old: 5, new: 3)');
    });

    test('Insert has correct properties', () {
      const insert = Insert<String>('test', 2);
      expect(insert.element, 'test');
      expect(insert.newIndex, 2);
      expect(insert.toString(), 'Insert(test at 2)');
    });

    test('Delete has correct properties', () {
      const delete = Delete<String>(7);
      expect(delete.oldIndex, 7);
      expect(delete.toString(), 'Delete(at 7)');
    });
  });

  group('myersDiff - Edge cases', () {
    test('both lists empty returns empty operations', () {
      final ops = myersDiff<String>([], []);
      expect(ops, isEmpty);
    });

    test('old list empty returns all inserts', () {
      final ops = myersDiff<String>([], ['a', 'b', 'c']);
      expect(ops.length, 3);
      expect(ops[0], isA<Insert<String>>());
      expect(ops[1], isA<Insert<String>>());
      expect(ops[2], isA<Insert<String>>());

      expect((ops[0] as Insert<String>).element, 'a');
      expect((ops[0] as Insert<String>).newIndex, 0);
      expect((ops[1] as Insert<String>).element, 'b');
      expect((ops[1] as Insert<String>).newIndex, 1);
      expect((ops[2] as Insert<String>).element, 'c');
      expect((ops[2] as Insert<String>).newIndex, 2);
    });

    test('new list empty returns all deletes', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], []);
      expect(ops.length, 3);
      expect(ops[0], isA<Delete<String>>());
      expect(ops[1], isA<Delete<String>>());
      expect(ops[2], isA<Delete<String>>());

      expect((ops[0] as Delete<String>).oldIndex, 0);
      expect((ops[1] as Delete<String>).oldIndex, 1);
      expect((ops[2] as Delete<String>).oldIndex, 2);
    });

    test('identical lists return all keeps', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['a', 'b', 'c']);
      expect(ops.length, 3);
      expect(ops.every((op) => op is Keep), isTrue);
    });
  });

  group('myersDiff - Basic operations', () {
    test('single insert', () {
      final ops = myersDiff<String>(['a', 'c'], ['a', 'b', 'c']);
      expect(ops.length, 3);
      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Insert<String>>());
      expect(ops[2], isA<Keep<String>>());

      expect((ops[1] as Insert<String>).element, 'b');
      expect((ops[1] as Insert<String>).newIndex, 1);
    });

    test('single delete', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['a', 'c']);
      expect(ops.length, 3);
      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Delete<String>>());
      expect(ops[2], isA<Keep<String>>());

      expect((ops[1] as Delete<String>).oldIndex, 1);
    });

    test('single replace (delete + insert)', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['a', 'd', 'c']);
      expect(ops.length, 4);
      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Delete<String>>());
      expect(ops[2], isA<Insert<String>>());
      expect(ops[3], isA<Keep<String>>());

      expect((ops[1] as Delete<String>).oldIndex, 1);
      expect((ops[2] as Insert<String>).element, 'd');
    });
  });

  group('myersDiff - Complex scenarios', () {
    test('multiple inserts', () {
      final ops = myersDiff<String>(['a', 'd'], ['a', 'b', 'c', 'd']);
      expect(ops.length, 4);
      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Insert<String>>());
      expect(ops[2], isA<Insert<String>>());
      expect(ops[3], isA<Keep<String>>());
    });

    test('multiple deletes', () {
      final ops = myersDiff<String>(['a', 'b', 'c', 'd'], ['a', 'd']);
      expect(ops.length, 4);
      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Delete<String>>());
      expect(ops[2], isA<Delete<String>>());
      expect(ops[3], isA<Keep<String>>());
    });

    test('interleaved operations', () {
      final ops = myersDiff<String>(['a', 'b', 'c', 'd'], ['a', 'x', 'c', 'y']);

      // Should have: Keep(a), Delete(b), Insert(x), Keep(c), Delete(d), Insert(y)
      expect(ops.any((op) => op is Keep), isTrue);
      expect(ops.any((op) => op is Delete), isTrue);
      expect(ops.any((op) => op is Insert), isTrue);
    });

    test('completely different lists', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['x', 'y', 'z']);

      // Should delete all old and insert all new
      final deletes = ops.whereType<Delete<String>>().toList();
      final inserts = ops.whereType<Insert<String>>().toList();

      expect(deletes.length, 3);
      expect(inserts.length, 3);
    });

    test('reordering elements', () {
      final ops = myersDiff<String>(['a', 'b', 'c'], ['c', 'b', 'a']);

      // Reordering requires deletes and inserts, should have no keeps
      // or different keeps depending on algorithm path
      expect(ops, isNotEmpty);
      expect(ops.any((op) => op is Delete || op is Insert), isTrue);
    });
  });

  group('myersDiff - Custom equality', () {
    test('uses custom equality function', () {
      final old = [
        CustomEqualsRoute(1),
        CustomEqualsRoute(2),
        CustomEqualsRoute(3),
      ];
      final newList = [
        CustomEqualsRoute(1),
        CustomEqualsRoute(4), // Different from 2
        CustomEqualsRoute(3),
      ];

      // With custom equality based on value
      final ops = myersDiff<CustomEqualsRoute>(
        old,
        newList,
        equals: (a, b) => a.value == b.value,
      );

      // Should detect change at index 1
      expect(ops.any((op) => op is Delete || op is Insert), isTrue);
    });

    test('custom equality for modulo comparison', () {
      final ops = myersDiff<int>(
        [1, 2, 3],
        [11, 12, 13],
        equals: (a, b) => a % 10 == b % 10,
      );

      // All should be kept since they match under modulo 10
      expect(ops.length, 3);
      expect(ops.every((op) => op is Keep), isTrue);
    });

    test('default equality when not provided', () {
      final ops = myersDiff<String>(['hello', 'world'], ['hello', 'world']);

      expect(ops.length, 2);
      expect(ops.every((op) => op is Keep), isTrue);
    });
  });

  group('myersDiff - Large lists', () {
    test('handles 50 element list efficiently', () {
      final old = List.generate(50, (i) => 'item_$i');
      final newList = List.generate(50, (i) => 'item_$i');

      final ops = myersDiff<String>(old, newList);

      expect(ops.length, 50);
      expect(ops.every((op) => op is Keep), isTrue);
    });

    test('handles 50 element list with changes', () {
      final old = List.generate(50, (i) => 'item_$i');
      final newList = List.generate(50, (i) {
        if (i == 25) return 'modified_$i';
        return 'item_$i';
      });

      final ops = myersDiff<String>(old, newList);

      expect(ops, isNotEmpty);
      expect(ops.whereType<Keep<String>>().length, greaterThan(40));
    });
  });

  group('myersDiff - Specific patterns', () {
    test('append to end', () {
      final ops = myersDiff<String>(['a', 'b'], ['a', 'b', 'c', 'd']);

      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Keep<String>>());
      expect(ops[2], isA<Insert<String>>());
      expect(ops[3], isA<Insert<String>>());
    });

    test('prepend to beginning', () {
      final ops = myersDiff<String>(['c', 'd'], ['a', 'b', 'c', 'd']);

      expect(ops[0], isA<Insert<String>>());
      expect(ops[1], isA<Insert<String>>());
      expect(ops[2], isA<Keep<String>>());
      expect(ops[3], isA<Keep<String>>());
    });

    test('insert in middle', () {
      final ops = myersDiff<String>(['a', 'd'], ['a', 'b', 'c', 'd']);

      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Insert<String>>());
      expect(ops[2], isA<Insert<String>>());
      expect(ops[3], isA<Keep<String>>());
    });

    test('remove from end', () {
      final ops = myersDiff<String>(['a', 'b', 'c', 'd'], ['a', 'b']);

      expect(ops[0], isA<Keep<String>>());
      expect(ops[1], isA<Keep<String>>());
      expect(ops[2], isA<Delete<String>>());
      expect(ops[3], isA<Delete<String>>());
    });

    test('remove from beginning', () {
      final ops = myersDiff<String>(['a', 'b', 'c', 'd'], ['c', 'd']);

      expect(ops[0], isA<Delete<String>>());
      expect(ops[1], isA<Delete<String>>());
      expect(ops[2], isA<Keep<String>>());
      expect(ops[3], isA<Keep<String>>());
    });
  });

  group('applyDiff', () {
    test('handles empty operations', () {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
      ]);

      applyDiff(path, <DiffOp<TestRoute>>[]);

      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'b');
    });

    test('applies only deletes', () {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
        TestRoute('c'),
      ]);

      final ops = [
        const Keep<TestRoute>(0, 0),
        const Delete<TestRoute>(1),
        const Keep<TestRoute>(2, 1),
      ];

      applyDiff(path, ops);

      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'c');
    });

    test('applies only inserts', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('c'),
      ]);

      final ops = [
        const Keep<TestRoute>(0, 0),
        Insert<TestRoute>(TestRoute('b'), 1),
        const Keep<TestRoute>(1, 2),
      ];

      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 3);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'b');
      expect(path.stack[2].id, 'c');
    });

    test('applies mixed operations', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
        TestRoute('c'),
      ]);

      final ops = [
        const Keep<TestRoute>(0, 0),
        const Delete<TestRoute>(1),
        Insert<TestRoute>(TestRoute('x'), 1),
        const Keep<TestRoute>(2, 2),
      ];

      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 3);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'x');
      expect(path.stack[2].id, 'c');
    });

    test('applies multiple deletes in reverse order', () {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
        TestRoute('c'),
        TestRoute('d'),
      ]);

      final ops = [
        const Keep<TestRoute>(0, 0),
        const Delete<TestRoute>(1),
        const Delete<TestRoute>(2),
        const Keep<TestRoute>(3, 1),
      ];

      applyDiff(path, ops);

      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'd');
    });

    test('applies multiple inserts', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('d'),
      ]);

      final ops = [
        const Keep<TestRoute>(0, 0),
        Insert<TestRoute>(TestRoute('b'), 1),
        Insert<TestRoute>(TestRoute('c'), 2),
        const Keep<TestRoute>(1, 3),
      ];

      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 4);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'b');
      expect(path.stack[2].id, 'c');
      expect(path.stack[3].id, 'd');
    });

    test('handles complete replacement', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
      ]);

      final ops = [
        const Delete<TestRoute>(0),
        const Delete<TestRoute>(1),
        Insert<TestRoute>(TestRoute('x'), 0),
        Insert<TestRoute>(TestRoute('y'), 1),
      ];

      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'x');
      expect(path.stack[1].id, 'y');
    });
  });

  group('applyDiff - Edge cases', () {
    test('handles delete with out-of-bounds index gracefully', () {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
      ]);

      final ops = [
        const Delete<TestRoute>(5), // Out of bounds
      ];

      applyDiff(path, ops);

      // Should not crash, original stack unchanged
      expect(path.stack.length, 1);
      expect(path.stack[0].id, 'a');
    });

    test('handles insert beyond stack length', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
      ]);

      final ops = [
        Insert<TestRoute>(TestRoute('b'), 10), // Beyond length
      ];

      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      // Should append to end
      expect(path.stack.length, 2);
      expect(path.stack[1].id, 'b');
    });

    test('preserves Keep operations as no-op', () {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
      ]);

      final ops = [const Keep<TestRoute>(0, 0), const Keep<TestRoute>(1, 1)];

      applyDiff(path, ops);

      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'b');
    });
  });

  group('Integration - myersDiff + applyDiff', () {
    test('correctly transforms stack from old to new state', () async {
      final oldRoutes = <TestRoute>[
        TestRoute('home'),
        TestRoute('profile'),
        TestRoute('settings'),
      ];
      final newRoutes = <TestRoute>[
        TestRoute('home'),
        TestRoute('about'),
        TestRoute('settings'),
      ];

      final path = StackPath.navigationStack('test', oldRoutes.toList());

      final ops = myersDiff<TestRoute>(oldRoutes, newRoutes);
      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 3);
      expect(path.stack[0].id, 'home');
      expect(path.stack[1].id, 'about');
      expect(path.stack[2].id, 'settings');
    });

    test('handles complex transformation', () async {
      final oldRoutes = <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
        TestRoute('c'),
        TestRoute('d'),
      ];
      final newRoutes = <TestRoute>[
        TestRoute('a'),
        TestRoute('x'),
        TestRoute('c'),
        TestRoute('y'),
        TestRoute('z'),
      ];

      final path = StackPath.navigationStack('test', oldRoutes.toList());

      final ops = myersDiff<TestRoute>(oldRoutes, newRoutes);
      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 5);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'x');
      expect(path.stack[2].id, 'c');
      expect(path.stack[3].id, 'y');
      expect(path.stack[4].id, 'z');
    });

    test('handles empty to populated', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[]);

      final newRoutes = <TestRoute>[TestRoute('a'), TestRoute('b')];

      final ops = myersDiff<TestRoute>([], newRoutes);
      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'b');
    });

    test('handles populated to empty', () {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
        TestRoute('b'),
      ]);

      final ops = myersDiff<TestRoute>([TestRoute('a'), TestRoute('b')], []);
      applyDiff(path, ops);

      expect(path.stack, isEmpty);
    });

    test('notifications are triggered', () async {
      final path = StackPath.navigationStack('test', <TestRoute>[
        TestRoute('a'),
      ]);

      var notified = false;
      path.addListener(() {
        notified = true;
      });

      final ops = [Insert<TestRoute>(TestRoute('b'), 1)];
      applyDiff(path, ops);
      await Future.delayed(Duration.zero);

      expect(notified, isTrue);
    });
  });
}
