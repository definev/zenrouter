<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

**The Ultimate Flutter Router for Every Navigation Pattern**

[![pub package](https://img.shields.io/pub/v/zenrouter.svg)](https://pub.dev/packages/zenrouter)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)

</div>

---

## Installation

```bash
flutter pub add zenrouter
```

---

## Architecture Overview

ZenRouter provides three navigation paradigms through a layered architecture:

```
RouteTarget (base class for all routes)
  ├── Imperative    → NavigationPath + NavigationStack
  ├── Declarative   → NavigationStack.declarative (Myers diff)
  └── Coordinator   → Coordinator<T> + MaterialApp.router
        └── RouteUnique (URI-based identity for deep linking)
```

### Class Architecture

| Component | Responsibility |
|-----------|----------------|
| `RouteTarget` | Base class for all routes; provides identity via `props` and lifecycle |
| `NavigationPath` | Mutable stack container supporting `push`, `pop`, `replace`, and `reset` |
| `NavigationStack` | Flutter widget that renders a `NavigationPath` as a `Navigator` |
| `Coordinator<T>` | Central navigation hub orchestrating URI parsing, deep linking, layout resolution, and platform integration |

### Route Mixins

| Mixin | Responsibility |
|-------|----------------|
| `RouteUnique` | Provides URI-based identity; **required** for Coordinator routes |
| `RouteGuard` | Prevents popping via `popGuard()` / `popGuardWith(coordinator)` |
| `RouteRedirect` | Resolves redirects before the route is pushed |
| `RouteDeepLink` | Customises how a route is restored from a deep link URI |
| `RouteLayout` | Declares nested layout hierarchy; resolves child `StackPath` |
| `RouteTransition` | Overrides the default page transition for a specific route |
| `RouteRestorable` | Enables state restoration after process death |

---

## Paradigm Selection

```
Need deep linking, URL sync, or browser back button?
│
├─ YES → Coordinator
│
└─ NO → Is navigation derived from state?
       │
       ├─ YES → Declarative
       │
       └─ NO → Imperative
```

|  | **Imperative** | **Declarative** | **Coordinator** |
|---|:---:|:---:|:---:|
| Simplicity | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| Web / Deep Linking | ❌ | ❌ | ✅ |
| State-Driven | Compatible | ✅ Native | Compatible |
| Route Mixins | Guard, Redirect, Transition | Guard, Redirect, Transition | Guard, Redirect, Transition, **DeepLink** |

---

## Imperative

Direct stack control via `NavigationPath`. Routes are pushed and popped explicitly.

### Role in Navigation Flow

1. Create route classes extending `RouteTarget`
2. Create a `NavigationPath` to hold the route stack
3. Render the stack with `NavigationStack`, providing a `resolver` that maps each route to a `StackTransition`
4. Call `push()` / `pop()` on the path to navigate

### Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// 1. Define routes
sealed class OnboardingRoute extends RouteTarget {
  Widget build(BuildContext context);
}

class WelcomeStep extends OnboardingRoute {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => onboardingPath.push(
            PersonalInfoStep(formData: const OnboardingFormData()),
          ),
          child: const Text('Start Onboarding'),
        ),
      ),
    );
  }
}

class PersonalInfoStep extends OnboardingRoute with RouteGuard {
  final OnboardingFormData formData;
  PersonalInfoStep({required this.formData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => onboardingPath.push(
            PreferencesStep(formData: formData.copyWith(fullName: 'Joe')),
          ),
          child: const Text('Continue'),
        ),
      ),
    );
  }

  @override
  Future<bool> popGuard() async => true; // prevent accidental back
}

// 2. Create a NavigationPath
final onboardingPath = NavigationPath.create();

// 3. Wire up with NavigationStack
class AppRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationStack(
      path: onboardingPath,
      resolver: (route) => switch (route) {
        WelcomeStep() => StackTransition.material(route.build(context)),
        PersonalInfoStep() => StackTransition.material(route.build(context)),
        PreferencesStep() => StackTransition.material(route.build(context)),
      },
    );
  }
}
```

Navigate with:

```dart
onboardingPath.push(PersonalInfoStep(formData: data));
onboardingPath.pop();
onboardingPath.reset();
```

→ [Full imperative example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_imperative.dart)

---

## Declarative

State-driven navigation. The route list is rebuilt from state and ZenRouter applies the **Myers diff algorithm** to compute minimal push/pop operations.

### Role in Navigation Flow

1. Define routes extending `RouteTarget`
2. Use `NavigationStack.declarative` with a `routes` list derived from state
3. When state changes, rebuild the `routes` list — ZenRouter diffs and applies the minimal set of changes

### Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

class PageRoute extends RouteTarget {
  final int pageNumber;
  PageRoute(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class SpecialRoute extends RouteTarget {}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final List<int> _pageNumbers = [1];
  int _nextPageNumber = 2;
  bool showSpecial = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: NavigationStack.declarative(
              routes: <RouteTarget>[
                for (final pageNumber in _pageNumbers) PageRoute(pageNumber),
                if (showSpecial) SpecialRoute(),
              ],
              resolver: (route) => switch (route) {
                SpecialRoute() => StackTransition.sheet(SpecialPage()),
                PageRoute(:final pageNumber) =>
                  StackTransition.material(PageView(pageNumber: pageNumber)),
                _ => throw UnimplementedError(),
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() {
              _pageNumbers.add(_nextPageNumber++);
            }),
            child: const Text('Add Page'),
          ),
        ],
      ),
    );
  }
}
```

→ [Full declarative example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_declrative.dart)

---

## Coordinator

