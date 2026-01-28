# Route Mixin System

> **Compose route behavior with mixins**

ZenRouter uses a mixin-based architecture that lets you add specific behaviors to your routes. Instead of a deep inheritance hierarchy, you compose functionality by mixing in exactly what you need.

## Overview

```dart
class MyRoute extends RouteTarget    // Base class (required)
    with RouteUnique                 // For coordinator (optional)
    with RouteGuard                  // Prevent navigation (optional)
    with RouteRedirect               // Conditional routing (optional)
    with RouteRedirect               // Conditional routing (optional)
    with RouteDeepLink               // Custom deep link handling (optional)
    with RouteQueryParameters {      // Efficient query handling (optional)
  // Your route implementation
}
```

Each mixin adds specific capabilities:
- **RouteUnique** - Makes route work with Coordinator
- **RouteLayout** - Creates navigation layout for nested routes
- **RouteTransition** - Custom page transitions
- **RouteGuard** - Prevents unwanted navigation
- **RouteRedirect** - Redirects to different routes
- **RouteRedirectRule** - Composable redirect rules (works with RouteRedirect)
- **RouteDeepLink** - Custom deep link handling
- **RouteQueryParameters** - Efficiently handle query parameters

### Decision Tree

```
Which mixins do I need?
│
├─ Need custom page transitions?
│  ├─ Yes → Add RouteTransition ✓
│  └─ No → Continue
│
├─ Prevent navigation (unsaved changes)?
│  ├─ Yes → Add RouteGuard ✓
│  └─ No → Continue
│
├─ Conditional routing (auth, permissions)?
│  ├─ Need reusable/composable rules?
│  │  ├─ Yes → Add RouteRedirect + RouteRedirectRule ✓
│  │  └─ No → Add RouteRedirect ✓
│  └─ No → Continue
│
├─ Using Coordinator?
│  ├─ Yes → Add RouteUnique ✓
│  └─ No → Just extend RouteTarget
│
├─ Creating a navigation layout (tabs, navigation-stack)?
│  ├─ Yes → Add RouteLayout ✓
│  └─ No → Continue
│
└─ Custom deep link handling?
   ├─ Yes → Add RouteDeepLink ✓
   └─ No → Continue
│
└─ Need query parameters with granular updates?
   ├─ Yes → Add RouteQueryParameters ✓
   └─ Done!
```


## Mixin Reference

### RouteUnique

Makes a route identifiable by `Coordinator` and provides URI mapping. This mixin is **required** when using the Coordinator pattern for deep linking and URL synchronization.

**Required when:**
- Using the Coordinator pattern
- You need deep linking support
- You want URL synchronization

**Not needed when:**
- Using pure imperative navigation
- Using pure declarative navigation without Coordinator

#### Recommended Pattern

When using `RouteUnique`, **create a base abstract class first** that extends `RouteTarget` with the `RouteUnique` mixin. Then have all your app routes extend this base class:

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {}
```

**Why this pattern?**
1. **Narrows Coordinator scope** - Your `Coordinator<AppRoute>` only works with `AppRoute` types, providing strong type safety
2. **Better library context** - The internal library can accurately infer types and handle routing logic more efficiently
3. **Cleaner architecture** - Single source of truth for your app's route contract
4. **Covariant coordinator** - Routes receive your specific `AppCoordinator` type in `build()` methods, giving access to custom methods

> [!IMPORTANT]
> The `Coordinator` class is **covariant**. When you create `AppCoordinator extends Coordinator<AppRoute>`, the `build()` method in your routes will receive `AppCoordinator` (not generic `Coordinator`), providing type-safe access to any custom methods or properties you add.

#### API

```dart
mixin RouteUnique on RouteTarget {
  // Convert route to URI
  Uri toUri();
  
  // Build the UI for this route
  Widget build(covariant Coordinator coordinator, BuildContext context);
  
  // Optional: Parent layout Type
  Type? get layout => null;
  
  // Create a new layout instance (called automatically)
  RouteLayout? createLayout(covariant Coordinator coordinator);
  
  // Resolve or create layout from active layouts (called automatically)
  RouteLayout? resolveLayout(covariant Coordinator coordinator);
}
```

#### Example: Basic Setup

```dart
// 1. Create base route class
abstract class AppRoute extends RouteTarget with RouteUnique {}

