import 'dart:async';

import 'package:zenrouter/zenrouter.dart';

/// A mixin that provides redirection logic for routes.
///
/// `RouteRedirect` allows a route to specify another route to navigate to
/// instead of itself. This is commonly used for:
/// - **Authentication**: Redirecting unauthenticated users to a login page.
/// - **Permissions**: Redirecting users to an "Access Denied" page.
/// - **Aliases**: Mapping old route definitions to new ones.
///
/// When a route with this mixin is resolved by the [Coordinator], it calls
/// [redirect] (or [redirectWith]) to determine the final target. If multiple
/// redirects are chained, they are followed sequentially until a non-redirecting
/// route is reached.
///
/// **Example - Authentication Redirect:**
/// ```dart
/// class ProfileRoute extends RouteTarget with RouteUnique, RouteRedirect<AppRoute> {
///   @override
///   FutureOr<AppRoute?> redirectWith(AppCoordinator coordinator) {
///     // Check authentication state
///     if (!coordinator.authService.isLoggedIn) {
///       return LoginRoute(returnTo: this);
///     }
///     // Return self to stop redirection and navigate here
///     return this;
///   }
/// }
/// ```
///
/// **Example - Chained Redirects:**
/// ```dart
/// class OldDashboardRoute extends RouteTarget with RouteUnique, RouteRedirect<AppRoute> {
///   @override
///   FutureOr<AppRoute?> redirect() => NewDashboardRoute();
/// }
///
/// class NewDashboardRoute extends RouteTarget with RouteUnique, RouteRedirect<AppRoute> {
///   @override
///   FutureOr<AppRoute?> redirect() => this; // Stop here
/// }
/// ```
///
/// **Redirect Resolution Order:**
/// 1. Framework calls [redirectWith] (or [redirect] if no coordinator)
/// 2. If result is `null`, redirection is cancelled (user handled navigation manually)
/// 3. If result is `this`, navigation proceeds to this route
/// 4. If result is another route, process repeats with the new route
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  /// Resolves the final destination route by following any redirects.
  ///
  /// This method is used internally by the framework to find the ultimate [RouteTarget].
  /// It follows the [redirect] chain until it reaches a route that doesn't redirect.
  ///
  /// **Error Handling:**
  /// If any redirect throws an exception, it propagates up to the caller
  /// (typically [Coordinator.push] or [Coordinator.replace]).
  static Future<T?> resolve<T extends RouteTarget>(
    T route,
    Coordinator? coordinator,
  ) async {
    T target = route;
    while (target is RouteRedirect) {
      final redirect = target as RouteRedirect;
      final newTarget = await switch (coordinator) {
        null => redirect.redirect(),
        final coordinator => redirect.redirectWith(coordinator),
      };

      // If redirect returns null, stop redirection and return null so the
      // navigation is cancelled.
      if (newTarget == null) {
        // Discard the target route since it was not used
        target.onDiscard();
        return null;
      }

      // If it redirects to itself, we've found our destination
      if (newTarget == target) break;

      if (newTarget is T) {
        // Discard the target route since it was not used
        target.onDiscard();
        target = newTarget;
      }
    }
    return target;
  }

  // coverage:ignore-start
  /// Defines the redirection target for this route.
  ///
  /// Implement this method to return:
  /// - `null`: Redirect was handled manually by user code (e.g., you called
  ///   [Coordinator.push] yourself). Framework stops and uses original route.
  /// - `this`: Stop here and navigate to this route.
  /// - `anotherRoute`: Continue redirection with the new target.
  ///
  /// **Async Support:**
  /// This method returns [FutureOr], allowing async operations like
  /// checking server state or loading data before determining the target.
  FutureOr<T?> redirect() => this as T?;
  // coverage:ignore-end

  /// Called when the route is being resolved, providing access to the [Coordinator].
  ///
  /// This variant is preferred when redirection logic depends on application state
  /// or services accessible via the coordinator.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// FutureOr<AppRoute?> redirectWith(AppCoordinator coordinator) async {
  ///   final user = await coordinator.userService.getCurrentUser();
  ///   if (user == null) return LoginRoute();
  ///   if (!user.hasPermission('admin')) return AccessDeniedRoute();
  ///   return this;
  /// }
  /// ```
  ///
  /// Default implementation calls [redirect].
  FutureOr<T?> redirectWith(covariant Coordinator coordinator) => redirect();
}
