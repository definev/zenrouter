# Migrating from auto_route to ZenRouter

## Why Migrate?

`auto_route` provides excellent code generation for routing, but ZenRouter offers similar power without requiring build_runner on every change. If you want faster iteration, more control, or prefer writing routes as classes over annotations, this guide will help.

**What you'll gain:**
- ✅ **No build_runner delays** - Routes are plain Dart classes
- ✅ **Faster development** - No waiting for code generation
- ✅ **More control** - Direct access to routing logic
- ✅ **Optional code gen** - Use file-based routing generator if you prefer
- ✅ **Paradigm choice** - Not locked into one routing style

---

## Quick Comparison

| Feature | auto_route | ZenRouter |
|---------|-----------|-----------|
| **Route Definition** | `@RoutePage()` annotations | `RouteTarget` classes |
| **Code Generation** | Required (`build_runner`) | Optional (file-based) |
| **Navigation** | `context.router.push()` | `coordinator.push()` |
| **Guards** | `AutoRouteGuard` classes | `RouteRedirect` mixin |
| **Nested Routing** | `AutoRoute.new()` with children | `RouteLayout` + multiple paths |
| **Type Safety** | Generated routes | Native Dart classes |
| **Tab Navigation** | `AutoTabsRouter` | `IndexedStackPath` |
| **Deep Linking** | Built-in | Built-in (Coordinator) |

---

## Step-by-Step Migration

### 1. Update Dependencies

**Before (auto_route):**
```yaml
dependencies:
  auto_route: ^9.0.0

dev_dependencies:
  auto_route_generator: ^9.0.0
  build_runner: ^2.4.0
```

**After (ZenRouter):**
```yaml
dependencies:
  zenrouter: ^0.4.14

# Optional: if you want file-based generation
dev_dependencies:
  zenrouter_generator: ^0.4.14
  build_runner: ^2.4.0
```

### 2. Remove Build Configuration

Delete or rename `build.yaml` if it was only used for auto_route.

---

## Basic Routing Migration

### auto_route Example

```dart
// Route definition with annotation
@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.router.push(ProductRoute(id: '123'));
          },
          child: const Text('Go to Product'),
        ),
      ),
    );
  }
}

@RoutePage()
class ProductPage extends StatelessWidget {
  final String id;
  
  const ProductPage({
    super.key,
    @PathParam('id') required this.id,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $id')),
      body: Center(child: Text('Viewing product: $id')),
    );
  }
}

// Router configuration
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: ProductRoute.page, path: '/products/:id'),
  ];
}

// In main.dart
final _appRouter = AppRouter();

MaterialApp.router(
  routerConfig: _appRouter.config(),
);
```

### ZenRouter Equivalent

```dart
// Route definitions (no annotations needed!)
abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
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
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ProductPage(id: id);
  }
}

// Pages (unchanged)
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final coordinator = context.coordinator<AppCoordinator>();
    
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            coordinator.push(ProductRoute('123'));
          },
          child: const Text('Go to Product'),
        ),
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  final String id;
  
  const ProductPage({super.key, required this.id});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $id')),
      body: Center(child: Text('Viewing product: $id')),
    );
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
      _ => NotFoundRoute(),
    };
  }
}

// In main.dart
final coordinator = AppCoordinator();

MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
);
```

**Key Differences:**
- **No annotations** - Routes are just classes
- **No `build_runner`** - Changes take effect immediately
- **Parameters** - Constructor arguments instead of `@PathParam`
- **Navigation** - `coordinator.push()` instead of `context.router.push()`

---

## Guards & Auth

### auto_route Guards

```dart
class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (AuthService.instance.isAuthenticated) {
      resolver.next(true);
    } else {
      resolver.redirect(LoginRoute(onResult: (success) {
        resolver.next(success);
      }));
    }
  }
}

// In router config
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: ProfileRoute.page, guards: [AuthGuard()]),
    AutoRoute(page: LoginRoute.page),
  ];
}
```