// 2. Define concrete routes
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
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
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}

// 3. Create coordinator
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
```

#### Example: With Parameters

```dart
class UserRoute extends AppRoute {
  final String userId;
  
  UserRoute(this.userId);
  
  @override
  Uri toUri() => Uri.parse('/user/$userId');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User: $userId')),
      body: UserProfile(userId: userId),
    );
  }
  
  @override
  List<Object?> get props => [userId];
}
```

---

### RouteLayout<T>

Creates a navigation layout that contains and manages other routes, essential for building nested navigation hierarchies like tab bars, drawers, and shell routes.

`RouteLayout` acts as a layout for `StackPath` instances. Each type of stack path requires its own corresponding layout widget. ZenRouter provides two built-in path types: `NavigationPath` (for stack-based push/pop navigation) uses `NavigationStack` as its layout, while `IndexedStackPath` (for tab bars and indexed navigation) uses `IndexedStack` as its layout.

**Custom Layouts**: You can create your own layout types by implementing the `RouteLayout` mixin, registering the constructor in `layoutConstructorTable`, and providing the default widget builder in `layoutBuilderTable`. For more details, check out the advanced tutorial.

#### API

```dart
mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  // Which navigation path does this layout manage?
  StackPath<RouteUnique> resolvePath(covariant Coordinator coordinator);
  
  // Builds the layout UI (automatically delegates to layoutBuilderTable)
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context);
  
  // Optional: Parent layout Type (for nested layouts)
  @override
  Type? get layout => null;
  
  // Static tables for layout construction and building
  static Map<Type, RouteLayoutConstructor> layoutConstructorTable = {};
  static Map<String, RouteLayoutBuilder> layoutBuilderTable = {...};
  
  // Register a layout constructor
  static void defineLayout<T extends RouteLayout>(
    Type layoutType,
    T Function() constructor,
  );
}
```

#### Example: Tab Bar Layout (Indexed Navigation)

```dart
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;
  
  @override
  Uri toUri() => Uri.parse('/tabs');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (index) => switch (index) {
          0 => coordinator.push(FeedTab()),
          1 => coordinator.push(ProfileTab()),
          2 => coordinator.push(SettingsTab()),
          _ => null,
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// Tab routes point to the tab layout using Type reference
class FeedTab extends AppRoute {
  @override
  Type? get layout => TabBarLayout;
  
  @override
  Uri toUri() => Uri.parse('/tabs/feed');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(child: Text('Feed Tab'));
  }
}

// Register layout in Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineLayout() {
    RouteLayout.defineLayout(TabBarLayout, () => TabBarLayout());
  }
}
```

#### Example: Stack Navigation Layout (NavigationStack style)

```dart
class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.settingsStack;
  
  @override
  Uri toUri() => Uri.parse('/settings');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: buildPath(coordinator),
    );
  }
  
}

// Settings routes point to settings layout using Type reference
class GeneralSettings extends AppRoute {
  @override
  Type? get layout => SettingsLayout;
  
  @override
  Uri toUri() => Uri.parse('/settings/general');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Account'),
          onTap: () => coordinator.push(AccountSettings()),
        ),
        ListTile(
          title: const Text('Privacy'),
          onTap: () => coordinator.push(PrivacySettings()),
        ),
      ],
    );
  }
}

// Register layout in Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineLayout() {
    RouteLayout.defineLayout(SettingsLayout, () => SettingsLayout());
  }
}
```

#### Example: Nested Layouts

```dart
// Level 1: Main app layout
class AppLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.mainStack;
  
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: buildPath(coordinator),
    );
  }
}

