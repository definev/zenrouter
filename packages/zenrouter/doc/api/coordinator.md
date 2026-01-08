# Coordinator API

Complete API reference for the `Coordinator` class and related types.

## Overview

The `Coordinator` class manages multiple navigation paths, handles deep linking, and synchronizes navigation with URLs. It's the central router for the coordinator paradigm.

---

## Coordinator<T>

Base class for creating coordinators.

### Class Definition

```dart
abstract class Coordinator<T extends RouteUnique> {
  // Main navigation path (always present)
  final NavigationPath<T> root;
  
  // Additional paths for nested navigation
  List<StackPath> get paths;

  // Active state properties
  RouteLayout? get activeLayout;
  List<RouteLayout> get activeLayouts;
  List<StackPath> get activeLayoutPaths;
  StackPath<T> get activePath;
  Uri get currentUri;
  NavigatorState get navigator;
  
  // Parse URLs into routes
  T parseRouteFromUri(Uri uri);
  
  // Navigation methods
  Future<dynamic> push(T route);
  void pop();
  void replace(T route);
  void pushOrMoveToTop(T route);
  Future<bool?> tryPop();
  
  // Router integration
  CoordinatorRouterDelegate get routerDelegate;
  CoordinatorRouteParser get routeInformationParser;
}
```

### Creating a Coordinator

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // Define navigation paths
  late final homeStack = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'home',
  );
  
  late final tabPath = IndexedStackPath<AppRoute>.createWith(
    [
      FeedTab(),
      ProfileTab(),
      SettingsTab(),
    ],
    coordinator: this,
    label: 'tab',
  );
  
  @override
  List<StackPath> get paths => [root, homeStack, tabPath];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['settings'] => SettingsRoute(),
      _ => NotFoundRoute(uri),
    };
  }
}

// Use with MaterialApp.router
final coordinator = AppCoordinator();

MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```

---

## Properties

### `root` → `NavigationPath<T>`

The main navigation path. Always present and managed by the coordinator.

```dart
// Access the root stack
coordinator.root.stack;

// Get current root route
final currentRoute = coordinator.root.stack.last;

// Check stack depth
if (coordinator.root.stack.length > 1) {
  print('Can go back');
}
```

**Note:** You typically don't manipulate `root` directly - use coordinator methods like `push()`, `pop()`, etc.

### `paths` → `List<StackPath>`

All navigation paths managed by this coordinator.

**Must include:** The `root` path plus any additional paths for nested navigation.

```dart
@override
List<StackPath> get paths => [
  root,              // Main path (required!)
  homeStack,         // Home navigation
  settingsStack,     // Settings navigation
  tabPath,           // Tab bar (fixed)
  feedStack,         // Feed nested navigation
];
```

**Important:** Always include `root` in the list!

### `activeLayout` → `RouteLayout?`

Returns the deepest active `RouteLayout` in the navigation hierarchy.

Returns `null` if the root is the active layout.

### `activeLayouts` → `List<RouteLayout>`

Returns all active `RouteLayout` instances in the navigation hierarchy, from root to deepest.

### `activeLayoutPaths` → `List<StackPath>`

Returns the list of active layout paths in the navigation hierarchy, starting from `root`.

### `activePath` → `StackPath<T>`

Returns the currently active `StackPath`. This is the path that contains the currently active route.

### `currentUri` → `Uri`

Returns the current URI based on the active route.

### `navigator` → `NavigatorState`

Access to the `NavigatorState`.

### `routerDelegate` → `CoordinatorRouterDelegate`

Router delegate for `MaterialApp.router`.

Manages the navigator stack and handles system navigation events (back button, etc.).

```dart
MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```

**Access Navigator:**
```dart
// Get the navigator context
final context = coordinator.routerDelegate.navigatorKey.currentContext;

// Get the navigator state
final navigator = coordinator.routerDelegate.navigatorKey.currentState;
```

### `routeInformationParser` → `CoordinatorRouteParser`

Route information parser for URL handling.

Converts between `RouteInformation` and `Uri`.

```dart
MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```

Also available as `routeInformationParser` for convenience:
```dart
coordinator.routeInformationParser; // Same as coordinator.routeInformationParser
```

---

## Methods

### `parseRouteFromUri(Uri uri)` → `T`

**Abstract method** - You must implement this to parse URLs into routes.

Called when:
- App opens with a deep link
- User navigates to a URL in browser
- `recoverRouteFromUri()` is called manually

```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),
    ['profile', final id] => ProfileRoute(id),
    ['settings'] => SettingsRoute(),
    ['product', final id] => ProductRoute(id),
    _ => NotFoundRoute(uri),
  };
}
```

**With query parameters:**
```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  final filter = uri.queryParameters['filter'];
  final sort = uri.queryParameters['sort'];
  
  return switch (uri.pathSegments) {
    ['products'] => ProductListRoute(filter: filter, sort: sort),
    _ => NotFoundRoute(uri),
  };
}
```

**Tips:**
- Use pattern matching for clean URL parsing
- Handle query parameters when needed
- Always return a route (use NotFound for unmatched URLs)
- Consider using named parameters: `['user', final userId]`

**Best practice:** Use sealed classes for exhaustive matching!
```dart
sealed class AppRoute extends RouteTarget with RouteUnique {}

