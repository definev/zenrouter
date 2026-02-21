# Navigation Paths API

Complete API reference for navigation path types in ZenRouter.

## Overview

Navigation paths are stack-based containers that hold routes. ZenRouter provides:

- **`StackPath`** - Base class for all navigation paths
- **`NavigationPath`** - Mutable stack with push/pop operations (created via `StackPath.navigationStack()`)
- **`IndexedStackPath`** - Immutable stack with index-based navigation (created via `StackPath.indexedStack()`)
- **`NavigationStack`** - Widget that renders a navigation path
- **`DeclarativeNavigationStack`** - Widget for state-driven navigation

---

## StackPath<T>

Base class for all navigation paths. Provides common functionality for managing route stacks.


### Factory Constructors

#### `NavigationPath.create()`

Creates a mutable navigation path with push/pop operations.

```dart
factory NavigationPath.create({
  String? label,
  List<T>? stack,
  Coordinator? coordinator,
})
```

**Example:**
```dart
final path = NavigationPath.create(
  label: 'main-nav',
  stack: [HomeRoute()], // Start with home route
);
```

#### `IndexedStackPath.create()`

Creates an indexed navigation path with index-based navigation.

```dart
factory IndexedStackPath.create(
  List<T> stack, {
  String? label,
  Coordinator? coordinator,
})
```

**Example:**
```dart
final tabPath = IndexedStackPath.create(
  [
    FeedTab(),
    ProfileTab(),
    SettingsTab(),
  ], 
  label: 'main-tabs',
);
```

#### `createWith()`

Both `NavigationPath` and `IndexedStackPath` also provide a `createWith` factory to strictly bind a path to a `Coordinator`.

```dart
factory NavigationPath.createWith({
  required Coordinator coordinator,
  required String label,
  List<T>? stack,
})
```

### Common Properties

#### `stack` → `List<T>`

Returns an unmodifiable view of the current navigation stack.

```dart
final currentStack = path.stack;
print('Stack depth: ${currentStack.length}');
print('Top route: ${currentStack.last}');
```

#### `debugLabel` → `String?`

Optional label for debugging purposes.

```dart
print(path.debugLabel); // 'main-nav'
```

#### `activeRoute` → `T?`

The currently active route in the stack.

```dart
final current = path.activeRoute;
print('Active route: ${current?.runtimeType}');
```

### Common Methods

#### `reset()` → `void`

Force clears the entire navigation history.

```dart
path.reset();
// Stack is now empty
```

#### `activateRoute(T route)` → `Future<void>`

Navigates to a specific route.

```dart
await path.activateRoute(ProfileRoute());
```


#### `bindLayout(RouteLayoutConstructor constructor)`
Registers a layout constructor with the coordinator, allowing routes in this path to be wrapped by the specified layout.

**Example:**
```dart
late final profileStack = NavigationPath<AppRoute>.createWith(
  coordinator: this,
  label: 'profile',
)..bindLayout(ProfileLayout.new);
```

---


## NavigationPath<T>

A mutable stack path for standard navigation. Extends `StackPath` with `StackMutatable` mixin.

Supports pushing and popping routes. Used for the main navigation stack and modal flows.

### Role in Navigation Flow

`NavigationPath` is the primary path type for imperative navigation:
1. Stores routes in a mutable list (stack)
2. Supports push/pop/remove operations
3. Renders content via `NavigationStack` widget
4. Implements `RestorablePath` for state restoration

When navigating:
- `push` adds a new route to the top
- `pop` removes the top route
- `navigate` handles browser back/forward

### Constructor

Use the factory constructors:

```dart
// Standard creation
final path = NavigationPath.create(
  label: 'main-nav',
  stack: [HomeRoute()],
);

// With explicit coordinator binding (inside Coordinator)
late final path = NavigationPath.createWith(
  coordinator: this,
  label: 'main-nav',
  stack: [HomeRoute()],
);
```

