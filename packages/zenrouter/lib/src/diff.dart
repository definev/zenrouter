import 'path.dart';

/// Represents a diff operation between two lists.
sealed class DiffOp<T> {
  const DiffOp();
}

/// Represents keeping an element at a specific index (no change).
///
/// Indicates that the element at [oldIndex] in the old list is the same
/// as the element at [newIndex] in the new list.
class Keep<T> extends DiffOp<T> {
  const Keep(this.oldIndex, this.newIndex);

  /// The index of the element in the old list.
  final int oldIndex;

  /// The index of the element in the new list.
  final int newIndex;

  @override
  String toString() => 'Keep(old: $oldIndex, new: $newIndex)';
}

/// Represents inserting a new element at a specific index.
///
/// Indicates that [element] should be inserted at [newIndex] in the new list.
class Insert<T> extends DiffOp<T> {
  const Insert(this.element, this.newIndex);

  /// The element to insert.
  final T element;

  /// The index in the new list where the element should be inserted.
  final int newIndex;

  @override
  String toString() => 'Insert($element at $newIndex)';
}

/// Represents deleting an element at a specific index.
///
/// Indicates that the element at [oldIndex] in the old list should be removed.
class Delete<T> extends DiffOp<T> {
  const Delete(this.oldIndex);

  /// The index of the element in the old list to be removed.
  final int oldIndex;

  @override
  String toString() => 'Delete(at $oldIndex)';
}

/// Myers diff algorithm implementation.
///
/// Computes the shortest edit script (SES) between two lists using the
/// Myers O(ND) algorithm. This is the same algorithm used by Git.
///
/// This implementation is optimized for small lists (n ≤ 50) such as
/// navigation routes, using List-based storage for better cache locality
/// instead of Map-based storage.
///
/// The optional [equals] parameter allows custom equality comparison.
/// If not provided, the default `==` operator is used.
///
/// Example:
/// ```dart
/// final oldList = [route1, route2, route3];
/// final newList = [route1, route4, route3];
/// final ops = myersDiff(oldList, newList);
/// // ops will contain: [Keep(0,0), Delete(1), Insert(route4, 1), Keep(2,2)]
/// ```
List<DiffOp<T>> myersDiff<T>(
  List<T> oldList,
  List<T> newList, {
  bool Function(T a, T b)? equals,
}) {
  final n = oldList.length;
  final m = newList.length;

  // Early exit for empty cases
  if (n == 0 && m == 0) return const [];
  if (n == 0) {
    return List.generate(m, (i) => Insert<T>(newList[i], i), growable: false);
  }
  if (m == 0) {
    return List.generate(n, (i) => Delete<T>(i), growable: false);
  }

  final max = n + m;
  final offset = max;
  final equalityCheck = equals ?? (a, b) => a == b;

  // Use List instead of Map for better cache locality with small lists.
  // V[k] contains the furthest reaching x value on diagonal k.
  // We access v[k] as v[k + offset] to handle negative indices.
  final vSize = 2 * max + 1;
  final v = List<int>.filled(vSize, -1, growable: false);

  // Trace stores snapshots of v for backtracking.
  // For small lists, copying the list is faster than Map overhead.
  final trace = <List<int>>[];

  v[1 + offset] = 0;

  // Find the shortest edit script
  for (var d = 0; d <= max; d++) {
    // Store snapshot for backtracking
    trace.add(List.from(v, growable: false));

    for (var k = -d; k <= d; k += 2) {
      final kIndex = k + offset;
      int x;

      // Decide whether to move right (insert) or down (delete)
      // Add bounds checking to prevent array access errors
      final kMinusOneIndex = k - 1 + offset;
      final kPlusOneIndex = k + 1 + offset;

      final kMinusOne = (kMinusOneIndex >= 0 && kMinusOneIndex < vSize)
          ? v[kMinusOneIndex]
          : -1;
      final kPlusOne = (kPlusOneIndex >= 0 && kPlusOneIndex < vSize)
          ? v[kPlusOneIndex]
          // coverage:ignore-start
          : -1;
      // coverage:ignore-end

      if (k == -d || (k != d && kMinusOne < kPlusOne)) {
        x = kPlusOne;
      } else {
        x = kMinusOne + 1;
      }

      var y = x - k;

      // Follow diagonal (matching elements)
      while (x < n && y < m && equalityCheck(oldList[x], newList[y])) {
        x++;
        y++;
      }

      v[kIndex] = x;

      // Check if we've reached the end
      if (x >= n && y >= m) {
        return _backtrack(trace, oldList, newList, d, offset);
      }
    }
  }

  // coverage:ignore-start
  // Should never reach here, but return empty list as fallback
  return [];
  // coverage:ignore-end
}

