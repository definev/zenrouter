# ZenRouter 🧘

**The Flutter router that unifies Navigator 1.0 and 2.0 into one elegant system.**

ZenRouter bridges the gap between imperative navigation (Navigator 1.0) and declarative navigation (Navigator 2.0). Start with simple, imperative routing using `NavigationPath`, then optionally add the `Coordinator` pattern to make your app web-ready with deep linking support.

## Why ZenRouter?

🎯 **One System, Two Modes** - Use imperative routing for simplicity, or add declarative routing for web support  
✨ **Progressive Enhancement** - Start simple with NavigationPath, add Coordinator when you need it  
🔄 **Type-Safe** - Full type safety with compile-time route checking  
🛡️ **Powerful Guards** - Prevent unwanted navigation with async guards  
🔗 **Deep Linking Ready** - Built-in URI parsing and web navigation support  
📦 **Minimal Boilerplate** - Clean mixin-based architecture  

## Quick Start: Imperative Navigation

**Use ZenRouter like Navigator 1.0** - Simple, imperative, familiar.

### Step 1: Define Routes

```dart
import 'package:zenrouter/zenrouter.dart';

// Routes are just simple classes
class HomeRoute extends RouteTarget {}
class SettingsRoute extends RouteTarget {}
class ProfileRoute extends RouteTarget {
  final String userId;
  ProfileRoute(this.userId);

  /// See later section why we need this
  @override
  bool operator ==(Object other) {
    // First check base route equality (runtime type and navigation path)
    if (!equals(other)) return false;
    // Then check custom properties
    return other is ProfileRoute && other.userId == userId;
  }
  
  @override
  int get hashCode => Object.hash(super.hashCode, userId);
}
```

### Step 2: Create a NavigationPath

```dart
// A NavigationPath is like a navigation stack
final path = NavigationPath<RouteTarget>();
```

### Step 3: Navigate Imperatively

```dart
// Push a route (returns a Future for the result)
final result = await path.push(ProfileRoute('123'));

// Pop the current route
path.pop({'saved': true});

// Replace the entire stack
path.replace([HomeRoute(), SettingsRoute()]);
```

### Step 4: Render with NavigationStack

```dart
class MyApp extends StatelessWidget {
  final path = NavigationPath<RouteTarget>();
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationStack(
        path: path,
        resolver: (route) {
          return switch (route) {
            HomeRoute() => RouteDestination.material(HomeScreen()),
            SettingsRoute() => RouteDestination.material(SettingsScreen()),
            ProfileRoute(:final userId) => RouteDestination.material(
              ProfileScreen(userId: userId),
            ),
            _ => RouteDestination.material(NotFoundScreen()),
          };
        },
      ),
    );
  }
}
```

That's it! You now have **imperative navigation** similar to Navigator 1.0, but with better type safety and features.

---

## Level Up: Add Declarative Navigation for Web

Want **deep linking and web support**? Add the `Coordinator` pattern to make your app Navigator 2.0 ready.

### Step 1: Use RouteUnique and RouteBuilder

```dart
// Add RouteUnique for Coordinator integration
// Add RouteBuilder to define UI inline
class HomeRoute extends RouteTarget with RouteUnique, RouteBuilder {
  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.root;
  
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
```

### Step 2: Create a Coordinator

The coordinator manages navigation state and parses URIs:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['settings'] => SettingsRoute(),
      _ => HomeRoute(),
    };
  }
}

// Base class for all your routes
// 💡 Use sealed classes for exhaustive pattern matching!
sealed class AppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.root;
}
```

### Step 3: Wire Up MaterialApp.router

```dart
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
      routeInformationParser: coordinator.parser,
    );
  }
}
```

Now your app supports **deep linking and web URLs** automatically! 🎉

### Step 4: Navigate Declaratively

```dart
// Push a new route
coordinator.push(SettingsRoute());

// Replace current route
coordinator.replace(HomeRoute());

// Pop current route
coordinator.pop();
```

## Best Practices

### Use Sealed Classes for Exhaustive Routing

> [!TIP]
> **Always use `sealed class` for your route hierarchies!**
>
> Sealed classes enable exhaustive pattern matching in switch expressions, ensuring the compiler catches missing route cases at compile time.

```dart
// ✅ RECOMMENDED: Sealed class hierarchy
sealed class AppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.root;
}

