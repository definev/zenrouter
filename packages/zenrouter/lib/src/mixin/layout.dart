import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// Mixin for routes that define a layout structure.
///
/// A layout is a route that wraps other routes, such as a shell or a tab bar.
/// It defines how its children are displayed and managed.
mixin RouteLayout<T extends RouteIdentity> on RouteUnique
    implements RoutePath<T> {
  /// Registers a custom layout constructor.
  ///
  /// Use this to define how a specific layout type should be instantiated.
  static void defineLayout<T extends RouteLayout>(
    Type layout,
    T Function() constructor,
  ) {
    RoutePath.defineRoutePath(layout, constructor);
    final layoutInstance = constructor();
    layoutInstance.completeOnResult(null, null, true);
    RouteLayout._reflectionLayoutType[layoutInstance.runtimeType.toString()] =
        layoutInstance.runtimeType;
  }

  static final Map<String, Type> _reflectionLayoutType = {};
  static RouteLayout deserialize(Map<String, dynamic> value) {
    final type = _reflectionLayoutType[value['value'] as String];
    if (type == null) {
      throw UnimplementedError(
        'The [${value['value']}] layout isn\'t defined. You must define it using RouteLayout.defineLayout',
      );
    }
    return RoutePath.routePathConstructorTable[type]!() as RouteLayout;
  }

  /// Table of registered layout builders.
  ///
  /// This maps layout identifiers to their widget builder functions.
  static final Map<PathKey, RouteLayoutBuilder> _layoutBuilderTable = {
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
                DefaultTransitionStrategy.cupertino =>
                  StackTransition.cupertino(
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
    IndexedStackPath.key: (coordinator, path, layout, [restorationId]) =>
        ListenableBuilder(
          listenable: path as Listenable,
          builder: (context, child) {
            final indexedStackPath = path as IndexedStackPath<RouteUnique>;
            return IndexedStackPathBuilder(
              path: indexedStackPath,
              coordinator: coordinator,
              restorationId: restorationId,
            );
          },
        ),
  };

  static Widget buildRoot(Coordinator coordinator) {
    final rootPathKey = coordinator.root.pathKey;

    if (!_layoutBuilderTable.containsKey(rootPathKey)) {
      // coverage:ignore-start
      throw UnimplementedError(
        'No layout builder provided for [${rootPathKey.key}]. If you extend the [StackPath] class, you must register it via [RouteLayout.definePath] to use [RouteLayout.buildRoot].',
      );
      // coverage:ignore-end
    }

    return _layoutBuilderTable[rootPathKey]!(
      coordinator,
      coordinator.root,
      null,
    );
  }

  /// Build the layout for this route.
  Widget buildPath(covariant Coordinator coordinator) {
    final path = resolvePath(coordinator);

    if (!_layoutBuilderTable.containsKey(path.pathKey)) {
      throw UnimplementedError(
        'No layout builder provided for [${path.pathKey.key}]. If you extend the [StackPath] class, you must register it via [RouteLayout.definePath] to use [RouteLayout.buildPath].',
      );
    }
    return _layoutBuilderTable[path.pathKey]!(coordinator, path, this);
  }

  // coverage:ignore-start
  /// Registers a custom layout builder.
  ///
  /// Use this to define how a specific layout type should be built.
  static void definePath(PathKey key, RouteLayoutBuilder builder) =>
      _layoutBuilderTable[key] = builder;
  // coverage:ignore-end

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) =>
      buildPath(coordinator);

  Map<String, dynamic> serialize() => {
    'type': 'layout',
    'value': runtimeType.toString(),
  };

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  @override
  StackPath<RouteUnique> resolvePath(covariant CoordinatorCore coordinator);

  @override
  Object get routePathKey => runtimeType;

  /// RouteLayout does not use a URI.
  @override
  Uri toUri() => Uri(pathSegments: ['__layout', routePathKey.toString()]);

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    super.onDidPop(result, coordinator);
    assert(
      coordinator != null,
      '[RoutePath] must be used with a [Coordinator]',
    );
    resolvePath(coordinator!).reset();
  }

  @override
  operator ==(Object other) =>
      other is RoutePath && other.routePathKey == routePathKey;

  @override
  int get hashCode => routePathKey.hashCode;
}

extension RouteLayoutBinding<T extends RouteUnique> on StackPath<T> {
  void bindLayout(RouteLayoutConstructor constructor) =>
      bindRoutePath(constructor);
}