@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),
    ['profile'] => ProfileRoute(),
    // Compiler ensures all routes are handled!
  };
}
```

### `push(T route)` → `Future<dynamic>`

Pushes a route onto its appropriate navigation path.

The coordinator automatically:
1. Resolves which path the route belongs to (via `route.layout`)
2. Ensures all parent layouts are in place
3. Pushes the route to the correct path
4. Updates the browser URL

```dart
// Simple push
await coordinator.push(ProfileRoute('user123'));

// The coordinator figures out:
// 1. Which path ProfileRoute belongs to
// 2. What parent layouts need to be created
// 3. Pushes route to correct path
// 4. Updates URL to /profile/user123
```

**With nested navigation:**
```dart
class FeedDetailRoute extends AppRoute {
  @override
  Type? get layout => FeedTabLayout;
}

// Pushing FeedDetailRoute
coordinator.push(FeedDetailRoute('123'));

// Coordinator automatically:
// 1. Creates/resolves FeedTabLayout
// 2. Pushes FeedDetailRoute to feedStack
// 3. Updates URL
```

**With redirects:**
```dart
class ProtectedRoute extends AppRoute with RouteRedirect {
  @override
  Future<AppRoute> redirect() async {
    return await auth.check() ? this : LoginRoute();
  }
}

// If not authenticated, redirects to LoginRoute
coordinator.push(ProtectedRoute());
```

**Returns:** Future that completes when route resolution is done.

### `pop()` → `void`

Pops the last route from the nearest dynamic path.

The coordinator:
1. Finds the deepest active dynamic path
2. Consults route guards (if present)
3. Pops the route if guard allows
4. Cleans up empty paths
5. Updates the browser URL

```dart
await coordinator.pop();
```

**With guards:**
```dart
class GuardedRoute extends AppRoute with RouteGuard {
  @override
  Future<bool> popGuard() async {
    return await confirmExit();
  }
}

// If current route is GuardedRoute
await coordinator.pop(); // Guard is consulted first
```

**Behavior:**
- If stack becomes empty after pop, the coordinator handles cleanup
- Browser back button automatically calls `pop()`
- Returns `void`

### `replace(T route)` → `void`

Wipes the current navigation stack and replaces it with the new route.

All paths are cleared and the route is pushed to the appropriate path.

```dart
// Replace entire navigation with login
await coordinator.replace(LoginRoute());
// All previous routes are cleared
// Stack is now just [LoginRoute]

// After logout
coordinator.replace(WelcomeRoute());

// After completing a flow
coordinator.replace(DashboardRoute());
```

**Use cases:**
- Logging out (clear authenticated routes, show login)
- Completing wizards (clear wizard routes, show result)
- Resetting navigation state

**Note:** Unlike `push()`, this **does not** consult guards. It's a forced reset.

### `pushOrMoveToTop(T route)` → `void`

Pushes a route or moves it to the top if already present in its path.

Useful for tab navigation where you don't want duplicates.

```dart
// Switch tabs without duplicating routes
onTap: (index) => switch (index) {
  0 => coordinator.pushOrMoveToTop(FeedTab()),
  1 => coordinator.pushOrMoveToTop(ProfileTab()),
  2 => coordinator.pushOrMoveToTop(SettingsTab()),
  _ => null,
}
```

**Behavior:**
- If route is already in its path, it's moved to the top
- If not present, it's pushed normally
- Follows redirects (like `push()`)
- Updates URL

### `pushReplacement<R, RO>(T route, {RO? result})` → `Future<R?>`

Pops the current route and pushes a new route in its place.

**Parameters:**
- `route`: The new route to push after popping
- `result`: Optional value to pass to the popped route's `push()` Future

**Returns:** A `Future` that completes when the new route is popped. Returns `null` if redirect resolution fails or guard blocks the pop.

```dart
// Replace current screen without adding to history
await coordinator.pushReplacement(HomeRoute());

// Replace with result for the popped route
await coordinator.pushReplacement<void, String>(
  HomeRoute(),
  result: 'completed',
);
```

**Result handling:**
```dart
// Screen A pushes B and waits for result
final result = await coordinator.push<String>(ScreenBRoute());
print('Got: $result'); // Prints: Got: from_c