/// Backtrack through the trace to construct the edit script.
///
/// This function has been optimized to build operations in reverse order
/// and then reverse the list once at the end, avoiding O(n²) complexity
/// from repeated insertions at index 0.
List<DiffOp<T>> _backtrack<T>(
  List<List<int>> trace,
  List<T> oldList,
  List<T> newList,
  int d,
  int offset,
) {
  final n = oldList.length;
  final m = newList.length;
  var x = n;
  var y = m;

  // Build in reverse order to avoid O(n) insertions at index 0.
  // This changes backtracking from O(n²) to O(n).
  final opsReversed = <DiffOp<T>>[];

  // Backtrack from the end to the beginning
  for (var depth = d; depth >= 0; depth--) {
    final v = trace[depth];
    final k = x - y;
    final vSize = v.length;

    int prevK;
    // Add bounds checking to prevent array access errors
    final kMinusOneIndex = k - 1 + offset;
    final kPlusOneIndex = k + 1 + offset;

    final kMinusOne = (kMinusOneIndex >= 0 && kMinusOneIndex < vSize)
        ? v[kMinusOneIndex]
        // coverage:ignore-start
        : -1;
    // coverage:ignore-end
    final kPlusOne = (kPlusOneIndex >= 0 && kPlusOneIndex < vSize)
        ? v[kPlusOneIndex]
        // coverage:ignore-start
        : -1;
    // coverage:ignore-end

    if (k == -depth || (k != depth && kMinusOne < kPlusOne)) {
      prevK = k + 1;
    } else {
      prevK = k - 1;
    }

    final prevX = v[prevK + offset];
    final prevY = prevX - prevK;

    // Follow diagonal backwards (these are Keep operations)
    while (x > prevX && y > prevY) {
      x--;
      y--;
      opsReversed.add(Keep<T>(x, y));
    }

    if (depth == 0) break;

    // Determine if this was an insert or delete
    if (x == prevX) {
      // Insert
      y--;
      opsReversed.add(Insert<T>(newList[y], y));
    } else {
      // Delete
      x--;
      opsReversed.add(Delete<T>(x));
    }
  }

  // Reverse once at the end instead of inserting at 0 each time
  return opsReversed.reversed.toList();
}

/// Apply diff operations to a NavigationPath.
///
/// This function applies the diff operations calculated by [myersDiff]
/// to efficiently update the navigation path from the old state to the new state.
///
/// The operations are processed carefully to maintain correct indices:
/// - If both deletes and inserts exist, we rebuild the stack once
/// - Deletes alone are processed from highest to lowest index
/// - Inserts alone are processed by building a new stack
/// - Keeps are no-ops
void applyDiff<T extends RouteTarget>(
  NavigationPath<T> path,
  List<DiffOp<T>> operations,
) {
  // Early exit if no operations
  if (operations.isEmpty) return;

  // Group operations by type for efficient processing
  final deletes = <Delete<T>>[];
  final inserts = <Insert<T>>[];

  for (final op in operations) {
    switch (op) {
      case Delete<T>():
        deletes.add(op);
      case Insert<T>():
        inserts.add(op);
      case Keep<T>():
        // No action needed for Keep operations
        break;
    }
  }

  // If we have both deletes and inserts, it's more efficient to
  // build a new stack in one pass rather than multiple modifications
  if (deletes.isNotEmpty && inserts.isNotEmpty) {
    final stackList = path.stack.toList();

    // Apply deletes (reverse order to maintain indices)
    deletes.sort((a, b) => b.oldIndex.compareTo(a.oldIndex));
    for (final delete in deletes) {
      if (delete.oldIndex < stackList.length) {
        stackList.removeAt(delete.oldIndex);
      }
    }

    // Apply inserts
    for (final insert in inserts) {
      if (insert.newIndex <= stackList.length) {
        stackList.insert(insert.newIndex, insert.element);
      } else {
        // coverage:ignore-start
        stackList.add(insert.element);
        // coverage:ignore-end
      }
    }

    // Rebuild the path once
    path.reset();
    for (final route in stackList) {
      path.push(route);
    }
  } else if (deletes.isNotEmpty) {
    // Only deletes: process in reverse order to avoid index shifting
    deletes.sort((a, b) => b.oldIndex.compareTo(a.oldIndex));
    for (final delete in deletes) {
      if (delete.oldIndex < path.stack.length) {
        final element = path.stack[delete.oldIndex];
        path.remove(element);
      }
    }
  } else if (inserts.isNotEmpty) {
    // Only inserts: build new stack
    final stackList = path.stack.toList();
    for (final insert in inserts) {
      if (insert.newIndex <= stackList.length) {
        stackList.insert(insert.newIndex, insert.element);
      } else {
        stackList.add(insert.element);
      }
    }

    // Rebuild the path once
    path.reset();
    for (final route in stackList) {
      path.push(route);
    }
  }
}
