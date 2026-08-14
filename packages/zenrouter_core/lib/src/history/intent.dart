/// How the next committed navigation should affect an external history.
///
/// The core records intent without depending on a browser or UI framework.
/// A history adapter consumes the intent when it publishes the resulting URI.
enum NavigationHistoryIntent {
  /// Let the adapter infer the behavior from the old and new URI.
  automatic,

  /// Create a new history entry, even when the URI is unchanged.
  push,

  /// Update the current history entry without creating a new one.
  replace,

  /// The location originated from external history traversal.
  ///
  /// Applying the route must not author another history entry.
  traverse,
}