// Level 2: Tab bar layout (nested inside AppLayout)
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type? get layout => AppLayout; // Parent layout Type
  
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;
  
  @override
  Uri toUri() => Uri.parse('/tabs');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(/* ... */),
    );
  }
}

// Level 3: Feed stack layout (nested inside TabBarLayout)
class FeedLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type? get layout => TabBarLayout; // Parent layout Type
  
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.feedStack;
  
  @override
  Uri toUri() => Uri.parse('/tabs/feed');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return buildPath(coordinator);
  }
}

// Register all layouts in Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineLayout() {
    RouteLayout.defineLayout(AppLayout, () => AppLayout());
    RouteLayout.defineLayout(TabBarLayout, () => TabBarLayout());
    RouteLayout.defineLayout(FeedLayout, () => FeedLayout());
  }
}
```

---

### RouteGuard

Prevents navigation away from a route unless specific conditions are met, ideal for protecting unsaved work or confirmation prompts. When a user attempts to navigate away (via back button, swipe gesture, or programmatic `pop()`), the `popGuard()` method is automatically called to determine whether navigation should proceed.

Use this mixin when you need to protect forms with unsaved changes, prevent interruption of ongoing processes, or require user confirmation before leaving a screen.

#### API

```dart
mixin RouteGuard on RouteTarget {
  // Return true to allow pop, false to prevent
  FutureOr<bool> popGuard();

  // Called by system with coordinator context
  // Asserts path/coordinator consistency then calls popGuard()
  FutureOr<bool> popGuardWith(covariant Coordinator coordinator);
}
```

#### Example: Unsaved Changes Warning

```dart
class EditFormRoute extends RouteTarget with RouteUnique, RouteGuard {
  bool hasUnsavedChanges = false;
  
  @override
  Future<bool> popGuard() async {
    if (!hasUnsavedChanges) return true; // No unsaved changes, allow navigation
    
    // Ask user to confirm discarding changes
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }
  
  @override
  Uri toUri() => Uri.parse('/edit');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // popGuard() is automatically checked before navigation
            coordinator.pop();
          },
        ),
      ),
      body: TextField(
        onChanged: (value) => hasUnsavedChanges = true,
        decoration: const InputDecoration(
          hintText: 'Start typing...',
        ),
      ),
    );
  }
}
```

#### Example: Process Confirmation

```dart
class UploadRoute extends RouteTarget with RouteGuard {
  bool isUploading = false;
  
  @override
  Future<bool> popGuard() async {
    if (!isUploading) return true;
    
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload in Progress'),
        content: const Text('Cancel upload and go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Upload'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Upload'),
          ),
        ],
      ),
    );
    
    if (shouldCancel == true) {
      // Cancel the upload
      uploadTask.cancel();
    }
    
    return shouldCancel ?? false;
  }
}
```

---

### RouteRedirect<T>

Redirects navigation to a different route based on runtime conditions, essential for authentication flows, permission checks, and conditional routing. The `redirect()` method is called automatically when navigating to a route, allowing you to intercept and redirect to a different destination.

Use this mixin for authentication state checks, permission enforcement, data-driven conditional routing, or A/B testing different navigation flows.

#### API

```dart
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  // Return the target route (can be async)
  // Return `this` to proceed to the current route
  // Return null to cancel navigation
  FutureOr<T?> redirect();

  // Called by system with coordinator context
  // Intercepts and allows coordinator-aware redirect logic
  FutureOr<T?> redirectWith(covariant Coordinator coordinator);
}
```

#### Example: Authentication Check

```dart
class DashboardRoute extends RouteTarget 
    with RouteUnique, RouteRedirect<AppRoute> {
  @override
  Future<AppRoute?> redirect() async {
    final isLoggedIn = await authService.checkAuth();
    
    if (!isLoggedIn) {
      // User not authenticated, redirect to login with return URL
      return LoginRoute(redirectTo: '/dashboard');
    }
    
    // User is authenticated, proceed to dashboard
    return this;
  }
  
  @override
  Uri toUri() => Uri.parse('/dashboard');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Welcome to Dashboard!')),
    );
  }
}

