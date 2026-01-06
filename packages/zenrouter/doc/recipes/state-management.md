# Recipe: State Management Integration

## Problem

You need to integrate your routing with state management solutions like Riverpod, Bloc, or Provider. Common scenarios include:
- Navigate based on authentication state changes
- Deep link to a page and load its data
- Sync routing state with global app state
- Trigger navigation from business logic layer

## Solution Overview

ZenRouter works seamlessly with any state management solution. Routes are just Dart classes, so they can respond to state changes through:

- `RouteRedirect` for state-based redirects
- Listening to state providers in route widgets
- Coordinator integration with state notifiers
- Deep link handlers that fetch data before navigation

## Riverpod Integration

### Authentication with Riverpod

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenrouter/zenrouter.dart';

// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  
  const AuthState({this.isAuthenticated = false, this.userId});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());
  
  Future<void> login(String email, String password) async {
    // Simulate auth
    await Future.delayed(const Duration(seconds: 1));
    state = const AuthState(isAuthenticated: true, userId: 'user-123');
  }
  
  void logout() {
    state = const AuthState();
  }
}

// Routes
abstract class AppRoute extends RouteTarget with RouteUnique {}

// Protected route using Riverpod
class ProfileRoute extends AppRoute with RouteRedirect {
  final ProviderContainer container;
  
  ProfileRoute(this.container);
  
  @override
  List<Object?> get props => [];
  
  @override
  Future<AppRoute> redirect() async {
    final authState = container.read(authProvider);
    
    if (!authState.isAuthenticated) {
      return LoginRoute(container, intendedRoute: this);
    }
    
    return this;
  }
  
  @override
  Uri toUri() => Uri.parse('/profile');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const ProfilePage();
  }
}

class LoginRoute extends AppRoute {
  final ProviderContainer container;
  final AppRoute? intendedRoute;
  
  LoginRoute(this.container, {this.intendedRoute});
  
  @override
  List<Object?> get props => [intendedRoute];
  
  @override
  Uri toUri() => Uri.parse('/login');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return LoginPage(
      onLoginSuccess: () async {
        if (intendedRoute != null) {
          coordinator.replace(intendedRoute!);
        } else {
          coordinator.replace(HomeRoute(container));
        }
      },
    );
  }
}

class HomeRoute extends AppRoute {
  final ProviderContainer container;
  
  HomeRoute(this.container);
  
  @override
  List<Object?> get props => [];
  
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const HomePage();
  }
}

// Coordinator with Riverpod
class AppCoordinator extends Coordinator<AppRoute> {
  final ProviderContainer container;
  
  AppCoordinator(this.container);
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(container),
      ['login'] => LoginRoute(container),
      ['profile'] => ProfileRoute(container),
      _ => NotFoundRoute(container),
    };
  }
}

// Listening to auth changes in widgets
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.coordinator<AppCoordinator>().replace(
                HomeRoute(context.container),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('User ID: ${authState.userId}'),
      ),
    );
  }
}
```

### Data Loading with Deep Links

```dart
// Product provider
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  // Fetch product from API
  await Future.delayed(const Duration(seconds: 1));
  return Product(id: id, name: 'Product $id');
});

class Product {
  final String id;
  final String name;
  
  Product({required this.id, required this.name});
}

// Route with data loading
class ProductRoute extends AppRoute with RouteDeepLink {
  final String productId;
  final ProviderContainer container;
  
  ProductRoute(this.productId, this.container);
  
  @override
  List<Object?> get props => [productId];
  
  @override
  Uri toUri() => Uri.parse('/products/$productId');
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri) async {
    // Preload data before showing the page
    await container.read(productProvider(productId).future);
    coordinator.navigate(this);
  }
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return ProductPage(productId: productId);
  }
}

class ProductPage extends ConsumerWidget {
  final String productId;
  