class HomeRoute extends AppRoute with RouteBuilder { /* ... */ }
class SettingsRoute extends AppRoute with RouteBuilder { /* ... */ }
class ProfileRoute extends AppRoute with RouteBuilder { /* ... */ }

// Now the compiler ensures you handle ALL routes
Widget resolver(AppRoute route) {
  return switch (route) {
    HomeRoute() => RouteDestination.material(HomeScreen()),
    SettingsRoute() => RouteDestination.material(SettingsScreen()),
    ProfileRoute() => RouteDestination.material(ProfileScreen()),
    // Compiler error if you forget a route! ✓
  };
}
```

**Benefits:**
- **Compile-time safety**: Missing route cases cause compilation errors
- **Refactoring confidence**: Adding/removing routes shows all affected code
- **Better IDE support**: Auto-completion for all possible routes
- **Pattern matching**: Use destructuring to extract route parameters

```dart
// Pattern matching with parameter extraction
final destination = switch (route) {
  ProfileRoute(:final userId) => RouteDestination.material(
    ProfileScreen(userId: userId),
  ),
  // ...
};
```

### Shell Routes Must Define a Host

> [!IMPORTANT]
> **When using shell routes, you MUST define a host implementation!**
>
> Shell routes require a concrete host class that implements `RouteShellHost` to provide the container UI (e.g., bottom navigation bar, drawer).

```dart
// ✅ CORRECT: Define a host for your shell
sealed class HomeTabShell extends AppRoute with RouteShell<HomeTabShell> {
  // Define the host as a static field
  static final host = _$DefaultHomeTabShell();

  @override
  HomeTabShell get shellHost => host;

  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.home;
}

// The host implementation provides the container UI
class _$DefaultHomeTabShell extends HomeTabShell
    with RouteShellHost<HomeTabShell>, RouteBuilder {
  @override
  NavigationPath<HomeTabShell> getPath(AppCoordinator coordinator) =>
      coordinator.home;

  @override
  NavigationPath<AppRoute> getHostPath(AppCoordinator coordinator) =>
      coordinator.root;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: NavigationStack(
        path: coordinator.home,
        resolver: (route) => Coordinator.defaultResolver(coordinator, route),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Your navigation UI here
      ),
    );
  }
}

// Now define your shell children
class IdeaTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/idea');
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}

class NoteTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/note');
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}
```

**Why is this required?**
- The host provides the container UI (bottom nav, drawer, etc.)
- Shell children render inside the host's `NavigationStack`
- The host manages which child is currently active
- Without a host, shell routes have nowhere to render

**Common pattern:**
- Use a private class name like `_$DefaultHomeTabShell` for the host
- Store it as a static field in the sealed shell base class
- All shell children reference the same host instance

## Core Concepts

### Two Modes of Operation

**Imperative Mode (Navigator 1.0 style)**
- Use `NavigationPath` directly
- Call `push()`, `pop()`, `replace()` methods
- No Coordinator needed
- Perfect for mobile-only apps

**Declarative Mode (Navigator 2.0 style)**  
- Add `Coordinator` on top of NavigationPath
- Automatic deep linking and web support
- URI-based navigation
- Route-to-URL synchronization

### RouteTarget

The base class for all routes. Represents a destination in your app.

```dart
class MyRoute extends RouteTarget {
  // Routes can carry data as fields
  final String id;
  MyRoute(this.id);
}
```

> [!IMPORTANT]
> **Routes with Parameters Must Override Equality**
> 
> By default, `RouteTarget` only compares routes by runtime type and navigation path. If your route has data fields (like `id` above), you **must** override `==` and `hashCode` to include those fields.
> 
> **Always call the `equals()` helper function first** to check the base route properties, then check your custom properties:
> 
> ```dart
> class ProfileRoute extends RouteTarget {
>   final String userId;
>   ProfileRoute(this.userId);
>   
>   @override
>   bool operator ==(Object other) {
>     // First check base route equality (runtime type and navigation path)
>     if (!equals(other)) return false;
>     // Then check custom properties
>     return other is ProfileRoute && other.userId == userId;
>   }
>   
>   @override
>   int get hashCode => Object.hash(super.hashCode, userId);
> }
> ```
> 
> Without this, operations like `pushOrMoveToTop`, `remove`, and redirects won't work correctly because routes with the same data will be treated as different instances.

### NavigationPath (Imperative Core)

A stack-based container for managing routes - **this is the imperative heart of ZenRouter**.

```dart
final path = NavigationPath<MyRoute>();
await path.push(MyRoute('123'));  // Returns Future that completes when popped
path.pop({'result': true});        // Pop with a result value
path.replace([HomeRoute()]);       // Replace entire stack
```

### Coordinator (Declarative Layer)

**Optional wrapper** that adds Navigator 2.0 features on top of NavigationPath:
- Parses URIs into routes
- Syncs navigation to URLs
- Manages deep linking
- Handles multiple NavigationPaths

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // Define additional paths for nested navigation
  final NavigationPath<ShellRoute> shellPath = NavigationPath();
  
  @override
  List<NavigationPath> get paths => [root, shellPath];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // Parse URIs into your route objects
  }
}
```

