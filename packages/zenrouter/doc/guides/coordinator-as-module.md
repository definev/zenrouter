# Coordinator as RouteModule Guide

> **Unlock Powerful Versioning & Parallel Development Workflows**

Since `Coordinator<T>` implements `RouteModule<T>`, you can nest entire coordinators as modules within a parent. This architecture treats each child coordinator as a self-contained application, managing its own navigation history, deep linking logic, and state.

This capability is particularly powerful for **scalable feature development**. It allows teams to build major features in parallel—such as developing a "Shop V2" alongside a "Shop V1"—without code conflicts or regression risks. By isolating features into their own coordinators, you gain the ability to run safe A/B tests, incrementally migrate legacy apps, and let different teams own their entire vertical stack.

## Why Use Coordinators as Modules?

When you nest a `Coordinator` inside another, it behaves exactly like a standard `RouteModule`. It doesn't create a separate history stack or navigation context; instead, its routes are merged seamlessly into the parent's routing tree.

The true power of this pattern lies in **reusability and modularity**:

*   **Reuse Existing Code**: You can take a standalone `Coordinator` from an older project (or a different part of your app) and plug it directly into a modern `CoordinatorModular` setup without rewriting it.
*   **Seamless Versioning**: Because both V1 and V2 coordinators share the same parent history, users can navigate between them effortlessly. Pushing a V2 route from V1 feels just like a normal navigation event.
*   **Parallel Development**: Different teams can work on different `Coordinator` classes (e.g., `ShopCoordinatorV1` vs. `ShopCoordinatorV2`) simultaneously. Each coordinator is a self-contained unit of code, but at runtime, they act as one cohesive application.

### When to Use

This pattern is ideal when you want to **integrate an existing Coordinator** into a modular app, or when you are **rewriting a feature** and want to keep the old logic (V1) available while building the new one (V2). It allows you to maintain two complete, improved versions of a feature side-by-side in the same codebase.

If you are starting a new feature from scratch and don't need this specific kind of separation, a standard `RouteModule` is usually simpler and sufficient.



---

## Technical Implementation

The correct way to use a Coordinator as a Module is to verify the **Wrapper Pattern**. This allows you to keep your feature coordinator completely unaware of its parent or version prefix, maximizing reusability.

### 1. The Feature Coordinator

First, write your feature coordinator as a standard, standalone class. It doesn't need to know about parents or versioning.

```dart
class ShopCoordinator extends Coordinator<AppRoute> {
  // Define paths owned by this coordinator
  late final NavigationPath<AppRoute> shopStack = NavigationPath.createWith(
    label: 'shop',
    coordinator: this,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    // Standard route parsing logic
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ProductRoute(id: id),
      _ => null,
    };
  }
}
```

### 2. The Module Wrapper

Next, create a wrapper class that extends your feature coordinator. This wrapper connects the feature to the parent and handles any route prefixing (e.g., `/v1/shop` vs `/shop`).

```dart
class ShopCoordinatorModule extends ShopCoordinator {
  ShopCoordinatorModule(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    // Intercept routes starting with 'v1'
    return switch (uri.pathSegments) {
      ['v1', ...final rest] => super.parseRouteFromUri(
        uri.replace(pathSegments: rest), // Strip 'v1' and delegate
      ),
      _ => null, 
    };
  }
}
```

By overriding the `coordinator` field, you link the child to the parent. By modifying `parseRouteFromUri`, you handle the versioning externally, keeping `ShopCoordinator` clean.

### 3. Register in the Parent

Finally, register the *wrapper* in the parent's `defineModules` method.

```dart
class MainCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    // Register the wrapper, passing 'this' as the parent
    ShopCoordinatorModule(this), 
    SettingsModule(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
```

---

## Parallel Feature Development (Versioning)

The Wrapper Pattern naturally supports **Parallel Feature Development**. You can have multiple versions of the same feature coordinator running side-by-side by creating different wrappers for them.

### Example: V1 and V2 Coexistence

You might have a legacy `ShopCoordinatorV1` and a new `ShopCoordinatorV2`. You simply wrap them with different prefixes:

```dart
// Legacy Wrapper
class ShopCoordinatorV1Module extends ShopCoordinatorV1 {
  ShopCoordinatorV1Module(this.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', ...final rest] => super.parseRouteFromUri(
        uri.replace(pathSegments: rest),
      ),
      _ => null,
    };
  }
}

// New Wrapper
class ShopCoordinatorV2Module extends ShopCoordinatorV2 {
  ShopCoordinatorV2Module(this.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v2', ...final rest] => super.parseRouteFromUri(
        uri.replace(pathSegments: rest),
      ),
      _ => null,
    };
  }
}
```

Then register both in `MainCoordinator`:

```dart
@override
Set<RouteModule<AppRoute>> defineModules() => {
  ShopCoordinatorV1Module(this),
  ShopCoordinatorV2Module(this),
};
```

### Benefits of this Approach

1.  **Zero Regression Risk**: The legacy `ShopCoordinatorV1` remains untouched.
2.  **Clean Code**: Coordinators focus on logic, Wrappers focus on mounting and versioning.
3.  **Experiment Freedom**: V2 can use a completely different architecture or state management library.
4.  **Instant Rollback**: If V2 has bugs, you can restrict access to it in the wrapper or parent without redeploying valid code.



### Best Practices for Parallel Development

*   **Namespace Everything**: Prefix V2 classes with `V2` (e.g., `ShopCoordinatorV2`, `ShopHomeV2`) to prevent naming collisions and make the code self-documenting.
*   **Isolate Dependencies**: Avoid sharing complex ViewModels or Controllers between V1 and V2. Sharing only simple Data Transfer Objects (DTOs) ensures that changes in the new version don't accidentally break the old one.
*   **Visible Deprecation**: In the legacy V1 layouts, consider adding UI indicators like banners or badges to inform users of the new version and encourage them to migrate.

---

## Troubleshooting

### UnimplementedError: "This coordinator is standalone"

you will encounter this error if you use a Coordinator as a RouteModule but forget to override the `coordinator` getter. The base `Coordinator` class throws this error to prevent misuse. Ensure your child coordinator implements:

```dart
@override
CoordinatorModular<AppRoute> get coordinator => _parent;
```

### AssertionError: "you must return route from parseRouteFromUri"

If you are using a standalone coordinator (one that isn't nested) as your main `RouterConfig`, it *must* return a route from `parseRouteFromUri`. If it returns `null`, the app doesn't know what to show. Always ensure your top-level coordinator has a fallback, typically a `NotFoundRoute`.

---

**Need help?** File an issue at [github.com/definev/zenrouter/issues](https://github.com/definev/zenrouter/issues)
