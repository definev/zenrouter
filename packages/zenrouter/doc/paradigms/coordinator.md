# Coordinator Pattern

> **Centralize routing, handle deep links, manage nested navigation**

The coordinator pattern provides a centralized routing system with deep linking, URL synchronization, and support for complex nested navigation hierarchies. It's the most powerful paradigm in ZenRouter, building on top of the imperative foundation.

## When to Use Coordinator

✅ **Use coordinator pattern when:**
- You need deep linking or web URL support
- Building for web with browser navigation
- You want centralized route management
- You have complex nested navigation (tabs within tabs, drawer + tabs)
- You need URL-based routing and navigation
- You want debuggable route state
- You're building a large app with many routes

❌ **Don't use coordinator when:**
- Building simple mobile-only apps (use [Imperative](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) instead)
- Navigation is purely state-driven (use [Declarative](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) instead)
- You don't need URL synchronization

## Core Concept

A `Coordinator` manages multiple `StackPath`s and provides:
1. **URI Parsing** - Converts URLs to routes
2. **Route Resolution** - Finds the correct path for each route
3. **Deep Linking** - Handles incoming deep links
4. **Nested Navigation** - Manages multiple navigation stacks
5. **Back Button Handling** - Smart back navigation across stacks

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // Define multiple paths for nested navigation
  final NavigationPath<AppRoute> homeStack = NavigationPath();
  final IndexedStackPath<AppRoute> tabStack = IndexedStackPath([...]);
  
  @override
  List<StackPath> get paths => [root, homeStack, tabStack];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // Parse URLs into routes
    return switch (uri.pathSegments) {
      ['home'] => HomeRoute(),
      ['profile', final id] => ProfileRoute(id),
      _ => NotFoundRoute(),
    };
  }
}
```

The coordinator automatically:
- Syncs URLs with navigation state
- Handles browser back/forward buttons
- Resolves nested navigation hierarchies
- Manages route relationships

## Complete Example: Nested Navigation App

This example demonstrates a complete app with:
- Tab bar with fixed tabs
- Nested navigation within tabs
- Settings stack separate from main navigation
- Deep linking support
- Route guards and redirects

### Step 1: Define Route Hierarchy

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// Base class for all routes
abstract class AppRoute extends RouteTarget with RouteUnique {}

// Home layout - contains the tab bar
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;
  
  @override
  Uri toUri() => Uri.parse('/home');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RouteLayout.layoutBuilderTable[RouteLayout.navigationPath]!(
        coordinator,
        coordinator.homeStack,
        this,
      ),
    );
  }
}

// Tab bar layout - uses IndexedStack for tabs
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type? get layout => HomeLayout; // Nested inside HomeLayout
  
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabIndexed;
  
  @override
  Uri toUri() => Uri.parse('/home/tabs');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabIndexed;
    
    return Scaffold(
      body: Column(
        children: [
          // Tab content
          Expanded(
            child: RouteLayout.layoutBuilderTable[RouteLayout.indexedStackPath]!(
              coordinator,
              path,
              this,
            ),
          ),
          
          // Tab bar
          BottomNavigationBar(
            currentIndex: path.activePathIndex,
            onTap: (index) => switch (index) {
              0 => coordinator.push(FeedTab()),
              1 => coordinator.push(ProfileTab()),
              2 => coordinator.push(SettingsTab()),
              _ => null,
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ],
      ),
    );
  }
}

// Tab routes
class FeedTab extends AppRoute {
  @override
  Type? get layout => TabBarLayout;
  
  @override
  Uri toUri() => Uri.parse('/home/tabs/feed');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Feed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ListTile(
          title: const Text('Post 1'),
          onTap: () => coordinator.push(FeedDetail(id: '1')),
        ),
        ListTile(
          title: const Text('Post 2'),
          onTap: () => coordinator.push(FeedDetail(id: '2')),
        ),
      ],
    );
  }
}

class ProfileTab extends AppRoute {
  @override
  Type? get layout => TabBarLayout;
  
  @override
  Uri toUri() => Uri.parse('/home/tabs/profile');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => coordinator.push(ProfileDetail()),
        child: const Text('View Profile Details'),
      ),
    );
  }
}

class SettingsTab extends AppRoute {
  @override
  Type? get layout => TabBarLayout;
  
  @override
  Uri toUri() => Uri.parse('/home/tabs/settings');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => coordinator.push(GeneralSettings()),
        child: const Text('Go to Full Settings'),
      ),
    );
  }
}

// Detail routes (nested within tab navigation)
class FeedDetail extends AppRoute with RouteGuard, RouteRedirect, RouteDeepLink {
  final String id;
  
  FeedDetail({required this.id});
  
  @override
  Type? get layout => HomeLayout;
  
  @override
  Uri toUri() => Uri.parse('/home/feed/$id');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed Detail $id')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Post $id', style: const TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  List<Object?> get props => [id];
  
  // Guard: Confirm before leaving
  @override
  Future<bool> popGuard() async {
    final confirm = await showDialog<bool>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        title: const Text('Leave page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }
  
  // Redirect: Special ID redirects to profile
  @override
  Future<AppRoute?> redirect() async {
    if (id == 'profile') return ProfileDetail();
    return this;
  }
  
  // Deep link: Custom handling
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // Ensure we're in the right tab first
    coordinator.replace(FeedTab());
    coordinator.push(this);
  }
}

class ProfileDetail extends AppRoute {
  @override
  Type? get layout => HomeLayout;
  
  @override
  Uri toUri() => Uri.parse('/home/profile/detail');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Detail')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => coordinator.pop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}

// Settings stack (separate from main navigation)
class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.settingsStack;
  
  @override
  Uri toUri() => Uri.parse('/settings');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RouteLayout.layoutBuilderTable[RouteLayout.navigationPath]!(
        coordinator,
        coordinator.settingsStack,
        this,
      ),
    );
  }
  
}

class GeneralSettings extends AppRoute {
  @override
  Type? get layout => SettingsLayout;
  
  @override
  Uri toUri() => Uri.parse('/settings/general');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Account Settings'),
          onTap: () => coordinator.push(AccountSettings()),
        ),
        ListTile(
          title: const Text('Privacy Settings'),
          onTap: () => coordinator.push(PrivacySettings()),
        ),
      ],
    );
  }
}

class AccountSettings extends AppRoute {
  @override
  Type? get layout => SettingsLayout;
  
  @override
  Uri toUri() => Uri.parse('/settings/account');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(child: Text('Account Settings'));
  }
}

class PrivacySettings extends AppRoute {
  @override
  Type? get layout => SettingsLayout;
  
  @override
  Uri toUri() => Uri.parse('/settings/privacy');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(child: Text('Privacy Settings'));
  }
}
```

