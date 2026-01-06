# Migrating from Navigator 1.0 / 2.0 to ZenRouter

## Why Migrate?

Flutter's Navigator APIs are powerful but low-level. Navigator 1.0 requires manual route management, and Navigator 2.0 (Router API) has a steep learning curve. ZenRouter simplifies both approaches while adding type safety, better IDE support, and modern patterns.

**What you'll gain:**
- ✅ **Type-safe routes** - No more string-based route names
- ✅ **Better DX** - Less boilerplate than Navigator 2.0
- ✅ **Paradigm choice** - Use Imperative (like Navigator 1.0) or Coordinator (like Navigator 2.0)
- ✅ **Deep linking** - Built-in support without complex setup
- ✅ **State restoration** - Automatic with Coordinator pattern

---

## Quick Comparison

| Feature | Navigator 1.0 | Navigator 2.0 | ZenRouter |
|---------|---------------|---------------|-----------|
| **API Style** | Imperative | Declarative | Both + Coordinator |
| **Type Safety** | String routes | Manual | Built-in |
| **Deep Linking** | Complex | Built-in | Built-in (Coordinator) |
| **State Restoration** | Manual | Manual | Automatic (Coordinator) |
| **Learning Curve** | Low | High | Medium |
| **Boilerplate** | Low | High | Low-Medium |

---

## From Navigator 1.0

### Navigator 1.0 Example

```dart
// Route names
class Routes {
  static const home = '/';
  static const product = '/product';
  static const profile = '/profile';
}

// MaterialApp with routes
MaterialApp(
  initialRoute: Routes.home,
  routes: {
    Routes.home: (context) => const HomePage(),
    Routes.profile: (context) => const ProfilePage(),
  },
  onGenerateRoute: (settings) {
    if (settings.name?.startsWith(Routes.product) ?? false) {
      final id = settings.name!.split('/').last;
      return MaterialPageRoute(
        builder: (context) => ProductPage(id: id),
        settings: settings,
      );
    }
    return null;
  },
);

// Navigation
Navigator.pushNamed(context, Routes.profile);
Navigator.pushNamed(context, '${Routes.product}/123');
Navigator.pop(context);
```

### ZenRouter Imperative (Similar Feel)

```dart
// Define routes as classes
abstract class AppRoute extends RouteTarget {
  Widget build(BuildContext context);
}

class HomeRoute extends AppRoute {
  @override
  Widget build(BuildContext context) => const HomePage();
}

class ProfileRoute extends AppRoute {
  @override
  Widget build(BuildContext context) => const ProfilePage();
}

class ProductRoute extends AppRoute {
  final String id;
  ProductRoute(this.id);
  
  @override
  List<Object?> get props => [id];
  
  @override
  Widget build(BuildContext context) => ProductPage(id: id);
}

// Create a navigation path
final appPath = NavigationPath<AppRoute>.create();

// MaterialApp
MaterialApp(
  home: NavigationStack(
    path: appPath,
    defaultRoute: HomeRoute(),
    resolver: (route) => StackTransition.material(
      route.build(context),
    ),
  ),
);

// Navigation (type-safe!)
appPath.push(ProfileRoute());
appPath.push(ProductRoute('123'));
appPath.pop();
```

**Advantages:**
- **Type safety** - `ProductRoute('123')` instead of string concatenation
- **Parameter safety** - Constructor arguments instead of parsing strings
- **No route name constants** - Routes are classes
- **IDE support** - Autocomplete, refactoring, find usages

---

## From Navigator 2.0

Navigator 2.0 requires implementing `RouterDelegate`, `RouteInformationParser`, and managing page stacks manually. ZenRouter's Coordinator pattern provides the same capabilities with much less code.

### Navigator 2.0 Example

