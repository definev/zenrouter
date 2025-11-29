import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

/// =============================================================================
/// COMPREHENSIVE ZENROUTER EXAMPLE
/// =============================================================================
/// This example demonstrates EVERY capability of ZenRouter:
///
/// ✅ Sealed classes with exhaustive pattern matching
/// ✅ Imperative navigation (push, pop, replace)
/// ✅ Declarative navigation with Coordinator
/// ✅ RouteBuilder for inline UI definition
/// ✅ RouteGuard for unsaved changes protection
/// ✅ RouteRedirect for auth/conditional navigation
/// ✅ RouteShell + RouteShellHost for nested navigation (tabs)
/// ✅ RouteDeepLink for custom deep linking logic
/// ✅ Routes with parameters and proper equality
/// ✅ Deep linking with URI parsing
/// ✅ Custom page transitions (Material, Cupertino, Sheet, Dialog)
/// ✅ Redirect chains
/// ✅ Multiple NavigationPaths
/// ✅ DeeplinkStrategy (push vs replace)
/// =============================================================================

void main() {
  runApp(const ComprehensiveApp());
}

// =============================================================================
// COORDINATOR - Manages all navigation state
// =============================================================================

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug<AppRoute> {
  // Primary navigation path (for main screens)
  // root is inherited from Coordinator

  // Shell navigation path (for tab navigation)
  final NavigationPath<HomeTabShell> homeTabs = NavigationPath();

  // Modal navigation path (for overlays)
  final NavigationPath<ModalRoute> modals = NavigationPath();

  @override
  late final List<NavigationPath> paths = List.unmodifiable([
    root,
    homeTabs,
    modals,
  ]);

  @override
  String debugLabel(NavigationPath path) {
    if (path == root) return 'Root';
    if (path == homeTabs) return 'Home Tabs';
    if (path == modals) return 'Modals';
    return super.debugLabel(path);
  }

  @override
  List<AppRoute> get debugRoutes => [
    DashboardTab(),
    ProfileTab(),
    SettingsTab(),
    CreateProductRoute(),
    LoginRoute(),
    RegisterRoute(),
    AdminRoute(),
    ProtectedSettingsRoute(),
    AdminEditRoute(),
    SheetDemoRoute(),
    DialogDemoRoute(),
    CupertinoDemoRoute(),
    RedirectChainStartRoute(),
  ];

  // Auth state (simulated)
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  void login() => _isAuthenticated = true;
  void logout() {
    _isAuthenticated = false;
    replace(LoginRoute());
  }

  // Deep linking - Parse URIs into routes
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // Extract query parameters for demonstration
    final queryParams = uri.queryParameters;

    return switch (uri.pathSegments) {
      // Home tabs
      [] => DashboardTab(),
      ['dashboard'] => DashboardTab(),
      ['profile'] => ProfileTab(),
      ['settings'] => SettingsTab(),

      // Product routes with parameters
      ['product', final id] => ProductDetailRoute(
        productId: id,
        highlight: queryParams['highlight'],
      ),

      // User routes
      ['user', final userId] => UserProfileRoute(userId: userId),
      ['user', final userId, 'edit'] => EditUserRoute(userId: userId),

      // Form with guard
      ['create-product'] => CreateProductRoute(),

      // Auth
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(),

      // Protected routes
      ['admin'] => AdminRoute(),
      ['protected-settings'] => ProtectedSettingsRoute(),
      ['admin-edit'] => AdminEditRoute(),

      // Different page transitions
      ['sheet-demo'] => SheetDemoRoute(),
      ['dialog-demo'] => DialogDemoRoute(),
      ['cupertino-demo'] => CupertinoDemoRoute(),

      // Redirect demo
      ['redirect-chain'] => RedirectChainStartRoute(),

      // 404
      _ => NotFoundRoute(path: uri.path),
    };
  }
}

final coordinator = AppCoordinator();

// =============================================================================
// SEALED CLASS HIERARCHY - Enables exhaustive pattern matching
// =============================================================================

/// Base route class - SEALED for compile-time exhaustiveness checking!
sealed class AppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.root;
}

// =============================================================================
// AUTHENTICATION ROUTES - Demonstrating RouteRedirect
// =============================================================================

