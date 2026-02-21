import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/redirect.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

/// Result of a redirect rule, determining the next action in the chain.
///
/// This sealed class ensures all possible outcomes are handled:
/// - [StopRedirect]: Navigation is cancelled entirely
/// - [ContinueRedirect]: Processing continues to the next rule
/// - [RedirectTo]: Navigation proceeds to a different route
sealed class RedirectResult<T extends RouteTarget> {
  const RedirectResult();

  /// Cancels navigation entirely - the route will not be displayed.
  ///
  /// Used when access should be denied or conditions are not met.
  const factory RedirectResult.stop() = StopRedirect;

  /// Continues to the next rule in the chain.
  ///
  /// If no more rules exist, the original route proceeds.
  const factory RedirectResult.continueRedirect() = ContinueRedirect;

  /// Redirects to a different route instead of the original.
  ///
  /// The chain stops and navigation proceeds to the specified route.
  const factory RedirectResult.redirectTo(T route) = RedirectTo;
}

/// Result indicating navigation should be cancelled.
class StopRedirect<T extends RouteTarget> extends RedirectResult<T> {
  // coverage:ignore-start
  const StopRedirect();
  // coverage:ignore-end
}

/// Result indicating the next rule should be processed.
class ContinueRedirect<T extends RouteTarget> extends RedirectResult<T> {
  // coverage:ignore-start
  const ContinueRedirect();
  // coverage:ignore-end
}

/// Result indicating navigation to a different route.
class RedirectTo<T extends RouteTarget> extends RedirectResult<T> {
  const RedirectTo(this.route);

  /// The destination route to navigate to.
  final T route;
}

/// Base class for composable redirect logic.
///
/// Redirect rules allow redirect logic to be extracted from routes into
/// reusable, testable components. Rules are executed in order until one
/// stops the chain.
///
/// ## Role in Navigation Flow
///
/// When [CoordinatorCore] navigates to a route with [RouteRedirectRule]:
///
/// 1. It calls [redirectWith] which iterates through all rules
/// 2. Each rule's [redirectResult] is called in sequence
/// 3. Based on the result:
///    - [StopRedirect]: Navigation cancelled, user stays on current screen
///    - [ContinueRedirect]: Next rule processed
///    - [RedirectTo]: Chain stops, navigation proceeds to new route
/// 4. If all rules pass, original route is displayed
///
/// Rules can be composed for complex scenarios: authentication checks,
/// feature flags, permissions, logging, etc.
abstract class RedirectRule<T extends RouteTarget> {
  /// Determines the redirect result for a given route.
  ///
  /// Called during redirect resolution to determine what action should take
  /// place. The coordinator provides access to app state for decisions.
  FutureOr<RedirectResult<T>> redirectResult(
    covariant CoordinatorCore coordinator,
    covariant T route,
  );
}

/// Mixin for routes that use a list of redirect rules.
///
/// Routes with this mixin delegate their redirect logic to a list of
/// [RedirectRule] instances, enabling composable and testable redirect chains.
mixin RouteRedirectRule<T extends RouteTarget> on RouteRedirect<T> {
  /// The list of rules applied to this route, in order.
  ///
  /// Rules are processed sequentially. Earlier rules have higher priority.
  List<RedirectRule> get redirectRules;

  /// Implements [RouteRedirect.redirectWith] by running all rules in sequence.
  ///
  /// Processing stops when any rule returns [StopRedirect] or [RedirectTo].
  /// If all rules return [ContinueRedirect], the original route proceeds.
  @override
  FutureOr<T?> redirectWith(covariant CoordinatorCore coordinator) async {
    for (final rule in redirectRules) {
      final result = await rule.redirectResult(coordinator, this as T);
      switch (result) {
        case StopRedirect():
          return null;
        case ContinueRedirect():
          continue;
        case RedirectTo():
          return result.route as T;
      }
    }
    return this as T;
  }
}
