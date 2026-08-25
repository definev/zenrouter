import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  group('DevTools Layout Modes', () {
    testWidgets('defaults to stack layout mode and can switch via setter', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final coordinator = _LayoutTestCoordinator();
      addTearDown(coordinator.dispose);

      expect(coordinator.debugLayoutMode, DevToolsLayoutMode.stack);

      coordinator.setDebugLayoutMode(DevToolsLayoutMode.row);
      expect(coordinator.debugLayoutMode, DevToolsLayoutMode.row);

      coordinator.setDebugLayoutMode(DevToolsLayoutMode.column);
      expect(coordinator.debugLayoutMode, DevToolsLayoutMode.column);

      coordinator.setDebugLayoutMode(DevToolsLayoutMode.stack);
      expect(coordinator.debugLayoutMode, DevToolsLayoutMode.stack);
    });

    testWidgets(
      'Row layout mode places App and DevTools side-by-side and allows resizing',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1000, 800);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        final coordinator = _LayoutTestCoordinator();
        coordinator.setDebugLayoutMode(DevToolsLayoutMode.row);
        coordinator.toggleDebugOverlay();
        addTearDown(coordinator.dispose);

        await tester.pumpWidget(
          CupertinoApp(
            home: CoordinatorView<_LayoutTestRoute>(
              coordinator: coordinator,
              initialUri: Uri.parse('/'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final panel = find.byKey(const ValueKey('zenrouter-debug-panel'));
        final appKey = find.byKey(const ValueKey('layout-test-app-content'));
        final rowResizeHandle = find.byKey(
          const ValueKey('zenrouter-debug-panel-row-resize-handle'),
        );

        expect(panel, findsOneWidget);
        expect(appKey, findsOneWidget);
        expect(rowResizeHandle, findsOneWidget);

        final initialPanelSize = tester.getSize(panel);
        final initialAppSize = tester.getSize(appKey);

        expect(initialPanelSize.width + initialAppSize.width, 1000);
        expect(initialPanelSize.height, 800);
        expect(initialAppSize.height, 800);

        // Drag row resize handle to the left by 100 px -> panel width increases by 100
        await tester.drag(rowResizeHandle, const Offset(-100, 0));
        await tester.pumpAndSettle();

        final resizedPanelSize = tester.getSize(panel);
        final resizedAppSize = tester.getSize(appKey);

        expect(
          resizedPanelSize.width,
          closeTo(initialPanelSize.width + 100, 1),
        );
        expect(resizedAppSize.width, closeTo(initialAppSize.width - 100, 1));
        expect(resizedPanelSize.width + resizedAppSize.width, 1000);

        // Maximize in Row mode
        final maximizeButton = find.byKey(
          const ValueKey('zenrouter-debug-panel-maximize'),
        );
        await tester.tap(maximizeButton);
        await tester.pumpAndSettle();

        expect(tester.getSize(panel).width, 1000);

        // Restore from maximize
        await tester.tap(maximizeButton);
        await tester.pumpAndSettle();

        expect(tester.getSize(panel).width, resizedPanelSize.width);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Column layout mode places App and DevTools vertically and allows resizing',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1000, 800);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        final coordinator = _LayoutTestCoordinator();
        coordinator.setDebugLayoutMode(DevToolsLayoutMode.column);
        coordinator.toggleDebugOverlay();
        addTearDown(coordinator.dispose);

        await tester.pumpWidget(
          CupertinoApp(
            home: CoordinatorView<_LayoutTestRoute>(
              coordinator: coordinator,
              initialUri: Uri.parse('/'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final panel = find.byKey(const ValueKey('zenrouter-debug-panel'));
        final appKey = find.byKey(const ValueKey('layout-test-app-content'));
        final columnResizeHandle = find.byKey(
          const ValueKey('zenrouter-debug-panel-column-resize-handle'),
        );

        expect(panel, findsOneWidget);
        expect(appKey, findsOneWidget);
        expect(columnResizeHandle, findsOneWidget);

        final initialPanelSize = tester.getSize(panel);
        final initialAppSize = tester.getSize(appKey);

        expect(initialPanelSize.height + initialAppSize.height, 800);
        expect(initialPanelSize.width, 1000);
        expect(initialAppSize.width, 1000);

        // Drag column resize handle up by 80 px -> panel height increases by 80
        await tester.drag(columnResizeHandle, const Offset(0, -80));
        await tester.pumpAndSettle();

        final resizedPanelSize = tester.getSize(panel);
        final resizedAppSize = tester.getSize(appKey);

        expect(
          resizedPanelSize.height,
          closeTo(initialPanelSize.height + 80, 1),
        );
        expect(resizedAppSize.height, closeTo(initialAppSize.height - 80, 1));
        expect(resizedPanelSize.height + resizedAppSize.height, 800);

        // Maximize in Column mode
        final maximizeButton = find.byKey(
          const ValueKey('zenrouter-debug-panel-maximize'),
        );
        await tester.tap(maximizeButton);
        await tester.pumpAndSettle();

        expect(tester.getSize(panel).height, 800);

        // Restore from maximize
        await tester.tap(maximizeButton);
        await tester.pumpAndSettle();

        expect(tester.getSize(panel).height, resizedPanelSize.height);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Header tool menu dynamically switches between Stack, Row, and Column',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1000, 800);
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
        });

        final coordinator = _LayoutTestCoordinator()..toggleDebugOverlay();
        addTearDown(coordinator.dispose);

        await tester.pumpWidget(
          CupertinoApp(
            home: CoordinatorView<_LayoutTestRoute>(
              coordinator: coordinator,
              initialUri: Uri.parse('/'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(coordinator.debugLayoutMode, DevToolsLayoutMode.stack);

        final toolMenuButton = find.byKey(
          const ValueKey('zenrouter-debug-tool-menu-button'),
        );
        expect(toolMenuButton, findsOneWidget);

        // Open Tool Menu and select Row
        await tester.tap(toolMenuButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zenrouter-debug-tool-menu-popup')),
          findsOneWidget,
        );

        final rowMenuItem = find.byKey(
          const ValueKey('zenrouter-debug-layout-row'),
        );
        await tester.tap(rowMenuItem);
        await tester.pumpAndSettle();

        expect(coordinator.debugLayoutMode, DevToolsLayoutMode.row);
        expect(find.byType(Row), findsWidgets);
        expect(
          find.byKey(const ValueKey('zenrouter-debug-panel-row-resize-handle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('zenrouter-debug-tool-menu-popup')),
          findsNothing,
        );

        // Open Tool Menu and select Column
        await tester.tap(toolMenuButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zenrouter-debug-tool-menu-popup')),
          findsOneWidget,
        );

        final colMenuItem = find.byKey(
          const ValueKey('zenrouter-debug-layout-column'),
        );
        await tester.tap(colMenuItem);
        await tester.pumpAndSettle();

        expect(coordinator.debugLayoutMode, DevToolsLayoutMode.column);
        expect(find.byType(Column), findsWidgets);
        expect(
          find.byKey(
            const ValueKey('zenrouter-debug-panel-column-resize-handle'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('zenrouter-debug-tool-menu-popup')),
          findsNothing,
        );

        // Open Tool Menu and select Stack
        await tester.tap(toolMenuButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('zenrouter-debug-tool-menu-popup')),
          findsOneWidget,
        );

        final stackMenuItem = find.byKey(
          const ValueKey('zenrouter-debug-layout-stack'),
        );
        await tester.tap(stackMenuItem);
        await tester.pumpAndSettle();

        expect(coordinator.debugLayoutMode, DevToolsLayoutMode.stack);
        expect(
          find.byKey(const ValueKey('zenrouter-debug-panel-resize-handle')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('defaults opaque and can toggle see-through via setter', (
      tester,
    ) async {
      final coordinator = _LayoutTestCoordinator();
      addTearDown(coordinator.dispose);

      expect(coordinator.debugPanelSeeThrough, isFalse);

      coordinator.setDebugPanelSeeThrough(true);
      expect(coordinator.debugPanelSeeThrough, isTrue);

      coordinator.setDebugPanelSeeThrough(false);
      expect(coordinator.debugPanelSeeThrough, isFalse);
    });

    testWidgets('Tool menu see-through toggles translucent panel surfaces', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final coordinator = _LayoutTestCoordinator()..toggleDebugOverlay();
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: CoordinatorView<_LayoutTestRoute>(
            coordinator: coordinator,
            initialUri: Uri.parse('/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(coordinator.debugPanelSeeThrough, isFalse);
      expect(
        find.byKey(const ValueKey('zenrouter-debug-panel-surface-false')),
        findsOneWidget,
      );

      final toolMenuButton = find.byKey(
        const ValueKey('zenrouter-debug-tool-menu-button'),
      );
      await tester.tap(toolMenuButton);
      await tester.pumpAndSettle();

      final seeThroughItem = find.byKey(
        const ValueKey('zenrouter-debug-see-through'),
      );
      expect(seeThroughItem, findsOneWidget);
      await tester.tap(seeThroughItem);
      await tester.pumpAndSettle();

      expect(coordinator.debugPanelSeeThrough, isTrue);
      expect(
        find.byKey(const ValueKey('zenrouter-debug-panel-surface-true')),
        findsOneWidget,
      );
      expect(find.byType(BackdropFilter), findsWidgets);

      final surface = tester.widget<Container>(
        find.byKey(const ValueKey('zenrouter-debug-panel-surface-true')),
      );
      final decoration = surface.decoration! as BoxDecoration;
      expect(decoration.color!.a, closeTo(0.47, 0.001));

      // Toggle back to opaque via menu
      await tester.tap(toolMenuButton);
      await tester.pumpAndSettle();
      await tester.tap(seeThroughItem);
      await tester.pumpAndSettle();

      expect(coordinator.debugPanelSeeThrough, isFalse);
      expect(
        find.byKey(const ValueKey('zenrouter-debug-panel-surface-false')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile FAB respects safe area once (no double bottom inset)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(
        left: 0,
        top: 59,
        right: 0,
        bottom: 34,
      );
      tester.view.viewPadding = const FakeViewPadding(
        left: 0,
        top: 59,
        right: 0,
        bottom: 34,
      );
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
        tester.view.resetViewPadding();
      });

      final coordinator = _LayoutTestCoordinator();
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: CoordinatorView<_LayoutTestRoute>(
            coordinator: coordinator,
            initialUri: Uri.parse('/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final launcher = find.byKey(const ValueKey('zenrouter-debug-launcher'));
      final rect = tester.getRect(launcher);
      // bottom inset (34) + launcher margin (16) = 50 from screen bottom
      expect(rect.bottom, closeTo(844 - 34 - 16, 1));
      expect(rect.right, closeTo(390 - 16, 1));
      // Must not double-apply bottom (34*2 + 16 = 84)
      expect(rect.bottom, greaterThan(844 - 84));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile maximized panel respects top and bottom safe area', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(
        left: 0,
        top: 59,
        right: 0,
        bottom: 34,
      );
      tester.view.viewPadding = const FakeViewPadding(
        left: 0,
        top: 59,
        right: 0,
        bottom: 34,
      );
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
        tester.view.resetViewPadding();
      });

      final coordinator = _LayoutTestCoordinator()..toggleDebugOverlay();
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: CoordinatorView<_LayoutTestRoute>(
            coordinator: coordinator,
            initialUri: Uri.parse('/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final maximizeButton = find.byKey(
        const ValueKey('zenrouter-debug-panel-maximize'),
      );
      await tester.tap(maximizeButton);
      await tester.pumpAndSettle();

      final panel = find.byKey(const ValueKey('zenrouter-debug-panel'));
      final rect = tester.getRect(panel);
      expect(rect.top, closeTo(59, 1));
      expect(rect.bottom, closeTo(844 - 34, 1));
      expect(rect.left, closeTo(0, 1));
      expect(rect.right, closeTo(390, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile defaults to see-through and compact chrome', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final coordinator = _LayoutTestCoordinator()..toggleDebugOverlay();
      addTearDown(coordinator.dispose);

      expect(coordinator.debugPanelSeeThrough, isFalse);
      expect(coordinator.debugPanelSeeThroughForWidth(390), isTrue);
      expect(coordinator.debugPanelSeeThroughForWidth(1000), isFalse);

      await tester.pumpWidget(
        CupertinoApp(
          home: CoordinatorView<_LayoutTestRoute>(
            coordinator: coordinator,
            initialUri: Uri.parse('/'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zenrouter-debug-panel-surface-true')),
        findsOneWidget,
      );
      expect(find.text('DevTools'), findsOneWidget);
      expect(find.text('ZenRouter DevTools'), findsNothing);
      expect(
        find.byKey(const ValueKey('zenrouter-debug-tab-bar-true')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zenrouter-debug-uri-collapsed')),
        findsOneWidget,
      );
      expect(find.text('Go to…'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('zenrouter-debug-uri-expand')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('zenrouter-debug-uri-expanded-true')),
        findsOneWidget,
      );
      expect(find.text('Go to URI'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('zenrouter-debug-uri-collapse')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zenrouter-debug-uri-collapsed')),
        findsOneWidget,
      );

      // Explicit toggle off sticks even on mobile.
      coordinator.setDebugPanelSeeThrough(false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('zenrouter-debug-panel-surface-false')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

final class _LayoutTestRoute extends RouteTarget with RouteUnique {
  _LayoutTestRoute();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  List<Object?> get props => [];

  @override
  Widget build(
    covariant _LayoutTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const SizedBox.expand(
      key: ValueKey('layout-test-app-content'),
      child: ColoredBox(color: Color(0xFF1E293B)),
    );
  }
}

final class _LayoutTestCoordinator extends Coordinator<_LayoutTestRoute>
    with CoordinatorDebug<_LayoutTestRoute> {
  static final manifest = RouteManifest<String>(
    name: 'LayoutTestManifest',
    routes: [RouteManifestRoute(id: 'home', path: '/')],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  @override
  _LayoutTestRoute parseRouteFromUri(Uri uri) => _LayoutTestRoute();
}
