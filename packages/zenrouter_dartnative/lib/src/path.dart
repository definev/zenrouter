import 'package:zenrouter_core/zenrouter_core.dart';

/// A mutable, platform-neutral stack for native layout branches.
///
/// Physical rendering is deliberately separate. The root host can project one
/// such path to native presentations; a future nested-navigator adapter can do
/// the same for each branch without changing coordinator state semantics.
class NavigationPath<T extends RouteTarget> extends StackPath<T>
    with StackMutatable<T>, _PathListeners {
  NavigationPath._({List<T>? routes, super.debugLabel, super.coordinator})
    : super(List<T>.of(routes ?? const [])) {
    for (final route in stack) {
      // ignore: invalid_use_of_protected_member
      route.bindStackPath(this);
    }
  }

  factory NavigationPath.create({
    String? label,
    List<T>? routes,
    CoordinatorCore? coordinator,
  }) => NavigationPath._(
    routes: routes,
    debugLabel: label,
    coordinator: coordinator,
  );

  factory NavigationPath.createWith({
    required CoordinatorCore coordinator,
    required String label,
    List<T>? routes,
  }) => NavigationPath._(
    routes: routes,
    debugLabel: label,
    coordinator: coordinator,
  );

  static const key = PathKey('NavigationPath');

  @override
  PathKey get pathKey => key;

  @override
  T? get activeRoute => stack.lastOrNull;

  @override
  Future<void> activateRoute(T route) async {
    reset();
    await pushSilently(route);
  }

  @override
  void reset() {
    if (stack.isEmpty) return;
    clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    clearListeners();
    super.dispose();
  }
}

/// A fixed, platform-neutral route path for indexed navigation.
///
/// This is implemented in `zenrouter_dartnative` as a platform-clean path.
/// It owns navigation state only; a native
/// widget such as `IndexedStackPathBuilder` renders that state separately.
class IndexedStackPath<T extends RouteTarget> extends StackPath<T>
    with StackNavigatable<T>, _PathListeners {
  IndexedStackPath._(List<T> routes, {super.debugLabel, super.coordinator})
    : super(_validateRoutes(routes)) {
    for (final route in routes) {
      route.completeOnResult(null, null);
      // ignore: invalid_use_of_protected_member
      route.bindStackPath(this);
    }
  }

  factory IndexedStackPath.create(
    List<T> routes, {
    String? label,
    CoordinatorCore? coordinator,
  }) => IndexedStackPath._(routes, debugLabel: label, coordinator: coordinator);

  factory IndexedStackPath.createWith(
    List<T> routes, {
    required CoordinatorCore coordinator,
    required String label,
  }) => IndexedStackPath._(routes, debugLabel: label, coordinator: coordinator);

  static const key = PathKey('IndexedStackPath');

  @override
  PathKey get pathKey => key;

  int _activeIndex = 0;

  int get activeIndex => _activeIndex;

  @override
  T get activeRoute => stack[_activeIndex];

  /// Selects one of the fixed routes after consulting the current route guard
  /// and resolving redirects on the destination.
  Future<void> goToIndexed(int index) async {
    if (index < 0 || index >= stack.length) {
      throw RangeError.index(index, stack, 'index');
    }
    if (index == _activeIndex) return;

    final current = stack[_activeIndex];
    if (current case final RouteGuard guard) {
      final allowed = await switch (coordinator) {
        null => guard.popGuard(),
        final owner => guard.popGuardWith(owner),
      };
      if (!allowed) return;
    }

    var destination = stack[index];
    while (destination is RouteRedirect) {
      final redirect = destination as RouteRedirect;
      final resolved = await switch (coordinator) {
        null => redirect.redirect(),
        final owner => redirect.redirectWith(owner),
      };
      if (resolved == null) return;
      if (resolved is! T) {
        resolved.onDiscard();
        throw StateError(
          'An indexed route redirect must remain in the same route type.',
        );
      }
      if (identical(resolved, destination)) break;
      destination = resolved;
    }

    final destinationIndex = stack.indexOf(destination);
    if (destinationIndex < 0) {
      if (!stack.any((route) => identical(route, destination))) {
        destination.onDiscard();
      }
      return;
    }

    if (!identical(destination, stack[destinationIndex])) {
      stack[destinationIndex].onUpdate(destination);
      destination.onDiscard();
    }
    _activeIndex = destinationIndex;
    notifyListeners();
  }

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    if (index < 0) {
      route.onDiscard();
      throw StateError('Route is not a member of this indexed path.');
    }

    final existing = stack[index];
    if (!identical(existing, route)) {
      existing.onUpdate(route);
      route.onDiscard();
    }
    await goToIndexed(index);
  }

  @override
  Future<void> navigate(T route) async {
    final index = stack.indexOf(route);
    if (index < 0) {
      route.onDiscard();
      notifyListeners();
      return;
    }
    await activateRoute(route);
  }

  @override
  void reset() {
    if (_activeIndex == 0) return;
    _activeIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    clearListeners();
    super.dispose();
  }

  static List<T> _validateRoutes<T extends RouteTarget>(List<T> routes) {
    if (routes.isEmpty) {
      throw ArgumentError.value(
        routes,
        'routes',
        'An indexed path requires at least one route.',
      );
    }

    for (var index = 0; index < routes.length; index++) {
      final route = routes[index];
      if (route.stackPath != null) {
        throw StateError('Indexed routes must not already belong to a path.');
      }
      if (routes.take(index).contains(route)) {
        throw ArgumentError.value(
          routes,
          'routes',
          'Indexed routes must be unique.',
        );
      }
    }
    return List<T>.of(routes);
  }
}

