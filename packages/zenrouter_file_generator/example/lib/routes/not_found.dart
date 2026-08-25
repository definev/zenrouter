import 'package:flutter/material.dart';

import 'routes.zen.dart';

/// Custom NotFoundRoute example.
///
/// To use a custom NotFoundRoute:
/// 1. Create a file named `not_found.dart` in your `lib/routes/` directory
/// 2. Create a class named `NotFoundRoute` that extends `AppRoute`
/// 3. Implement the required constructor: `NotFoundRoute({required this.uri, this.queries = const {}})`
/// 4. Implement the required methods: `toUri()`, `props`, and `build()`
///
/// The generator will automatically detect and use your custom NotFoundRoute
/// instead of generating the default one.
class NotFoundRoute extends AppRoute {
  final Uri uri;
  final Map<String, String> queries;

  NotFoundRoute({required this.uri, this.queries = const {}});

  /// Get a query parameter by name.
  /// Returns null if the parameter is not present.
  String? query(String name) => queries[name];

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  List<Object?> get props => [uri, queries];

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('404 - Page Not Found'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Oops! Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The route "${uri.path}" does not exist.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => coordinator.recoverUri(Uri.parse('/')),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
