import 'package:zenrouter_core/src/mixin/target.dart';

/// Mixin that provides route identification capability.
///
/// This mixin gives routes a unique identifier that represents them in the
/// navigation system. The identifier type [T] determines how the route is
/// represented:
///
/// - [Uri]: Used by [RouteUri] for URL-based routing and deep linking
/// - [String]: Can be used for simpler in-app route identification
/// - Custom types: Support for app-specific routing schemes
///
/// ## Role in Navigation Flow
///
/// The identifier is used throughout the navigation system:
/// - [CoordinatorCore.currentUri] returns the active route's identifier
/// - Deep link parsing converts URLs to route identifiers
/// - Stack operations use identifiers to locate routes
///
/// Routes typically use [RouteUri] which implements this mixin with [Uri]
/// as the identifier type, enabling web URL synchronization.
mixin RouteIdentity<T> on RouteTarget {
  /// The unique identifier for this route.
  ///
  /// This identifier represents the route in the navigation system and is
  /// used for deep linking, URL synchronization, and stack operations.
  T get identifier;
}
