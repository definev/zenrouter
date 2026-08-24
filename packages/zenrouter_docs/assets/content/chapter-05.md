This chapter builds the smallest complete Coordinator application: a home screen, an article screen at `/articles/:id`, reverse URL generation, and a not-found outcome. The example is intentionally small enough to keep every graph seam visible.

## 1. Define route IDs

Route IDs identify manifest nodes. An enum keeps IDs typed in memory; the codec gives them stable wire names when the graph is serialized.

```dart
enum AppRouteId { home, article }
```

## 2. Declare the URI graph

The manifest owns the route patterns. It does not import Flutter widgets.

```dart
final appManifest = RouteManifest<AppRouteId>(
  name: 'compass',
  idCodec: RouteIdCodec.enumValues(AppRouteId.values),
  routes: [
    RouteManifestRoute(
      id: AppRouteId.home,
      path: '/',
    ),
    RouteManifestRoute(
      id: AppRouteId.article,
      path: '/articles/:id',
    ),
  ],
);
```

`:id` matches exactly one decoded path segment. Query parameters are not part of this pattern; they remain available on the matched URI.

## 3. Define typed targets

Create one route base for the application:

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {}
```

The home route has no parameters and uses the manifest for its location:

```dart
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => AppCoordinator.location.home;

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compass')),
      body: ListTile(
        title: const Text('Understanding route graphs'),
        subtitle: const Text('Article 42'),
        onTap: () => coordinator.push(ArticleRoute('42')),
      ),
    );
  }
}
```

The article route carries only the stable ID. Including it in `props` makes route equality reflect the destination value.

```dart
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
  ) {
    return Scaffold(
      appBar: AppBar(title: Text('Article $id')),
      body: ArticleScreen(articleId: id),
    );
  }
}
```

`ArticleScreen` can read a repository or provider using `articleId`. Do not put the loaded article model into the route.

## 4. Preserve unknown locations

Not-found is a route outcome, not a parser exception. Preserve the requested URI so the address bar, analytics, and error screen agree.

```dart
class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute(this.uri);

  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) => Scaffold(
    body: Center(child: Text('No page matches ${uri.path}')),
  );
}
```

## 5. Bind matches to routes

The Coordinator exposes the manifest and creates the complete binding registry:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, AppRouteId> {
  static final manifest = appManifest;

  static final location = AppLocations(manifest);

  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(
        id: AppRouteId.home,
        create: (_) => HomeRoute(),
      ),
      RouteBinding(
        id: AppRouteId.article,
        create: (match) => ArticleRoute(
          match.pathParameters['id']!,
        ),
      ),
    ],
    notFound: NotFoundRoute.new,
  );
}
```

`RouteModuleBinding` implements URI parsing through the registry. Do not add a second `parseRouteFromUri` switch to the same Coordinator.

For a handwritten graph, a tiny location wrapper keeps call sites readable:

```dart
class AppLocations {
  const AppLocations(this.manifest);

  final RouteManifest<AppRouteId> manifest;

  Uri get home => manifest.location(AppRouteId.home);

  Uri article(String id) => manifest.location(
    AppRouteId.article,
    pathParameters: {'id': id},
  );
}
```

The file generator emits an equivalent typed `location` surface automatically.

## 6. Mount the Coordinator

A Coordinator is a Flutter `RouterConfig<Uri>`:

```dart
void main() {
  final coordinator = AppCoordinator();
  runApp(MaterialApp.router(routerConfig: coordinator));
}
```

Open `/articles/42` directly. The manifest matches the pattern, the binding constructs `ArticleRoute('42')`, the root path commits the route, and Flutter builds the article screen.

## 7. Navigate without strings

In-app code uses typed routes or manifest locations:

```dart
await coordinator.push(ArticleRoute('42'));
await coordinator.pushUri(AppCoordinator.location.article('42'));
```

Both forms reach the same target. The first starts with a typed value; the second exercises the URI boundary.

## What happens on `/articles/42`

```text
/articles/42
  → manifest matches AppRouteId.article
  → binding reads id = 42
  → ArticleRoute('42')
  → root NavigationPath mutation
  → navigation commit
  → ArticleScreen(articleId: '42')
  → browser location remains /articles/42
```

## Failure modes

**The route is missing from bindings.** Registry construction fails rather than serving an incomplete graph.

**`props` omits `id`.** `ArticleRoute('41')` and `ArticleRoute('42')` compare equal, which changes `navigate` and declarative retention behavior.

**`toUri()` interpolates a string manually.** The reverse URL can drift from the manifest. Use the location surface.

**The binding loads domain data.** Matching becomes coupled to network state. Construct the route synchronously when possible and let the screen/store load the article.

## Checkpoint

Verify all four contracts:

1. `/` opens `HomeRoute`.
2. `/articles/42` opens `ArticleRoute('42')` directly.
3. `location.article('42')` returns `/articles/42` and matches back to the same ID.
4. `/missing` renders `NotFoundRoute` while preserving `/missing`.

Next, **Navigate without string drift** explains `push`, `navigate`, `replace`, URI operations, results, and commits.
