import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import '../app_route.dart';
import '../demo_widgets.dart';
import '../playground_layout.dart';
import 'counter_demo.dart';
import 'selection_demo.dart';

/// A regular coordinator used as a RouteModule. It owns its parser and tabs;
/// its root and navigation transactions belong to the parent coordinator.
class ControlsCoordinator extends Coordinator<AppRoute> {
  ControlsCoordinator(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  late final tabs = IndexedStackPath<AppRoute>.createWith(
    [CounterRoute(), SelectionRoute()],
    coordinator: this,
    label: 'controls-tabs',
  )..bindLayout(ControlsLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, tabs];

  @override
  AppRoute? parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['controls'] || ['controls', 'counter'] => CounterRoute(),
    ['controls', 'selection'] => SelectionRoute(),
    _ => null,
  };
}

class ControlsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type get layout => PlaygroundLayout;

  @override
  IndexedStackPath<AppRoute> resolvePath(Coordinator<AppRoute> coordinator) =>
      moduleOf<ControlsCoordinator>(coordinator).tabs;

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      FeatureTabs(
        coordinator: moduleOf<ControlsCoordinator>(coordinator),
        path: resolvePath(coordinator),
        labels: const ['Counter', 'Selection'],
      );
}

class CounterRoute extends AppRoute {
  @override
  Type get layout => ControlsLayout;

  @override
  Uri toUri() => Uri(path: '/controls/counter');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      CounterDemo(coordinator: moduleOf<ControlsCoordinator>(coordinator));
}

class SelectionRoute extends AppRoute {
  @override
  Type get layout => ControlsLayout;

  @override
  Uri toUri() => Uri(path: '/controls/selection');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      const SelectionDemo();
}
