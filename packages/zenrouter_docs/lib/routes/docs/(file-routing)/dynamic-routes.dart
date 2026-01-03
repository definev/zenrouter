/// # Dynamic Routes
///
/// Parameters in URLs: single segments like `:id` and catch-all
/// segments like `*rest`.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'dynamic-routes.g.dart';

/// The Dynamic Routes documentation page.
@ZenRoute()
class DynamicRoutesRoute extends _$DynamicRoutesRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dynamic Routes', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Parameters and Catch-All Patterns',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
Not every route is static. A user profile needs a user ID. A blog post needs a slug. Documentation might have arbitrary nested paths. Dynamic routes handle these cases with parameters.
''',
          ),
          const SizedBox(height: 32),

          Text(
            'Single-Segment Parameters: [param]',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A file named `[something].dart` creates a route that captures a single path segment. The captured value becomes a parameter on your route class.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'routes/profile/[userId].dart',
            code: '''
@ZenRoute()
class ProfileUserIdRoute extends _\$ProfileUserIdRoute {
  // The parameter is passed via the constructor
  ProfileUserIdRoute({required super.userId});
  
  @override
  Widget build(DocsCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile: \$userId')),
      body: ProfileContent(userId: userId),
    );
  }
}

// Generated navigation:
coordinator.pushProfileUserId(userId: 'user-123');

// URL: /profile/user-123''',
          ),
          const SizedBox(height: 32),

          Text(
            'Catch-All Parameters: [...param]',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A file or folder named `[...something]` captures *all remaining* path segments as a `List<String>`. This is perfect for:
- Documentation with arbitrary nesting: `/docs/getting-started/installation`
- File browsers: `/files/folder/subfolder/file.txt`
- Blog post paths: `/blog/2024/01/my-post-title`
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'routes/docs/[...slugs]/index.dart',
            code: '''
@ZenRoute()
class DocsRoute extends _\$DocsRoute {
  DocsRoute({required super.slugs});  // List<String>
  
  @override
  Widget build(DocsCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Docs: \${slugs.join('/')}'),
      ),
      body: DocumentationContent(path: slugs),
    );
  }
}

// Usage:
coordinator.pushDocs(slugs: ['getting-started', 'installation']);
// URL: /docs/getting-started/installation

coordinator.pushDocs(slugs: ['api', 'coordinator', 'methods']);
// URL: /docs/api/coordinator/methods''',
          ),
          const SizedBox(height: 32),

          Text('Combining Parameters', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
You can have routes inside a catch-all folder, combining catch-all with additional fixed or dynamic segments:
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Complex Route Structure',
            language: 'bash',
            code: '''
routes/docs/
└── [...slugs]/
    ├── index.dart      # /docs/a/b/c (catch-all)
    ├── edit.dart       # /docs/a/b/c/edit
    └── [version].dart  # /docs/a/b/c/v2

# Matched paths:
/docs/api/coordinator         → DocsRoute(slugs: ['api', 'coordinator'])
/docs/api/coordinator/edit    → DocsEditRoute(slugs: ['api', 'coordinator'])
/docs/api/coordinator/v2      → DocsVersionRoute(slugs: ['api', 'coordinator'], version: 'v2')''',
          ),
          const SizedBox(height: 32),

          Text(
            'Generated Pattern Matching',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
The generator creates Dart pattern matching code that handles all these cases. Here's what it produces:
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Generated parseRouteFromUri',
            code: '''
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    // Static routes first (more specific)
    [] => IndexRoute(),
    ['about'] => AboutRoute(),
    
    // Single-segment parameters
    ['profile', final userId] => ProfileUserIdRoute(userId: userId),
    
    // Catch-all with additional segments (more specific first)
    ['docs', ...final slugs, 'edit'] => DocsEditRoute(slugs: slugs),
    ['docs', ...final slugs, final version] => DocsVersionRoute(
      slugs: slugs,
      version: version,
    ),
    
    // Pure catch-all (least specific)
    ['docs', ...final slugs] => DocsRoute(slugs: slugs),
    
    // Fallback
    _ => NotFoundRoute(uri: uri),
  };
}''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'Note the ordering: more specific patterns come before less specific ones. The generator handles this automatically, ensuring `/docs/api/edit` matches the edit route, not the catch-all.',
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
        onTap: () => coordinator.pushDeferredImports(),
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
                      'Next: Deferred Imports',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lazy loading routes for faster startup',
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
