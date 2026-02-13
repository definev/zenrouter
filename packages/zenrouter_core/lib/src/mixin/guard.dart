import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

/// Mixin for routes that need to guard against being popped.
///
/// Use this mixin to intercept pop operations and conditionally prevent them.
/// Common use cases include:
/// - **Unsaved changes**: Prompt user before losing form data
/// - **Confirmation dialogs**: Require explicit confirmation before leaving
/// - **Async validation**: Check with a server before allowing navigation
///
/// **Example - Confirmation Dialog:**
/// ```dart
/// class EditFormRoute extends RouteTarget with RouteUnique, RouteGuard {
///   bool hasUnsavedChanges = false;
///
///   @override
///   FutureOr<bool> popGuard() async {
///     if (!hasUnsavedChanges) return true;
///
///     // Show confirmation dialog
///     final shouldPop = await showDialog<bool>(
///       context: navigatorContext,
///       builder: (context) => AlertDialog(
///         title: Text('Discard changes?'),
///         content: Text('You have unsaved changes.'),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.pop(context, false),
///             child: Text('Cancel'),
///           ),
///           TextButton(
///             onPressed: () => Navigator.pop(context, true),
///             child: Text('Discard'),
///           ),
///         ],
///       ),
///     );
///     return shouldPop ?? false;
///   }
/// }
/// ```
///
/// **Note:** Guards are consulted during:
/// - [NavigationPath.pop] and [Coordinator.tryPop]
/// - Browser back button navigation
/// - [IndexedStackPath.goToIndexed] when leaving the current tab
mixin RouteGuard on RouteTarget {
  // coverage:ignore-start
  /// Called when the route is about to be popped.
  ///
  /// Return `true` to allow the pop, or `false` to prevent it.
  /// This can be async to show dialogs or perform validation.
  ///
  /// **Important:** This method should not have side effects beyond
  /// showing UI (like dialogs). The actual pop happens after this returns.
  FutureOr<bool> popGuard() => true;
  // coverage:ignore-end

  /// Called when the route is about to be popped, with coordinator access.
  ///
  /// This variant provides access to the [Coordinator] for routes that need
  /// to check application state or access dependencies during the guard check.
  ///
  /// **Coordinator Binding:**
  /// The assertion ensures the route's path was created with the same coordinator
  /// that is handling the navigation. This prevents bugs where routes are
  /// accidentally managed by the wrong coordinator.
  ///
  /// **Example - State-dependent guard:**
  /// ```dart
  /// @override
  /// FutureOr<bool> popGuardWith(AppCoordinator coordinator) async {
  ///   // Access app state through coordinator
  ///   if (coordinator.authState.isLoggingOut) {
  ///     return false; // Prevent navigation during logout
  ///   }
  ///   return popGuard();
  /// }
  /// ```
  FutureOr<bool> popGuardWith(covariant CoordinatorCore coordinator) {
    assert(stackPath?.coordinator == coordinator, '''
[RouteGuard] The path [${stackPath.toString()}] is associated with a different coordinator (or null) than the one currently handling the navigation.
Expected coordinator: $coordinator
Path's coordinator: ${stackPath?.coordinator}
Ensure that the path is created with the correct coordinator using `.createWith()` and that routes are being managed by the correct coordinator.
''');
    return popGuard();
  }
}
