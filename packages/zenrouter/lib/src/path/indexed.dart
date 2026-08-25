// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:zenrouter/src/coordinator/base.dart';
import 'package:zenrouter/src/path/restoration.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// A fixed stack path for indexed navigation (like tabs).
///
/// Routes are pre-defined and cannot be added or removed. Navigation switches
/// the active index.
///
/// ## Role in Navigation Flow
///
/// [IndexedStackPath] manages tab-based navigation:
/// 1. Routes are defined upfront in a fixed list
/// 2. Navigation switches the active index rather than stack
/// 3. Renders content via [IndexedStackPathBuilder] widget
/// 4. Implements [RestorablePath] for tab index restoration
///
/// When navigating:
/// - [goToIndexed] switches to a different route by index
/// - [activateRoute] activates a route already in the stack
/// - Routes cannot be pushed or popped, only activated
class IndexedStackPath<T extends RouteTarget> extends StackPath<T>
    with StackNavigatable<T>, RestorablePath<T, int, int>, ChangeNotifier {
  IndexedStackPath._(super.stack, {super.debugLabel, super.coordinator})
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super() {
    for (final path in stack) {
      /// Set the output of every route to null since this cannot pop
      path.completeOnResult(null, null);
      path.bindStackPath(this);
    }
  }

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

  /// The key used to identify this type in [defineLayoutBuilder].
  static const key = PathKey('IndexedStackPath');

  /// IndexedStackPath key. This is used to identify this type in [defineLayoutBuilder].
  @override
  PathKey get pathKey => key;

  int _activeIndex = 0;

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
    while (newRoute is RouteRedirect) {
      final routeRedirect = newRoute as RouteRedirect;
      final redirectTo = await switch (coordinator) {
        null => routeRedirect.redirect(),
        final coordinator => routeRedirect.redirectWith(coordinator),
      };
      assert(
        redirectTo == null || redirectTo is T,
        'Redirected route must be the same type as the stack route',
      );
      if (redirectTo == null) return;
      if (identical(redirectTo, newRoute)) break;
      newRoute = redirectTo as T;
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
    if (index == -1) {
      route.onDiscard();
      throw StateError('Route not found');
    }

    final indexRoute = stack[index];

    /// Update the existing route with new state
    indexRoute.onUpdate(route);

    if (!indexRoute.deepEquals(route)) {
      route.onDiscard();
    }

    if (index == _activeIndex) return;
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

  @override
  Future<void> navigate(T route) async {
    final routeIndex = stack.indexOf(route);
    if (routeIndex == -1) {
      // Route not found in IndexedStackPath - restore the URL to current state
      notifyListeners();
      return;
    }
    await activateRoute(route);
  }
}

/// A fixed collection of layout branches with an independent child path per
/// branch.
///
/// [BranchedStackPath] owns branch selection while each branch route owns its
/// own [StackPath] through [RouteLayoutParent.resolvePath]. Switching branches
/// therefore preserves the navigation depth of every branch.
///
/// Branch roots must implement [RouteLayoutParent]. Use [goToBranch] to switch
/// branches directly, or navigate to a route inside a branch and let the
/// coordinator activate the required branch hierarchy.
class BranchedStackPath<T extends RouteTarget> extends IndexedStackPath<T> {
  BranchedStackPath._(List<T> branches, {super.debugLabel, super.coordinator})
    : super._(_validateBranches(branches));

  /// Creates a branched path with fixed layout roots.
  factory BranchedStackPath.create(
    List<T> branches, {
    String? label,
    Coordinator? coordinator,
  }) => BranchedStackPath._(
    branches,
    debugLabel: label,
    coordinator: coordinator,
  );

  /// Creates a branched path associated with a [Coordinator].
  factory BranchedStackPath.createWith(
    List<T> branches, {
    required Coordinator coordinator,
    required String label,
  }) => BranchedStackPath._(
    branches,
    debugLabel: label,
    coordinator: coordinator,
  );

  /// The key used to select the built-in branched layout builder.
  static const key = PathKey('BranchedStackPath');

  @override
  PathKey get pathKey => key;

  /// The index of the currently active branch.
  int get activeBranchIndex => activeIndex;

  /// The layout root of the currently active branch.
  T get activeBranch => activeRoute;

  /// Switches to the branch at [index].
  Future<void> goToBranch(int index) => goToIndexed(index);

  /// Resets branch selection and every child path owned by the branch roots.
  ///
  /// This keeps a shell removal from leaking stale branch history when the
  /// shell is activated again. Ordinary branch switches do not reset children.
  @override
  void reset() {
    final branchCoordinator = proxyCoordinator ?? coordinator;
    if (branchCoordinator != null) {
      for (final branch in stack.cast<RouteLayoutParent>()) {
        final childPath = branch.resolvePath(branchCoordinator);
        if (!identical(childPath, this)) childPath.reset();
      }
    }
    super.reset();
  }

  static List<T> _validateBranches<T extends RouteTarget>(List<T> branches) {
    if (branches.isEmpty) {
      throw ArgumentError.value(
        branches,
        'branches',
        'A branched path requires at least one branch layout',
      );
    }
    final invalidBranches = branches
        .where((branch) => branch is! RouteLayoutParent)
        .map((branch) => branch.runtimeType)
        .toList(growable: false);
    if (invalidBranches.isNotEmpty) {
      throw ArgumentError.value(
        branches,
        'branches',
        'Every branch must implement RouteLayoutParent; invalid roots: '
            '$invalidBranches',
      );
    }
    final branchKeys = <Object>{};
    final duplicateBranchKeys = <Object>{};
    for (final branch in branches.cast<RouteLayoutParent>()) {
      if (!branchKeys.add(branch.layoutKey)) {
        duplicateBranchKeys.add(branch.layoutKey);
      }
    }
    if (duplicateBranchKeys.isNotEmpty) {
      throw ArgumentError.value(
        branches,
        'branches',
        'Branch layout keys must be unique; duplicates: '
            '$duplicateBranchKeys',
      );
    }
    return branches;
  }
}
