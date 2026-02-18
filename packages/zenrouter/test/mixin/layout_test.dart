import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Layout Test Routes & Coordinator
// ============================================================================

abstract class LayoutTestRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends LayoutTestRoute {
  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(key: const ValueKey('home'));
  }

  @override
  List<Object?> get props => [];
}

class SettingRoute extends LayoutTestRoute {
  @override
  Uri toUri() => Uri.parse('/setting');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('setting'),
      body: Center(
        child: ElevatedButton(
          key: const ValueKey('go-back-setting'),
          onPressed: () => coordinator.pop(),
          child: const Text('Go back'),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [];
}

class AllowPopLayoutChildRoute extends LayoutTestRoute {
  AllowPopLayoutChildRoute({this.id = '1'});
  final String id;

  @override
  Type get layout => AllowPopLayout;

  @override
  Uri toUri() => Uri.parse('/allow-pop/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('child-$id'),
      appBar: AppBar(
        title: Text('Child $id'),
        leading: IconButton(
          key: ValueKey('back-button-$id'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => coordinator.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Child Page $id'),
            ElevatedButton(
              key: const ValueKey('push-child-2'),
              onPressed: () =>
                  coordinator.push(AllowPopLayoutChildRoute(id: '2')),
              child: const Text('Push Child 2'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [id];
}

class NotAllowPopLayoutChildRoute extends LayoutTestRoute {
  NotAllowPopLayoutChildRoute({this.id = '1'});
  final String id;

  @override
  Type get layout => NotAllowPopLayout;

  @override
  Uri toUri() => Uri.parse('/not-allow/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: ValueKey('child-$id'),
      appBar: AppBar(
        title: Text('Child $id'),
        leading: IconButton(
          key: ValueKey('back-button-$id'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => coordinator.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Child Page $id'),
            ElevatedButton(
              key: const ValueKey('push-child-2'),
              onPressed: () =>
                  coordinator.push(NotAllowPopLayoutChildRoute(id: '2')),
              child: const Text('Push Child 2'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [id];
}

class AllowPopLayout extends LayoutTestRoute
    with RouteLayout<LayoutTestRoute>, RouteGuard {
  @override
  StackPath<RouteUnique> resolvePath(
    covariant LayoutTestCoordinator coordinator,
  ) => coordinator.allowPopPath;

  @override
  Future<bool> popGuard() async => true;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('layout-scaffold'),
      body: Row(
        children: [
          const SizedBox(width: 50, child: Text('Sidebar (allow pop)')),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
    );
  }
}

class NotAllowPopLayout extends LayoutTestRoute
    with RouteLayout<LayoutTestRoute>, RouteGuard {
  @override
  StackPath<RouteUnique> resolvePath(
    covariant LayoutTestCoordinator coordinator,
  ) => coordinator.notAllowPopPath;

  @override
  Future<bool> popGuard() async => false;

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      key: const ValueKey('layout-scaffold'),
      body: Row(
        children: [
          const SizedBox(width: 50, child: Text('Sidebar')),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
    );
  }
}

class LayoutTestCoordinator extends Coordinator<LayoutTestRoute> {
  late final allowPopPath = NavigationPath<LayoutTestRoute>.create(
    label: 'nested',
    coordinator: this,
  );
  late final notAllowPopPath = NavigationPath<LayoutTestRoute>.create(
    label: 'nested',
    coordinator: this,
  );

  @override
  void defineLayout() {
    defineLayoutParent(AllowPopLayout.new);
    defineLayoutParent(NotAllowPopLayout.new);
  }

  @override
  List<StackPath> get paths => [...super.paths, allowPopPath];

  @override
  LayoutTestRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['allow-pop', final id] => AllowPopLayoutChildRoute(id: id),
      ['not-allow-pop', final id] => NotAllowPopLayoutChildRoute(id: id),
      ['setting'] => SettingRoute(),
      _ => HomeRoute(),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('RouteLayout Mixin Tests', () {
    testWidgets('Layout renders correctly with child', (tester) async {
      final coordinator = LayoutTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push child into nested path manually for this test case (normally coordinator logic would do this)
      coordinator.push(AllowPopLayoutChildRoute(id: '1'));
      await tester.pumpAndSettle();

      // Verify layout structure
      expect(find.byKey(const ValueKey('layout-scaffold')), findsOneWidget);
      expect(find.text('Sidebar (allow pop)'), findsOneWidget);

      // Verify child content
      expect(find.byKey(const ValueKey('child-1')), findsOneWidget);
    });

    testWidgets('Layout guard prevents pop from nested child', (tester) async {
      final coordinator = LayoutTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Start at home
      expect(find.byKey(const ValueKey('home')), findsOneWidget);

      // Push child in TestLayout
      coordinator.push(NotAllowPopLayoutChildRoute(id: '1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('child-1')), findsOneWidget);

      // Try to pop using system back button (simulated)
      // This should hit the layout's route guard because the active route in the root stack is the layout
      await tester.tap(
        find.byKey(const ValueKey('back-button-1')),
      ); // AppBar back button of child
      await tester.pumpAndSettle();

      // Should still be on Layout/Child1
      expect(find.byKey(const ValueKey('layout-scaffold')), findsOneWidget);
      expect(find.byKey(const ValueKey('child-1')), findsOneWidget);

      coordinator.push(SettingRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('setting')), findsOneWidget);

      /// Try to navigate back to home but since the TestLayout has a guard it will not allow it
      coordinator.navigate(HomeRoute());
      await tester.pumpAndSettle();

      // Should still be on Layout/Child1
      expect(find.byKey(const ValueKey('layout-scaffold')), findsOneWidget);
      expect(find.byKey(const ValueKey('child-1')), findsOneWidget);
    });

    testWidgets('Layout guard allows pop to home', (tester) async {
      final coordinator = LayoutTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push child in TestLayout
      coordinator.push(AllowPopLayoutChildRoute(id: '1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('layout-scaffold')), findsOneWidget);

      // Pop root stack
      coordinator.pop();
      await tester.pumpAndSettle();

      // Should be back at home
      expect(find.byKey(const ValueKey('home')), findsOneWidget);
    });

    testWidgets('Nested navigation within layout', (tester) async {
      final coordinator = LayoutTestCoordinator();
      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(AllowPopLayoutChildRoute(id: '1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('child-1')), findsOneWidget);

      // Push another child to nested stack
      coordinator.push(AllowPopLayoutChildRoute(id: '2'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('child-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('child-1')), findsNothing); // Covered

      // Pop child 2
      coordinator.allowPopPath.pop();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('child-1')), findsOneWidget);
    });
  });
}