class LoginRoute extends RouteTarget with RouteUnique {
  final String? redirectTo;
  
  LoginRoute({this.redirectTo});
  
  @override
  Uri toUri() => Uri.parse('/login');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await authService.login();
            if (redirectTo != null) {
              coordinator.recoverRouteFromUri(Uri.parse(redirectTo!));
            } else {
              coordinator.replace(DashboardRoute());
            }
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
```

#### Example: Permission Check

```dart
class AdminRoute extends RouteTarget with RouteRedirect<AppRoute> {
  @override
  Future<AppRoute?> redirect() async {
    final user = await authService.getCurrentUser();
    
    if (user == null) {
      return LoginRoute(redirectTo: '/admin');
    }
    
    if (!user.isAdmin) {
      return UnauthorizedRoute();
    }
    
    return this; // User has admin privileges, allow access
  }
}
```

#### Example: Data-Driven Redirect

```dart
class PostRoute extends RouteTarget with RouteRedirect<AppRoute> {
  final String postId;
  
  PostRoute(this.postId);
  
  @override
  Future<AppRoute?> redirect() async {
    final post = await postService.getPost(postId);
    
    if (post == null) {
      return NotFoundRoute();
    }
    
    if (post.isDeleted) {
      return DeletedPostRoute(postId);
    }
    
    if (post.requiresSubscription && !user.hasSubscription) {
      return SubscriptionRequiredRoute();
    }
    
    return this;
  }
}
```

#### Redirect Chains

Redirects can chain together automatically. ZenRouter follows each redirect until reaching a route that doesn't redirect:

```dart
// RouteA redirects to RouteB
class RouteA extends RouteTarget with RouteRedirect<AppRoute> {
  @override
  Future<AppRoute> redirect() async => RouteB();
}

// RouteB redirects to RouteC
class RouteB extends RouteTarget with RouteRedirect<AppRoute> {
  @override
  Future<AppRoute> redirect() async => RouteC();
}

// RouteC has no redirect, this is the final destination
class RouteC extends RouteTarget {}

// Pushing RouteA ends up at RouteC!
coordinator.push(RouteA());
// Internal flow: RouteA → RouteB → RouteC
```

---

### RouteRedirectRule

Enables composable, reusable redirect logic by chaining multiple `RedirectRule` instances together. This mixin works with `RouteRedirect` to provide a rule-based approach to redirects, making it easy to create reusable authentication, authorization, feature flag, and logging rules.

**Benefits over direct `RouteRedirect` implementation:**
- **Reusable**: One rule can be used for multiple routes
- **Composable**: Chain multiple rules together (auth → feature flag → logging)
- **Testable**: Test each rule independently
- **Maintainable**: Centralized redirect logic, easy to modify

**Use when:**
- You need the same redirect logic across multiple routes
- You want to combine multiple checks (auth + permissions + feature flags)
- You prefer a rule-based architecture
- You want to test redirect logic independently

**Not needed when:**
- You have simple, route-specific redirect logic
- You only need a single redirect check

#### API

```dart
// Base class for creating redirect rules
abstract class RedirectRule<T extends RouteTarget> {
  FutureOr<RedirectResult<T>> redirectResult(
    covariant Coordinator coordinator,
    covariant T route,
  );
}

// Result types
sealed class RedirectResult<T extends RouteTarget> {
  const RedirectResult.stop();              // Stop navigation
  const RedirectResult.continueRedirect();  // Continue to next rule
  const RedirectResult.redirectTo(T route); // Redirect to route
}

// Mixin for routes
mixin RouteRedirectRule<T extends RouteTarget> on RouteRedirect<T> {
  List<RedirectRule> get redirectRules;
  
  // Automatically implements RouteRedirect.redirectWith()
}
```

#### Example: Authentication Rule

```dart
class AuthenticationRule extends RedirectRule<AppRoute> {
  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) {
    if (!AuthService.isAuthenticated) {
      // Not logged in → redirect to login page
      return RedirectResult.redirectTo(LoginRoute());
    }
    // Logged in → continue to next rule
    return const RedirectResult.continueRedirect();
  }
}

