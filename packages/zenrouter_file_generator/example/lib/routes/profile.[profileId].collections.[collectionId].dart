import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part 'profile.[profileId].collections.[collectionId].g.dart';

/// Demonstrates query parameter manipulation using [RouteQueryParameters] mixin.
///
/// URL: /profile/:profileId/collections/:collectionId?page=1&sort=asc&filter=all
@ZenRoute(queries: ['*'])
class CollectionsCollectionIdRoute extends _$CollectionsCollectionIdRoute {
  CollectionsCollectionIdRoute({
    required super.collectionId,
    required super.profileId,
    super.queries = const {},
  });

  // Helper to get current page (default 1)
  int get currentPage => int.tryParse(query('page') ?? '1') ?? 1;

  // Helper to get current sort order
  String get sortOrder => query('sort') ?? 'asc';

  // Helper to get current filter
  String get filter => query('filter') ?? 'all';

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collection: $collectionId (Profile: $profileId)'),
      ),
      // ValueListenableBuilder rebuilds ONLY when queries change
      // This is more efficient than listening to the entire coordinator
      body: ValueListenableBuilder<Map<String, String>>(
        valueListenable: queryNotifier,
        builder: (context, currentQueries, child) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current URL display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current URL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toUri().toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pagination controls
              const Text(
                'Pagination',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 1
                        ? () => updateQueries(
                            coordinator,
                            queries: {...queries, 'page': '${currentPage - 1}'},
                          )
                        : null,
                    child: const Text('← Prev'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Page $currentPage'),
                  ),
                  ElevatedButton(
                    onPressed: () => updateQueries(
                      coordinator,
                      queries: {...queries, 'page': '${currentPage + 1}'},
                    ),
                    child: const Text('Next →'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sort controls
              const Text(
                'Sort Order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'asc', label: Text('Ascending')),
                  ButtonSegment(value: 'desc', label: Text('Descending')),
                ],
                selected: {sortOrder},
                onSelectionChanged: (selected) => updateQueries(
                  coordinator,
                  queries: {...queries, 'sort': selected.first},
                ),
              ),
              const SizedBox(height: 16),

              // Filter controls
              const Text(
                'Filter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: ['all', 'active', 'archived'].map((f) {
                  return ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    onSelected: (_) => updateQueries(
                      coordinator,
                      queries: {...queries, 'filter': f},
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Clear all queries
              OutlinedButton.icon(
                onPressed: () => updateQueries(coordinator, queries: {}),
                icon: const Icon(Icons.clear),
                label: const Text('Clear All Queries'),
              ),
            ],
          ),
        ),
      ), // End of ListenableBuilder
    );
  }
}
