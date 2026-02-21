# Coordinator API

Complete API reference for the `Coordinator` class and related types in ZenRouter.

## Overview

The Flutter-specific implementation of the navigation coordinator orchestrates navigation by:
1. Receiving navigation calls via `push`, `pop`, `replace`, `navigate`
2. Processing redirects through `RouteRedirect.resolve`
3. Resolving layout hierarchies via `RouteLayoutParent`
4. Updating appropriate `StackPath` (push/pop/activate)
5. Triggering UI rebuilds through `NavigationStack`
6. Synchronizing browser URL via `CoordinatorRouterDelegate`

## Inheritance Architecture

```dart
Coordinator<T extends RouteUnique>
  extends CoordinatorCore<T>           // Core navigation logic
  with CoordinatorLayout<T>,           // Layout builders
       CoordinatorRestoration<T>,      // State restoration
       CoordinatorTransitionStrategy<T> // Page transitions
  implements RouterConfig<Uri>,         // Flutter Router integration
           RouteModule<T>,              // Modular navigation support
           ChangeNotifier               // Observable state
```

### Class Architecture

This class composes functionality from multiple sources:

| Component | Responsibility |
|-----------|----------------|
| `CoordinatorCore` | Core navigation logic (push, pop, replace) |
| `CoordinatorLayout` | Layout builder registration and parent constructors |
| `CoordinatorRestoration` | State restoration key encoding/decoding |
| `CoordinatorTransitionStrategy` | Default page transition configuration |

## Quick Start

```dart
// 1. Define your route type
abstract class AppRoute extends RouteTarget with RouteUnique {}

// 2. Create a coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['product', final id] => ProductRoute(id),
      _ => HomeRoute(),
    };
  }
}

// 3. Use in MaterialApp.router
MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```

## Coordinator<T extends RouteUnique>

This is an **abstract class** that requires implementation of:
- `parseRouteFromUri(Uri)`: Converts URIs to route objects synchronously or asynchronously.

### Modes of Operation

`Coordinator` can operate in two modes:

**Standalone Mode** (default):
- Has its own root `NavigationPath`
- Can be used directly with `MaterialApp.router`
- Full control over navigation state

**Modular Mode** (part of `CoordinatorModular`):
- Shares root path with parent coordinator
- Cannot use `routerDelegate` or `routeInformationParser`
- Integrates into larger navigation hierarchy
- Access parent via `coordinator` getter

### Properties & Getters

- `root` → `NavigationPath<T>`: The root (primary) navigation path. All coordinators have at least this one path. Returns parent's root in modular mode.
- `activeLayouts` → `List<RouteLayout>`: Returns all active `RouteLayout` instances in the navigation hierarchy, from root to deepest layout.
- `activeLayout` → `RouteLayout?`: Returns the deepest active `RouteLayout`. Returns `null` if only the root layout is active.
- `parseRouteFromUriSync` → `RouteUriParserSync<T>`: Synchronous version of `parseRouteFromUri`. Used by `NavigationPathRestorable` during restoration.
- `navigator` → `NavigatorState`: Access to the navigator state. Useful for imperative operations like showing dialogs or bottom sheets. Retrievals from `routerDelegate.navigatorKey`.

### Layout Builders

- `layoutBuilder(BuildContext context)`: Builds the root widget (the primary navigator). Delegates to `RouteLayout.buildRoot` by default. Override to customize the root navigation structure. Called by `CoordinatorRouterDelegate.build` to create the widget tree.
- `defineLayoutParent(RouteLayoutConstructor constructor)`: Registers a layout parent constructor so `RouteLayoutChild` can look it up via `parentLayoutKey` and create new instance of layout parent. Automatically encodes layout key for restoration.

---

## CoordinatorLayout

Mixin that provides layout builder and parent constructor management for `Coordinator`.

### Role in Navigation Flow
`CoordinatorLayout` enables the coordinator to:
1. Register layout builders that render `StackPath` contents
2. Create layout parent instances for nested navigation
3. Bind routes to their appropriate layout containers

When a route is pushed:
1. `Coordinator` resolves the route's parent layout
2. `createLayoutParent` instantiates the layout if needed
3. `getLayoutBuilder` provides the widget that renders the path's stack

### API

