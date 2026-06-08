// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// Builds the host-route mirror stack represented by a [ProxyPath].
typedef ProxyPathStackProvider<T extends RouteTarget> = List<T> Function();

/// Handles navigation actions emitted by a [ProxyPath].
///
/// Return values are action-specific:
/// - [ProxyPush] and [ProxyPushReplacement] may return the route result, or a
///   future that completes with that result.
/// - [ProxyPop] should return whether the pop was accepted.
/// - Other actions ignore the returned value.
typedef ProxyPathActionHandler<T extends RouteTarget> =
    FutureOr<Object?> Function(ProxyPathAction<T> action);

/// Builds the embedded router represented by a [ProxyPath].
typedef ProxyPathWidgetBuilder<T extends RouteTarget> =
    Widget Function(BuildContext context, ProxyPath<T> path);

/// Lets a route handle proxy actions directly.
///
/// Routes stored in a [ProxyPath] must implement this mixin. [onActivate] and
/// [onPop] are required because deep-link activation and back navigation are
/// shell-specific. Other navigation methods default to activation semantics.
mixin ProxyRoute<T extends RouteTarget> on RouteTarget {
  /// Handles [ProxyActivate] for this route.
  FutureOr<void> onActivate(ProxyPath<T> path);

  /// Handles [ProxyNavigate] for this route.
  FutureOr<void> onNavigate(ProxyPath<T> path) => onActivate(path);

  /// Handles [ProxyPush] for this route.
  FutureOr<R?> onPush<R extends Object>(ProxyPath<T> path) async {
    await Future<void>.value(onNavigate(path));
    return null;
  }

  /// Handles [ProxyPushReplacement] for this route.
  FutureOr<R?> onPushReplacement<R extends Object, RO extends Object>(
    ProxyPath<T> path, {
    RO? result,
  }) async {
    await Future<void>.value(onNavigate(path));
    return null;
  }

  /// Handles [ProxyPushOrMoveToTop] for this route.
  FutureOr<void> onPushOrMoveToTop(ProxyPath<T> path) => onNavigate(path);

  /// Handles [ProxyPop] for the currently active route.
  FutureOr<bool?> onPop(ProxyPath<T> path, [Object? result]);
}

/// A navigation action emitted by [ProxyPath].
sealed class ProxyPathAction<T extends RouteTarget> {
  const ProxyPathAction();
}

/// Makes [route] the active route.
final class ProxyActivate<T extends RouteTarget> extends ProxyPathAction<T> {
  const ProxyActivate(this.route);

  final T route;
}

/// Navigates to [route] using the target router's idempotent navigation.
final class ProxyNavigate<T extends RouteTarget> extends ProxyPathAction<T> {
  const ProxyNavigate(this.route);

  final T route;
}

/// Pushes [route] onto the target router.
final class ProxyPush<T extends RouteTarget> extends ProxyPathAction<T> {
  const ProxyPush(this.route);

  final T route;
}

/// Replaces the current route with [route].
final class ProxyPushReplacement<T extends RouteTarget>
    extends ProxyPathAction<T> {
  const ProxyPushReplacement(this.route, {this.result});

  final T route;
  final Object? result;
}

/// Pushes [route] or moves an existing route instance to the top.
final class ProxyPushOrMoveToTop<T extends RouteTarget>
    extends ProxyPathAction<T> {
  const ProxyPushOrMoveToTop(this.route);

  final T route;
}

/// Pops the target router.
final class ProxyPop<T extends RouteTarget> extends ProxyPathAction<T> {
  const ProxyPop([this.result]);

  final Object? result;
}

/// Resets the target router.
final class ProxyReset<T extends RouteTarget> extends ProxyPathAction<T> {
  const ProxyReset();
}

