# Migration Guide

This guide outlines the changes and steps required to migrate to the latest version of `zenrouter`.

## Path Constructors

The constructors for `NavigationPath` and `IndexedStackPath` have been updated to provide better clarity and type safety, especially when binding to a `Coordinator`.

### Changes

- **Deprecated**: The default unnamed constructors `NavigationPath(...)` and `IndexedStackPath(...)`.
- **New**: `create` factory constructor for creating paths with optional arguments.
- **New**: `createWith` factory constructor for creating paths that are explicitly bound to a `Coordinator`.

### Migration

Replace direct constructor calls with `create` or `createWith`:

**Before:**
```dart
final path = NavigationPath(
  'root',
  [],
  coordinator,
);
```

**After (Standard):**
```dart
final path = NavigationPath.create(
  label: 'root',
  stack: [],
  coordinator: coordinator,
);
```

**After (With explicit Coordinator):**
```dart
late final path = NavigationPath.createWith(
  coordinator: this,
  label: 'root',
  stack: [],
);
```

Same applies to `IndexedStackPath`.

### Rationale

Deeply integrating paths with their coordinator using `createWith` provides several benefits:

1.  **Coordinator Awareness**: The path explicitly knows which coordinator it belongs to, enabling features like `popGuardWith` to verify that operations are happening in the correct context.
2.  **Safety**: Prevents a path from being used detached from its coordinator, which could lead to silent failures or incorrect state management.
3.  **Strict Binding**: The `late final ... = ... .createWith(coordinator: this, ...)` pattern ensures that the path and coordinator are 1:1 linked from the moment of creation, avoiding race conditions or initialization order issues.

### Trade-offs

*   **Coupling**: This approach tightly couples instances of `StackPath` to a specific `Coordinator`. While this is by design, it means paths are less "standalone".
*   **Testing**: Unit testing individual paths in isolation now requires providing a mock or dummy `Coordinator` if you use `createWith`, whereas previously they could be tested as simple data containers.
*   **Initialization**: Requires using `late final` variables in the `Coordinator` to handle the circular reference (Coordinator needs Path, Path needs Coordinator). Exceptions during initialization might be harder to debug if not careful.

**Why it is worth it:**
When using `createWith`, you are explicitly creating a path intended to work *with* a Coordinator. Therefore, this coupling is intentional and necessary. It guarantees that the path always has access to the correct context for advanced features like guards and redirects, making the system more robust and preventing common configuration errors.

## Path Layout Builder: `defineLayoutBuilder()`

The `RouteLayout.definePath()` static method has been deprecated and replaced by the instance method `coordinator.defineLayoutBuilder()`.

### Changes

- **Deprecated**: The static method `RouteLayout.definePath(coordinator, key, builder)`.
- **New**: The instance method `coordinator.defineLayoutBuilder(key, builder)`.

### Migration

Replace calls to the static `RouteLayout.definePath` with the `defineLayoutBuilder` method on your coordinator instance.

**Before:**
```dart
// Static definition
RouteLayout.definePath(
  NavigationPath.key,
  (coordinator, path, layout) => CustomNavigationStack(...),
);
```

**After:**
```dart
// Instance definition
coordinator.defineLayoutBuilder(
  NavigationPath.key,
  (coordinator, path, layout) => CustomNavigationStack(...),
);
```

### Rationale

Moving `defineLayoutBuilder` to the `Coordinator` instance solves a critical architectural issue by **avoiding global state**:

1. **Scoped State**: Layout builders are now scoped to the specific `Coordinator` instance rather than sitting in a static global context. This ensures that multiple coordinators (e.g., in testing or advanced architectures) do not interfere with each other's custom layout builders.
2. **Lifecycle Management**: By associating the builder table with the coordinator, it automatically cleans up when the coordinator is disposed, preventing memory leaks.

## Layout Registration: `bindLayout()`

The layout registration API has been simplified from `defineLayout()` to `bindLayout()`.

### Changes

- **Deprecated**: `defineLayout()` method with `RouteLayout.defineLayout()` calls.
- **New**: `bindLayout()` method on `StackPath` for inline layout registration.

### Migration

**Before (using defineLayout):**
```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  );

  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, HomeLayout.new);
  }
}
```

**After (using bindLayout):**
```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  )..bindLayout(HomeLayout.new);  // Register inline!

  // No need to override defineLayout() when using bindLayout
}
```

Both approaches work, but `bindLayout()` is recommended for new code.

### Benefits

- **More concise**: Single line instead of separate method override
- **Collocated**: Path creation and layout registration in one place
- **Less boilerplate**: No need to override `defineLayout()`

## RouteGuard API

The `RouteGuard` mixin has been enhanced to support coordinator validation during pop operations.

### Changes

- **New**: `popGuardWith(Coordinator coordinator)` method.
  - This method is called by the framework when a pop is attempted.
  - It asserts that the route's path is associated with the correct coordinator.
  - It internally calls `popGuard()`.

- **Existing**: `popGuard()` remains the place to implement your custom guard logic.

### Migration

If you are manually calling `popGuard` in your custom logic or tests, consider using `popGuardWith` if you have access to the coordinator to benefit from the additional checks.

No changes are needed for existing `popGuard` implementations unless you are overriding the default behavior significantly.

## RouteRedirect API

The `RouteRedirect` mixin has been updated similarly to `RouteGuard`.

### Changes

- **New**: `redirectWith(Coordinator coordinator)` method.
  - Called by the framework during route resolution.
  - Helps ensuring the path belongs to the correct coordinator context.
  - Internally calls `redirect()`.

- **Existing**: `redirect()` remains the place to implement your redirect logic.

## parseRouteFromUri Return Type

The return type of `parseRouteFromUri` has been changed to support nullable returns.

### Changes

- **Before**: `FutureOr<T> parseRouteFromUri(Uri uri)`
- **After**: `FutureOr<T?> parseRouteFromUri(Uri uri)`

### Migration

For most coordinators, no changes are needed. The nullable return is primarily for nested coordinators (route modules) that want to indicate "this URI doesn't belong to me".

```dart
// Before
@override
FutureOr<AppRoute> parseRouteFromUri(Uri uri) { ... }

// After - return null to let parent handle unrecognized URIs
@override
FutureOr<AppRoute?> parseRouteFromUri(Uri uri) { ... }
```

## Internal Properties (`internalProps`)

A new property `internalProps` has been introduced to the `Equatable` base class (and consequently `RouteTarget`) to handling deep comparison and hashing of internal state.

### Changes

- **`internalProps`**: A list of properties used for calculating `hashCode` and ensuring object identity, separate from the public `props`.
- `RouteTarget` now includes `runtimeType`, `_path`, and the internal result completer in `internalProps`.

### Impact

This ensures that `RouteTarget` instances are correctly distinguished even if they have identical configuration `props`, especially when they belong to different paths or have different lifecycle states. This improves the reliability of deep comparisons and sets containing routes.
