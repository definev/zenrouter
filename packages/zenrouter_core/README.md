# zenrouter_core

Platform-independent routing framework for building custom navigation systems.

## What is zenrouter_core?

zenrouter_core provides the **core abstractions** for implementing arbitrary routing structures. It defines the relationship between routes, navigation stacks, and their rendering—but leaves the actual rendering implementation to you.

```
┌──────────────────────────────────────────────────────────────────┐
│                        Your Implementation                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐   │
│   │ RouteTarget  │───▶│  StackPath   │───▶│ Component Render │   │
│   └──────────────┘    └──────────────┘    └──────────────────┘   │
│         │                    │                     ▲             │
│         │                    │                     │             │
│         │    manages         │    notifies         │             │
│         └────────────────────┴─────────────────────┘             │
│                                                                  │
│   RouteTarget: WHAT to navigate (destination, data, identity)    │
│   StackPath:   HOW to navigate (push, pop, stack operations)     │
│   Component:   HOW to display (platform-specific rendering)      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**You implement**: Routes, StackPath subclasses, and Component Render  
**zenrouter_core provides**: RouteTarget, CoordinatorCore, all mixins, and navigation primitives

## Installation

```yaml
dependencies:
  zenrouter_core: ^2.0.0
```

## Architecture

### The Triangle Relationship

| Component | Role | You Implement |
|-----------|------|---------------|
| **RouteTarget** | WHAT - Defines the navigation destination | Your route classes |
| **StackPath** | HOW - Manages route stack operations | Optional custom paths |
| **Component Render** | DISPLAY - Renders routes to screen | **Required** (Flutter widgets, DOM, etc.) |

The flow:
1. **Push a RouteTarget** onto a StackPath
2. **StackPath notifies** listeners of stack changes
3. **Component Render** listens and rebuilds based on current stack

---

## Core Components

### RouteTarget

**Role**: Base class for all navigation destinations.

Every screen, dialog, or navigable component extends RouteTarget. It provides:
- Route identity and equality (via `props`)
- Navigation lifecycle hooks (`onDidPop`, `onDiscard`, `onUpdate`)
- Stack path binding for coordinator access

```dart
class ProfileRoute extends RouteTarget {
  final int userId;
  
  ProfileRoute({required this.userId});
  
  @override
  List<Object?> get props => [userId];
}
```

**Lifecycle**: Creation → Redirect → Path Binding → Build → Active → Pop Request → Guard Check → Pop Completion → Cleanup

---

### CoordinatorCore<T extends RouteUri>

**Role**: Central hub managing navigation state and operations.

Provides:
- Navigation methods: `push`, `pop`, `replace`, `navigate`, `recover`
- Deep link handling via `parseRouteFromUri`
- Layout hierarchy resolution
- Listener notifications for UI rebuilds

```dart
class AppCoordinator extends CoordinatorCore<AppRoute> {
  @override
  StackPath<AppRoute> get root => 
      NavigationPath(key: const PathKey('root'));

  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async {
    // Convert URI to route
  }
}
```

**Navigation Methods**:
| Method | Behavior |
|--------|----------|
| `push(route)` | Adds route to stack |
| `pop(result)` | Removes top route |
| `replace(route)` | Clears stack, sets single route |
| `navigate(route)` | Smart navigation - pops to existing or pushes new |
| `recover(route)` | Deep link handling with RouteDeepLink strategy |

---

### StackPath<T extends RouteTarget>

**Role**: Container managing a stack of RouteTargets.

Provides:
- Route storage and access (`stack`, `activeRoute`)
- Path key for layout builder lookup
- Listener notifications for changes

```dart
// Access stack state
path.stack;           // Unmodifiable list of all routes
path.activeRoute;     // Top of stack (current route)
path.pathKey;         // PathKey identifier for builder lookup
```

**StackMutatable** mixin adds:
- `push(route)` - Add to top
- `pop(result)` - Remove top (respects guards)
- `replace(route)` - Replace current
- `navigate(route)` - Browser-style navigation

---

## Route Mixins

Mixins add capabilities to RouteTarget.

### RouteUri

**Role**: Provides URI-based identity for URL synchronization.

```dart
class AppRoute extends RouteUri {
  final int userId;
  
  @override
  Uri toUri() => Uri.parse('/profile/$userId');
  
