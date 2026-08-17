import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  group('CoordinatorDebug recording pause lease', () {
    testWidgets('acquire notifies, stacks, and double-release is idempotent', (
      tester,
    ) async {
      final coordinator = _TestCoordinator();
      addTearDown(coordinator.dispose);

      var notifies = 0;
      coordinator.addListener(() => notifies += 1);

      expect(coordinator.debugNavigationFlowRecording, isTrue);

      final releaseFirst = coordinator
          .acquireDebugNavigationFlowRecordingPause();
      expect(notifies, 1);
      expect(coordinator.debugNavigationFlowRecording, isFalse);

      final releaseSecond = coordinator
          .acquireDebugNavigationFlowRecordingPause();
      expect(notifies, 2);
      expect(coordinator.debugNavigationFlowRecording, isFalse);

      notifies = 0;
      releaseFirst();
      expect(notifies, 0);
      expect(coordinator.debugNavigationFlowRecording, isFalse);

      releaseSecond();
      expect(notifies, 0);
      expect(coordinator.debugNavigationFlowRecording, isTrue);

      releaseSecond();
      expect(notifies, 0);
      expect(coordinator.debugNavigationFlowRecording, isTrue);
    });

    testWidgets(
      'lease skips record and capture; release resumes on the next commit',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 300);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        final coordinator = _TestCoordinator();
        addTearDown(coordinator.dispose);
        await tester.pumpWidget(
          CupertinoApp(
            home: CoordinatorView<_TestRoute>(
              coordinator: coordinator,
              initialUri: Uri.parse('/'),
            ),
          ),
        );
        await tester.pump();

        final recorder = coordinator.debugNavigationFlow;
        await _waitForPreview(tester, coordinator, 'home');

        await coordinator.pushSilently(_ProfileRoute());
        await tester.pump();

        expect(recorder.transitions, isNotEmpty);
        final recordedRevision = recorder.lastRecordedRevision;
        final transitionCount = recorder.transitions.length;
        final homePreviewRevision =
            recorder.nodes['home']!.screenPreview!.revision;

        var notifies = 0;
        coordinator.addListener(() => notifies += 1);

        final release = coordinator.acquireDebugNavigationFlowRecordingPause();
        expect(coordinator.debugNavigationFlowRecording, isFalse);
        expect(notifies, 1);

        await coordinator.pushSilently(_HomeRoute());
        await tester.pump();
        coordinator.debugNavigationFlow;
        await _pumpCaptureAttempts(tester);

        expect(recorder.lastRecordedRevision, recordedRevision);
        expect(recorder.transitions, hasLength(transitionCount));
        expect(
          recorder.nodes['home']!.screenPreview!.revision,
          homePreviewRevision,
        );
        expect(
          recorder.previewForRevision(
            coordinator.lastNavigationCommit!.revision,
          ),
          isNull,
        );

        coordinator.clearDebugNavigationFlow();
        await _pumpCaptureAttempts(tester);
        expect(recorder.nodes['home']!.screenPreview, isNull);
        expect(recorder.lastRecordedRevision, recordedRevision);

        notifies = 0;
        release();
        expect(notifies, 0);
        expect(coordinator.debugNavigationFlowRecording, isTrue);

        await coordinator.pushSilently(_ProfileRoute());
        await tester.pump();

        expect(recorder.lastRecordedRevision, greaterThan(recordedRevision));
        expect(recorder.transitions, isNotEmpty);

        release();
        expect(coordinator.debugNavigationFlowRecording, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Future<void> _waitForPreview(
  WidgetTester tester,
  _TestCoordinator coordinator,
  String routeId,
) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    if (coordinator.debugNavigationFlow.nodes[routeId]?.screenPreview != null) {
      return;
    }
  }
  fail('Timed out waiting for $routeId preview');
}

Future<void> _pumpCaptureAttempts(WidgetTester tester) async {
  for (var attempt = 0; attempt < 5; attempt += 1) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
}

abstract class _TestRoute extends RouteTarget with RouteUnique {
  @override
  Widget build(covariant _TestCoordinator coordinator, BuildContext context) =>
      ColoredBox(
        color: this is _ProfileRoute
            ? const Color(0xFF2563EB)
            : const Color(0xFF059669),
      );
}

final class _HomeRoute extends _TestRoute {
  @override
  Uri toUri() => Uri.parse('/');
}

final class _ProfileRoute extends _TestRoute {
  @override
  Uri toUri() => Uri.parse('/profile');
}

final class _TestCoordinator extends Coordinator<_TestRoute>
    with CoordinatorDebug<_TestRoute> {
  static final manifest = RouteManifest<String>(
    name: 'WidgetGraph',
    routes: [
      RouteManifestRoute(id: 'home', path: '/', parentId: 'shell'),
      RouteManifestRoute(id: 'profile', path: '/profile', parentId: 'shell'),
    ],
    layouts: [
      RouteManifestLayout.indexed(
        id: 'shell',
        path: '/',
        childIds: ['home', 'profile'],
      ),
    ],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  @override
  _TestRoute parseRouteFromUri(Uri uri) =>
      uri.path == '/profile' ? _ProfileRoute() : _HomeRoute();
}