### Methods
### Constructor

Use the factory constructors:

```dart
// Standard creation
final path = NavigationPath.create(
  label: 'main-nav',
  stack: [HomeRoute()],
);

// With explicit coordinator binding (inside Coordinator)
late final path = NavigationPath.createWith(
  coordinator: this,
  label: 'main-nav',
  stack: [HomeRoute()],
);
```

### Methods

#### `push(T element)` → `Future<dynamic>`

Pushes a route onto the navigation stack.

**Returns:** A `Future` that completes when the route is popped, with the pop result value.

**Handles redirects:** If the route has `RouteRedirect`, the redirect chain is followed until a non-redirecting route is reached.

**Example:**
```dart
// Push and wait for result
final result = await path.push(EditProfileRoute());
if (result?['saved'] == true) {
  showSnackBar('Profile saved!');
}

// Push without waiting for result
path.push(SettingsRoute());

// Push returns the result when popped
final formData = await path.push(FormRoute());
print('User submitted: $formData');
```

**With redirects:**
```dart
// If EditRoute has RouteRedirect that checks auth
await path.push(EditRoute());
// If not authenticated, automatically redirects to LoginRoute
```

#### `pop([Object? result])` → `Future<void>`

Removes the top route from the navigation stack.

**Parameters:**
- `result`: Optional value returned to the `Future` from `push()`

**Guards:** If the route has `RouteGuard`, the guard is consulted first. The pop is cancelled if the guard returns `false`.

**Example:**
```dart
// Pop with a result
path.pop({'saved': true, 'name': 'John'});

// Pop without a result
path.pop();

// The result is received by the Future from push()
final result = await path.push(EditorRoute());
// When EditorRoute calls: path.pop({'content': 'Hello'})
print(result['content']); // 'Hello'
```

**With guards:**
```dart
// If current route has RouteGuard
await path.pop(); // Guard is consulted, pop only happens if guard returns true
```

#### `pushOrMoveToTop(T element)` → `Future<void>`

Pushes a route to the top of the stack, or moves it if already present.

If the route is already in the stack, it's removed from its current position and moved to the top. If not present, it's added to the top.

**Use for:** Tab navigation where you don't want duplicates.

**Example:**
```dart
// Switch between tabs without duplicating
path.pushOrMoveToTop(FeedTab());
// Stack: [FeedTab]

path.pushOrMoveToTop(ProfileTab());
// Stack: [FeedTab, ProfileTab]

path.pushOrMoveToTop(FeedTab());
// Stack: [ProfileTab, FeedTab] - FeedTab moved to top!
```

**Follows redirects:** Just like `push()`, redirect chains are followed.

#### `pushReplacement(T element, {Object? result})` → `Future<dynamic>`

Pops the current route and pushes a new route in its place.

**Parameters:**
- `element`: The new route to push after popping
- `result`: Optional value to pass to the popped route's `push()` Future

**Returns:** A `Future` that completes when the new route is popped, with the pop result value. Returns `null` if redirect resolution fails or guard blocks the pop.

**Behavior based on stack state:**
- **Empty stack:** Pushes the new route normally
- **Single element:** Completes the active route with `result`, resets the stack, then pushes the new route
- **Multiple elements:** Pops the top route (respecting `RouteGuard`), waits for the animation, then pushes

**Example:**
```dart
// Replace current screen without adding to history
await path.pushReplacement(HomeRoute());

// Replace with result for the popped route
await path.pushReplacement(HomeRoute(), result: 'completed');

// Common flow: Screen A waits for result, Screen B replaces with C
// In Screen A:
final result = await path.push(ScreenBRoute());
print('Got: $result'); // Prints: Got: from_c

// In Screen B:
path.pushReplacement(ScreenCRoute(), result: 'from_c');
```

**With guards:**
```dart
// If current route has RouteGuard that returns false
final newRoute = await path.pushReplacement(HomeRoute());
// Returns null if guard blocks the pop
```

