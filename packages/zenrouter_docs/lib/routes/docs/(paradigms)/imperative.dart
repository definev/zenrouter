/// # Imperative Navigation
///
/// We begin where Flutter's navigation story began: with direct,
/// imperative control over a stack of routes. Push, pop, replace -
/// commands as clear as placing cards on a deck.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'imperative.g.dart';

/// The Imperative Navigation documentation page.
@ZenRoute()
class ImperativeRoute extends _$ImperativeRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Imperative Navigation', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Direct Control Over the Stack',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
In the beginning, there was the stack.

Flutter's original navigation model - what we now call Navigator 1.0 - gave developers direct, imperative control over a stack of routes. When you wished to show a new screen, you pushed it onto the stack. When you wished to dismiss it, you popped it off. The mental model was immediate and intuitive: a deck of cards, with the topmost card visible to the user.

ZenRouter's imperative paradigm preserves this simplicity while adding the structure of typed routes. You define your routes as classes, then manipulate them through a NavigationPath.
''',
          ),
          const SizedBox(height: 32),

          Text('The NavigationPath', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A NavigationPath is, conceptually, a typed list of routes with built-in notification when it changes. You create one, optionally give it a default route, and then push and pop to your heart's content.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Creating a NavigationPath',
            code: '''
// Define your route base class
sealed class AppRoute extends RouteTarget {
  Widget build(BuildContext context);
}

// Create a navigation path
final path = NavigationPath<AppRoute>.create();

// Now you can navigate
path.push(HomeRoute());
path.push(ProfileRoute(userId: '123'));
path.pop();''',
          ),
          const SizedBox(height: 32),

          Text(
            'Rendering with NavigationStack',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
A NavigationPath holds state; a NavigationStack renders it. The stack listens to the path and rebuilds when routes change, handling transitions between them.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Using NavigationStack',
            code: '''
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationStack(
        path: path,
        defaultRoute: HomeRoute(),
        resolver: (route) => StackTransition.material(
          route.build(context),
        ),
      ),
    );
  }
}''',
          ),
          const SizedBox(height: 32),

          Text('When to Use Imperative', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
The imperative paradigm excels when:

• Your navigation is event-driven - the user taps a button, you respond with a push
• You're building a mobile-only app without deep linking requirements  
• You're migrating from Navigator 1.0 and want a gentle transition
• Your navigation flows are linear and predictable

It struggles when:

• You need deep linking or web URL support
• Your navigation state should be derived from application state
• You need to rebuild complex navigation stacks from a single URL
''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'The imperative paradigm is not inferior to the others - it is appropriate for different circumstances. Many excellent apps need nothing more.',
          ),
          const SizedBox(height: 48),

          // Navigation to next page
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
        onTap: () => coordinator.pushDeclarative(),
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
                      'Next: Declarative Navigation',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What if the stack were derived from state?',
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
