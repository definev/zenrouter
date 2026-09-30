import 'dart:async';

import 'package:zenrouter_core/zenrouter_core.dart';

import 'coordinator.dart';

/// One physical presentation, deliberately independent of route value equality.
final class NavigationEntry<T extends RouteUri> {
  NavigationEntry(this.route);
  final T route;
  final Object token = Object();
}

/// Internal seam shared by the real Navigator adapter and the test adapter.
///
/// push completes when mounted, NOT when its pop-result Future completes.
/// pop completes only after the platform acknowledges removal. Native callbacks
/// may be synchronous, duplicated, or arrive after a newer logical commit.
abstract interface class PresentationDriver<T extends RouteUri> {
  Future<void> mountRoot(NavigationEntry<T> entry);
  Future<void> present(
    NavigationEntry<T> entry,
    void Function(Object? result) onDismissed,
  );
  Future<void> dismiss(NavigationEntry<T> entry, Object? result);
}

/// Reconciles committed core snapshots with one native stack.
///
/// It coalesces commits while a native command is in flight. It never derives
/// stack changes from URI/historyIntent, and never waits on a route result to
/// dispatch the next push. A driver failure is terminal for this session:
/// physical state is then unknown and silently retrying would duplicate routes.
final class NavigationSession<T extends RouteUri> {
  NavigationSession({
    required this.coordinator,
    required this.driver,
    required this.onError,
  });

  final Coordinator<T> coordinator;
  final PresentationDriver<T> driver;
  final void Function(Object error, StackTrace stackTrace) onError;

  final _entries = <NavigationEntry<T>>[];
  final _removing = <Object>{};
  final _dismissed = Expando<bool>();
  final _acknowledgements = <Future<void>>{};
  List<T> _desired = [];
  Future<void>? _work;
  Future<bool?>? _backRequest;
  bool _started = false;
  bool _disposed = false;
  Object? failure;

  List<NavigationEntry<T>> get entries => List.unmodifiable(_entries);

  void start() {
    if (_started || _disposed) throw StateError('Session cannot be restarted.');
    _started = true;
    coordinator.addListener(_captureCommit);
    _captureCommit();
  }

  void _captureCommit() {
    if (_disposed || failure != null) return;
    // Capture synchronously: NavigationCommit does not contain path snapshots.
    _desired = List.unmodifiable(coordinator.root.stack);
    _schedule();
  }

  List<T> get _target => [
    for (final route in _desired)
      if (_dismissed[route] != true) route,
  ];

  void _schedule() {
    if (_work != null || _disposed || failure != null) return;
    // Set _work before calling a driver that may synchronously call us back.
    _work = Future<void>.microtask(_drain)
        .catchError((Object e, StackTrace s) {
          _fail(e, s);
        })
        .whenComplete(() {
          _work = null;
          if (!_disposed && failure == null && !_matchesTarget()) _schedule();
        });
  }

  bool _matchesTarget() {
    final target = _target;
    return target.length == _entries.length &&
        List.generate(
          target.length,
          (i) => i,
        ).every((i) => identical(target[i], _entries[i].route));
  }

  Future<void> _drain() async {
    while (!_disposed && failure == null) {
      final target = _target;
      if (target.isEmpty)
        throw StateError('A native stack needs a root route.');
      if (_matchesTarget()) return;

      if (_entries.isEmpty) {
        final entry = NavigationEntry(target.first);
        _entries.add(entry);
        await driver.mountRoot(entry);
        continue;
      }

      var common = 0;
      while (common < target.length &&
          common < _entries.length &&
          identical(target[common], _entries[common].route)) {
        common++;
      }

      if (_entries.length > common && _entries.length > 1) {
        final outgoing = _entries.last;
        _removing.add(outgoing.token);
        try {
          await driver.dismiss(outgoing, outgoing.route.resultValue);
          _entries.removeWhere((entry) => identical(entry, outgoing));
        } finally {
          _removing.remove(outgoing.token);
        }
      } else if (common == 0) {
        final entry = NavigationEntry(target.first);
        _entries[0] = entry;
        await driver.mountRoot(entry);
      } else {
        final entry = NavigationEntry(target[_entries.length]);
        _entries.add(entry);
        await driver.present(
          entry,
          (result) => _presentationDismissed(entry, result),
        );
      }
    }
  }

  void _presentationDismissed(NavigationEntry<T> entry, Object? result) {
    if (_disposed || failure != null || _removing.contains(entry.token)) return;
    final index = _entries.indexWhere((item) => identical(item, entry));
    if (index < 0)
      return; // Duplicate / late callback from an old presentation.
    if (index == 0 || index != _entries.length - 1) {
      _fail(
        StateError('Native removal was not the current pushed screen.'),
        StackTrace.current,
      );
      return;
    }
    _entries.removeLast();
    // A queued snapshot may still contain this route while the core transaction
    // queue is busy. Never re-push a screen the user has just dismissed.
    _dismissed[entry.route] = true;
    final acknowledgement = coordinator
        .acknowledgePop(entry.route, result)
        .then((_) {
          if (!_disposed) _captureCommit();
        }, onError: (Object e, StackTrace s) => _fail(e, s));
    _acknowledgements.add(acknowledgement);
    unawaited(
      acknowledgement.whenComplete(() {
        _acknowledgements.remove(acknowledgement);
      }),
    );
  }

  /// A blocked PopScope requests a guarded logical pop. Double back gestures
  /// share one request, and stale screens can never pop a newer destination.
  Future<bool?> requestPop(NavigationEntry<T> entry, [Object? result]) {
    if (_disposed || failure != null || _removing.contains(entry.token)) {
      return Future.value(false);
    }
    if (_backRequest != null) return _backRequest!;
    final request = coordinator.runNavigationTransaction<bool?>(() {
      if (_disposed ||
          _entries.isEmpty ||
          !identical(_entries.last, entry) ||
          !identical(coordinator.root.activeRoute, entry.route)) {
        return false;
      }
      return coordinator.tryPop(result);
    });
    _backRequest = request;
    // Observe errors without changing the returned Future's error semantics.
    unawaited(
      request.then(
        (_) {
          _backRequest = null;
        },
        onError: (Object e, StackTrace s) {
          _backRequest = null;
        },
      ),
    );
    return request;
  }

  /// Waits for the current native reconciliation, not for a screen's result.
  Future<void> get settled async {
    while (_work != null || _acknowledgements.isNotEmpty) {
      await Future.wait([
        if (_work case final work?) work,
        ..._acknowledgements,
      ]);
    }
    if (failure case final error?) throw error;
  }

  void _fail(Object error, StackTrace stackTrace) {
    if (_disposed || failure != null) return;
    failure = error;
    onError(error, stackTrace);
  }

  /// Driver-side failures that happen after push has mounted (e.g. its result
  /// Future fails) are just as terminal as command failures.
  void reportFailure(Object error, StackTrace stackTrace) =>
      _fail(error, stackTrace);

  /// Detaches only. The app owns the coordinator and the native root lifetime.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    coordinator.removeListener(_captureCommit);
  }
}