### ZenRouter RouteRedirect

```dart
mixin AuthGuard on RouteRedirect {
  AppRoute get intendedRoute;

  @override
  Future<AppRoute> redirect() async {
    if (!AuthService.instance.isAuthenticated) {
      return LoginRoute(intendedRoute: intendedRoute);
    }
    return this;
  }
}

class ProfileRoute extends AppRoute with AuthGuard {
  @override
  AppRoute get intendedRoute => ProfileRoute();
  
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
- Guard logic is reusable but still local to the route
- Automatic intended route preservation

See [Authentication Flow Recipe](../recipes/authentication-flow.md) for more patterns.

---

## Tab Navigation

### auto_route AutoTabsRouter

```dart
@RoutePage()
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: [
        HomeRoute(),
        SearchRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
```

### ZenRouter IndexedStackPath

```dart
class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => 
      coordinator.tabPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return RootLayout(
      coordinator: coordinator,
      child: buildPath(coordinator),
    );
  }
}

class HomeRoute extends AppRoute {
  @override
  Type get layout => TabLayout;
  
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const HomePage();
  }
}

// Similar for SearchRoute, ProfileRoute...

class AppCoordinator extends Coordinator<AppRoute> {
  late final tabPath = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'tab',
    [
      HomeRoute(),
      SearchRoute(),
      ProfileRoute(),
    ],
  )..bindLayout(TabLayout.new);
  
  @override
  List<StackPath<AppRoute>> get paths => [...super.paths, tabPath];
  
  void switchToTab(int index) => tabPath.activeIndex = index;
  int get currentTab => tabPath.activeIndex;
}

class RootLayout extends StatelessWidget {
  final AppCoordinator coordinator;
  final Widget child;
  
  const RootLayout({super.key, required this.coordinator, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: ListenableBuilder(
        listenable: coordinator.tabPath,
        builder: (context, _) {
          return BottomNavigationBar(
            currentIndex: coordinator.currentTab,
            onTap: coordinator.switchToTab,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          );
        },
      ),
    );
  }
}
```

**Advantages:**
- No magic method in `Coordinator` to call
- All tab switching logic own by `IndexedStackPath`
- Deep linking & State Restoration works out of the box

See [Bottom Navigation Recipe](../recipes/bottom-navigation.md) for advanced patterns.

---

## Nested Routes

### auto_route Children

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: DashboardRoute.page,
      children: [
        AutoRoute(page: OverviewRoute.page, initial: true),
        AutoRoute(page: DetailsRoute.page),
        AutoRoute(page: SettingsRoute.page),
      ],
    ),
  ];
}

@RoutePage()
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AutoRouter(); // Renders child routes
  }
}
```

### ZenRouter RouteLayout

```dart
class DashboardLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => 
      coordinator.dashboardPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return DashboardScaffold(
      child: buildPath(coordinator), // Renders child routes
    );
  }
}

class OverviewRoute extends AppRoute {
  @override
  Type get layout => DashboardLayout;
  
  @override
  Uri toUri() => Uri.parse('/dashboard');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const OverviewPage();
  }
}

class DetailsRoute extends AppRoute {
  @override
  Type get layout => DashboardLayout;
  
  @override
  Uri toUri() => Uri.parse('/dashboard/details');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const DetailsPage();
  }
}

class AppCoordinator extends Coordinator<AppRoute> {
  late final dashboardPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'dashboard',
  )..bindLayout(DashboardLayout.new);
  
  @override
  List<StackPath<AppRoute>> get paths => [...super.paths, dashboardPath];
}
```

---

## Query Parameters

### auto_route

```dart
@RoutePage()
class SearchPage extends StatelessWidget {
  final String? query;
  
  const SearchPage({super.key, @QueryParam() this.query});
  
  @override
  Widget build(BuildContext context) {
    return Text('Searching: $query');
  }
}

// Navigate
context.router.push(SearchRoute(query: 'flutter'));
```

### ZenRouter

