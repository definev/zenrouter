import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox();
  }

  @override
  List<Object?> get props => [];
}

class LeafRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/leaf');
}

class LeafModule extends RouteModule<AppRoute> {
  LeafModule(super.coordinator);

  int layoutCount = 0;
  int converterCount = 0;

  @override
  void defineLayout() {
    layoutCount++;
    super.defineLayout();
  }

  @override
  void defineConverter() {
    converterCount++;
    super.defineConverter();
  }

  late final NavigationPath<AppRoute> leafPath = NavigationPath.createWith(
    label: 'leaf',
    coordinator: coordinator as Coordinator<AppRoute>,
  );

  @override
  List<StackPath> get paths => [leafPath];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    if (uri.path == '/leaf') return LeafRoute();
    return null;
  }
}

class SubCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  SubCoordinator(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {LeafModule(this)};

  @override
  AppRoute notFoundRoute(Uri uri) => throw UnimplementedError();
}

class RootCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {SubCoordinator(this)};

  @override
  AppRoute notFoundRoute(Uri uri) => throw UnimplementedError();
}

void main() {
  test('Nested CoordinatorModular double inclusion/execution', () {
    final root = RootCoordinator();

    final leaf = root.getModule<LeafModule>();

    final paths = root.paths;
    final leafPaths = paths.where((p) => p == leaf.leafPath).toList();

    expect(paths.length, 2);
    expect(
      leafPaths.length,
      1,
      reason: 'Leaf path was included multiple times in root paths',
    );
    expect(
      leaf.layoutCount,
      1,
      reason: 'defineLayout was called multiple times on leaf module',
    );
    expect(
      leaf.converterCount,
      1,
      reason: 'defineConverter was called multiple times on leaf module',
    );
  });
}
