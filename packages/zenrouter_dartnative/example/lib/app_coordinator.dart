import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import 'app_route.dart';

/// Coordinates the cupping studio: a persistent shelf, pushed tastings, and
/// a barista module that owns its own routes.
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  AppCoordinator() : super(initialRoute: StudioLayoutRoute());

  late final IndexedStackPath<AppRoute> tabs =
      IndexedStackPath<AppRoute>.createWith(
        [ShelfRoute(), LogbookRoute()],
        coordinator: this,
        label: 'studio-tabs',
      )..bindLayout(StudioLayoutRoute.new);

  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [BaristaCoordinator(this)];

  @override
  List<StackPath> get paths => [...super.paths, tabs];

  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async =>
      switch (uri.pathSegments) {
        [] || ['shelf'] => ShelfRoute(),
        ['logbook'] => LogbookRoute(),
        ['lot', final id] => LotRoute(id),
        ['cupping'] => CuppingRoute(lotId: uri.queryParameters['lot']),
        ['brew'] => BrewGuideRoute(
          lotId: uri.queryParameters['lot'] ?? 'yirga',
        ),
        _ => await super.parseRouteFromUri(uri),
      };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
}
