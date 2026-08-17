import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  group('NavigationFlowPlayer', () {
    test('empty log stays before the first event and ignores transport', () {
      final player = _player(const []);
      addTearDown(player.dispose);

      expect(player.isEmpty, isTrue);
      expect(player.length, 0);
      expect(player.index, -1);
      expect(player.isPlaying, isFalse);
      expect(player.speed, 1);
      expect(player.current, isNull);
      expect(player.fromId, isNull);
      expect(player.toId, isNull);
      expect(player.currentPreview, isNull);
      expect(player.currentPreviewIsStale, isFalse);

      var notifications = 0;
      player.addListener(() => notifications++);
      player.play();
      player.stepForward();
      player.stepBack();
      player.seek(0);
      player.seek(-1);
      player.pause();

      expect(player.index, -1);
      expect(player.isPlaying, isFalse);
      expect(notifications, 0);
    });

    test('play and pause toggle isPlaying and notify listeners', () {
      final timer = _ManualTimer();
      final player = _player(_threeTransitions(), startTimer: timer.start);
      addTearDown(player.dispose);

      var notifications = 0;
      player.addListener(() => notifications++);

      player.play();
      expect(player.isPlaying, isTrue);
      expect(player.index, 0);
      expect(notifications, 1);

      player.play();
      expect(notifications, 1);

      player.pause();
      expect(player.isPlaying, isFalse);
      expect(player.index, 0);
      expect(notifications, 2);

      player.pause();
      expect(notifications, 2);
    });

    test('stepForward and stepBack stay within -1 and last', () {
      final player = _player(_threeTransitions());
      addTearDown(player.dispose);

      expect(player.index, -1);
      player.stepBack();
      expect(player.index, -1);

      player.stepForward();
      expect(player.index, 0);
      expect(player.toId, 'profile');

      player.stepForward();
      expect(player.index, 1);
      player.stepForward();
      expect(player.index, 2);
      player.stepForward();
      expect(player.index, 2);
      expect(player.toId, 'home');

      player.stepBack();
      expect(player.index, 1);
      player.stepBack();
      expect(player.index, 0);
      player.stepBack();
      expect(player.index, -1);
      expect(player.current, isNull);
      player.stepBack();
      expect(player.index, -1);
    });

    test('seek accepts -1 and last and clamps out of range', () {
      final player = _player(_threeTransitions());
      addTearDown(player.dispose);

      player.seek(2);
      expect(player.index, 2);
      expect(player.current?.revision, 3);
      expect(player.fromId, 'settings');
      expect(player.toId, 'home');

      player.seek(-1);
      expect(player.index, -1);
      expect(player.current, isNull);
      expect(player.fromId, isNull);
      expect(player.toId, isNull);

      player.seek(99);
      expect(player.index, 2);
      player.seek(-8);
      expect(player.index, -1);
    });

    test('seek and step pause playback', () {
      final timer = _ManualTimer();
      final player = _player(_threeTransitions(), startTimer: timer.start);
      addTearDown(player.dispose);

      player.play();
      expect(player.isPlaying, isTrue);
      expect(timer.callback, isNotNull);

      player.stepForward();
      expect(player.isPlaying, isFalse);
      expect(player.index, 1);
      expect(timer.callback, isNull);

      player.play();
      player.seek(0);
      expect(player.isPlaying, isFalse);
      expect(player.index, 0);
      expect(timer.callback, isNull);

      player.play();
      player.stepBack();
      expect(player.isPlaying, isFalse);
      expect(player.index, -1);
    });

    test('setSpeed accepts only 0.5, 1, 2, and 4', () {
      final player = _player(_threeTransitions());
      addTearDown(player.dispose);

      var notifications = 0;
      player.addListener(() => notifications++);

      player.setSpeed(2);
      expect(player.speed, 2);
      expect(notifications, 1);

      player.setSpeed(2);
      expect(notifications, 1);

      player.setSpeed(3);
      player.setSpeed(0);
      player.setSpeed(8);
      player.setSpeed(1.5);
      expect(player.speed, 2);
      expect(notifications, 1);

      player.setSpeed(0.5);
      expect(player.speed, 0.5);
      player.setSpeed(4);
      expect(player.speed, 4);
      player.setSpeed(1);
      expect(player.speed, 1);
      expect(notifications, 4);
    });

    test('setSpeed reschedules the pending step while playing', () {
      final timer = _ManualTimer();
      final player = _player(_threeTransitions(), startTimer: timer.start);
      addTearDown(player.dispose);

      player.seek(0);
      player.play();
      expect(timer.startCount, 1);
      expect(timer.delay, const Duration(milliseconds: 250));

      player.setSpeed(2);
      expect(player.speed, 2);
      expect(player.isPlaying, isTrue);
      expect(timer.cancelCount, 1);
      expect(timer.startCount, 2);
      expect(timer.delay, const Duration(milliseconds: 125));
    });

    test('clamps inter-event delays and last-event hold from occurredAt', () {
      final timer = _ManualTimer();
      final transitions = [
        _transition(
          revision: 1,
          fromId: 'home',
          toId: 'profile',
          previousUri: '/',
          currentUri: '/profile',
          occurredAt: DateTime.utc(2026, 8, 17, 12),
        ),
        _transition(
          revision: 2,
          fromId: 'profile',
          toId: 'settings',
          previousUri: '/profile',
          currentUri: '/settings',
          // 100ms raw → minStep 250ms
          occurredAt: DateTime.utc(2026, 8, 17, 12, 0, 0, 100),
        ),
        _transition(
          revision: 3,
          fromId: 'settings',
          toId: 'home',
          previousUri: '/settings',
          currentUri: '/',
          // 500ms raw stays 500ms
          occurredAt: DateTime.utc(2026, 8, 17, 12, 0, 0, 600),
        ),
        _transition(
          revision: 4,
          fromId: 'home',
          toId: 'profile',
          previousUri: '/',
          currentUri: '/profile',
          // 5s raw → maxStep 1500ms
          occurredAt: DateTime.utc(2026, 8, 17, 12, 0, 5, 600),
        ),
      ];
      final player = _player(transitions, startTimer: timer.start);
      addTearDown(player.dispose);

      player.play();
      expect(player.index, 0);
      expect(timer.delay, const Duration(milliseconds: 250));

      timer.fire();
      expect(player.index, 1);
      expect(timer.delay, const Duration(milliseconds: 500));

      timer.fire();
      expect(player.index, 2);
      expect(timer.delay, const Duration(milliseconds: 1500));

      timer.fire();
      expect(player.index, 3);
      expect(player.isPlaying, isTrue);
      expect(timer.delay, const Duration(milliseconds: 250));

      timer.fire();
      expect(player.index, 3);
      expect(player.isPlaying, isFalse);
      expect(timer.callback, isNull);
    });

    test('scales clamped delays by speed without a wall clock', () {
      final timer = _ManualTimer();
      final transitions = [
        _transition(
          revision: 1,
          fromId: 'home',
          toId: 'profile',
          previousUri: '/',
          currentUri: '/profile',
          occurredAt: DateTime.utc(2026, 8, 17, 12),
        ),
        _transition(
          revision: 2,
          fromId: 'profile',
          toId: 'home',
          previousUri: '/profile',
          currentUri: '/',
          occurredAt: DateTime.utc(2026, 8, 17, 12, 0, 5),
        ),
      ];
      final player = _player(transitions, startTimer: timer.start);
      addTearDown(player.dispose);

      player.setSpeed(4);
      player.play();
      expect(timer.delay, const Duration(milliseconds: 375));

      timer.fire();
      expect(player.index, 1);
      expect(timer.delay, const Duration(microseconds: 62500));

      timer.fire();
      expect(player.isPlaying, isFalse);
      expect(player.index, 1);
    });

    test('currentPreview falls back to latest-by-id and marks stale', () {
      final revisionPreview = _preview(revision: 1, bytes: const [1, 2]);
      final latestPreview = _preview(revision: 9, bytes: const [3, 4]);
      final otherPreview = _preview(revision: 2, bytes: const [5]);
      final transitions = _threeTransitions();
      final player = NavigationFlowPlayer<String>(
        transitions: transitions,
        previewsByRevision: {1: revisionPreview, 2: otherPreview},
        latestPreviewById: {'home': latestPreview, 'settings': latestPreview},
      );
      addTearDown(player.dispose);

      expect(player.currentPreview, isNull);
      expect(player.currentPreviewIsStale, isFalse);

      player.seek(0);
      expect(player.currentPreview, same(revisionPreview));
      expect(player.currentPreviewIsStale, isFalse);

      player.seek(1);
      expect(player.currentPreview, same(otherPreview));
      expect(player.currentPreviewIsStale, isFalse);

      player.seek(2);
      expect(player.current?.toId, 'home');
      expect(player.currentPreview, same(latestPreview));
      expect(player.currentPreviewIsStale, isTrue);
    });

    test('missing revision and latest previews are not stale', () {
      final player = _player(_threeTransitions());
      addTearDown(player.dispose);

      player.seek(0);
      expect(player.currentPreview, isNull);
      expect(player.currentPreviewIsStale, isFalse);
    });

    test('notifyListeners on every cursor change', () {
      final timer = _ManualTimer();
      final player = _player(_threeTransitions(), startTimer: timer.start);
      addTearDown(player.dispose);

      final indices = <int>[];
      player.addListener(() => indices.add(player.index));

      player.seek(0);
      player.seek(0);
      player.stepForward();
      player.stepForward();
      player.seek(-1);

      expect(indices, [0, 1, 2, -1]);
    });

    test('dispose cancels the pending timer', () {
      final timer = _ManualTimer();
      final player = _player(_threeTransitions(), startTimer: timer.start);

      player.play();
      expect(timer.startCount, 1);
      expect(timer.cancelCount, 0);
      expect(timer.callback, isNotNull);

      player.dispose();
      expect(timer.cancelCount, 1);
      expect(timer.callback, isNull);
    });

    test('snapshots incoming collections without copying preview bytes', () {
      final preview = _preview(revision: 1, bytes: const [7, 8, 9]);
      final transitions = List<NavigationFlowTransition<String>>.of(
        _threeTransitions().take(1),
      );
      final previewsByRevision = <int, NavigationFlowScreenPreview>{1: preview};
      final latestPreviewById = <String, NavigationFlowScreenPreview>{
        'profile': preview,
      };
      final player = NavigationFlowPlayer<String>(
        transitions: transitions,
        previewsByRevision: previewsByRevision,
        latestPreviewById: latestPreviewById,
      );
      addTearDown(player.dispose);

      player.seek(0);
      expect(player.length, 1);
      expect(player.currentPreview, same(preview));

      transitions.add(_threeTransitions()[1]);
      previewsByRevision[2] = _preview(revision: 2);
      latestPreviewById['settings'] = _preview(revision: 2);

      expect(player.length, 1);
      player.seek(1);
      expect(player.index, 0);
      expect(player.currentPreview, same(preview));
    });

    test('does not loop after the last event', () {
      final timer = _ManualTimer();
      final player = _player(_threeTransitions(), startTimer: timer.start);
      addTearDown(player.dispose);

      player.seek(2);
      player.play();
      expect(player.isPlaying, isTrue);
      expect(timer.delay, const Duration(milliseconds: 250));

      timer.fire();
      expect(player.isPlaying, isFalse);
      expect(player.index, 2);
      expect(timer.callback, isNull);
    });
  });
}

