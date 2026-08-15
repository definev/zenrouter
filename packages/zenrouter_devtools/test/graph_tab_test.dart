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
      topologyRoutes.first.position.value,
      topologyPositions.first,
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
      observedNodes.first.position.value,
      observedPositions.first,
    );

    expect(find.textContaining('2 paths'), findsOneWidget);
    expect(find.text('Open profile ×1'), findsOneWidget);
    expect(find.text('Back home ×1'), findsOneWidget);
    final profilePreview = find.byKey(
      const ValueKey('observed-screen-preview-profile'),
    );
    expect(
      find.descendant(of: profilePreview, matching: find.byType(Image)),
      findsOneWidget,
    );

    await tester.tap(profilePreview);
    await tester.pumpAndSettle();
    expect(find.text('Navigate Here'), findsOneWidget);
    expect(find.text('Copy URI'), findsOneWidget);
    expect(find.textContaining('Visited 1 times'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('observed-toggle-labels')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open profile ×1'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('observed-toggle-labels')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open profile ×1'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('observed-screen-capture-toggle')),
    );
    await tester.pump();
    expect(coordinator.debugScreenCaptureEnabled, isFalse);
    expect(find.text('SCREEN CAPTURE OFF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
      RouteManifestLayout(
        id: 'shell',
        path: '/',
        kind: RouteManifestLayoutKind.indexed,
        indexedChildIds: ['home', 'profile'],
      ),
      RouteManifestLayout(
        id: 'auth',
        path: '/auth',
        kind: RouteManifestLayoutKind.stack,
      ),
    ],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  @override
  _TestRoute parseRouteFromUri(Uri uri) =>
      uri.path == '/profile' ? _ProfileRoute() : _HomeRoute();
}
