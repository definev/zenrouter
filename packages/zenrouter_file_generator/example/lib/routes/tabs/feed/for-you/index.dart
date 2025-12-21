import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part 'index.g.dart';

/// Demonstrates query parameter manipulation using [RouteQueryParameters] mixin.
///
/// This route shows how to:
/// - Use [QuerySelector.select] for fine-grained rebuilds on specific query changes
/// - Update query parameters without triggering navigation
/// - Sync URL with [updateQueries]
@ZenRoute(queries: ['*'])
class ForYouRoute extends _$ForYouRoute {
  ForYouRoute({super.queries = const {}});

  // Helper getters for query parameters
  String get category => query('category') ?? 'all';
  int get page => int.tryParse(query('page') ?? '1') ?? 1;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('For You - Query Demo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current URL display - rebuilds only when queries map changes
              selectorBuilder<String>(
                selector: (q) => toUri().toString(),
                builder: (context, url) => Card(
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
                          url,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category selector - rebuilds only when 'category' changes
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              selectorBuilder<String>(
                selector: (q) => q['category'] ?? 'all',
                builder: (context, selectedCategory) => Wrap(
                  spacing: 8,
                  children: ['all', 'trending', 'new', 'popular'].map((cat) {
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) => updateQueries(
                        coordinator,
                        queries: {...queries, 'category': cat, 'page': '1'},
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Pagination - rebuilds only when 'page' changes
              const Text('Page', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              selectorBuilder<int>(
                selector: (q) => int.tryParse(q['page'] ?? '1') ?? 1,
                builder: (context, currentPage) => Row(
                  children: [
                    IconButton.filled(
                      onPressed: currentPage > 1
                          ? () => updateQueries(
                              coordinator,
                              queries: {
                                ...queries,
                                'page': '${currentPage - 1}',
                              },
                            )
                          : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Page $currentPage',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => updateQueries(
                        coordinator,
                        queries: {...queries, 'page': '${currentPage + 1}'},
                      ),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Clear queries button - static, no listener needed
              OutlinedButton.icon(
                onPressed: () => updateQueries(coordinator, queries: {}),
                icon: const Icon(Icons.clear),
                label: const Text('Clear All Queries'),
              ),
              const SizedBox(height: 24),

              // Show sheet button - static, no listener needed
              ElevatedButton(
                onPressed: () => coordinator.pushForYouSheet(),
                child: const Text('Show Sheet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
