/// # The Road Not Found
///
/// When a traveler ventures to an unknown destination, we must guide
/// them gracefully back to familiar ground. This route handles all
/// URIs that do not match our defined paths.
library;

import 'package:flutter/material.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';

/// A route for paths that lead nowhere - yet.
///
/// Every good application must handle the unexpected with grace.
/// When a user types an invalid URL or follows a broken link,
/// they should not be met with confusion, but with helpful guidance.
class NotFoundRoute extends DocsRoute {
  NotFoundRoute({required this.uri, this.queries = const {}});

  /// The URI that was attempted
  final Uri uri;

  /// Any query parameters that accompanied the request
  final Map<String, String> queries;

  @override
  List<Object?> get props => [uri, queries];

  @override
  Uri toUri() => uri;

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_off,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text('Page Not Found', style: theme.textTheme.displaySmall),
              const SizedBox(height: 16),
              Text(
                'The path "${uri.path}" does not lead anywhere we know.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Perhaps it once did, or perhaps it shall in the future.\nFor now, let us return to familiar ground.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => coordinator.replaceIndex(),
                icon: const Icon(Icons.home),
                label: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
