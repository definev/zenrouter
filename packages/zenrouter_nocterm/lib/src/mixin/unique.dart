import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_core/zenrouter_core.dart';
import 'package:zenrouter_nocterm/src/coordinator/base.dart';
import 'package:zenrouter_nocterm/src/mixin/layout.dart';

/// Base mixin for unique routes in the application.
///
/// Most routes should mix this in. It provides integration with the [Coordinator]
/// and layout system.
///
/// ## Role in Navigation Flow
///
/// [RouteUnique] enables routes to participate in coordinator-based navigation:
/// 1. Implements [RouteUri] for URI-based identification
/// 2. Can be resolved by [Coordinator.parseRouteFromUri]
/// 3. Can be bound to a [RouteLayout] via the [layout] getter
/// 4. Creates parent layouts via [createParentLayout]
///
/// This is the most common mixin for application routes.
mixin RouteUnique on RouteTarget implements RouteUri {
  @override
  Uri get identifier => toUri();

  /// The type of layout that wraps this route.
  ///
  /// Return the type of the [RouteLayout] subclass that should contain this route.
  Type? get layout => null;

  @override
  Object? get parentLayoutKey => layout;

  @override
  RouteLayout createParentLayout(covariant CoordinatorCore coordinator) {
    final constructor = _proxy.createParentLayout(coordinator);

    if (constructor == null) {
      throw UnimplementedError(
        'Missing constructor for the [$parentLayoutKey] layout. '
        'You can define a constructor by calling `bindLayout` in the corresponding [StackPath].\n'
        'Alternatively, you can define a constructor for this layout by calling [defineLayoutParent] '
        'in the [defineLayout] function of [${coordinator.runtimeType}].',
      );
    }

    return constructor as RouteLayout;
  }

  // coverage:ignore-start
  /// Resolves the parent layout for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  @Deprecated('use `resolveParentLayout` instead.')
  RouteLayout? resolveLayout(covariant CoordinatorCore coordinator) =>
      resolveParentLayout(coordinator);
  // coverage:ignore-end

  late final _proxy = RouteLayoutChild.proxy(this);

  @override
  RouteLayout? resolveParentLayout(coordinator) {
    final layout = _proxy.resolveParentLayout(coordinator) as RouteLayout?;
    return layout;
  }

  /// Builds the widget for this route.
  Component build(covariant CoordinatorCore coordinator, BuildContext context);
}
