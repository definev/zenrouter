import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

/// Route builds receive the host coordinator; navigation from a module may
/// resolve layouts with the module itself. Both locate the same feature here.
M moduleOf<M extends RouteModule<AppRoute>>(CoordinatorCore coordinator) =>
    (coordinator.rootCoordinator as CoordinatorModular<AppRoute>)
        .getModule<M>();