**Use cases:**
- Login → Home transition (back should not return to login)
- Splash screen → Main content
- Wizard flows where previous steps shouldn't be revisited

#### `remove(T element)` → `void`

Removes a specific route from the stack at any position.

**⚠️ Warning:** Guards are NOT consulted. This is a forced removal. Use with caution.

**Example:**
```dart
// Remove a specific route
final routeToRemove = path.stack.firstWhere((r) => r is LoginRoute);
path.remove(routeToRemove);

// Remove all routes of a certain type
path.stack.whereType<SplashRoute>().forEach(path.remove);

// Remove by index (via stack list)
final oldRoute = path.stack[2];
path.remove(oldRoute);
```

**Common use cases:**
- Cleaning up intermediate routes after a flow completes
- Removing login/splash screens from history
- Manual stack management

#### `reset()` → `void`

Force clears the entire navigation history.

**⚠️ Warning:** Guards are NOT consulted. This is a hard reset that clears everything.

**Example:**
```dart
// Clear everything
path.reset();
// Stack is now empty

// After reset, you typically push a new initial route
path.reset();
path.push(WelcomeRoute());
```

**Use cases:**
- Logging out
- Resetting app state
- Clearing navigation before a new flow

---

## IndexedStackPath<T>

A fixed stack path for indexed navigation (like tabs).

Routes are pre-defined and cannot be added or removed. Navigation switches the active index.

### Role in Navigation Flow

`IndexedStackPath` manages tab-based navigation:
1. Routes are defined upfront in a fixed list
2. Navigation switches the active index rather than stack
3. Renders content via `IndexedStackPathBuilder` widget
4. Implements `RestorablePath` for tab index restoration

When navigating:
- `goToIndexed` switches to a different route by index
- `activateRoute` activates a route already in the stack
- Routes cannot be pushed or popped, only activated

### Constructor


Use the factory constructors:

```dart
// Standard creation
final tabPath = IndexedStackPath.create(
  [
    FeedTab(),
    ProfileTab(),
    SettingsTab(),
  ], 
  debugLabel: 'main-tabs',
);

// With explicit coordinator binding (inside Coordinator)
late final tabPath = IndexedStackPath.createWith(
  [
    FeedTab(),
    ProfileTab(),
    SettingsTab(),
  ], 
  coordinator: this, 
  label: 'main-tabs',
);
```

**Important:** The stack is immutable - you cannot add or remove routes after creation.

### Properties

#### `stack` → `List<T>`

Returns the complete list of routes (unmodifiable).

```dart
final tabs = tabPath.stack;
print('Total tabs: ${tabs.length}');
```

#### `activePathIndex` → `int`

The index of the currently active route.

```dart
print('Current tab: ${tabPath.activePathIndex}');
// 0 = first tab, 1 = second tab, etc.
```

#### `activeRoute` → `T`

The currently active route.

```dart
final current = tabPath.activeRoute;
print('Active: ${current.runtimeType}');
```

### Methods

#### `goToIndexed(int index)` → `Future<void>`

Navigates to the route at the specified index.

**Consults guards:** If the current route has `RouteGuard`, it's consulted before switching.

**Follows redirects:** If the target route has `RouteRedirect`, the redirect is followed.

**Example:**
```dart
// Switch to second tab
await tabPath.goToIndexed(1);

// Switch to first tab
await tabPath.goToIndexed(0);

// With guard
class GuardedTab extends RouteTarget with RouteGuard {
  @override
  Future<bool> popGuard() async {
    return await confirmLeave();
  }
}
// If current tab is GuardedTab:
await tabPath.goToIndexed(2); // Guard is consulted first
```

**Throws:** `StateError` if index is out of bounds.

#### `activateRoute(T route)` → `Future<void>`

Navigates to a specific route by reference.

