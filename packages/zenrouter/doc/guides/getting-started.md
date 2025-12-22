# Getting Started with ZenRouter

Welcome to ZenRouter! This guide will help you choose the right paradigm and get started quickly.

## Installation

Add zenrouter to your `pubspec.yaml`:

```yaml
dependencies:
  zenrouter: ^0.1.0  # Check pub.dev for latest version
```

Then run:

```bash
flutter pub get
```

## Choose Your Paradigm

ZenRouter offers three paradigms. Choose based on your needs:

```
┌─────────────────────────────────────────────────────────────┐
│                     DECISION FLOWCHART                      │
└─────────────────────────────────────────────────────────────┘

Do you need web support or deep linking?
│
├─ YES → Use COORDINATOR
│        ✓ Deep linking
│        ✓ URL synchronization  
│        ✓ Browser back button
│        ✓ Centralized routing
│        → See: Coordinator Quick Start
│
└─ NO → Is your navigation driven by state?
       │
       ├─ YES → Use DECLARATIVE
       │        ✓ State-driven routing
       │        ✓ React-like declarative UI
       │        ✓ Efficient updates with Myers diff
       │        → See: Declarative Quick Start
       │
       └─ NO → Use IMPERATIVE
                ✓ Simple and straightforward
                ✓ Direct control over stack
                ✓ Event-driven navigation
                → See: Imperative Quick Start
```

## Comparison Table

| Feature | Imperative | Declarative | Coordinator |
|---------|-----------|-------------|-------------|
| **Complexity** | ⭐ Simple | ⭐⭐ Moderate | ⭐⭐⭐ Advanced |
| **Control** | Full | State-driven | Centralized |
| **Deep Linking** | ❌ No | ❌ No | ✅ Yes |
| **Web Support** | ❌ No | ❌ No | ✅ Yes |
| **URL Sync** | ❌ No | ❌ No | ✅ Yes |
| **State-Driven** | Compatible | ✅ Native | Compatible |
| **Best For** | Mobile apps | Tab bars, lists | Web, large apps |
| **Learning Curve** | Easy | Easy | Moderate |

---

## Imperative Quick Start

**Best for:** Mobile-only apps, event-driven navigation, Navigator 1.0 migration

### 1. Define Routes

```dart
import 'package:zenrouter/zenrouter.dart';

// Base class
sealed class AppRoute extends RouteTarget {
  Widget build(BuildContext context);
}

class HomeRoute extends AppRoute {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => path.push(ProfileRoute()),
          child: const Text('Go to Profile'),
        ),
      ),
    );
  }
}

class ProfileRoute extends AppRoute {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}
```

### 2. Create Navigation Path

```dart
final path = NavigationPath<AppRoute>.create();
```

### 3. Render with NavigationStack

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
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

### 4. Navigate!

```dart
// Push a route
path.push(ProfileRoute());

// Pop back
path.pop();

// Replace entire stack
path.replace([HomeRoute()]);
```

**Next steps:** [Imperative Navigation Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md)

---

## Declarative Quick Start

**Best for:** State-driven navigation, tab bars, filtered lists, React-like UI

### 1. Define Routes with Equality

```dart
import 'package:zenrouter/zenrouter.dart';

class PageRoute extends RouteTarget {
  final int pageNumber;
  
  PageRoute(this.pageNumber);
  
  // IMPORTANT: Implement equality for Myers diff!
  @override
  List<Object?> get props => [pageNumber];
}
```