/// Fixed layout branches whose child paths keep independent logical state.
///
/// This class does not claim that DartNative can render a native Navigator per
/// branch. It models the router topology, leaving the
/// physical nested-navigation adapter as a separate capability.
class BranchedStackPath<T extends RouteTarget> extends IndexedStackPath<T> {
  BranchedStackPath._(List<T> branches, {super.debugLabel, super.coordinator})
    : super._(_validateBranches(branches));

  factory BranchedStackPath.create(
    List<T> branches, {
    String? label,
    CoordinatorCore? coordinator,
  }) => BranchedStackPath._(
    branches,
    debugLabel: label,
    coordinator: coordinator,
  );

  factory BranchedStackPath.createWith(
    List<T> branches, {
    required CoordinatorCore coordinator,
    required String label,
  }) => BranchedStackPath._(
    branches,
    debugLabel: label,
    coordinator: coordinator,
  );

  static const key = PathKey('BranchedStackPath');

  @override
  PathKey get pathKey => key;

  int get activeBranchIndex => activeIndex;
  T get activeBranch => activeRoute;

  Future<void> goToBranch(int index) => goToIndexed(index);

  @override
  void reset() {
    final owner = proxyCoordinator ?? coordinator;
    if (owner != null) {
      for (final branch in stack.cast<RouteLayoutParent>()) {
        final childPath = branch.resolvePath(owner);
        if (!identical(childPath, this)) childPath.reset();
      }
    }
    super.reset();
  }

  static List<T> _validateBranches<T extends RouteTarget>(List<T> branches) {
    final keys = <Object>{};
    for (final branch in branches) {
      if (branch is! RouteLayoutParent) {
        throw ArgumentError.value(
          branches,
          'branches',
          'Every native branch must be a RouteLayoutParent.',
        );
      }
      if (!keys.add(branch.layoutKey)) {
        throw ArgumentError.value(
          branches,
          'branches',
          'Native branch layout keys must be unique.',
        );
      }
    }
    return branches;
  }
}

mixin _PathListeners implements ListenableObject {
  final _listeners = <void Function()>{};

  @override
  void addListener(void Function() listener) => _listeners.add(listener);

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void clearListeners() => _listeners.clear();

  @override
  void notifyListeners() {
    for (final listener in List<void Function()>.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }
}
