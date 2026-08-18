# Query parameters

`RouteQueryParameters` updates `?page=2` on the current route without
pushing a new screen. It requires `RouteUnique` (already on `AppRoute`).
Selected widgets rebuild; the route instance stays the same; the URL
syncs.

To read query strings only at construction, use
`uri.queryParameters` (or `match.uri.queryParameters` in a binding).

## Usage

### Setup

Mix `RouteQueryParameters` into the route. Change values with
`updateQueries`, not by building a new URI in `toUri()`.

> [!TIP]
> This mixin is designed to be used with a base abstract class (e.g. `AppRoute`) that already implements `RouteTarget` and `RouteUnique`.

```dart
import 'package:zenrouter/zenrouter.dart';

// Example implementation
class CollectionListRoute extends AppRoute with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  CollectionListRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

  // ... other route implementation
}
```

### Listening to Changes

You can listen to changes in query parameters in two ways:

#### 1. Using `selectorBuilder` (Recommended)

The `selectorBuilder` method allows you to select a specific value derived from the query parameters and rebuild only when that value changes.

```dart
@override
Widget build(AppCoordinator coordinator, BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Rebuilds ONLY when 'page' query changes
        selectorBuilder(
          selector: (queries) => int.tryParse(queries['page'] ?? '1') ?? 1,
          builder: (context, page) {
            return Text('Current Page: $page');
          },
        ),
        // Rebuilds ONLY when 'sort' query changes
        selectorBuilder(
          selector: (queries) => queries['sort'] ?? 'asc',
          builder: (context, sortOrder) {
            return Text('Sort Order: $sortOrder');
          },
        ),
      ],
    ),
  );
}
```

#### 2. Using `queryNotifier` directly

You can also use the `queryNotifier` directly with a `ValueListenableBuilder`.

```dart
ValueListenableBuilder(
  valueListenable: queryNotifier,
  builder: (context, queries, child) {
    return Text('All Active Queries: ${queries.keys.join(', ')}');
  },
)
```

### Updating Queries

To update query parameters programmatically, use the `updateQueries` method. This will update the `queryNotifier` (triggering UI rebuilds) and sync the URL.

```dart
// Update 'page' to 2, keeping other existing queries
updateQueries(
  coordinator,
  queries: {...queries, 'page': '2'},
);

// clear all and set 'filter' to 'active'
updateQueries(
  coordinator,
  queries: {'filter': 'active'},
);
```

### Reading Queries

You can strictly access the current query parameters using the `queries` getter or the `query(name)` helper.

```dart
final currentFilter = query('filter'); // Returns String? or null
final allQueries = queries; // Returns Map<String, String>
```

## Complete Example

Here is a complete example of a route that handles pagination and filtering using `RouteQueryParameters`.

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// Assumes AppRoute extends RouteTarget and mixes in RouteUnique
class CollectionListRoute extends AppRoute with RouteQueryParameters {
  
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  CollectionListRoute({Map<String, String> queries = const {}})
      : queryNotifier = ValueNotifier(queries);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection')),
      body: Column(
        children: [
          // Filter Selector
          selectorBuilder(
            selector: (q) => q['filter'] ?? 'all',
            builder: (context, filter) => DropdownButton<String>(
              value: filter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
              ],
              onChanged: (newValue) {
                if (newValue != null) {
                  updateQueries(
                    coordinator, 
                    queries: {...queries, 'filter': newValue}
                  );
                }
              },
            ),
          ),
          
          // Page Display
          selectorBuilder(
            selector: (q) => int.tryParse(q['page'] ?? '1') ?? 1,
            builder: (context, page) => Text('Page $page'),
          ),

          // Pagination Controls
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                   final currentPage = int.tryParse(query('page') ?? '1') ?? 1;
                   if (currentPage > 1) {
                     updateQueries(
                       coordinator,
                       queries: {...queries, 'page': '${currentPage - 1}'}
                     );
                   }
                },
                child: const Text('Prev'),
              ),
              ElevatedButton(
                onPressed: () {
                   final currentPage = int.tryParse(query('page') ?? '1') ?? 1;
                   updateQueries(
                     coordinator,
                     queries: {...queries, 'page': '${currentPage + 1}'}
                   );
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## See also

- [Getting Started](getting-started.md)
- [State restoration](state-restoration.md)
- [URL strategies](../recipes/url-strategies.md)
