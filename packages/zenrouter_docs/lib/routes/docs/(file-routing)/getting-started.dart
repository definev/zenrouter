/// # Getting Started with File-Based Routing
///
/// Your file structure becomes your route structure. No more
/// maintaining route lists - just create files and run build_runner.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'getting-started.g.dart';

/// The Getting Started documentation page for file-based routing.
@ZenRoute()
class GettingStartedRoute extends _$GettingStartedRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Getting Started', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'File = Route',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
The zenrouter_file_generator package brings file-based routing to Flutter - a pattern popularized by Next.js, Nuxt, and Expo Router. Instead of maintaining route lists and parsing logic manually, you create files and let the generator do the rest.

This documentation app is itself built with file-based routing. The file you're reading exists at `lib/routes/(file-routing)/getting-started.dart`, which automatically creates the `/getting-started` URL you see in your browser.
''',
          ),
          const SizedBox(height: 32),

          Text('Installation', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'pubspec.yaml',
            language: 'yaml',
            code: '''
dependencies:
  zenrouter: ^0.4.10
  zenrouter_file_annotation: ^0.4.9

dev_dependencies:
  build_runner: ^2.10.4
  zenrouter_file_generator: ^0.4.9''',
          ),
          const SizedBox(height: 32),

          Text('Project Structure', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Create a `routes` directory inside `lib`. Each file becomes a route:
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Directory Structure',
            language: 'bash',
            code: '''
lib/routes/
├── _coordinator.dart    # Optional: configure coordinator name
├── _route.dart          # Optional: custom route base class
├── index.dart           # → /
├── about.dart           # → /about
├── profile/
│   └── [id].dart        # → /profile/:id
└── settings/
    ├── index.dart       # → /settings
    └── account.dart     # → /settings/account''',
          ),
          const SizedBox(height: 32),

          Text('Your First Route', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A route file is simple: import the annotation, extend the generated base class, and implement `build`:
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'lib/routes/about.dart',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          Text('Generate the Code', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Terminal',
            language: 'bash',
            code: '''
# One-time generation
dart run build_runner build

# Watch mode (regenerates on file changes)
dart run build_runner watch''',
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
This generates:
- `routes.zen.dart` - Your coordinator with all routes and navigation methods
- `*.g.dart` files - Base classes for each route

The generated coordinator provides type-safe navigation methods like `pushAbout()`, `pushProfileId(id: '123')`, etc.
''',
          ),
          const SizedBox(height: 32),

          Text('Wire Up Your App', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'lib/main.dart',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'That\'s it. Create files, run build_runner, and you have a fully-functional routing system with deep linking, type-safe navigation, and URL synchronization.',
          ),
          const SizedBox(height: 48),

          _buildNextPageCard(context, coordinator),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildNextPageCard(BuildContext context, DocsCoordinator coordinator) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => coordinator.pushConventions(),
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
                      'Next: Naming Conventions',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Understanding file names, route groups, and layouts',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
