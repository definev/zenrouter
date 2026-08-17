import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/src/debug_overlay.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  testWidgets('coordinator captures the app layer for an observed screen', (
    tester,
  ) async {
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

    for (var attempt = 0; attempt < 5; attempt += 1) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      if (coordinator.debugNavigationFlow.nodes['home']?.screenPreview !=
          null) {
        break;
      }
    }

    final preview =
        coordinator.debugNavigationFlow.nodes['home']?.screenPreview;
    expect(preview, isNotNull);
    expect(preview!.bytes, isNotEmpty);
    expect(coordinator.debugScreenCapturePixelRatio, 0.8);
    expect(preview.width, 320);
    expect(preview.height, 240);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed launcher moves freely and still opens the panel', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final coordinator = _TestCoordinator();
    addTearDown(coordinator.dispose);
    await tester.pumpWidget(
      CupertinoApp(home: DebugOverlay<_TestRoute>(coordinator: coordinator)),
    );

    final launcher = find.byKey(const ValueKey('zenrouter-debug-launcher'));
    final launcherButton = find.byKey(
      const ValueKey('zenrouter-debug-launcher-button'),
    );
    final initialPosition = tester.getTopLeft(launcher);

    await tester.drag(launcher, const Offset(-300, -200));
    await tester.pump();
    final movedPosition = tester.getTopLeft(launcher);
    expect(movedPosition.dx, closeTo(initialPosition.dx - 300, 1));
    expect(movedPosition.dy, closeTo(initialPosition.dy - 200, 1));

    await tester.tap(launcherButton);
    await tester.pump();
    expect(find.byKey(const ValueKey('zenrouter-debug-panel')), findsOneWidget);

    coordinator.toggleDebugOverlay();
    await tester.pump();
    expect(tester.getTopLeft(launcher), movedPosition);

    tester.view.physicalSize = const Size(300, 250);
    await tester.pump();
    final clampedRect = tester.getRect(launcher);
    expect(clampedRect.left, greaterThanOrEqualTo(16));
    expect(clampedRect.top, greaterThanOrEqualTo(16));
    expect(clampedRect.right, lessThanOrEqualTo(284));
    expect(clampedRect.bottom, lessThanOrEqualTo(234));
    expect(tester.takeException(), isNull);
  });

  testWidgets('debug panel resizes, maximizes, and clamps to the viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final coordinator = _TestCoordinator()..toggleDebugOverlay();
    addTearDown(coordinator.dispose);
    await tester.pumpWidget(
      CupertinoApp(home: DebugOverlay<_TestRoute>(coordinator: coordinator)),
    );

    final panel = find.byKey(const ValueKey('zenrouter-debug-panel'));
    final resizeHandle = find.byKey(
      const ValueKey('zenrouter-debug-panel-resize-handle'),
    );
    final maximizeButton = find.byKey(
      const ValueKey('zenrouter-debug-panel-maximize'),
    );

    expect(tester.getSize(panel), const Size(420, 500));
    await tester.tap(find.text('Graph'));
    await tester.pump();
    final graph = find.byType(NavigationGraphTab<_TestRoute>);
    final initialGraphSize = tester.getSize(graph);

    await tester.drag(resizeHandle, const Offset(-200, -100));
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size(620, 600));
    final resizedGraphSize = tester.getSize(graph);
    expect(resizedGraphSize.width, greaterThan(initialGraphSize.width));
    expect(resizedGraphSize.height, greaterThan(initialGraphSize.height));

    await tester.tap(maximizeButton);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size(1000, 800));
    final maximizedGraphSize = tester.getSize(graph);
    expect(maximizedGraphSize.width, greaterThan(resizedGraphSize.width));
    expect(maximizedGraphSize.height, greaterThan(resizedGraphSize.height));
    expect(resizeHandle, findsNothing);

    await tester.tap(maximizeButton);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size(620, 600));

    tester.view.physicalSize = const Size(500, 450);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size(500, 450));

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel), const Size(620, 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('graph tab appears and exposes interactive node details', (
    tester,
  ) async {
    final coordinator = _TestCoordinator()..toggleDebugOverlay();
    addTearDown(coordinator.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: DebugOverlay<_TestRoute>(coordinator: coordinator),
        ),
      ),
    );

    expect(find.text('Graph'), findsOneWidget);
    await tester.tap(find.text('Graph'));
    await tester.pump();

    expect(find.byKey(const ValueKey('topology-node-flow')), findsOneWidget);
    expect(find.byKey(const ValueKey('minimap-graph')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('topology-layout-group-shell')),
      findsOneWidget,
    );
    final topologyEditor = tester.widget<NodeFlowEditor<dynamic, Object?>>(
      find.byKey(const ValueKey('topology-node-flow')),
    );
    expect(topologyEditor.behavior, NodeFlowBehavior.preview);
    expect(
      topologyEditor.controller.nodes.values.every((node) => !node.locked),
      isTrue,
    );
    final rootGroups = topologyEditor.controller.nodes.values
        .whereType<GroupNode<dynamic>>()
        .toList(growable: false);
    expect(rootGroups, hasLength(2));
    expect(
      _nodeRect(rootGroups[0]).overlaps(_nodeRect(rootGroups[1])),
      isFalse,
    );
    expect(find.textContaining('WidgetGraph'), findsOneWidget);
    expect(find.textContaining('Current: home'), findsOneWidget);
    expect(find.text('profile'), findsOneWidget);

    final allTopologyRoutes = topologyEditor.controller.nodes.values
        .where((node) => node is! GroupNode<dynamic>)
        .toList(growable: false);
    final profileNode = allTopologyRoutes.singleWhere(
      (node) => (node.data as dynamic).id == 'profile',
    );
    final homeNode = allTopologyRoutes.singleWhere(
      (node) => (node.data as dynamic).id == 'home',
    );
    expect(
      (profileNode.position.value.dx - homeNode.position.value.dx).abs(),
      152.0 + 16.0,
    );
    final topologyRoutes = [
      profileNode,
      allTopologyRoutes.firstWhere((node) => node != profileNode),
    ];
    await tester.tap(find.text('profile'));
    await tester.pump();

    expect(find.textContaining('Selected: profile'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(
      find.byKey(const ValueKey('topology-route-node-home')),
      warnIfMissed: false,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final topologyPositions = [
      for (final node in topologyRoutes) node.position.value,
    ];
    expect(topologyEditor.controller.selectedNodeIds, hasLength(2));
    topologyEditor.controller
      ..startNodeDrag(topologyRoutes.first.id)
      ..moveNodeDrag(const Offset(30, 24))
      ..endNodeDrag();
    await tester.pump();
    _expectNodesMovedTogether(topologyRoutes, topologyPositions);

    await tester.tap(find.byKey(const ValueKey('topology-auto-layout')));
    await tester.pumpAndSettle();
    expect(
      topologyEditor.controller.nodes[topologyRoutes.first.id]?.position.value,
      topologyPositions.first,
    );

    expect(find.byKey(const ValueKey('topology-mode-toggle')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('topology-mode-toggle')));
    await tester.pump();
    expect(
      tester
          .widget<NodeFlowEditor<dynamic, Object?>>(
            find.byKey(const ValueKey('topology-node-flow')),
          )
          .behavior,
      NodeFlowBehavior.inspect,
    );

    await tester.tap(find.byKey(const ValueKey('topology-mode-toggle')));
    await tester.pump();
    expect(
      tester
          .widget<NodeFlowEditor<dynamic, Object?>>(
            find.byKey(const ValueKey('topology-node-flow')),
          )
          .behavior,
      NodeFlowBehavior.preview,
    );

    await coordinator.debugFlowAction(
      'Open profile',
      () => coordinator.pushSilently(_ProfileRoute()),
    );
    await coordinator.debugFlowAction('Back home', () async {
      coordinator
        ..toggleDebugOverlay()
        ..toggleDebugOverlay();
      await coordinator.pushSilently(_HomeRoute());
    });
    coordinator.debugNavigationFlow.attachScreenPreview(
      'profile',
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4'
        '2mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      revision: coordinator.lastNavigationCommit!.revision,
    );
    await tester.pump();
    await tester.tap(find.text('Observed'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('observed-node-flow')), findsOneWidget);
    expect(find.byKey(const ValueKey('minimap-graph')), findsOneWidget);
    final observedEditor = tester.widget<NodeFlowEditor<dynamic, Object?>>(
      find.byKey(const ValueKey('observed-node-flow')),
    );
    expect(observedEditor.behavior, NodeFlowBehavior.preview);
    expect(
      observedEditor.controller.nodes.values.every((node) => !node.locked),
      isTrue,
    );
    final observedNodes = observedEditor.controller.nodes.values.toList(
      growable: false,
    );
    await tester.tap(
      find.byKey(const ValueKey('observed-flow-node-home')),
      warnIfMissed: false,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(
      find.byKey(const ValueKey('observed-flow-node-profile')),
      warnIfMissed: false,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final observedPositions = [
      for (final node in observedNodes) node.position.value,
    ];
    expect(observedEditor.controller.selectedNodeIds, hasLength(2));
    observedEditor.controller
      ..startNodeDrag(observedNodes.first.id)
      ..moveNodeDrag(const Offset(24, 30))
      ..endNodeDrag();
    await tester.pump();
    _expectNodesMovedTogether(observedNodes, observedPositions);

    await tester.tap(find.byKey(const ValueKey('observed-auto-layout')));
    await tester.pumpAndSettle();
    expect(
      observedEditor.controller.nodes[observedNodes.first.id]?.position.value,
      observedPositions.first,
    );

    expect(find.textContaining('2 paths'), findsOneWidget);
    expect(find.text('Open profile ×1'), findsNothing);
    expect(find.text('Back home ×1'), findsNothing);
    final observedAfterLayout = observedEditor.controller.nodes.values.toList(
      growable: false,
    );
    final observedHome = observedAfterLayout.singleWhere(
      (node) => (node.data as dynamic).id == 'home',
    );
    final observedProfile = observedAfterLayout.singleWhere(
      (node) => (node.data as dynamic).id == 'profile',
    );
    expect(
      observedProfile.position.value.dy,
      greaterThan(observedHome.position.value.dy),
    );

    final profilePreview = find.byKey(
      const ValueKey('observed-screen-preview-profile'),
    );
    expect(
      find.descendant(of: profilePreview, matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('observed-screen-zoom-profile')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Navigate Here'), findsOneWidget);
    expect(find.text('Copy URI'), findsOneWidget);
    expect(find.textContaining(RegExp(r'Visited \d+ times')), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pumpAndSettle();
    expect(find.text('Navigate Here'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('observed-screen-capture-toggle')),
    );
    await tester.pump();
    expect(coordinator.debugScreenCaptureEnabled, isFalse);
    expect(find.text('SCREEN CAPTURE OFF'), findsOneWidget);

    expect(find.byKey(const ValueKey('observed-mode-toggle')), findsOneWidget);
    expect(
      tester
          .widget<NodeFlowEditor<dynamic, Object?>>(
            find.byKey(const ValueKey('observed-node-flow')),
          )
          .behavior,
      NodeFlowBehavior.preview,
    );

    await tester.tap(find.byKey(const ValueKey('observed-mode-toggle')));
    await tester.pump();
    expect(
      tester
          .widget<NodeFlowEditor<dynamic, Object?>>(
            find.byKey(const ValueKey('observed-node-flow')),
          )
          .behavior,
      NodeFlowBehavior.inspect,
    );

    await tester.tap(find.byKey(const ValueKey('observed-mode-toggle')));
    await tester.pump();
    expect(
      tester
          .widget<NodeFlowEditor<dynamic, Object?>>(
            find.byKey(const ValueKey('observed-node-flow')),
          )
          .behavior,
      NodeFlowBehavior.preview,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('topology wraps a fifth sibling route onto the next row', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final coordinator = _WrapCoordinator()..toggleDebugOverlay();
    addTearDown(coordinator.dispose);
    await tester.pumpWidget(
      CupertinoApp(home: DebugOverlay<_WrapRoute>(coordinator: coordinator)),
    );
    await tester.tap(find.text('Graph'));
    await tester.pump();

    final topologyEditor = tester.widget<NodeFlowEditor<dynamic, Object?>>(
      find.byKey(const ValueKey('topology-node-flow')),
    );
    Offset positionOf(String id) => topologyEditor.controller.nodes.values
        .firstWhere(
          (node) => node is! GroupNode && (node.data as dynamic).id == id,
        )
        .position
        .value;

    const slot = 152.0 + 16.0;
    const nodeHeight = 68.0;
    const verticalGap = 16.0;
    final first = positionOf('one');
    expect(positionOf('four').dx - first.dx, slot * 3);
    expect(positionOf('four').dy, first.dy);
    expect(positionOf('five').dx, first.dx);
    expect(positionOf('five').dy, first.dy + nodeHeight + verticalGap);
  });

  testWidgets('play key exists after matched transitions are recorded', (
    tester,
  ) async {
    await _pumpObservedWithTransitions(tester);
    expect(find.byKey(const ValueKey('observed-replay-play')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('step changes 1-based REPLAY i / n', (tester) async {
    await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-next')));
    await tester.pump();
    expect(find.textContaining('REPLAY 1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('observed-replay-next')));
    await tester.pump();
    expect(find.textContaining('REPLAY 2 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exit restores LIVE and records the next pushSilently', (
    tester,
  ) async {
    final coordinator = await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
    await tester.pump();
    expect(find.textContaining('REPLAY 1 / 2'), findsOneWidget);
    expect(coordinator.debugNavigationFlowRecording, isFalse);

    await tester.tap(find.byKey(const ValueKey('observed-replay-exit')));
    await tester.pump();
    expect(find.textContaining('REPLAY'), findsNothing);
    expect(find.text('LIVE'), findsWidgets);
    expect(coordinator.debugNavigationFlowRecording, isTrue);

    final before = coordinator.debugNavigationFlow.transitions.length;
    await coordinator.pushSilently(_ProfileRoute());
    await tester.pump();
    expect(coordinator.debugNavigationFlow.transitions, hasLength(before + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leave Observed during live-export replay does not throw', (
    tester,
  ) async {
    final coordinator = await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
    await tester.pump();
    expect(coordinator.debugNavigationFlowRecording, isFalse);

    await tester.tap(find.text('Topology'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(coordinator.debugNavigationFlowRecording, isTrue);

    final before = coordinator.debugNavigationFlow.transitions.length;
    await coordinator.pushSilently(_ProfileRoute());
    await tester.pump();
    expect(coordinator.debugNavigationFlow.transitions, hasLength(before + 1));
  });

  testWidgets('leave Graph during live-export replay does not throw', (
    tester,
  ) async {
    final coordinator = await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
    await tester.pump();

    await tester.tap(find.text('Inspect'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(coordinator.debugNavigationFlowRecording, isTrue);

    final before = coordinator.debugNavigationFlow.transitions.length;
    await coordinator.pushSilently(_ProfileRoute());
    await tester.pump();
    expect(coordinator.debugNavigationFlow.transitions, hasLength(before + 1));
  });

  testWidgets('close overlay during live-export replay does not throw', (
    tester,
  ) async {
    final coordinator = await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
    await tester.pump();

    coordinator.toggleDebugOverlay();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(coordinator.debugNavigationFlowRecording, isTrue);

    final before = coordinator.debugNavigationFlow.transitions.length;
    await coordinator.pushSilently(_ProfileRoute());
    await tester.pump();
    expect(coordinator.debugNavigationFlow.transitions, hasLength(before + 1));
  });

  testWidgets('import of recorded JSON enters replay without a lease', (
    tester,
  ) async {
    final coordinator = await _pumpObservedWithTransitions(tester);
    final encoded = coordinator.debugNavigationFlow.exportSession().encode();
    final recorded = coordinator.debugNavigationFlow.transitions.length;

    await tester.tap(find.byKey(const ValueKey('observed-replay-import')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('observed-replay-import-field')),
      encoded,
    );
    await tester.tap(
      find.byKey(const ValueKey('observed-replay-import-confirm')),
    );
    await tester.pump();

    expect(find.textContaining('REPLAY 1 / 2'), findsOneWidget);
    expect(find.text('Replaying imported session.'), findsOneWidget);
    expect(coordinator.debugNavigationFlowRecording, isTrue);

    await coordinator.pushSilently(_ProfileRoute());
    await tester.pump();
    expect(
      coordinator.debugNavigationFlow.transitions,
      hasLength(recorded + 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('import of unmatched URIs shows banner and disables transport', (
    tester,
  ) async {
    await _pumpObservedWithTransitions(tester);
    const unmatchedJson = '''
{
  "schemaVersion": 1,
  "kind": "zenrouter.devtools.observedSession",
  "initialUri": "/unknown",
  "ignoredTransitionCount": 0,
  "transitions": [
    {
      "revision": 1,
      "previousUri": "/unknown",
      "currentUri": "/also-unknown",
      "historyIntent": "push",
      "occurredAt": "2026-08-17T12:00:01.000Z"
    }
  ]
}''';

    await tester.tap(find.byKey(const ValueKey('observed-replay-import')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('observed-replay-import-field')),
      unmatchedJson,
    );
    await tester.tap(
      find.byKey(const ValueKey('observed-replay-import-confirm')),
    );
    await tester.pump();

    expect(
      find.text('Imported session did not match this manifest.'),
      findsOneWidget,
    );
    expect(find.textContaining('REPLAY 0 / 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
    await tester.pump();
    expect(find.textContaining('REPLAY 0 / 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live navigate during replay does not loadGraph', (tester) async {
    final coordinator = await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-next')));
    await tester.pump();

    final editor = tester.widget<NodeFlowEditor<dynamic, Object?>>(
      find.byKey(const ValueKey('observed-node-flow')),
    );
    final ids = editor.controller.nodes.keys.toList(growable: false);
    final positions = [
      for (final node in editor.controller.nodes.values) node.position.value,
    ];

    await coordinator.navigate(_ProfileRoute());
    await tester.pump();

    expect(editor.controller.nodes.keys.toList(), ids);
    expect([
      for (final node in editor.controller.nodes.values) node.position.value,
    ], positions);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sparkles is disabled during replay', (tester) async {
    await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-next')));
    await tester.pump();

    final editor = tester.widget<NodeFlowEditor<dynamic, Object?>>(
      find.byKey(const ValueKey('observed-node-flow')),
    );
    final firstId = editor.controller.nodes.keys.first;
    final original = editor.controller.nodes[firstId]!.position.value;
    editor.controller
      ..startNodeDrag(firstId)
      ..moveNodeDrag(const Offset(40, 24))
      ..endNodeDrag();
    await tester.pump();
    final moved = editor.controller.nodes[firstId]!.position.value;
    expect(moved, isNot(original));

    await tester.tap(find.byKey(const ValueKey('observed-auto-layout')));
    await tester.pump();
    expect(editor.controller.nodes[firstId]!.position.value, moved);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'camera during live-export replay does not attach or evict previews',
    (tester) async {
      final coordinator = await _pumpObservedWithTransitions(tester);
      const png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4'
          '2mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      final previewRevision = coordinator.lastNavigationCommit!.revision;
      coordinator.debugNavigationFlow.attachScreenPreview(
        'home',
        base64Decode(png),
        revision: previewRevision,
      );
      final playheadPreview = coordinator.debugNavigationFlow
          .previewForRevision(previewRevision);
      expect(playheadPreview, isNotNull);

      await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('observed-screen-capture-toggle')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('observed-screen-capture-toggle')),
      );
      await tester.pump();

      await coordinator.pushSilently(_ProfileRoute());
      await tester.pump();
      for (var attempt = 0; attempt < 5; attempt += 1) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }

      expect(
        coordinator.debugNavigationFlow.previewForRevision(previewRevision),
        same(playheadPreview),
      );
      expect(
        coordinator.debugNavigationFlow.previewForRevision(
          coordinator.lastNavigationCommit!.revision,
        ),
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('trash after play does not throw', (tester) async {
    await _pumpObservedWithTransitions(tester);
    await tester.tap(find.byKey(const ValueKey('observed-replay-play')));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.trash));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('REPLAY'), findsNothing);
  });
}

Future<_TestCoordinator> _pumpObservedWithTransitions(
  WidgetTester tester,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  final coordinator = _TestCoordinator()..toggleDebugOverlay();
  addTearDown(coordinator.dispose);
  await tester.pumpWidget(
    CupertinoApp(home: DebugOverlay<_TestRoute>(coordinator: coordinator)),
  );
  await tester.tap(find.text('Graph'));
  await tester.pump();
  await coordinator.pushSilently(_ProfileRoute());
  await tester.pump();
  await coordinator.pushSilently(_HomeRoute());
  await tester.pump();
  await tester.tap(find.text('Observed'));
  await tester.pump();
  return coordinator;
}

Rect _nodeRect(Node<dynamic> node) => node.position.value & node.size.value;

void _expectNodesMovedTogether(
  List<Node<dynamic>> nodes,
  List<Offset> originalPositions,
) {
  final firstDelta = nodes.first.position.value - originalPositions.first;
  expect(firstDelta.distance, greaterThan(0));
  for (var index = 1; index < nodes.length; index += 1) {
    final delta = nodes[index].position.value - originalPositions[index];
    expect(delta.dx, closeTo(firstDelta.dx, 0.001));
    expect(delta.dy, closeTo(firstDelta.dy, 0.001));
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

final class _WrapRoute extends RouteTarget with RouteUnique {
  _WrapRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri.parse(path);

  @override
  List<Object?> get props => [path];

  @override
  Widget build(covariant _WrapCoordinator coordinator, BuildContext context) =>
      const ColoredBox(color: Color(0xFF059669));
}

final class _WrapCoordinator extends Coordinator<_WrapRoute>
    with CoordinatorDebug<_WrapRoute> {
  static const _tabIds = ['one', 'two', 'three', 'four', 'five'];

  static final manifest = RouteManifest<String>(
    name: 'WrapGraph',
    routes: [
      for (final id in _tabIds)
        RouteManifestRoute(id: id, path: '/$id', parentId: 'shell'),
    ],
    layouts: [
      RouteManifestLayout.indexed(id: 'shell', path: '/', childIds: _tabIds),
    ],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  @override
  _WrapRoute parseRouteFromUri(Uri uri) => _WrapRoute(uri.path);
}

final class _TestCoordinator extends Coordinator<_TestRoute>
    with CoordinatorDebug<_TestRoute> {
  static final manifest = RouteManifest<String>(
    name: 'WidgetGraph',
    routes: [
      RouteManifestRoute(id: 'home', path: '/', parentId: 'shell'),
      RouteManifestRoute(id: 'profile', path: '/profile', parentId: 'shell'),
      RouteManifestRoute(id: 'login', path: '/login', parentId: 'auth'),
    ],
    layouts: [
      RouteManifestLayout.indexed(
        id: 'shell',
        path: '/',
        childIds: ['home', 'profile'],
      ),
      RouteManifestLayout.stack(id: 'auth', path: '/auth'),
    ],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  @override
  _TestRoute parseRouteFromUri(Uri uri) =>
      uri.path == '/profile' ? _ProfileRoute() : _HomeRoute();
}
