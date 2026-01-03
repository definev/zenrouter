/// # Guards and Redirects
///
/// Not every navigation should succeed. Sometimes we must ask "are you
/// sure?" and sometimes we must redirect the user elsewhere entirely.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'guards-redirects.g.dart';

/// The Guards and Redirects documentation page.
@ZenRoute()
class GuardsRedirectsRoute extends _$GuardsRedirectsRoute with RouteSeo {
  @override
  String get title => 'Guards & Redirects';

  @override
  String get description => 'Controlling Navigation Flow';

  @override
  String get keywords => 'Guards, Redirects, Route Protection, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Guards & Redirects',
      subtitle: 'Controlling Navigation Flow',
      tocController: tocController,
      markdown: '''
Sometimes navigation must be conditional. A checkout screen requires authentication. An editor should warn before discarding unsaved changes. A route might need to redirect to another based on application state.

ZenRouter provides two mixins for this: RouteGuard and RouteRedirect.

## RouteGuard: Controlling Exit

A guard controls whether navigation *away* from a route is allowed. When the user tries to pop (via back button, gesture, or programmatic pop), the guard's `popGuard` method is called. Return `true` to allow the pop, `false` to prevent it.

\`\`\`dart
class EditPostRoute extends AppRoute with RouteGuard {
  bool hasUnsavedChanges = false;
  
  @override
  FutureOr<bool> popGuard() async {
    if (!hasUnsavedChanges) return true;
    
    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}
\`\`\`

## RouteRedirect: Controlling Entry

A redirect controls whether navigation *to* a route is allowed - and where to go instead. The `redirect` method is called before the route is shown. Return `null` to proceed normally, or return a different route to redirect.

\`\`\`dart
class CheckoutRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  FutureOr<AppRoute?> redirect() async {
    final isLoggedIn = await authService.isAuthenticated();
    
    if (!isLoggedIn) {
      // Redirect to login, preserving the intended destination
      return LoginRoute(redirectTo: toUri().toString());
    }
    
    // Proceed normally
    return null;
  }
}

// Multiple conditions
class AdminRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  FutureOr<AppRoute?> redirect() async {
    final user = await authService.currentUser();
    
    if (user == null) {
      return LoginRoute();
    }
    
    if (!user.isAdmin) {
      return UnauthorizedRoute();
    }
    
    return null;  // Proceed to admin panel
  }
}
\`\`\`

## File-Based Routing Integration

When using zenrouter_file_generator, you enable guards and redirects through the @ZenRoute annotation:

\`\`\`dart
@ZenRoute(
  guard: true,     // Enable RouteGuard mixin
  redirect: true,  // Enable RouteRedirect mixin
)
class CheckoutRoute extends _\$CheckoutRoute {
  @override
  FutureOr<bool> popGuard() async {
    // Your guard logic
  }
  
  @override
  FutureOr<DocsRoute?> redirect() async {
    // Your redirect logic
  }
}
\`\`\`

> Guards and redirects are checked before any transition animation begins. The user never sees a flash of the protected content - the redirect happens before rendering.
''',
    );
  }
}