**Example:**
```dart
final profileTab = ProfileTab();
final tabPath = IndexedStackPath.create([
  FeedTab(),
  profileTab,
  SettingsTab(),
]);

// Navigate to profile tab
await tabPath.activateRoute(profileTab);
```

**Throws:** `StateError` if route is not found in the stack.

**Note:** Route equality is used for matching. Make sure your routes implement `==` correctly if they have parameters.

#### `reset()` → `void`

Resets all route state but keeps the active index.

```dart
tabPath.reset();
// All routes have their internal state reset
// Active index remains the same
```


#### `bindLayout(RouteLayoutConstructor constructor)`
Registers a layout constructor with the coordinator, allowing routes in this path to be wrapped by the specified layout.

**Example:**
```dart
late final profileStack = NavigationPath<AppRoute>.createWith(
  coordinator: this,
  label: 'profile',
)..bindLayout(ProfileLayout.new);
```

---


## NavigationStack Widget

A widget that renders a stack of pages based on a `NavigationPath`.

This is the core widget for imperative navigation. It listens to the `path` and updates the `Navigator` with the corresponding pages.

### Role in Navigation Flow

`NavigationStack` is the visual representation of a `NavigationPath`:
1. Listens to path changes via path listeners
2. Uses Myers diff algorithm to calculate route changes
3. Builds `Page` objects via the `resolver` callback
4. Updates Flutter's Navigator with the page stack

The widget handles:
- Page creation and disposal
- Guard execution on pop attempts
- Route result completion
- State restoration

### Constructor


```dart
NavigationStack<T extends RouteTarget>({
  Key? key,
  required NavigationPath<T> path,
  required StackTransitionResolver<T> resolver,
  T? defaultRoute,
  Coordinator? coordinator,
  GlobalKey<NavigatorState>? navigatorKey,
})
```

**Parameters:**

- **`path`** (required): The navigation path to render
  ```dart
  NavigationStack(
    path: myPath,
    resolver: resolver,
  )
  ```

- **`resolver`** (required): Function that converts routes to `StackTransition`
  ```dart
  resolver: (route) => switch (route) {
    HomeRoute() => StackTransition.material(HomeScreen()),
    ProfileRoute() => StackTransition.cupertino(ProfileScreen()),
    _ => StackTransition.material(NotFoundScreen()),
  }
  ```

- **`defaultRoute`** (optional): Initial route to push when stack initializes
  ```dart
  NavigationStack(
    path: path,
    defaultRoute: HomeRoute(), // Pushed on first build
    resolver: resolver,
  )
  ```

- **`coordinator`** (optional): Associated coordinator for this stack
  ```dart
  NavigationStack(
    path: path,
    coordinator: myCoordinator,
    resolver: resolver,
  )
  ```

- **`navigatorKey`** (optional): Key for accessing navigator state
  ```dart
  final navKey = GlobalKey<NavigatorState>();
  NavigationStack(
    path: path,
    navigatorKey: navKey,
    resolver: resolver,
  )
  // Later: navKey.currentState?.maybePop()
  ```

### Example

```dart
class MyApp extends StatelessWidget {
  final path = NavigationPath.create();
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationStack(
        path: path,
        defaultRoute: HomeRoute(),
        resolver: (route) => StackTransition.material(
          route.build(context),
        ),
      ),
    );
  }
}
```

---

## NavigationStack.declarative

Factory constructor for creating a declarative, state-driven navigation stack.

Instead of pushing and popping, you provide a list of `routes`. The widget calculates the difference between the old and new routes (using Myers diff) and updates the stack accordingly.

### Role in Navigation Flow

`DeclarativeNavigationStack` provides declarative navigation:
1. Receives a list of routes as the source of truth
2. Compares with previous route list using Myers diff
3. Updates the underlying `NavigationPath` accordingly
4. Uses the same `NavigationStack` for rendering

### Constructor