class ProtectedRoute extends AppRoute
    with RouteRedirect, RouteRedirectRule {
  @override
  List<RedirectRule> get redirectRules => [
    AuthenticationRule(), // Check authentication first
  ];
  
  @override
  Uri toUri() => Uri.parse('/protected');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected')),
      body: const Center(child: Text('Protected Content')),
    );
  }
}
```

#### Example: Chaining Multiple Rules

```dart
class FeatureFlagRule extends RedirectRule<AppRoute> {
  final String feature;
  FeatureFlagRule({required this.feature});

  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    final isEnabled = await FeatureService.isEnabled(feature);
    if (!isEnabled) {
      return RedirectResult.stop(); // Stop navigation
    }
    return const RedirectResult.continueRedirect();
  }
}

class PermissionRule extends RedirectRule<AppRoute> {
  final String permission;
  PermissionRule({required this.permission});

  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      return RedirectResult.redirectTo(LoginRoute());
    }
    if (!user.hasPermission(permission)) {
      return RedirectResult.redirectTo(UnauthorizedRoute());
    }
    return const RedirectResult.continueRedirect();
  }
}

class LoggingRule extends RedirectRule<AppRoute> {
  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    // Log navigation event (side effect)
    Analytics.logNavigation(route.toUri());
    return const RedirectResult.continueRedirect(); // Always continue
  }
}

// Use all rules together
class AdminDashboardRoute extends AppRoute
    with RouteRedirect, RouteRedirectRule {
  @override
  List<RedirectRule> get redirectRules => [
    AuthenticationRule(),                    // 1. Check login
    PermissionRule(permission: 'admin'),     // 2. Check admin permission
    FeatureFlagRule(feature: 'admin-panel'), // 3. Check feature flag
    LoggingRule(),                           // 4. Log navigation
  ];
  
  @override
  Uri toUri() => Uri.parse('/admin/dashboard');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(child: Text('Admin Content')),
    );
  }
}
```

#### Rule Execution Flow

Rules are executed in the order they appear in the `redirectRules` list:

```
Rule 1: AuthenticationRule
  ├─ Not authenticated → RedirectResult.redirectTo(LoginRoute) → STOP ✅
  └─ Authenticated → RedirectResult.continueRedirect() → Continue

Rule 2: PermissionRule
  ├─ No permission → RedirectResult.redirectTo(UnauthorizedRoute) → STOP ✅
  └─ Has permission → RedirectResult.continueRedirect() → Continue

Rule 3: FeatureFlagRule
  ├─ Feature disabled → RedirectResult.stop() → STOP ❌ (cancel navigation)
  └─ Feature enabled → RedirectResult.continueRedirect() → Continue

Rule 4: LoggingRule
  └─ Always → RedirectResult.continueRedirect() → Continue

All rules passed → Display original route ✅
```

**Important:** Once a rule returns `StopRedirect` or `RedirectTo`, subsequent rules are **not executed**.

#### Example: Reusing Rules Across Routes

```dart
// Define rules once
final authRule = AuthenticationRule();
final adminPermissionRule = PermissionRule(permission: 'admin');
final userPermissionRule = PermissionRule(permission: 'user');

// Use in multiple routes
class AdminSettingsRoute extends AppRoute
    with RouteRedirect, RouteRedirectRule {
  @override
  List<RedirectRule> get redirectRules => [
    authRule,
    adminPermissionRule,
  ];
}

