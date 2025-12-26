part of 'base.dart';

/// A fixed stack path for indexed navigation (like tabs).
///
/// Routes are pre-defined and cannot be added or removed. Navigation switches
/// the active index.
class IndexedStackPath<T extends RouteTarget> extends StackPath<T>
    with RestorablePath<T, int, int> {
  IndexedStackPath._(super.stack, {super.debugLabel, super.coordinator})
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super() {
    for (final path in stack) {
      /// Set the output of every route to null since this cannot pop
      path.completeOnResult(null, null);
      path._path = this;
    }
  }

  // coverage:ignore-start
  /// Creates an [IndexedStackPath] with a fixed list of routes.
  ///
  /// This is deprecated. Use [IndexedStackPath.create] or [IndexedStackPath.createWith] instead.
  @Deprecated(
    'Use IndexedStackPath.create or IndexedStackPath.createWith instead',
  )
  factory IndexedStackPath(
    List<T> stack, [
    String? debugLabel,
    Coordinator? coordinator,
  ]) => IndexedStackPath._(
    stack,
    debugLabel: debugLabel,
    coordinator: coordinator,
  );
  // coverage:ignore-end

  /// Creates an [IndexedStackPath] with a fixed list of routes.
  ///
  /// This is the standard way to create a fixed stack for indexed navigation.
  factory IndexedStackPath.create(
    List<T> stack, {
    String? label,
    Coordinator? coordinator,
  }) => IndexedStackPath._(stack, debugLabel: label, coordinator: coordinator);

  /// Creates an [IndexedStackPath] associated with a [Coordinator].
  ///
  /// This constructor binds the path to a specific coordinator, allowing it to
  /// interact with the coordinator for navigation actions.
  factory IndexedStackPath.createWith(
    List<T> stack, {
    required Coordinator coordinator,
    required String label,
  }) => IndexedStackPath._(stack, debugLabel: label, coordinator: coordinator);

  /// The key used to identify this type in [RouteLayout.definePath].
  static const key = PathKey('IndexedStackPath');

  /// IndexedStackPath key. This is used to identify this type in [RouteLayout.definePath].
  @override
  PathKey get pathKey => key;

  int _activeIndex = 0;

  // coverage:ignore-start
  /// The index of the currently active path in the stack.
  @Deprecated('Use `activeIndex` instead. This will be removed in 1.0.0')
  int get activePathIndex => _activeIndex;
  // coverage:ignore-end

  /// The index of the currently active path in the stack.
  int get activeIndex => _activeIndex;

  @override
  T get activeRoute => stack[activeIndex];

  /// Switches the active route to the one at [index].
  ///
  /// Handles guards on the current route and redirects on the new route.
  Future<void> goToIndexed(int index) async {
    if (index >= stack.length || index < 0) {
      throw StateError('Index out of bounds');
    }

    /// Ignore already active index
    if (index == _activeIndex) return;

    final oldIndex = _activeIndex;
    final oldRoute = stack[oldIndex];
    if (oldRoute is RouteGuard) {
      final guard = oldRoute as RouteGuard;
      final canPop = await switch (coordinator) {
        null => guard.popGuard(),
        final coordinator => guard.popGuardWith(coordinator),
      };
      if (!canPop) return;
    }
    var newRoute = stack[index];
    while (newRoute is RouteRedirect<T>) {
      final redirectTo = await (newRoute as RouteRedirect<T>).redirect();
      if (redirectTo == null) return;
      newRoute = redirectTo;
    }

    final newIndex = stack.indexOf(newRoute);
    // Not found
    if (newIndex == -1) return;
    _activeIndex = newIndex;
    notifyListeners();
  }

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    route.completeOnResult(null, null, true);
    if (index == _activeIndex) {
      final currentRoute = stack[_activeIndex];

      /// If the route is a [RouteQueryParameters], update the queries
      if (currentRoute is RouteQueryParameters &&
          route is RouteQueryParameters) {
        currentRoute.queries = route.queries;
      }
      return;
    }
    if (index == -1) throw StateError('Route not found');
    await goToIndexed(index);
  }

  @override
  void reset() {
    _activeIndex = 0;
    notifyListeners();
  }

  @override
  void restore(int data) {
    assert(data >= 0 && data < stack.length, 'Index out of bounds');
    _activeIndex = data;
  }

  @override
  int serialize() => _activeIndex;

  @override
  int deserialize(int data) => data;
}
