
import 'package:zenrouter_core/src/mixin/target.dart';
import 'package:zenrouter_core/src/path/base.dart';

/// Mixin for stack paths that support navigation.
///
/// Apply this mixin to [StackPath] subclasses that need navigation support.
mixin StackNavigatable<T extends RouteTarget> on StackPath<T> {
  /// Navigate to a specific route in the stack.
  ///
  /// This is useful for handling back/forward button on the browser.
  Future<void> navigate(T route);
}
