part of 'base.dart';

/// Handler invoked when recovering a deep link with a given [DeeplinkStrategy].
///
/// Custom handlers are awaited. Use [CoordinatorMutatable.pushSilently] when a
/// handler needs push semantics but should complete as soon as the route commits.
typedef CoordinatorDeeplinkHandler<T extends RouteUri> =
    FutureOr<void> Function(CoordinatorRecoverable<T> coordinator, T route);

/// Mixin for coordinators that recover navigation state from deep links.
///
/// Requires both [CoordinatorNavigatable] and [CoordinatorMutatable].
/// Override strategy behaviour via [defineDeeplinkHandler].
mixin CoordinatorRecoverable<T extends RouteUri>
    on CoordinatorNavigatable<T>, CoordinatorMutatable<T> {
  final Map<DeeplinkStrategy, CoordinatorDeeplinkHandler<T>> _deeplinkHandlers =
      {};

  /// Registers or overrides the handler for [strategy].
  ///
  /// Registered handlers are awaited by [recover], so asynchronous work and
  /// failures are propagated to the caller. A handler that needs a route result
  /// may await [push]; a handler that only needs navigation completion should
  /// await [pushSilently].
  ///
  /// Built-in defaults:
  /// - [DeeplinkStrategy.navigate] → [navigate]
  /// - [DeeplinkStrategy.push] → [push]
  /// - [DeeplinkStrategy.replace] → [replace]
  ///
  /// [DeeplinkStrategy.custom] always uses [RouteDeepLink.deeplinkHandler] on
  /// the target route; registering a handler for `custom` has no effect.
  void defineDeeplinkHandler(
    DeeplinkStrategy strategy,
    CoordinatorDeeplinkHandler<T> handler,
  ) {
    assert(
      strategy != DeeplinkStrategy.custom,
      'DeeplinkStrategy.custom always uses RouteDeepLink.deeplinkHandler; '
      'defineDeeplinkHandler(custom, ...) has no effect.',
    );
    _deeplinkHandlers[strategy] = handler;
  }

  CoordinatorDeeplinkHandler<T> _defaultDeeplinkHandler(
    DeeplinkStrategy strategy,
  ) => switch (strategy) {
    DeeplinkStrategy.navigate => (c, r) => c.navigate(r),
    DeeplinkStrategy.push => (c, r) => c.pushSilently(r),
    DeeplinkStrategy.replace => (c, r) => c.replace(r),
    DeeplinkStrategy.custom => (c, r) => c.replace(r),
  };

  Future<void> _handleDeeplinkStrategy(
    DeeplinkStrategy strategy,
    T target,
  ) async {
    final handler = _deeplinkHandlers[strategy];
    if (handler != null) {
      await handler(this, target);
      return;
    }

    await _defaultDeeplinkHandler(strategy)(this, target);
  }

  /// Recovers navigation state from a route, respecting [RouteDeepLink] strategy.
  ///
  /// Completes after the selected navigation strategy has committed. It never
  /// waits for the recovered route to be popped.
  Future<void> recover(T route) async {
    T? target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    if (target case RouteDeepLink(
      :final deeplinkStrategy,
      :final deeplinkHandler,
      :final identifier,
    )) {
      switch (deeplinkStrategy) {
        case DeeplinkStrategy.custom:
          await deeplinkHandler(this, identifier);
        case DeeplinkStrategy.navigate:
        case DeeplinkStrategy.push:
        case DeeplinkStrategy.replace:
          await _handleDeeplinkStrategy(deeplinkStrategy, target);
      }
    } else {
      await _handleDeeplinkStrategy(DeeplinkStrategy.replace, target);
    }
  }

  /// Parses [uri] via [parseRouteFromUri] then calls [recover].
  ///
  /// Throws [StateError] if [parseRouteFromUri] returns `null`.
  Future<void> recoverRouteFromUri(Uri uri) async {
    final route = await parseRouteFromUri(uri);
    if (route == null) {
      throw StateError(
        'If you want to use coordinator deeplink feature, you must return '
        'route from [parseRouteFromUri]',
      );
    }
    return recover(route);
  }
}
