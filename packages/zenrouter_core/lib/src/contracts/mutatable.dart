/// Shared stack-mutation contract for coordinators and stack paths.
///
/// Implemented by [StackMutatable] and [CoordinatorMutatable].
///
/// Path-level and coordinator-level [pop] APIs differ (path returns
/// `Future<bool?>`, coordinator may expose both [CoordinatorMutatable.pop]
/// and [CoordinatorMutatable.tryPop]), so pop is intentionally not part of
/// this shared contract.
abstract interface class Mutatable<T> {
  /// Adds [route] to the navigation stack.
  ///
  /// Returns a future that completes when the route is later popped.
  Future<R?> push<R extends Object>(T route);

  /// Adds [route] and completes once the stack mutation is committed.
  ///
  /// Unlike [push], this does not wait for the route to be popped and does
  /// not return a pop result.
  Future<void> pushSilently(T route);

  /// Pushes [route], or moves an existing equal route to the top.
  Future<void> pushOrMoveToTop(T route);

  /// Replaces the current route with [route].
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T route, {
    RO? result,
  });
}
