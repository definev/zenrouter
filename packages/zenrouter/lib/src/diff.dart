import 'package:zenrouter/src/core.dart';

/// Represents a diff operation between two lists.
sealed class DiffOp<T> {
  const DiffOp();
}

/// Represents keeping an element at a specific index (no change).
class Keep<T> extends DiffOp<T> {
  const Keep(this.oldIndex, this.newIndex);

  final int oldIndex;
  final int newIndex;

  @override
  String toString() => 'Keep(old: $oldIndex, new: $newIndex)';
}

/// Represents inserting a new element at a specific index.
class Insert<T> extends DiffOp<T> {
  const Insert(this.element, this.newIndex);

  final T element;
  final int newIndex;

  @override
  String toString() => 'Insert($element at $newIndex)';
}

/// Represents deleting an element at a specific index.
class Delete<T> extends DiffOp<T> {
  const Delete(this.oldIndex);

  final int oldIndex;

  @override
  String toString() => 'Delete(at $oldIndex)';
}

/// Myers diff algorithm implementation.
///
/// Computes the shortest edit script (SES) between two lists using the
/// Myers O(ND) algorithm. This is the same algorithm used by Git.
///
/// Example:
/// ```dart
/// final oldList = [route1, route2, route3];
/// final newList = [route1, route4, route3];
/// final ops = myersDiff(oldList, newList);
/// // ops will contain: [Keep(0,0), Delete(1), Insert(route4, 1), Keep(2,2)]
/// ```
List<DiffOp<T>> myersDiff<T>(List<T> oldList, List<T> newList) {
  final n = oldList.length;
  final m = newList.length;
  final max = n + m;

  // V[k] contains the furthest reaching x value on diagonal k
  final v = <int, int>{};

  // Trace stores the V array at each iteration for backtracking
  final trace = <Map<int, int>>[];

  v[1] = 0;

  // Find the shortest edit script
  for (var d = 0; d <= max; d++) {
    trace.add(Map.from(v));

    for (var k = -d; k <= d; k += 2) {
      int x;

      // Decide whether to move right (insert) or down (delete)
      if (k == -d || (k != d && (v[k - 1] ?? -1) < (v[k + 1] ?? -1))) {
        x = v[k + 1] ?? 0;
      } else {
        x = (v[k - 1] ?? 0) + 1;
      }

      var y = x - k;

      // Follow diagonal (matching elements)
      while (x < n && y < m && oldList[x] == newList[y]) {
        x++;
        y++;
      }

      v[k] = x;

      // Check if we've reached the end
      if (x >= n && y >= m) {
        return _backtrack(trace, oldList, newList, d);
      }
    }
  }

  // Should never reach here, but return empty list as fallback
  return [];
}

/// Backtrack through the trace to construct the edit script.
List<DiffOp<T>> _backtrack<T>(
  List<Map<int, int>> trace,
  List<T> oldList,
  List<T> newList,
  int d,
) {
  final n = oldList.length;
  final m = newList.length;
  var x = n;
  var y = m;

  final ops = <DiffOp<T>>[];

  // Backtrack from the end to the beginning
  for (var depth = d; depth >= 0; depth--) {
    final v = trace[depth];
    final k = x - y;

    int prevK;
    if (k == -depth || (k != depth && (v[k - 1] ?? -1) < (v[k + 1] ?? -1))) {
      prevK = k + 1;
    } else {
      prevK = k - 1;
    }

    final prevX = v[prevK] ?? 0;
    final prevY = prevX - prevK;

    // Follow diagonal backwards (these are Keep operations)
    while (x > prevX && y > prevY) {
      x--;
      y--;
      ops.insert(0, Keep<T>(x, y));
    }

    if (depth == 0) break;

    // Determine if this was an insert or delete
    if (x == prevX) {
      // Insert
      y--;
      ops.insert(0, Insert<T>(newList[y], y));
    } else {
      // Delete
      x--;
      ops.insert(0, Delete<T>(x));
    }
  }

  return ops;
}

/// Apply diff operations to a NavigationPath.
///
/// This function applies the diff operations calculated by [myersDiff]
/// to efficiently update the navigation path from the old state to the new state.
///
/// The operations are processed carefully to maintain correct indices:
/// - Deletes are processed from highest to lowest index to avoid shifting
/// - Inserts are processed in order
/// - Keeps are no-ops
void applyDiff<T extends RouteTarget>(
  NavigationPath<T> path,
  List<DiffOp<T>> operations,
) {
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

  // Process deletes in reverse order to avoid index shifting issues
  deletes.sort((a, b) => b.oldIndex.compareTo(a.oldIndex));
  for (final delete in deletes) {
    if (delete.oldIndex < path.stack.length) {
      final element = path.stack[delete.oldIndex];
      path.remove(element);
    }
  }

  // Process inserts in order
  for (final insert in inserts) {
    // Since we've already deleted, we need to insert at the correct position
    // by pushing and then manually adjusting the stack
    path.push(insert.element);

    // Move the newly added element to the correct position
    final currentIndex = path.stack.length - 1;
    if (currentIndex != insert.newIndex) {
      final stackList = path.stack.toList();
      final element = stackList.removeAt(currentIndex);
      stackList.insert(insert.newIndex, element);

      // Clear and rebuild (this is safe because we're in sync)
      path.clear();
      for (final route in stackList) {
        path.push(route);
      }
    }
  }
}