/// Login route - Entry point for unauthenticated users
class LoginRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                coordinator.login();
                coordinator.replace(DashboardTab());
              },
              child: const Text('Login (Simulate)'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => coordinator.push(RegisterRoute()),
              child: const Text('Go to Register'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Register route
class RegisterRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/register');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(
        child: Text('Register Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// =============================================================================
// REUSABLE AUTH REDIRECT MIXIN - Best Practice Pattern! 🎯
// =============================================================================

/// Reusable mixin that adds authentication redirect to any route.
///
/// This demonstrates how to create reusable navigation logic that can be
/// applied to multiple routes without duplicating code.
///
/// Usage:
/// ```dart
/// class MyProtectedRoute extends AppRoute with RequiresAuth, RouteBuilder {
///   @override
///   Widget build(coordinator, context) => Scaffold(...);
/// }
/// ```
mixin RequiresAuth on AppRoute implements RouteRedirect<AppRoute> {
  @override
  FutureOr<AppRoute> redirect() async {
    // Simulate async auth check
    await Future.delayed(const Duration(milliseconds: 100));

    // Redirect to login if not authenticated
    if (!coordinator.isAuthenticated) {
      return LoginRoute();
    }

    // Return self if authenticated
    return this;
  }
}

// =============================================================================
// PROTECTED ROUTES - Demonstrating RequiresAuth mixin usage
// =============================================================================

/// Protected admin route - Uses RequiresAuth mixin
class AdminRoute extends AppRoute with RequiresAuth, RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/admin');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔒 Protected Admin Area',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text('This route uses the RequiresAuth mixin'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => coordinator.logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Another reusable mixin - Requires admin role
/// This can be COMBINED with RequiresAuth for double protection!
mixin RequiresAdmin on AppRoute implements RouteRedirect<AppRoute> {
  @override
  FutureOr<AppRoute> redirect() async {
    // Check if user is logged in AND has admin role
    if (!coordinator.isAuthenticated) {
      return LoginRoute();
    }

    // Simulate admin role check
    // In a real app, check user.role == 'admin'
    final isAdmin = coordinator.isAuthenticated; // Simplified for demo

    if (!isAdmin) {
      // Redirect to a "not authorized" page or back to dashboard
      return DashboardTab();
    }

    return this;
  }
}

/// Protected settings route - Also uses RequiresAuth
class ProtectedSettingsRoute extends AppRoute with RequiresAuth, RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/protected-settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              '🔒 Another Protected Route',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('This also uses RequiresAuth mixin'),
            const SizedBox(height: 20),
            const Text(
              'Try accessing this while logged out - you\'ll be redirected!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMBINING MULTIPLE MIXINS - Advanced Pattern! 🚀
// =============================================================================

/// This route demonstrates combining MULTIPLE mixins:
/// 1. RequiresAuth - Authentication check
/// 2. RequiresAdmin - Role-based permission check
/// 3. RouteGuard - Prevents navigation with unsaved changes
/// 4. RouteBuilder - Builds the UI
///
/// Order matters! Mixins are applied right-to-left:
/// - RouteBuilder provides build()
/// - RouteGuard provides popGuard()
/// - RequiresAdmin provides redirect() (overrides RequiresAuth's redirect)
/// - RequiresAuth is still in the chain but RequiresAdmin takes precedence
class AdminEditRoute extends AppRoute
    with RequiresAdmin, RouteGuard, RouteBuilder {
  bool _hasChanges = false;

  @override
  Uri toUri() => Uri.parse('/admin-edit');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Edit'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '🚀 Multiple Mixins Combined!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('This route uses:'),
                  const Text('✅ RequiresAdmin - Role check'),
                  const Text('✅ RouteGuard - Unsaved changes protection'),
                  const Text('✅ RouteBuilder - UI rendering'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Admin Configuration Editor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Try to navigate away after making changes!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'System Config Key',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _hasChanges = value.isNotEmpty,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Config Value',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _hasChanges = value.isNotEmpty,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _hasChanges = false;
                coordinator.pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RouteGuard implementation - prevents navigation with unsaved changes
  @override
  FutureOr<bool> popGuard() async {
    if (!_hasChanges) return true;

    final context = coordinator.routerDelegate.navigatorKey.currentContext!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('⚠️ Unsaved Changes'),
          ],
        ),
        content: const Text(
          'You have unsaved admin configuration changes. Discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// =============================================================================
// SHELL NAVIGATION - Demonstrating RouteShell + RouteShellHost
// =============================================================================

/// Sealed base class for all home tabs - MUST define a host!
sealed class HomeTabShell extends AppRoute with RouteShell<HomeTabShell> {
  // Static host instance - required for shell navigation
  static final host = _$HomeTabShellHost();

  @override
  HomeTabShell get shellHost => host;

  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.homeTabs;
}

/// The host provides the container UI (bottom navigation bar)
class _$HomeTabShellHost extends HomeTabShell
    with RouteShellHost<HomeTabShell>, RouteBuilder {
  @override
  NavigationPath<HomeTabShell> getPath(AppCoordinator coordinator) =>
      coordinator.homeTabs;

  @override
  NavigationPath<AppRoute> getHostPath(AppCoordinator coordinator) =>
      coordinator.root;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final shellPath = getPath(coordinator);

    return ListenableBuilder(
      listenable: shellPath,
      builder: (context, _) {
        // Exhaustive pattern matching on sealed class!
        final currentIndex = switch (shellPath.stack.lastOrNull) {
          DashboardTab() => 0,
          ProfileTab() => 1,
          SettingsTab() => 2,
          _ => 0,
        };

        return Scaffold(
          body: NavigationStack(
            path: shellPath,
            resolver: (route) =>
                Coordinator.defaultResolver(coordinator, route),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => switch (index) {
              0 => coordinator.replace(DashboardTab()),
              1 => coordinator.replace(ProfileTab()),
              2 => coordinator.replace(SettingsTab()),
              _ => null,
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// TAB ROUTES - Children of the shell
// =============================================================================

class DashboardTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/dashboard');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '🎉 Welcome to ZenRouter!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            'Route with Parameters',
            'Demonstrates routes with data fields',
            () => coordinator.push(ProductDetailRoute(productId: '123')),
          ),
          _buildFeatureCard(
            'Route with Query Params',
            'Deep linking with query parameters',
            () => coordinator.push(
              ProductDetailRoute(productId: '456', highlight: 'reviews'),
            ),
          ),
          _buildFeatureCard(
            'Route Guard (Form)',
            'Prevents navigation with unsaved changes',
            () => coordinator.push(CreateProductRoute()),
          ),
          _buildFeatureCard(
            'Protected Route (Admin)',
            'Auth redirect with RequiresAuth mixin',
            () => coordinator.push(AdminRoute()),
          ),
          _buildFeatureCard(
            'Protected Settings',
            'Another route using RequiresAuth mixin',
            () => coordinator.push(ProtectedSettingsRoute()),
          ),
          _buildFeatureCard(
            'Admin Edit (Multiple Mixins) 🚀',
            'Combines RequiresAdmin + RouteGuard + RouteBuilder',
            () => coordinator.push(AdminEditRoute()),
          ),
          _buildFeatureCard(
            'Sheet Presentation',
            'Bottom sheet page transition',
            () => coordinator.push(SheetDemoRoute()),
          ),
          _buildFeatureCard(
            'Dialog Presentation',
            'Dialog page transition',
            () => coordinator.push(DialogDemoRoute()),
          ),
          _buildFeatureCard(
            'Cupertino Transition',
            'iOS-style page transition',
            () => coordinator.push(CupertinoDemoRoute()),
          ),
          _buildFeatureCard(
            'Redirect Chain',
            'Multiple redirects in sequence',
            () => coordinator.push(RedirectChainStartRoute()),
          ),
          _buildFeatureCard(
            'Deep Link (Push Strategy)',
            'Custom deep link handling',
            () => coordinator.push(UserProfileRoute(userId: 'deep-link-demo')),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class ProfileTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/profile');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            const Text('John Doe', style: TextStyle(fontSize: 24)),
            const Text('john@example.com'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => coordinator.logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(value: false, onChanged: (_) {}),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ROUTES WITH PARAMETERS - Demonstrating proper equality implementation
// =============================================================================

class ProductDetailRoute extends AppRoute with RouteBuilder, RouteDeepLink {
  ProductDetailRoute({required this.productId, this.highlight});

  final String productId;
  final String? highlight;

  @override
  Uri toUri() {
    final uri = Uri.parse('/product/$productId');
    if (highlight != null) {
      return uri.replace(queryParameters: {'highlight': highlight});
    }
    return uri;
  }

  // CRITICAL: Override equality for routes with parameters!
  @override
  bool operator ==(Object other) {
    if (!equals(other)) return false;
    return other is ProductDetailRoute &&
        other.productId == productId &&
        other.highlight == highlight;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, productId, highlight);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $productId')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Product $productId',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This is a detailed product description. The route includes the product ID as a parameter.',
              style: TextStyle(fontSize: 16),
            ),
            if (highlight != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✨ Highlighting: $highlight (from query parameter)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('Great product!'),
              subtitle: Text('5/5 stars'),
            ),
            const ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('Highly recommended'),
              subtitle: Text('5/5 stars'),
            ),
          ],
        ),
      ),
    );
  }

  // Custom deep link handling - ensures we have proper navigation stack
  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) {
    // First ensure we're on the dashboard
    coordinator.replace(DashboardTab());
    // Then push this product detail
    coordinator.push(this);
  }
}

class UserProfileRoute extends AppRoute with RouteBuilder, RouteDeepLink {
  UserProfileRoute({required this.userId});

  final String userId;

  @override
  Uri toUri() => Uri.parse('/user/$userId');

  @override
  bool operator ==(Object other) {
    if (!equals(other)) return false;
    return other is UserProfileRoute && other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, userId);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User $userId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(
                userId[0].toUpperCase(),
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 20),
            Text('User ID: $userId', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => coordinator.push(EditUserRoute(userId: userId)),
              icon: const Icon(Icons.edit),
              label: const Text('Edit User'),
            ),
          ],
        ),
      ),
    );
  }

  // Demonstrate push strategy for deep links (instead of default replace)
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;

  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) {
    coordinator.replace(DashboardTab());
    coordinator.push(this);
  }
}

