A URL is an external contract. It may be copied, bookmarked, indexed, restored, or opened by an older application version. Keep its topology in the manifest so matching and reverse routing use one declaration.

## Path parameters

A named parameter matches one path segment:

```dart
RouteManifestRoute(
  id: AppRouteId.article,
  path: '/articles/:id',
)
```

The binding reads the decoded value:

```dart
RouteBinding(
  id: AppRouteId.article,
  create: (match) => ArticleRoute(
    match.pathParameters['id']!,
  ),
)
```

Reverse routing requires the same parameter name:

```dart
final uri = manifest.location(
  AppRouteId.article,
  pathParameters: {'id': '42'},
);
```

Do not index `uri.pathSegments` in one place and interpolate strings in another. The pattern is the shared contract.

## Catch-all parameters

Use `...:slugs` for zero or more trailing segments:

```dart
RouteManifestRoute(
  id: AppRouteId.docs,
  path: '/docs/...:slugs',
)
```

`/docs`, `/docs/guides`, and `/docs/guides/routing` match the same node. The binding reads `match.restParameters['slugs']` as the captured segments. Catch-alls are useful for content paths, but a specific static route should remain more specific than a broad rest route.

## Query parameters

Query strings represent optional view state rather than route topology:

```text
/articles?sort=newest&page=2
```

Read them during construction through `match.uri.queryParameters`. When a route needs to update query state without replacing its page entry, mix in `RouteQueryParameters`:

```dart
class ArticlesRoute extends AppRoute with RouteQueryParameters {
  ArticlesRoute({Map<String, String> queries = const {}})
      : queryNotifier = ValueNotifier(queries);

  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;
}
```

Update through the mixin so selected widgets and the URL stay synchronized:

```dart
updateQueries(
  coordinator,
  queries: {...queries, 'page': '2'},
);
```

Use path segments for resource identity and queries for optional filters, paging, sorting, or view mode.

## Matching specificity

Static segments should outrank parameters, and parameters should outrank catch-alls. For example, `/products/new` must resolve deterministically beside `/products/:id`.

The manifest validates equally specific ambiguous patterns at graph construction. Do not rely on declaration order to hide an overlap; it creates fragile links when fragments are composed in a different order.

## Not-found as a route

Unknown paths should resolve to a typed not-found target that preserves the requested URI:

```dart
class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute(this.uri);
  final Uri uri;

  @override
  Uri toUri() => uri;
}
```

Provide it to the binding registry:

```dart
final bindings = manifest.bind<AppRoute>(
  bindings: routeBindings,
  notFound: NotFoundRoute.new,
);
```

A 404 is not an exception that wipes the app shell. If the missing location belongs beneath a documentation or account layout, preserve the valid parent context when your graph and recovery policy support it.

## Browser history

Coordinator commits include explicit history intent:

- `push` creates a new history entry;
- `replace` updates the current entry;
- `traverse` applies browser back/forward without authoring another entry.

The final URI is published only after the navigation transaction completes, so the address bar does not expose a half-resolved layout.

## URL test matrix

Test each public pattern in both directions:

| Case | Example | Assert |
| --- | --- | --- |
| Static | `/settings` | exact route ID |
| Parameter | `/articles/42` | decoded `id` |
| Catch-all | `/docs/a/b` | rest segments |
| Query | `/articles?page=2` | query state |
| Encoded value | `/search/flutter%20web` | decoded value and re-encoding |
| Unknown | `/missing` | preserved not-found URI |

For every match, ask the manifest to generate the location and match it again.

## Common mistakes

**Putting query syntax in a path pattern.** Patterns describe paths; read query values from the matched URI.

**Dropping the requested URI on 404.** Analytics, retry actions, and the address bar lose the real failure.

**Using human-readable names as permanent IDs.** Prefer stable IDs and let the screen load mutable display names.

**Treating URL updates as decoration.** The URL is one representation of navigation state and must commit with it.

## Checkpoint

Open a static URL, parameter URL, catch-all URL, query URL, encoded URL, and unknown URL directly. Confirm the typed target, parameters, active layout, browser history, and generated reverse location agree.

Next, **Guards and redirects** adds navigation policy without mixing “may leave” and “may enter.”
