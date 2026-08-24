This chapter builds the mental model you will use to read every later example. The goal is not to memorize class names; it is to know which seam to inspect when a URL, stack, or screen is wrong.

## One destination, several representations

Consider an article at `/articles/42`. The product sees one destination, but the router needs several representations:

```text
manifest node     AppRouteId.article, /articles/:id
match             pathParameters['id'] == '42'
typed target      ArticleRoute(id: '42')
path state        [..., ArticleRoute('42')]
rendered page     ArticleScreen(articleId: '42')
committed URI     /articles/42
```

ZenRouter keeps these representations connected without collapsing them into one object.

## Route targets

A `RouteTarget` is a typed navigation value. It should contain the minimum stable information needed to identify and rebuild a destination.

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {}

class ArticleRoute extends AppRoute {
  ArticleRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => AppCoordinator.location.article(id);

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) => ArticleScreen(articleId: id);
}
```

`RouteUnique` provides URI identity for Coordinator routes. Equality comes from `props`. Keep loaded `Article` objects in a domain store; a route ID survives restarts and deep links, while an in-memory model does not.

## Paths and layouts

A `StackPath` owns navigation state. `NavigationPath` is an ordered mutable stack, `IndexedStackPath` selects one fixed child, and `BranchedStackPath` selects a branch while each branch retains its own stack.

A `RouteLayout` owns how one child path becomes UI. A shell can keep an app bar or navigation rail visible while its child route changes. The route chooses its parent layout; the layout resolves and renders the bound path.

```text
AppShellLayout
└── rootPath
    ├── HomeRoute
    └── ArticleRoute('42')  ← active
```

The layout does not parse URLs, and the manifest does not build widgets.

## Manifest and bindings

The manifest is adapter-neutral topology:

```dart
enum AppRouteId { home, article }

final manifest = RouteManifest<AppRouteId>(
  name: 'compass',
  idCodec: RouteIdCodec.enumValues(AppRouteId.values),
  routes: [
    RouteManifestRoute(id: AppRouteId.home, path: '/'),
    RouteManifestRoute(
      id: AppRouteId.article,
      path: '/articles/:id',
    ),
  ],
);
```

A binding is the Flutter adapter from a successful match to a typed target:

```dart
final bindings = manifest.bind<AppRoute>(
  bindings: [
    RouteBinding(id: AppRouteId.home, create: (_) => HomeRoute()),
    RouteBinding(
      id: AppRouteId.article,
      create: (match) => ArticleRoute(
        match.pathParameters['id']!,
      ),
    ),
  ],
  notFound: NotFoundRoute.new,
);
```

Construction validates duplicate IDs, unknown IDs, layouts bound as leaf routes, and missing bindings. An invalid graph fails early instead of waiting for a user to open the broken link.

## Incoming trace

When the browser opens `/articles/42`, follow this order:

1. The manifest ranks matching patterns and selects `article`.
2. The match exposes `id == '42'`.
3. The binding constructs `ArticleRoute('42')`.
4. Redirects and recovery policy resolve the final target.
5. Layout resolution finds the path that owns the target.
6. The path mutation is published as one navigation commit.
7. `NavigationStack` renders the new page.
8. The route location and browser-history intent are synchronized.

## Reverse trace

Reverse routing starts from the same manifest node:

```dart
final uri = manifest.location(
  AppRouteId.article,
  pathParameters: {'id': '42'},
);
```

The result is `/articles/42`. There is no second string template in the screen and no hand-maintained segment index.

## How to diagnose disagreement

| Symptom | Inspect first |
| --- | --- |
| No route matches a valid-looking URL | Manifest pattern and specificity |
| URL matches but creates the wrong data | Route binding |
| Correct route appears in the wrong shell | Manifest parent and route layout |
| Screen is correct but back goes somewhere surprising | Owning path and history intent |
| Generated location differs from accepted URL | Manifest parameters and codec |
| DevTools graph is empty | Coordinator manifest exposure |

## Checkpoint

Draw your application using only manifest nodes, layouts, and paths. Then trace one incoming URL from match to commit. If every step has one owner, the model is ready for code.

Next, **Install ZenRouter 3** pins the correct prerelease and explains the handwritten and generated setup choices.
