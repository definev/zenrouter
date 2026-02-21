import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

/// Mixin for routes that can intercept and block pop operations.
///
/// When a user attempts to navigate back (via back button, swipe gesture, or
/// programmatic pop), the coordinator checks each route's guard before allowing
/// the navigation to proceed. This allows routes to implement custom logic such
/// as prompting for confirmation or blocking navigation based on app state.
///
/// ## Role in Navigation Flow
///
/// Guards are checked during:
/// - [NavigationPath.pop] - when user initiates back navigation
/// - [CoordinatorCore.tryPop] - programmatic pop attempts
/// - Browser back button on web platforms
/// - Tab switches in [IndexedStackPath] when leaving a tab
///
/// If any guard returns `false`, the pop operation is aborted and the
/// navigation state remains unchanged.
mixin RouteGuard on RouteTarget {
  // coverage:ignore-start
  /// Called when the route is about to be popped.
  ///
  /// Return `true` to allow the pop operation to proceed, or `false` to block it.
  /// This method can be async to support dialogs or asynchronous validation.
  ///
  /// The actual pop occurs after this method returns. Side effects beyond
  /// showing UI (dialogs) should be avoided as they may execute unexpectedly.
  FutureOr<bool> popGuard() => true;
  // coverage:ignore-end

  /// Called when the route is about to be popped, with access to the coordinator.
  ///
  /// This variant allows routes to check application state through the coordinator
  /// before deciding whether to allow the pop. Use this when the guard logic
  /// depends on external state not available on the route itself.
  ///
  /// The coordinator assertion ensures the route is managed by the correct
  /// coordinator instance, preventing bugs from routes being handled by
  /// the wrong navigation state.
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
