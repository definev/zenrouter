# RouteLayout Guide

RouteLayout is a powerful mixin that enables you to create nested navigation structures like shells, tab bars, and custom layouts. This guide covers how to create custom layouts and register them with your Coordinator.

## What is RouteLayout?

`RouteLayout` is a mixin that transforms a route into a container that manages a `StackPath` (navigation container). Think of it as a "shell" or "wrapper" that can display multiple child routes within its own stack path.

**Common use cases:**
- **Tab bars**: Show multiple tabs with their own navigation stacks
- **Shell routes**: Wrap routes with a persistent UI (e.g., sidebar, navigation bar)
- **Modal flows**: Create custom navigation containers for modals or sheets
- **Master-detail layouts**: Side-by-side navigation for tablets and desktops

## Built-in Stack Paths

ZenRouter provides two built-in `StackPath` implementations:

| Type | Purpose | Behavior |
|------|---------|----------|
| **NavigationPath** | Standard navigation | Mutable stack with push/pop operations |
| **IndexedStackPath** | Tab navigation | Fixed stack with indexed switching |

Both are automatically registered and ready to use. Custom layouts typically use one of these paths.

---

## Creating a RouteLayout

### Step 1: Define Your Layout Route

A layout route must:
1. Use the `RouteLayout` mixin
2. Implement `resolvePath()` to return its `StackPath`
3. Build its UI using `buildPath()`

**Example: Simple Shell Layout**

```dart
class ShellLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.shellPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      drawer: MyDrawer(),
      // buildPath() renders the current route in the shell's path
      body: buildPath(coordinator),
    );
  }
}
```

### Step 2: Create the StackPath in Your Coordinator

Add a `StackPath` property to your coordinator. This holds the navigation stack for the layout.

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // Create a dedicated path for the shell layout
  late final NavigationPath<AppRoute> shellPath = NavigationPath.createWith(
    label: 'shell',        // Unique label for restoration
    coordinator: this,
  )
  // ✅ Register the route layout constructor
  ..bindLayout(ShellLayout.new);

  @override
  List<StackPath> get paths => [
    ...super.paths,
    shellPath,  // Register the path
  ];
}
```

> **Important:** Always use the `.createWith()` factory to bind paths to coordinators. This ensures proper lifecycle management and state restoration.

> **Why is this needed?**
> ZenRouter needs to create layout instances during navigation and state restoration. By registering the constructor, you enable ZenRouter to instantiate layouts without reflection (important for web and minification compatibility).

### Step 3: Assign Routes to the Layout

Routes specify which layout they belong to using the `layout` getter:

```dart
class HomeRoute extends AppRoute {
  @override
  Type get layout => ShellLayout;

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Center(child: Text('Home Page'));
  }
}
```

When you push `HomeRoute`, the coordinator will:
1. Check if `ShellLayout` is active
2. If not, activate/push the layout first
3. Then push `HomeRoute` to the shell's `NavigationPath`

---

## Using bindLayout (Recommended Pattern)

For a more concise approach, use the `bindLayout` extension method to register layouts inline:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> shellPath = NavigationPath.createWith(
    label: 'shell',
    coordinator: this,
  )..bindLayout(ShellLayout.new);  // ✅ Register layout inline

  @override
  List<StackPath> get paths => [...super.paths, shellPath];

  // No need to override defineLayout() when using bindLayout
}
```

**Benefits of `bindLayout`:**
- ✅ More concise (no separate `defineLayout()` method)
- ✅ Collocates path and layout registration
- ✅ Reduces boilerplate

**When to use each approach:**
| Approach | When to Use |
|----------|-------------|
| `bindLayout` | Modern code, single layout per path |
| `defineLayout()` | Multiple layouts, legacy code migration |

---

## Using definePath for Custom StackPaths

If you extend `StackPath` to create custom navigation behavior (e.g., modal sheets, custom transitions), you must register a builder using `definePath`.

### Creating a Custom StackPath

```dart
class ModalPath<T extends RouteTarget> extends StackPath<T>
    with StackMutatable<T> {
  // 1. Define a unique PathKey
  static const key = PathKey('ModalPath');

  ModalPath._(super.stack, {super.debugLabel, super.coordinator});

  factory ModalPath.createWith({
    required Coordinator coordinator,
    required String label,
  }) => ModalPath._([], debugLabel: label, coordinator: coordinator);

  // 2. Return the key
  @override
  PathKey get pathKey => key;

  @override
  T? get activeRoute => _stack.lastOrNull;

  @override
  void reset() {
    for (final route in _stack) {
      route.completeOnResult(null, null, true);
    }
    _stack.clear();
  }

  @override
  Future<void> activateRoute(T route) async {
    reset();
    push(route);
  }
}
```

### Registering the Custom Path Builder

Use `definePath` to tell ZenRouter how to render your custom path:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final ModalPath<AppRoute> modalPath = ModalPath.createWith(
    label: 'modal',
    coordinator: this,
  );

  @override
  void defineLayout() {
    // Register custom path builder
    RouteLayout.definePath(
      ModalPath.key,
      (coordinator, path, layout) {
        return ModalStack(
          path: path as ModalPath<AppRoute>,
          coordinator: coordinator,
        );
      },
    );
  }
}
```

The builder receives:
- `coordinator`: Your app's coordinator
- `path`: The StackPath instance
- `layout`: The parent RouteLayout (if nested)

---

## Complete Example: Tab Bar with Nested Navigation

Here's a real-world example showing tabs with independent navigation stacks.

```dart
// ============================================================================
// Routes
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabIndexed;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabIndexed;
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: buildPath(coordinator)),  // Tab content
          _buildTabBar(coordinator, path),          // Tab buttons
        ],
      ),
    );
  }

  Widget _buildTabBar(AppCoordinator coordinator, IndexedStackPath path) {
    return ListenableBuilder(
      listenable: path,
      builder: (context, _) => Row(
        children: [
          _TabButton(
            label: 'Home',
            isActive: path.activeIndex == 0,
            onTap: () => coordinator.push(HomeTab()),
          ),
          _TabButton(
            label: 'Profile',
            isActive: path.activeIndex == 1,
            onTap: () => coordinator.push(ProfileTab()),
          ),
        ],
      ),
    );
  }
}