### 2. Create Stateful Widget

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<int> _pages = [1]; // State
  
  void _addPage() {
    setState(() {
      _pages.add(_pages.length + 1);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NavigationStack.declarative(
          // Derive routes from state
          routes: [
            for (final page in _pages) PageRoute(page),
          ],
          resolver: (route) => StackTransition.material(
            PageScreen(pageNumber: (route as PageRoute).pageNumber),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addPage,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class PageScreen extends StatelessWidget {
  final int pageNumber;
  
  const PageScreen({super.key, required this.pageNumber});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page $pageNumber')),
      body: Center(child: Text('Page $pageNumber')),
    );
  }
}
```

**Next steps:** [Declarative Navigation Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md)

---

## Coordinator Quick Start

**Best for:** Web apps, deep linking, complex nested navigation, large apps

### 1. Define Routes with RouteUnique

```dart
import 'package:zenrouter/zenrouter.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

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
```

### 2. Create Coordinator

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

final coordinator = AppCoordinator();
```

### 3. Use MaterialApp.router

```dart
void main() {
  runApp(const MyApp());
}

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

### 4. Navigate!

```dart
// Push a route
coordinator.push(ProfileRoute());

// Pop back
coordinator.pop();

// Replace stack
coordinator.replace(HomeRoute());
```

Now you have:
- ✅ Deep linking: Open `myapp://profile` to go directly to profile
- ✅ Web URLs: Navigate to `/profile` in browser
- ✅ Browser back button support

**Next steps:** [Coordinator Pattern Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md)

---

## Mixing Paradigms

You can combine paradigms in the same app:

```dart
// Use coordinator for main navigation (deep linking)
class AppCoordinator extends Coordinator<AppRoute> { ... }

// Use declarative for a tab bar (state-driven)
NavigationStack.declarative(
  routes: [
    for (final tab in tabs) TabRoute(tab),
  ],
  resolver: resolver,
)

// Use imperative for a modal flow (event-driven)
final modalPath = NavigationPath<ModalRoute>.create();
modalPath.push(Step1Route());
```

## Common Recipes

### Recipe: Tab Bar Navigation

**Use:** Declarative or Coordinator with `IndexedStackPath`

```dart
// Declarative approach
int selectedTab = 0;

NavigationStack.declarative(
  routes: [
    HomeRoute(),
    switch (selectedTab) {
      0 => FeedRoute(),
      1 => ProfileRoute(),
      2 => SettingsRoute(),
      _ => FeedRoute(),
    },
  ],
  resolver: resolver,
)
```

### Recipe: Multi-Step Form

**Use:** Imperative with state passing

```dart
// Step 1
path.push(PersonalInfoStep(data: FormData()));

// Step 2 (in PersonalInfoStep)
path.push(PreferencesStep(data: updatedData));

// Step 3 (in PreferencesStep)
path.push(ReviewStep(data: updatedData));
```

### Recipe: Authentication Flow

**Use:** Coordinator with `RouteRedirect`

```dart
class ProtectedRoute extends AppRoute with RouteRedirect {
  @override
  Future<AppRoute> redirect() async {
    final isAuthed = await auth.check();
    return isAuthed ? this : LoginRoute();
  }
}
```

### Recipe: Deep Linking

**Use:** Coordinator with `RouteDeepLink`

```dart
class ProductRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri) async {
    // Set up navigation stack
    coordinator.replace(ShopTab());
    coordinator.push(this);
    
    // Track analytics
    analytics.logDeepLink(uri);
  }
}
```

## Next Steps

1. **Read the paradigm guide** for your chosen approach
2. **Explore the examples** in the `example/` directory
3. **Check the API reference** for detailed documentation
4. **Join the community** for support and discussions

## Documentation

- **Paradigm Guides**
  - [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md)
  - [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md)
  - [Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md)

- **API Reference**
  - [Core Classes](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/core-classes.md)
  - [Navigation Paths](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md)
  - [Route Mixins](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md)
  - [Coordinator API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md)

- **Examples**
  - [Imperative Example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_imperative.dart)
  - [Declarative Example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_declrative.dart)
  - [Coordinator Example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_coordinator.dart)

## Need Help?

- **Issues**: [GitHub Issues](https://github.com/definev/zenrouter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/definev/zenrouter/discussions)
- **Examples**: Check the `example/` directory

Happy routing! 🧘
