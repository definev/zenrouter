/// # Routes and Paths
///
/// The fundamental building blocks: what is a Route, what is a Path,
/// and how do they relate to one another?
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'routes-and-paths.g.dart';

/// The Routes and Paths documentation page.
@ZenRoute()
class RoutesAndPathsRoute extends _$RoutesAndPathsRoute with RouteSeo {
  @override
  String get title => 'Routes & Paths';

  @override
  String get description => 'The Fundamental Building Blocks';

  @override
  String get keywords => 'Routes, Paths, Coordinator, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Routes & Paths',
      subtitle: 'The Fundamental Building Blocks',
      tocController: tocController,
      markdown: '''
Before we can navigate, we must understand what we are navigating *between* and what we are navigating *through*.

A Route is a destination - a thing you can go to. It is an object that knows how to build a widget and, optionally, how to express itself as a URI.

A Path is a container for routes - a stack that holds them in order, tracks which is active, and notifies listeners when anything changes.

The relationship is fundamental: routes are nouns, paths are the sentences that arrange them.

## RouteTarget: The Base Class

All routes in ZenRouter extend `RouteTarget`. This base class provides one critical capability: equality through the `props` getter.

When you override `props`, you tell ZenRouter which values define this route's identity. Two routes with the same runtime type and the same props are considered equal.

```dart
class ProfileRoute extends RouteTarget {
  ProfileRoute({required this.userId});
  
  final String userId;
  
  // These values define identity
  @override
  List<Object?> get props => [userId];
}

// These are equal:
ProfileRoute(userId: '123') == ProfileRoute(userId: '123'); // true

// These are not:
ProfileRoute(userId: '123') == ProfileRoute(userId: '456'); // false
```

## StackPath: The Container

A StackPath holds routes and notifies listeners when they change. There are two primary implementations:

**NavigationPath** - A dynamic stack where you can push, pop, and replace routes freely. Think of it as an ArrayList of routes.

**IndexedStackPath** - A fixed collection where you can only change which route is "active". Think of it as a tab bar: the tabs are predetermined, you just select between them.

```dart
final path = NavigationPath<AppRoute>.create();

// Add routes
path.push(HomeRoute());
path.push(ProfileRoute(userId: '123'));

// Remove routes
path.pop();              // Remove the top route
path.pop(HomeRoute());   // Remove specific route

// Replace
path.replace([HomeRoute()]);  // Clear and set new stack

// Query
path.stack;              // List of all routes
path.stack.last;         // Current (top) route
path.isEmpty;            // Is the stack empty?
```

## Why Equality Matters

Equality is not merely academic - it drives several critical behaviors:

1. **Duplicate Prevention**: Pushing a route equal to the current route is a no-op
2. **Declarative Diffing**: The Myers algorithm compares routes by equality to compute changes
3. **Deep Link Resolution**: The Coordinator checks if the parsed route equals the current route
4. **State Preservation**: Widget state is preserved when the route remains equal

If your routes do not implement `props` correctly, you may see routes pushed multiple times, unnecessary rebuilds, or lost widget state.

> A route without proper equality is like a person without a name - technically present, but impossible to address correctly.
''',
    );
  }
}
