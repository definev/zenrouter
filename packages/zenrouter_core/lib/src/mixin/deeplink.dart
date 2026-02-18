import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/uri.dart';

/// Strategy for handling deep links.
///
/// - [replace]: Replace the current navigation stack (default)
/// - [navigate]: Navigate to the route (Go to route if exists, else push to top)
/// - [push]: Push onto the existing navigation stack
/// - [custom]: Custom strategy for handling deep links
enum DeeplinkStrategy { replace, navigate, push, custom }

mixin RouteDeepLink on RouteUri {
  /// The strategy to use when handling this deep link.
  DeeplinkStrategy get deeplinkStrategy;

  // coverage:ignore-start
  /// Custom handler for deep links.
  ///
  /// This is called when [deeplinkStrategy] is [DeeplinkStrategy.custom].
  FutureOr<void> deeplinkHandler(
    covariant CoordinatorCore coordinator,
    Uri uri,
  ) => null;
  // coverage:ignore-end
}