### Step 2: Create the Coordinator

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // Define navigation paths
  final NavigationPath<AppRoute> homeStack = NavigationPath('home');
  final NavigationPath<AppRoute> settingsStack = NavigationPath('settings');
  final IndexedStackPath<AppRoute> tabIndexed = IndexedStackPath([
    FeedTab(),
    ProfileTab(),
    SettingsTab(),
  ], 'tabs');
  
  @override
  List<StackPath> get paths => [
    root,
    homeStack,
    settingsStack,
    tabIndexed,
  ];
  
  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, () => HomeLayout());
    RouteLayout.defineLayout(TabBarLayout, () => TabBarLayout());
    RouteLayout.defineLayout(SettingsLayout, () => SettingsLayout());
  }
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      // Root - default to feed tab
      [] => FeedTab(),
      
      // Home routes
      ['home'] => FeedTab(),
      ['home', 'tabs'] => FeedTab(),
      ['home', 'tabs', 'feed'] => FeedTab(),
      ['home', 'tabs', 'profile'] => ProfileTab(),
      ['home', 'tabs', 'settings'] => SettingsTab(),
      ['home', 'feed', final id] => FeedDetail(id: id),
      ['home', 'profile', 'detail'] => ProfileDetail(),
      
      // Settings routes
      ['settings'] => GeneralSettings(),
      ['settings', 'general'] => GeneralSettings(),
      ['settings', 'account'] => AccountSettings(),
      ['settings', 'privacy'] => PrivacySettings(),
      
      // Not found
      _ => NotFoundRoute(uri: uri),
    };
  }
}

class NotFoundRoute extends AppRoute {
  final Uri uri;
  
  NotFoundRoute({required this.uri});
  
