import 'dart:async';

/// Cooperative cancellation token for route resolution and loaders.
final class RouteCancellationToken {
  final Completer<Object?> _cancelled = Completer<Object?>();
  Object? _reason;

  bool get isCancelled => _cancelled.isCompleted;
  Object? get reason => _reason;

  /// Completes once cancellation is requested.
  Future<Object?> get whenCancelled => _cancelled.future;

  /// Requests cancellation once. Returns false when already cancelled.
  bool cancel([Object? reason]) {
    if (isCancelled) return false;
    _reason = reason;
    _cancelled.complete(reason);
    return true;
  }

  /// Throws [RouteResolutionCancelled] after cancellation was requested.
  void throwIfCancelled() {
    if (isCancelled) throw RouteResolutionCancelled(_reason);
  }
}

/// Control-flow exception used to stop a superseded route resolution.
final class RouteResolutionCancelled implements Exception {
  const RouteResolutionCancelled([this.reason]);

  final Object? reason;

  @override
  String toString() => reason == null
      ? 'Route resolution cancelled'
      : 'Route resolution cancelled: $reason';
}
