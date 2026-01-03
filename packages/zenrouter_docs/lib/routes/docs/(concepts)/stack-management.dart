/// # Stack Management
///
/// The operations that move us through our application: push, pop,
/// replace, and the subtleties that distinguish them.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'stack-management.g.dart';

/// The Stack Management documentation page.
@ZenRoute()
class StackManagementRoute extends _$StackManagementRoute with RouteSeo {
  @override
  String get description => 'Orchestrating the Navigation Stack';

  @override
  String get keywords => 'Stack Management, Coordinator, Flutter';

  @override
  String get title => 'Stack Management';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Stack Management',
      subtitle: 'Orchestrating the Navigation Stack',
      tocController: tocController,
      markdown: '''
Navigation, at its core, is stack manipulation. We push routes to go forward, pop them to go back, and occasionally replace the entire stack when the user's context changes fundamentally (like after logging in or out).

The Coordinator provides several methods for stack manipulation, each with distinct semantics and use cases.

## push: Adding a Route

`push` adds a route to the top of the appropriate stack. It returns a `Future` that completes when that route is eventually popped, allowing you to receive results from child routes.

```dart
// Simple push
coordinator.push(ProfileRoute(userId: '123'));

// Push with result
final result = await coordinator.push(EditProfileRoute());
if (result == true) {
  // User saved changes
  showSnackbar('Profile updated!');
}

// In EditProfileRoute:
coordinator.pop(true);  // Pop with result
```

## pop: Removing Routes

`pop` removes the topmost route from the nearest dynamic path. You can optionally pass a result value that will be delivered to whoever pushed the route.

There's also `popTo`, which pops routes until a specific route is reached.

```dart
// Pop the top route
coordinator.pop();

// Pop with a result
coordinator.pop('success');
coordinator.pop({'saved': true});

// Pop until reaching a specific route
coordinator.popTo(HomeRoute());

// Programmatic back button
// (respects guards, see Patterns section)
coordinator.maybePop();
```

## replace: Resetting Context

`replace` clears the stack and pushes a new route. This is appropriate when the user's context changes fundamentally - after authentication, for instance.

```dart
// After successful login
void onLoginSuccess() {
  // Clear the auth flow, start fresh at home
  coordinator.replace(HomeRoute());
}

// After logout
void onLogout() {
  // Clear everything, show login
  coordinator.replace(LoginRoute());
}

// Replace doesn't trigger pop animations
// - good for context switches
// - not good for "going back"
```

## recover: Deep Link Handling

`recoverRouteFromUri` handles deep links. It parses a URI, constructs the navigation stack, and navigates to the target. This is what gets called when your app receives an external deep link.

The difference from `push` is that `recover` may reconstruct the entire navigation hierarchy to reach the target, ensuring that back navigation makes sense.

```dart
// When app receives deep link: myapp://profile/user-123
void handleDeepLink(Uri uri) {
  coordinator.recoverRouteFromUri(uri);
}

// The coordinator:
// 1. Parses the URI → ProfileRoute(userId: 'user-123')
// 2. Checks if route has custom deeplink handler
// 3. If not, builds appropriate navigation stack
// 4. Navigates to the route

// You can also recover programmatically
coordinator.recoverRouteFromUri(
  Uri.parse('/shop/product/abc123'),
);
```

## pushOrMoveToTop

Sometimes you want to navigate to a route that might already be in the stack. `pushOrMoveToTop` checks if an equal route exists in the stack; if so, it brings that route to the top. If not, it pushes the new route.

```dart
// User taps "Profile" multiple times
coordinator.pushOrMoveToTop(ProfileRoute(userId: '123'));
// First tap: pushes ProfileRoute
// Second tap: no-op (already on top)
// Tap from elsewhere: moves ProfileRoute to top

// Useful for:
// - Tab bar navigation
// - Toolbar shortcuts
// - Notifications that may be tapped multiple times
```
''',
    );
  }
}
