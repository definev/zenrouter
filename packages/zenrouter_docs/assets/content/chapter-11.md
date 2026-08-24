Restoration and deep-link recovery both rebuild navigation, but they begin with different evidence. Restoration replays state saved by the application after process death. Recovery accepts an external location whose sender may know nothing about the current stack.

## Keep the two boundaries separate

| Boundary | Source | Primary question |
| --- | --- | --- |
| State restoration | Flutter restoration data | “Can I reconstruct the previous route values?” |
| Deep-link recovery | URI from browser, notification, or host | “What valid navigation context should this location produce now?” |

Both eventually produce typed route targets and path mutations. Their validation and fallback policies differ.

## Enable Flutter restoration

Give the application a restoration scope while mounting the Coordinator:

```dart
MaterialApp.router(
  restorationScopeId: 'app_state',
  routerConfig: coordinator,
)
```

ZenRouter restores nested paths and layouts through their route identities. Path labels must be stable and unique because they participate in restoration identity.

## Prefer URI restoration

When all route-defining state fits in a stable location, let `toUri()` be the restoration representation:

```dart
class ProductRoute extends AppRoute {
  ProductRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => AppCoordinator.location.product(id);
}
```

On restore, ZenRouter parses the URI through the manifest and binding again. This keeps restored state subject to the current graph rather than resurrecting a stale widget.

Restoration runs before the first frame and requires synchronous reconstruction. Synchronous `RouteBinding` factories already satisfy that requirement. If a production binding is deferred or asynchronous, provide a synchronous restoration parser:

```dart
@override
AppRoute parseRouteFromUriSync(Uri uri) {
  final match = manifest.match(uri);
  if (match == null) return NotFoundRoute(uri);

  return switch (match.id) {
    AppRouteId.home => HomeRoute(),
    AppRouteId.product => ProductRoute(
      match.pathParameters['id']!,
    ),
  };
}
```

Do not perform network work in this parser. Restore the route value, then let the screen or domain store load current data.

## Converter restoration

Use `RouteRestorable` and a converter only when stable navigation state should not live in the public URL—for example a private draft identifier or compact, versioned editor configuration.

```dart
class FilterRoute extends AppRoute with RouteRestorable<FilterRoute> {
  FilterRoute(this.filters);
  final FilterData filters;

  @override
  String get restorationId => 'filters-v1';

  @override
  RestorationStrategy get restorationStrategy =>
      RestorationStrategy.converter;

  @override
  RestorableConverter<FilterRoute> get converter =>
      const FilterRouteConverter();
}
```

The converter serializes JSON-safe data and reconstructs the route:

```dart
class FilterRouteConverter extends RestorableConverter<FilterRoute> {
  const FilterRouteConverter();

  @override
  String get key => 'filter-route-v1';

  @override
  Map<String, dynamic> serialize(FilterRoute route) => {
    'categories': route.filters.categories,
    'minPrice': route.filters.minPrice,
  };

  @override
  FilterRoute deserialize(Map<String, dynamic> data) => FilterRoute(
    FilterData(
      categories: List<String>.from(data['categories'] as List),
      minPrice: data['minPrice'] as num?,
    ),
  );
}
```

Register converters in `init()` with a stable key:

```dart
@override
void init() {
  super.init();
  defineRestorableConverter(
    'filter-route-v1',
    () => const FilterRouteConverter(),
  );
}
```

Version converter keys or payloads when shapes change. Reject data you cannot safely understand and recover to a known root instead of producing a half-valid stack.

## Recover external locations

At the external boundary, call:

```dart
await coordinator.recoverUri(incomingUri);
```

The URI is matched and bound, redirects resolve, then `RouteDeepLink` selects a strategy:

- `replace` for a complete new context;
- `navigate` to reuse compatible existing history;
- `push` to add the destination;
- `custom` for an application-specific reconstruction.

A target without `RouteDeepLink` defaults to replacement. This is safer than guessing that an arbitrary existing stack is compatible with the incoming link.

## Failure and fallback policy

Restoration may fail because the app version changed, a converter disappeared, or a saved ID is no longer valid. Recovery may fail because a URI is unknown or access policy redirects it. Decide the safe fallback explicitly:

```text
invalid saved state → HomeRoute
unknown external URI → NotFoundRoute(requestedUri)
protected external URI → LoginRoute(continueUri)
```

Do not silently drop to Home for every unknown link; that hides broken integrations and loses user intent.

## Test both boundaries

For restoration, navigate into nested layouts, save state, recreate the restoration bucket, and assert active paths before the first rendered frame. On Android, also background the app, kill its process with `adb shell am kill <package>`, and relaunch.

For recovery, begin from an empty root and from an unrelated deep stack. Recover the same URI and assert the final paths, location, and exactly one commit.

## Checkpoint

Kill and relaunch from a nested route, then open the same destination as a fresh deep link. Both flows should produce a valid graph context, but each should follow its own source validation and fallback policy.

Next, **File-based routing** generates the same manifest, bindings, and locations from a directory structure.
