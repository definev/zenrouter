/// # Layouts
///
/// Nested navigation through the RouteLayout mixin - tab bars within
/// tab bars, drawers with their own stacks, complex hierarchies made manageable.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'layouts.g.dart';

/// The Layouts documentation page.
@ZenRoute()
class LayoutsRoute extends _$LayoutsRoute with RouteSeo, RouteToc {
  @override
  String get title => 'Layouts';

  @override
  String get description => 'Nested Navigation Hierarchies';

  @override
  String get keywords => 'Layouts, Nested Navigation, RouteLayout, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Layouts',
      subtitle: 'Nested Navigation Hierarchies',
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown: '''
Real applications rarely have flat navigation. Consider a typical mobile app: a bottom tab bar with three tabs, each tab having its own navigation stack. When you're deep in the Feed tab and switch to Profile, then back to Feed, you expect to return to where you were.

This is nested navigation, and ZenRouter handles it through the RouteLayout mixin.

## The RouteLayout Mixin

A layout is a route that contains other routes. It wraps child routes with shared UI (like a scaffold with a bottom nav bar) and manages its own navigation path.

```dart
class TabsLayout extends AppRoute with RouteLayout<AppRoute> {
  // Which path does this layout manage?
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) {
    return coordinator.tabsPath;
  }
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    
    return Scaffold(
      // buildPath renders the current child route
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (index) {
          // Push the tab route - coordinator handles the rest
          coordinator.push(path.stack[index]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

## Declaring Path Ownership

Routes declare which layout they belong to via the `layout` getter. When you push such a route, the Coordinator automatically wraps it with its layout and routes it to the correct path.

```dart
// In your coordinator, define the paths:
class AppCoordinator extends Coordinator<AppRoute> {
  late final tabsPath = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'tabs',
    [HomeTabLayout(), SearchTabLayout(), ProfileTabLayout()],
  );
  
  late final homeStack = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'home',
  );
  
  @override
  List<StackPath> get paths => [...super.paths, tabsPath, homeStack];
}

// Routes declare their layout:
class FeedRoute extends AppRoute {
  @override
  Type? get layout => HomeTabLayout;  // Belongs to home tab
  
  // ...
}

class PostDetailRoute extends AppRoute {
  @override
  Type? get layout => HomeTabLayout;  // Also in home tab
  
  // Pushing this from FeedRoute adds it to homeStack,
  // not to the root navigation
}
```

## IndexedStackPath vs NavigationPath

**IndexedStackPath** is for fixed collections where you switch between predefined routes. Tab bars are the classic example: the tabs are known upfront, you just select which one is active.

**NavigationPath** is for dynamic stacks where routes are pushed and popped. A detail screen pushed from a list, a multi-step wizard, a modal flow.

Often, you'll nest these: an IndexedStackPath for your tabs, with each tab containing a NavigationPath for its own push/pop navigation.

> This documentation app uses exactly this pattern. The main navigation is a stack (you can go from home to paradigms to concepts), but within each section, a stack renders the current page while the sidebar shows all available pages.
''',
    );
  }
}