  @override
  List<Object?> get props => [userId];
}
```

Combines `RouteIdentity<Uri>` + `RouteLayoutChild`.

---

### RouteDeepLink

**Role**: Configures deep link handling behavior.

```dart
class AppRoute extends RouteUri with RouteDeepLink {
  @override
  Uri toUri() => Uri.parse('/profile/$userId');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.navigate;
  
  @override
  Future<void> deeplinkHandler(CoordinatorCore coordinator, Uri uri) async {
    // Custom handling
  }
}
```

**Strategies**:
| Strategy | Behavior |
|----------|----------|
| `replace` | Replace current stack (default) |
| `navigate` | Pop to existing or push new |
| `push` | Always push new |
| `custom` | Use custom handler |

---

### RouteGuard

**Role**: Blocks pop operations based on conditions.

```dart
class FormRoute extends RouteTarget with RouteGuard {
  @override
  FutureOr<bool> popGuard() async {
    if (hasUnsavedChanges) {
      return await _showDiscardDialog();
    }
    return true;
  }
  
  // Variant with coordinator access
  @override
  FutureOr<bool> popGuardWith(CoordinatorCore coordinator) {
    return popGuard();
  }
}
```

Called during: `StackMutatable.pop()`, `CoordinatorCore.tryPop()`, browser back button.

---

### RouteIdentity<T>

**Role**: Provides unique identifier for route matching.

```dart
// URI-based (common)
class AppRoute extends RouteTarget with RouteIdentity<Uri> {
  @override
  Uri get identifier => Uri.parse('/profile/$userId');
}

// String-based
class AppRoute extends RouteTarget with RouteIdentity<String> {
  @override
  String get identifier => 'profile_$userId';
}
```

---

### Nested Routing with RouteLayout

**Role**: Enable nested layout hierarchies (tab navigation, shell routes).

**Real Example from zenrouter**:

```
┌────────────────────────────────────────────────────────────────┐
│ AppCoordinator                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ paths: [homeStack, tabIndexed, settingsStack, ...]      │   │
│  └─────────────────────────────────────────────────────────┘   │
│        │                    │                    │             │
│        ▼                    ▼                    ▼             │
│  ┌────────────┐       ┌────────────┐       ┌─────────────┐     │
│  │ homeStack  │       │ tabIndexed │       │settingsStack│     │
│  │ (NavPath)  │       │(IdxStack)  │       │ (NavPath)   │     │
│  └────────────┘       └────────────┘       └─────────────┘     │
│        │                    │                    │             │
│        │ bindLayout         │ bindLayout         │ bindLayout  │
│        ▼                    ▼                    ▼             │
│  ┌────────────┐       ┌────────────┐       ┌──────────────┐    │
│  │HomeLayout  │       │TabBarLayout│       │SettingsLayout│    │
│  │            │       │            │       │              │    │
│  │ resolvePath│       │ resolvePath│       │ resolvePath. │    │
│  │  ───────►  │       │  ───────►  │       │  ───────►    │    │
│  │ homeStack  │       │ tabIndexed │       │settingsStack.│    │
│  └────────────┘       └────────────┘       └──────────────┘    │
│        │                                                       │
│        │ Route.layout = HomeLayout                             │
│        ▼                                                       │
│  ┌────────────┐                                                │
│  │ FeedDetail │ ◄── belongs to HomeLayout                      │
│  └────────────┘                                                │
└────────────────────────────────────────────────────────────────┘
```

**Key Concepts**:

| Concept | Type | Description |
|---------|------|-------------|
| `RouteLayoutParent.layoutKey` | `Object` | Lookup key for finding layout constructor (not forced to be Type) |
| `RouteLayoutChild.parentLayoutKey` | `Object?` | The key that identifies which parent layout this route belongs to |
| `RouteLayout.resolvePath()` | `StackPath` | Returns the StackPath this layout manages |
| `StackPath.bindLayout()` | void | Binds a layout constructor to a path |

**Note**: In zenrouter (Flutter), `RouteLayout` provides a default `layoutKey` returning `runtimeType`, and `RouteUnique` adds a convenience `.layout` property (Type). But in zenrouter_core, `layoutKey` is just `Object` - you can use any object as key.

**Implementation**:

```dart
// 1. Define base route
abstract class AppRoute extends RouteTarget with RouteUnique {}

// 2. Define layout route (shell with nested navigation)
// Note: layoutKey can be any Object, not just Type
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  // layoutKey defaults to runtimeType, or override:
  // @override
  // Object get layoutKey => 'home';  // Use String key instead

  // Return the StackPath this layout manages
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;

  // Build the layout UI
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      // RouteLayout.buildPath() internally gets the builder
      body: buildPath(coordinator),
    );
  }
}

