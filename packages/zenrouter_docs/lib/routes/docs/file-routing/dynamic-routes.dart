/// # Dynamic Routes
///
/// Parameters in URLs: single segments like `:id` and catch-all
/// segments like `*rest`.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'dynamic-routes.g.dart';

/// The Dynamic Routes documentation page.
@ZenRoute()
class DynamicRoutesRoute extends _$DynamicRoutesRoute with RouteSeo, RouteToc {
  @override
  String get title => 'Dynamic Routes';

  @override
  String get description => 'Parameters and Catch-All Patterns';

  @override
  String get keywords => 'Dynamic Routes, Parameters, Catch-All, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Dynamic Routes',
      subtitle: 'Parameters and Catch-All Patterns',
      onTocItemsReady: (items) => tocItems.value = items,
      tocController: tocController,
      markdown: '''
Not every route is static. A user profile needs a user ID. A blog post needs a slug. Documentation might have arbitrary nested paths. Dynamic routes handle these cases with parameters.

## Single-Segment Parameters: [param]

A file named `[something].dart` creates a route that captures a single path segment. The captured value becomes a parameter on your route class.

```dart
// routes/profile/[userId].dart
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

// URL: /profile/user-123
```

## Catch-All Parameters: [...param]

A file or folder named `[...something]` captures *all remaining* path segments as a `List<String>`. This is perfect for:
- Documentation with arbitrary nesting: `/docs/getting-started/installation`
- File browsers: `/files/folder/subfolder/file.txt`
- Blog post paths: `/blog/2024/01/my-post-title`

```dart
// routes/docs/[...slugs]/index.dart
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
// URL: /docs/api/coordinator/methods
```

## Combining Parameters

You can have routes inside a catch-all folder, combining catch-all with additional fixed or dynamic segments:

```json
routes/docs/
└── [...slugs]/
    ├── index.dart      # /docs/a/b/c (catch-all)
    ├── edit.dart       # /docs/a/b/c/edit
    └── [version].dart  # /docs/a/b/c/v2

# Matched paths:
/docs/api/coordinator         → DocsRoute(slugs: ['api', 'coordinator'])
/docs/api/coordinator/edit    → DocsEditRoute(slugs: ['api', 'coordinator'])
/docs/api/coordinator/v2      → DocsVersionRoute(slugs: ['api', 'coordinator'], version: 'v2')
```

## Generated Pattern Matching

The generator creates Dart pattern matching code that handles all these cases. Here's what it produces:

```dart
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
}
```

> Note the ordering: more specific patterns come before less specific ones. The generator handles this automatically, ensuring `/docs/api/edit` matches the edit route, not the catch-all.
''',
    );
  }
}
