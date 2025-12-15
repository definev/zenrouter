# Write your first Coordinator

> **Centralize routing, handle deep links, manage nested navigation**

You are now starting the quick start guide to create your first Coordinator to enable handling routing in your app. In about 15 minutes, you will learn the basics. Now let's start!

## What is a Coordinator?

The Coordinator is a pattern that provides a centralized routing system with deep linking, URL synchronization, and support for complex nested navigation hierarchies. It's the most powerful paradigm in ZenRouter, building on top of the imperative foundation.

### When to Use Coordinator

- You need deep linking or web URL support
- Building for web with browser navigation
- You want centralized route management
- You have complex nested navigation (tabs within tabs, drawer + tabs)
- You need URL-based routing and navigation
- You want debuggable route state
- You're building a large app with many routes

Let's dive into the core concepts of the Coordinator.


## Example app

The code of example app can be found [here](https://github.com/definev/zenrouter/tree/main/packages/zenrouter/doc/paradigms/coordinator/example). You can go to the `example` folder and run `flutter run` to see the final result or follow step by step guide below.

### Create the project

Let's create your project with the `flutter create` command.

```bash
flutter create --empty coordinator_example
cd coordinator_example
```

After that open the project inside your favourite IDE and add the `zenrouter` dependency to your `pubspec.yaml` file.

```yaml
dependencies:
  zenrouter: ^0.2.1
```

Now that the setup is complete, let's create a folder structure for our app.

```bash
lib
|- main.dart
|- routes
| |- coordinator.dart
| |- app_route.dart
```

### Setup Coordinator

A `Coordinator` is the central piece of URI routing.

A `Coordinator` manages multiple `StackPath`s and provides:
1. **URI Parsing** - Converts URLs to routes
2. **Route Resolution** - Finds the correct path for each route
3. **Deep Linking** - Handles incoming deep links
4. **Nested Navigation** - Manages multiple navigation stacks

When using Coordinator you must override `parseRouteFromUri` method to convert **URI** to **Route**.

The AppRoute class represents a route in the application. It extends the RouteTarget class and implements the RouteUnique mixin. This ensures that each route has a unique identifier. See more at [Mixin Section](#routeunique).

```dart
/// file: lib/routes/coordinator.dart

import 'app_route.dart';

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    ...
  }
}
```

And setup the `AppRoute` for `Coordinator`.

```dart
/// file: lib/routes/app_route.dart

abstract class AppRoute extends RouteTarget with RouteUnique {}
```

### How to create a Route?

You will extend the `AppRoute` abstract class above to create a new Route in our app.

For example, here is the `Home` and `PostDetail` route. `Home` has no parameters, while `PostDetail` has an `id` parameter.

> **Important**: When a route has parameters (like `id` in `PostDetail`), you **must** override `props` to include them. ZenRouter uses this for equality checks to prevent duplicate routes and handle updates correctly.

```dart
/// file: lib/routes/app_route.dart

class Home extends AppRoute {
  Uri toUri() => Uri.parse('/');
  
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => coordinator.push(PostDetail(id: 1)),
          child: const Text('Go to Post Detail'),
        ),
      ),
    );
  }
}

class PostDetail extends AppRoute {
  PostDetail({
    required this.id,
  });
  
  final String id;
  
  /// If the params has involved in `toUri` function, you must add it to `props`
  List<Object?> get props => [id];
  
  Uri toUri() => Uri.parse('/post/$id');
  
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post $id Detail'),
      ),
      body: Center(
        child: Text('Post ID: $id'),
      ),
    );
  }
}
```

### Wiring up the Coordinator

So let's go back to your `AppCoordinator`. You will need to implement the `uri` to `AppRoute` mapping in the `parseRouteFromUri` method.

```dart
/// file: lib/routes/coordinator.dart

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => Home(),
      ['post', String id] => PostDetail(id: id),
      /// No matching route found
      _ => NotFoundRoute(uri: uri),
    };
  }
}

/// No matching route found
class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});

  final Uri uri;
  
  @override
  Uri toUri() => uri;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
      ),
      body: Center(
        child: Text('Route not found: $uri'),
      ),
    );
  }
}
```

That's it! You have now created a Coordinator that can handle deep links and nested navigation.

Finally just wire your `Coordinator` inside your `MaterialApp`.

```dart

void main() {
  runApp(const MainApp());
}

/// The entrypoint of your app
/// 
/// It wire up the `Coordinator` inside your `MaterialApp`.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  final appCoordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: appCoordinator.routerDelegate,
      routeInformationParser: appCoordinator.routeInformationParser,
    );
  }
}
```

Let's run your app in browser with 
```
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```
Now when you open `http://localhost:8080/#/post/123`, it goes directly to post 123.

### Advanced Usage

Now that you have two basic routes in your app, let's advance! 
Imagine a home view with two tabs: `Feed` and `Profile`.
- The `Feed` tab contains two sub-routes: `PostList` and `PostDetail`.
- The `Profile` tab contains two sub-routes: `ProfileView` and `SettingsView`.

The `Feed` Flow: You have a list of posts, and when you click on a post, it will navigate to the `PostDetail` route.

```bash
 0---------------------0
 |                     |
 | Post 1              |
 |- - - - - - - - - - -|
 | Post 2              |
 |- - - - - - - - - - -|
 | Post 3              |
 |- - - - - - - - - - -|
 | Post 4              |
 |- - - - - - - - - - -|
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |    *     |          |
 0---------------------0
          |
          | Click "Post 1"
          V
 0---------------------0
 |                     |
 |    Post 1 Detail    |
 |- - - - - - - - - - -|
 |                     |
 |                     |
 |      Post id: 1     |
 |         |           |
 |     Lorem ipsum     |
 |                     |
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |    *     |          |
 0---------------------0

```

The `Profile` Flow: You have a profile view and a settings view.

```bash
 0---------------------0
 |                     |
 | Hello, User         |
 |- - - - - - - - - - -|
 | Open "Settings"     |
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |          |    *     |
 0---------------------0
          |
          | Click "Settings"
          V
 0---------------------0
 |                     |
 | <- Settings View    |
 |- - - - - - - - - - -|
 |                     |
 |                     |
 |                     |
 |                     |
 |                     |
 0---------------------0
 |  Feed    | Profile  |
 |          |    *     |
 0---------------------0
```

That represents the whole flow of our new app. To achieve this, I need to introduce you to a new concept: `RouteLayout`. `RouteLayout` implements `RouteUnique` and owns a `StackPath` (which contains a list of `RouteUnique` items).

There are two types of `StackPath`:
- `NavigationPath`: A stack path where you can push, pop, or remove routes dynamically; usually used with `NavigationStack`.
- `IndexedStackPath`: A stack path that has a fixed number of routes. You cannot modify it after initialization and can only select which one is currently active; usually used with `IndexedStack`.

For the layout above, we have 3 `RouteLayout`s to create:
- `FeedLayout`: A `NavigationPath` that can have 2 tabs: `PostList` and `PostDetail`.
- `ProfileLayout`: A `NavigationPath` that can have 2 tabs: `ProfileView` and `SettingsView`.
- `HomeLayout`: An `IndexedStackPath` that contains only 2 tabs: `FeedLayout` and `ProfileLayout`. (Note that `RouteLayout` is still a `RouteUnique`, so it can be used as a route).

You must define the `StackPath` in the `Coordinator`. Let's create it in `lib/routes/coordinator.dart`.

```dart
/// file: lib/routes/coordinator.dart

class AppCoordinator extends Coordinator<AppRoute> {
  late final homeIndexed = IndexedStackPath<AppRoute>.createWith(
    [
      FeedLayout(),
      ProfileLayout(),
    ],
    coordinator: this,
    debugLabel: 'home',
  );
  late final feedNavigation = NavigationPath<AppRoute>.coordinator(
    coordinator: this,
    debugLabel: 'feed',
  );
  late final profileNavigation = NavigationPath<AppRoute>.coordinator(
    coordinator: this,
    debugLabel: 'profile',
  );

  /// IMPORTANT: You must register all your stack paths here!
  /// ZenRouter uses this list to manage navigation state and listeners.
  /// Don't forget to include the 'root' path which is provided by the Coordinator.
  @override
  List<StackPath<RouteTarget>> get paths => [
    root, 
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];

  ...
}
```

And let's wire it up in `lib/routes/app_route.dart` file. The `FeedLayout` and `ProfileLayout` located within `HomeLayout` so we override the `layout` property in them to `HomeLayout`.

```dart
/// file: lib/routes/app_route.dart

class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.homeIndexed;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return Scaffold(
      body: RouteLayout.buildPrimitivePath<AppRoute>(
        IndexedStackPath,
        coordinator,
        path,
        this,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: path.activeIndex,
        onTap: (index) {
          coordinator.push(path.stack[index]);

          /// Ensure the selected tab is not empty
          switch (index) {
            case 0:
              if (coordinator.feedNavigation.stack.isEmpty) {
                coordinator.push(PostList());
              }
            case 1:
              if (coordinator.profileNavigation.stack.isEmpty) {
                coordinator.push(Profile());
              }
          }
        },
      ),
    );
  }
}

class FeedLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.feedNavigation;

  Type? get layout => HomeLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return RouteLayout.buildPrimitivePath<AppRoute>(
      NavigationPath,
      coordinator,
      path,
      this,
    );
  }
}

class ProfileLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.profileNavigation;

  Type? get layout => HomeLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return RouteLayout.buildPrimitivePath<AppRoute>(
      NavigationPath,
      coordinator,
      path,
      this,
    );
  }
}
```

We setting up the `RouteLayout` for our app. Now let's create the `PostList` and `PostDetail`.

```dart
class PostList extends AppRoute {
  Uri toUri() => Uri.parse('/post');

  /// `PostList` will be rendered inside `FeedLayout`
  Type? get layout => FeedLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Post 1'),
          onTap: () => coordinator.push(PostDetail(id: 1)),
        ),
        ListTile(
          title: const Text('Post 2'),
          onTap: () => coordinator.push(PostDetail(id: 2)),
        ),
      ],
    );
  }
}

class PostDetail extends AppRoute {
  ...

  /// `PostDetail` will be rendered inside `FeedLayout`
  /// Add this line in existing `PostDetail` route
  Type? get layout => FeedLayout;

  ...
}
```

Next up, we go to `ProfileLayout` and create `ProfileView` and `SettingsView`.

```dart

class Profile extends AppRoute {
  Uri toUri() => Uri.parse('/profile');

  /// `ProfileView` will be rendered inside `ProfileLayout`
  Type? get layout => ProfileLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const ListTile(title: Text('Hello, User')),
          ListTile(
            title: const Text('Open Settings'),
            onTap: () => coordinator.push(Settings()),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class Settings extends AppRoute {
  Uri toUri() => Uri.parse('/settings');

  /// `SettingsView` will be rendered inside `ProfileLayout`
  Type? get layout => ProfileLayout;

  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(
      child: Text('Settings View'),
    );
  }
}
```

Great, every route is set up. Now let's wire it up in the `lib/routes/coordinator.dart` file. The final boilerplate code when defining a layout is that you have to define a factory function in the `defineLayout` method.
The `defineLayout` function takes 2 parameters: the `Type` of `RouteLayout` and a factory `Function` that creates the `RouteLayout`.

```dart
/// file: lib/routes/coordinator.dart

class AppCoordinator extends Coordinator<AppRoute> {
  final homeIndexed = IndexedStackPath<AppRoute>(
    routes: [
      FeedLayout(),
      ProfileLayout(),
    ],
  );
  final feedNavigation = NavigationPath<AppRoute>();
  final profileNavigation = NavigationPath<AppRoute>();

  @override
  List<StackPath<RouteTarget>> get paths => [
    root,
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, HomeLayout.new);
    RouteLayout.defineLayout(FeedLayout, FeedLayout.new);
    RouteLayout.defineLayout(ProfileLayout, ProfileLayout.new);
  }

  ...
}

```

The `parseRouteFromUri` method needs to be reworked since we added many new screens.

### Handling Root Path

Sometimes you want to redirect the root path `/` to a specific route, like `PostList`. You can use `RouteRedirect` mixin to achieve this.

```dart
class IndexRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<AppRoute?> redirect() {
    return PostList();
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

Now let's update `parseRouteFromUri`:

```dart

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['post'] => PostList(),
      ['post', final id] => PostDetail(id: id),
      ['profile'] => Profile(),
      ['settings'] => Settings(),
      _ => NotFoundRoute(uri: uri),
    };
  }
}
```

All done. Now you can run your app and test it. The final result should be like this:

![Coordinator](https://raw.githubusercontent.com/definev/zenrouter/main/packages/zenrouter/doc/paradigms/coordinator/final.gif)

## API Reference

For complete API documentation including all methods, properties, and advanced usage, see:

**[→ Coordinator API Reference](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md)**

Quick reference for `Coordinator`:

| Method | Description |
|--------|-------------|
| `parseRouteFromUri(Uri)` | Abstract method to parse URLs into routes |
| `push(T)` | Push route onto appropriate path |
| `pop()` | Pop from nearest dynamic path |
| `replace(T)` | Wipe stack and replace with route |
| `pushOrMoveToTop(T)` | Push or move route to top |
| `recoverRouteFromUri(Uri)` | Handle deep link URI |

| Property | Description |
|----------|-------------|
| `root` | Main navigation path (always present) |
| `paths` | All navigation paths managed by coordinator |
| `routerDelegate` | Router delegate for MaterialApp.router |
| `routeInformationParser` | Route information parser |

**Example:**
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

MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```


