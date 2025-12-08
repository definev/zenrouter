# ZenRouter 🧘

**The Ultimate Flutter Router for Every Navigation Pattern**

[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)

ZenRouter is the only router you'll ever need - supporting three distinct paradigms to handle any routing scenario. From simple mobile apps to complex web applications with deep linking, ZenRouter adapts to your needs.

---

## Why ZenRouter?

**One router. Three paradigms. Infinite possibilities.**

✨ **Three Paradigms in One** - Choose imperative, declarative, or coordinator based on your needs  
🚀 **Start Simple, Scale Seamlessly** - Begin with basics, add complexity as you grow  
🌐 **Full Web & Deep Linking** - Built-in URL handling and browser navigation  
⚡ **Blazing Fast** - Efficient Myers diff algorithm for optimal performance  
🔒 **Type-Safe** - Catch routing errors at compile-time, not runtime  
🛡️ **Powerful Guards & Redirects** - Protect routes and control navigation flow  
📦 **Zero Boilerplate** - Clean, mixin-based architecture  
📝 **No Codegen Needed (for core)** - Pure Dart, no build_runner or generated files required. *(Optional file-based routing via `zenrouter_file_generator` is available when you want codegen.)*  

---

## Three Paradigms, Infinite Flexibility


### Choose Your Path

```
Need web support, deep linking, and router devtools to handle complex scalable navigation?
│
├─ YES → Use Coordinator
│        ✓ Deep linking & URL sync
│        ✓ Devtools ready!
│        ✓ Back button gesture (Web back, predictive back, etc)
│        ✓ Perfect for web, complex mobile apps
│
└─ NO → Is navigation driven by state?
       │
       ├─ YES → Use Declarative
       │        ✓ Efficient Myers diff
       │        ✓ React-like patterns
       │        ✓ Perfect for tab bars
       │
       └─ NO → Use Imperative
                ✓ Simple & direct
                ✓ Full control
                ✓ Perfect for mobile
```

### 🎮 **Imperative** - Direct Control

*Perfect for mobile apps and event-driven navigation*

#### Quick Start

First, define a navigation path and all possible routes. For example, let's say you have `Home` and `Profile` routes:

```dart
class Home extends RouteTarget {}

class Profile extends RouteTarget {
  Profile(this.id);
  final String id;

  /// Make sure to add `id` in `props` to prevent unwanted behavior when pushing the same route
  List<Object?> get props => [id];
}

final appPath = NavigationPath();
```

Now that the setup is complete, let's wire up the navigation. The `NavigationStack` widget expects two main parameters:
- `path`: The route stack to display
- `resolver`: A function for resolving which transition type each route will use

```dart
class AppRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationStack(
      path: appPath,
      resolver: (route) => switch (route) {
        Home() => StackTransition.material(HomePage()),
        Profile() => StackTransition.material(ProfilePage()),
      },
    );
  }
}
```

That's it! You've successfully set up imperative routing for your app. To navigate, simply call `push()` to open a new route (you can `await` the result when it's popped), and `pop()` to go back. The `NavigationPath` class offers many handy operations—see more in the [NavigationPath API documentation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#navigationpath).

```dart
// Open Profile route
ElevatedButton(
  onPressed: () => appPath.push(Profile('Joe')),
  child: Text('Open "Joe" profile'),
),

// Pop back
appPath.pop();
```

**When to use:**
- Mobile-only applications
- Button clicks and gesture-driven navigation
- Migrating from Navigator 1.0
- You want simple, direct control

[→ Learn Imperative Routing](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md)

---

### 📊 **Declarative** - State-Driven
*Perfect for tab bars, filtered lists, and React-like UIs*

#### Quick Start

In declarative navigation, your UI is a function of your state. When your state changes, the navigation stack automatically updates to reflect it. ZenRouter uses the **Myers diff algorithm** to efficiently compute the minimal changes needed, ensuring optimal performance even with complex navigation stacks.

Let's build a simple tab navigation example. First, define your routes and state:

```dart
class HomeTab extends RouteTarget {}
class SearchTab extends RouteTarget {}
class ProfileTab extends RouteTarget {}

class TabNavigator extends StatefulWidget {
  @override
  State<TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  int currentTab = 0;
  
  @override
  Widget build(BuildContext context) {
    return NavigationStack.declarative(
      routes: [
        HomeTab(),
        switch (currentTab) {
          0 => SearchTab(),
          1 => ProfileTab(),
          _ => SearchTab(),
        },
      ],
      resolver: (route) => switch (route) {
        HomeTab() => StackTransition.material(HomePage()),
        SearchTab() => StackTransition.material(SearchPage()),
        ProfileTab() => StackTransition.material(ProfilePage()),
      },
    );
  }
}
```

When you update the state, the navigation stack automatically reflects the changes. ZenRouter intelligently diffs the old and new route lists to determine the minimal set of push/pop operations needed:

```dart
// Switch tabs
setState(() => currentTab = 1); // Automatically pushes ProfileTab
```

That's it! The navigation stack stays perfectly in sync with your state—no manual `push()` or `pop()` calls needed. This pattern is ideal for tab bars, filtered lists, or any UI where navigation is derived from application state.

**When to use:**
- Tab navigation
- Filtered or dynamic lists
- State-driven UIs
- React-like declarative patterns

[→ Learn Declarative Routing](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md)

---

### 🗺️ **Coordinator** - Deep Linking & Web
*Perfect for web apps and complex navigation hierarchies*

#### Quick Start

Ready to level up? When your app needs to support deep linking, web URLs, or browser navigation, it's time to graduate to the **Coordinator** pattern. This is the final and most powerful routing paradigm in ZenRouter—built for production apps that need to handle complex navigation scenarios across multiple platforms.

The Coordinator pattern gives you:
- 🔗 **Deep linking** - Open specific screens from external sources (`myapp://profile/123`)
- 🌐 **URL synchronization** - Keep browser URLs in sync with navigation state
- ⬅️ **Browser back button** - Native web navigation that just works
- 🛠️ **Dev tools** - Built-in debugging and route inspection

Let's build a Coordinator-powered app. First, define your routes with URI support:

First, create a base route class for your app. The `RouteUnique` mixin is **required** for Coordinator—it enforces that every route must define a unique URI, which is essential for deep linking and URL synchronization:

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {}
```

Now define your concrete routes by extending `AppRoute`:

```dart
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return HomePage(coordinator: coordinator);
  }
}

