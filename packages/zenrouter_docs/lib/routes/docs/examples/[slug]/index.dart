/// # Example Viewer
///
/// A dynamic route that displays live examples based on the slug parameter.
/// This demonstrates dynamic routing with [slug] in the file name.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_docs/widgets/mardown_section.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'index.g.dart';

/// The example viewer route at /examples/:slug
///
/// This file demonstrates the [slug] dynamic parameter pattern.
/// The slug is captured from the URL and passed to the route.
@ZenRoute()
class ExamplesSlugRoute extends _$ExamplesSlugRoute with RouteSeo, RouteToc {
  ExamplesSlugRoute({required super.slug});

  @override
  String get title {
    final example = examples[slug];
    return example?.title ?? 'Example Not Found';
  }

  @override
  String get description {
    final example = examples[slug];
    return example?.subtitle ?? 'The requested example does not exist';
  }

  @override
  String get keywords {
    final example = examples[slug];
    return example != null
        ? 'Example, ${example.title}, Code Sample, Flutter'
        : 'Example, Not Found';
  }

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    final example = examples[slug];
    if (example == null) {
      return _buildNotFound(context, coordinator, tocController);
    }

    return DocPage(
      title: example.title,
      subtitle: example.subtitle,
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown:
          '''
${example.description}

## Implementation

```dart
${example.code}
```

${example.notes != null ? '## Notes\n\n${example.notes}' : ''}
''',
    );
  }

  Widget _buildNotFound(
    BuildContext context,
    DocsCoordinator coordinator,
    TocController? tocController,
  ) {
    return DocPage(
      title: 'Example Not Found',
      subtitle: 'The requested example does not exist',
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown:
          '''
The example "$slug" does not exist.

Available examples:
- [Basic Navigation](examples/basic-navigation) - Push, Pop, and Replace
- [Tab Bar Navigation](examples/tab-bar) - IndexedStackPath with Multiple Tabs
- [Deep Linking](examples/deep-linking) - Custom Navigation Stack Setup
- [Authentication Flow](examples/auth-flow) - Guards and Redirects
''',
    );
  }
}

/// Example data model
class _Example {
  const _Example({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.codeTitle,
    required this.code,
    this.notes,
  });

  final String title;
  final String subtitle;
  final String description;
  final String codeTitle;
  final String code;
  final String? notes;
}