## Route Mixins for Coordinator

These mixins provide special functionality when using the coordinator pattern:

### RouteUnique

**Required** for all routes used with Coordinator.

```dart
mixin RouteUnique on RouteTarget {
  // Convert route to URL
  Uri toUri();
  
  // Build the UI for this route
  Widget build(Coordinator coordinator, BuildContext context);
  
  // Optional: Layout layout for nested navigation
  Type? get layout => null;
}
```

**Example:**
```dart
class HomeRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
    );
  }
}
```

### RouteLayout<T>

Creates a navigation layout that contains other routes.

```dart
mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  // Which path does this layout manage?
  StackPath<RouteUnique> resolvePath(Coordinator coordinator);
  
  // Builds the layout UI (automatically delegates to layoutBuilderTable)
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context);
  
  // Optional: Parent layout Type
  @override
  Type? get layout => null;
}
```

**Example - NavigationStack style navigation layout:**
```dart
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RouteLayout.buildPrimitivePath(
        NavigationPath,
        coordinator,
        coordinator.homeStack,
        this,
      ),
    );
  }
}

// Routes specify layout using Type reference
class DetailRoute extends AppRoute {
  @override
  Type? get layout => HomeLayout;
}

// Register in Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, () => HomeLayout());
  }
}
```

**Example - Indexed navigation layout (tabs):**
```dart
class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    return Scaffold(
      body: RouteLayout.buildPrimitivePath(
        IndexedStackPath,
        coordinator,
        path,
        this,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (index) => coordinator.push(tabs[index]),
        items: [...],
      ),
    );
  }
}

// Tab routes use Type reference
class HomeTab extends AppRoute {
  @override
  Type? get layout => TabLayout;
}
```

