import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/src/debug_overlay.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
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

    expect(find.textContaining('WidgetGraph'), findsOneWidget);
    expect(find.textContaining('Current: home'), findsOneWidget);
    expect(find.text('profile'), findsOneWidget);

    await tester.tap(find.text('profile'));
    await tester.pump();

    expect(find.textContaining('Selected: profile'), findsOneWidget);

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
    await tester.pump();
    await tester.tap(find.text('Observed'));
    await tester.pump();

    expect(find.textContaining('2 paths'), findsOneWidget);
    expect(find.text('Open profile ×1'), findsOneWidget);
    expect(find.text('Back home ×1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

abstract class _TestRoute extends RouteTarget with RouteUnique {
  @override
  Widget build(covariant _TestCoordinator coordinator, BuildContext context) =>
      const SizedBox();
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
      RouteManifestRoute(id: 'home', path: '/'),
      RouteManifestRoute(id: 'profile', path: '/profile'),
    ],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  @override
  _TestRoute parseRouteFromUri(Uri uri) =>
      uri.path == '/profile' ? _ProfileRoute() : _HomeRoute();
}
