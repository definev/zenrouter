import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

final kDefaultLayoutBuilderTable = Map.unmodifiable(<
  PathKey,
  RouteLayoutBuilder
>{
  NavigationPath.key: (coordinator, path, layout) {
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
  IndexedStackPath.key: (coordinator, path, layout, [restorationId]) {
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

mixin CoordinatorLayout<T extends RouteUnique> on CoordinatorCore<T> {
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

  @override
  void defineLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  ) => layoutParentConstructorTable[layoutKey] = constructor;

  RouteLayoutParentConstructor? getLayoutParentConstructor(Object layoutKey) =>
      layoutParentConstructorTable[layoutKey];

  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) =>
      layoutParentConstructorTable[layoutKey]?.call(layoutKey);

  void defineLayoutBuilder(PathKey key, RouteLayoutBuilder builder) =>
      layoutBuilderTable[key] = builder;

  RouteLayoutBuilder? getLayoutBuilder(PathKey key) => layoutBuilderTable[key];

  @override
  void dispose() {
    _layoutParentConstructorTable.clear();
    _layoutBuilderTable.clear();
    super.dispose();
  }
}