```dart
class AppRouterDelegate extends RouterDelegate<RoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  final List<Page> _pages = [];
  
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: List.unmodifiable(_pages),
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        _pages.removeLast();
        notifyListeners();
        return true;
      },
    );
  }
  
  @override
  Future<void> setNewRoutePath(RoutePath path) async {
    // Update _pages based on path
    // ... complex logic ...
    notifyListeners();
  }
}

class AppRouteInformationParser extends RouteInformationParser<RoutePath> {
  @override
  Future<RoutePath> parseRouteInformation(RouteInformation info) async {
    final uri = Uri.parse(info.uri.toString());
    // Parse URI to RoutePath
    // ... manual parsing logic ...
    return RoutePath(/* ... */);
  }
  
  @override
  RouteInformation? restoreRouteInformation(RoutePath path) {
    // Convert RoutePath back to URI
    // ... manual conversion ...
    return RouteInformation(uri: Uri.parse(/* ... */));
  }
}

// In MaterialApp
final routerDelegate = AppRouterDelegate();
final routeInformationParser = AppRouteInformationParser();

MaterialApp.router(
  routerDelegate: routerDelegate,
  routeInformationParser: routeInformationParser,
);
```

### ZenRouter Coordinator (Much Simpler)

```dart
// Define routes
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

// Coordinator (replaces RouterDelegate + RouteInformationParser)
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['products', String id] => ProductRoute(id),
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
```

**Advantages:**
- **10x less boilerplate** - No manual page stack management
- **Automatic URL generation** - Each route knows its URI via `toUri()`
- **Built-in state restoration** - Works automatically
- **Type-safe parsing** - Pattern matching instead of string manipulation

---

## Named Routes Migration

### Navigator 1.0 Named Routes

```dart
// Define routes
class Routes {
  static const home = '/';
  static const settings = '/settings';
  static const about = '/about';
}

// In MaterialApp
routes: {
  Routes.home: (context) => const HomePage(),
  Routes.settings: (context) => const SettingsPage(),
  Routes.about: (context) => const AboutPage(),
}

// Navigate
Navigator.pushNamed(context, Routes.settings);
Navigator.pushNamed(context, Routes.about);
```

### ZenRouter Equivalent

```dart
// Define route classes
class HomeRoute extends AppRoute {
  @override
  Widget build(BuildContext context) => const HomePage();
}

class SettingsRoute extends AppRoute {
  @override
  Widget build(BuildContext context) => const SettingsPage();
}

class AboutRoute extends AppRoute {
  @override
  Widget build(BuildContext context) => const AboutPage();
}

// Navigate (type-safe)
appPath.push(SettingsRoute());
appPath.push(AboutRoute());
```

No route name constants needed - the route class IS the identifier.

---

## Route Arguments

### Navigator 1.0 Arguments

```dart
// Pass arguments
Navigator.pushNamed(
  context,
  '/product',
  arguments: {'id': '123', 'name': 'Widget'},
);

// Receive arguments
class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = args['id'] as String;
    final name = args['name'] as String;
    
    return Text('Product: $id - $name');
  }
}
```

### ZenRouter Type-Safe Arguments

```dart
// Route with parameters
class ProductRoute extends AppRoute {
  final String id;
  final String name;
  
  ProductRoute({required this.id, required this.name});
  
  @override
  List<Object?> get props => [id, name];
  
  @override
  Widget build(BuildContext context) {
    return ProductPage(id: id, name: name);
  }
}

// Navigate (compile-time type checking!)
appPath.push(ProductRoute(id: '123', name: 'Widget'));

// Receive arguments
class ProductPage extends StatelessWidget {
  final String id;
  final String name;
  
  const ProductPage({required this.id, required this.name});
  
  @override
  Widget build(BuildContext context) {
    return Text('Product: $id - $name');
  }
}
```

**No runtime casting, no null checks, no errors!**

---

## Custom Transitions

### Navigator 1.0 PageRoute

```dart
class FadePageRoute extends PageRouteBuilder {
  final Widget page;
  
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

// Navigate
Navigator.push(context, FadePageRoute(page: const ProfilePage()));
```

### ZenRouter StackTransition

```dart
class FadePage<T> extends Page<T> {
  const FadePage({super.key, required this.child});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

// In resolver
resolver: (route) {
  if (route is ProfileRoute) {
    return StackTransition.custom<ProfileRoute>(
      builder: (context) => const ProfilePage(),
      pageBuilder: (context, routeKey, child) => FadePage(
        key: routeKey,
        child: child,
      ),
    );
  }
  return StackTransition.material(route.build(context));
}
```