/// A [StackPath] facade that proxies route actions to another router.
///
/// Unlike [NavigationPath], this path owns only a host-route mirror stack.
/// The real navigation state remains in the embedded router, while mutation
/// methods are forwarded through [ProxyRoute] handlers.
class ProxyPath<T extends RouteTarget> extends StackPath<T>
    with ChangeNotifier
    implements StackMutatable<T> {
  ProxyPath._({
    ProxyPathActionHandler<T>? onAction,
    ProxyPathStackProvider<T>? stack,
    ProxyPathWidgetBuilder<T>? builder,
    String? label,
    super.coordinator,
    bool notifyAfterAction = true,
  }) : _onAction = onAction,
       _stackProvider = stack,
       _builder = builder,
       _notifyAfterAction = notifyAfterAction,
       super(<T>[], debugLabel: label) {
    _syncStackFromProvider();
  }

  /// Creates a proxy path with an optional host-route mirror stack provider.
  factory ProxyPath.create({
    ProxyPathActionHandler<T>? onAction,
    ProxyPathStackProvider<T>? stack,
    ProxyPathWidgetBuilder<T>? builder,
    String? label,
    CoordinatorCore? coordinator,
    bool notifyAfterAction = true,
  }) => ProxyPath._(
    onAction: onAction,
    stack: stack,
    builder: builder,
    label: label,
    coordinator: coordinator,
    notifyAfterAction: notifyAfterAction,
  );

  /// Creates a proxy path associated with a [CoordinatorCore].
  factory ProxyPath.createWith({
    required CoordinatorCore coordinator,
    required String label,
    ProxyPathActionHandler<T>? onAction,
    ProxyPathStackProvider<T>? stack,
    ProxyPathWidgetBuilder<T>? builder,
    bool notifyAfterAction = true,
  }) => ProxyPath._(
    onAction: onAction,
    stack: stack,
    builder: builder,
    label: label,
    coordinator: coordinator,
    notifyAfterAction: notifyAfterAction,
  );

  /// The key used to identify this type in [defineLayoutBuilder].
  static const key = PathKey('ProxyPath');

  final ProxyPathActionHandler<T>? _onAction;
  final ProxyPathStackProvider<T>? _stackProvider;
  final ProxyPathWidgetBuilder<T>? _builder;
  final bool _notifyAfterAction;
  bool _notificationPending = false;
  bool _isDisposed = false;

  @override
  PathKey get pathKey => key;

  @override
  T? get activeRoute {
    final snapshot = stack;
    if (snapshot.isEmpty) return null;
    return snapshot.last;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Defers listener notification while widgets are building.
  ///
  /// [ProxyPath] can be notified mid-build when an embedded coordinator calls
  /// [notifyListeners]. Synchronous [ChangeNotifier.notifyListeners] would
  /// rebuild listeners (including the root [CoordinatorCore]) during build.
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    _syncStackFromProvider();

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notificationPending) return;
      _notificationPending = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notificationPending = false;
        if (!_isDisposed) super.notifyListeners();
      });
      return;
    }

    super.notifyListeners();
  }

  /// Rebuilds the owned host-route mirror stack from [stack].
  ///
  /// Call this directly when you need to sync without notifying listeners.
  bool syncStack() => _syncStackFromProvider();

  /// Builds the embedded router represented by this path.
  Widget build(BuildContext context) {
    final builder = _builder;
    if (builder == null) {
      throw UnimplementedError(
        'ProxyPath requires a builder when used with RouteLayout.buildPath '
        'or RouteLayout.buildRoot.',
      );
    }
    return builder(context, this);
  }

  Future<T?> _resolve(T route) => RouteRedirect.resolve(route, coordinator);

  void _prepareRoute(T route) {
    _proxyRouteFor(route);
    route.isPopByPath = false;
    route.bindStackPath(this);
  }

  bool _syncStackFromProvider() {
    final provider = _stackProvider;
    if (provider == null) return false;
    return _replaceStack(provider());
  }

  void _activateOwnedRoute(T route) {
    if (_stackProvider != null) return;
    _replaceStack([route]);
  }

  void _navigateOwnedRoute(T route) {
    if (_stackProvider != null) return;

    final routeIndex = stack.indexOf(route);
    if (routeIndex == -1) {
      _replaceStack([...stack, route]);
      return;
    }

    final existingRoute = stack[routeIndex];
    existingRoute.onUpdate(route);
    if (!identical(existingRoute, route)) {
      route.onDiscard();
      route.clearStackPath();
    }
    _replaceStack(stack.take(routeIndex + 1).toList());
  }

  void _pushOwnedRoute(T route) {
    if (_stackProvider != null) return;
    _replaceStack([...stack, route]);
  }

  void _pushReplacementOwnedRoute(T route) {
    if (_stackProvider != null) return;
    final nextStack = stack.isEmpty
        ? [route]
        : [...stack.take(stack.length - 1), route];
    _replaceStack(nextStack);
  }

  void _pushOrMoveOwnedRoute(T route) {
    if (_stackProvider != null) return;

    final currentStack = stack;
    final routeIndex = currentStack.indexOf(route);
    if (routeIndex != -1 && routeIndex == currentStack.length - 1) {
      currentStack.last.onUpdate(route);
      if (!identical(currentStack.last, route)) {
        route.onDiscard();
        route.clearStackPath();
      }
      return;
    }

    final nextStack = [...currentStack];
    if (routeIndex != -1) {
      final removed = nextStack.removeAt(routeIndex);
      if (!identical(removed, route)) {
        removed.onDiscard();
        removed.clearStackPath();
      }
    }
    _replaceStack([...nextStack, route]);
  }

  void _popOwnedRouteIfAccepted(bool? accepted) {
    if (_stackProvider != null || accepted != true || stack.isEmpty) return;
    _replaceStack(stack.take(stack.length - 1).toList());
  }

  bool _replaceStack(List<T> nextStack) {
    for (final route in nextStack) {
      _proxyRouteFor(route);
    }
    if (_stackMatches(nextStack)) return false;

    for (final route in stack) {
      route.clearStackPath();
    }
    bindStack(nextStack);
    return true;
  }

  bool _stackMatches(List<T> nextStack) {
    final currentStack = stack;
    if (currentStack.length != nextStack.length) return false;
    for (var i = 0; i < currentStack.length; i++) {
      if (currentStack[i] != nextStack[i]) return false;
    }
    return true;
  }

  ProxyRoute<T> _proxyRouteFor(T route) {
    if (route case final ProxyRoute<T> proxyRoute) return proxyRoute;
    throw ArgumentError.value(
      route,
      'route',
      'ProxyPath stack entries must implement ProxyRoute<$T>.',
    );
  }

  void _notifyActionProxied() {
    if (_notifyAfterAction) notifyListeners();
  }

  FutureOr<Object?> _fallbackAction(ProxyPathAction<T> action) {
    final onAction = _onAction;
    if (onAction == null) {
      throw UnimplementedError(
        'ProxyPath has no handler for ${action.runtimeType}. Provide onAction '
        'or override the matching method on ProxyRoute.',
      );
    }
    return onAction(action);
  }

  Future<Object?> _dispatchProxy(
    FutureOr<Object?> Function() invoke,
    ProxyPathAction<T> fallback,
  ) async {
    try {
      return await Future<Object?>.value(invoke());
    } on UnimplementedError {
      return await Future<Object?>.value(_fallbackAction(fallback));
    }
  }

  @override
  Future<void> activateRoute(T route) async {
    _prepareRoute(route);
    final proxyRoute = _proxyRouteFor(route);
    final result = _dispatchProxy(
      () => proxyRoute.onActivate(this),
      ProxyActivate(route),
    );
    _activateOwnedRoute(route);
    _notifyActionProxied();
    await result;
  }

  @override
  Future<void> navigate(T route) async {
    final target = await _resolve(route);
    if (target == null) return;

    _prepareRoute(target);
    final proxyRoute = _proxyRouteFor(target);
    final result = _dispatchProxy(
      () => proxyRoute.onNavigate(this),
      ProxyNavigate(target),
    );
    _navigateOwnedRoute(target);
    _notifyActionProxied();
    await result;
  }

  @override
  Future<R?> push<R extends Object>(T element) async {
    final target = await _resolve(element);
    if (target == null) return null;

    _prepareRoute(target);
    final proxyRoute = _proxyRouteFor(target);
    final result = _dispatchProxy(
      () => proxyRoute.onPush<R>(this),
      ProxyPush(target),
    );
    _pushOwnedRoute(target);
    _notifyActionProxied();
    return await Future<Object?>.value(result) as R?;
  }

  @override
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T element, {
    RO? result,
  }) async {
    final target = await _resolve(element);
    if (target == null) return null;

    _prepareRoute(target);
    final proxyRoute = _proxyRouteFor(target);
    final proxyResult = _dispatchProxy(
      () => proxyRoute.onPushReplacement<R, RO>(this, result: result),
      ProxyPushReplacement(target, result: result),
    );
    _pushReplacementOwnedRoute(target);
    _notifyActionProxied();
    return await Future<Object?>.value(proxyResult) as R?;
  }

  @override
  Future<void> pushOrMoveToTop(T element) async {
    final target = await _resolve(element);
    if (target == null) return;

    _prepareRoute(target);
    final proxyRoute = _proxyRouteFor(target);
    final result = _dispatchProxy(
      () => proxyRoute.onPushOrMoveToTop(this),
      ProxyPushOrMoveToTop(target),
    );
    _pushOrMoveOwnedRoute(target);
    _notifyActionProxied();
    await result;
  }

  @override
  Future<bool?> pop([Object? result]) async {
    final route = activeRoute;
    if (route != null) {
      route.isPopByPath = true;
      route.bindResultValue(result);
    }

    final proxyResult = switch (route) {
      final T route => _dispatchProxy(
        () => _proxyRouteFor(route).onPop(this, result),
        ProxyPop(result),
      ),
      _ => _fallbackAction(ProxyPop(result)),
    };
    final accepted = await Future<Object?>.value(proxyResult) as bool?;
    _popOwnedRouteIfAccepted(accepted);
    _notifyActionProxied();
    return accepted;
  }

  @override
  void reset() {
    final handler = _onAction;
    if (handler != null) handler(const ProxyReset());
    if (_stackProvider == null) _replaceStack(<T>[]);
    _notifyActionProxied();
  }

  @override
  void remove(T element, {bool discard = true}) {
    if (discard) element.onDiscard();
    element.clearStackPath();
    if (_stackProvider == null) {
      _replaceStack(stack.where((route) => route != element).toList());
    }
    _notifyActionProxied();
  }
}
