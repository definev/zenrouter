import 'package:zenrouter/zenrouter.dart';

/// Mixin that enables custom page transitions for routes.
///
/// When mixed into routes, allows each route to define its own transition
/// animation when being pushed or popped from the navigation stack.
///
/// ## Role in Navigation Flow
///
/// Routes with [RouteTransition] participate in navigation by:
/// 1. Returning a [StackTransition] from the [transition] method
/// 2. The [NavigationStack] uses this transition when building pages
/// 3. The transition is applied by Flutter's Navigator when the route is shown
mixin RouteTransition on RouteUnique {
  /// Returns the [StackTransition] for this route.
  StackTransition<T> transition<T extends RouteUnique>(
    covariant CoordinatorCore coordinator,
  );
}
