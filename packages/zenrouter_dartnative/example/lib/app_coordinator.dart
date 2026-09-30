import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import 'app_route.dart';
import 'controls/controls_coordinator.dart';
import 'gallery/gallery_coordinator.dart';
import 'navigation_demo.dart';
import 'playground_layout.dart';

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  AppCoordinator() : super(initialRoute: HomeRoute());

  late final sections = BranchedStackPath<AppRoute>.createWith(
    [ControlsLayout(), GalleryLayout()],
    coordinator: this,
    label: 'playground-sections',
  )..bindLayout(PlaygroundLayout.new);

  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [
    ControlsCoordinator(this),
    GalleryCoordinator(this),
  ];

  @override
  List<StackPath> get paths => [...super.paths, sections];

  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async =>
      switch (uri.pathSegments) {
        [] => CounterRoute(),
        ['navigation'] => HomeRoute(),
        ['details', final id] => DetailRoute(id),
        ['editor'] => EditorRoute(),
        ['sheet'] => SheetRoute(),
        _ => await super.parseRouteFromUri(uri),
      };

  @override
  AppRoute notFoundRoute(Uri uri) => MissingRoute(uri);
}
