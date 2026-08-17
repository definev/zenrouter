import 'package:meta/meta.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

/// Coordinator-to-path seam for a route that is already redirect-resolved.
///
/// Public path APIs still resolve redirects themselves. Coordinator actions
/// resolve once, then call these methods so [RouteRedirect.redirect] is not
/// invoked again on a self-returning gate.
@internal
abstract interface class StackCommit<T extends RouteTarget> {
  /// Commits [target] as a new stack entry.
  T commitResolvedRoute(T target);

  /// Replaces the current entry with [target].
  ///
  /// Returns null when a [RouteGuard] blocks the pop of the current route.
  Future<T?> commitResolvedReplacement<RO extends Object>(
    T target, {
    RO? result,
  });

  /// Moves [target] to the top, or appends it when it is not in the stack.
  void commitResolvedMoveToTop(T target);

  /// Pops back to [target] when it is already in the stack, otherwise commits
  /// it as a new entry.
  Future<void> commitResolvedNavigate(T target);
}