## Mixin Decision Guide

ZenRouter uses mixins to add functionality to routes. Here's when to use each:

| Mixin | Purpose | When to Use | Example |
|-------|---------|-------------|---------|
| **RouteUnique** | Makes routes identifiable by Coordinator | ✅ Required for all routes used with Coordinator | Every route in your app |
| **RouteBuilder** | Declarative widget building | Use when you want to define UI inline with the route | Simple pages, one-off screens |
| **RouteGuard** | Prevent navigation away from route | Use for unsaved changes warnings, confirmation dialogs | Forms, editors |
| **RouteRedirect** | Redirect to different route | Use for conditional navigation (e.g., auth checks) | Login redirects, permission checks |
| **RouteShell** | Nested navigation child | Use for tabs, nested navigators | Tab content, drawer items |
| **RouteShellHost** | Host for shell routes | Use to create the shell container (e.g., bottom nav bar) | Tab bar scaffold, drawer scaffold |
| **RouteDeepLink** | Custom deep link handling | Use when you need custom logic beyond simple route creation | Multi-step deep linking, analytics |

### Common Combinations

#### Simple Page
```dart
class SimplePage extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/simple');
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}
```

#### Guarded Form
```dart
class FormPage extends AppRoute with RouteBuilder, RouteGuard {
  bool hasUnsavedChanges = false;
  
  @override
  FutureOr<bool> popGuard() async {
    if (!hasUnsavedChanges) return true;
    return await showConfirmDialog(context);
  }
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}
```

#### Auth Redirect
```dart
class ProtectedRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  FutureOr<AppRoute> redirect() async {
    final isAuthenticated = await authService.checkAuth();
    return isAuthenticated ? this : LoginRoute();
  }
}
```

#### Shell Navigation (Tab Bar)
```dart
// Define the sealed shell base class
sealed class HomeTabShell extends AppRoute with RouteShell<HomeTabShell> {
  static final host = _$DefaultHomeTabShell();

  @override
  HomeTabShell get shellHost => host;

  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.home;
}

// Shell host (the scaffold with bottom navigation)
class _$DefaultHomeTabShell extends HomeTabShell
    with RouteShellHost<HomeTabShell>, RouteBuilder {
  @override
  NavigationPath<HomeTabShell> getPath(AppCoordinator coordinator) =>
      coordinator.home;
  
  @override
  NavigationPath<AppRoute> getHostPath(AppCoordinator coordinator) =>
      coordinator.root;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: NavigationStack(
        path: coordinator.home,
        resolver: (route) => Coordinator.defaultResolver(coordinator, route),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) => switch (index) {
          0 => coordinator.replace(IdeaTab()),
          1 => coordinator.replace(NoteTab()),
          _ => null,
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Idea'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Note'),
        ],
      ),
    );
  }
}

// Shell children (tab pages)
class IdeaTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/idea');
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}

class NoteTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/note');
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}
```

#### Deep Link with Custom Logic
```dart
class ProductDetail extends AppRoute with RouteBuilder, RouteDeepLink {
  final String productId;
  ProductDetail(this.productId);
  
  @override
  Uri toUri() => Uri.parse('/product/$productId');
  
  @override
  FutureOr<void> deeplinkHandler(coordinator, uri) {
    // Custom logic: ensure category is in stack first
    coordinator.replace(CategoryRoute());
    coordinator.push(ProductDetail(productId));
    analytics.logDeepLink(uri);
  }
  
  @override
  Widget build(coordinator, context) => Scaffold(...);
}
```

## Advanced Features

### Async Redirects

Redirects can be asynchronous, perfect for auth checks:

```dart
class DashboardRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Future<AppRoute> redirect() async {
    final user = await authService.getCurrentUser();
    return user != null ? this : LoginRoute();
  }
}
```

