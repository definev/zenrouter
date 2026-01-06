# Migrating from go_router to ZenRouter

## Why Migrate?

`go_router` is a powerful declarative router, but ZenRouter offers additional paradigm choices and a more Flutter-idiomatic API. If you're finding go_router's declarative-only approach limiting, or you want better type safety and less boilerplate, this guide will help you transition smoothly.

**What you'll gain:**
- ✅ **Paradigm flexibility** - Choose Imperative, Declarative, or Coordinator patterns
- ✅ **Better type safety** - Routes are classes, not string paths
- ✅ **Less boilerplate** - No need for path templates and parameter extraction
- ✅ **Simpler guards** - Mixin-based redirects instead of redirect callbacks
- ✅ **Cleaner layouts** - RouteLayout instead of ShellRoute nesting

---

## Quick Comparison

| Feature | go_router | ZenRouter |
|---------|-----------|-----------|
| **Routing Style** | Declarative only | Imperative, Declarative, Coordinator |
| **Route Definition** | `GoRoute` with path strings | `RouteTarget` classes |
| **Navigation** | `context.go('/path')` | `coordinator.push(Route())` |
| **Type Safety** | Require code generation | Class-based routes |
| **Guards/Redirects** | `redirect` callback | `RouteRedirect` mixin |
| **Nested Routes** | `ShellRoute` | `RouteLayout` |
| **Deep Linking** | Built-in | Built-in (Coordinator) |
| **Web Support** | Built-in | Built-in (Coordinator) |
| **Code Generation** | Not required | Optional (file-based) |

---

## Step-by-Step Migration

### 1. Update Dependencies

**Before (go_router):**
```yaml
dependencies:
  go_router: ^14.0.0
```

**After (ZenRouter):**
```yaml
dependencies:
  zenrouter: ^0.4.14
```

### 2. Choose Your Paradigm

go_router uses a declarative approach. ZenRouter offers three options:

- **Coordinator** - Most similar to go_router, recommended for web/deep linking
- **Declarative** - Pure state-driven routing
- **Imperative** - Simple push/pop navigation

For this guide, we'll use **Coordinator** as it maps most closely to go_router's capabilities.

---

## Basic Routing Migration

### go_router Example

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/products/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProductPage(id: id);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);

// In MaterialApp
MaterialApp.router(
  routerConfig: router,
);

// Navigation
context.go('/products/123');
context.push('/profile');
```

### ZenRouter Equivalent

```dart
// Define routes as classes
abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const HomePage();
  }
}

class ProductRoute extends AppRoute {
  final String id;
  ProductRoute(this.id);
  
  @override
  List<Object?> get props => [id];
  
  @override
  Uri toUri() => Uri.parse('/products/$id');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return ProductPage(id: id);
  }
}

class ProfileRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/profile');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const ProfilePage();
  }
}

// Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  late final mainPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'main',
  );
  
  @override
  List<StackPath<AppRoute>> get paths => [...super.paths, mainPath];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['products', String id] => ProductRoute(id),
      ['profile'] => ProfileRoute(),
      _ => NotFoundRoute(),
    };
  }
}

// In MaterialApp
final coordinator = AppCoordinator();

MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
);

// Navigation
coordinator.push(ProductRoute('123'));
coordinator.push(ProfileRoute());
```

**Key Differences:**
- Routes are **type-safe classes** instead of path strings
- Parameters are **constructor arguments** instead of extracted from path
- Navigation uses **route objects** instead of string paths
- URI parsing is **pattern matching** instead of template matching

---

## Nested Routes & Layouts

### go_router ShellRoute

```dart
GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNav(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
      ],
    ),
  ],
);
```

### ZenRouter RouteLayout

```dart
class MainLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => 
      coordinator.mainPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ScaffoldWithNav(
      child: buildPath(coordinator),
    );
  }
}

class HomeRoute extends AppRoute {
  @override
  Type get layout => MainLayout;
  
  @override
  Uri toUri() => Uri.parse('/home');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const HomePage();
  }
}

class SearchRoute extends AppRoute {
  @override
  Type get layout => MainLayout;
  
  @override
  Uri toUri() => Uri.parse('/search');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const SearchPage();
  }
}

// Bind layout to path
class AppCoordinator extends Coordinator<AppRoute> {
  late final mainPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'main',
  )..bindLayout(MainLayout.new);
  
  // ...
}
```

**Advantages:**
- Layouts are **reusable classes**
- Child routes declare their layout via `Type get layout`
- More explicit and type-safe

---

## Authentication & Guards

### go_router Redirect

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final isGoingToLogin = state.matchedLocation == '/login';
    
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }
    
    if (isLoggedIn && isGoingToLogin) {
      return '/';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
  ],
);
```

### ZenRouter RouteRedirect

```dart
class ProfileRoute extends AppRoute with RouteRedirect {
  @override
  Future<AppRoute> redirect() async {
    if (!AuthService.instance.isLoggedIn) {
      return LoginRoute(intendedRoute: this);
    }
    return this;
  }
  
  @override
  Uri toUri() => Uri.parse('/profile');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const ProfilePage();
  }
}

class LoginRoute extends AppRoute {
  final AppRoute? intendedRoute;
  
  LoginRoute({this.intendedRoute});
  
  @override
  List<Object?> get props => [intendedRoute];
  
  @override
  Uri toUri() => Uri.parse('/login');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return LoginPage(
      onSuccess: () {
        if (intendedRoute != null) {
          coordinator.replace(intendedRoute!);
        } else {
          coordinator.replace(HomeRoute());
        }
      },
    );
  }
}
```

