A shell, detail flow, and tab bar should not become one undifferentiated global page list. Paths own navigation state; layouts own the persistent UI that renders a path.

## The ownership rule

Use this sentence when designing a shell:

> A `RouteLayout` owns exactly one child `StackPath`, and every child route names that layout as its parent.

For a shop section, the graph might be:

```text
App root
└── ShopLayout                 persistent app bar + drawer
    └── shopPath               NavigationPath
        ├── ShopHomeRoute
        └── ProductRoute('42') active
```

The product push changes `shopPath`. It does not remove and rebuild the app shell.

## Create and bind the path

Create Coordinator-owned paths with `createWith`, give each a unique label for restoration, and bind the layout constructor:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final shopPath = NavigationPath<AppRoute>.createWith(
    label: 'shop',
    coordinator: this,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopPath];
}
```

Forgetting to include `super.paths` hides the root and other registered paths. Duplicate labels make restoration identity ambiguous.

## Build the layout

The layout resolves its path and renders `buildPath(coordinator)` inside persistent UI:

```dart
class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(
    covariant AppCoordinator coordinator,
  ) => coordinator.shopPath;

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      drawer: const ShopDrawer(),
      body: buildPath(coordinator),
    );
  }
}
```

Call `buildPath`, not `super.build()`. The layout builder knows how to render its bound path type.

## Attach child routes

Every route that belongs below the shell names the layout type:

```dart
class ProductRoute extends AppRoute {
  ProductRoute(this.id);
  final String id;

  @override
  Type? get layout => ShopLayout;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => AppCoordinator.location.product(id);
}
```

When `ProductRoute` is pushed, the Coordinator creates or activates `ShopLayout`, resolves `shopPath`, and commits the route there.

## Choose a path shape

| Product behavior | Path | Layout kind |
| --- | --- | --- |
| Unbounded detail stack under a shell | `NavigationPath` | stack |
| Fixed destinations, one active | `IndexedStackPath` | indexed |
| Fixed branches, each retaining depth | `BranchedStackPath` | branched |

An indexed path stores fixed route targets. A branched path stores direct child layouts; each branch layout resolves an independent child stack.

## Mirror layouts in the manifest

When using a manifest, describe the same shell in static topology:

```dart
RouteManifestLayout.stack(
  id: AppRouteId.shopLayout,
  path: '/shop',
),
RouteManifestRoute(
  id: AppRouteId.shopHome,
  path: '/shop',
  parentId: AppRouteId.shopLayout,
),
RouteManifestRoute(
  id: AppRouteId.product,
  path: '/shop/products/:id',
  parentId: AppRouteId.shopLayout,
),
```

`parentId` is a manifest ID; `layout` is a Dart type. They describe the same parent at different seams. Keeping them aligned lets graph validation and DevTools show the shell before runtime navigation occurs.

Indexed layout children must be direct children. Branched layout children must themselves be layouts. Unknown parents, duplicate children, and cycles fail during manifest construction.

## Nested layouts

Layouts may nest when each one owns a distinct responsibility:

```text
AppShellLayout
└── tabsPath (branched)
    └── ShopBranchLayout
        └── shopPath (stack)
            └── ProductRoute
```

The Coordinator walks the target's parent chain and activates missing layouts from outermost to innermost.

## Troubleshooting

**“Missing constructor for the layout.”** Bind the constructor on the path with `..bindLayout(ShopLayout.new)`.

**The route appears outside its shell.** Check the route's `layout`, the manifest `parentId`, and that the path is present in `coordinator.paths`.

**A nested push removes the shell.** You probably used `replace`, targeted the root path, or flattened shell and child routes into one path.

**Restoration rebuilds the wrong path.** Ensure path labels are stable and unique, and restore route values rather than widgets.

## Checkpoint

Draw every persistent shell as a box and every owned path as an arrow. Push a detail route and verify only the intended child stack changes. Next, **Tabs and retained branches** applies the same ownership rule to bottom navigation.