class ProfileRoute extends AppRoute {
  ProfileRoute(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
  
  @override
  Uri toUri() => Uri.parse('/profile/$userId');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ProfilePage(userId: userId, coordinator: coordinator);
  }
}
```

> [!IMPORTANT]
> Notice that the `build()` method uses `AppCoordinator` (not `Coordinator`) as the parameter type. This is because `Coordinator` is **covariant**—when you create your `AppCoordinator extends Coordinator<AppRoute>`, all your routes will receive that specific coordinator type, giving you type-safe access to any custom methods or properties you add to `AppCoordinator`.

Next, create your Coordinator by extending the `Coordinator` class and implementing URI parsing:

```dart
class AppCoordinator extends Coordinator<RouteTarget> {
  @override
  RouteTarget parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile', String userId] => ProfileRoute(userId),
      _ => NotFoundRoute(),
    };
  }
}
```

Finally, wire it up with `MaterialApp.router` to enable full platform navigation:

```dart
class MyApp extends StatelessWidget {
  final coordinator = AppCoordinator();
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}
```

That's it! Your app now supports:
- ✅ Deep links: `myapp://profile/joe` automatically navigates to Joe's profile
- ✅ Web URLs: Users can bookmark and share `https://myapp.com/profile/joe`
- ✅ Browser navigation: Back/forward buttons work seamlessly
- ✅ Dev tools: Debug routes and navigation flows in real-time

The Coordinator handles all the complexity of URI parsing, route restoration, and platform integration—you just focus on building your app.

**When to use:**
- Web applications
- Deep linking requirements
- Complex nested navigation
- URL synchronization needed

[→ Learn Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator/coordinator.md)

---

## Quick Comparison

|  | **Imperative** | **Declarative** | **Coordinator** |
|---|:---:|:---:|:---:|
| **Simplicity** | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| **Web Support** | ❌ | ❌ | ✅ |
| **Deep Linking** | ❌ | ❌ | ✅ |
| **State-Driven** | Compatible | ✅ Native | Compatible |
| **Best For** | Mobile apps | Tab bars, lists | Web, large apps |
| **Route Ability** | `Guard`, `Redirect`, `Transition` | `Guard`, `Redirect`, `Transition` | `Guard`, `Redirect`, `Transition`, **`DeepLink`** |

---


## Documentation

### **📚 Guides**
- [Getting Started](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/getting-started.md) - Choose your paradigm and get started
- [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Direct stack control
- [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) - State-driven routing
- [Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md) - Deep linking & web support

### **🔧 API Reference**
- [Route Mixins](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - Guards, redirects, transitions, and more
- [Navigation Paths](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md) - Stack containers and navigation
- [Coordinator API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md) - Full coordinator reference
- [Core Classes](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/core-classes.md) - RouteTarget and fundamentals

### **💡 Examples**
- [Imperative Example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_imperative.dart) - Multi-step form
- [Declarative Example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_declrative.dart) - State-driven navigation
- [Coordinator Example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_coordinator.dart) - Deep linking & nested navigation
- [File-based Routing Example (Coordinator + generator)](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/file_based_routing/README.md) - Next.js-style file-based routing using `zenrouter_file_generator`

To get Next.js / Nuxt.js–style file-based routing on top of the Coordinator paradigm, use the optional [`zenrouter_file_generator`](../zenrouter_file_generator/README.md) package, which provides annotations and a `build_runner`-based code generator.

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/CONTRIBUTING.md) for guidelines.

## License

Apache 2.0 License - see [LICENSE](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/LICENSE) for details.

## Created With Love By

[definev](https://github.com/definev)

---

<div align="center">

**The Ultimate Router for Flutter**

[Documentation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/getting-started.md) • [Examples](https://github.com/definev/zenrouter/tree/main/packages/zenrouter/example) • [Issues](https://github.com/definev/zenrouter/issues)

**Happy Routing! 🧘**

</div>
