/// # Getting Started with File-Based Routing
///
/// Your file structure becomes your route structure. No more
/// maintaining route lists - just create files and run build_runner.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'getting-started.g.dart';

/// The Getting Started documentation page for file-based routing.
@ZenRoute()
class GettingStartedRoute extends _$GettingStartedRoute
    with RouteSeo, RouteToc {
  @override
  String get title => 'Getting Started';

  @override
  String get description => 'File = Route';

  @override
  String get keywords => 'File-Based Routing, Getting Started, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Getting Started',
      subtitle: 'File = Route',
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown: '''
The zenrouter_file_generator package brings file-based routing to Flutter - a pattern popularized by Next.js, Nuxt, and Expo Router. Instead of maintaining route lists and parsing logic manually, you create files and let the generator do the rest.

This documentation app is itself built with file-based routing. The file you're reading exists at `lib/routes/docs/file-routing/getting-started.dart`, which automatically creates the `/docs/file-routing/getting-started` URL you see in your browser.

## Installation

```yaml
# pubspec.yaml
dependencies:
  zenrouter: ^0.4.10
  zenrouter_file_annotation: ^0.4.9

dev_dependencies:
  build_runner: ^2.10.4
  zenrouter_file_generator: ^0.4.9
```

## Project Structure

Create a `routes` directory inside `lib`. Each file becomes a route:

```json
lib/routes/
├── _coordinator.dart    # Optional: configure coordinator name
├── _route.dart          # Optional: custom route base class
├── index.dart           # → /
├── about.dart           # → /about
├── profile/
│   └── [id].dart        # → /profile/:id
└── settings/
    ├── index.dart       # → /settings
    └── account.dart     # → /settings/account
```

## Your First Route

A route file is simple: import the annotation, extend the generated base class, and implement `build`:

```dart
// lib/routes/about.dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part 'about.g.dart';

@ZenRoute()
class AboutRoute extends _\$AboutRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to our app!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.pushIndex(),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Generate the Code

```json
# One-time generation
dart run build_runner build

# Watch mode (regenerates on file changes)
dart run build_runner watch
```

This generates:
- `routes.zen.dart` - Your coordinator with all routes and navigation methods
- `*.g.dart` files - Base classes for each route

The generated coordinator provides type-safe navigation methods like `pushAbout()`, `pushProfileId(id: '123')`, etc.

## Wire Up Your App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'routes/routes.zen.dart';

final coordinator = AppCoordinator();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}
```

> That's it. Create files, run `build_runner`, and you have a fully-functional routing system with deep linking, type-safe navigation, and URL synchronization.
''',
    );
  }
}
