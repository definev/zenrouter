import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

typedef GetLayoutKeyCallback = Object? Function(String key);

/// Mixin for routes that define a layout structure.
///
/// A layout is a route that wraps other routes, such as a shell or a tab bar.
/// It defines how its children are displayed and managed.
mixin RouteLayout<T extends RouteUnique> on RouteUnique
    implements RouteLayoutParent<T> {
  // coverage:ignore-start
  @Deprecated(
    'Use `coordinator.defineRouteLayout` insteads\n'
    'If you want to use this method, you must provide a [Coordinator] instance to the [RouteLayout.defineLayout] method.\n'
    'Example: `OLD: RouteLayout.defineLayout(ShopLayout, ShopLayout.new);`\n'
    '         `NEW: RouteLayout.defineLayout(this, ShopLayout, ShopLayout.new);`',
  )
  static void defineLayout<T extends RouteLayout>(
    Coordinator coordinator,
    Object layoutKey,
    T Function() constructor,
  ) => coordinator.defineRouteLayout(layoutKey, () => constructor());
  // coverage:ignore-end

  /// Route restoration reflection table.
  static RouteLayout deserialize(
    RouteLayoutParentConstructor resolveRouteLayoutParent,
    GetLayoutKeyCallback layoutKeyLookup,
    Map<String, dynamic> value,
  ) {
    final key = value['value'] as String;
    final layoutKey = layoutKeyLookup(key);
    if (layoutKey == null) {
      throw UnimplementedError(
        'The [$key] layout isn\'t defined. You must define it using RouteLayout.defineLayout',
      );
    }
    return resolveRouteLayoutParent(layoutKey) as RouteLayout;
  }

  static Widget buildRoot(Coordinator coordinator) {
    final rootPathKey = coordinator.root.pathKey;

    final routeLayoutBuilder = coordinator.getLayoutBuilder(rootPathKey);
    // coverage:ignore-start
    if (routeLayoutBuilder == null) {
      throw UnimplementedError(
        'No layout builder provided for [${rootPathKey.key}]. If you extend the [StackPath] class, you must register it via [RouteLayout.definePath] to use [RouteLayout.buildRoot].',
      );
    }
    // coverage:ignore-end

    return routeLayoutBuilder(coordinator, coordinator.root, null);
  }

  /// Build the layout for this route.
  Widget buildPath(covariant Coordinator coordinator) {
    final path = resolvePath(coordinator);

    final routeLayoutBuilder = coordinator.getLayoutBuilder(path.pathKey);
    if (routeLayoutBuilder == null) {
      throw UnimplementedError(
        'No layout builder provided for [${path.pathKey.key}]. If you extend the [StackPath] class, you must register it via [RouteLayout.definePath] to use [RouteLayout.buildPath].',
      );
    }

    return routeLayoutBuilder(coordinator, path, this);
  }

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      buildPath(coordinator as Coordinator);

  Map<String, dynamic> serialize() => {
    'type': 'layout',
    'value': layoutKey.toString(),
  };

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  @override
  StackPath<RouteUnique> resolvePath(covariant CoordinatorCore coordinator);

  @override
  Object get layoutKey => runtimeType;

  /// RouteLayout does not use a URI.
  @override
  Uri toUri() => Uri(pathSegments: ['__layout', layoutKey.toString()]);

  late final _proxy = RouteLayoutParent.proxy(this);

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    super.onDidPop(result, coordinator);
    _proxy.onDidPop(result, coordinator);
  }

  @override
  RouteLayoutParent<RouteTarget>? createParentLayout(coordinator) =>
      _proxy.createParentLayout(coordinator);

  @override
  RouteLayoutParent<RouteTarget>? resolveParentLayout(coordinator) =>
      _proxy.resolveParentLayout(coordinator);

  @override
  bool matchedLayoutKey(coordinator, other) =>
      _proxy.matchedLayoutKey(coordinator, other);

  @override
  operator ==(Object other) => _proxy.compareLayout(this, other);

  @override
  int get hashCode => _proxy.resolveHashCode(this);
}

extension RouteLayoutBinding<T extends RouteUnique> on StackPath<T> {
  void bindLayout(RouteLayoutConstructor constructor) {
    final instance = constructor()..onDiscard();
    (coordinator as Coordinator).defineRouteLayout(
      instance.layoutKey,
      () => constructor(),
    );
  }
}