```dart
class SearchRoute extends AppRoute with RouteQueryParameters {
  SearchRoute({String? query}) {
    if (query != null) {
      queries({'q': query});
    }
  }
  
  @override
  Uri toUri() => Uri.parse('/search').replace(queryParameters: queries);
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return SearchPage(searchRoute: this);
  }
}

class SearchPage extends StatelessWidget {
  final SearchRoute searchRoute;
  
  const SearchPage({super.key, required this.searchRoute});
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: searchRoute.queryNotifier,
      builder: (context, queries, _) {
        final q = queries['q'];
        return Text('Searching: $q');
      },
    );
  }
}

// Navigate
coordinator.push(SearchRoute(query: 'flutter'));
```

**Advantage:** 
- Query parameters are **reactive** - changing the value updates the URL automatically.
- You can listen separately on each query parameter and achieve fine-grained control over the UI.

---

## Common Gotchas

> [!CAUTION]
> **Context extensions**
> auto_route adds `context.router`. ZenRouter doesn't have it build-in. You can create your own `InheritedWidget` to provide the `coordinator` to the widget tree.

> [!TIP]
> **No more build_runner**
> After migration, you can remove `flutter packages pub run build_runner build` from your workflow. Changes to routes take effect immediately!

> [!NOTE]
> **Route parameters**
> auto_route uses `@PathParam` and `@QueryParam`. ZenRouter uses constructor arguments and `RouteQueryParameters` mixin.

> [!WARNING]
> **Navigation API**
> Replace all `context.router.push()` / `context.router.pop()` / `context.router.replace()` with `coordinator.push()` / `coordinator.pop()` / `coordinator.replace()`.

---

## Migration Checklist

- [ ] Replace `auto_route` dependencies with `zenrouter`
- [ ] Remove `build_runner` configuration (or keep for other packages)
- [ ] Convert `@RoutePage()` classes to `RouteTarget` classes
- [ ] Remove `@PathParam`, `@QueryParam` annotations
- [ ] Create a `Coordinator` with `parseRouteFromUri`
- [ ] Replace `context.router.*` with `coordinator.*`
- [ ] Convert`AutoRouteGuard` to `RouteRedirect` mixins
- [ ] Migrate `AutoTabsRouter` to `IndexedStackPath`
- [ ] Update nested routes to use `RouteLayout`
- [ ] Test deep linking and navigation flows
- [ ] Remove generated `*.gr.dart` files

---

## What You Gain

### Faster Iteration

```bash
# auto_route
# Edit route → run build_runner → wait → see changes
flutter pub run build_runner build

# ZenRouter
# Edit route → hot reload → see changes immediately!
```

### No Code Generation Complexity

No more dealing with:
- `part 'file.gr.dart';` statements
- Build cache issues
- Generated file conflicts in version control
- Build runner configuration

### More Direct Control

```dart
// Custom route resolution logic
@override
AppRoute parseRouteFromUri(Uri uri) {
  // Add custom logic here
  if (uri.host == 'legacy.example.com') {
    return LegacyRedirectRoute(uri);
  }
  
  return switch (uri.pathSegments) {
    ['products', String id] => ProductRoute(id),
    _ => NotFoundRoute(),
  };
}
```

---

## Optional: File-Based Routing Generator

If you prefer code generation, ZenRouter has an optional generator:

```yaml
dev_dependencies:
  zenrouter_generator: ^0.4.14
  build_runner: ^2.4.0
```

Create route files in a special directory structure, and the generator creates the coordinator for you. Best of both worlds!

---

## Need Help?

- [ZenRouter Getting Started](../guides/getting-started.md)
- [Coordinator Pattern Guide](../paradigms/coordinator.md)
- [Bottom Navigation Recipe](../recipes/bottom-navigation.md)
- [Authentication Recipe](../recipes/authentication-flow.md)
- [GitHub Issues](https://github.com/definev/zenrouter/issues)

---

**Happy migrating! 🧘**