- `defineLayoutParentConstructor(Object layoutKey, RouteLayoutParentConstructor constructor)`: Registers a constructor function for a layout parent.
- `getLayoutParentConstructor(Object layoutKey)`: Retrieves the constructor function.
- `createLayoutParent(Object layoutKey)`: Instantiates a new layout parent.
- `defineLayoutBuilder(PathKey key, RouteLayoutBuilder builder)`: Registers a layout builder for a specific `PathKey` (e.g., `NavigationPath.key` uses `NavigationStack`, `IndexedStackPath.key` uses `IndexedStackPathBuilder`).
- `getLayoutBuilder(PathKey key)`: Retrieves registered layout builder for the given key.

---

## CoordinatorRestoration

Mixins for coordinating route state restoration.

### Role in Navigation Flow
Enables state persistence across app restarts:
1. Encodes layout keys for restoration when layouts are defined.
2. Decodes layout keys when restoring navigation state.
3. Generates restoration IDs for routes based on their path hierarchy.

### API

- `encodeLayoutKey(Object value)`: Encodes a layout key.
- `decodeLayoutKey(String key)` → `Object`: Decodes and returns the stored layout key. Throws `UnimplementedError` if missing.
- `rootRestorationId` → `String`: The restoration ID for the root path.
- `resolveRouteId(T route)` → `String`: Generates a unique restoration ID for the route's state by traversing parent layouts.

### Related Widgets & Classes

**CoordinatorRestorable**
A widget that enables state restoration for a `Coordinator` and its navigation hierarchy. Wraps the coordinator's widget tree, saves state when coordinator changes, and restores navigation state during app initialization. Automatically added by `routerDelegate.build`.

**ActiveRouteRestorable<T>**
A `RestorableValue` that manages the restoration of the currently active route in the navigation stack separately from the full navigation stack.

---

## CoordinatorRouterDelegate / CoordinatorRouteParser

These classes integrate ZenRouter with Flutter's Router widget.

### CoordinatorRouteParser
Parses `RouteInformation` to and from `Uri`. Used internally by `MaterialApp.router` configuration.
1. Flutter's Router calls `parseRouteInformation` when URL changes.
2. Parsed URI is passed to `CoordinatorRouterDelegate.setNewRoutePath`.
3. Navigation is dispatched to the coordinator.

### CoordinatorRouterDelegate
Router delegate that connects the `Coordinator` to Flutter's Router.
- **`build(BuildContext context)`**: Wraps the layout builder with `CoordinatorRestorable` for state restoration.
- **`setNewRoutePath(Uri configuration)`**: Handles browser navigation events (back/forward buttons, URL changes).
  - Submits the URI to `coordinator.parseRouteFromUri`.
  - Determines if route contains `RouteDeepLink` mixin to process custom deep link strategies.
  - Automatically pops/pushes stack while consulting guards. Handles `notifyListeners` if a guard blocks the operation to keep the browser URL synchronized with app-state.
- **`popRoute()`**: Invokes `coordinator.tryPop()`.

---

## CoordinatorNavigatorObserver

Mixin that provides a list of observers for the coordinator's navigator.

### Role in Navigation Flow
`CoordinatorNavigatorObserver` enables observability of navigation events:
1. Observers are attached to each `NavigationStack` in the coordinator.
2. Flutter's Navigator notifies observers of route changes.
3. Useful for analytics, logging, or custom behavior on navigation events.

### API

- `observers` → `List<NavigatorObserver>`: A list of observers that apply for every `NavigationPath` in the coordinator.

---

## Type Definitions

### `RouteUriParserSync<T>`
`typedef RouteUriParserSync<T extends RouteTarget> = T Function(Uri uri);`
Synchronous parser function that converts a `Uri` into a route instance. Used by the restoration system.

### `RouteLayoutBuilder<T>`
`typedef RouteLayoutBuilder<T extends RouteUnique> = Widget Function(Coordinator coordinator, StackPath<T> path, RouteLayout<T>? layout);`
Builder function for creating a layout widget that wraps route content.

### `RouteLayoutConstructor<T>`
`typedef RouteLayoutConstructor<T extends RouteUnique> = RouteLayout<T> Function();`
Constructor function for creating a layout instance.

### `QuerySelectorBuilder<T>`
`typedef QuerySelectorBuilder<T> = Widget Function({required T Function(Map<String, String> queries) selector, required Widget Function(BuildContext context, T value) builder});`
Widget builder for query parameters.
