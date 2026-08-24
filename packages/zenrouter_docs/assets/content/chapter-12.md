File-based routing is a graph authoring tool. It turns `lib/routes/` into the same manifest, bindings, layouts, and locations you can write by hand. The generated output is reviewable code, not a separate runtime router.

## Install the generator

```yaml
dependencies:
  zenrouter: ^3.0.0-beta.1
  zenrouter_file_annotation: ^3.0.0-beta.1

dev_dependencies:
  build_runner: ^2.10.4
  zenrouter_file_generator: ^3.0.0-beta.1
```

## Start with the directory contract

```text
lib/routes/
├── _coordinator.dart               Coordinator configuration
├── index.dart                      /
├── about.dart                      /about
├── profile/
│   └── [id].dart                   /profile/:id
├── docs/
│   └── [...slugs]/
│       └── index.dart              /docs/...:slugs
├── (auth)/
│   ├── _layout.dart                layout, no URL group segment
│   ├── login.dart                  /login
│   └── register.dart               /register
└── tabs/
    ├── _layout.dart                /tabs layout
    ├── feed.dart                   /tabs/feed
    └── profile.dart                /tabs/profile
```

The public patterns are predictable:

| File form | Route form |
| --- | --- |
| `index.dart` | directory URL |
| `about.dart` | named static segment |
| `[id].dart` | one dynamic segment |
| `[...slugs]/index.dart` | catch-all segments |
| `_layout.dart` | layout node, not a leaf route |
| `(group)/` | organizational/layout group without a URL segment |
| `_helper.dart` | private generator input ignored as a route |

Dot notation can flatten directories: `shop.products.[id].dart` represents `/shop/products/:id`.

## Define a route

Route classes extend their generated base. Dynamic parameters become typed constructor fields:

```dart
// lib/routes/profile/[id].dart
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import '../routes.zen.dart';

part '[id].g.dart';

@ZenRoute()
class ProfileIdRoute extends _$ProfileIdRoute {
  ProfileIdRoute({required super.id});

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) => ProfileScreen(profileId: id);
}
```

The generator provides equality, location identity, manifest binding, and navigation helpers around the declared parameter.

## Define a layout

`_layout.dart` creates a layout node. Choose the child structure explicitly:

```dart
@ZenLayout(
  type: LayoutType.indexed,
  routes: [FeedRoute, ProfileRoute],
)
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) {
    final path = resolvePath(coordinator);
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: NavigationBar(
        selectedIndex: path.activeIndex,
        onDestinationSelected: path.goToIndexed,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.feed), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

Use stack layouts for unbounded child stacks, indexed layouts for fixed destinations, and branched layouts for retained branch histories.

## Configure the Coordinator

The generator discovers `_coordinator.dart`:

```dart
@ZenCoordinator(
  name: 'AppCoordinator',
  routeBase: 'AppRoute',
  deferredImport: true,
)
class CoordinatorConfig {
  const CoordinatorConfig();
}
```

Deferred imports reduce initial bundle work for large web applications. Generated bindings await the library before constructing the target. If state restoration needs those routes, also provide a synchronous restoration path as described in the previous chapter.

## Generate and inspect

```bash
dart run build_runner build --delete-conflicting-outputs
```

The output includes:

- a `RouteManifest` containing routes and layouts;
- `RouteBinding`s that construct generated route classes;
- `location` methods for reverse routing;
- `push`, `replace`, and `recover` extensions;
- parameter extraction from `pathParameters` and `restParameters`;
- optional deferred-library loaders.

Inspect this output after every topology change. A second generation run should produce no diff.

## Navigate through generated surfaces

```dart
await coordinator.pushProfileId(id: 'user-42');
await coordinator.replaceIndex();
await coordinator.recoverDocs(slugs: ['guides', 'routing']);

final uri = coordinator.location.profileId(id: 'user-42');
```

Generated helpers prevent route names and parameter keys from drifting across call sites.

## Team workflow

1. Add or rename the route file.
2. Run generation.
3. Review the source and generated graph together.
4. Run manifest round-trip and widget tests.
5. Commit generated files with the route change.

Do not manually edit `.g.dart` or `routes.zen.dart`. Customize behavior in the annotated class or the custom Coordinator subclass.

## Common failures

**A route is missing.** Confirm the file is under `lib/routes/`, is not private, and contains `@ZenRoute`.

**A URL includes a group name.** Parentheses groups are organizational; use a normal directory when the segment belongs in the URL.

**Catch-all and static routes overlap.** Keep only one catch-all per pattern and let specific nodes remain deterministic.

**Generated imports are stale.** Re-run `build_runner` after moves and delete conflicting outputs when changing generator shape.

## Checkpoint

Add `profile/[id].dart`, generate, and verify one contract end to end: the manifest contains `/profile/:id`, the binding extracts `id`, the route constructor exposes it, and the location helper generates a URL that matches back to the same node.

Next, **Scale the graph** divides ownership across features without returning to one giant parser.