// Each tab can have its own nested navigation
class HomeTabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type get layout => TabBarLayout;  // Nested inside TabBarLayout

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeTabPath;
}

class HomeTab extends AppRoute {
  @override
  Type get layout => HomeTabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/home');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('Item 1'),
          onTap: () => coordinator.push(DetailRoute(id: '1')),
        ),
      ],
    );
  }
}

class DetailRoute extends AppRoute {
  DetailRoute({required this.id});
  final String id;

  @override
  Type get layout => HomeTabLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/home/detail/$id');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail $id')),
      body: Center(child: Text('Detail for $id')),
    );
  }

  @override
  List<Object?> get props => [id];
}

// ============================================================================
// Coordinator
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute> {
  // Tab container with indexed navigation
  late final IndexedStackPath<AppRoute> tabIndexed =
      IndexedStackPath.createWith(
    coordinator: this,
    label: 'tabs',
    [HomeTabLayout(), ProfileTab()],
  )..bindLayout(TabBarLayout.new);

  // Each tab gets its own navigation stack
  late final NavigationPath<AppRoute> homeTabPath =
      NavigationPath.createWith(
    label: 'home-tab',
    coordinator: this,
  )..bindLayout(HomeTabLayout.new);

  @override
  List<StackPath> get paths => [
    ...super.paths,
    tabIndexed,
    homeTabPath,
  ];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['tabs', 'home'] => HomeTab(),
      ['tabs', 'home', 'detail', final id] => DetailRoute(id: id),
      ['tabs', 'profile'] => ProfileTab(),
      _ => HomeTab(),
    };
  }
}
```

---

## Layout Hierarchies

Layouts can be nested arbitrarily. The coordinator resolves the full hierarchy when navigating.

**Example hierarchy:**
```
RootLayout (NavigationPath)
  └─ TabBarLayout (IndexedStackPath)
       ├─ HomeTabLayout (NavigationPath)
       │    └─ DetailRoute
       └─ ProfileTab
```

When you push `DetailRoute`:
1. Coordinator activates `RootLayout` (if needed)
2. Then activates `TabBarLayout` inside root
3. Then activates `HomeTabLayout` inside tabs
4. Finally pushes `DetailRoute` to home tab's path

**Navigation path resolution:**
- Each route's `layout` getter points to its parent
- The coordinator walks up the chain to build the full hierarchy
- All required layouts are activated/pushed automatically

---

## Key Concepts Reference

### RouteLayout Methods

| Method | Purpose |
|--------|---------|
| `resolvePath()` | Returns the StackPath this layout manages |
| `buildPath()` | Renders the current route in the path |
| `build()` | Builds the layout's UI (wrap with shell, etc.) |

### Registration Functions

| Function | Purpose | When to Use |
|----------|---------|-------------|
| `bindLayout()` | Register layout constructor inline | Modern code, recommended |
| `defineLayout()` | Register layout in coordinator | Multiple layouts, legacy code |
| `definePath()` | Register custom StackPath builder | Custom navigation containers |

### Best Practices

✅ **Do:**
- Use `bindLayout` for cleaner code
- Always use `.createWith()` to bind paths to coordinators
- Provide unique `label` for each path (required for state restoration)
- Keep layout hierarchies simple and logical

❌ **Don't:**
- Create paths without binding to a coordinator
- Forget to register layouts with `bindLayout` or `defineLayout`
- Create circular layout dependencies
- Use the same label for multiple paths

---

## Troubleshooting

### Error: "Missing RouteLayout constructor"

```
Missing RouteLayout constructor for [MyLayout] must define by calling 
[defineLayoutParent] in [defineLayout] function
```

**Solution:** Register the layout constructor:
```dart
// Option 1: Using bindLayout (recommended)
late final path = NavigationPath.createWith(...)
  ..bindLayout(MyLayout.new);

// Option 2: Using defineLayout
@override
void defineLayout() {
  RouteLayout.defineLayout(MyLayout, MyLayout.new);
}
```

### Error: "No layout builder provided"

```
No layout builder provided for [CustomPath]. If you extend the [StackPath] 
class, you must register it via [RouteLayout.definePath]
```

**Solution:** Register your custom path's builder:
```dart
@override
void defineLayout() {
  RouteLayout.definePath(
    CustomPath.key,
    (coordinator, path, layout) => CustomPathWidget(path: path),
  );
}
```

### Layout Not Appearing

**Check:**
1. Path is added to `coordinator.paths` list
2. Layout is registered with `bindLayout` or `defineLayout`
3. Route's `layout` getter returns the correct Type
4. Path is bound to coordinator with `.createWith()`

---

## Next Steps

- **See [getting-started.md](./getting-started.md)** for basic navigation patterns
- **See [query-parameters.md](./query-parameters.md)** for handling URL parameters
- **See [state-restoration.md](./state-restoration.md)** for persisting navigation state
- **Check example code** in `packages/zenrouter/example/lib/main_coordinator.dart`

---

**Need help?** File an issue at [github.com/definev/zenrouter/issues](https://github.com/definev/zenrouter/issues)
