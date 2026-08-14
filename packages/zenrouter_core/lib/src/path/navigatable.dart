import 'package:zenrouter_core/src/contracts/navigatable.dart';
import 'package:zenrouter_core/src/mixin/target.dart';
import 'package:zenrouter_core/src/path/base.dart';

/// Mixin for stack paths that support browser history navigation.
///
/// Paths with this mixin can handle back/forward button navigation
/// by popping or pushing routes to reach a target state.
///
/// Implements the shared [Navigatable] contract also used by
/// [CoordinatorNavigatable].
mixin StackNavigatable<T extends RouteTarget> on StackPath<T>
    implements Navigatable<T> {
  /// Navigates to a specific route, adjusting the stack accordingly.
  ///
  /// If the route exists in the stack, pops back to it.
  /// If not, pushes the route onto the stack.
  @override
  Future<void> navigate(T route);
}
