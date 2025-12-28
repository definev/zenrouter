import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part 'collection.list.g.dart';

/// Demonstrates advanced routing capabilities including dot-notation file naming
/// and reactive query parameter handling.
///
/// This route uses the [RouteQueryParameters] mixin to enable granular rebuilds
/// when specific query parameters change, optimizing performance for complex
/// filter/sort/pagination scenarios.
///
/// File naming convention:
/// `collection.list.dart` automatically maps to the route path `/collection/list`.
@ZenRoute(queries: ['page', 'sortOrder', 'filter'])
class CollectionListRoute extends _$CollectionListRoute {
  CollectionListRoute({super.queries = const {}});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current URL display
            selectorBuilder(
              selector: (value) => value,
              builder: (context, value) => Card(
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
            ),
            // Pagination controls
            const Text(
              'Pagination',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            pageBuilder(
              selector: (page) => int.tryParse(query('page') ?? '1') ?? 1,
              builder: (context, currentPage) => Row(
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
            ),
          ],
        ),
      ), // End of ListenableBuilder
    );
  }
}
