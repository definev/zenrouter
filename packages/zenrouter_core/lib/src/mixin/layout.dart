import 'package:zenrouter_core/zenrouter_core.dart';

typedef RouteLayoutParentConstructor<T extends RouteTarget> =
    RouteLayoutParent<T>? Function(Object key);

mixin RouteLayoutParent<T extends RouteTarget> on RouteLayoutChild {
  static _ProxyRouteLayoutParent proxy(RouteLayoutParent host) =>
      _ProxyRouteLayoutParent(host)..onDiscard();

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  StackPath<RouteIdentity> resolvePath(covariant CoordinatorCore coordinator);

  /// The lookup key for this layout.
  ///
  /// It's used to help [CoordinatorCore] find the correct [RouteLayoutParent] constructor
  /// to create a new [RouteLayoutParent] instance.
  Object get layoutKey;

  bool matchedLayoutKey(covariant CoordinatorCore coordinator, Object other) =>
      layoutKey == other;

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
      other is RouteLayoutParent && other.layoutKey == layoutKey;

  @override
  int get hashCode => layoutKey.hashCode;
}

class _ProxyRouteLayoutParent extends RouteTarget
    with RouteLayoutChild, RouteLayoutParent<RouteTarget> {
  _ProxyRouteLayoutParent(this.host);

  final RouteLayoutParent host;

  @override
  Object get layoutKey => host.layoutKey;

  @override
  Object? get parentLayoutKey => host.parentLayoutKey;

  @override
  StackPath<RouteIdentity> resolvePath(coordinator) =>
      host.resolvePath(coordinator);

  @override
  // ignore: must_call_super
  void onDidPop(
    Object? result,
    covariant CoordinatorCore<RouteIdentity>? coordinator,
  ) {
    assert(
      coordinator != null,
      '[RoutePath] must be used with a [CoordinatorCore]',
    );
    resolvePath(coordinator!).reset();
  }

  bool compareLayout(RouteLayoutParent self, Object other) =>
      identical(self, other) ||
      (other is RouteLayoutParent && other.layoutKey == self.layoutKey);

  int resolveHashCode(RouteLayoutParent self) => self.layoutKey.hashCode;

  @override
  Type get runtimeType => host.runtimeType;
}

mixin RouteLayoutChild on RouteTarget {
  static _ProxyRouteLayoutChild proxy(RouteLayoutChild host) =>
      _ProxyRouteLayoutChild(host)..onDiscard();

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

    final constructor = coordinator.resolveRouteLayoutParent(parentLayoutKey!);
    if (constructor == null) {
      throw UnimplementedError(
        'Missing constructor for [${this.runtimeType}] layout.'
        'You must define constructor for this layout by calling [RouteLayout.defineLayout] or if you use custom `layoutKey` '
        'you must call [RouteLayout.defineLayoutWithKey] to define constructor for this layout.'
        'by calling [RouteLayout.defineLayout] in [defineLayout] function at [${coordinator.runtimeType}]',
      );
    }
    return constructor;
  }

  /// {@template zenrouter_core.RouteLayoutChild.resolveParentLayout}
  /// Resolve a [RouteLayoutParent] instance in [CoordinatorCore] of this [RouteLayoutChild].
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
    final parentLayoutList = coordinator.activeRouteLayoutList;

    // Find existing layout or create new one
    RouteLayoutParent? resolvedParentLayout;
    for (var i = parentLayoutList.length - 1; i >= 0; i -= 1) {
      final parentLayout = parentLayoutList[i];
      if (parentLayout.matchedLayoutKey(coordinator, parentLayoutKey!)) {
        resolvedParentLayout = parentLayout;
        break;
      }
    }

    return resolvedParentLayout ??= createParentLayout(coordinator);
  }
}

class _ProxyRouteLayoutChild extends RouteTarget with RouteLayoutChild {
  _ProxyRouteLayoutChild(this.host);

  final RouteLayoutChild host;

  @override
  Object? get parentLayoutKey => host.parentLayoutKey;

  @override
  Type get runtimeType => host.runtimeType;
}