See [Route Transitions Recipe](../recipes/route-transitions.md) for more patterns.

---

## WillPopScope / PopScope Migration

### Navigator 1.0/2.0 WillPopScope

```dart
class EditPage extends StatefulWidget {
  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  bool _hasUnsavedChanges = false;
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_hasUnsavedChanges) return true;
        
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(/* ... */),
    );
  }
}
```

### ZenRouter RouteGuard

```dart
class EditRoute extends AppRoute with RouteGuard {
  final bool hasUnsavedChanges;
  
  EditRoute({this.hasUnsavedChanges = false});
  
  @override
  List<Object?> get props => [hasUnsavedChanges];
  
  @override
  Future<bool> canPop() async {
    if (!hasUnsavedChanges) return true;
    
    final result = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return EditPage(onChanged: () {
      // Update route with new state
      coordinator.replace(EditRoute(hasUnsavedChanges: true));
    });
  }
}
```

---

## Deep Linking

### Navigator 2.0 Deep Linking

Requires significant boilerplate with `RouteInformationParser` and `RouterDelegate`.

### ZenRouter Deep Linking

**Automatic** with Coordinator pattern! Just define `toUri()` and `parseRouteFromUri()`:

```dart
class ProductRoute extends AppRoute {
  final String id;
  ProductRoute(this.id);
  
  @override
  Uri toUri() => Uri.parse('/products/$id');
}

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['products', String id] => ProductRoute(id),
      _ => NotFoundRoute(),
    };
  }
}
```

Now links like `myapp://products/123` automatically work!

---

## Common Gotchas

> [!CAUTION]
> **Context.pushNamed is gone**
> Navigator 1.0's `context.pushNamed()` becomes `path.push(Route())` or `coordinator.push(Route())`.

> [!TIP]
> **Choose your paradigm**
> If you loved Navigator 1.0's simplicity, use ZenRouter **Imperative**. If you need Navigator 2.0's power, use **Coordinator**.

> [!NOTE]
> **Arguments are constructor parameters**
> No more `ModalRoute.of(context)!.settings.arguments`. Pass data through route constructors.

> [!WARNING]
> **onGenerateRoute is parseRouteFromUri**
> The pattern matching in `parseRouteFromUri` replaces `onGenerateRoute` logic.

---

## Migration Checklist

### From Navigator 1.0

- [ ] Convert route name constants to `RouteTarget` classes
- [ ] Create a `NavigationPath` or `Coordinator`
- [ ] Replace `MaterialApp.routes` with `NavigationStack` or `MaterialApp.router`
- [ ] Update all `Navigator.pushNamed()` to `path.push(Route())`
- [ ] Convert route arguments to constructor parameters
- [ ] Replace `onGenerateRoute` with `parseRouteFromUri` (if using Coordinator)
- [ ] Migrate `WillPopScope` to `RouteGuard` mixin

### From Navigator 2.0

- [ ] Delete custom `RouterDelegate` and `RouteInformationParser`
- [ ] Convert page classes to `RouteTarget` classes
- [ ] Create `Coordinator` with `parseRouteFromUri`
- [ ] Implement `toUri()` on each route
- [ ] Update `MaterialApp.router` to use `coordinator.routerDelegate` and `routeInformationParser`
- [ ] Test deep linking and state restoration

---

## What You Gain

### Type Safety

```dart
// Navigator 1.0 - runtime error
Navigator.pushNamed(context, '/prodcut/123'); // Typo!

// ZenRouter - compile error
coordinator.push(Prodcut Route('123')); // Won't compile!
```

### Less Boilerplate

Navigator 2.0 requires ~200 lines for basic routing. ZenRouter Coordinator: ~50 lines.

### Better IDE Support

- Autocomplete for routes
- Find all usages
- Rename refactoring
- Type hints

---

## Need Help?

- [ZenRouter Getting Started](../guides/getting-started.md)
- [Imperative Paradigm Guide](../paradigms/imperative.md)
- [Coordinator Pattern Guide](../paradigms/coordinator.md)
- [Route Transitions Recipe](../recipes/route-transitions.md)
- [GitHub Issues](https://github.com/definev/zenrouter/issues)

---

**Happy migrating! 🧘**
