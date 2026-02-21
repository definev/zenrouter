import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

/// Mixin that allows routes to redirect to different destinations.
///
/// When a route with this mixin is navigated to, the coordinator calls
/// [redirectWith] (or [redirect]) to determine the final destination.
/// This enables authentication checks, permission validation, route aliases,
/// and other conditional navigation logic.
///
/// ## Role in Navigation Flow
///
/// Before any route is displayed:
///
/// 1. [CoordinatorCore.resolve] calls [redirectWith] with the coordinator
/// 2. If the result is `null`: Navigation is cancelled
/// 3. If the result is `this`: Navigation proceeds to this route
/// 4. If the result is another route: Resolution repeats with the new target
///
/// This chain continues until a route returns itself or navigation is cancelled.
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  /// Resolves the final destination by following the redirect chain.
  ///
  /// This static method handles the full redirect resolution process:
  /// - Iteratively follows redirects until a non-redirecting route is found
  /// - Calls [redirectWith] if coordinator is available, otherwise [redirect]
  /// - Handles route discarding for redirected-away routes
  static Future<T?> resolve<T extends RouteTarget>(
    T route,
    CoordinatorCore? coordinator,
  ) async {
    T target = route;
    while (target is RouteRedirect) {
      final redirect = target as RouteRedirect;
      final newTarget = await switch (coordinator) {
        null => redirect.redirect(),
        final coordinator => redirect.redirectWith(coordinator),
      };

      if (newTarget == null) {
        target.onDiscard();
        return null;
      }

      if (newTarget == target) break;

      if (newTarget is T) {
        target.onDiscard();
        target = newTarget;
      }
    }
    return target;
  }

  // coverage:ignore-start
  /// Returns the redirect destination for this route.
  ///
  /// Return `this` to proceed with navigation to this route.
  /// Return a different route to redirect to that route instead.
  /// Return `null` to cancel the navigation entirely.
  FutureOr<T> redirect() => this as T;
  // coverage:ignore-end

  /// Returns the redirect destination with coordinator access.
  ///
  /// This variant provides access to the coordinator for checking app state,
  /// services, or other dependencies during redirect resolution.
  ///
  /// Default implementation delegates to [redirect].
  FutureOr<T?> redirectWith(covariant CoordinatorCore coordinator) =>
      redirect();
}