// Screen B replaces itself with C, passing result to A
coordinator.pushReplacement<void, String>(
  ScreenCRoute(),
  result: 'from_c',
);
```

**Behavior:**
1. Resolves any `RouteRedirect`s
2. Ensures required `RouteLayout` hierarchy is active
3. Delegates to `StackMutatable.pushReplacement`:
   - On single-element stack: completes the route and pushes new one
   - On multi-element stack: pops (respecting guards), then pushes
4. Updates the browser URL

**Use cases:**
- Login → Home transition (back should not return to login)
- Splash/Loading → Main content transition
- Wizard flows where previous steps shouldn't be revisited
- Replacing temporary screens with actual content

**With guards:**
```dart
// If current route has RouteGuard that returns false
final result = await coordinator.pushReplacement(HomeRoute());
// Returns null if guard blocks the pop
```

### `recoverRouteFromUri(Uri uri)` → `Future<void>`

Handles navigation from a deep link URI.

Called automatically when:
- App opens with a deep link
- Browser URL changes
- System navigation event occurs

Can also be called manually:

```dart
// Handle a custom deep link
await coordinator.recoverRouteFromUri(
  Uri.parse('myapp://product/123?ref=email'),
);

// Parse and navigate
final uri = Uri.parse('/profile/settings');
await coordinator.recoverRouteFromUri(uri);
```

**Process:**
1. Calls `parseRouteFromUri(uri)` to get the route
2. Checks if route has `RouteDeepLink` mixin
3. If yes and strategy is `custom`: Calls `route.deeplinkHandler()`
4. If yes and strategy is `push`: Calls `push(route)`
5. If no or strategy is `replace`: Calls `replace(route)` (default)

**Deep link strategies:**
```dart
class MyRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri) async {
    // Custom setup logic
    coordinator.replace(HomeTab());
    coordinator.push(this);
    analytics.logDeepLink(uri);
  }
}
```

### `defineLayout()` → `void`

Registers layout constructors for Type-based layout creation.

**Override** to register your layout types:

```dart
@override
void defineLayout() {
  RouteLayout.defineLayout(TabBarLayout, () => TabBarLayout());
  RouteLayout.defineLayout(SettingsLayout, () => SettingsLayout());
  RouteLayout.defineLayout(ProductsLayout, () => ProductsLayout());
}
```

**Required when:**
- Using `RouteLayout` with nested navigation
- Routes specify a `layout` Type

**Important:** Call this in your Coordinator constructor (happens automatically).

### `layoutBuilder(BuildContext context)` → `Widget`

Builds the root widget (the primary navigator).

**Override** to customize the root navigation structure:

```dart
@override
Widget layoutBuilder(BuildContext context) {
  return Scaffold(
    body: RouteLayout.buildRoot(this),
    drawer: Drawer(
      child: DrawerContent(),
    ),
  );
}
```

**Default implementation:**
```dart
@override
Widget layoutBuilder(BuildContext context) {
  return RouteLayout.buildRoot(this);
}
```

### `tryPop()` → `Future<bool?>`

Attempts to pop the nearest dynamic path.

**Returns:**
- `true` if the route was popped
- `false` if the route prevented the pop (via guard)
- `null` if the guard wants manual control

```dart
final didPop = await coordinator.tryPop();
if (didPop == true) {
  print('Successfully popped');
} else if (didPop == false) {
  print('Pop was blocked by guard');
} else {
  print('Guard is handling it manually');
}
```

**With guards:**
```dart
class EditorRoute extends AppRoute with RouteGuard {
  @override
  Future<bool> popGuard() async {
    // Return false to prevent pop
    if (hasUnsavedChanges) return false;
    return true;
  }
}
```

**Note:** Called automatically by system back button. You rarely need to call this manually.

---

## Mixins

### CoordinatorNavigatorObserver

Mixin that provides a list of observers for the coordinator's navigator.

When applied to a `Coordinator`, this mixin allows you to define global `NavigatorObserver`s that will be automatically applied to all `NavigationStack` widgets that use this coordinator.

#### Mixin Definition

```dart
mixin CoordinatorNavigatorObserver on Coordinator {
  /// A list of observers that apply for every NavigationPath in the coordinator.
  List<NavigatorObserver> get observers;
}
```

#### Usage

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorNavigatorObserver {
  
  // Define global observers
  @override
  List<NavigatorObserver> get observers => [
    MyAnalyticsObserver(),
    MyLoggingObserver(),
  ];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // ... route parsing
  }
}
```

#### How It Works

When a `NavigationStack` is created with a coordinator that has this mixin:

1. The `NavigationStack` checks if the coordinator implements `CoordinatorNavigatorObserver`
2. If yes, it combines the coordinator's observers with any local observers
3. All observers are passed to the underlying `Navigator` widget

```dart
// In NavigationStack
Navigator(
  observers: [
    ...coordinator.observers,  // From CoordinatorNavigatorObserver
    ...widget.observers,        // Local observers
  ],
)
```