// =============================================================================
// ROUTE GUARD - Demonstrating form protection
// =============================================================================

class CreateProductRoute extends AppRoute with RouteBuilder, RouteGuard {
  bool _hasUnsavedChanges = false;

  @override
  Uri toUri() => Uri.parse('/create-product');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🛡️ This form is protected by RouteGuard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Try to navigate away after typing - you\'ll get a confirmation dialog!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _hasUnsavedChanges = value.isNotEmpty;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) {
                _hasUnsavedChanges = value.isNotEmpty;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _hasUnsavedChanges = false;
                coordinator.pop();
              },
              child: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  FutureOr<bool> popGuard() async {
    if (!_hasUnsavedChanges) return true;

    final context = coordinator.routerDelegate.navigatorKey.currentContext!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class EditUserRoute extends AppRoute with RouteBuilder, RouteGuard {
  EditUserRoute({required this.userId});

  final String userId;
  bool _hasChanges = false;

  @override
  Uri toUri() => Uri.parse('/user/$userId/edit');

  @override
  bool operator ==(Object other) {
    if (!equals(other)) return false;
    return other is EditUserRoute && other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, userId);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _hasChanges = true,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _hasChanges = true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _hasChanges = false;
                coordinator.pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  FutureOr<bool> popGuard() async {
    if (!_hasChanges) return true;
    final context = coordinator.routerDelegate.navigatorKey.currentContext!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard changes?'),
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
}

// =============================================================================
// CUSTOM PAGE TRANSITIONS
// =============================================================================

class SheetDemoRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/sheet-demo');

  @override
  RouteDestination<T> destination<T extends RouteUnique>(
    AppCoordinator coordinator,
  ) {
    return RouteDestination.sheet(
      build(
        coordinator,
        coordinator.routerDelegate.navigatorKey.currentContext!,
      ),
    );
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.layers, size: 64, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            '📱 Bottom Sheet Presentation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'This route uses RouteDestination.sheet()',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => coordinator.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class DialogDemoRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/dialog-demo');

  @override
  RouteDestination<T> destination<T extends RouteUnique>(
    AppCoordinator coordinator,
  ) {
    return RouteDestination.dialog(
      build(
        coordinator,
        coordinator.routerDelegate.navigatorKey.currentContext!,
      ),
    );
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 10),
          Text('Dialog Presentation'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💬 This route uses RouteDestination.dialog()'),
          SizedBox(height: 10),
          Text('Perfect for confirmations, alerts, or modal interactions.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => coordinator.pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }
}

class CupertinoDemoRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/cupertino-demo');

  @override
  RouteDestination<T> destination<T extends RouteUnique>(
    AppCoordinator coordinator,
  ) {
    return RouteDestination.cupertino(
      build(
        coordinator,
        coordinator.routerDelegate.navigatorKey.currentContext!,
      ),
    );
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('iOS Style'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => coordinator.pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.device_phone_portrait, size: 64),
            const SizedBox(height: 20),
            const Text(
              '🍎 Cupertino Transition',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('This route uses RouteDestination.cupertino()'),
            const SizedBox(height: 10),
            const Text('Notice the iOS-style slide transition!'),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: () => coordinator.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// REDIRECT CHAINS - Demonstrating multiple redirects
// =============================================================================

class RedirectChainStartRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/redirect-chain');

  @override
  FutureOr<AppRoute> redirect() {
    // Redirect to the middle route
    return RedirectChainMiddleRoute();
  }
}

class RedirectChainMiddleRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  FutureOr<AppRoute> redirect() async {
    // Simulate async processing
    await Future.delayed(const Duration(milliseconds: 200));
    // Redirect to the final route
    return RedirectChainEndRoute();
  }
}

class RedirectChainEndRoute extends AppRoute with RouteBuilder {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redirect Chain End')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              '🔗 Redirect Chain Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This route was reached through multiple redirects:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Start → Middle → End',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Each redirect can be async and conditional!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MODAL ROUTES - Demonstrating separate navigation path
// =============================================================================

sealed class ModalRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.modals;
}

// =============================================================================
// UTILITY ROUTES
// =============================================================================

class NotFoundRoute extends AppRoute with RouteBuilder {
  NotFoundRoute({required this.path});

  final String path;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404 Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Path: $path'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => coordinator.replace(DashboardTab()),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// APP ENTRY POINT
// =============================================================================

class ComprehensiveApp extends StatelessWidget {
  const ComprehensiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Comprehensive Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerDelegate: CoordinatorRouterDelegate(coordinator: coordinator),
      routeInformationParser: CoordinatorRouteParser(coordinator: coordinator),
    );
  }
}
