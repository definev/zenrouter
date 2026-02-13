import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/internal/type.dart';
import 'package:zenrouter_core/src/mixin/identity.dart';
import 'package:zenrouter_core/src/path/base.dart';

/// Mixin for routes that define a layout structure.
///
/// A layout is a route that wraps other routes, such as a shell or a tab bar.
/// It defines how its children are displayed and managed.
mixin RoutePath<T extends RouteIdentity> on RouteIdentity {
  /// Registers a custom layout constructor.
  ///
  /// Use this to define how a specific layout type should be instantiated.
  static void defineRoutePath<T extends RoutePath>(
    Object routePathKey,
    T Function() constructor,
  ) {
    RoutePath.routePathConstructorTable[routePathKey] = constructor;
    final layoutInstance = constructor();
    layoutInstance.completeOnResult(null, null, true);
  }

  /// Table of registered layout constructors.
  static Map<Object, RoutePathConstructor> routePathConstructorTable = {};

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  StackPath<RouteIdentity> resolvePath(covariant CoordinatorCore coordinator);

  // coverage:ignore-start
  /// RouteLayout does not use a URI.
  @override
  Uri toUri() => Uri.parse('/__layout/$runtimeType');
  // coverage:ignore-end

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    super.onDidPop(result, coordinator);
    assert(
      coordinator != null,
      '[RouteLayout] must be used with a [Coordinator]',
    );
    resolvePath(coordinator!).reset();
  }

  @override
  operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

extension RoutePathBinding<T extends RouteIdentity> on StackPath<T> {
  void bindRoutePath(RoutePathConstructor constructor) {
    final instance = constructor()..onDiscard();
    RoutePath.defineRoutePath(instance.runtimeType, constructor);
  }
}
