// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// Builds the embedded router represented by a [ProxyPath].
typedef ProxyPathWidgetBuilder<T extends RouteTarget> =
    Widget Function(BuildContext context, ProxyPath<T> path);

/// Lets a route handle proxy actions directly.
///
/// Routes stored in a [ProxyPath] must implement this mixin. [onActivate] and
/// [onPop] are required because deep-link activation and back navigation are
/// shell-specific. Other navigation methods default to activation semantics.
mixin ProxyRoute<T extends RouteTarget> on RouteTarget {
  /// Handles route activation for this proxy route.
  FutureOr<void> onActivate(ProxyPath<T> path);

  /// Handles idempotent navigation to this proxy route.
  FutureOr<void> onNavigate(ProxyPath<T> path) => onActivate(path);

  /// Handles pushing this proxy route.
  FutureOr<R?> onPush<R extends Object>(ProxyPath<T> path) async {
    await Future<void>.value(onNavigate(path));
    return null;
  }

  /// Handles replacing the current route with this proxy route.
  FutureOr<R?> onPushReplacement<R extends Object, RO extends Object>(
    ProxyPath<T> path, {
    RO? result,
  }) async => onPush(path);

  /// Handles pushing this route or moving it to the top of the proxy stack.
  FutureOr<void> onPushOrMoveToTop(ProxyPath<T> path) => onNavigate(path);

  /// Handles popping while this route is active.
  FutureOr<bool?> onPop(ProxyPath<T> path, [Object? result]);
}

mixin CoordinatorProxyRoute<T extends RouteTarget, PT extends RouteUnique>
    on ProxyRoute<T> {
  CoordinatorCore<PT> resolveProxyCoordinator(covariant ProxyPath<T> path);

  PT get proxyRoute;

  @override
  Future<void> onActivate(ProxyPath<T> path) =>
      resolveProxyCoordinator(path).replace(proxyRoute);

  @override
  Future<void> onNavigate(ProxyPath<T> path) =>
      resolveProxyCoordinator(path).navigate(proxyRoute);

  @override
  Future<R?> onPush<R extends Object>(ProxyPath<T> path) =>
      resolveProxyCoordinator(path).push<R>(proxyRoute);

  @override
  Future<R?> onPushReplacement<R extends Object, RO extends Object>(
    ProxyPath<T> path, {
    RO? result,
  }) => resolveProxyCoordinator(
    path,
  ).pushReplacement<R, RO>(proxyRoute, result: result);

  @override
  Future<void> onPushOrMoveToTop(ProxyPath<T> path) async {
    resolveProxyCoordinator(path).pushOrMoveToTop(proxyRoute);
  }

  @override
  Future<bool?> onPop(ProxyPath<T> path, [Object? result]) =>
      resolveProxyCoordinator(path).tryPop(result);
}

