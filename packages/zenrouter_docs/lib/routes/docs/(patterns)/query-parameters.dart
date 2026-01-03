/// # Query Parameters
///
/// The question mark in your URL: `/search?q=flutter&page=2`.
/// How to read them, update them, and react to their changes.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'query-parameters.g.dart';

/// The Query Parameters documentation page.
///
/// Note: We enable queries here as a workaround - the generator expects it
/// based on the route name pattern. This demonstrates the feature in action.
@ZenRoute(queries: ['*'])
class QueryParametersRoute extends _$QueryParametersRoute with RouteSeo {
  QueryParametersRoute({super.queries = const {}});

  @override
  String get title => 'Query Parameters';

  @override
  String get description => 'Reactive URL State';

  @override
  String get keywords => 'Query Parameters, URL State, Reactive, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Query Parameters',
      subtitle: 'Reactive URL State',
      tocController: tocController,
      markdown: '''
Query parameters are the key-value pairs after the question mark in a URL: `/search?q=flutter&sort=recent&page=2`. They're useful for state that should be shareable via URL but doesn't warrant a separate route.

ZenRouter provides first-class support for query parameters, including reactive updates that rebuild only the widgets that depend on changed parameters.

## Enabling Query Parameters

When using zenrouter_file_generator, you enable query parameter support through the `@ZenRoute` annotation. You can enable all parameters with `['*']` or specify which parameters your route cares about.

```dart
// Enable specific parameters
@ZenRoute(queries: ['q', 'sort', 'page'])
class SearchRoute extends _\$SearchRoute {
  // ...
}

// Enable all parameters
@ZenRoute(queries: ['*'])
class FlexibleRoute extends _\$FlexibleRoute {
  // ...
}
```

## Reading Query Parameters

Routes with query support receive a `queries` map that you can access directly. For reactive updates, use `selectorBuilder` which rebuilds only when the selected value changes.

```dart
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
}
```

## Updating Query Parameters

Use `updateQueries` to change query parameters without a full navigation. The URL updates, listeners are notified, and only the affected widgets rebuild.

```dart
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
updateQueries(coordinator, queries: {});
```

> Query parameters are ideal for filter/sort/search state - values that should be shareable and bookmarkable but that don't represent fundamentally different screens. When in doubt, ask: "Should this state be lost when the user navigates away?" If yes, use widget state. If no, consider query parameters.
''',
    );
  }
}
