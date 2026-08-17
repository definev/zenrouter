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

## Generated Bindings

The manifest owns matching precedence. The generator only binds each route ID
to a constructor:

```dart
@override
late final routeBindings = manifest.bind<AppRoute>(
  bindings: [
    RouteBinding(id: 'IndexRoute', create: (_) => IndexRoute()),
    RouteBinding(id: 'AboutRoute', create: (_) => AboutRoute()),
    RouteBinding(
      id: 'ProfileUserIdRoute',
      create: (match) => ProfileUserIdRoute(
        userId: match.pathParameters['userId']!,
      ),
    ),
    RouteBinding(
      id: 'DocsEditRoute',
      create: (match) => DocsEditRoute(
        slugs: match.restParameters['slugs']!,
      ),
    ),
    RouteBinding(
      id: 'DocsVersionRoute',
      create: (match) => DocsVersionRoute(
        slugs: match.restParameters['slugs']!,
        version: match.pathParameters['version']!,
      ),
    ),
    RouteBinding(
      id: 'DocsRoute',
      create: (match) => DocsRoute(
        slugs: match.restParameters['slugs']!,
      ),
    ),
  ],
  notFound: (uri) => NotFoundRoute(uri: uri),
);
```

> Overlapping patterns are rejected or ordered by specificity when the
> manifest is constructed. `/docs/api/edit` matches the edit route, not the
> catch-all.
''',
    );
  }
}
