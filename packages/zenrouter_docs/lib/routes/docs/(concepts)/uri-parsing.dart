/// # URI Parsing
///
/// The transformation at the heart of the Coordinator: turning URLs
/// into routes, and routes back into URLs.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'uri-parsing.g.dart';

/// The URI Parsing documentation page.
@ZenRoute()
class UriParsingRoute extends _$UriParsingRoute with RouteSeo {
  @override
  String get description => 'The Art of Address Translation';

  @override
  String get keywords => 'URI, Parsing, Coordinator, Flutter';

  @override
  String get title => 'URI Parsing';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'URI Parsing',
      subtitle: 'The Art of Address Translation',
      tocController: tocController,
      markdown: '''
A URL is an address - a string of characters that identifies a resource. A route is an object - a Dart class instance that knows how to render itself. The Coordinator must translate between these two representations in both directions.

When a user navigates to a URL (by typing it, clicking a link, or using the browser's back button), the Coordinator parses that URL into a route. When the user pushes a route programmatically, the Coordinator updates the URL to match.

This bidirectional translation is what enables deep linking, browser navigation, and shareable URLs.

## parseRouteFromUri

The `parseRouteFromUri` method is the only abstract method in `Coordinator`. It receives a URI and must return a route. Dart's pattern matching makes this elegant:

```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    // Empty path → home
    [] => HomeRoute(),
    
    // Single segment
    ['about'] => AboutRoute(),
    ['settings'] => SettingsRoute(),
    
    // Path with parameter
    ['profile', final userId] => ProfileRoute(userId: userId),
    ['post', final postId] => PostRoute(postId: postId),
    
    // Nested paths
    ['shop', 'product', final id] => ProductRoute(id: id),
    ['shop', 'cart'] => CartRoute(),
    
    // Catch-all with rest pattern
    ['docs', ...final slugs] => DocsRoute(slugs: slugs),
    
    // Fallback for unknown paths
    _ => NotFoundRoute(uri: uri),
  };
}
```

## toUri: The Reverse Journey

Every route that mixes in `RouteUnique` must implement `toUri()`. This method returns the URI that represents this route. It should be the inverse of `parseRouteFromUri`: if you parse the URI returned by `toUri()`, you should get an equal route back.

```dart
class ProfileRoute extends AppRoute {
  ProfileRoute({required this.userId});
  
  final String userId;
  
  @override
  Uri toUri() => Uri.parse('/profile/\$userId');
  
  @override
  List<Object?> get props => [userId];
}

// The round-trip should work:
final route = ProfileRoute(userId: '123');
final uri = route.toUri();  // /profile/123
final parsed = coordinator.parseRouteFromUri(uri);
assert(route == parsed);  // Should be true!
```

## Query Parameters

URIs can carry query parameters: `/search?q=flutter&page=2`. These are accessible via `uri.queryParameters` in your parsing logic:

```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    ['search'] => SearchRoute(
      query: uri.queryParameters['q'] ?? '',
      page: int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1,
    ),
    // ...
  };
}

class SearchRoute extends AppRoute {
  SearchRoute({required this.query, this.page = 1});
  
  final String query;
  final int page;
  
  @override
  Uri toUri() => Uri(
    path: '/search',
    queryParameters: {
      'q': query,
      if (page > 1) 'page': page.toString(),
    },
  );
  
  @override
  List<Object?> get props => [query, page];
}
```

> The beauty of Dart's pattern matching is that your routing logic reads like a specification. Each case is a rule: "this pattern means this route." There are no hidden conventions, no magic strings buried in annotations.
''',
    );
  }
}