NavigationFlowPlayer<String> _player(
  List<NavigationFlowTransition<String>> transitions, {
  NavigationFlowTimerStart? startTimer,
  Map<int, NavigationFlowScreenPreview> previewsByRevision = const {},
  Map<String, NavigationFlowScreenPreview> latestPreviewById = const {},
}) => NavigationFlowPlayer<String>(
  transitions: transitions,
  previewsByRevision: previewsByRevision,
  latestPreviewById: latestPreviewById,
  startTimer: startTimer,
);

List<NavigationFlowTransition<String>> _threeTransitions() => [
  _transition(
    revision: 1,
    fromId: 'home',
    toId: 'profile',
    previousUri: '/',
    currentUri: '/profile',
    occurredAt: DateTime.utc(2026, 8, 17, 12),
  ),
  _transition(
    revision: 2,
    fromId: 'profile',
    toId: 'settings',
    previousUri: '/profile',
    currentUri: '/settings',
    occurredAt: DateTime.utc(2026, 8, 17, 12, 0, 0, 100),
  ),
  _transition(
    revision: 3,
    fromId: 'settings',
    toId: 'home',
    previousUri: '/settings',
    currentUri: '/',
    occurredAt: DateTime.utc(2026, 8, 17, 12, 0, 0, 200),
  ),
];

