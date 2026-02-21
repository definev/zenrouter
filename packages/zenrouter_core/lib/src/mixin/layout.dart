import 'package:zenrouter_core/zenrouter_core.dart';

/// Function signature for creating [RouteLayoutParent] instances.
///
/// [CoordinatorCore] uses this to instantiate layout parent widgets on-demand
/// when navigating to routes that belong to a layout.
typedef RouteLayoutParentConstructor<T extends RouteTarget> =
    RouteLayoutParent<T>? Function(Object key);

/// Mixin for routes that act as layout parents (shell routes).
///
/// Layout parents are routes that contain nested [StackPath] instances for managing
/// child routes. When a route has a [parentLayoutKey], the coordinator navigates
/// through the appropriate layout hierarchy, ensuring child routes are placed
/// inside their designated shell.
///
/// ## Role in Navigation Flow
///
/// When [CoordinatorCore] navigates to a route:
///
/// 1. It resolves the route's parent layout via [RouteLayoutChild.resolveParentLayout]
/// 2. If the parent layout is already active, it uses that instance
/// 3. If not, it creates a new instance using the constructor registered via
///    [CoordinatorCore.defineLayoutParentConstructor]
/// 4. The route is then pushed onto the [StackPath] returned by [resolvePath]
///
/// Layout parents maintain their own navigation state, allowing independent
/// navigation stacks within each shell (e.g., each tab in a tab bar).
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

/// Mixin for routes that belong to a parent layout.
///
/// Routes with this mixin can specify a [parentLayoutKey] to indicate which
/// [RouteLayoutParent] should contain them. This creates a parent-child
/// relationship between routes, enabling nested navigation stacks.
///
/// ## Role in Navigation Flow
///
/// 1. When navigating to a route, [CoordinatorCore] checks [parentLayoutKey]
/// 2. It resolves or creates the parent layout via [resolveParentLayout]
/// 3. The route is pushed onto the [StackPath] provided by that layout
/// 4. When the route pops, the layout's stack is reset via [RouteLayoutParent.onDidPop]
///
/// This mixin is automatically included in [RouteUri], so most routes
/// inherently support parent layouts without explicitly mixing this in.
mixin RouteLayoutChild on RouteTarget {
  static _ProxyRouteLayoutChild proxy(RouteLayoutChild host) =>
      _ProxyRouteLayoutChild(host);

  Object? get parentLayoutKey;

  /// Creates a new [RouteLayoutParent] instance for this route.
  ///
  /// This is a low-level method that directly instantiates the parent layout
  /// using the coordinator's registered constructor. Used internally when
  /// no existing layout instance can be reused.
  ///
  /// Returns `null` if [parentLayoutKey] is not set.
  RouteLayoutParent? createParentLayout(covariant CoordinatorCore coordinator) {
    if (parentLayoutKey == null) return null;
    return coordinator.createLayoutParent(parentLayoutKey!);
  }

  /// Resolves the active or creates a new [RouteLayoutParent] for this route.
  ///
  /// This is the primary method for finding where a route belongs in the
  /// navigation hierarchy. It checks the coordinator's currently active
  /// layouts first, returning an existing instance if found. If no matching
  /// layout exists, it creates a new one via [createParentLayout].
  ///
  /// Returns `null` if [parentLayoutKey] is not set.
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
