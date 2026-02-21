import 'package:zenrouter/zenrouter.dart';

/// Strategy for controlling page transition animations in the navigator.
///
/// This enum defines how routes animate when pushed or popped from the
/// navigation stack. The strategy is used by [RouteLayout] when building
/// pages to determine the appropriate [PageTransitionsBuilder].
///
/// **Platform Recommendations:**
/// - **Android/Web/Desktop**: Use [material] for consistency with Material Design
/// - **iOS/macOS**: Use [cupertino] for native iOS-style transitions
/// - **Testing/Screenshots**: Use [none] to disable animations
///
/// Example:
/// ```dart
/// @override
/// DefaultTransitionStrategy get transitionStrategy {
///   // Use platform-appropriate transitions
///   if (Platform.isIOS || Platform.isMacOS) {
///     return DefaultTransitionStrategy.cupertino;
///   }
///   return DefaultTransitionStrategy.material;
/// }
/// ```
enum DefaultTransitionStrategy {
  /// Uses Material Design transitions.
  ///
  /// Provides slide-up, fade, and shared-axis transitions typical of
  /// Android applications. This is the default strategy.
  material,

  /// Uses Cupertino (iOS-style) transitions.
  ///
  /// Provides horizontal slide and parallax transitions typical of
  /// iOS applications, including the edge-swipe-to-go-back gesture.
  cupertino,

  /// Disables transition animations.
  ///
  /// Routes appear and disappear instantly without any animation.
  /// Useful for testing, taking screenshots, or when you want to
  /// implement fully custom transitions.
  none,
}

mixin CoordinatorTransitionStrategy<T extends RouteUnique>
    on CoordinatorCore<T> {
  /// The transition strategy for this coordinator.
  ///
  /// Override this getter to customize how page transitions are animated
  /// throughout your navigation stack. The strategy applies to all routes
  /// managed by this coordinator.
  ///
  /// **Default Behavior:**
  /// Returns [DefaultTransitionStrategy.material], which provides Material
  /// Design transitions (slide-up, fade effects).
  ///
  /// **Common Overrides:**
  /// ```dart
  /// // Platform-adaptive transitions
  /// @override
  /// DefaultTransitionStrategy get transitionStrategy {
  ///   return Platform.isIOS
  ///       ? DefaultTransitionStrategy.cupertino
  ///       : DefaultTransitionStrategy.material;
  /// }
  ///
  /// // Disable all transitions
  /// @override
  /// DefaultTransitionStrategy get transitionStrategy =>
  ///     DefaultTransitionStrategy.none;
  /// ```
  ///
  /// **Note:** This strategy is used by [RouteLayout] when constructing
  /// [Page] objects. If you need per-route transition control, consider
  /// implementing custom [RouteTransition] logic on individual routes instead.
  DefaultTransitionStrategy get transitionStrategy =>
      DefaultTransitionStrategy.material;
}