/// A [StackPath] facade that proxies route actions to another router.
///
/// Unlike [NavigationPath], this path owns only a host-route proxy stack.
/// The real navigation state remains in the embedded router, while mutation
/// methods are forwarded through [ProxyRoute] handlers.
class ProxyPath<T extends RouteTarget> extends StackPath<T>
    with ChangeNotifier
    implements
        StackNavigatable<T>,
        StackPush<T>,
        StackPushReplacement<T>,
        StackPushOrMoveToTop<T>,
        StackReset<T>,
        StackRemove<T>,
        StackPop<T> {
  ProxyPath._({
    ProxyPathWidgetBuilder<T>? builder,
    VoidCallback? onReset,
    String? label,
    super.coordinator,
    bool notifyAfterAction = true,
  }) : _builder = builder,
       _onReset = onReset,
       _notifyAfterAction = notifyAfterAction,
       super(<T>[], debugLabel: label);

  /// Creates a proxy path.
  factory ProxyPath.create({
    ProxyPathWidgetBuilder<T>? builder,
    VoidCallback? onReset,
    String? label,
    CoordinatorCore? coordinator,
    bool notifyAfterAction = true,
  }) => ProxyPath._(
    builder: builder,
    onReset: onReset,
    label: label,
    coordinator: coordinator,
    notifyAfterAction: notifyAfterAction,
  );

  /// Creates a proxy path associated with a [CoordinatorCore].
  factory ProxyPath.createWith({
    required CoordinatorCore coordinator,
    required String label,
    ProxyPathWidgetBuilder<T>? builder,
    VoidCallback? onReset,
    bool notifyAfterAction = true,
  }) => ProxyPath._(
    builder: builder,
    onReset: onReset,
    label: label,
    coordinator: coordinator,
    notifyAfterAction: notifyAfterAction,
  );

  /// The key used to identify this type in [defineLayoutBuilder].
  static const key = PathKey('ProxyPath');

  final ProxyPathWidgetBuilder<T>? _builder;
  final VoidCallback? _onReset;
  final bool _notifyAfterAction;
  bool _notificationPending = false;
  bool _isDisposed = false;

  @override
  PathKey get pathKey => key;

  @override
  T? get activeRoute => stack.lastOrNull;

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

  Future<T?> _resolve(T route) async {
    // Coordinator-owned paths receive pre-resolved routes from CoordinatorCore.
    if (coordinator != null) return route;
    return RouteRedirect.resolve(route, coordinator);
  }

  void _prepareRoute(T route) {
    _proxyRouteFor(route);
    route.isPopByPath = false;
    route.bindStackPath(this);
  }

  void _activateOwnedRoute(T route) {
    _replaceStack([route]);
  }

  Future<bool> _navigateOwnedRoute(T route) async {
    final routeIndex = stack.indexOf(route);
    if (routeIndex == -1) {
      return false;
    }

    while (stack.length > routeIndex + 1) {
      final allowPop = await pop();
      if (allowPop == null || !allowPop) {
        notifyListeners();
        return true;
      }
    }

    final existingRoute = stack[routeIndex];
    existingRoute.onUpdate(route);
    notifyListeners();

    if (!existingRoute.deepEquals(route)) {
      route.onDiscard();
      route.clearStackPath();
    }
    return true;
  }

  void _pushOwnedRoute(T route) {
    _replaceStack([...stack, route]);
  }

  void _pushReplacementOwnedRoute(T route) {
    final nextStack = stack.isEmpty
        ? [route]
        : [...stack.take(stack.length - 1), route];
    _replaceStack(nextStack);
  }

  void _pushOrMoveOwnedRoute(T route) {
    final currentStack = stack;
    final routeIndex = currentStack.indexOf(route);
    if (routeIndex != -1 && routeIndex == currentStack.length - 1) {
      currentStack.last.onUpdate(route);
      if (!currentStack.last.deepEquals(route)) {
        route.onDiscard();
        route.clearStackPath();
      }
      return;
    }

    final nextStack = [...currentStack];
    if (routeIndex != -1) {
      final removed = nextStack.removeAt(routeIndex);
      if (!removed.deepEquals(route)) {
        removed.onDiscard();
        removed.clearStackPath();
      }
    }
    _replaceStack([...nextStack, route]);
  }

  void _popOwnedRouteIfAccepted(bool? accepted) {
    if (accepted != true || stack.isEmpty) return;
    _replaceStack(stack.take(stack.length - 1).toList());
  }

  bool _replaceStack(List<T> nextStack, {bool discardRemoved = false}) {
    for (final route in nextStack) {
      _proxyRouteFor(route);
    }
    if (_stackMatches(nextStack)) return false;

    for (final route in stack) {
      if (discardRemoved && !nextStack.contains(route)) {
        route.onDiscard();
      }
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

  @override
  Future<void> activateRoute(T route) async {
    _prepareRoute(route);
    final proxyRoute = _proxyRouteFor(route);
    final result = proxyRoute.onActivate(this);
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
    final handledExistingRoute = await _navigateOwnedRoute(target);
    if (handledExistingRoute) return;

    final result = proxyRoute.onNavigate(this);
    _pushOwnedRoute(target);
    _notifyActionProxied();
    await result;
  }

  @override
  Future<R?> push<R extends Object>(T element) async {
    final target = await _resolve(element);
    if (target == null) return null;

    _prepareRoute(target);
    final proxyRoute = _proxyRouteFor(target);
    final result = proxyRoute.onPush<R>(this);
    _pushOwnedRoute(target);
    _notifyActionProxied();
    return result;
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
    final proxyResult = proxyRoute.onPushReplacement<R, RO>(
      this,
      result: result,
    );
    _pushReplacementOwnedRoute(target);
    _notifyActionProxied();
    return proxyResult;
  }

  @override
  Future<void> pushOrMoveToTop(T element) async {
    final target = await _resolve(element);
    if (target == null) return;

    _prepareRoute(target);
    final proxyRoute = _proxyRouteFor(target);
    final result = proxyRoute.onPushOrMoveToTop(this);
    _pushOrMoveOwnedRoute(target);
    _notifyActionProxied();
    return result;
  }

  @override
  Future<bool?> pop([Object? result]) async {
    final route = activeRoute;
    if (route != null) {
      route.isPopByPath = true;
      route.bindResultValue(result);
    }

    final proxyResult = switch (activeRoute) {
      final T route => _proxyRouteFor(route).onPop(this, result),
      _ => null,
    };
    final accepted = await proxyResult;
    _popOwnedRouteIfAccepted(accepted);
    _notifyActionProxied();
    return accepted;
  }

  @override
  void reset() {
    _onReset?.call();
    _replaceStack(<T>[]);
    _notifyActionProxied();
  }

  @override
  void remove(T element, {bool discard = true}) {
    if (discard) element.onDiscard();
    element.clearStackPath();
    _replaceStack(stack.where((route) => route != element).toList());
    _notifyActionProxied();
  }

  @override
  FutureOr<bool?> get canPop => stack.length >= 2;
}
