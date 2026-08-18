# Layouts

A `RouteLayout` owns a `StackPath` and wraps child routes (app bar,
sidebar, tab bar).

1. Create the path with `createWith` and `bindLayout(TheLayout.new)`.
2. On each child: `Type? get layout => TheLayout`.

Works with any `Coordinator`. Add the path to `coordinator.paths`.

```
/shop                  ShopLayout + ShopHomeRoute
/shop/products/:id     ShopLayout + ProductRoute
```

## Stack

Unbounded push/pop under a shell.

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final shopStack = NavigationPath<AppRoute>.createWith(
    label: 'shop',
    coordinator: this,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopStack];

  @override
  AppRoute parseRouteFromUri(Uri uri) { /* ... */ }
}
```

`label` must be unique (state restoration). `bindLayout` registers the
constructor.

```dart
class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(covariant AppCoordinator c) =>
      c.shopStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      drawer: const ShopDrawer(),
      body: buildPath(coordinator),
    );
  }
}

class ShopHomeRoute extends AppRoute {
  @override
  Type? get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop');

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return ListTile(
      title: const Text('Product 1'),
      onTap: () => coordinator.push(ProductRoute(id: '1')),
    );
  }
}

class ProductRoute extends AppRoute {
  ProductRoute({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Type? get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop/products/$id');
}
```

Call `buildPath(coordinator)`, not `super.build()`.

`push(ProductRoute(id: '1'))` activates `ShopLayout` if needed, then
pushes the product onto `shopStack`.

## Indexed (tabs)

Fixed child list. Switching tabs does not keep a nested stack per tab.

```dart
late final tabStack = IndexedStackPath<AppRoute>.createWith(
  coordinator: this,
  label: 'main-tabs',
  [HomeTab(), ShopTab(), ProfileTab()],
)..bindLayout(TabBarLayout.new);
```

```dart
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(covariant AppCoordinator c) =>
      c.tabStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: ListenableBuilder(
        listenable: coordinator.tabStack,
        builder: (context, _) => BottomNavigationBar(
          currentIndex: coordinator.tabStack.activeIndex,
          onTap: coordinator.tabStack.activateAt,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
```

Tab routes set `layout => TabBarLayout`.

## Branched (stateful shell)

Each child is a layout with its own stack. Switching branches retains
depth.

```dart
late final branches = BranchedStackPath<AppRoute>.createWith(
  [HomeBranchLayout(), SettingsBranchLayout()],
  coordinator: this,
  label: 'app-branches',
)..bindLayout(AppShellLayout.new);

await branches.goToBranch(1);
```

Register each branch's child `NavigationPath` on `coordinator.paths`.

## Nesting

```
TabBarLayout          (indexed)
  └─ HomeTabLayout    (stack)
       └─ ProductRoute
```

The coordinator walks `layout` and activates missing parents.

## Custom StackPath

```dart
@override
void init() {
  super.init();
  defineLayoutBuilder(
    ModalPath.key,
    (coordinator, path, layout) {
      return ModalStack(
        path: path as ModalPath<AppRoute>,
        coordinator: coordinator as AppCoordinator,
      );
    },
  );
}
```

Default builders for `NavigationPath` and `IndexedStackPath` require
Flutter `Coordinator`, not a bare `CoordinatorCore`.

## Troubleshooting

**Missing constructor for the [MyLayout] layout**

Add `..bindLayout(MyLayout.new)` on the path.

**Layout does not appear**

- Path is in `coordinator.paths` (spread `super.paths`)
- Child `layout` getter is the correct type
- Path created with `createWith`

**Default layout builder requires a zenrouter Coordinator**

Extend `Coordinator`, or register a custom builder.

## Manifest layouts

Only if the coordinator uses a `RouteManifest`. Declare the same shell
on the graph so matching and the Graph tab see it.

`parentId` is a manifest ID (`ShopRouteId.layout`). `layout` is a type
(`ShopLayout`). They must name the same shell.

```dart
RouteManifestLayout.stack(id: ShopRouteId.layout, path: '/shop');

RouteManifestRoute(
  id: ShopRouteId.home,
  path: '/shop',
  parentId: ShopRouteId.layout,
);

RouteManifestLayout.indexed(
  id: TabsRouteId.layout,
  path: '/tabs',
  childIds: [TabsRouteId.home, TabsRouteId.shop, TabsRouteId.profile],
);

RouteManifestLayout.branched(
  id: ShellRouteId.shell,
  path: '/',
  childIds: [ShellRouteId.homeBranch, ShellRouteId.settingsBranch],
);
```

Indexed `childId`s must be direct children. Branched children must
themselves be layouts. Cycles fail at manifest construction.

| Kind | Manifest | Path |
|------|----------|------|
| Stack | `RouteManifestLayout.stack` | `NavigationPath` |
| Tabs | `RouteManifestLayout.indexed` | `IndexedStackPath` |
| Stateful shell | `RouteManifestLayout.branched` | `BranchedStackPath` |

## See also

- [Modular coordinator](coordinator-modular.md)
- [State restoration](state-restoration.md)
- [Bottom navigation](../recipes/bottom-navigation.md)
- [`main_coordinator.dart`](../../example/lib/main_coordinator.dart)
