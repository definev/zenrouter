/// # The Coordinator Pattern
///
/// At last we arrive at the heart of ZenRouter: the Coordinator.
/// Here, imperative simplicity meets declarative elegance, and both
/// gain the power to speak the language of URLs.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'coordinator.g.dart';

/// The Coordinator Pattern documentation page.
@ZenRoute()
class CoordinatorRoute extends _$CoordinatorRoute with RouteSeo, RouteToc {
  @override
  String get title => 'The Coordinator Pattern';

  @override
  String get description => 'URI-Aware Navigation for the Modern Age';

  @override
  String get keywords => 'Coordinator, Deep Linking, URLs, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'The Coordinator Pattern',
      subtitle: 'URI-Aware Navigation for the Modern Age',
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown: '''
The web was built on URLs. Every resource has an address; every address can be shared, bookmarked, or deep-linked. Mobile apps, for the most part, abandoned this - and then slowly realized what they had lost.

Deep linking. Universal links. Web support. State restoration. All of these require that your app understand URLs - that it can translate a URI into a navigation state and vice versa.

The Coordinator pattern provides this capability. It sits at the center of your app's navigation, parsing incoming URIs, managing multiple navigation paths, and ensuring that the URL bar (on web) always reflects the current state.

## Anatomy of a Coordinator

A Coordinator is a class that extends `Coordinator<YourRouteType>`. At minimum, you must implement one method: `parseRouteFromUri`, which takes a URI and returns a route.

```dart
// First, define your route base class with RouteUnique
abstract class AppRoute extends RouteTarget with RouteUnique {}

// Then, create your coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // Pattern matching on path segments
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['about'] => AboutRoute(),
      ['profile', final id] => ProfileRoute(id: id),
      ['settings'] => SettingsRoute(),
      _ => NotFoundRoute(uri: uri),
    };
  }
}
```

## Routes with RouteUnique

Unlike routes in the imperative paradigm, Coordinator routes must know their URI. The RouteUnique mixin requires you to implement `toUri()`, allowing the Coordinator to update the URL when navigation changes.

```dart
class ProfileRoute extends AppRoute {
  ProfileRoute({required this.id});
  
  final String id;
  
  // Required: How does this route look as a URI?
  @override
  Uri toUri() => Uri.parse('/profile/\$id');
  
  // Required for routes with parameters:
  // Define equality based on significant values
  @override
  List<Object?> get props => [id];
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return ProfileScreen(userId: id);
  }
}
```

## Integration with MaterialApp

The Coordinator provides a `routerDelegate` and `routeInformationParser` that plug directly into Flutter's Router system via `MaterialApp.router`.

```dart
final coordinator = AppCoordinator();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// Now you can navigate:
coordinator.push(ProfileRoute(id: 'user-123'));
coordinator.pop();
coordinator.replace(HomeRoute());

// And handle deep links:
// Opening myapp://profile/user-456 will automatically
// parse and navigate to ProfileRoute(id: 'user-456')
```

> This documentation app uses the Coordinator pattern. Right now, your browser's URL bar (if you're on web) shows the path to this page. You could share that URL, and anyone opening it would arrive exactly here.

## Multiple Navigation Paths

Real apps often have nested navigation: a bottom tab bar with independent stacks, a drawer with a separate navigation context, nested tabs within tabs. The Coordinator supports this through multiple StackPaths.

Each path is a separate navigation stack. Routes declare which path they belong to via the `layout` property, and the Coordinator routes pushes to the appropriate stack.

We explore this in depth in the Layouts documentation.
''',
    );
  }
}