### Redirect Chains

Redirects can chain together:

```dart
// A -> B -> C results in navigation to C
coordinator.push(RedirectToB());  // RedirectToB redirects to RedirectToC
// User ends up at C
```

### Route Guards

Guards can prevent navigation based on state:

```dart
class EditPage extends AppRoute with RouteBuilder, RouteGuard {
  @override
  FutureOr<bool> popGuard() async {
    if (!hasChanges) return true;  // Allow pop
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Discard')),
        ],
      ),
    );
    
    return shouldPop ?? false;  // Prevent pop unless confirmed
  }
}
```

### Deep Linking

ZenRouter automatically handles deep links by parsing URIs:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['product', final id] => ProductRoute(id),
      ['category', final cat] => CategoryRoute(cat),
      _ => HomeRoute(),
    };
  }
}
```

By default, deep links replace the current route. Change this with `deeplinkStrategy`:

```dart
class ProductRoute extends AppRoute with RouteBuilder {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;  // Push instead of replace
}
```

### Nested Navigation (Shells)

Create complex navigation hierarchies with shells:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  final shellPath = NavigationPath<ShellRoute>();
  
  @override
  List<NavigationPath> get paths => [root, shellPath];
}

// The shell host provides the UI container
class TabShell extends AppRoute with RouteShellHost, RouteBuilder {
  @override
  Widget build(coordinator, context) {
    return Scaffold(
      body: NavigationStack(
        path: coordinator.shellPath,
        resolver: (route) => Coordinator.defaultResolver(coordinator, route),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [...],
        onTap: (index) {
          switch (index) {
            case 0: coordinator.replace(Tab1());
            case 1: coordinator.replace(Tab2());
          }
        },
      ),
    );
  }
}
```

### Custom Page Transitions

ZenRouter provides built-in page types:

```dart
RouteDestination.material(child);       // Material page transition
RouteDestination.cupertino(child);      // Cupertino page transition  
RouteDestination.sheet(child);          // Bottom sheet presentation
RouteDestination.dialog(child);         // Dialog presentation
```

Override the destination for custom transitions:

```dart
class CustomRoute extends AppRoute with RouteBuilder {
  @override
  RouteDestination<AppRoute> destination(coordinator) {
    return RouteDestination.custom(
      builder: (context) => MyWidget(),
      pageBuilder: (context, key, child) => CustomPage(key: key, child: child),
    );
  }
}
```

## Decision Tree: Choosing the Right Mixins

```
Start here: Does your route need to work with Coordinator?
│
├─ Yes → Add RouteUnique ✓
│   │
│   └─ Do you need nested navigation (tabs, drawer)?
│       │
│       ├─ Yes, this is the container/host → Add RouteShellHost + RouteBuilder
│       │
│       └─ Yes, this is a child/tab → Add RouteShell + RouteBuilder
│           │
│           └─ Need custom deep linking logic?
│               ├─ Yes → Add RouteDeepLink
│               └─ No → Done! ✓
│
└─ No → Just use RouteTarget for simple navigation paths
    │
    └─ Do you need to prevent navigation away?
        │
        ├─ Yes → Add RouteGuard
        │
        └─ No → Do you need to redirect to another route?
            │
            ├─ Yes → Add RouteRedirect
            │
            └─ No → Done! ✓
```

## API Reference

### Core Classes

- **`RouteTarget`** - Base class for all routes
- **`NavigationPath<T>`** - Stack-based route container
- **`Coordinator<T>`** - Navigation coordinator and manager
- **`NavigationStack`** - Widget that renders a navigation path
- **`RouteDestination`** - Route-to-widget resolver

### Mixins

- **`RouteUnique`** - Required for Coordinator integration
- **`RouteBuilder`** - Declarative widget building
- **`RouteGuard`** - Pop prevention and confirmation
- **`RouteRedirect<T>`** - Route redirection
- **`RouteShell<T>`** - Nested navigation child
- **`RouteShellHost<T>`** - Nested navigation host
- **`RouteDeepLink`** - Custom deep link handling

### Enums

- **`DeeplinkStrategy`** - `.push` or `.replace` for deep links

## Examples

Check out the [example](example/) directory for complete working examples:

- **Basic Navigation** - Simple push/pop navigation
- **Shell Navigation** - Tab bars and nested navigation
- **Guards and Redirects** - Protected routes and conditional navigation
- **Deep Linking** - URL-based navigation

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.