class UserProfileRoute extends AppRoute
    with RouteRedirect, RouteRedirectRule {
  @override
  List<RedirectRule> get redirectRules => [
    authRule,
    userPermissionRule,
  ];
}
```

#### Example: Async Rules

Rules can be async to fetch data, call APIs, or read from databases:

```dart
class SubscriptionRule extends RedirectRule<AppRoute> {
  @override
  Future<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    // Fetch subscription status from API
    final subscription = await SubscriptionService.getCurrent();
    
    if (subscription == null) {
      return RedirectResult.redirectTo(SubscribeRoute());
    }
    
    if (subscription.isExpired) {
      return RedirectResult.redirectTo(RenewSubscriptionRoute());
    }
    
    return const RedirectResult.continueRedirect();
  }
}
```

#### Example: Route-Specific Rule Logic

Rules can inspect the route being navigated to:

```dart
class RateLimitRule extends RedirectRule<AppRoute> {
  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    // Check if route requires premium subscription
    if (route is PremiumRoute) {
      final user = await AuthService.getCurrentUser();
      if (user?.isPremium != true) {
        return RedirectResult.redirectTo(UpgradeRoute());
      }
    }
    
    return const RedirectResult.continueRedirect();
  }
}
```

#### When to Use RouteRedirectRule vs RouteRedirect

| Use Case | Use RouteRedirect | Use RouteRedirectRule |
|----------|------------------|----------------------|
| Simple, route-specific logic | ✅ Yes | ❌ No |
| Reusable across multiple routes | ❌ No | ✅ Yes |
| Single check (auth only) | ✅ Yes | ✅ Yes (if reusable) |
| Multiple checks (auth + permissions + flags) | ❌ No | ✅ Yes |
| Testable, isolated logic | ❌ No | ✅ Yes |
| Side effects (logging, analytics) | ❌ No | ✅ Yes |

#### Best Practices

**✅ DO:**
- Put critical rules first (auth, permissions)
- Put side-effect rules last (logging, analytics)
- Make rules reusable across routes
- Test rules independently
- Use `StopRedirect` to cancel navigation when appropriate

**❌ DON'T:**
- Put side-effect rules before critical checks
- Create rules that depend on execution order unnecessarily
- Mix route-specific logic with reusable rules
- Return `null` from rules (use `StopRedirect` instead)

---

### RouteDeepLink

Provides custom handling for deep links with advanced control over navigation behavior. While ZenRouter handles basic deep linking automatically through `RouteUnique`, this mixin allows you to customize how your app responds to deep links—whether by replacing the entire stack, pushing onto the current stack, or executing completely custom logic.

Use this mixin when deep links require multi-step navigation setup, analytics tracking, data preloading, or custom navigation flows that go beyond simple route replacement.

#### API

```dart
mixin RouteDeepLink on RouteUnique {
  // Strategy for handling deep links
  DeeplinkStrategy get deeplinkStrategy;
  
  // Custom deep link handler (only called if strategy is custom)
  FutureOr<void> deeplinkHandler(
    covariant Coordinator coordinator,
    Uri uri,
  );
}

enum DeeplinkStrategy {
  replace,  // Replace entire navigation stack with this route (default)
  push,     // Push this route onto the existing stack
  custom,   // Use deeplinkHandler()
}
```

#### Example: Multi-Step Deep Link Setup

```dart
class ProductDetailRoute extends RouteTarget 
    with RouteUnique, RouteDeepLink {
  final String productId;
  
  ProductDetailRoute(this.productId);
  
  @override
  Uri toUri() => Uri.parse('/product/$productId');
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(
    AppCoordinator coordinator,
    Uri uri,
  ) async {
    // Step 1: Navigate to the correct tab
    coordinator.replace(ShopTab());
    
    // Step 2: Load product data asynchronously
    final product = await productService.loadProduct(productId);
    
    // Step 3: Navigate to category if available
    if (product.category != null) {
      coordinator.push(CategoryRoute(product.category!));
    }
    
    // Step 4: Finally navigate to the product detail
    coordinator.push(this);
    
    // Step 5: Track deep link analytics
    analytics.logDeepLink(uri, {
      'product_id': productId,
      'source': uri.queryParameters['source'],
    });
  }
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $productId')),
      body: ProductDetailView(productId: productId),
    );
  }
}
```

#### Example: Push Strategy

```dart
class ModalRoute extends RouteTarget with RouteUnique, RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
  
  @override
  Uri toUri() => Uri.parse('/modal');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: const Text('Modal from deep link'),
      ),
    );
  }
}

