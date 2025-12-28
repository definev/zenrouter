<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

# ZenRouter File Generator

[![pub package](https://img.shields.io/pub/v/zenrouter_file_generator.svg)](https://pub.dev/packages/zenrouter_file_generator)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)

</div>

A code generator for **file-based routing** in Flutter using [zenrouter](https://pub.dev/packages/zenrouter). Generate type-safe routes from your file/directory structure, similar to Next.js, Nuxt.js or expo-router.

This package is part of the [ZenRouter](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/README.md) ecosystem and builds on the Coordinator paradigm for deep linking and web support.

## Features

- 🗂️ **File = Route** - Each file in `routes/` becomes a route automatically
- 📁 **Nested layouts** - `_layout.dart` files define layout wrappers for nested routes
- 🔗 **Dynamic routes** - `[param].dart` files create typed path parameters
- 🌟 **Catch-all routes** - `[...params].dart` files capture multiple path segments
- 📦 **Route groups** - `(name)/` folders wrap routes in layouts without affecting URLs
- 🎯 **Type-safe navigation** - Generated extension methods for type-safe navigation
- 📱 **Full ZenRouter support** - Deep linking, guards, redirects, transitions, and more
- 🚀 **Zero boilerplate** - Routes are generated from your file structure
- 🕸️ **Lazy loading** - Routes can be lazy loaded using the `deferredImport` option in the `@ZenCoordinator` annotation. Improves app startup time and reduces initial bundle size.

## Installation

Add `zenrouter_file_generator`, `zenrouter_file_annotation` and `zenrouter` to your `pubspec.yaml`:

```yaml
dependencies:
  zenrouter: ^0.4.10
  zenrouter_file_annotation: ^0.4.9

dev_dependencies:
  build_runner: ^2.10.4
  zenrouter_file_generator: ^0.4.9
```

## Quick Start

### 1. Create your routes directory structure

Organize your routes in `lib/routes/` following these conventions:

```
lib/routes/
├── index.dart            → /
├── about.dart            → /about
├── (auth)/               → Route group (no URL segment)
│   ├── _layout.dart      → AuthLayout wrapper
│   ├── login.dart        → /login
│   └── register.dart     → /register
├── profile/
│   └── [id].dart         → /profile/:id
├── docs/
│   └── [...slugs]/       → Catch-all: /docs/a/b/c
│       └── index.dart    → /docs/any/path
└── tabs/
    ├── _layout.dart      → Layout for tabs
    ├── feed/
    │   ├── index.dart    → /tabs/feed
    │   └── [postId].dart → /tabs/feed/:postId
    ├── profile.dart      → /tabs/profile
    └── settings.dart     → /tabs/settings
```

### 2. Define routes with `@ZenRoute`

```dart
// lib/routes/about.dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_file_generator/zenrouter_file_generator.dart';
import 'routes.zen.dart';

part 'about.g.dart';

@ZenRoute()
class AboutRoute extends _$AboutRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Page')),
    );
  }
}
```

### 3. Dynamic parameters with `[param].dart`

Files named with brackets create dynamic route parameters:

```dart
// lib/routes/profile/[id].dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'routes.zen.dart';

part '[id].g.dart';

@ZenRoute()
class ProfileIdRoute extends _$ProfileIdRoute {
  ProfileIdRoute({required super.id});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile: $id')),
      body: Center(child: Text('User ID: $id')),
    );
  }
}
```

### 3.1 Catch-all parameters with `[...params].dart`

Folders or files named with `[...name]` capture **all remaining path segments** as a `List<String>`. This is useful for:

- Documentation pages: `/docs/getting-started/installation`
- File paths: `/files/folder/subfolder/file.txt`
- Arbitrary nested routing: `/blog/2024/01/my-post-title`

```dart
// lib/routes/docs/[...slugs]/index.dart
// Matches: /docs/any/number/of/segments
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'routes.zen.dart';

part 'index.g.dart';

@ZenRoute()
class DocsRoute extends _$DocsRoute {
  DocsRoute({required super.slugs}); // slugs is List<String>

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Docs: ${slugs.join('/')}'),
      body: Center(
        child: Column(
          children: [
            Text('Path segments: ${slugs.length}'),
            for (final slug in slugs) Text('- $slug'),
          ],
        ),
      ),
    );
  }
}
```

#### Combining with other parameters

You can have additional routes inside a catch-all folder:

```
lib/routes/
└── docs/
    └── [...slugs]/
        ├── index.dart      → /docs/a/b/c (catch-all)
        ├── about.dart      → /docs/a/b/c/about
        └── [id].dart       → /docs/a/b/c/:id
```

```dart
// lib/routes/docs/[...slugs]/[id].dart
// Matches: /docs/any/path/user-123
@ZenRoute()
class DocsItemRoute extends _$DocsItemRoute {
  DocsItemRoute({required super.slugs, required super.id});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Item: $id')),
      body: Text('In path: ${slugs.join('/')}'),
    );
  }
}
```

#### Generated pattern matching

The generator uses Dart's rest patterns for URL parsing:

```dart
// Generated parseRouteFromUri
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    ['docs', ...final slugs] => DocsRoute(slugs: slugs),
    ['docs', ...final slugs, final id] => DocsItemRoute(slugs: slugs, id: id),
    _ => NotFoundRoute(uri: uri),
  };
}

// Generated navigation methods
extension AppCoordinatorNav on AppCoordinator {
  Future<dynamic> pushDocs(List<String> slugs) => 
    push(DocsRoute(slugs: slugs));
  Future<dynamic> pushDocsItem(List<String> slugs, String id) => 
    push(DocsItemRoute(slugs: slugs, id: id));
}
```

> **Note:** Only one catch-all parameter is allowed per route. Routes with static segments are prioritized over catch-all routes during matching.

### 4. Layouts with `_layout.dart`

Layouts wrap child routes in a common UI structure:

```dart
// lib/routes/tabs/_layout.dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'routes.zen.dart';

part '_layout.g.dart';

@ZenLayout(
  type: LayoutType.indexed,
  routes: [FeedRoute, ProfileRoute, SettingsRoute],
)
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    
    return Scaffold(
      body: buildPath(coordinator),
      // You control the UI completely
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (i) => coordinator.push(path.stack[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

### 5. Run build_runner

Generate the routing code:

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

### 6. Use in your app

```dart
import 'package:flutter/material.dart';
import 'routes/routes.zen.dart';

final coordinator = AppCoordinator();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// Type-safe navigation with generated methods
coordinator.pushAbout();              // Push to /about
coordinator.pushProfileId('user-123'); // Push to /profile/user-123
coordinator.replaceIndex();            // Replace with home
coordinator.recoverTabProfile();       // Deep link to /tabs/profile
```

## File Naming Conventions

| Pattern | URL | Description |
|---------|-----|-------------|
| `index.dart` | `/path` | Route at directory level |
| `about.dart` | `/path/about` | Named route |
| `[id].dart` | `/path/:id` | Dynamic parameter (single segment) |
| `[...slugs]/` | `/path/*` | Catch-all parameter (multiple segments, `List<String>`) |
| `_layout.dart` | - | Layout wrapper (not a route) |
| `_*.dart` | - | Private files (ignored) |
| `(group)/` | - | Route group (layout without URL segment) |

### Dot Notation

You can also use dot notation in file names to represent directory nesting. This helps flatten your file structure while keeping deep URL paths.

`parent.child.dart` is equivalent to `parent/child.dart`.

**Examples:**
- `shop.products.[id].dart` → `/shop/products/:id`
- `settings.account.dart` → `/settings/account`
- `docs.[version].index.dart` → `/docs/:version`

This is especially useful for grouping related deep routes without creating many nested folders.

## Route Groups `(name)`

Route groups allow you to wrap routes with a layout **without adding the folder name to the URL path**. This is useful for:

- Grouping related routes under a shared layout (e.g., auth flows)
- Organizing routes without affecting URL structure
- Applying different styling/themes to route groups

### Example

```
lib/routes/
├── (auth)/                 # Route group - wraps routes without URL segment
│   ├── _layout.dart        # AuthLayout - shared auth styling
│   ├── login.dart          → /login (NOT /(auth)/login)
│   └── register.dart       → /register (NOT /(auth)/register)
├── (marketing)/
│   ├── _layout.dart        # MarketingLayout
│   ├── landing.dart        → /landing
│   └── pricing.dart        → /pricing
└── dashboard/
    └── index.dart          → /dashboard
```

### Creating a Route Group Layout

```dart
// lib/routes/(auth)/_layout.dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter/zenrouter.dart';

import '../routes.zen.dart';

part '_layout.g.dart';

@ZenLayout(type: LayoutType.stack)
class AuthLayout extends _$AuthLayout {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Container(
        // Auth-specific styling (gradient, logo, etc.)
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
        ),
        child: buildPath(coordinator),
      ),
    );
  }
}
```

### Routes Inside Route Groups

```dart
// lib/routes/(auth)/login.dart
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part 'login.g.dart';

// URL: /login (not /(auth)/login)
// Layout: AuthLayout
@ZenRoute()
class LoginRoute extends _$LoginRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: 'Email')),
          TextField(decoration: InputDecoration(labelText: 'Password')),
          ElevatedButton(
            onPressed: () => coordinator.replaceIndex(),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
```

### Generated Code

The generator correctly handles route groups:

```dart
// Generated parseRouteFromUri
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    ['login'] => LoginRoute(),      // /login - wrapped by AuthLayout
    ['register'] => RegisterRoute(), // /register - wrapped by AuthLayout
    ['dashboard'] => DashboardRoute(),
    _ => NotFoundRoute(uri: uri),
  };
}

// Generated navigation methods
extension AppCoordinatorNav on AppCoordinator {
  Future<dynamic> pushLogin() => push(LoginRoute());
  Future<dynamic> pushRegister() => push(RegisterRoute());
}
```

## Deferred Imports

Improve your app's startup time by lazy-loading routes using deferred imports. When enabled, routes are only loaded when first navigated to, reducing initial bundle size.

### Per-Route Configuration

Enable deferred imports for individual routes:

```dart
@ZenRoute(deferredImport: true)
class HeavyRoute extends _$HeavyRoute {
  // Route implementation
}
```

### Global Configuration

Enable deferred imports for all routes via `build.yaml`:

```yaml
# In your project's build.yaml (not the package's build.yaml)
targets:
  $default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: true
```

### Precedence Rules

1. **Route annotation takes precedence**: `deferredImport: false` in annotation overrides global config
2. **IndexedStack routes are always non-deferred**: Routes in `LayoutType.indexed` cannot use deferred imports
3. **Otherwise, global config applies**: Routes without explicit annotation use the global setting

### Example with Global Config

```yaml
# build.yaml
targets:
  $default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: true  # All routes deferred by default
```

```dart
// Most routes use deferred imports automatically
@ZenRoute()  // Uses global config (deferred)
class AboutRoute extends _$AboutRoute { }

// Explicitly disable for critical routes
@ZenRoute(deferredImport: false)  // Override global config
class HomeRoute extends _$HomeRoute { }

// IndexedStack routes are always non-deferred
@ZenLayout(
  type: LayoutType.indexed,
  routes: [Tab1Route, Tab2Route],  // Always non-deferred
)
class TabsLayout extends _$TabsLayout { }
```

### Generated Code

With deferred imports enabled:

```dart
// Generated imports
import 'about.dart' deferred as about;
import 'home.dart';  // Non-deferred (explicit or IndexedStack)

// Generated navigation
Future<void> pushAbout() async => push(await () async {
  await about.loadLibrary();
  return about.AboutRoute();
}());

Future<void> pushHome() => push(HomeRoute());  // No deferred loading
```

### Performance Benchmarks

Real-world benchmarks demonstrate significant initial bundle size reductions with deferred imports:

| Metric | Without Deferred | With Deferred | Improvement |
|--------|-----------------|---------------|-------------|
| **Initial bundle** | 2,414 KB | 2,155 KB | **-259 KB (-10.7%)** ✅ |
| **Total app size** | 2,719 KB | 2,759 KB | +40 KB (+1.5%) |
| **Deferred chunks** | 0 | 24 chunks | - |

**Key Benefits:**
- ✅ **10.7% faster initial load** - Users see the app faster
- ✅ **On-demand loading** - Routes load only when navigated to
- ✅ **Better caching** - Unchanged routes won't re-download
- ⚠️ **Minimal overhead** - Only 1.5% total size increase

**Recommendation:** For most applications, enabling deferred imports provides substantial initial load improvements with minimal trade-offs. The feature is especially effective for apps with many routes or large route components.

See the example's [BENCHMARK_ANALYSIS.md](example/BENCHMARK_ANALYSIS.md) for detailed measurements.

## Route Mixins

Enable advanced behaviors with annotation parameters:

```dart
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

@ZenRoute(
  guard: true,      // RouteGuard - control pop behavior
  redirect: true,   // RouteRedirect - conditional routing
  deepLink: DeeplinkStrategyType.custom, // Custom deep link handling
  transition: true, // RouteTransition - custom animations
  queries: ['search', 'page'], // Query parameters
)
class CheckoutRoute extends _$CheckoutRoute {
  @override
  FutureOr<bool> popGuard() async {
    return await confirmExit();
  }
  
  @override
  FutureOr<AppRoute?> redirect() async {
    if (!auth.isLoggedIn) return LoginRoute();
    return null; // null means proceed with this route
  }
  
  @override
  FutureOr<void> deeplinkHandler(AppCoordinator c, Uri uri) async {
    c.replace(HomeRoute());
    c.push(CartRoute());
    c.push(this);
  }
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final searchTerm = query('search');
    final page = query('page');
    return CheckoutScreen(search: searchTerm, page: page);
  }
}
```

## Route Query Parameters

You can easily handle query parameters with reactive updates using the `queries` parameter in `@ZenRoute`.

### 1. Enable Query Support

```dart
// Enable all query parameters
@ZenRoute(queries: ['*'])
class SearchRoute extends _$SearchRoute { ... }

// OR enable specific parameters
@ZenRoute(queries: ['q', 'page', 'sort'])
class SearchRoute extends _$SearchRoute { ... }
```

### 2. Access and Watch Queries

Use `selectorBuilder` to rebuild *only* when specific query parameters change, avoiding unnecessary rebuilds.

```dart
@override
Widget build(AppCoordinator coordinator, BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Search Results')),
    body: Column(
      children: [
        // Rebuilds ONLY when 'q' query param changes
        selectorBuilder<String>(
          selector: (queries) => queries['q'] ?? '',
          builder: (context, searchTerm) {
            return Text('Searching for: $searchTerm');
          },
        ),
        // ... rest of UI
      ],
    ),
  );
}
```

### 3. Update Queries

You can update queries without full navigation (preserving widget state where possible). The URL will be updated automatically.

```dart
// Update specific query param
updateQueries(
  coordinator, 
  queries: {...queries, 'page': '2'},
);

// Clear all queries
updateQueries(coordinator, queries: {});
```

## Layout Types

### Stack Layout (NavigationPath)

For push/pop navigation:

```dart
@ZenLayout(type: LayoutType.stack)
class SettingsLayout extends _$SettingsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: buildPath(coordinator),
    );
  }
}
```

### Indexed Layout (IndexedStackPath)

For tabs/drawers:

```dart
@ZenLayout(
  type: LayoutType.indexed,
  routes: [Tab1Route, Tab2Route, Tab3Route], // Order = index
)
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    
    return Scaffold(
      body: buildPath(coordinator),
      // Full control over navigation UI
      bottomNavigationBar: YourNavigationWidget(
        index: path.activePathIndex,
        onTap: (i) => coordinator.push(path.stack[i]),
      ),
    );
  }
}
```

## Generated Code Structure

After running `build_runner`, your routes directory will look like:

```
lib/routes/
├── index.dart          # Your route class
├── index.g.dart        # Generated base class
├── about.dart
├── about.g.dart
└── routes.zen.dart     # Generated coordinator
```

### Generated Coordinator

The generator creates `routes.zen.dart` with:

- `AppRoute` base class (or custom name via `@ZenCoordinator`)
- `AppCoordinator` class with `parseRouteFromUri` implementation
- Navigation path definitions for layouts
- Type-safe navigation extension methods (push/replace/recover)

```dart
// routes.zen.dart (generated)
abstract class AppRoute extends RouteTarget with RouteUnique {}

class AppCoordinator extends Coordinator<AppRoute> {
  final IndexedStackPath<AppRoute> tabsPath = IndexedStackPath([...]);
  
  @override
  List<StackPath> get paths => [root, tabsPath];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['about'] => AboutRoute(),
      ['profile', final id] => ProfileIdRoute(id: id),
      _ => NotFoundRoute(uri: uri),
    };
  }
}

// Type-safe navigation extensions
extension AppCoordinatorNav on AppCoordinator {
  // Push, Replace, Recover methods for each route
  Future<dynamic> pushAbout() => push(AboutRoute());
  void replaceAbout() => replace(AboutRoute());
  void recoverAbout() => recoverRouteFromUri(AboutRoute().toUri());
  
  // Routes with parameters
  Future<dynamic> pushProfileId(String id) => push(ProfileIdRoute(id: id));
  void replaceProfileId(String id) => replace(ProfileIdRoute(id: id));
  void recoverProfileId(String id) => recoverRouteFromUri(ProfileIdRoute(id: id).toUri());
}
```

### Navigation Methods: Push / Replace / Recover

For each route, the generator creates **three type-safe navigation methods**:

| Method | Return Type | Description |
|--------|-------------|-------------|
| `push{Route}()` | `Future<dynamic>` | Push route onto stack. Returns result when popped. |
| `replace{Route}()` | `void` | Replace current route. No navigation history. |
| `recover{Route}()` | `void` | Restore full navigation state from URI. For deep links. |

#### When to Use Each Method

**`push` - Standard Navigation**
```dart
// Navigate forward, user can go back
coordinator.pushAbout();
coordinator.pushProfileId('user-123');

// Wait for result when route pops
final result = await coordinator.pushCheckout();
if (result == 'success') { /* ... */ }
```

**`replace` - Replace Current Route**
```dart
// After login, replace login screen with home (no back button to login)
coordinator.replaceIndex();

// Switch tabs without adding to history
coordinator.replaceTabProfile();
```

**`recover` - Deep Link / State Restoration**
```dart
// Restore complete navigation state from a URI
// This rebuilds the entire navigation stack to reach the target route
coordinator.recoverProfileId('user-123');
// Equivalent to: coordinator.recoverRouteFromUri(Uri.parse('/profile/user-123'));

// Use for:
// - Deep links from external sources
// - App state restoration
// - Sharing URLs that should restore full navigation context
```

#### Example: Auth Flow

```dart
// On app start - check auth and recover appropriate state
if (isLoggedIn) {
  coordinator.recoverIndex();  // Restore to home with full stack
} else {
  coordinator.replaceLogin();  // Show login, no back navigation
}

// After successful login
coordinator.replaceIndex();  // Replace login with home

// User taps profile
coordinator.pushProfileId('current-user');  // Can go back to home
```

#### Example: Deep Link Handling

```dart
// When app receives deep link: myapp://profile/user-123
void handleDeepLink(Uri uri) {
  // recover rebuilds navigation stack: [Home] -> [Profile]
  coordinator.recoverProfileId('user-123');
}
```

## Custom Coordinator Configuration

Customize the generated coordinator by creating `lib/routes/_coordinator.dart`:

```dart
// lib/routes/_coordinator.dart
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

@ZenCoordinator(
  name: 'MyAppCoordinator',
  routeBase: 'MyAppRoute',
)
class CoordinatorConfig {}
```

## Integration with ZenRouter

This package generates routes compatible with zenrouter's coordinator pattern:

- Routes extend `RouteTarget with RouteUnique`
- Layouts use `RouteLayout` mixin
- Dynamic routes have typed parameters
- Full deep linking and URL synchronization support
- Route guards, redirects, and transitions

See the [zenrouter documentation](https://pub.dev/packages/zenrouter) for more details on advanced features.

## Example

Check out the `/example` directory for a complete working example:

```bash
cd example
flutter pub get
dart run build_runner build
flutter run
```

## License

Apache License 2.0 - see LICENSE file for details.
