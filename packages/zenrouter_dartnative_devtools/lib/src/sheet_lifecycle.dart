import 'dart:async';

/// The resources owned by one inspector presentation.
abstract interface class DevToolsSheetSession {
  Future<void> get closed;
  void close();
  void dispose();
}

/// Serializes opening without locking the launcher for a sheet's lifetime.
final class DevToolsSheetLifecycle {
  DevToolsSheetLifecycle({this.dismissalTimeout = const Duration(seconds: 1)});

  final Duration dismissalTimeout;
  DevToolsSheetSession? _active;
  bool _opening = false;
  bool _disposed = false;

  Future<void> open(DevToolsSheetSession Function() present) async {
    if (_opening || _disposed) return;
    _opening = true;
    try {
      final previous = _active;
      if (previous != null) await _close(previous);
      if (_disposed) return;

      final session = present();
      _active = session;
      unawaited(
        session.closed.then((_) {
          if (identical(_active, session)) _active = null;
        }),
      );
    } finally {
      _opening = false;
    }
  }

  Future<void> _close(DevToolsSheetSession session) async {
    try {
      session.close();
      await session.closed.timeout(
        dismissalTimeout,
        onTimeout: session.dispose,
      );
    } finally {
      session.dispose();
      if (identical(_active, session)) _active = null;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final session = _active;
    if (session != null) unawaited(_close(session));
  }
}
