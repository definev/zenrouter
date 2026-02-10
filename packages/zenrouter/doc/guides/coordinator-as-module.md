# Coordinator as RouteModule Guide

> **Use a full Coordinator as a RouteModule inside a parent CoordinatorModular**

Since `Coordinator<T>` implements `RouteModule<T>`, you can nest entire coordinators as modules within a parent. Each child coordinator brings its own paths, layouts, converters, and route parsing—enabling powerful composition patterns like **route versioning**, **micro-frontends**, and **feature-flag gated modules**.

## What is Coordinator-as-RouteModule?

A regular `RouteModule` is a lightweight object that handles routes for a specific domain. But because `Coordinator` already implements `RouteModule`, you can use a **full Coordinator** in place of a module. This gives you:

- **Full coordinator capabilities** — each module has its own paths, layouts, and state
- **Isolation** — child coordinators are self-contained and independently testable
- **Composition** — nest coordinators to arbitrary depth
- **Cross-coordinator navigation** — routes navigate seamlessly across coordinator boundaries

### When to Use

✅ **Use when:**
- Different parts of your app need completely independent routing logic
- You want to version routes (e.g., `/v1/shop` vs `/v2/shop`)
- Teams own separate features that each need a full coordinator
- You want to reuse coordinators across different parent applications

❌ **Don't use when:**
- A simple `RouteModule` is sufficient for your domain
- Your modules don't need their own navigation paths or layouts
- You prefer a flat, centralized routing structure

---

## Quick Start

### Step 1: Create a Child Coordinator

Override the `coordinator` getter to point back to the parent:

```dart
class ShopCoordinator extends Coordinator<AppRoute> {
  ShopCoordinator(this._parent);
  final MainCoordinator _parent;

  // Link back to the parent — required for Coordinator-as-RouteModule
  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  // Define paths owned by this coordinator
  late final NavigationPath<AppRoute> shopStack = NavigationPath.createWith(
    label: 'shop',
    coordinator: _parent, // Bind to the parent, not `this`
  );

  @override
  List<StackPath> get paths => [...super.paths, shopStack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopLayout, ShopLayout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ProductRoute(id: id),
      _ => null,
    };
  }
}
```

> [!IMPORTANT]
> **Bind paths to the parent coordinator**, not to `this`. The parent is the `RouterConfig` that manages the navigator, so its paths must include the child's paths.

### Step 2: Create the Parent Coordinator

Register child coordinators in `defineModules`, just like regular modules:

```dart
class MainCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    ShopCoordinator(this),
    SettingsCoordinator(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
```

**That's it!** The parent automatically:
- Aggregates paths from all child coordinators
- Delegates route parsing to each child
- Calls `defineLayout` and `defineConverter` on each child

---

## The `coordinator` Getter

The `coordinator` getter is the key mechanism that distinguishes standalone coordinators from nested ones.

### Standalone Coordinator (default)

By default, `Coordinator` throws `UnimplementedError`:

```dart
// In Coordinator base class:
@override
CoordinatorModular<T> get coordinator => throw UnimplementedError(
  'This coordinator is standalone and does not belong to any CoordinatorModular',
);
```

This is fine when a coordinator is used as a top-level `RouterConfig`.

### Nested Coordinator

When used as a `RouteModule`, override the getter to return the parent:

```dart
@override
CoordinatorModular<AppRoute> get coordinator => _parent;
```

> [!CAUTION]
> If you use a standalone coordinator as a `RouterConfig` and its `parseRouteFromUri` returns `null`, a debug assertion will fire. Standalone coordinators **must** always return a route.

---

## Route Versioning Pattern

The most compelling use case for Coordinator-as-RouteModule is **route versioning** — running multiple versions of the same feature side by side.

### Architecture

```
MainCoordinator (CoordinatorModular)
├── ShopCoordinatorV1  → /v1/shop/...  (deprecated)
├── ShopCoordinatorV2  → /v2/shop/...  (current)
└── SettingsCoordinator → /settings/...
```

### Implementation

