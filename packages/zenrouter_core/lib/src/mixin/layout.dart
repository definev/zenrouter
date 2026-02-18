import 'package:zenrouter_core/zenrouter_core.dart';

typedef RouteLayoutParentConstructor<T extends RouteTarget> =
    RouteLayoutParent<T>? Function(Object key);

mixin RouteLayoutParent<T extends RouteTarget> on RouteLayoutChild {
  static _ProxyRouteLayoutParent proxy(RouteLayoutParent host) =>
      _ProxyRouteLayoutParent(host);

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  StackPath resolvePath(covariant CoordinatorCore coordinator);

  /// The lookup key for this layout.
  ///
  /// It's used to help [CoordinatorCore] find the correct [RouteLayoutParent] constructor
  /// to create a new [RouteLayoutParent] instance.
  Object get layoutKey;

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    super.onDidPop(result, coordinator);
    assert(
      coordinator != null,
      '[RoutePath] must be used with a [CoordinatorCore]',
    );
    resolvePath(coordinator!).reset();
  }

  @override
  operator ==(Object other) =>
      other is RouteLayoutParent &&
      other.layoutKey == layoutKey &&
      other.parentLayoutKey == parentLayoutKey;

  @override
  int get hashCode => layoutKey.hashCode ^ parentLayoutKey.hashCode;
}

class _ProxyRouteLayoutParent extends RouteTarget
    with RouteLayoutChild, RouteLayoutParent<RouteTarget> {
  _ProxyRouteLayoutParent(this.host) {
    onDiscard();
  }

  final RouteLayoutParent host;

  @override
  Object get layoutKey => host.layoutKey;

  @override
  Object? get parentLayoutKey => host.parentLayoutKey;

  @override
  StackPath resolvePath(coordinator) => host.resolvePath(coordinator);

  operator ==(Object other) => identical(host, other) || super == other;
}

mixin RouteLayoutChild on RouteTarget {
  static _ProxyRouteLayoutChild proxy(RouteLayoutChild host) =>
      _ProxyRouteLayoutChild(host);

  Object? get parentLayoutKey;

  /// {@template zenrouter_core.RouteLayoutChild.createParentLayout}
  /// Create a [RouteLayoutParent] instance of this [RouteLayoutChild].
  ///
  /// The [RouteLayoutParent] will be created by looking up the constructor
  /// in [RouteLayoutParent.routePathConstructorTable].
  ///
  /// This method shouldn't call manually unless you know what you're doing.
  /// Use [resolveParentLayout] for maximum reuse layout in [CoordinatorCore].
  ///
  /// If the constructor is not found, an [UnimplementedError] is thrown.
  /// {@endtemplate}
  RouteLayoutParent? createParentLayout(covariant CoordinatorCore coordinator) {
    if (parentLayoutKey == null) return null;
    return coordinator.createLayoutParent(parentLayoutKey!);
  }

  /// {@template zenrouter_core.RouteLayoutChild.resolveParentLayout}
  /// Resolve [RouteLayoutParent] for this [RouteLayoutChild] in [coordinator].
  ///
  /// If the [parentLayoutKey] is null, it will return null.
  ///
  /// If the [RouteLayoutParent] is not found, it will create a new one using
  /// [createParentLayout].
  ///
  /// {@endtemplate}
  RouteLayoutParent? resolveParentLayout(
    covariant CoordinatorCore coordinator,
  ) {
    if (parentLayoutKey == null) return null;

    // ignore: invalid_use_of_protected_member
    final routeParentLayoutList = coordinator.activeLayoutParentList;

    // Find existing layout or create new one
    RouteLayoutParent? resolvedParentLayout;
    for (var index = routeParentLayoutList.length - 1; index >= 0; index -= 1) {
      final parentLayout = routeParentLayoutList[index];
      if (parentLayout.layoutKey == parentLayoutKey) {
        resolvedParentLayout = parentLayout;
        break;
      }
    }

    return resolvedParentLayout ??= createParentLayout(coordinator);
  }
}

class _ProxyRouteLayoutChild extends RouteTarget with RouteLayoutChild {
  _ProxyRouteLayoutChild(this.host) {
    onDiscard();
  }

  final RouteLayoutChild host;

  @override
  Object? get parentLayoutKey => host.parentLayoutKey;
}
