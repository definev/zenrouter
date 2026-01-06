# Recipe: Authentication Flow

## Problem

You need to protect certain routes in your app, redirecting unauthenticated users to a login page. After successful login, users should be sent to their originally requested page. This pattern is essential for apps with user accounts, admin panels, or premium content.

## Solution Overview

ZenRouter provides the **RouteRedirect** mixin for implementing authentication guards. This approach:

- Automatically intercepts protected routes
- Redirects unauthenticated users to login
- Preserves the original destination for post-login navigation
- Works seamlessly with deep linking
- Keeps auth logic separate from UI code

## Complete Code Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// 1. Sample authentication service
class AuthService {
  bool _isAuthenticated = false;
  
  bool get isAuthenticated => _isAuthenticated;
  
  Future<bool> login(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'user@example.com' && password == 'password') {
      _isAuthenticated = true;
      return true;
    }
    return false;
  }
  
  void logout() {
    _isAuthenticated = false;
  }
}

// Global auth service (or use dependency injection)
final authService = AuthService();

// 2. Define your base route class
abstract class AppRoute extends RouteTarget with RouteUnique {}

// 3. Create a mixin for protected routes
mixin ProtectedRoute on AppRoute implements RouteRedirect {
  AppRoute get intendedRoute;

  @override
  Future<AppRoute> redirect() async {
    if (!authService.isAuthenticated) {
      // Redirect to login with the intended destination
      return LoginRoute(intendedRoute: intendedRoute);
    }
    return this; // User is authenticated, allow access
  }
}

// 4. Define the login route
class LoginRoute extends AppRoute {
  final AppRoute? intendedRoute;
  
  LoginRoute({this.intendedRoute});
  
  @override
  List<Object?> get props => [intendedRoute];
  
  @override
  Uri toUri() => Uri.parse('/login');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return LoginPage(
      onLoginSuccess: () {
        if (intendedRoute != null) {
          // Navigate to originally intended page
          coordinator.navigate(intendedRoute!);
        } else {
          // No intended route, go to home
          coordinator.navigate(HomeRoute());
        }
      },
    );
  }
}

// 5. Protected routes using the mixin
class ProfileRoute extends AppRoute with ProtectedRoute {
  @override
  Uri toUri() => Uri.parse('/profile');

  @override
  AppRoute get intendedRoute => ProfileRoute();
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const ProfilePage();
  }
}

class SettingsRoute extends AppRoute with ProtectedRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  AppRoute get intendedRoute => SettingsRoute();
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const SettingsPage();
  }
}

class DashboardRoute extends AppRoute with ProtectedRoute {
  @override
  Uri toUri() => Uri.parse('/dashboard');

  @override
  AppRoute get intendedRoute => DashboardRoute();
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const DashboardPage();
  }
}

// Public routes (no mixin needed)
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  AppRoute get intendedRoute => HomeRoute();
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return HomePage(coordinator: coordinator);
  }
}

// 6. Setup the Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['login'] => LoginRoute(),
      ['profile'] => ProfileRoute(),
      ['settings'] => SettingsRoute(),
      ['dashboard'] => DashboardRoute(),
      _ => NotFoundRoute(),
    };
  }
}

// 7. Login page UI
class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  
  const LoginPage({super.key, required this.onLoginSuccess});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final success = await authService.login(
      _emailController.text,
      _passwordController.text,
    );
    
    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or password';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Demo: user@example.com / password',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Example: Home page with login/logout
class HomePage extends StatelessWidget {
  final AppCoordinator coordinator;
  
