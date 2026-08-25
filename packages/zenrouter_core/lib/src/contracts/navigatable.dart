/// Shared navigation contract for coordinators and stack paths.
///
/// Implemented by [StackNavigatable] and [CoordinatorNavigatable].
abstract interface class Navigatable<T> {
  /// Navigates to [route], adjusting history as needed.
  ///
  /// If [route] already exists in the stack, pops back to it.
  /// Otherwise pushes [route].
  Future<void> navigate(T route);
}
