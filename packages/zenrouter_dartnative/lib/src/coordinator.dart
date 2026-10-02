import 'dart:async';

import 'package:zenrouter_core/zenrouter_core.dart';

import 'path.dart';

/// Optional core-side contract for routes that restrict persistent-root use.
///
/// `RouteUnique` implements this from its selected presentation. Keeping the
/// contract here lets synchronization tests stay independent of DartNative.
abstract interface class RootMountable {
  bool get canMountAsRoot;
}

/// A coordinator backed by a native presentation stack.
///
/// Standalone coordinators require a fresh, already-resolved [initialRoute].
/// To use a coordinator as a route module, override [coordinator] with its
/// owning [CoordinatorModular] and omit the initial route. The module shares
/// its owner's root, transactions, and presentation host.
///
/// Navigation futures retain core semantics: push waits for a result, whereas
/// pushSilently waits for a logical commit, not for native presentation.
/// The physical presentation stack remains linear. Additional indexed/layout
/// paths may model persistent in-tree navigation such as a bottom tab shell.
abstract class Coordinator<T extends RouteUri> extends CoordinatorCore<T>
    with
        _Listeners,
        CoordinatorLayoutCore<T>,
        CoordinatorNavigatable<T>,
        CoordinatorMutatable<T>,
        CoordinatorRecoverable<T> {
  Coordinator({T? initialRoute}) : _initialRoute = initialRoute;

  final T? _initialRoute;
  late final _RootPath<T> _root = isRouteModule
      ? coordinator.root as _RootPath<T>
      : _RootPath(
          this,
          _initialRoute ??
              (throw ArgumentError(
                'A standalone Coordinator requires an initialRoute.',
              )),
        );

  @override
  StackPath<T> get root => _root;

  /// Registers a layout constructor by its layout key.
  void defineLayoutParent(RouteLayoutParent<T> Function() constructor) {
    final sample = constructor();
    final key = sample.layoutKey;
    sample.onDiscard();
    defineLayoutParentConstructor(key, (_) => constructor());
  }

  /// Changes indexed navigation as one coordinator commit. The selected index,
  /// current URI, deep-link state, and native renderer therefore share a single
  /// source of truth.
  Future<void> selectIndex(IndexedStackPath<T> path, int index) =>
      runNavigationTransaction(() {
        final owner = path.proxyCoordinator ?? path.coordinator;
        if (!identical(owner?.root, root)) {
          throw StateError('The indexed path belongs to another coordinator.');
        }
        return path.goToIndexed(index);
      }, historyIntent: NavigationHistoryIntent.replace);

  // Resolve and validate the future persistent root before clearing any path.
  // This prevents a rejected modal root or missing layout from destroying the
  // currently synchronized logical stack.
  @override
  Future<void> replace(T route) => runNavigationTransaction(() async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    final layouts = <RouteLayoutParent>[];
    RouteLayoutParent? current = target.createParentLayout(this);
    while (current != null) {
      layouts.add(current);
      current = current.createParentLayout(this);
    }

    final rootTarget = layouts.isEmpty ? target : layouts.last;
    if (rootTarget is! T) {
      throw StateError('A native layout must use the coordinator route type.');
    }
    _root.validateRoot(rootTarget);

    // A module replaces the whole navigation state, including sibling paths.
    for (final path in _root.coordinator!.paths) {
      path.reset();
    }

    StackPath parentPath = root;
    for (final layout in layouts.reversed) {
      await parentPath.activateRoute(layout);
      parentPath = layout.resolvePath(this);
    }
    await parentPath.activateRoute(target);
  }, historyIntent: NavigationHistoryIntent.replace);

  /// Used by the presentation adapter after the platform has already popped.
  /// Removes that exact entry, never an equal route or the new active route.
  /// Does not run guards a second time or issue another native pop.
  Future<void> acknowledgePop(T route, Object? result) =>
      runNavigationTransaction(() {
        _root.acknowledgePop(route, result);
      }, historyIntent: NavigationHistoryIntent.replace);

  @override
  void dispose() {
    super.dispose();
    clearListeners();
  }
}

