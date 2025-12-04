# Route Mixin System

> **Compose route behavior with mixins**

ZenRouter uses a mixin-based architecture that lets you add specific behaviors to your routes. Instead of a deep inheritance hierarchy, you compose functionality by mixing in exactly what you need.

## Overview

```dart
class MyRoute extends RouteTarget    // Base class (required)
    with RouteUnique                 // For coordinator (optional)
    with RouteGuard                  // Prevent navigation (optional)
    with RouteRedirect               // Conditional routing (optional)
    with RouteDeepLink {             // Custom deep link handling (optional)
  // Your route implementation
}
```

Each mixin adds specific capabilities:
- **RouteUnique** - Makes route work with Coordinator
- **RouteLayout** - Creates navigation host for nested routes
- **RouteTransition** - Custom page transitions
- **RouteGuard** - Prevents unwanted navigation
- **RouteRedirect** - Redirects to different routes
- **RouteDeepLink** - Custom deep link handling

### Decision Tree

```
Which mixins do I need?
│
├─ Using Coordinator?
│  ├─ Yes → Add RouteUnique ✓
│  └─ No → Just extend RouteTarget
│
├─ Creating a navigation host (tabs, navigation-stack)?
│  ├─ Yes → Add RouteLayout ✓
│  └─ No → Continue
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
│  ├─ Yes → Add RouteRedirect ✓
│  └─ No → Continue
│
└─ Custom deep link handling?
   ├─ Yes → Add RouteDeepLink ✓
   └─ No → Done!
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

`RouteLayout` acts as a host for `StackPath` instances. Each type of stack path requires its own corresponding layout widget. ZenRouter provides two built-in path types: `NavigationPath` (for stack-based push/pop navigation) uses `NavigationStack` as its layout, while `IndexedStackPath` (for tab bars and indexed navigation) uses `IndexedStack` as its layout.

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
      body: RouteLayout.layoutBuilderTable[RouteLayout.indexedStackPath]!(
        coordinator,
        path,
        this,
      ),
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
      body: RouteLayout.layoutBuilderTable[RouteLayout.navigationPath]!(
        coordinator,
        coordinator.settingsStack,
        this,
      ),
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
      body: RouteLayout.layoutBuilderTable[RouteLayout.navigationPath]!(
        coordinator,
        coordinator.mainStack,
        this,
      ),
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
      body: RouteLayout.layoutBuilderTable[RouteLayout.indexedStackPath]!(
        coordinator,
        coordinator.tabPath,
        this,
      ),
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
    return RouteLayout.layoutBuilderTable[RouteLayout.navigationPath]!(
      coordinator,
      coordinator.feedStack,
      this,
    );
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
class TabHost extends RouteTarget with RouteLayout {...}
// Won't work with pure imperative/declarative navigation

// ✅ GOOD: Use RouteUnique with RouteLayout
class TabHost extends RouteTarget with RouteUnique, RouteLayout {...}
// Works with Coordinator
```

## See Also

- [Imperative Navigation](../paradigms/imperative.md) - Using mixins with imperative navigation
- [Coordinator Pattern](../paradigms/coordinator.md) - Using mixins with coordinator
- [API Reference](../api/core-classes.md) - Detailed API documentation
