// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Definitions
// ============================================================================

abstract class BaseTestRoute extends RouteTarget {
  // Inherits abstract build from RouteUnique:
  // Widget build(covariant Coordinator coordinator, BuildContext context);

  Widget buildWidget(BuildContext context);
}

class TestRoute extends BaseTestRoute with RouteUnique {
  TestRoute(this.path);
  final String path;

  @override
  Uri toUri() => Uri.parse(path);

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Route: $path', key: ValueKey(path)));
  }

  @override
  Widget buildWidget(BuildContext context) =>
      build(DummyCoordinator(), context);

  @override
  List<Object?> get props => [path];
}

class RestorableTestRoute extends BaseTestRoute
    with RouteUnique, RouteRestorable<RestorableTestRoute> {
  RestorableTestRoute(this.id, {this.data});
  final String id;
  final String? data;

  @override
  String get restorationId => id;

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.converter;

  @override
  RestorableConverter<RestorableTestRoute> get converter =>
      const TestRouteConverter();

  @override
  Uri toUri() => Uri.parse('/restorable/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Restorable: $id', key: ValueKey(id)));
  }

  @override
  Widget buildWidget(BuildContext context) =>
      build(DummyCoordinator(), context);

  @override
  List<Object?> get props => [id, data];
}

class TestRouteConverter extends RestorableConverter<RestorableTestRoute> {
  const TestRouteConverter();

  @override
  String get key => 'test_path_converter';

  @override
  RestorableTestRoute deserialize(Map<String, dynamic> data) {
    return RestorableTestRoute(
      data['id'] as String,
      data: data['data'] as String?,
    );
  }

  @override
  Map<String, dynamic> serialize(RestorableTestRoute route) {
    return {'id': route.id, 'data': route.data};
  }
}

class UnimplementedRoute extends BaseTestRoute {
  @override
  Widget buildWidget(BuildContext context) {
    return SizedBox();
  }
}

class DummyCoordinator extends Coordinator<RouteUnique> {
  @override
  void defineConverter() {}

  @override
  RouteUnique parseRouteFromUri(Uri uri) => TestRoute(uri.path);

  @override
  // ignore: must_call_super
  List<StackPath<RouteTarget>> get paths => [];
}

class DummyContext extends Fake implements BuildContext {}

// ============================================================================
// Tests
// ============================================================================

void main() {
  RestorableConverter.defineConverter(
    'test_path_converter',
    () => const TestRouteConverter(),
  );

  group('NavigationStack Standalone Restoration', () {
    testWidgets('restores routes provided manually (String/Unique)', (
      tester,
    ) async {
      final path = NavigationPath<BaseTestRoute>.create();
      TestRoute parseRoute(Uri uri) => TestRoute(uri.toString());

      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'app',
          home: NavigationStack(
            path: path,
            resolver: (route) => StackTransition.material(
              Builder(builder: (context) => route.buildWidget(context)),
            ),
            restorationId: 'main_stack',
            parseRouteFromUri: parseRoute,
          ),
        ),
      );
      await tester.pumpAndSettle();

      path.push(TestRoute('/home'));
      path.push(TestRoute('/details'));
      await tester.pumpAndSettle();

      expect(find.text('Route: /home'), findsNothing);
      expect(find.text('Route: /details'), findsOneWidget);

      final future = tester.restartAndRestore();

      // Clear manual reference to simulate clean start logic on restoration
      path.reset();
      await future;

      await tester.pumpAndSettle();

      expect(path.stack[1], isA<TestRoute>());
      expect(path.stack.length, 2);
    });

    testWidgets('restores complex routes (RouteRestorable/Map)', (
      tester,
    ) async {
      final path = NavigationPath<BaseTestRoute>.create();

      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'app',
          home: NavigationStack(
            path: path,
            resolver: (route) => StackTransition.material(
              Builder(builder: (context) => route.buildWidget(context)),
            ),
            restorationId: 'main_stack',
            parseRouteFromUri: (uri) => TestRoute('/dummy'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      path.push(RestorableTestRoute('123', data: 'Secret Data'));
      await tester.pumpAndSettle();

      expect(find.text('Restorable: 123'), findsOneWidget);

      final future = tester.restartAndRestore();
      path.reset();
      await future;
      await tester.pumpAndSettle();

      expect(path.stack.length, 1);
      final restored = path.stack.first as RestorableTestRoute;
      expect(restored.id, '123');
      expect(restored.data, 'Secret Data');
    });

    testWidgets('restores unimplemented route throw error', (tester) async {
      final path = NavigationPath<BaseTestRoute>.create();

      await tester.pumpWidget(
        MaterialApp(
          restorationScopeId: 'app',
          home: NavigationStack(
            path: path,
            resolver: (route) => StackTransition.material(
              Builder(builder: (context) => route.buildWidget(context)),
            ),
            restorationId: 'main_stack',
            parseRouteFromUri: (uri) => TestRoute('/dummy'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      path.push(UnimplementedRoute());
      await tester.pumpAndSettle();

      final future = tester.restartAndRestore();
      path.reset();
      await future;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isUnimplementedError);
    });

    test(
      'throws assertion error if restoration configured without parser/coordinator',
      () {
        final path = NavigationPath<BaseTestRoute>.create();
        expect(
          () => NavigationStack(
            path: path,
            resolver: (_) => throw UnimplementedError(),
            restorationId: 'main_stack',
          ),
          throwsAssertionError,
        );
      },
    );
  });

  group('IndexedStackPathBuilder Restoration Limitation', () {
    testWidgets(
      'verifies IndexedStackPathBuilder does NOT restore state autonomously',
      (tester) async {
        final coordinator = DummyCoordinator();
        final path = IndexedStackPath<RouteUnique>.createWith(
          [TestRoute('/tab1'), TestRoute('/tab2')],
          coordinator: coordinator,
          label: 'tabs',
        );

        await tester.pumpWidget(
          MaterialApp(
            restorationScopeId: 'app',
            home: Scaffold(
              body: IndexedStackPathBuilder(
                path: path,
                coordinator: coordinator,
                restorationId: 'tabs',
              ),
            ),
          ),
        );

        await path.goToIndexed(1);
        await tester.pumpAndSettle();
        expect(path.activeIndex, 1);

        final future = tester.restartAndRestore();
        path.reset();
        await future;
        await tester.pumpAndSettle();

        expect(path.activeIndex, equals(0));
      },
    );
  });
}
