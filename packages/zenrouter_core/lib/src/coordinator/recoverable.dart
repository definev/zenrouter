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
    if (strategy == DeeplinkStrategy.custom) {
      assert(
        false,
        'DeeplinkStrategy.custom always uses RouteDeepLink.deeplinkHandler; '
        'defineDeeplinkHandler(custom, ...) has no effect.',
      );
      return;
    }
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
}

/// Location-based convenience operations for a fully capable coordinator.
///
/// Each operation parses [location] into a route before delegating to the
/// corresponding route-based coordinator operation. This keeps locations
/// adapter-neutral while allowing route bindings to perform asynchronous work,
/// including deferred-library loading, before navigation mutates the stack.
extension CoordinatorUriActions<T extends RouteUri>
    on CoordinatorRecoverable<T> {
  Future<T> _requireRouteFromUri(Uri uri) async {
    final route = await parseRouteFromUri(uri);
    if (route == null) {
      throw StateError(
        'Cannot navigate to $uri because [parseRouteFromUri] returned null',
      );
    }
    return route;
  }

  /// Parses [uri] and navigates to the resulting route.
  Future<void> navigateUri(Uri uri) async {
    await navigate(await _requireRouteFromUri(uri));
  }

  /// Parses [uri], pushes the resulting route, and waits for its result.
  Future<R?> pushUri<R extends Object>(Uri uri) async {
    return push<R>(await _requireRouteFromUri(uri));
  }

  /// Parses [uri] and pushes the resulting route without waiting for pop.
  Future<void> pushSilentlyUri(Uri uri) async {
    await pushSilently(await _requireRouteFromUri(uri));
  }

  /// Parses [uri] and replaces the current navigation state with it.
  Future<void> replaceUri(Uri uri) async {
    await replace(await _requireRouteFromUri(uri));
  }

  /// Parses [uri] and recovers it using its deep-link strategy.
  Future<void> recoverUri(Uri uri) async {
    await recover(await _requireRouteFromUri(uri));
  }

  /// Parses [uri] and replaces the current route with the resulting route.
  Future<R?> pushReplacementUri<R extends Object, RO extends Object>(
    Uri uri, {
    RO? result,
  }) async {
    return pushReplacement<R, RO>(
      await _requireRouteFromUri(uri),
      result: result,
    );
  }

  /// Parses [uri] and pushes the route, or moves it to the top if present.
  Future<void> pushOrMoveToTopUri(Uri uri) async {
    await pushOrMoveToTop(await _requireRouteFromUri(uri));
  }
}