#### Example: Analytics Observer

```dart
class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    analytics.logScreenView(route.settings.name);
  }
  
  @override
  void didPop(Route route, Route? previousRoute) {
    analytics.logScreenView(previousRoute?.settings.name);
  }
}

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorNavigatorObserver {
  
  @override
  List<NavigatorObserver> get observers => [
    AnalyticsObserver(),
  ];
  
  // ... rest of coordinator
}
```

#### Example: Combining Global and Local Observers

```dart
// Global observers in coordinator
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorNavigatorObserver {
  
  @override
  List<NavigatorObserver> get observers => [
    AnalyticsObserver(),      // Track all navigation
    PerformanceObserver(),    // Monitor performance
  ];
}

// Local observers in NavigationStack
NavigationStack<AppRoute>(
  path: coordinator.root,
  coordinator: coordinator,
  observers: [
    DebugObserver(),  // Only for this stack
  ],
  resolver: (route) => route.transition,
)

// Result: Navigator gets all three observers:
// [AnalyticsObserver, PerformanceObserver, DebugObserver]
```

#### Example: Logging Observer

```dart
class LoggingObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print('📍 Pushed: ${route.settings.name}');
  }
  
  @override
  void didPop(Route route, Route? previousRoute) {
    print('📍 Popped: ${route.settings.name}');
  }
  
  @override
  void didRemove(Route route, Route? previousRoute) {
    print('📍 Removed: ${route.settings.name}');
  }
  
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    print('📍 Replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }
}

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorNavigatorObserver {
  
  @override
  List<NavigatorObserver> get observers => [
    if (kDebugMode) LoggingObserver(),
  ];
}
```

#### Benefits

- **Centralized Monitoring**: Define observers once in the coordinator instead of repeating them for each `NavigationStack`
- **Consistent Tracking**: Ensures all navigation paths use the same observers
- **Easy Testing**: Mock or replace observers at the coordinator level
- **Clean Separation**: Keep navigation logic separate from observation logic

#### When to Use

Use `CoordinatorNavigatorObserver` when you need to:
- Track all navigation events for analytics
- Log navigation for debugging
- Monitor performance across all routes
- Implement global navigation behaviors
- Test navigation flows

Use local observers (on `NavigationStack`) when you need:
- Stack-specific tracking
- Different observers for different navigation contexts
- Temporary debugging observers

---

## Related Classes

### CoordinatorRouterDelegate<T>

Router delegate that connects the coordinator to Flutter's Router.

**Properties:**
- `navigatorKey` → Key for accessing navigator state
- `currentConfiguration` → Current URI

**Methods:**
- `build(BuildContext)` → Builds the navigator widget
- `setNewRoutePath(Uri)` → Handles URL changes
- `popRoute()` → Handles system back button

**Usage:**
```dart
// Access navigator
final context = coordinator.routerDelegate.navigatorKey.currentContext;
final navigator = coordinator.routerDelegate.navigatorKey.currentState;

// Get current URL
final uri = coordinator.routerDelegate.currentConfiguration;
```

### CoordinatorRouteParser<T>

Parses `RouteInformation` to and from `Uri`.

**Methods:**
- `parseRouteInformation(RouteInformation)` → Parses to URI
- `restoreRouteInformation(Uri)` → Converts back to RouteInformation

**Usage:**
```dart
// Typically used automatically by MaterialApp.router
MaterialApp.router(
  routeInformationParser: coordinator.routeInformationParser,
  routerDelegate: coordinator.routerDelegate,
)
```

---

## Extension Types

### CoordinatorUtils<T>

Utility methods for `NavigationPath`.

```dart
extension type CoordinatorUtils<T extends RouteTarget>(
  NavigationPath<T> path
) {
  // Clears the path and sets a single route
  void setRoute(T route);
}
```

**Usage:**
```dart
// Clear and set a single route
CoordinatorUtils(coordinator.homeStack).setRoute(HomeRoute());

// Or directly if imported
coordinator.homeStack.setRoute(HomeRoute());
```

---

## Complete Example

```dart
// Define routes
sealed class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => coordinator.push(ProfileRoute()),
          child: const Text('Go to Profile'),
        ),
      ),
    );
  }
}

class ProfileRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/profile');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}

// Create coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile'] => ProfileRoute(),
      _ => HomeRoute(),
    };
  }
}

// Use in app
void main() {
  runApp(const MyApp());
}

final coordinator = AppCoordinator();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}
```

---

## See Also

- [Coordinator Pattern Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md) - Complete usage guide
- [Route Mixins](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - RouteUnique, RouteLayout, RouteDeepLink
- [Navigation Paths](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md) - NavigationPath, IndexedStackPath
- [Deep Linking Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/deep-linking.md) - Deep linking setup (if exists)