  const ProductPage({super.key, required this.productId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: productAsync.when(
        data: (product) => Center(
          child: Text(product.name),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
```

## Bloc Integration

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Auth Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    emit(const AuthState(isAuthenticated: true, userId: 'user-123'));
  }
  
  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState());
  }
}

// Protected route with Bloc
class DashboardRoute extends AppRoute with RouteRedirect {
  final AuthBloc authBloc;
  
  DashboardRoute(this.authBloc);
  
  @override
  Future<AppRoute> redirect() async {
    if (!authBloc.state.isAuthenticated) {
      return LoginRoute(authBloc, intendedRoute: DashboardRoute(authBloc));
    }
    return this;
  }
  
  @override
  Uri toUri() => Uri.parse('/dashboard');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const DashboardPage();
  }
}

// Page with Bloc listener for navigation
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!state.isAuthenticated) {
          // Logged out - navigate to home
          context.coordinator<AppCoordinator>().replace(HomeRoute());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        ),
        body: const Center(
          child: Text('Dashboard Content'),
        ),
      ),
    );
  }
}
```

## Provider Integration

```dart
import 'package:provider/provider.dart';

// Auth provider
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  
  bool get isAuthenticated => _isAuthenticated;
  
  Future<void> login() async {
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    notifyListeners();
  }
  
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}

// Protected route
class SettingsRoute extends AppRoute with RouteRedirect {
  final BuildContext context;
  
  SettingsRoute(this.context);
  
  @override
  Future<AppRoute> redirect() async {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      return LoginRoute();
    }
    
    return this;
  }
  
  @override
  Uri toUri() => Uri.parse('/settings');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const SettingsPage();
  }
}
```

## Advanced Patterns

### Navigation from Business Logic

```dart
// Navigation service with Riverpod
final navigationServiceProvider = Provider((ref) {
  return NavigationService(ref);
});

class NavigationService {
  final Ref ref;
  late final AppCoordinator coordinator;
  
  NavigationService(this.ref);
  
  void initialize(AppCoordinator coordinator) {
    this.coordinator = coordinator;
  }
  
  void navigateToProfile() {
    coordinator.push(ProfileRoute(ref.container));
  }
  
  void navigateToProduct(String productId) {
    coordinator.push(ProductRoute(productId, ref.container));
  }
  
  void goHome() {
    coordinator.replace(HomeRoute(ref.container));
  }
}

// Usage in business logic
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref ref;
  
  CheckoutNotifier(this.ref) : super(CheckoutState.initial());
  
  Future<void> completeCheckout() async {
    // Process payment...
    
    // Navigate to success page
    ref.read(navigationServiceProvider).navigateToProduct('order-123');
  }
}
```

### Query Parameters as State

```dart
class SearchRoute extends AppRoute with RouteQueryParameters {
  SearchRoute({String? initialQuery}) {
    if (initialQuery != null) {
      queryParameters['q'].value = initialQuery;
    }
  }
  
  @override
  Uri toUri() {
    final query = queryParameters['q']!.value as String?;
    return Uri.parse('/search').replace(
      queryParameters: query != null ? {'q': query} : null,
    );
  }
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return SearchPage(searchRoute: this);
  }
}

class SearchPage extends StatelessWidget {
  final SearchRoute searchRoute;
  
  const SearchPage({super.key, required this.searchRoute});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<dynamic>(
        valueListenable: searchRoute.queryParameters['q']!,
        builder: (context, query, _) {
          return SearchResults(query: query as String?);
        },
      ),
    );
  }
}
```

## Common Gotchas

> [!TIP]
> **Pass providers/containers to routes**
> Since routes are created during URI parsing (potentially before context is available), pass `ProviderContainer` or similar to route constructors.
> If you don't want to pass providers/containers to routes, you can create a global instance of `ProviderContainer` and use it in all routes.

> [!CAUTION]
> **Avoid context in redirect**
> The `redirect()` method may not have access to `BuildContext`. Use dependency injection or pass state explicitly.

> [!NOTE]
> **State changes triggering navigation**
> Use `BlocListener`, `ref.listen`, or similar to react to state changes and navigate. Don't navigate inside `build()` methods.

> [!WARNING]
> **Circular dependencies**
> Be careful not to create circular dependencies between your coordinator and state management. Use dependency injection patterns.

## Related Recipes

- [Authentication Flow](authentication-flow.md) - Auth patterns with state
- [Bottom Navigation](bottom-navigation.md) - Tab state management
- [Nested Navigation](nested-navigation.md) - Nested state contexts

## See Also

- [RouteRedirect Mixin](../api/mixins.md#routeredirect)
- [RouteQueryParameters](../api/mixins.md#routequeryparameters)
- [Riverpod Documentation](https://riverpod.dev)
- [Bloc Documentation](https://bloclibrary.dev)
