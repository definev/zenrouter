import 'package:zenrouter/zenrouter.dart';

/// Mixin for routes that define a custom transition.
mixin RouteTransition on RouteUnique {
  /// Returns the [StackTransition] for this route.
  StackTransition<T> transition<T extends RouteUnique>(
    covariant CoordinatorCore coordinator,
  );
}
