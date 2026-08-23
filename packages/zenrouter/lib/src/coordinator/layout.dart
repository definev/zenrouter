part of 'base.dart';

/// Ensures [coordinatorCore] is a Flutter [Coordinator] for default path builders.
///
/// [NavigationPath], [IndexedStackPath], and [BranchedStackPath] defaults use
/// [NavigationStack] or [IndexedStackPathBuilder],
/// restoration IDs, and transitions that require [Coordinator]. Throws an
/// [AssertionError] in debug when [coordinatorCore] is another [CoordinatorCore]
/// implementation — register a custom builder via
/// [CoordinatorLayout.defineLayoutBuilder] instead.
@visibleForTesting
@protected
Coordinator requireFlutterCoordinator(
  CoordinatorCore coordinatorCore, {
  required PathKey pathKey,
}) {
  assert(
    coordinatorCore is Coordinator,
    'The default layout builder for "${pathKey.key}" requires a zenrouter '
    'Coordinator (extend Coordinator<YourRoute>), but received '
    '${coordinatorCore.runtimeType}. '
    'NavigationPath, IndexedStackPath, and BranchedStackPath use Flutter '
    'navigation widgets and need '
    'Coordinator.routerDelegate, CoordinatorRestoration, and transition '
    'strategy. Either extend Coordinator or call defineLayoutBuilder('
    '${pathKey.key}, ...) with a builder that supports your coordinator type. '
    'See packages/zenrouter/doc/guides/route-layout.md#default-layout-builders-require-coordinator.',
  );
  return coordinatorCore as Coordinator;
}

/// Built-in layout builders for [NavigationPath], [IndexedStackPath], and
/// [BranchedStackPath].
///
/// All entries call [requireFlutterCoordinator] — they are not valid for a
/// bare [CoordinatorCore] that is not a [Coordinator].
final Map<PathKey, RouteLayoutBuilder>
kDefaultLayoutBuilderTable = Map.unmodifiable(<PathKey, RouteLayoutBuilder>{
  NavigationPath.key: (coordinatorCore, path, layout) {
    final coordinator = requireFlutterCoordinator(
      coordinatorCore,
      pathKey: NavigationPath.key,
    );

    final restorationId = switch (layout) {
      RouteUnique route => coordinator.resolveRouteId(route),
      _ => coordinator.rootRestorationId,
    };

    return NavigationStack(
      path: path as NavigationPath<RouteUnique>,
      navigatorKey: coordinator.routerDelegate.navigatorKeyFor(path),
      coordinator: coordinator,
      restorationId: restorationId,
      resolver: (route) {
        switch (route) {
          case RouteTransition():
            return route.transition(coordinator);
          default:
            final routeRestorationId = coordinator.resolveRouteId(route);
            final builder = Builder(
              builder: (context) => route.build(coordinator, context),
            );
            return switch (coordinator.transitionStrategy) {
              DefaultTransitionStrategy.material => StackTransition.material(
                builder,
                restorationId: routeRestorationId,
              ),
              DefaultTransitionStrategy.cupertino => StackTransition.cupertino(
                builder,
                restorationId: routeRestorationId,
              ),
              DefaultTransitionStrategy.none => StackTransition.none(
                builder,
                restorationId: routeRestorationId,
              ),
            };
        }
      },
    );
  },
  IndexedStackPath.key: (coordinatorCore, path, layout, [restorationId]) {
    final coordinator = requireFlutterCoordinator(
      coordinatorCore,
      pathKey: IndexedStackPath.key,
    );
    return ListenableBuilder(
      listenable: path as Listenable,
      builder: (context, child) {
        final indexedStackPath = path as IndexedStackPath<RouteUnique>;
        return IndexedStackPathBuilder(
          path: indexedStackPath,
          coordinator: coordinator,
          restorationId: restorationId,
        );
      },
    );
  },
  BranchedStackPath.key: (coordinatorCore, path, layout, [restorationId]) {
    final coordinator = requireFlutterCoordinator(
      coordinatorCore,
      pathKey: BranchedStackPath.key,
    );
    return ListenableBuilder(
      listenable: path as Listenable,
      builder: (context, child) {
        final branchedPath = path as BranchedStackPath<RouteUnique>;
        return IndexedStackPathBuilder(
          path: branchedPath,
          coordinator: coordinator,
          restorationId: restorationId,
        );
      },
    );
  },
});

/// Mixin that provides Flutter layout builders for [Coordinator].
///
/// Layout-parent registration and hierarchy activation live in
/// [CoordinatorLayoutCore] (`zenrouter_core`). This mixin only owns the
/// widget builder table used by [NavigationStack] / [IndexedStackPathBuilder].
mixin CoordinatorLayout<T extends RouteUnique> on CoordinatorLayoutCore<T>
    implements CoordinatorLayoutBuilder<T> {
  late final Map<PathKey, RouteLayoutBuilder> _layoutBuilderTable =
      switch (isRouteModule) {
        true => <PathKey, RouteLayoutBuilder>{},
        false => <PathKey, RouteLayoutBuilder>{...kDefaultLayoutBuilderTable},
      };
  late final Map<PathKey, RouteLayoutBuilder> layoutBuilderTable = isRouteModule
      ? (coordinator as CoordinatorLayout)._layoutBuilderTable
      : _layoutBuilderTable;

  /// Registers a layout builder for a specific [PathKey].
  ///
  /// Layout builders determine how a [StackPath] renders its pages. Common builders:
  /// - [NavigationPath.key]: Renders pages using [NavigationStack]
  /// - [IndexedStackPath.key]: Renders pages using [IndexedStackPathBuilder]
  /// - [BranchedStackPath.key]: Retains every branch with
  ///   [IndexedStackPathBuilder]
  ///
  /// The first argument is [CoordinatorCore]. Built-in defaults from
  /// [kDefaultLayoutBuilderTable] require a Flutter [Coordinator]; passing
  /// another [CoordinatorCore] subtype triggers an [assert] in debug mode.
  /// Register a custom [builder] for custom coordinator types.
  ///
  /// Override default builders to customize page rendering behavior.
  void defineLayoutBuilder(PathKey key, RouteLayoutBuilder builder) =>
      layoutBuilderTable[key] = builder;

  /// Retrieves the layout builder registered for a specific [PathKey].
  ///
  /// Returns `null` if no builder was registered for the given [key].
  RouteLayoutBuilder? getLayoutBuilder(PathKey key) => layoutBuilderTable[key];

  @override
  void dispose() {
    _layoutBuilderTable.clear();
    super.dispose();
  }

  /// Builds the root widget (the primary navigator).
  ///
  /// ## When to Override
  /// Override to customize the root navigation structure.
  ///
  /// ## Relationship
  /// Called by [CoordinatorRouterDelegate.build] to create the widget tree.
  /// Delegates to [RouteLayout.buildRoot] by default.
  @override
  Widget layoutBuilder(BuildContext context) => RouteLayout.buildRoot(this);
}

mixin CoordinatorLayoutBuilder<T extends RouteUri> on CoordinatorCore<T> {
  /// Builds the root widget (the primary navigator).
  ///
  /// ## When to Override
  /// Override to customize the root navigation structure.
  ///
  /// ## Relationship
  /// Called by [CoordinatorRouterDelegate.build] to create the widget tree.
  /// Delegates to [RouteLayout.buildRoot] by default.
  Widget layoutBuilder(BuildContext context);
}