### RouteDeepLink

Custom deep link handling with strategies.

```dart
mixin RouteDeepLink on RouteUnique {
  // Strategy for handling deep links
  DeeplinkStrategy get deeplinkStrategy;
  
  // Custom deep link handler
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri);
}

enum DeeplinkStrategy {
  replace,  // Replace current stack (default)
  push,     // Push onto current stack
  custom,   // Use custom handler
}
```

**Example:**
```dart
class ProductRoute extends AppRoute with RouteDeepLink {
  final String productId;
  
  ProductRoute(this.productId);
  
  @override
  Uri toUri() => Uri.parse('/product/$productId');
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // Custom logic: ensure we're in the right tab
    coordinator.replace(ShopTab());
    
    // Load product data
    final product = await loadProduct(productId);
    
    // Then navigate to this route
    coordinator.push(this);
    
    // Log analytics
    analytics.logDeepLink(uri);
  }
}
```

## Deep Linking

### How Deep Links Work

1. App opens with URL: `myapp://home/feed/123`
2. Coordinator calls `parseRouteFromUri(Uri.parse('myapp://home/feed/123'))`
3. You return: `FeedDetail(id: '123')`
4. Coordinator checks if route has `RouteDeepLink`
   - If yes and strategy == `custom`: Call `deeplinkHandler()`
   - If yes and strategy == `push`: Push route
   - If no: Replace stack with route

