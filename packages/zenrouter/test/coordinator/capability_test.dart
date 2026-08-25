import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class ViewRoute extends RouteTarget with RouteUnique {}

class CoreViewRoute extends RouteUri {
  @override
  Uri toUri() => Uri.parse('/core');

  @override
  List<Object?> get props => const [];
}

class HomeViewRoute extends ViewRoute {
  HomeViewRoute([this.id = 'home']);

  final String id;

  @override
  Uri toUri() => Uri.parse('/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Text(id);
  }

  @override
  List<Object?> get props => [id];
}

/// Minimal path so layout-only coordinators need not cast to Flutter [Coordinator].
class _SimplePath extends StackPath<ViewRoute>
    with ChangeNotifier, StackMutatable<ViewRoute> {
  _SimplePath({super.coordinator}) : super([]);

  @override
  ViewRoute? get activeRoute => stack.isEmpty ? null : stack.last;

  @override
  PathKey get pathKey => const PathKey('simple');

  @override
  void reset() {
    clear();
  }

  @override
  Future<void> activateRoute(ViewRoute route) => pushSilently(route);
}

class _CoreSimplePath extends StackPath<CoreViewRoute>
    with ChangeNotifier, StackMutatable<CoreViewRoute> {
  _CoreSimplePath({super.coordinator}) : super([]);

  @override
  CoreViewRoute? get activeRoute => stack.lastOrNull;

  @override
  PathKey get pathKey => const PathKey('core-simple');

  @override
  void reset() => clear();

  @override
  Future<void> activateRoute(CoreViewRoute route) => pushSilently(route);
}

mixin _TestListenable {
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}

/// Layout builder only — no [CoordinatorNavigatable].
class LayoutOnlyCoordinator extends CoordinatorCore<ViewRoute>
    with CoordinatorLayoutCore<ViewRoute>, _TestListenable
    implements CoordinatorLayoutBuilder<ViewRoute> {
  late final _SimplePath _root = _SimplePath(coordinator: this);

  @override
  StackPath<ViewRoute> get root => _root;

  @override
  FutureOr<ViewRoute?> parseRouteFromUri(Uri uri) => HomeViewRoute();

  @override
  Widget layoutBuilder(BuildContext context) => const Text('layout-only');
}

class CoreLayoutCoordinator extends CoordinatorCore<CoreViewRoute>
    with
        CoordinatorLayoutCore<CoreViewRoute>,
        CoordinatorNavigatable<CoreViewRoute>,
        _TestListenable
    implements CoordinatorLayoutBuilder<CoreViewRoute> {
  late final _CoreSimplePath _root = _CoreSimplePath(coordinator: this);

  @override
  StackPath<CoreViewRoute> get root => _root;

  @override
  FutureOr<CoreViewRoute?> parseRouteFromUri(Uri uri) => CoreViewRoute();

  @override
  Widget layoutBuilder(BuildContext context) => const Text('core-layout');
}

void main() {
  test('LayoutOnlyCoordinator composes without Navigatable', () {
    final coordinator = LayoutOnlyCoordinator();
    expect(coordinator, isA<CoordinatorLayoutCore>());
    expect(coordinator, isA<CoordinatorLayoutBuilder>());
    expect(coordinator, isNot(isA<CoordinatorNavigatable>()));
    expect(coordinator, isNot(isA<CoordinatorMutatable>()));
    expect(coordinator, isNot(isA<CoordinatorRecoverable>()));
  });

  testWidgets('CoordinatorView accepts RouteUri coordinators', (tester) async {
    final coordinator = CoreLayoutCoordinator();

    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatorView<CoreViewRoute>(
          coordinator: coordinator,
          initialUri: Uri.parse('/core'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('core-layout'), findsOneWidget);
    expect(coordinator.root.activeRoute, isA<CoreViewRoute>());
  });

  testWidgets(
    'defineDeeplinkHandler overrides replace on Flutter Coordinator',
    (tester) async {
      final coordinator = _DeeplinkOverrideCoordinator();
      var overrideCalled = false;
      coordinator.defineDeeplinkHandler(DeeplinkStrategy.replace, (c, route) {
        overrideCalled = true;
        unawaited(c.push(route));
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: coordinator));
      await tester.pumpAndSettle();

      unawaited(coordinator.push(HomeViewRoute('base')));
      await tester.pumpAndSettle();
      final lengthBefore = coordinator.root.stack.length;

      await coordinator.recover(HomeViewRoute('deep'));
      await tester.pumpAndSettle();

      expect(overrideCalled, isTrue);
      expect(coordinator.root.stack.length, greaterThan(lengthBefore));
    },
  );
}

class _DeeplinkOverrideCoordinator extends Coordinator<ViewRoute> {
  @override
  FutureOr<ViewRoute?> parseRouteFromUri(Uri uri) => HomeViewRoute();
}
