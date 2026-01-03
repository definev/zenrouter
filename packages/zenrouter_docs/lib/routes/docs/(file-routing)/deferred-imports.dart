/// # Deferred Imports
///
/// Lazy loading routes for improved startup performance - load code
/// only when (and if) the user navigates there.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'deferred-imports.g.dart';

/// The Deferred Imports documentation page.
@ZenRoute()
class DeferredImportsRoute extends _$DeferredImportsRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deferred Imports', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Lazy Loading for Performance',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
Every route in your app contributes to its initial bundle size. For large applications with many routes, this can slow down startup - users wait longer before seeing anything, and on web, they download code they may never execute.

Deferred imports solve this: routes are loaded only when first navigated to. The initial bundle stays lean, and features load on demand.
''',
          ),
          const SizedBox(height: 32),

          Text(
            'Enabling Deferred Imports',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
You can enable deferred imports per-route or globally.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Per-Route Configuration',
            code: '''
// Enable for a specific route
@ZenRoute(deferredImport: true)
class HeavyAdminPanelRoute extends _\$HeavyAdminPanelRoute {
  // This route and its dependencies load only when navigated to
}

// Disable for a critical route (when globally enabled)
@ZenRoute(deferredImport: false)
class HomeRoute extends _\$HomeRoute {
  // Always in initial bundle - no loading delay
}''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'build.yaml (Global Configuration)',
            language: 'yaml',
            code: '''
# Enable deferred imports for all routes by default
targets:
  \$default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: true''',
          ),
          const SizedBox(height: 32),

          Text('Precedence Rules', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
When both per-route and global configuration exist:

1. **Route annotation wins**: Explicit `deferredImport: false` overrides global config
2. **IndexedStack routes are always non-deferred**: Tab routes need to be immediately available for smooth tab switching
3. **Global config applies otherwise**: Routes without explicit annotation use the global setting
''',
          ),
          const SizedBox(height: 32),

          Text('Generated Code', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
With deferred imports, the generator produces async navigation:
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Generated Code with Deferred Imports',
            code: '''
// Generated imports
import 'about.dart' deferred as about;
import 'admin.dart' deferred as admin;
import 'home.dart';  // Non-deferred (explicit or IndexedStack)

// Generated parseRouteFromUri (now async)
@override
Future<AppRoute> parseRouteFromUri(Uri uri) async {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),  // Immediate
    ['about'] => await () async {
      await about.loadLibrary();
      return about.AboutRoute();
    }(),
    ['admin'] => await () async {
      await admin.loadLibrary();
      return admin.AdminPanelRoute();
    }(),
    _ => NotFoundRoute(uri: uri),
  };
}

// Generated navigation (also async)
Future<T?> pushAbout<T extends Object>() async => push(await () async {
  await about.loadLibrary();
  return about.AboutRoute();
}());''',
          ),
          const SizedBox(height: 32),

          Text('Performance Benefits', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          _buildBenchmarkTable(context),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Real-world benchmarks show significant improvements:

**Key Benefits:**
- Initial bundle reduced by ~10-15%
- Faster time-to-interactive for users
- Better caching - unchanged routes don't re-download
- Code splitting happens automatically

**Trade-offs:**
- Slight navigation delay on first visit to deferred routes
- Small increase in total code size (~1-2%)
- Async nature propagates through navigation methods
''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'This documentation app uses deferred imports. Most pages load on-demand, keeping the initial bundle lean. The home page and critical navigation are non-deferred for instant interaction.',
          ),
          const SizedBox(height: 48),

          // Continue to examples
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: InkWell(
              onTap: () =>
                  coordinator.pushExamplesSlug(slug: 'basic-navigation'),
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
                            'Explore Live Examples',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'See these patterns in action with interactive examples.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.play_circle,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildBenchmarkTable(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        columns: const [
          DataColumn(label: Text('Metric')),
          DataColumn(label: Text('Without Deferred')),
          DataColumn(label: Text('With Deferred')),
          DataColumn(label: Text('Change')),
        ],
        rows: [
          DataRow(
            cells: [
              const DataCell(Text('Initial bundle')),
              const DataCell(Text('2,414 KB')),
              const DataCell(Text('2,155 KB')),
              DataCell(
                Text(
                  '-10.7%',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const DataRow(
            cells: [
              DataCell(Text('Total app size')),
              DataCell(Text('2,719 KB')),
              DataCell(Text('2,759 KB')),
              DataCell(Text('+1.5%')),
            ],
          ),
          const DataRow(
            cells: [
              DataCell(Text('Deferred chunks')),
              DataCell(Text('0')),
              DataCell(Text('24')),
              DataCell(Text('-')),
            ],
          ),
        ],
      ),
    );
  }
}
