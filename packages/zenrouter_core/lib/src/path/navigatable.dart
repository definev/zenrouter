import 'package:zenrouter_core/src/mixin/target.dart';
import 'package:zenrouter_core/src/path/base.dart';

/// Mixin for stack paths that support browser history navigation.
///
/// Paths with this mixin can handle back/forward button navigation
/// by popping or pushing routes to reach a target state.
mixin StackNavigatable<T extends RouteTarget> on StackPath<T> {
  /// Navigates to a specific route, adjusting the stack accordingly.
  ///
  /// If the route exists in the stack, pops back to it.
  /// If not, pushes the route onto the stack.
  Future<void> navigate(T route);
}