```dart
class ShopCoordinatorV1 extends Coordinator<AppRoute> {
  ShopCoordinatorV1(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopV1Stack = NavigationPath.createWith(
    label: 'shop-v1',
    coordinator: _parent,
  );

  @override
  List<StackPath> get paths => [...super.paths, shopV1Stack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopV1Layout, ShopV1Layout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', 'shop'] => ShopHomeV1(),
      ['v1', 'shop', 'products'] => ProductListV1(),
      _ => null,
    };
  }
}

class ShopCoordinatorV2 extends Coordinator<AppRoute> {
  ShopCoordinatorV2(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopV2Stack = NavigationPath.createWith(
    label: 'shop-v2',
    coordinator: _parent,
  );

  @override
  List<StackPath> get paths => [...super.paths, shopV2Stack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopV2Layout, ShopV2Layout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v2', 'shop'] => ShopHomeV2(),
      ['v2', 'shop', 'products'] => ProductListV2(),
      ['v2', 'shop', 'products', final id] => ProductDetailV2(id: id),
      _ => null,
    };
  }
}
```

### Cross-Version Navigation

Navigate between versions using the parent coordinator:

```dart
// From V1 layout, offer migration to V2
TextButton(
  onPressed: () => coordinator.replace(ShopHomeV2()),
  child: const Text('Switch to V2'),
)

// From V2, link back to legacy V1
TextButton(
  onPressed: () => coordinator.replace(ShopHomeV1()),
  child: const Text('Open Legacy Shop'),
)
```

### Deprecation Banner

V1 layouts can show a deprecation banner:

```dart
class ShopV1Layout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          MaterialBanner(
            content: const Text('This shop version is deprecated.'),
            actions: [
              TextButton(
                onPressed: () => coordinator.replace(ShopHomeV2()),
                child: const Text('Switch to V2'),
              ),
            ],
          ),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
    );
  }
}
```

---

## Coordinator vs RouteModule — When to Use Which

| Aspect | `RouteModule` | `Coordinator` as module |
|--------|---------------|------------------------|
| **Route parsing** | ✅ | ✅ |
| **Own paths** | ✅ | ✅ |
| **Own layouts** | ✅ | ✅ |
| **Own converters** | ✅ | ✅ |
| **Full coordinator lifecycle** | ❌ | ✅ |
| **Can be used standalone** | ❌ | ✅ |
| **Independently testable** | Partially | ✅ Fully |
| **Use case** | Simple domain routing | Complex, self-contained features |

---

## Best Practices

### ✅ Do

- **Override `coordinator`** to return the parent when nesting
- **Bind paths to the parent**, not to `this`
- **Spread `...super.paths`** in your `paths` getter to include the root path
- **Use unique path labels** across all child coordinators (e.g., `shop-v1`, `shop-v2`)
- **Keep child coordinators independent** — they shouldn't know about siblings

### ❌ Don't

- **Don't access sibling coordinators directly** — use `coordinator.getModule<T>()` through the parent
- **Don't forget to return `null`** for unhandled routes
- **Don't bind paths to `this`** in a child coordinator — they won't be visible to the parent's navigator

---

## Troubleshooting

### UnimplementedError: "This coordinator is standalone"

**Problem:** You're using a Coordinator as a RouteModule but haven't overridden the `coordinator` getter.

**Solution:**
```dart
@override
CoordinatorModular<AppRoute> get coordinator => _parent;
```

### AssertionError: "you must return route from parseRouteFromUri"

**Problem:** A standalone coordinator's `parseRouteFromUri` returned null.

**Solution:** Standalone coordinators used as `RouterConfig` must always return a non-null route:
```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    // ... your routes ...
    _ => NotFoundRoute(uri: uri), // Always provide a fallback
  };
}
```

### Paths not visible in parent

**Problem:** Child coordinator paths aren't navigable from the parent.

**Solution:** Bind paths to the **parent** coordinator:
```dart
// ❌ Wrong
late final myPath = NavigationPath.createWith(
  label: 'my-path',
  coordinator: this, // Binds to child — invisible to parent's navigator
);

// ✅ Correct
late final myPath = NavigationPath.createWith(
  label: 'my-path',
  coordinator: _parent, // Binds to parent — visible to navigator
);
```

---

## Next Steps

- **See [coordinator-modular.md](./coordinator-modular.md)** for the simpler `RouteModule` approach
- **See [route-layout.md](./route-layout.md)** for creating custom layouts
- **See the [Route Versioning recipe](../recipes/route-versioning.md)** for a complete working example
- **Check example code** in `packages/zenrouter/example/lib/main_coordinator_module.dart`

---

**Need help?** File an issue at [github.com/definev/zenrouter/issues](https://github.com/definev/zenrouter/issues)