### Deep Link Strategies

#### Replace (Default)

Replaces the entire stack with the deep link route:

```dart
// URL: myapp://profile/123
// Result: Stack = [ProfileRoute('123')]
```

#### Push

Pushes the route onto the existing stack:

```dart
class MyRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
}

// If stack was [HomeRoute()]
// After deep link: Stack = [HomeRoute(), ProfileRoute('123')]
```

#### Custom

Full control over deep link handling:

```dart
class CheckoutRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // 1. Ensure user is logged in
    if (!await auth.isLoggedIn()) {
      coordinator.replace(LoginRoute(
        redirectTo: uri.toString(),
      ));
      return;
    }
    
    // 2. Set up the navigation stack
    coordinator.replace(HomeRoute());
    coordinator.push(CartRoute());
    coordinator.push(this);
    
    // 3. Track analytics
    analytics.logDeepLink(uri);
  }
}
```

### Testing Deep Links

#### iOS Simulator
```bash
xcrun simctl openurl booted "myapp://home/feed/123"
```

#### Android Emulator
```bash
adb shell am start -W -a android.intent.action.VIEW \\
  -d "myapp://home/feed/123" com.example.myapp
```

#### Flutter
```dart
// In your code
coordinator.recoverRouteFromUri(
  Uri.parse('myapp://home/feed/123'),
);
```

## See Also

- [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Direct stack control
- [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) - State-driven routing
- [Route Mixins Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - All available mixins
- [Coordinator API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/coordinator.md) - Complete API reference
- [Deep Linking Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/deep-linking.md) - Deep linking setup
