import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  group('NavigationFlowRecorder', () {
    test('records, deduplicates, and aggregates directed transitions', () {
      var clockTick = 0;
      final recorder = NavigationFlowRecorder<String>(
        manifest: _manifest,
        initialUri: Uri.parse('/'),
        clock: () => DateTime.utc(2026, 1, 1, 0, 0, clockTick++),
      );
      addTearDown(recorder.dispose);

      expect(recorder.entryNodeId, 'home');
      expect(recorder.nodes['home']!.visitCount, 1);

      expect(
        recorder.record(
          _commit(1, '/', '/profile', NavigationHistoryIntent.push),
          actionLabel: 'Open profile',
        ),
        isTrue,
      );
      expect(
        recorder.record(
          _commit(1, '/', '/profile', NavigationHistoryIntent.push),
        ),
        isFalse,
      );
      recorder.record(
        _commit(2, '/profile', '/settings', NavigationHistoryIntent.push),
      );
      recorder.record(
        _commit(3, '/settings', '/profile', NavigationHistoryIntent.replace),
      );
      recorder.record(
        _commit(4, '/', '/profile', NavigationHistoryIntent.push),
        actionLabel: 'Open profile',
      );

      expect(recorder.transitions, hasLength(4));
      expect(recorder.edges, hasLength(3));
      expect(recorder.nodes['profile']!.visitCount, 3);
      final homeToProfile = recorder.edges.singleWhere(
        (edge) => edge.fromId == 'home' && edge.toId == 'profile',
      );
      expect(homeToProfile.count, 2);
      expect(homeToProfile.displayLabel, 'Open profile');
      expect(homeToProfile.actionLabels, {'Open profile'});
      expect(homeToProfile.historyIntents, {NavigationHistoryIntent.push});
    });

    test('counts unmatched transitions without inventing graph nodes', () {
      final recorder = NavigationFlowRecorder<String>(
        manifest: _manifest,
        initialUri: Uri.parse('/'),
      );
      addTearDown(recorder.dispose);

      recorder.record(
        _commit(1, '/', '/outside', NavigationHistoryIntent.push),
      );

      expect(recorder.ignoredTransitionCount, 1);
      expect(recorder.edges, isEmpty);
      expect(recorder.nodes.keys, ['home']);
    });

    test(
      'clear preserves revision deduplication and reseeds current route',
      () {
        final recorder = NavigationFlowRecorder<String>(
          manifest: _manifest,
          initialUri: Uri.parse('/'),
        );
        addTearDown(recorder.dispose);
        final commit = _commit(
          7,
          '/',
          '/profile',
          NavigationHistoryIntent.push,
        );
        recorder.record(commit);

        recorder.clear(initialUri: Uri.parse('/profile'));

        expect(recorder.entryNodeId, 'profile');
        expect(recorder.nodes.keys, ['profile']);
        expect(recorder.edges, isEmpty);
        expect(recorder.record(commit), isFalse);
      },
    );

    test('bounds chronological transitions while retaining aggregates', () {
      final recorder = NavigationFlowRecorder<String>(
        manifest: _manifest,
        initialUri: Uri.parse('/'),
        maxTransitions: 2,
      );
      addTearDown(recorder.dispose);
      recorder.record(
        _commit(1, '/', '/profile', NavigationHistoryIntent.push),
      );
      recorder.record(
        _commit(2, '/profile', '/settings', NavigationHistoryIntent.push),
      );
      recorder.record(
        _commit(3, '/settings', '/', NavigationHistoryIntent.replace),
      );

      expect(recorder.transitions.map((item) => item.revision), [2, 3]);
      expect(recorder.edges, hasLength(3));
    });

    test('stores bounded memory-only screen previews', () {
      final recorder = NavigationFlowRecorder<String>(
        manifest: _manifest,
        initialUri: Uri.parse('/'),
        maxScreenPreviews: 2,
      );
      addTearDown(recorder.dispose);
      recorder.record(
        _commit(1, '/', '/profile', NavigationHistoryIntent.push),
      );
      recorder.record(
        _commit(2, '/profile', '/settings', NavigationHistoryIntent.push),
      );

      final homeBytes = Uint8List.fromList([1, 2, 3]);
      expect(
        recorder.attachScreenPreview('home', homeBytes, revision: 0),
        isTrue,
      );
      homeBytes[0] = 9;
      expect(recorder.nodes['home']!.screenPreview!.bytes, [1, 2, 3]);
      recorder.attachScreenPreview(
        'profile',
        Uint8List.fromList([4]),
        revision: 1,
      );
      recorder.attachScreenPreview(
        'settings',
        Uint8List.fromList([5]),
        revision: 2,
      );

      expect(recorder.nodes['home']!.screenPreview, isNull);
      expect(recorder.nodes['profile']!.screenPreview!.bytes, [4]);
      expect(recorder.nodes['settings']!.screenPreview!.bytes, [5]);

      recorder.clear(initialUri: Uri.parse('/settings'));
      expect(recorder.nodes['settings']!.screenPreview, isNull);
    });

    test('aliases node-latest previews by revision without copying bytes', () {
      final recorder = NavigationFlowRecorder<String>(
        manifest: _manifest,
        initialUri: Uri.parse('/'),
        maxScreenPreviews: 2,
      );
      addTearDown(recorder.dispose);
      recorder.record(
        _commit(1, '/', '/profile', NavigationHistoryIntent.push),
      );
      recorder.record(
        _commit(2, '/profile', '/settings', NavigationHistoryIntent.push),
      );

      expect(
        recorder.attachScreenPreview(
          'home',
          Uint8List.fromList([1, 2, 3]),
          revision: 0,
        ),
        isTrue,
      );
      expect(
        recorder.previewForRevision(0),
        same(recorder.nodes['home']!.screenPreview),
      );

      recorder.attachScreenPreview(
        'profile',
        Uint8List.fromList([4]),
        revision: 1,
      );
      recorder.attachScreenPreview(
        'settings',
        Uint8List.fromList([5]),
        revision: 2,
      );

      expect(recorder.nodes['home']!.screenPreview, isNull);
      expect(recorder.previewForRevision(0), isNull);
      expect(
        recorder.previewForRevision(1),
        same(recorder.nodes['profile']!.screenPreview),
      );
      expect(
        recorder.previewForRevision(2),
        same(recorder.nodes['settings']!.screenPreview),
      );

      recorder.attachScreenPreview(
        'profile',
        Uint8List.fromList([6]),
        revision: 3,
      );
      expect(recorder.previewForRevision(1), isNull);
      expect(
        recorder.previewForRevision(3),
        same(recorder.nodes['profile']!.screenPreview),
      );
      expect(recorder.nodes['profile']!.screenPreview!.bytes, [6]);
    });

    test('recapture does not evict other routes from the preview LRU', () {
      final recorder = NavigationFlowRecorder<String>(
        manifest: _manifest,
        initialUri: Uri.parse('/'),
        maxScreenPreviews: 2,
      );
      addTearDown(recorder.dispose);
      recorder.record(
        _commit(1, '/', '/profile', NavigationHistoryIntent.push),
      );

      recorder.attachScreenPreview(
        'home',
        Uint8List.fromList([1]),
        revision: 0,
      );
      recorder.attachScreenPreview(
        'profile',
        Uint8List.fromList([2]),
        revision: 1,
      );
      final profilePreview = recorder.nodes['profile']!.screenPreview;

      for (var revision = 2; revision < 26; revision += 1) {
        recorder.attachScreenPreview(
          'home',
          Uint8List.fromList([revision]),
          revision: revision,
        );
      }

      expect(recorder.previewForRevision(1), same(profilePreview));
      expect(recorder.nodes['profile']!.screenPreview, same(profilePreview));
      expect(recorder.previewForRevision(0), isNull);
      expect(
        recorder.previewForRevision(25),
        same(recorder.nodes['home']!.screenPreview),
      );
    });
  });
}

final _manifest = RouteManifest<String>(
  name: 'flow-test',
  routes: [
    RouteManifestRoute(id: 'home', path: '/'),
    RouteManifestRoute(id: 'profile', path: '/profile'),
    RouteManifestRoute(id: 'settings', path: '/settings'),
  ],
);

NavigationCommit _commit(
  int revision,
  String previousUri,
  String currentUri,
  NavigationHistoryIntent intent,
) => NavigationCommit(
  revision: revision,
  previousUri: Uri.parse(previousUri),
  currentUri: Uri.parse(currentUri),
  historyIntent: intent,
);