/// Available examples, indexed by slug
const examples = <String, _Example>{
  'basic-navigation': _Example(
    title: 'Basic Navigation',
    subtitle: 'Push, Pop, and Replace',
    description: '''
This example demonstrates the fundamental navigation operations: pushing a new route onto the stack, popping back, and replacing the current route.

These operations form the foundation of all navigation in ZenRouter, whether using the imperative, declarative, or coordinator paradigm.
''',
    codeTitle: 'Basic Navigation Example',
    code: '''
// Define your routes
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              // Push adds a route to the stack
              onPressed: () => coordinator.push(ProfileRoute()),
              child: const Text('Go to Profile'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              // Replace clears the stack
              onPressed: () => coordinator.replace(SettingsRoute()),
              child: const Text('Replace with Settings'),
            ),
          ],
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
      body: Center(
        child: ElevatedButton(
          // Pop removes the top route
          onPressed: () => coordinator.pop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}''',
    notes: '''
Key points:
- `push` adds to the stack - user can go back
- `pop` removes from the stack - returns to previous route
- `replace` clears everything - no back navigation
- The URL bar (on web) updates automatically with each navigation
''',
  ),

  'tab-bar': _Example(
    title: 'Tab Bar Navigation',
    subtitle: 'IndexedStackPath with Multiple Tabs',
    description: '''
Tab bars require a different navigation model: you're not pushing and popping, you're switching between a fixed set of destinations. Each tab maintains its own navigation state.

This example shows how to implement a bottom tab bar using IndexedStackPath and RouteLayout.
''',
    codeTitle: 'Tab Bar Implementation',
    code: '''
// In your Coordinator, define the tab path:
class AppCoordinator extends Coordinator<AppRoute> {
  late final tabsPath = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'tabs',
    [HomeTabLayout(), SearchTabLayout(), ProfileTabLayout()],
  );

  @override
  List<StackPath> get paths => [...super.paths, tabsPath];
}

// The tabs layout wraps all tab content
class TabsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) {
    return coordinator.tabsPath;
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return Scaffold(
      body: buildPath(coordinator),  // Renders active tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: path.activePathIndex,
        onTap: (index) => coordinator.push(path.stack[index]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}''',
    notes: '''
Key points:
- IndexedStackPath holds a fixed set of tab routes
- Each tab can have its own NavigationPath for internal push/pop
- Tab state is preserved when switching - users return where they left off
- Deep links work: /profile opens directly to the profile tab
''',
  ),

  'deep-linking': _Example(
    title: 'Deep Linking',
    subtitle: 'Custom Navigation Stack Setup',
    description: '''
When your app is opened from a URL, you need to set up an appropriate navigation stack. The user should be able to tap "back" and reach sensible screens.

This example shows how to implement custom deep link handling for complex flows.
''',
    codeTitle: 'Custom Deep Link Handler',
    code: '''
class ProductRoute extends AppRoute with RouteDeepLink {
  ProductRoute({required this.productId});

  final String productId;

  @override
  Uri toUri() => Uri.parse('/product/\$productId');

  // Use custom handling instead of simple replace
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Future<void> deeplinkHandler(
    AppCoordinator coordinator,
    Uri uri,
  ) async {
    // Build a sensible navigation stack

    // 1. Start at home
    coordinator.replace(HomeRoute());

    // 2. Go to shop tab
    coordinator.push(ShopTabLayout());

    // 3. Show product category
    final category = await loadProductCategory(productId);
    coordinator.push(CategoryRoute(category: category));

    // 4. Finally, show this product
    coordinator.push(this);

    // Now "back" goes: Product → Category → Shop → Home
    // Much better than orphaned product page!
  }
}''',
    notes: '''
Key points:
- DeeplinkStrategy.custom gives full control over navigation setup
- Build a stack that makes "back" navigation sensible
- You can async load data before completing navigation
- Consider auth state - redirect to login if needed
''',
  ),

  'auth-flow': _Example(
    title: 'Authentication Flow',
    subtitle: 'Guards and Redirects',
    description: '''
Many apps have protected routes that require authentication. ZenRouter's RouteRedirect mixin lets you check auth state before showing a route, redirecting to login if needed.

This example demonstrates a complete authentication flow.
''',
    codeTitle: 'Protected Route with Auth Redirect',
    code: '''
// A mixin for routes that require authentication
mixin AuthRequired<T extends RouteTarget> on RouteRedirect<T> {
  @override
  FutureOr<T?> redirect() async {
    final isLoggedIn = await authService.isAuthenticated();

    if (!isLoggedIn) {
      // Redirect to login, saving intended destination
      return LoginRoute(redirectTo: toUri().toString()) as T;
    }

    return null;  // Proceed to this route
  }
}

// Apply to protected routes
class DashboardRoute extends AppRoute
    with RouteRedirect<AppRoute>, AuthRequired<AppRoute> {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return DashboardScreen();
  }
}

// Login handles the redirect back
class LoginRoute extends AppRoute {
  LoginRoute({this.redirectTo});

  final String? redirectTo;

  void onLoginSuccess(AppCoordinator coordinator) {
    if (redirectTo != null) {
      // Return to intended destination
      coordinator.recoverRouteFromUri(Uri.parse(redirectTo!));
    } else {
      // Default to home
      coordinator.replace(HomeRoute());
    }
  }
}''',
    notes: '''
Key points:
- RouteRedirect runs before the route is shown
- Return null to proceed, or another route to redirect
- Store the intended destination to return after login
- Consider using a mixin for reusable auth checks
''',
  ),
};