mixin _Listeners {
  final _listeners = <void Function()>[];

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void clearListeners() => _listeners.clear();

  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }
}

class _RootPath<T extends RouteUri> extends StackPath<T>
    with _Listeners, StackMutatable<T> {
  _RootPath(Coordinator<T> coordinator, T initialRoute)
    : super([], coordinator: coordinator, debugLabel: 'root') {
    validateRoot(initialRoute);
    _used.add(initialRoute);
    bindStack([initialRoute]);
  }

  // A route's result completer is one-shot. Even after removal, an instance
  // cannot be pushed again. Expando avoids retaining every visited route.
  final _used = _RouteInstances<T>();

  @override
  PathKey get pathKey => const PathKey('RootPath');

  @override
  T? get activeRoute => stack.lastOrNull;

  void validateFresh(T route) {
    if (route.parentLayoutKey != null) {
      throw UnsupportedError(
        'The route declares a parent layout but no registered layout path '
        'accepted it.',
      );
    }
    if (_used.contains(route) || route.stackPath != null) {
      throw StateError('Use a fresh route instance for each new stack entry.');
    }
  }

  void validateRoot(T route) {
    validateFresh(route);
    if (route case RootMountable(canMountAsRoot: false)) {
      throw UnsupportedError(
        'This route presentation cannot become the persistent native root. '
        'Push it, or give its presentation root support.',
      );
    }
  }

  @override
  T commitResolvedRoute(T target) {
    validateFresh(target);
    _used.add(target);
    // ignore: invalid_use_of_internal_member
    return super.commitResolvedRoute(target);
  }

  @override
  Future<T?> commitResolvedReplacement<RO extends Object>(
    T target, {
    RO? result,
  }) {
    validateFresh(target);
    if (stack.length <= 1) {
      if (target case RootMountable(canMountAsRoot: false)) {
        throw UnsupportedError(
          'A non-root presentation cannot replace the persistent native root.',
        );
      }
    }
    // ignore: invalid_use_of_internal_member
    return super.commitResolvedReplacement(target, result: result);
  }

  @override
  void commitResolvedMoveToTop(T target) {
    final index = stack.indexOf(target);
    if (index >= 0 && index != stack.length - 1) {
      throw UnsupportedError(
        'Moving an existing native screen is unsupported. '
        'Use navigate() to pop back to it.',
      );
    }
    if (index < 0) {
      commitResolvedRoute(target);
    } else {
      // ignore: invalid_use_of_internal_member
      super.commitResolvedMoveToTop(target);
    }
  }

  @override
  void replaceAll(Iterable<T> routes) {
    final next = routes.toList();
    if (next.length != 1) {
      throw UnsupportedError('Only a single fresh root reset is supported.');
    }
    validateRoot(next.single);
    _used.add(next.single);
    super.replaceAll(next);
  }

  @override
  void reset() {
    clear();
    notifyListeners();
  }

  @override
  Future<void> activateRoute(T route) async {
    replaceAll([route]);
  }

  void acknowledgePop(T route, Object? result) {
    final current = stack;
    final index = current.indexWhere((item) => identical(item, route));
    if (index < 0) return; // Already removed by a logical transaction.
    if (index == 0) throw StateError('The native root cannot be popped.');
    // Do not use List.remove/operator ==: equal URIs can be distinct entries.
    route.isPopByPath = true;
    route.completeOnResult(result, coordinator, true);
    route.onDidPop(result, coordinator);
    bindStack([...current.take(index), ...current.skip(index + 1)]);
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    clearListeners();
    super.dispose();
  }
}

class _RouteInstances<T extends RouteUri> {
  final _entries = Expando<bool>();
  bool contains(T route) => _entries[route] == true;
  void add(T route) => _entries[route] = true;
}
