import 'dart:async';

import 'package:zenrouter/zenrouter.dart';

/// Result of a redirect rule that determines what happens next.
///
/// **3 types of results:**
/// - [StopRedirect]: Stop navigation, prevent route from being displayed
/// - [ContinueRedirect]: Continue processing the next rule in the chain
/// - [RedirectTo]: Redirect to a different route instead of the original one
///
/// **Sealed class**: Ensures switch/case handles all possible cases.
///
/// **Example:**
/// ```dart
/// class AuthRule extends RedirectRule<AppRoute> {
///   @override
///   FutureOr<RedirectResult<AppRoute>> redirectResult(
///     Coordinator coordinator,
///     AppRoute route,
///   ) {
///     if (!isAuthenticated) {
///       return RedirectResult.redirectTo(LoginRoute()); // Redirect
///     }
///     return const RedirectResult.continueRedirect(); // Continue
///   }
/// }
/// ```
sealed class RedirectResult<T extends RouteTarget> {
  const RedirectResult();

  /// Create a "stop navigation" result - prevents route from being displayed.
  ///
  /// **When to use:**
  /// - User doesn't have access permission
  /// - Feature is disabled
  /// - Required conditions are not met
  const factory RedirectResult.stop() = StopRedirect;

  /// Create a "continue" result - proceed to the next rule.
  ///
  /// **When to use:**
  /// - Conditions are met, allow continuation
  /// - Rule only does side effects (logging, analytics)
  /// - Need to combine multiple rules
  const factory RedirectResult.continueRedirect() = ContinueRedirect;

  /// Create a "redirect" result - navigate to a different route.
  ///
  /// **When to use:**
  /// - Not logged in → redirect to login
  /// - Permission denied → redirect to error page
  /// - Route deprecated → redirect to new route
  const factory RedirectResult.redirectTo(T route) = RedirectTo;
}

/// Stop navigation result - route will not be displayed.
///
/// Navigation will be cancelled, user stays on the current screen.
class StopRedirect<T extends RouteTarget> extends RedirectResult<T> {
  const StopRedirect();
}

/// Continue result - proceed to the next rule in the chain.
///
/// If this is the last rule, the original route will be displayed.
class ContinueRedirect<T extends RouteTarget> extends RedirectResult<T> {
  const ContinueRedirect();
}

/// Redirect result - replace the original route with a different one.
///
/// The new route will be displayed instead of the original route.
class RedirectTo<T extends RouteTarget> extends RedirectResult<T> {
  const RedirectTo(this.route);

  /// The destination route to redirect to.
  final T route;
}

/// Base class for reusable redirect rules.
///
/// **Benefits of the Rule-based approach:**
/// - **Reusable**: One rule can be used for multiple routes
/// - **Composable**: Chain multiple rules together (auth → feature flag → logging)
/// - **Testable**: Test each rule independently
/// - **Maintainable**: Centralized redirect logic, easy to modify
///
/// **Common rule types:**
/// - Authentication: Check login status
/// - Authorization: Check access permissions
/// - Feature Flags: Check if feature is enabled
/// - Logging/Analytics: Log navigation events
/// - A/B Testing: Redirect based on experiments
///
/// **Example - Authentication Rule:**
/// ```dart
/// class AuthenticationRule extends RedirectRule<AppRoute> {
///   @override
///   FutureOr<RedirectResult<AppRoute>> redirectResult(
///     Coordinator coordinator,
///     AppRoute route,
///   ) {
///     if (!AuthService.isAuthenticated) {
///       // Not logged in → redirect to login page
///       return RedirectResult.redirectTo(LoginRoute());
///     }
///     // Logged in → continue
///     return const RedirectResult.continueRedirect();
///   }
/// }
/// ```
///
/// **Example - Feature Flag Rule:**
/// ```dart
/// class FeatureFlagRule extends RedirectRule<AppRoute> {
///   final String feature;
///   FeatureFlagRule({required this.feature});
///
///   @override
///   FutureOr<RedirectResult<AppRoute>> redirectResult(
///     Coordinator coordinator,
///     AppRoute route,
///   ) async {
///     final isEnabled = await FeatureService.isEnabled(feature);
///     if (!isEnabled) {
///       return RedirectResult.stop(); // Stop navigation
///     }
///     return const RedirectResult.continueRedirect();
///   }
/// }
/// ```
abstract class RedirectRule<T extends RouteTarget> {
  /// Determines the redirect result for a specific route.
  ///
  /// **Parameters:**
  /// - [coordinator]: Access coordinator methods and state
  /// - [route]: Route being navigated to
  ///
  /// **Returns:**
  /// - [StopRedirect]: Stop navigation
  /// - [ContinueRedirect]: Continue to next rule
  /// - [RedirectTo]: Redirect to a different route
  ///
  /// This method can be async to call APIs, read from database, etc.
  FutureOr<RedirectResult<T>> redirectResult(
    covariant Coordinator coordinator,
    covariant T route,
  );
}

/// Mixin that allows a route to use a list of redirect rules.
///
/// **Usage:**
/// ```dart
/// class ProtectedRoute extends AppRoute
///     with RouteRedirect, RouteRedirectRule {
///   @override
///   List<RedirectRule> get redirectRules => [
///         AuthenticationRule(),           // Check login first
///         FeatureFlagRule(feature: 'new'), // Then check feature flag
///         LoggingRule(),                   // Finally log
///       ];
/// }
/// ```
///
/// **Execution order:**
/// Rules are executed in list order. If any rule returns
/// [StopRedirect] or [RedirectTo], subsequent rules won't run.
///
/// **Chain Flow:**
/// ```
/// Rule 1 → ContinueRedirect
///   ↓
/// Rule 2 → ContinueRedirect
///   ↓
/// Rule 3 → RedirectTo(LoginRoute) → STOP, redirect immediately
/// Rule 4 → Never executed
/// ```
mixin RouteRedirectRule<T extends RouteTarget> on RouteRedirect<T> {
  /// List of rules applied to this route.
  ///
  /// **Order matters:**
  /// - Critical rules (auth, permissions) should come first
  /// - Side-effect rules (logging) should come last
  List<RedirectRule> get redirectRules;

  /// Implementation of RouteRedirect.redirectWith() - runs all rules.
  ///
  /// **Processing flow:**
  /// 1. Iterate through each rule in order
  /// 2. Call rule's `redirectResult()`
  /// 3. Handle result:
  ///    - StopRedirect: Return null (cancel navigation)
  ///    - ContinueRedirect: Move to next rule
  ///    - RedirectTo: Return new route (stop chain)
  /// 4. If all rules continue: Return original route
  @override
  FutureOr<T?> redirectWith(covariant Coordinator coordinator) async {
    for (final rule in redirectRules) {
      final result = await rule.redirectResult(coordinator, this as T);
      switch (result) {
        case StopRedirect():
          return null; // Cancel navigation
        case ContinueRedirect():
          continue; // Next rule
        case RedirectTo():
          return result.route as T; // Redirect immediately
      }
    }
    return this as T; // All rules passed → display original route
  }
}