// Example: myapp://modal opens as a modal on top of current navigation
// The existing stack is preserved
```

#### Example: Analytics Tracking

```dart
class CampaignRoute extends RouteTarget with RouteDeepLink {
  final String campaignId;
  
  CampaignRoute(this.campaignId);
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(
    AppCoordinator coordinator,
    Uri uri,
  ) async {
    // Track campaign parameters
    final source = uri.queryParameters['utm_source'];
    final medium = uri.queryParameters['utm_medium'];
    final campaign = uri.queryParameters['utm_campaign'];
    
    analytics.logEvent('campaign_opened', {
      'campaign_id': campaignId,
      'source': source,
      'medium': medium,
      'campaign': campaign,
    });
    
    // Load campaign data
    final data = await campaignService.load(campaignId);
    
    // Navigate to appropriate screen
    if (data.type == 'product') {
      coordinator.replace(ProductRoute(data.productId));
    } else {
      coordinator.replace(CampaignDetailRoute(campaignId));
    }
  }
}
```

---

### RouteTransition

Customizes page transition animations for a route.

**Use when:**
- You want custom page transitions
- Different routes need different transitions
- Platform-specific transitions

#### API

```dart
mixin RouteTransition on RouteUnique {
  StackTransition<T> transition<T extends RouteUnique>(
    covariant Coordinator coordinator,
  );
}
```

#### Example: Custom Transition

```dart
class FadeRoute extends RouteTarget with RouteUnique, RouteTransition {
  @override
  Uri toUri() => Uri.parse('/fade');
  
  @override
  StackTransition<T> transition<T extends RouteUnique>(
    Coordinator coordinator,
  ) {
    return StackTransition.custom(
      builder: (context) => build(coordinator, context),
      pageBuilder: (context, key, child) => PageRouteBuilder(
        settings: RouteSettings(name: key.toString()),
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fade Transition')),
      body: const Center(child: Text('Faded in!')),
    );
  }
}
```

#### Example: Platform-Specific Transitions

```dart
class AdaptiveRoute extends RouteTarget with RouteTransition {
  @override
  StackTransition<T> transition<T extends RouteUnique>(
    Coordinator coordinator,
  ) {
    if (Platform.isIOS) {
      return StackTransition.cupertino(
        build(coordinator, coordinator.navigator.context),
      );
    } else {
      return StackTransition.material(
        build(coordinator, coordinator.navigator.context),
      );
    }
  }
}
```

---


### Full Example
```dart
class ComplexRoute extends AppRoute
    with RouteUnique, RouteGuard, RouteRedirect, RouteDeepLink {
  bool isDirty = false;
  
  @override
  Future<bool> popGuard() async => !isDirty || await confirmExit();
  
  @override
  Future<AppRoute?> redirect() async {
    if (!await auth.check()) return LoginRoute();
    return this;
  }
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri) async {
    analytics.log(uri);
    coordinator.push(this);
  }
  
  @override
  Uri toUri() => Uri.parse('/complex');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return ComplexScreen(onChanged: () => isDirty = true);
  }
}
```

## Best Practices

### ✅ DO: Use Minimal Mixins

Only add mixins you actually need:

```dart
// ✅ GOOD: Only what's needed
class SimpleRoute extends RouteTarget with RouteUnique {
  // Just basic coordinator support
}

