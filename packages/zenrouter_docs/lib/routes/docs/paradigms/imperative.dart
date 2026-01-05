/// # Imperative Navigation
///
/// We begin where Flutter's navigation story began: with direct,
/// imperative control over a stack of routes. Push, pop, replace -
/// commands as clear as placing cards on a deck.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'imperative.g.dart';

/// The Imperative Navigation documentation page.
@ZenRoute()
class ImperativeRoute extends _$ImperativeRoute with RouteSeo, RouteToc {
  @override
  String get title => 'Imperative Navigation';

  @override
  String get description => 'Direct Control Over the Stack';

  @override
  String get keywords => 'Imperative Navigation, NavigationPath, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Imperative Navigation',
      subtitle: 'Direct Control Over the Stack',
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown: '''
In the beginning, there was the stack.

Flutter's original navigation model - what we now call Navigator 1.0 - gave developers direct, imperative control over a stack of routes. When you wished to show a new screen, you pushed it onto the stack. When you wished to dismiss it, you popped it off. The mental model was immediate and intuitive: a deck of cards, with the topmost card visible to the user.

ZenRouter's imperative paradigm preserves this simplicity while adding the structure of typed routes. You define your routes as classes, then manipulate them through a NavigationPath.

## The NavigationPath

A NavigationPath is, conceptually, a typed list of routes with built-in notification when it changes. You create one, optionally give it a default route, and then push and pop to your heart's content.

```dart
// Define your route base class
sealed class AppRoute extends RouteTarget {
  Widget build(BuildContext context);
}

// Create a navigation path
final path = NavigationPath<AppRoute>.create();

// Now you can navigate
path.push(HomeRoute());
path.push(ProfileRoute(userId: '123'));
path.pop();
```

## Rendering with NavigationStack

A NavigationPath holds state; a NavigationStack renders it. The stack listens to the path and rebuilds when routes change, handling transitions between them.

```dart
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
}
```

## When to Use Imperative

The imperative paradigm excels when:

- Your navigation is event-driven - the user taps a button, you respond with a push
- You're building a mobile-only app without deep linking requirements  
- You're migrating from Navigator 1.0 and want a gentle transition
- Your navigation flows are linear and predictable

It struggles when:

- You need deep linking or web URL support
- Your navigation state should be derived from application state
- You need to rebuild complex navigation stacks from a single URL

> The imperative paradigm is not inferior to the others - it is appropriate for different circumstances. Many excellent apps need nothing more.
''',
    );
  }
}
