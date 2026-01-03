/// # File Naming Conventions
///
/// The rules that transform file paths into URL paths.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'conventions.g.dart';

/// The Naming Conventions documentation page.
@ZenRoute()
class ConventionsRoute extends _$ConventionsRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Naming Conventions', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'The Rules of the Road',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
File-based routing follows a set of conventions that map file paths to URL paths. Understanding these conventions lets you design your route structure with intention.
''',
          ),
          const SizedBox(height: 32),

          Text('Basic Routes', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          _buildConventionTable(context),
          const SizedBox(height: 32),

          Text('The index.dart Pattern', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A file named `index.dart` represents the route at its directory level. This lets you have both `/settings` (from `settings/index.dart`) and `/settings/account` (from `settings/account.dart`).
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Index Routes',
            language: 'bash',
            code: '''
routes/
├── settings/
│   ├── index.dart      # → /settings
│   ├── account.dart    # → /settings/account
│   └── privacy.dart    # → /settings/privacy
└── about.dart          # → /about''',
          ),
          const SizedBox(height: 32),

          Text('Route Groups: (name)', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Folders wrapped in parentheses create "route groups". They provide shared layouts without adding to the URL path. This documentation uses route groups extensively.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Route Groups',
            language: 'bash',
            code: '''
routes/
├── (auth)/              # Route group - no URL segment
│   ├── _layout.dart     # Shared layout for auth pages
│   ├── login.dart       # → /login (NOT /(auth)/login)
│   └── register.dart    # → /register
├── (marketing)/
│   ├── _layout.dart     # Different layout
│   ├── pricing.dart     # → /pricing
│   └── features.dart    # → /features
└── dashboard.dart       # → /dashboard''',
          ),
          const SizedBox(height: 32),

          Text(
            'Layout Files: _layout.dart',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A `_layout.dart` file defines a wrapper for all routes in its directory (and subdirectories). Use it for shared UI like navigation bars, sidebars, or common scaffolding.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Layout Definition',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          Text(
            'Private Files: _name.dart',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Files starting with underscore are private - they don't become routes. Use them for:
- `_layout.dart` - Layout definitions
- `_coordinator.dart` - Coordinator configuration  
- `_route.dart` - Custom route base class
- Any shared utilities

The generator ignores these files when creating routes.
''',
          ),
          const SizedBox(height: 32),

          Text('Dot Notation', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
You can use dots in file names to represent nesting without creating directories. This flattens your file structure for deep paths.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Dot Notation',
            language: 'bash',
            code: '''
# These are equivalent:

# Directory approach
routes/shop/products/reviews.dart    # → /shop/products/reviews

# Dot notation approach
routes/shop.products.reviews.dart    # → /shop/products/reviews

# Useful for:
routes/settings.account.index.dart   # → /settings/account
routes/blog.[...slugs].dart          # → /blog/* (catch-all)''',
          ),
          const SizedBox(height: 48),

          _buildNextPageCard(context, coordinator),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildConventionTable(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        columns: const [
          DataColumn(label: Text('Pattern')),
          DataColumn(label: Text('URL')),
          DataColumn(label: Text('Description')),
        ],
        rows: const [
          DataRow(
            cells: [
              DataCell(Text('index.dart')),
              DataCell(Text('/path')),
              DataCell(Text('Route at directory level')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('about.dart')),
              DataCell(Text('/path/about')),
              DataCell(Text('Named route')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('[id].dart')),
              DataCell(Text('/path/:id')),
              DataCell(Text('Dynamic parameter')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('[...slugs].dart')),
              DataCell(Text('/path/*')),
              DataCell(Text('Catch-all parameter')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('_layout.dart')),
              DataCell(Text('-')),
              DataCell(Text('Layout wrapper')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('_*.dart')),
              DataCell(Text('-')),
              DataCell(Text('Private file (ignored)')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('(group)/')),
              DataCell(Text('-')),
              DataCell(Text('Route group (no URL segment)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextPageCard(BuildContext context, DocsCoordinator coordinator) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => coordinator.pushDynamicRoutes(),
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
                      'Next: Dynamic Routes',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parameters, catch-all routes, and typed values',
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