**Advantages:**
- Guard logic is **attached to the route** that needs protection
- Automatic **intended route preservation**
- Per-route redirects instead of global redirect logic

---

## Restorations

### go_router

You needs to specify `restorationId` for each `GoRoute`.

### zenrouter

ZenRouter support `restoration` by default. You just need to enable it in `MaterialApp.router`.

```dart
MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
  restorationScopeId: 'app',
);
```

---

## Query Parameters

### go_router

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    return SearchPage(query: query);
  },
);

// Navigate
context.go('/search?q=flutter');
```

### ZenRouter

```dart
class SearchRoute extends AppRoute with RouteQueryParameters {
  SearchRoute({String? initialQuery}) {
    if (initialQuery != null) {
      queries({'q': initialQuery});
    }
  }
  
  @override
  Uri toUri() => Uri.parse('/search').replace(queryParameters: queries);
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return SearchPage(queryRoute: this);
  }
}

// In SearchPage
class SearchPage extends StatelessWidget {
  final SearchRoute queryRoute;
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: queryRoute.queryNotifier,
      builder: (context, queries, _) {
        final query = queries['q'];
        return Text('Searching for: $query');
      },
    );
  }
}

// Navigate
coordinator.push(SearchRoute(initialQuery: 'flutter'));
```

**Advantages:**
- Query parameters are **reactive** (ValueNotifier)
- Type-safe access via `queryParameters` map
- URL updates automatically when values change

---

## 404 Handling

### go_router

```dart
GoRouter(
  errorBuilder: (context, state) => const NotFoundPage(),
  routes: [...],
);
```

### ZenRouter

```dart
class NotFoundRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/404');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const NotFoundPage();
  }
}

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['products', String id] => ProductRoute(id),
      _ => NotFoundRoute(), // Catch-all
    };
  }
}
```

See [404 Handling Recipe](../recipes/404-handling.md) for advanced patterns.

---

## Deep Linking & Web URLs

Both go_router and ZenRouter support deep linking out of the box when using `MaterialApp.router`.

### URL Strategies

**go_router:**
```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy(); // Remove # from URLs
  runApp(MyApp());
}
```

**ZenRouter:**
```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy(); // Same as go_router
  runApp(MyApp());
}
```

See [URL Strategies Recipe](../recipes/url-strategies.md) for deployment configuration.

---

## Common Gotchas

> [!CAUTION]
> **String paths vs route objects**
> go_router uses string paths everywhere. ZenRouter uses route objects. Don't try to call `coordinator.push('/path')`—use `coordinator.push(RouteClass())`.

> [!TIP]
> **Preserve intended destinations**
> In go_router, you manually preserve `state.matchedLocation`. In ZenRouter, pass `intendedRoute` to your LoginRoute and it's automatically handled.

> [!NOTE]
> **No global redirect**
> go_router has a global `redirect` callback. ZenRouter uses per-route `RouteRedirect` mixins. This is more modular but requires adding the mixin to each protected route.

> [!WARNING]
> **Path parameter extraction**
> go_router extracts parameters from the path. ZenRouter expects you to **parse** them in `parseRouteFromUri` and **pass** them as constructor arguments.

---

## Migration Checklist

- [ ] Replace `go_router` dependency with `zenrouter`
- [ ] Convert `GoRoute` definitions to `RouteTarget` classes
- [ ] Create a `Coordinator` with `parseRouteFromUri` implementation
- [ ] Update `MaterialApp` to use `coordinator.routerDelegate` and `routeInformationParser`
- [ ] Replace `context.go()`, `context.push()` with `coordinator.push()`, `coordinator.replace()`
- [ ] Migrate `redirect` callbacks to `RouteRedirect` mixins
- [ ] Convert `ShellRoute` to `RouteLayout` classes
- [ ] Update query parameter handling to use `RouteQueryParameters`
- [ ] Test deep linking and web URLs
- [ ] Add 404 handling with catch-all pattern

---

## What You Gain

### Type Safety
```dart
// go_router - runtime error if typo
context.go('/prodcuts/123'); // No compile error!

// ZenRouter - compile-time safety
coordinator.push(ProductRoute('123')); // Type-checked!
```

### Paradigm Flexibility

If Coordinator feels heavy for your use case, switch to Imperative:

```dart
final path = NavigationPath<AppRoute>.create();

// Direct push/pop
path.push(HomeRoute());
path.push(ProductRoute('123'));
path.pop();
```

### Better Refactoring

Routes are classes, so renaming and refactoring is safer. Your IDE can find all references.

### Cleaner Deep Link Handling

```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    ['products', String id] when id.length == 36 => ProductRoute(id),
    ['products', String id] => ProductRoute(id, legacy: true),
    _ => NotFoundRoute(),
  };
}
```

Pattern matching gives you powerful URI parsing logic.

---

## Need Help?

- [ZenRouter Getting Started](../guides/getting-started.md)
- [Coordinator Pattern Guide](../paradigms/coordinator.md)
- [Authentication Recipe](../recipes/authentication-flow.md)
- [GitHub Issues](https://github.com/definev/zenrouter/issues)

---

**Happy migrating! 🧘**
