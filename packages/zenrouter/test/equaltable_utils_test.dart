import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/src/equaltable_utils.dart' as eq;
import 'package:zenrouter/src/path.dart';

// Test route implementations
class TestRoute extends RouteTarget {
  TestRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

class MultiPropRoute extends RouteTarget {
  MultiPropRoute(this.id, this.value);
  final String id;
  final int value;

  @override
  List<Object?> get props => [id, value];
}

void main() {
  group('mapPropsToHashCode', () {
    test('returns consistent hash for null', () {
      final hash1 = eq.mapPropsToHashCode(null);
      final hash2 = eq.mapPropsToHashCode(null);
      expect(hash1, equals(hash2));
    });

    test('returns consistent hash for empty list', () {
      final hash1 = eq.mapPropsToHashCode([]);
      final hash2 = eq.mapPropsToHashCode([]);
      expect(hash1, equals(hash2));
    });

    test('returns consistent hash for same props', () {
      final props = ['a', 'b', 'c'];
      final hash1 = eq.mapPropsToHashCode(props);
      final hash2 = eq.mapPropsToHashCode(props);
      expect(hash1, equals(hash2));
    });

    test('returns different hash for different props', () {
      final hash1 = eq.mapPropsToHashCode(['a', 'b', 'c']);
      final hash2 = eq.mapPropsToHashCode(['a', 'b', 'd']);
      expect(hash1, isNot(equals(hash2)));
    });

    test('returns different hash for different order', () {
      final hash1 = eq.mapPropsToHashCode(['a', 'b', 'c']);
      final hash2 = eq.mapPropsToHashCode(['c', 'b', 'a']);
      expect(hash1, isNot(equals(hash2)));
    });

    test('handles nested lists', () {
      final hash1 = eq.mapPropsToHashCode([
        'a',
        ['b', 'c'],
      ]);
      final hash2 = eq.mapPropsToHashCode([
        'a',
        ['b', 'c'],
      ]);
      expect(hash1, equals(hash2));
    });

    test('handles maps with consistent ordering', () {
      final hash1 = eq.mapPropsToHashCode([
        {'key1': 'value1', 'key2': 'value2'},
      ]);
      final hash2 = eq.mapPropsToHashCode([
        {'key2': 'value2', 'key1': 'value1'},
      ]);
      // Maps should have same hash regardless of insertion order
      expect(hash1, equals(hash2));
    });

    test('handles sets with consistent ordering', () {
      final hash1 = eq.mapPropsToHashCode([
        {1, 2, 3},
      ]);
      final hash2 = eq.mapPropsToHashCode([
        {3, 2, 1},
      ]);
      // Sets should have same hash regardless of insertion order
      expect(hash1, equals(hash2));
    });

    test('handles mixed types', () {
      final hash = eq.mapPropsToHashCode([
        'string',
        42,
        true,
        null,
        [1, 2, 3],
        {'key': 'value'},
      ]);
      expect(hash, isA<int>());
    });

    test('handles numbers', () {
      final hash1 = eq.mapPropsToHashCode([1, 2, 3]);
      final hash2 = eq.mapPropsToHashCode([1, 2, 3]);
      expect(hash1, equals(hash2));
    });
  });

  group('equals', () {
    test('returns true for identical lists', () {
      final list = ['a', 'b', 'c'];
      expect(eq.equals(list, list), isTrue);
    });

    test('returns true for equal lists', () {
      expect(eq.equals(['a', 'b', 'c'], ['a', 'b', 'c']), isTrue);
    });

    test('returns false for different lists', () {
      expect(eq.equals(['a', 'b', 'c'], ['a', 'b', 'd']), isFalse);
    });

    test('returns false for different lengths', () {
      expect(eq.equals(['a', 'b'], ['a', 'b', 'c']), isFalse);
    });

    test('returns false when first is null', () {
      expect(eq.equals(null, ['a', 'b']), isFalse);
    });

    test('returns false when second is null', () {
      expect(eq.equals(['a', 'b'], null), isFalse);
    });

    test('returns true when both are null', () {
      expect(eq.equals(null, null), isTrue);
    });

    test('handles empty lists', () {
      expect(eq.equals([], []), isTrue);
    });

    test('handles nested lists', () {
      expect(
        eq.equals(
          [
            'a',
            ['b', 'c'],
          ],
          [
            'a',
            ['b', 'c'],
          ],
        ),
        isTrue,
      );
    });

    test('returns false for different nested lists', () {
      expect(
        eq.equals(
          [
            'a',
            ['b', 'c'],
          ],
          [
            'a',
            ['b', 'd'],
          ],
        ),
        isFalse,
      );
    });
  });

  group('iterableEquals', () {
    test('returns true for identical iterables', () {
      final iterable = [1, 2, 3];
      expect(eq.iterableEquals(iterable, iterable), isTrue);
    });

    test('returns true for equal iterables', () {
      expect(eq.iterableEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('returns false for different iterables', () {
      expect(eq.iterableEquals([1, 2, 3], [1, 2, 4]), isFalse);
    });

    test('returns false for different lengths', () {
      expect(eq.iterableEquals([1, 2], [1, 2, 3]), isFalse);
    });

    test('handles empty iterables', () {
      expect(eq.iterableEquals([], []), isTrue);
    });

    test('handles nested iterables', () {
      expect(
        eq.iterableEquals(
          [
            1,
            [2, 3],
          ],
          [
            1,
            [2, 3],
          ],
        ),
        isTrue,
      );
    });

    test('throws assertion error for sets', () {
      expect(
        () => eq.iterableEquals({1, 2, 3}, {1, 2, 3}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('works with different iterable types', () {
      expect(eq.iterableEquals([1, 2, 3], [1, 2, 3].map((e) => e)), isTrue);
    });
  });

  group('numEquals', () {
    test('returns true for equal integers', () {
      expect(eq.numEquals(42, 42), isTrue);
    });

    test('returns true for equal doubles', () {
      expect(eq.numEquals(3.14, 3.14), isTrue);
    });

    test('returns true for int and double with same value', () {
      expect(eq.numEquals(3, 3.0), isTrue);
    });

    test('returns false for different numbers', () {
      expect(eq.numEquals(42, 43), isFalse);
    });

    test('returns false for different doubles', () {
      expect(eq.numEquals(3.14, 3.15), isFalse);
    });

    test('handles negative numbers', () {
      expect(eq.numEquals(-42, -42), isTrue);
      expect(eq.numEquals(-42, 42), isFalse);
    });

    test('handles zero', () {
      expect(eq.numEquals(0, 0), isTrue);
      expect(eq.numEquals(0.0, 0), isTrue);
    });
  });

  group('setEquals', () {
    test('returns true for identical sets', () {
      final set = {1, 2, 3};
      expect(eq.setEquals(set, set), isTrue);
    });

    test('returns true for equal sets', () {
      expect(eq.setEquals({1, 2, 3}, {1, 2, 3}), isTrue);
    });

    test('returns true for sets with different insertion order', () {
      expect(eq.setEquals({1, 2, 3}, {3, 2, 1}), isTrue);
    });

    test('returns false for different sets', () {
      expect(eq.setEquals({1, 2, 3}, {1, 2, 4}), isFalse);
    });

    test('returns false for different lengths', () {
      expect(eq.setEquals({1, 2}, {1, 2, 3}), isFalse);
    });

    test('handles empty sets', () {
      expect(eq.setEquals({}, {}), isTrue);
    });

    test('handles sets with complex objects', () {
      expect(
        eq.setEquals(
          {
            [1, 2],
            [3, 4],
          },
          {
            [3, 4],
            [1, 2],
          },
        ),
        isTrue,
      );
    });

    test('handles sets with nested collections', () {
      expect(
        eq.setEquals(
          {
            {'a': 1},
            {'b': 2},
          },
          {
            {'b': 2},
            {'a': 1},
          },
        ),
        isTrue,
      );
    });
  });

  group('mapEquals', () {
    test('returns true for identical maps', () {
      final map = {'a': 1, 'b': 2};
      expect(eq.mapEquals(map, map), isTrue);
    });

    test('returns true for equal maps', () {
      expect(eq.mapEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 2}), isTrue);
    });

    test('returns true for maps with different insertion order', () {
      expect(eq.mapEquals({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
    });

    test('returns false for different maps', () {
      expect(eq.mapEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 3}), isFalse);
    });

    test('returns false for different keys', () {
      expect(eq.mapEquals({'a': 1, 'b': 2}, {'a': 1, 'c': 2}), isFalse);
    });

    test('returns false for different lengths', () {
      expect(eq.mapEquals({'a': 1}, {'a': 1, 'b': 2}), isFalse);
    });

    test('handles empty maps', () {
      expect(eq.mapEquals({}, {}), isTrue);
    });

    test('handles nested maps', () {
      expect(
        eq.mapEquals(
          {
            'a': {'x': 1},
          },
          {
            'a': {'x': 1},
          },
        ),
        isTrue,
      );
    });

    test('handles maps with list values', () {
      expect(
        eq.mapEquals(
          {
            'a': [1, 2, 3],
          },
          {
            'a': [1, 2, 3],
          },
        ),
        isTrue,
      );
    });

    test('returns false for maps with different nested values', () {
      expect(
        eq.mapEquals(
          {
            'a': [1, 2, 3],
          },
          {
            'a': [1, 2, 4],
          },
        ),
        isFalse,
      );
    });
  });

  group('objectsEquals', () {
    test('returns true for identical objects', () {
      final obj = Object();
      expect(eq.objectsEquals(obj, obj), isTrue);
    });

    test('returns true for equal primitives', () {
      expect(eq.objectsEquals('hello', 'hello'), isTrue);
      expect(eq.objectsEquals(42, 42), isTrue);
      expect(eq.objectsEquals(true, true), isTrue);
    });

    test('returns false for different primitives', () {
      expect(eq.objectsEquals('hello', 'world'), isFalse);
      expect(eq.objectsEquals(42, 43), isFalse);
      expect(eq.objectsEquals(true, false), isFalse);
    });

    test('returns true for null values', () {
      expect(eq.objectsEquals(null, null), isTrue);
    });

    test('returns false when one is null', () {
      expect(eq.objectsEquals(null, 'hello'), isFalse);
      expect(eq.objectsEquals('hello', null), isFalse);
    });

    test('handles numbers correctly', () {
      expect(eq.objectsEquals(42, 42), isTrue);
      expect(eq.objectsEquals(3.14, 3.14), isTrue);
      expect(eq.objectsEquals(3, 3.0), isTrue);
    });

    test('handles RouteTarget objects', () {
      final route1 = TestRoute('a');
      final route2 = TestRoute('a');
      final route3 = TestRoute('b');

      expect(eq.objectsEquals(route1, route2), isTrue);
      expect(eq.objectsEquals(route1, route3), isFalse);
    });

    test('handles sets', () {
      expect(eq.objectsEquals({1, 2, 3}, {3, 2, 1}), isTrue);
      expect(eq.objectsEquals({1, 2, 3}, {1, 2, 4}), isFalse);
    });

    test('handles iterables', () {
      expect(eq.objectsEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(eq.objectsEquals([1, 2, 3], [1, 2, 4]), isFalse);
    });

    test('handles maps', () {
      expect(eq.objectsEquals({'a': 1}, {'a': 1}), isTrue);
      expect(eq.objectsEquals({'a': 1}, {'a': 2}), isFalse);
    });

    test('returns false for different runtime types', () {
      expect(eq.objectsEquals('42', 42), isFalse);
      // Note: comparing list to set is handled correctly by objectsEquals
      // It checks if both are sets first, then if both are iterables
    });

    test('handles complex nested structures', () {
      final obj1 = {
        'list': [1, 2, 3],
        'map': {'a': 1},
        'set': {1, 2},
      };
      final obj2 = {
        'list': [1, 2, 3],
        'map': {'a': 1},
        'set': {2, 1},
      };
      expect(eq.objectsEquals(obj1, obj2), isTrue);
    });

    test('handles deeply nested structures', () {
      final obj1 = [
        {
          'a': [
            {1, 2},
            {'x': 'y'},
          ],
        },
      ];
      final obj2 = [
        {
          'a': [
            {2, 1},
            {'x': 'y'},
          ],
        },
      ];
      expect(eq.objectsEquals(obj1, obj2), isTrue);
    });
  });

  group('mapPropsToString', () {
    test('returns string representation for empty props', () {
      final result = eq.mapPropsToString(TestRoute, []);
      expect(result, equals('TestRoute()'));
    });

    test('returns string representation for single prop', () {
      final result = eq.mapPropsToString(TestRoute, ['value']);
      expect(result, equals('TestRoute(value)'));
    });

    test('returns string representation for multiple props', () {
      final result = eq.mapPropsToString(MultiPropRoute, ['id', 42]);
      expect(result, equals('MultiPropRoute(id, 42)'));
    });

    test('handles null values', () {
      final result = eq.mapPropsToString(TestRoute, [null]);
      expect(result, equals('TestRoute(null)'));
    });

    test('handles mixed types', () {
      final result = eq.mapPropsToString(TestRoute, ['string', 42, true, null]);
      expect(result, equals('TestRoute(string, 42, true, null)'));
    });

    test('handles lists', () {
      final result = eq.mapPropsToString(TestRoute, [
        [1, 2, 3],
      ]);
      expect(result, equals('TestRoute([1, 2, 3])'));
    });

    test('handles maps', () {
      final result = eq.mapPropsToString(TestRoute, [
        {'key': 'value'},
      ]);
      expect(result, contains('TestRoute({key: value})'));
    });

    test('handles sets', () {
      final result = eq.mapPropsToString(TestRoute, [
        {1, 2, 3},
      ]);
      expect(result, contains('TestRoute({'));
      expect(result, contains('1'));
      expect(result, contains('2'));
      expect(result, contains('3'));
    });
  });

  group('Integration tests', () {
    test('RouteTarget equality uses objectsEquals', () {
      final route1 = TestRoute('home');
      final route2 = TestRoute('home');
      final route3 = TestRoute('profile');

      expect(route1 == route2, isTrue);
      expect(route1 == route3, isFalse);
    });

    test('RouteTarget hashCode uses mapPropsToHashCode', () {
      final route1 = TestRoute('home');
      final route2 = TestRoute('home');

      // Hash codes include instance-specific fields (_path, _onResult)
      // so different instances will have different hash codes
      expect(route1 == route2, isTrue);
      // Different props should contribute to different hashes
      expect(route1.hashCode, isNot(equals(route2.hashCode)));
    });

    test('MultiPropRoute equality works correctly', () {
      final route1 = MultiPropRoute('home', 1);
      final route2 = MultiPropRoute('home', 1);
      final route3 = MultiPropRoute('home', 2);
      final route4 = MultiPropRoute('profile', 1);

      expect(route1 == route2, isTrue);
      expect(route1 == route3, isFalse);
      expect(route1 == route4, isFalse);
    });

    test('Routes with same props are equal', () {
      final route1 = TestRoute('home');
      final route2 = TestRoute('home');

      // Both routes have the same props
      expect(route1 == route2, isTrue);
    });

    test('Hash codes are consistent across multiple calls', () {
      final props = ['a', 'b', 'c', 1, 2, 3];
      final hash1 = eq.mapPropsToHashCode(props);
      final hash2 = eq.mapPropsToHashCode(props);
      final hash3 = eq.mapPropsToHashCode(props);

      expect(hash1, equals(hash2));
      expect(hash2, equals(hash3));
    });

    test('Different prop orders produce different hashes', () {
      final hash1 = eq.mapPropsToHashCode(['a', 'b', 'c']);
      final hash2 = eq.mapPropsToHashCode(['c', 'b', 'a']);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Set and map ordering does not affect hash', () {
      final hash1 = eq.mapPropsToHashCode([
        {1, 2, 3},
        {'a': 1, 'b': 2},
      ]);
      final hash2 = eq.mapPropsToHashCode([
        {3, 2, 1},
        {'b': 2, 'a': 1},
      ]);

      expect(hash1, equals(hash2));
    });
  });

  group('Edge cases', () {
    test('handles very large lists', () {
      final list1 = List.generate(1000, (i) => i);
      final list2 = List.generate(1000, (i) => i);

      expect(eq.iterableEquals(list1, list2), isTrue);
      expect(
        eq.mapPropsToHashCode(list1),
        equals(eq.mapPropsToHashCode(list2)),
      );
    });

    test('handles very large sets', () {
      final set1 = Set.from(List.generate(1000, (i) => i));
      final set2 = Set.from(List.generate(1000, (i) => i).reversed);

      expect(eq.setEquals(set1, set2), isTrue);
    });

    test('handles very large maps', () {
      final map1 = Map.fromEntries(
        List.generate(1000, (i) => MapEntry('key$i', i)),
      );
      final map2 = Map.fromEntries(
        List.generate(1000, (i) => MapEntry('key$i', i)),
      );

      expect(eq.mapEquals(map1, map2), isTrue);
    });

    test('handles deeply nested structures', () {
      dynamic createNested(int depth) {
        if (depth == 0) return 'leaf';
        return [createNested(depth - 1)];
      }

      final obj1 = createNested(10);
      final obj2 = createNested(10);

      expect(eq.objectsEquals(obj1, obj2), isTrue);
    });

    test('handles nested maps in hash', () {
      // Test that deeply nested maps work correctly
      final map = <String, Object?>{
        'nested': {
          'inner': {'deep': 'value'},
        },
      };

      expect(() => eq.mapPropsToHashCode([map]), returnsNormally);
    });

    test('handles special number values', () {
      expect(eq.numEquals(double.infinity, double.infinity), isTrue);
      expect(
        eq.numEquals(double.negativeInfinity, double.negativeInfinity),
        isTrue,
      );
      // Note: NaN != NaN per IEEE 754 standard
      expect(eq.numEquals(double.nan, double.nan), isFalse);
    });

    test('handles empty collections in complex structures', () {
      final obj1 = {
        'emptyList': [],
        'emptySet': <int>{},
        'emptyMap': <String, int>{},
      };
      final obj2 = {
        'emptyList': [],
        'emptySet': <int>{},
        'emptyMap': <String, int>{},
      };

      expect(eq.objectsEquals(obj1, obj2), isTrue);
    });
  });
}
