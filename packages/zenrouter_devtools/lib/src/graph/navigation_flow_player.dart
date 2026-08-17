import 'dart:async';

import 'package:flutter/foundation.dart';

import 'navigation_flow.dart';

/// Cancels a timer started by [NavigationFlowTimerStart].
typedef NavigationFlowTimerCancel = void Function();

/// Starts [callback] after [delay] and returns a cancel function.
///
/// Production default: [Timer] / [Timer.cancel].
/// Tests: inject `fakeAsync` or a manual map of pending callbacks.
typedef NavigationFlowTimerStart =
    NavigationFlowTimerCancel Function(
      Duration delay,
      void Function() callback,
    );

/// Clock-free playhead over rematched Observed [NavigationFlowTransition]s.
///
/// Incoming lists and maps are copied so callers cannot mutate this snapshot.
/// Preview maps keep refs to existing [NavigationFlowScreenPreview] instances
/// and do not copy PNG bytes.
final class NavigationFlowPlayer<I extends Object> extends ChangeNotifier {
  NavigationFlowPlayer({
    required List<NavigationFlowTransition<I>> transitions,
    required Map<int, NavigationFlowScreenPreview> previewsByRevision,
    required Map<I, NavigationFlowScreenPreview> latestPreviewById,
    NavigationFlowTimerStart? startTimer,
    this.minStep = const Duration(milliseconds: 250),
    this.maxStep = const Duration(milliseconds: 1500),
  }) : _transitions = List.unmodifiable(transitions),
       _previewsByRevision = Map.unmodifiable(previewsByRevision),
       _latestPreviewById = Map.unmodifiable(latestPreviewById),
       _startTimer = startTimer ?? _defaultStartTimer;

  /// Lower bound applied to recorded inter-event gaps (and the last-event hold).
  final Duration minStep;

  /// Upper bound applied to recorded inter-event gaps.
  final Duration maxStep;

  final List<NavigationFlowTransition<I>> _transitions;
  final Map<int, NavigationFlowScreenPreview> _previewsByRevision;
  final Map<I, NavigationFlowScreenPreview> _latestPreviewById;
  final NavigationFlowTimerStart _startTimer;

  int _index = -1;
  bool _isPlaying = false;
  double _speed = 1;
  NavigationFlowTimerCancel? _cancelPending;
  bool _disposed = false;

  /// 0-based playhead. `-1` is before the first event.
  int get index => _index;

  int get length => _transitions.length;

  bool get isPlaying => _isPlaying;

  bool get isEmpty => _transitions.isEmpty;

  /// Playback rate. One of `0.5`, `1`, `2`, or `4`.
  double get speed => _speed;

  NavigationFlowTransition<I>? get current =>
      _index >= 0 && _index < _transitions.length ? _transitions[_index] : null;

  I? get fromId => current?.fromId;

  I? get toId => current?.toId;

  /// Revision-keyed preview, else the latest preview for [toId].
  NavigationFlowScreenPreview? get currentPreview {
    final transition = current;
    if (transition == null) return null;
    return _previewsByRevision[transition.revision] ??
        _latestPreviewById[transition.toId];
  }

  /// True when the revision-keyed preview is missing and the id fallback is used.
  bool get currentPreviewIsStale {
    final transition = current;
    if (transition == null) return false;
    if (_previewsByRevision.containsKey(transition.revision)) return false;
    return _latestPreviewById.containsKey(transition.toId);
  }

  /// Starts playback from the current cursor.
  ///
  /// A playhead still before the first event seeks to index `0`.
  void play() {
    if (_disposed || isEmpty || _isPlaying) return;
    if (_index < 0) {
      _index = 0;
    }
    _isPlaying = true;
    notifyListeners();
    _scheduleAdvance();
  }

  void pause() {
    if (_disposed || !_isPlaying) return;
    _isPlaying = false;
    _cancelPendingTimer();
    notifyListeners();
  }

  /// Advances one event and pauses. No-op at the last event when already paused.
  void stepForward() {
    if (_disposed || isEmpty) return;
    if (_index < length - 1) {
      seek(_index + 1);
      return;
    }
    pause();
  }

  /// Moves one event toward the start and pauses. No-op at `-1` when already paused.
  void stepBack() {
    if (_disposed || isEmpty) return;
    if (_index > -1) {
      seek(_index - 1);
      return;
    }
    pause();
  }

  /// Moves the playhead to [index], clamped to `-1 … length-1`, and pauses.
  void seek(int index) {
    if (_disposed) return;
    final maxIndex = length - 1;
    final next = index < -1 ? -1 : (index > maxIndex ? maxIndex : index);
    final wasPlaying = _isPlaying;
    _cancelPendingTimer();
    _isPlaying = false;
    if (_index == next && !wasPlaying) return;
    _index = next;
    notifyListeners();
  }

  /// Sets the rate to `0.5`, `1`, `2`, or `4`. Other values are ignored.
  ///
  /// If playing, the pending step is cancelled and rescheduled at the new rate.
  void setSpeed(double speed) {
    if (_disposed || !_isAllowedSpeed(speed) || _speed == speed) {
      return;
    }
    _speed = speed;
    notifyListeners();
    if (_isPlaying) {
      _scheduleAdvance();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _isPlaying = false;
    _cancelPendingTimer();
    super.dispose();
  }

  void _scheduleAdvance() {
    _cancelPendingTimer();
    if (_disposed || !_isPlaying || isEmpty) return;
    _cancelPending = _startTimer(_delayFrom(_index), _onTick);
  }

  void _onTick() {
    _cancelPending = null;
    if (_disposed || !_isPlaying) return;
    if (_index >= length - 1) {
      _isPlaying = false;
      notifyListeners();
      return;
    }
    _index += 1;
    notifyListeners();
    if (_isPlaying) {
      _scheduleAdvance();
    }
  }

  Duration _delayFrom(int fromIndex) {
    final raw = fromIndex >= 0 && fromIndex < length - 1
        ? _transitions[fromIndex + 1].occurredAt.difference(
            _transitions[fromIndex].occurredAt,
          )
        : minStep;
    final clamped = raw < minStep
        ? minStep
        : raw > maxStep
        ? maxStep
        : raw;
    return _scale(clamped);
  }

  Duration _scale(Duration duration) {
    if (_speed == 1) return duration;
    return Duration(microseconds: (duration.inMicroseconds / _speed).round());
  }

  void _cancelPendingTimer() {
    final cancel = _cancelPending;
    _cancelPending = null;
    cancel?.call();
  }

  static bool _isAllowedSpeed(double speed) =>
      speed == 0.5 || speed == 1 || speed == 2 || speed == 4;

  static NavigationFlowTimerCancel _defaultStartTimer(
    Duration delay,
    void Function() callback,
  ) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }
}
