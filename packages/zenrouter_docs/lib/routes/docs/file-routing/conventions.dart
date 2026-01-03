/// # File Naming Conventions
///
/// The rules that transform file paths into URL paths.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'conventions.g.dart';

/// The Naming Conventions documentation page.
@ZenRoute()
class ConventionsRoute extends _$ConventionsRoute with RouteSeo {
  @override
  String get title => 'Naming Conventions';

  @override
  String get description => 'The Rules of the Road';

  @override
  String get keywords => 'File Naming, Conventions, Route Groups, Layouts';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Naming Conventions',
      subtitle: 'The Rules of the Road',
      tocController: tocController,
      markdown: '''
File-based routing follows a set of conventions that map file paths to URL paths. Understanding these conventions lets you design your route structure with intention.

## Basic Routes

| Pattern | URL | Description |
|---------|-----|-------------|
| `index.dart` | `/path` | Route at directory level |
| `about.dart` | `/path/about` | Named route |
| `[id].dart` | `/path/:id` | Dynamic parameter |
| `[...slugs].dart` | `/path/*` | Catch-all parameter |
| `_layout.dart` | `-` | Layout wrapper |
| `_*.dart` | `-` | Private file (ignored) |
| `(group)/` | `-` | Route group (no URL segment) |

## The index.dart Pattern

A file named `index.dart` represents the route at its directory level. This lets you have both `/settings` (from `settings/index.dart`) and `/settings/account` (from `settings/account.dart`).

```bash
routes/
├── settings/
│   ├── index.dart      # → /settings
│   ├── account.dart    # → /settings/account
│   └── privacy.dart    # → /settings/privacy
└── about.dart          # → /about
```

## Route Groups: (name)

Folders wrapped in parentheses create "route groups". They provide shared layouts without adding to the URL path. This documentation uses route groups extensively.

```bash
routes/
├── (auth)/              # Route group - no URL segment
│   ├── _layout.dart     # Shared layout for auth pages
│   ├── login.dart       # → /login (NOT /(auth)/login)
│   └── register.dart    # → /register
├── (marketing)/
│   ├── _layout.dart     # Different layout
│   ├── pricing.dart     # → /pricing
│   └── features.dart    # → /features
└── dashboard.dart       # → /dashboard
```

## Layout Files: _layout.dart

A `_layout.dart` file defines a wrapper for all routes in its directory (and subdirectories). Use it for shared UI like navigation bars, sidebars, or common scaffolding.

```dart
// routes/tabs/_layout.dart
@ZenLayout(
  type: LayoutType.indexed,  // For tab-like navigation
  routes: [HomeRoute, SearchRoute, ProfileRoute],
)
class TabsLayout extends _\$TabsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    
    return Scaffold(
      body: buildPath(coordinator),  // Renders the current route
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (i) => coordinator.push(path.stack[i]),
        items: const [...],
      ),
    );
  }
}
```

## Private Files: _name.dart

Files starting with underscore are private - they don't become routes. Use them for:
- `_layout.dart` - Layout definitions
- `_coordinator.dart` - Coordinator configuration  
- `_route.dart` - Custom route base class
- Any shared utilities

The generator ignores these files when creating routes.

## Dot Notation

You can use dots in file names to represent nesting without creating directories. This flattens your file structure for deep paths.

```bash
# These are equivalent:

# Directory approach
routes/shop/products/reviews.dart    # → /shop/products/reviews

# Dot notation approach
routes/shop.products.reviews.dart    # → /shop/products/reviews

# Useful for:
routes/settings.account.index.dart   # → /settings/account
routes/blog.[...slugs].dart          # → /blog/* (catch-all)
```
''',
    );
  }
}