Central navigation hub for deep linking, URL synchronisation, browser navigation, state restoration, and nested layouts.

### Inheritance Architecture

```
Coordinator<T extends RouteUnique>
  extends CoordinatorCore<T>             // Push, pop, replace, navigate
  with CoordinatorLayout<T>              // Layout hierarchy resolution
     , CoordinatorRestoration<T>         // State restoration after process death
  implements RouterConfig<RouteTarget>   // Platform Router integration
```

### Role in Navigation Flow

1. Define route classes extending `RouteTarget with RouteUnique`
2. Create a `Coordinator<T>` subclass implementing `parseRouteFromUri`
3. Declare `NavigationPath` and `IndexedStackPath` instances for nested stacks
4. Wire up with `MaterialApp.router` using `routerDelegate` and `routeInformationParser`
5. Navigate with `coordinator.push()`, `coordinator.pop()`, `coordinator.replace()`

### Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// 1. Base route with RouteUnique (required for URI identity)
abstract class AppRoute extends RouteTarget with RouteUnique {}

// 2. Define routes
class FeedTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/home/tabs/feed');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Post 1'),
          onTap: () => coordinator.push(FeedDetail(id: '1')),
        ),
      ],
    );
  }
}

class FeedDetail extends AppRoute with RouteGuard, RouteRedirect {
  FeedDetail({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/home/feed/$id');

  @override
  AppRoute redirect() {
    if (id == 'profile') return ProfileDetail();
    return this;
  }

  @override
  FutureOr<bool> popGuardWith(AppCoordinator coordinator) async {
    final confirm = await showDialog<bool>(
      context: coordinator.navigator.context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed Detail $id')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => coordinator.pop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}

// 3. Layout routes for nested navigation
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: buildPath(coordinator), // renders nested NavigationPath
    );
  }
}

class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type get layout => HomeLayout;

  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabIndexed;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: buildPath(coordinator)),
          // tab bar UI ...
        ],
      ),
    );
  }
}

// 4. Coordinator — the central hub
class AppCoordinator extends Coordinator<AppRoute> {
  late final homeStack = NavigationPath.createWith(
    label: 'home', coordinator: this,
  )..bindLayout(HomeLayout.new);

  late final tabIndexed = IndexedStackPath.createWith(
    coordinator: this, label: 'home-tabs',
    [FeedTab(), ProfileTab(), SettingsTab()],
  )..bindLayout(TabBarLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, homeStack, tabIndexed];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => FeedTab(),
      ['home', 'tabs', 'feed'] => FeedTab(),
      ['home', 'feed', final id] => FeedDetail(id: id),
      _ => NotFound(uri: uri),
    };
  }
}

// 5. Wire up with MaterialApp.router
class MyApp extends StatelessWidget {
  static final coordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'app', // enables state restoration
      routerConfig: coordinator,
    );
  }
}
```

> [!IMPORTANT]
> The `build()` method on `RouteUnique` routes receives the **concrete coordinator type** (e.g. `AppCoordinator`), not the generic `Coordinator`. This is because `Coordinator` is covariant — giving you type-safe access to custom paths and methods.

> [!IMPORTANT]
> State restoration requires routes to be parsed **synchronously** during startup. If `parseRouteFromUri` is asynchronous, override `parseRouteFromUriSync` to provide a synchronous fallback.

→ [Full coordinator example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_coordinator.dart) · [Modular coordinator example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_coordinator_module.dart) · [State restoration example](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/example/lib/main_restoration.dart)

---

## Relationship with Related Packages

| Package | Relationship |
|---------|-------------|
| [`zenrouter_core`](https://pub.dev/packages/zenrouter_core) | Platform-independent core: `RouteTarget`, `CoordinatorCore`, `StackPath`, and all route mixins |
| [`zenrouter`](https://pub.dev/packages/zenrouter) | Flutter integration: `Coordinator`, `NavigationStack`, `StackTransition`, state restoration |
| [`zenrouter_devtools`](https://pub.dev/packages/zenrouter_devtools) | DevTools extension for inspecting routes, testing deep links, and debugging navigation |
| [`zenrouter_file_generator`](https://pub.dev/packages/zenrouter_file_generator) | Optional `build_runner` code generator for Next.js-style file-based routing on top of Coordinator |

---

## Documentation

### Guides
- [Getting Started](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/getting-started.md)
- [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md)
- [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md)
- [Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator/coordinator.md)

### API Reference
- [Route Mixins](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md)
- [Navigation Paths](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md)
- [Coordinator API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md)
- [Core Classes](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/core-classes.md)

### Recipes
- [404 Handling](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/404-handling.md)
- [Authentication Flow](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/authentication-flow.md)
- [Bottom Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/bottom-navigation.md)
- [Route Transitions](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/route-transitions.md)
- [State Management Integration](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/state-management.md)
- [URL Strategies](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/url-strategies.md)
- [Coordinator as Route Module](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/recipes/coordinator-as-routemodule.md)

### Migration Guides
- [From go_router](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/migration/from-go-router.md)
- [From auto_route](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/migration/from-auto-route.md)
- [From Navigator 1.0/2.0](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/migration/from-navigator.md)

---

## Contributing

See [CONTRIBUTING.md](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/CONTRIBUTING.md) for guidelines.

## License

Apache 2.0 — see [LICENSE](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/LICENSE).

## Created With Love By

[definev](https://github.com/definev)

---

<div align="center">

**The Ultimate Router for Flutter**

[Documentation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/getting-started.md) • [Examples](https://github.com/definev/zenrouter/tree/main/packages/zenrouter/example) • [Issues](https://github.com/definev/zenrouter/issues)

**Happy Routing! 🧘**

</div>
