import 'package:zenrouter_core/src/history/intent.dart';

/// Immutable snapshot published after a coordinator transaction commits.
final class NavigationCommit {
  const NavigationCommit({
    required this.revision,
    required this.previousUri,
    required this.currentUri,
    required this.historyIntent,
  });

  /// Monotonically increasing coordinator-local commit number.
  final int revision;

  /// URI visible before the transaction started.
  final Uri previousUri;

  /// URI visible after every path mutation in the transaction completed.
  final Uri currentUri;

  /// How an external history adapter should publish [currentUri].
  final NavigationHistoryIntent historyIntent;

  bool get uriChanged => previousUri != currentUri;

  @override
  String toString() =>
      'NavigationCommit($revision, $previousUri -> $currentUri, '
      '$historyIntent)';
}