```dart
static DeclarativeNavigationStack<T> declarative<T extends RouteTarget>({
  required List<T> routes,
  required StackTransitionResolver<T> resolver,
  GlobalKey<NavigatorState>? navigatorKey,
  String? debugLabel,
})
```

**Parameters:**

- **`routes`** (required): List of routes derived from your state
  ```dart
  routes: [
    HomePage(),
    if (showProfile) ProfileRoute(),
    for (final item in items) ItemRoute(item.id),
  ]
  ```

- **`resolver`** (required): Function that converts routes to `StackTransition`
  ```dart
  resolver: (route) => switch (route) {
    HomeRoute() => StackTransition.material(HomeScreen()),
    ProfileRoute() => StackTransition.cupertino(ProfileScreen()),
    _ => StackTransition.material(NotFoundScreen()),
  }
  ```

- **`navigatorKey`** (optional): Key for accessing navigator state
  ```dart
  final navigatorKey = GlobalKey<NavigatorState>();
  NavigationStack.declarative(
    navigatorKey: navigatorKey,
    routes: routes,
    resolver: resolver,
  )
  // Later: navigatorKey.currentState?.pop()
  ```

- **`debugLabel`** (optional): Label for debugging
  ```dart
  debugLabel: 'main-navigation'
  ```

### Example

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<int> pages = [1, 2, 3];
  bool showSpecial = false;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NavigationStack.declarative(
          routes: [
            for (final page in pages) PageRoute(page),
            if (showSpecial) SpecialRoute(),
          ],
          resolver: (route) => StackTransition.material(
            route.build(context),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() => pages.add(pages.length + 1)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

**How it works:**
- When `setState` is called and routes change, Myers diff calculates the minimal set of operations
- Only changed routes are added/removed
- Existing routes are preserved with their state intact

---

## StackTransition

Defines page transition types for routes. Used by `NavigationStack` resolver.

### StackTransition.material

Standard Material page transition.

**Behavior:**
- Android: Slide from bottom
- iOS: Slide from right

```dart
StackTransition.material(
  Scaffold(
    appBar: AppBar(title: const Text('Material Page')),
    body: const Center(child: Text('Hello')),
  ),
)
```

### StackTransition.cupertino

iOS-style page transition (slide from right on all platforms).

```dart
StackTransition.cupertino(
  CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(
      middle: Text('Cupertino Page'),
    ),
    child: const Center(child: Text('Hello')),
  ),
)
```

### StackTransition.sheet

Bottom sheet presentation.

```dart
StackTransition.sheet(
  Container(
    height: 400,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: const Center(child: Text('Bottom Sheet')),
  ),
)
```

### StackTransition.dialog

Dialog presentation (centered, with barrier).

```dart
StackTransition.dialog(
  AlertDialog(
    title: const Text('Dialog'),
    content: const Text('This is a dialog'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
)
```

### StackTransition.custom

Custom transition with full control.

```dart
StackTransition.custom(
  builder: (context) => MyWidget(),
  pageBuilder: (context, key, child) => PageRouteBuilder(
    settings: RouteSettings(name: key.toString()),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  ),
)
```

---

## Type Definitions

### StackTransitionResolver<T>

Function type for resolving routes to transitions.

```dart
typedef StackTransitionResolver<T extends RouteTarget> = 
    StackTransition Function(T route);
```

**Example:**
```dart
StackTransition resolver(AppRoute route) {
  return switch (route) {
    HomeRoute() => StackTransition.material(HomeScreen()),
    ProfileRoute() => StackTransition.cupertino(ProfileScreen()),
    ModalRoute() => StackTransition.sheet(ModalSheet()),
    _ => StackTransition.material(NotFoundScreen()),
  };
}
```

---

## See Also

- [Imperative Navigation Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Using DynamicNavigationPath
- [Declarative Navigation Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) - Using NavigationStack.declarative
- [Coordinator Pattern Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md) - Using paths with Coordinator
- [Route Mixins](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - Adding behavior to routes
