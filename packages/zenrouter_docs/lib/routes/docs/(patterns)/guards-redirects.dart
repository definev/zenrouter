/// # Guards and Redirects
///
/// Not every navigation should succeed. Sometimes we must ask "are you
/// sure?" and sometimes we must redirect the user elsewhere entirely.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'guards-redirects.g.dart';

/// The Guards and Redirects documentation page.
@ZenRoute()
class GuardsRedirectsRoute extends _$GuardsRedirectsRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guards & Redirects', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Controlling Navigation Flow',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
Sometimes navigation must be conditional. A checkout screen requires authentication. An editor should warn before discarding unsaved changes. A route might need to redirect to another based on application state.

ZenRouter provides two mixins for this: RouteGuard and RouteRedirect.
''',
          ),
          const SizedBox(height: 32),

          Text(
            'RouteGuard: Controlling Exit',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A guard controls whether navigation *away* from a route is allowed. When the user tries to pop (via back button, gesture, or programmatic pop), the guard's `popGuard` method is called. Return `true` to allow the pop, `false` to prevent it.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Unsaved Changes Guard',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          Text(
            'RouteRedirect: Controlling Entry',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A redirect controls whether navigation *to* a route is allowed - and where to go instead. The `redirect` method is called before the route is shown. Return `null` to proceed normally, or return a different route to redirect.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Authentication Redirect',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          Text(
            'File-Based Routing Integration',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
When using zenrouter_file_generator, you enable guards and redirects through the @ZenRoute annotation:
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Annotation-Based Guards',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'Guards and redirects are checked before any transition animation begins. The user never sees a flash of the protected content - the redirect happens before rendering.',
          ),
          const SizedBox(height: 48),

          _buildNextPageCard(context, coordinator),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildNextPageCard(BuildContext context, DocsCoordinator coordinator) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => coordinator.pushDeepLinking(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next: Deep Linking',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Handling external links and custom navigation setup',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