// 3. Child routes specify their layout via .layout property (zenrouter convenience)
class FeedDetail extends AppRoute {
  @override
  Type get layout => HomeLayout;  // Belongs to HomeLayout

  @override
  Uri toUri() => Uri.parse('/home/feed/$id');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed Detail')),
      body: Center(child: Text('Feed $id')),
    );
  }
}

// 4. Tab layout (uses IndexedStackPath)
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabIndexed;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: buildPath(coordinator)),  // IndexedStack
          // Tab bar
          BottomNavigationBar(...),
        ],
      ),
    );
  }
}

// 5. Coordinator creates paths and binds layouts
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  )..bindLayout(HomeLayout.new);  // Bind layout to path

  late final IndexedStackPath<AppRoute> tabIndexed =
      IndexedStackPath.createWith(coordinator: this, label: 'tabs', [
        FeedTabLayout(),
        ProfileTab(),
        SettingsTab(),
      ])..bindLayout(TabBarLayout.new);

  @override
  List<StackPath> get paths => [root, homeStack, tabIndexed, settingsStack];
}
```

**How Navigation Works**:

1. Push `FeedDetail(layout: HomeLayout)`
2. Coordinator checks `route.layout` → finds HomeLayout
3. If HomeLayout not active, activates it on `homeStack`
4. Pushes FeedDetail onto `homeStack` (which HomeLayout resolves to)
5. When rendering HomeLayout: `buildPath(coordinator)` → `getLayoutBuilder(path.pathKey)`

---

### RouteRedirect<T>

**Role**: Transforms routes before navigation.

```dart
class SplashRoute extends RouteTarget with RouteRedirect<RouteTarget> {
  @override
  FutureOr<RouteTarget> redirect() async {
    if (await auth.isLoggedIn) {
      return HomeRoute();
    }
    return LoginRoute();
  }
  
  // Variant with coordinator access
  @override
  FutureOr<RouteTarget?> redirectWith(CoordinatorCore coordinator) {
    return redirect();
  }
}
```

---

## Advanced Features

### CoordinatorModular

**Role**: Compose multiple route modules into one coordinator.

```dart
class AppCoordinator extends CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    AuthModule(this),
    ShopModule(this),
  };
  
  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute();
}
```

**RouteModule** responsibilities:
- `parseRouteFromUri` - Handle subset of URIs
- `paths` - Nested navigation paths
- `defineLayout` - Layout constructors
- `defineConverter` - State restoration

---

### Internal Utilities

**Myers Diff Algorithm** - For declarative navigation:

```dart
import 'package:zenrouter_core/src/internal/diff.dart';

final oldStack = [routeA, routeB, routeC];
final newStack = [routeA, routeD, routeC];

final ops = myersDiff(oldStack, newStack);
// Result: [Keep(0,0), Delete(1), Insert(routeD, 1), Keep(2,2)]

applyDiff(path, ops);
```

---

## Building a Platform Integration

zenrouter_core is **renderer-agnostic**. To use with a platform:

1. **Create your routes** extending RouteTarget with appropriate mixins

2. **Create Coordinator** extending CoordinatorCore

3. **Implement component render** that:
   - Listens to Coordinator/StackPath changes
   - Builds widgets based on current stack
   - Handles back button, deep links

---

## Export Reference

```dart
// Core
export 'src/coordinator/base.dart';       // CoordinatorCore
export 'src/coordinator/modular.dart';   // CoordinatorModular, RouteModule
export 'src/path/base.dart';             // StackPath, PathKey, StackMutatable
export 'src/path/navigatable.dart';       // StackNavigatable, NavigationPath

// Mixins
export 'src/mixin/target.dart';           // RouteTarget
export 'src/mixin/uri.dart';              // RouteUri
export 'src/mixin/deeplink.dart';         // RouteDeepLink, DeeplinkStrategy
export 'src/mixin/guard.dart';            // RouteGuard
export 'src/mixin/identity.dart';         // RouteIdentity
export 'src/mixin/layout.dart';           // RouteLayoutParent, RouteLayoutChild
export 'src/mixin/redirect.dart';         // RouteRedirect
export 'src/mixin/redirect_rule.dart';    // RedirectRule

// Internal
export 'src/internal/diff.dart';          // myersDiff, DiffOp, applyDiff
export 'src/internal/equatable.dart';     // Equatable
export 'src/internal/reactive.dart';     // ListenableObject
```
