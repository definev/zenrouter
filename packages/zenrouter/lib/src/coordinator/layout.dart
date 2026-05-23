import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// Ensures [coordinatorCore] is a Flutter [Coordinator] for default path builders.
///
/// [NavigationPath] and [IndexedStackPath] defaults use [NavigationStack],
/// restoration IDs, and transitions that require [Coordinator]. Throws an
/// [AssertionError] in debug when [coordinatorCore] is another [CoordinatorCore]
/// implementation — register a custom builder via
/// [CoordinatorLayout.defineLayoutBuilder] instead.
Coordinator requireFlutterCoordinator(
  CoordinatorCore coordinatorCore, {
  required PathKey pathKey,
}) {
  assert(
    coordinatorCore is Coordinator,
    'The default layout builder for "${pathKey.key}" requires a zenrouter '
    'Coordinator (extend Coordinator<YourRoute>), but received '
    '${coordinatorCore.runtimeType}. '
    'NavigationPath and IndexedStackPath use NavigationStack and need '
    'Coordinator.routerDelegate, CoordinatorRestoration, and transition '
    'strategy. Either extend Coordinator or call defineLayoutBuilder('
    '${pathKey.key}, ...) with a builder that supports your coordinator type. '
    'See packages/zenrouter/doc/guides/route-layout.md#default-layout-builders-require-coordinator.',
  );
  return coordinatorCore as Coordinator;
}

/// Built-in layout builders for [NavigationPath] and [IndexedStackPath].
///
/// Both entries call [requireFlutterCoordinator] — they are not valid for a
/// bare [CoordinatorCore] that is not a [Coordinator].
final kDefaultLayoutBuilderTable = Map.unmodifiable(<
  PathKey,
  RouteLayoutBuilder
>{
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
      navigatorKey: layout == null
          ? coordinator.routerDelegate.navigatorKey
          : null,
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
});

/// Mixin that provides layout builder and parent constructor management for [Coordinator].
///
/// ## Role in Navigation Flow
///
/// [CoordinatorLayout] enables the coordinator to:
/// 1. Register layout builders that render [StackPath] contents
/// 2. Create layout parent instances for nested navigation
/// 3. Bind routes to their appropriate layout containers
///
/// When a route is pushed:
/// 1. [Coordinator] resolves the route's parent layout
/// 2. [createLayoutParent] instantiates the layout if needed
/// 3. [getLayoutBuilder] provides the widget that renders the path's stack
///
/// This mixin is automatically applied to [Coordinator] and handles:
/// - [defineLayoutBuilder]: Register layout builders for different path types
/// - [defineLayoutParentConstructor]: Register constructors for layout parents
/// - [getLayoutBuilder]: Retrieve the builder for a specific [PathKey]
/// - [getLayoutParentConstructor]: Retrieve the constructor for a layout key
///
/// Layout builders control how [StackPath]s render their pages:
/// - [NavigationPath]: Uses [NavigationStack] widget
/// - [IndexedStackPath]: Uses [IndexedStackPathBuilder] widget
///
/// Default builders are provided via the top-level [kDefaultLayoutBuilderTable].
mixin CoordinatorLayout<T extends RouteUnique> on CoordinatorCore<T>
    implements CoordinatorLayoutBuilder<T> {
  final _layoutParentConstructorTable =
      <Object, RouteLayoutParentConstructor>{};
  late final layoutParentConstructorTable = isRouteModule
      ? (coordinator as CoordinatorLayout)._layoutParentConstructorTable
      : _layoutParentConstructorTable;
  late final _layoutBuilderTable = switch (isRouteModule) {
    true => <PathKey, RouteLayoutBuilder>{},
    false => <PathKey, RouteLayoutBuilder>{...kDefaultLayoutBuilderTable},
  };
  late final layoutBuilderTable = isRouteModule
      ? (coordinator as CoordinatorLayout)._layoutBuilderTable
      : _layoutBuilderTable;

  /// Registers a constructor function for a layout parent identified by [layoutKey].
  ///
  /// The constructor is called by [createLayoutParent] to instantiate layout
  /// parent widgets (e.g., shell routes with nested navigation).
  ///
  /// [layoutKey]: Unique identifier for the layout (typically the layout class itself)
  /// [constructor]: Function that returns a new [RouteLayoutParent] instance
  @override
  void defineLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  ) => layoutParentConstructorTable[layoutKey] = constructor;

  /// Retrieves the constructor function for a layout parent identified by [layoutKey].
  ///
  /// Returns `null` if no constructor was registered for the given [layoutKey].
  RouteLayoutParentConstructor? getLayoutParentConstructor(Object layoutKey) =>
      layoutParentConstructorTable[layoutKey];

  /// Creates a new layout parent instance using the registered constructor.
  ///
  /// Calls the constructor registered via [defineLayoutParentConstructor] for
  /// the given [layoutKey]. Returns `null` if no constructor was registered.
  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) =>
      layoutParentConstructorTable[layoutKey]?.call(layoutKey);

  /// Registers a layout builder for a specific [PathKey].
  ///
  /// Layout builders determine how a [StackPath] renders its pages. Common builders:
  /// - [NavigationPath.key]: Renders pages using [NavigationStack]
  /// - [IndexedStackPath.key]: Renders pages using [IndexedStackPathBuilder]
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
    _layoutParentConstructorTable.clear();
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
