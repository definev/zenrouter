import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  group('NavigationFlowSession', () {
    test(
      'round-trips recorder log through encode, decode, and fromSession',
      () {
        var clockTick = 0;
        final occurredAt = [
          DateTime.utc(2026, 8, 17, 12, 0, 1, 250),
          DateTime.utc(2026, 8, 17, 12, 0, 2),
          DateTime.utc(2026, 8, 17, 12, 0, 3, 500),
        ];
        final exportedAt = DateTime.utc(2026, 8, 17, 12, 0, 4);
        final recorder = NavigationFlowRecorder<String>(
          manifest: _manifest,
          initialUri: Uri.parse('/'),
          clock: () => [...occurredAt, exportedAt][clockTick++],
        );
        addTearDown(recorder.dispose);

        recorder.record(
          _commit(1, '/', '/profile', NavigationHistoryIntent.push),
          actionLabel: 'Open profile',
        );
        recorder.record(
          _commit(2, '/profile', '/settings', NavigationHistoryIntent.push),
          actionLabel: 'Open settings',
        );
        recorder.record(
          _commit(3, '/settings', '/', NavigationHistoryIntent.replace),
        );

        final session = recorder.exportSession();
        expect(
          session.schemaVersion,
          NavigationFlowSession.currentSchemaVersion,
        );
        expect(session.initialUri, Uri.parse('/'));
        expect(session.ignoredTransitionCount, 0);
        expect(session.exportedAt, exportedAt);
        expect(session.transitions, hasLength(3));
        expect(session.transitions.map((row) => row.fromId), [
          'home',
          'profile',
          'settings',
        ]);
        expect(session.transitions.map((row) => row.toId), [
          'profile',
          'settings',
          'home',
        ]);

        final decoded = NavigationFlowSession.decode(session.encode());
        expect(decoded.schemaVersion, session.schemaVersion);
        expect(decoded.initialUri, session.initialUri);
        expect(decoded.ignoredTransitionCount, session.ignoredTransitionCount);
        expect(decoded.exportedAt, session.exportedAt);
        expect(decoded.transitions, hasLength(3));

        final hydrated = NavigationFlowRecorder.fromSession(_manifest, decoded);
        addTearDown(hydrated.dispose);

        expect(hydrated.transitions.map((item) => item.revision), [1, 2, 3]);
        expect(hydrated.transitions.map((item) => item.previousUri), [
          Uri.parse('/'),
          Uri.parse('/profile'),
          Uri.parse('/settings'),
        ]);
        expect(hydrated.transitions.map((item) => item.currentUri), [
          Uri.parse('/profile'),
          Uri.parse('/settings'),
          Uri.parse('/'),
        ]);
        expect(hydrated.transitions.map((item) => item.historyIntent), [
          NavigationHistoryIntent.push,
          NavigationHistoryIntent.push,
          NavigationHistoryIntent.replace,
        ]);
        expect(hydrated.transitions.map((item) => item.actionLabel), [
          'Open profile',
          'Open settings',
          null,
        ]);
        expect(hydrated.transitions.map((item) => item.occurredAt), occurredAt);
        expect(hydrated.entryNodeId, 'home');
        expect(hydrated.edges, hasLength(3));
        expect(hydrated.ignoredTransitionCount, 0);
      },
    );

    test('fromSession rematches URIs and ignores wire fromId/toId hints', () {
      final session = NavigationFlowSession(
        initialUri: Uri.parse('/'),
        ignoredTransitionCount: 2,
        transitions: [
          NavigationFlowSessionTransition(
            revision: 1,
            previousUri: '/',
            currentUri: '/profile',
            historyIntent: NavigationHistoryIntent.push.name,
            actionLabel: 'Open profile',
            occurredAt: '2026-08-17T12:00:01.250Z',
            fromId: 'not-home',
            toId: 'not-profile',
          ),
          NavigationFlowSessionTransition(
            revision: 2,
            previousUri: '/profile',
            currentUri: '/outside',
            historyIntent: NavigationHistoryIntent.push.name,
            occurredAt: '2026-08-17T12:00:02.000Z',
            fromId: 'profile',
            toId: 'invented',
          ),
        ],
      );

      final hydrated = NavigationFlowRecorder.fromSession(_manifest, session);
      addTearDown(hydrated.dispose);

      expect(hydrated.ignoredTransitionCount, 3);
      expect(hydrated.transitions, hasLength(1));
      expect(hydrated.transitions.single.fromId, 'home');
      expect(hydrated.transitions.single.toId, 'profile');
      expect(
        hydrated.transitions.single.occurredAt,
        DateTime.utc(2026, 8, 17, 12, 0, 1, 250),
      );
      expect(hydrated.nodes.keys, ['home', 'profile']);
      expect(hydrated.nodes.containsKey('outside'), isFalse);
      expect(hydrated.nodes.containsKey('invented'), isFalse);
      expect(hydrated.edges, hasLength(1));
    });

    test('rejects unknown kind', () {
      expect(
        () => NavigationFlowSession.fromJson(<String, Object?>{
          'schemaVersion': 1,
          'kind': 'zenrouter.devtools.other',
          'initialUri': '/',
          'transitions': const <Map<String, Object?>>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown schemaVersion', () {
      expect(
        () => NavigationFlowSession.fromJson(<String, Object?>{
          'schemaVersion': 2,
          'kind': NavigationFlowSession.kind,
          'initialUri': '/',
          'transitions': const <Map<String, Object?>>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown historyIntent', () {
      expect(
        () => NavigationFlowSession.fromJson(<String, Object?>{
          'schemaVersion': 1,
          'kind': NavigationFlowSession.kind,
          'initialUri': '/',
          'transitions': [
            <String, Object?>{
              'revision': 1,
              'previousUri': '/',
              'currentUri': '/profile',
              'historyIntent': 'pop',
              'occurredAt': '2026-08-17T12:00:01.250Z',
            },
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode of non-object JSON throws FormatException', () {
      expect(
        () => NavigationFlowSession.decode('[]'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => NavigationFlowSession.decode('"session"'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'exportSession omits preview bytes and ignores imported preview keys',
      () {
        final recorder = NavigationFlowRecorder<String>(
          manifest: _manifest,
          initialUri: Uri.parse('/'),
        );
        addTearDown(recorder.dispose);
        recorder.record(
          _commit(1, '/', '/profile', NavigationHistoryIntent.push),
        );
        expect(
          recorder.attachScreenPreview(
            'home',
            Uint8List.fromList([1, 2, 3]),
            revision: 0,
          ),
          isTrue,
        );

        final json = recorder.exportSession().toJson();
        expect(json.containsKey('previews'), isFalse);
        expect(json.containsKey('png'), isFalse);
        expect(json.containsKey('base64'), isFalse);
        expect(recorder.exportSession().encode().contains('png'), isFalse);

        final decoded = NavigationFlowSession.fromJson(<String, Object?>{
          ...json,
          'png': 'not-a-preview',
          'base64': 'AAAA',
          'previews': [
            <String, Object?>{'png': 'deadbeef'},
          ],
        });
        expect(decoded.toJson().containsKey('previews'), isFalse);
        expect(decoded.toJson().containsKey('png'), isFalse);
        expect(decoded.toJson().containsKey('base64'), isFalse);
      },
    );

    test('exportSession encodes enum route ids with idCodec wire names', () {
      final recorder = NavigationFlowRecorder<_SessionId>(
        manifest: _enumManifest,
        initialUri: Uri.parse('/'),
      );
      addTearDown(recorder.dispose);
      recorder.record(
        _commit(1, '/', '/profile', NavigationHistoryIntent.push),
      );

      final row = recorder.exportSession().transitions.single;
      expect(row.fromId, 'home');
      expect(row.toId, 'profile');
    });
  });
}

enum _SessionId { home, profile, settings }

final _manifest = RouteManifest<String>(
  name: 'flow-session-test',
  routes: [
    RouteManifestRoute(id: 'home', path: '/'),
    RouteManifestRoute(id: 'profile', path: '/profile'),
    RouteManifestRoute(id: 'settings', path: '/settings'),
  ],
);

final _enumManifest = RouteManifest<_SessionId>(
  name: 'enum-flow-session-test',
  idCodec: RouteIdCodec.enumValues(_SessionId.values),
  routes: [
    RouteManifestRoute(id: _SessionId.home, path: '/'),
    RouteManifestRoute(id: _SessionId.profile, path: '/profile'),
    RouteManifestRoute(id: _SessionId.settings, path: '/settings'),
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