NavigationFlowTransition<String> _transition({
  required int revision,
  required String fromId,
  required String toId,
  required String previousUri,
  required String currentUri,
  required DateTime occurredAt,
}) => NavigationFlowTransition<String>(
  revision: revision,
  fromId: fromId,
  toId: toId,
  previousUri: Uri.parse(previousUri),
  currentUri: Uri.parse(currentUri),
  historyIntent: NavigationHistoryIntent.push,
  actionLabel: null,
  occurredAt: occurredAt,
);

NavigationFlowScreenPreview _preview({
  required int revision,
  List<int> bytes = const [1],
}) => NavigationFlowScreenPreview(
  bytes: Uint8List.fromList(bytes),
  revision: revision,
  capturedAt: DateTime.utc(2026, 8, 17),
);

final class _ManualTimer {
  Duration? delay;
  void Function()? callback;
  var startCount = 0;
  var cancelCount = 0;

  NavigationFlowTimerCancel start(Duration delay, void Function() cb) {
    startCount += 1;
    this.delay = delay;
    callback = cb;
    var cancelled = false;
    return () {
      if (cancelled) return;
      cancelled = true;
      cancelCount += 1;
      if (callback == cb) {
        callback = null;
      }
    };
  }

  void fire() {
    final cb = callback;
    callback = null;
    cb?.call();
  }
}