  @override
  Uri toUri() => Uri.parse('/not-found');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Route not found: ${uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.replace(FeedTab()),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Wire Up MaterialApp.router

```dart
void main() {
  runApp(const MyApp());
}

final appCoordinator = AppCoordinator();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Coordinator Example',
      routerDelegate: appCoordinator.routerDelegate,
      routeInformationParser: appcoordinator.routeInformationParser,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
```

Now you have:
- ✅ Deep linking: Open `yourapp://home/feed/123` goes directly to post 123
- ✅ Web URLs: Navigate to `/settings/privacy` in browser
- ✅ Browser back button support
- ✅ Nested navigation (tabs, settings, details)
- ✅ Route guards and redirects

## API Reference

For complete API documentation including all methods, properties, and advanced usage, see:

**[→ Coordinator API Reference](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md)**

Quick reference for `Coordinator`:

| Method | Description |
|--------|-------------|
| `parseRouteFromUri(Uri)` | Abstract method to parse URLs into routes |
| `push(T)` | Push route onto appropriate path |
| `pop()` | Pop from nearest dynamic path |
| `replace(T)` | Wipe stack and replace with route |
| `pushOrMoveToTop(T)` | Push or move route to top |
| `recoverRouteFromUri(Uri)` | Handle deep link URI |

| Property | Description |
|----------|-------------|
| `root` | Main navigation path (always present) |
| `paths` | All navigation paths managed by coordinator |
| `routerDelegate` | Router delegate for MaterialApp.router |
| `parser` | Route information parser |

**Example:**
```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile'] => ProfileRoute(),
      _ => NotFoundRoute(),
    };
  }
}

MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```


## Route Mixins for Coordinator

These mixins provide special functionality when using the coordinator pattern:

### RouteUnique

**Required** for all routes used with Coordinator.

```dart
mixin RouteUnique on RouteTarget {
  // Convert route to URL
  Uri toUri();
  
  // Build the UI for this route
  Widget build(Coordinator coordinator, BuildContext context);
  
  // Optional: Layout layout for nested navigation
  RouteLayout? get layout => null;
}
```

**Example:**
```dart
class HomeRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
```

### RouteLayout<T>

Creates a navigation layout that contains other routes.

```dart
mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  // Which path does this layout manage?
  StackPath<RouteUnique> resolvePath(Coordinator coordinator);
  
  // Builds the layout UI (automatically delegates to layoutBuilderTable)
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context);
  
  // Optional: Parent layout Type
  @override
  Type? get layout => null;
  
  // Static tables for layout construction and building
  static Map<Type, RouteLayoutConstructor> layoutConstructorTable = {};
  static Map<String, RouteLayoutBuilder> layoutBuilderTable = {...};
  
  // Register a layout constructor
  static void defineLayout<T extends RouteLayout>(
    Type layoutType,
    T Function() constructor,
  );
}
```

**Example - NavigationStack style navigation layout:**
```dart
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RouteLayout.layoutBuilderTable[RouteLayout.navigationPath]!(
        coordinator,
        coordinator.homeStack,
        this,
      ),
    );
  }
}

// Routes specify layout using Type reference
class DetailRoute extends AppRoute {
  @override
  Type? get layout => HomeLayout;
}

// Register in Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, () => HomeLayout());
  }
}
```

**Example - Indexed navigation layout (tabs):**
```dart
class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    return Scaffold(
      body: RouteLayout.layoutBuilderTable[RouteLayout.indexedStackPath]!(
        coordinator,
        path,
        this,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (index) => coordinator.push(tabs[index]),
        items: [...],
      ),
    );
  }
}

// Tab routes use Type reference
class HomeTab extends AppRoute {
  @override
  Type? get layout => TabLayout;
}
```

### RouteDeepLink

Custom deep link handling with strategies.

```dart
mixin RouteDeepLink on RouteUnique {
  // Strategy for handling deep links
  DeeplinkStrategy get deeplinkStrategy;
  
  // Custom deep link handler
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri);
}

enum DeeplinkStrategy {
  replace,  // Replace current stack (default)
  push,     // Push onto current stack
  custom,   // Use custom handler
}
```

**Example:**
```dart
class ProductRoute extends AppRoute with RouteDeepLink {
  final String productId;
  
  ProductRoute(this.productId);
  
  @override
  Uri toUri() => Uri.parse('/product/$productId');
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // Custom logic: ensure we're in the right tab
    coordinator.replace(ShopTab());
    
    // Load product data
    final product = await loadProduct(productId);
    
    // Then navigate to this route
    coordinator.push(this);
    
    // Log analytics
    analytics.logDeepLink(uri);
  }
}
```

## Deep Linking

### How Deep Links Work

1. App opens with URL: `myapp://home/feed/123`
2. Coordinator calls `parseRouteFromUri(Uri.parse('myapp://home/feed/123'))`
3. You return: `FeedDetail(id: '123')`
4. Coordinator checks if route has `RouteDeepLink`
   - If yes and strategy == `custom`: Call `deeplinkHandler()`
   - If yes and strategy == `push`: Push route
   - If no: Replace stack with route

### Deep Link Strategies

#### Replace (Default)

Replaces the entire stack with the deep link route:

```dart
// URL: myapp://profile/123
// Result: Stack = [ProfileRoute('123')]
```

#### Push

Pushes the route onto the existing stack:

```dart
class MyRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
}

// If stack was [HomeRoute()]
// After deep link: Stack = [HomeRoute(), ProfileRoute('123')]
```

#### Custom

Full control over deep link handling:

```dart
class CheckoutRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // 1. Ensure user is logged in
    if (!await auth.isLoggedIn()) {
      coordinator.replace(LoginRoute(
        redirectTo: uri.toString(),
      ));
      return;
    }
    
    // 2. Set up the navigation stack
    coordinator.replace(HomeRoute());
    coordinator.push(CartRoute());
    coordinator.push(this);
    
    // 3. Track analytics
    analytics.logDeepLink(uri);
  }
}
```

### Testing Deep Links

#### iOS Simulator
```bash
xcrun simctl openurl booted "myapp://home/feed/123"
```

#### Android Emulator
```bash
adb shell am start -W -a android.intent.action.VIEW \\
  -d "myapp://home/feed/123" com.example.myapp
```

#### Flutter
```dart
// In your code
coordinator.recoverRouteFromUri(
  Uri.parse('myapp://home/feed/123'),
);
```

## See Also

- [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Direct stack control
- [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) - State-driven routing
- [Route Mixins Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - All available mixins
- [Coordinator API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md) - Complete API reference
- [Deep Linking Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/deep-linking.md) - Deep linking setup
