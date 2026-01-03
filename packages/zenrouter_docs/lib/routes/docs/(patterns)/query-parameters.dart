/// # Query Parameters
///
/// The question mark in your URL: `/search?q=flutter&page=2`.
/// How to read them, update them, and react to their changes.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'query-parameters.g.dart';

/// The Query Parameters documentation page.
///
/// Note: We enable queries here as a workaround - the generator expects it
/// based on the route name pattern. This demonstrates the feature in action.
@ZenRoute(queries: ['*'])
class QueryParametersRoute extends _$QueryParametersRoute {
  QueryParametersRoute({super.queries = const {}});

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Query Parameters', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Reactive URL State',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
Query parameters are the key-value pairs after the question mark in a URL: `/search?q=flutter&sort=recent&page=2`. They're useful for state that should be shareable via URL but doesn't warrant a separate route.

ZenRouter provides first-class support for query parameters, including reactive updates that rebuild only the widgets that depend on changed parameters.
''',
          ),
          const SizedBox(height: 32),

          Text(
            'Enabling Query Parameters',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
When using zenrouter_file_generator, you enable query parameter support through the `@ZenRoute` annotation. You can enable all parameters with `['*']` or specify which parameters your route cares about.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Enabling Queries',
            code: '''
// Enable specific parameters
@ZenRoute(queries: ['q', 'sort', 'page'])
class SearchRoute extends _\$SearchRoute {
  // ...
}

// Enable all parameters
@ZenRoute(queries: ['*'])
class FlexibleRoute extends _\$FlexibleRoute {
  // ...
}''',
          ),
          const SizedBox(height: 32),

          Text(
            'Reading Query Parameters',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Routes with query support receive a `queries` map that you can access directly. For reactive updates, use `selectorBuilder` which rebuilds only when the selected value changes.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Reactive Query Access',
            code: '''
@ZenRoute(queries: ['q', 'page', 'sort'])
class SearchRoute extends _\$SearchRoute {
  @override
  Widget build(DocsCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This rebuilds only when 'q' changes
        title: selectorBuilder<String>(
          selector: (queries) => queries['q'] ?? '',
          builder: (context, searchTerm) {
            return Text('Search: \$searchTerm');
          },
        ),
      ),
      body: Column(
        children: [
          // This rebuilds only when 'sort' changes
          selectorBuilder<String>(
            selector: (queries) => queries['sort'] ?? 'recent',
            builder: (context, sortOrder) {
              return SortDropdown(
                value: sortOrder,
                onChanged: (value) => updateQueries(
                  coordinator,
                  queries: {...queries, 'sort': value},
                ),
              );
            },
          ),
          
          // Search results - rebuilds when q or sort changes
          Expanded(
            child: selectorBuilder<(String, String)>(
              selector: (q) => (q['q'] ?? '', q['sort'] ?? 'recent'),
              builder: (context, params) {
                final (query, sort) = params;
                return SearchResults(query: query, sort: sort);
              },
            ),
          ),
        ],
      ),
    );
  }
}''',
          ),
          const SizedBox(height: 32),

          Text(
            'Updating Query Parameters',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Use `updateQueries` to change query parameters without a full navigation. The URL updates, listeners are notified, and only the affected widgets rebuild.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Updating Queries',
            code: '''
// Update a single parameter
updateQueries(
  coordinator,
  queries: {...queries, 'page': '2'},
);

// Update multiple parameters
updateQueries(
  coordinator,
  queries: {
    ...queries,
    'q': 'new search',
    'page': '1',  // Reset to page 1 on new search
  },
);

// Remove a parameter
final newQueries = Map.of(queries)..remove('sort');
updateQueries(coordinator, queries: newQueries);

// Clear all parameters
updateQueries(coordinator, queries: {});''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'Query parameters are ideal for filter/sort/search state - values that should be shareable and bookmarkable but that don\'t represent fundamentally different screens. When in doubt, ask: "Should this state be lost when the user navigates away?" If yes, use widget state. If no, consider query parameters.',
          ),
          const SizedBox(height: 48),

          // Continue to file routing section
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: InkWell(
              onTap: () => coordinator.pushGettingStarted(),
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
                            'Continue to File-Based Routing',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Learn how zenrouter_file_generator eliminates boilerplate.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.arrow_forward,
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
}
