import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

void main() {
  group('NavigationCommit', () {
    test('reports whether the URI changed and formats as a snapshot', () {
      final changed = NavigationCommit(
        revision: 3,
        previousUri: Uri.parse('/old'),
        currentUri: Uri.parse('/new'),
        historyIntent: NavigationHistoryIntent.push,
      );
      final unchanged = NavigationCommit(
        revision: 4,
        previousUri: Uri.parse('/same'),
        currentUri: Uri.parse('/same'),
        historyIntent: NavigationHistoryIntent.replace,
      );

      expect(changed.uriChanged, isTrue);
      expect(unchanged.uriChanged, isFalse);
      expect(
        changed.toString(),
        'NavigationCommit(3, /old -> /new, NavigationHistoryIntent.push)',
      );
    });
  });

  group('NavigationHistoryIntent', () {
    test('exposes every adapter-facing history mode', () {
      expect(NavigationHistoryIntent.values, [
        NavigationHistoryIntent.automatic,
        NavigationHistoryIntent.push,
        NavigationHistoryIntent.replace,
        NavigationHistoryIntent.traverse,
      ]);
    });
  });
}
