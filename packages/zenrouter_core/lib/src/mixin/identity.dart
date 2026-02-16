import 'package:zenrouter_core/zenrouter_core.dart';

/// [RouteIdentity] give [RouteTarget] an [Uri] an a layout aware.
///
/// [RouteIdentity] useful for [CoordinatorCore] pattern
mixin RouteIdentity on RouteTarget implements RouteLayoutChild {
  /// Return a [Uri] that represents this route.
  Uri toUri();

  /// [RouteLayoutChild] proxy.
  late final _proxy = RouteLayoutChild.proxy(this);

  /// {@macro zenrouter_core.RouteLayoutChild.createParentLayout}
  @override
  RouteLayoutParent<RouteTarget>? createParentLayout(coordinator) =>
      _proxy.createParentLayout(coordinator);

  /// {@macro zenrouter_core.RouteLayoutChild.resolveParentLayout}
  @override
  RouteLayoutParent<RouteTarget>? resolveParentLayout(coordinator) =>
      _proxy.resolveParentLayout(coordinator);
}