  const HomePage({super.key, required this.coordinator});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (authService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authService.logout();
                coordinator.replace(HomeRoute()); // Refresh to update UI
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              authService.isAuthenticated
                  ? 'You are logged in!'
                  : 'You are not logged in',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            if (!authService.isAuthenticated) ...[
              ElevatedButton(
                onPressed: () => coordinator.push(LoginRoute()),
                child: const Text('Login'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => coordinator.push(ProfileRoute()),
                child: const Text('Go to Profile (Protected)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => coordinator.push(DashboardRoute()),
                child: const Text('Go to Dashboard (Protected)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Step-by-Step Explanation

### 1. Create a Reusable Protection Mixin

```dart
mixin ProtectedRoute on AppRoute implements RouteRedirect {
  AppRoute get intendedRoute;

  @override
  Future<AppRoute> redirect() async {
    if (!authService.isAuthenticated) {
      return LoginRoute(intendedRoute: intendedRoute);
    }
    return this;
  }
}
```

- The `ProtectedRoute` mixin implements `RouteRedirect`
- `redirect()` checks authentication status
- If not authenticated, returns `LoginRoute` with the intended route stored
- If authenticated, returns `this` (allowing access)

### 2. Preserve Intended Destination

```dart
class LoginRoute extends AppRoute {
  final AppRoute? intendedRoute;
  
  LoginRoute({this.intendedRoute});
  
  // After successful login:
  onLoginSuccess: () {
    if (intendedRoute != null) {
      coordinator.replace(intendedRoute!);
    } else {
      coordinator.replace(HomeRoute());
    }
  }
}
```

- Store the intended route in `LoginRoute`
- After successful authentication, navigate to the intended route
- Falls back to home if no intended route exists

### 3. Apply Protection to Routes

```dart
class ProfileRoute extends AppRoute with ProtectedRoute {
  @override
  AppRoute get intendedRoute => ProfileRoute();

  // ... route implementation
}
```

Simply add `with ProtectedRoute` to any route that requires authentication.

## Advanced Variations

### Role-Based Access Control

```dart
enum UserRole { user, admin, moderator }

class AuthService {
  UserRole? _currentRole;
  
  bool get isAuthenticated => _currentRole != null;
  UserRole? get currentRole => _currentRole;
  
  bool hasRole(UserRole role) => _currentRole == role;
  bool hasAnyRole(List<UserRole> roles) => 
      _currentRole != null && roles.contains(_currentRole);
}

// Role-specific protection
mixin AdminRoute on AppRoute implements RouteRedirect {
  @override
  AppRoute get intendedRoute;

  @override
  Future<AppRoute> redirect() async {
    if (!authService.isAuthenticated) {
      return LoginRoute(intendedRoute: intendedRoute);
    }
    
    if (!authService.hasRole(UserRole.admin)) {
      return UnauthorizedRoute(); // Or redirect to home
    }
    
    return this;
  }
}

// Usage
class AdminPanelRoute extends AppRoute with AdminRoute {
  @override
  AppRoute get intendedRoute => AdminPanelRoute();

  @override
  Uri toUri() => Uri.parse('/admin');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const AdminPanelPage();
  }
}
```

### Token-Based Authentication

```dart
class AuthService {
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  bool get isAuthenticated {
    if (_accessToken == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }
  
  Future<bool> refreshToken() async {
    // Call refresh endpoint
    try {
      final response = await api.refreshToken();
      _accessToken = response.accessToken;
      _tokenExpiry = DateTime.now().add(Duration(hours: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}

mixin ProtectedRoute on AppRoute implements RouteRedirect {
  @override
  AppRoute get intendedRoute;

  @override
  Future<AppRoute> redirect() async {
    if (!authService.isAuthenticated) {
      // Try to refresh token first
      final refreshed = await authService.refreshToken();
      if (!refreshed) {
        return LoginRoute(intendedRoute: intendedRoute);
      }
    }
    return this;
  }
}
```

### Deep Link Preservation with Query Parameters

```dart
class LoginRoute extends AppRoute {
  final Uri? intendedUri;
  
  LoginRoute({AppRoute? intendedRoute, this.intendedUri})
      : _intendedRoute = intendedRoute;
  
  final AppRoute? _intendedRoute;
  
  @override
  List<Object?> get props => [_intendedRoute, intendedUri];
  
  @override
  Uri toUri() {
    if (intendedUri != null) {
      return Uri.parse('/login').replace(
        queryParameters: {'redirect': intendedUri?.toUri()?.toString()},
      );
    }
    return Uri.parse('/login');
  }
  
  // After login:
  onLoginSuccess: () {
    if (intendedUri != null) {
      coordinator.navigate(coordinator.parseRouteFromUri(intendedUri!));
    } else if (_intendedRoute != null) {
      coordinator.replace(_intendedRoute!);
    } else {
      coordinator.replace(HomeRoute());
    }
  }
}
```

## Common Gotchas

> [!CAUTION]
> **Remember to implement equals/hashCode**
> If your `LoginRoute` stores an `intendedRoute`, make sure to include it in `props` for proper route comparison.

> [!WARNING]
> **Avoid infinite redirect loops**
> Never add `RouteRedirect` to your `LoginRoute` itself, or it may create a redirect loop.

> [!TIP]
> **Test with deep links**
> Try opening protected deep links when logged out (e.g., `myapp://profile`). Users should land on login, then automatically navigate to the profile after authenticating.

> [!NOTE]
> **State management integration**
> This recipe uses a simple `AuthService` singleton. In production, consider integrating with your state management solution (Riverpod, Bloc, Provider) for reactive auth state.

## Related Recipes

- [404 Handling](404-handling.md) - Handle unauthorized vs not found
- [State Management Integration](state-management.md) - Integrate with Riverpod/Bloc
- [Nested Navigation](nested-navigation.md) - Protected sections in nested nav

## See Also

- [RouteRedirect Mixin](../api/mixins.md#routeredirect)
- [RouteGuard Mixin](../api/mixins.md#routeguard) - Alternative for preventing navigation
- [Coordinator Pattern Guide](../paradigms/coordinator/coordinator.md)