// ❌ BAD: Unnecessary mixins
class SimpleRoute extends RouteTarget 
    with RouteUnique, RouteGuard, RouteRedirect {
  @override
  Future<bool> popGuard() => true; // Always true = useless
  
  @override
  Future<AppRoute> redirect() => this; // Always this = useless
}
```

### ✅ DO: Combine Related Mixins

Guards and redirects work well together:

```dart
class SecureFormRoute extends AppRoute 
    with RouteUnique, RouteGuard, RouteRedirect {
  bool hasChanges = false;
  
  // Redirect: Check auth first
  @override
  Future<AppRoute> redirect() async {
    return await auth.check() ? this : LoginRoute();
  }
  
  // Guard: Prevent accidental exit
  @override
  Future<bool> popGuard() async {
    return !hasChanges || await confirmDiscard();
  }
}
```

### ❌ DON'T: Create Deep Inheritance Hierarchies

Use composition, not inheritance:

```dart
// ❌ BAD: Deep hierarchy
abstract class AuthenticatedRoute extends AppRoute with RouteRedirect {...}
abstract class GuardedRoute extends AuthenticatedRoute with RouteGuard {...}
class MyRoute extends GuardedRoute {...}

// ✅ GOOD: Flat composition
class MyRoute extends AppRoute 
    with RouteUnique, RouteRedirect, RouteGuard {
  // All mixins at once, clear and explicit
}
```

### ❌ DON'T: Use RouteLayout Without Coordinator

`RouteLayout` requires `Coordinator`:

```dart
// ❌ BAD: RouteLayout without coordinator
class TabLayout extends RouteTarget with RouteLayout {...}
// Won't work with pure imperative/declarative navigation

// ✅ GOOD: Use RouteUnique with RouteLayout
class TabLayout extends RouteTarget with RouteUnique, RouteLayout {...}
// Works with Coordinator
```

---

### RouteQueryParameters

Efficiently handles query parameters by allowing granular UI rebuilds. This mixin provides a `ValueNotifier` for query parameters, enabling parts of your UI to rebuild when specific queries change without rebuilding the entire route or triggering navigation transitions.

**Required when:**
- You have complex routes with filters, sorting, or pagination
- You want to update the URL without navigation
- You need high performance for frequent parameter updates

#### API

```dart
mixin RouteQueryParameters on RouteUnique {
  // The notifier for query parameters
  ValueNotifier<Map<String, String>> get queryNotifier;

  // Current query parameters
  Map<String, String> get queries;

  // Get a specific query
  String? query(String name);

  // Update queries and sync URL
  void updateQueries(
    covariant Coordinator coordinator, {
    required Map<String, String> queries,
  });

  // Build widgets that rebuild only when specific queries change
  Widget selectorBuilder<T>({
    required T Function(Map<String, String> queries) selector,
    required Widget Function(BuildContext context, T value) builder,
  });
}
```

#### Example: Pagination and Filtering

```dart
class CollectionListRoute extends AppRoute with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  CollectionListRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Only rebuilds when 'filter' changes
          selectorBuilder(
            selector: (q) => q['filter'] ?? 'all',
            builder: (context, filter) => Text('Filter: $filter'),
          ),
          
          // Only rebuilds when 'page' changes
          selectorBuilder(
            selector: (q) => int.tryParse(q['page'] ?? '1') ?? 1,
            builder: (context, page) => Text('Page: $page'),
          ),

          ElevatedButton(
            onPressed: () {
              updateQueries(
                coordinator,
                queries: {...queries, 'page': '2'},
              );
            },
            child: const Text('Go to Page 2'),
          ),
        ],
      ),
    );
  }
}
```

---

## See Also

- [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Using mixins with imperative navigation
- [Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md) - Using mixins with coordinator
- [API Reference](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/core-classes.md) - Detailed API documentation
