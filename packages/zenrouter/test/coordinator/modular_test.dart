import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Routes
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text(toString()));
  }

  @override
  List<Object?> get props => [];
}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  String toString() => 'HomeRoute';
}

class AuthLoginRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/auth/login');

  @override
  String toString() => 'AuthLoginRoute';
}

class AuthRegisterRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/auth/register');

  @override
  String toString() => 'AuthRegisterRoute';
}

class ShopHomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/shop');

  @override
  String toString() => 'ShopHomeRoute';
}

class ShopProductRoute extends AppRoute {
  ShopProductRoute({required this.id});

  final String id;

  @override
  Uri toUri() => Uri.parse('/shop/products/$id');

  @override
  String toString() => 'ShopProductRoute(id: $id)';

  @override
  List<Object?> get props => [id];
}

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  String toString() => 'SettingsRoute';
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});

  final Uri uri;

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  String toString() => 'NotFoundRoute(uri: $uri)';

  @override
  List<Object?> get props => [uri];
}

// ============================================================================
// Test Modules
// ============================================================================

class AuthModule extends RouteModule<AppRoute> {
  AuthModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['auth', 'login'] => AuthLoginRoute(),
      ['auth', 'register'] => AuthRegisterRoute(),
      _ => null,
    };
  }

  @override
  void defineLayout() {
    // Auth module doesn't define layouts
  }
}

class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  late final NavigationPath<AppRoute> shopPath = NavigationPath.createWith(
    label: 'shop',
    coordinator: coordinator,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [shopPath];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ShopProductRoute(id: id),
      _ => null,
    };
  }
}

class SettingsModule extends RouteModule<AppRoute> {
  SettingsModule(super.coordinator);

  late final NavigationPath<AppRoute> settingsPath = NavigationPath.createWith(
    label: 'settings',
    coordinator: coordinator,
  );

  @override
  List<StackPath> get paths => [settingsPath];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['settings'] => SettingsRoute(),
      _ => null,
    };
  }

  @override
  void defineLayout() {
    // Settings module doesn't define layouts
  }
}

// Module that returns null for all routes (should be skipped)
class EmptyModule extends RouteModule<AppRoute> {
  EmptyModule(super.coordinator);

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() {}
}

// Module with async parsing
class AsyncModule extends RouteModule<AppRoute> {
  AsyncModule(super.coordinator, {this.delay = Duration.zero});

  final Duration delay;

  @override
  List<StackPath> get paths => [];

  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async {
    await Future.delayed(delay);
    return switch (uri.pathSegments) {
      ['async'] => HomeRoute(),
      _ => null,
    };
  }

  @override
  void defineLayout() {}
}

// Module that throws an error
class ErrorModule extends RouteModule<AppRoute> {
  ErrorModule(super.coordinator);

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    throw Exception('Module error');
  }

  @override
  void defineLayout() {}
}

// ============================================================================
// Test Layouts
// ============================================================================

class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) {
    final shopModule = coordinator.getModule<ShopModule>();
    return shopModule.shopPath;
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: buildPath(coordinator));
  }
}

// ============================================================================
// Test Coordinators
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    AuthModule(this),
    ShopModule(this),
    SettingsModule(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class SingleModuleCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {AuthModule(this)};

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class EmptyModulesCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {EmptyModule(this)};

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class AsyncModulesCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  AsyncModulesCoordinator({Duration delay = Duration.zero}) : _delay = delay;

  final Duration _delay;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    AsyncModule(this, delay: _delay),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class ErrorModulesCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {ErrorModule(this)};

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('CoordinatorModular', () {
    group('Module Registration', () {
      test('registers modules correctly', () {
        final coordinator = AppCoordinator();

        expect(coordinator.getModule<AuthModule>(), isA<AuthModule>());
        expect(coordinator.getModule<ShopModule>(), isA<ShopModule>());
        expect(coordinator.getModule<SettingsModule>(), isA<SettingsModule>());
      });

      test('throws when accessing non-existent module', () {
        final coordinator = SingleModuleCoordinator();

        expect(
          () => coordinator.getModule<ShopModule>(),
          throwsA(isA<TypeError>()),
        );
      });

      test('modules are initialized with coordinator reference', () {
        final coordinator = AppCoordinator();

        final authModule = coordinator.getModule<AuthModule>();
        expect(authModule.coordinator, equals(coordinator));

        final shopModule = coordinator.getModule<ShopModule>();
        expect(shopModule.coordinator, equals(coordinator));
      });

      test('modules are stored by type', () {
        final coordinator = AppCoordinator();

        final module1 = coordinator.getModule<AuthModule>();
        final module2 = coordinator.getModule<AuthModule>();

        expect(identical(module1, module2), isTrue);
      });
    });

    group('Route Parsing', () {
      test('delegates to first matching module', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/auth/login'),
        );

        expect(route, isA<AuthLoginRoute>());
      });

      test('returns null from module when route not found in module', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/unknown'),
        );

        expect(route, isA<NotFoundRoute>());
      });

      test('checks modules in order until match found', () async {
        final coordinator = AppCoordinator();

        // Auth module should match first
        final authRoute = await coordinator.parseRouteFromUri(
          Uri.parse('/auth/login'),
        );
        expect(authRoute, isA<AuthLoginRoute>());

        // Shop module should match
        final shopRoute = await coordinator.parseRouteFromUri(
          Uri.parse('/shop'),
        );
        expect(shopRoute, isA<ShopHomeRoute>());

        // Settings module should match
        final settingsRoute = await coordinator.parseRouteFromUri(
          Uri.parse('/settings'),
        );
        expect(settingsRoute, isA<SettingsRoute>());
      });

      test('handles async route parsing', () async {
        final coordinator = AsyncModulesCoordinator();

        final route = await coordinator.parseRouteFromUri(Uri.parse('/async'));

        expect(route, isA<HomeRoute>());
      });

      test('handles routes with parameters', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/shop/products/123'),
        );

        expect(route, isA<ShopProductRoute>());
        expect((route as ShopProductRoute).id, equals('123'));
      });

      test('calls notFoundRoute when no module matches', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/unknown/route'),
        );

        expect(route, isA<NotFoundRoute>());
        expect((route as NotFoundRoute).uri.path, equals('/unknown/route'));
      });

      test('handles empty modules gracefully', () async {
        final coordinator = EmptyModulesCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/any/route'),
        );

        expect(route, isA<NotFoundRoute>());
      });

      test('propagates errors from module parsing', () async {
        final coordinator = ErrorModulesCoordinator();

        expect(
          () => coordinator.parseRouteFromUri(Uri.parse('/any')),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Path Aggregation', () {
      test('aggregates paths from all modules', () {
        final coordinator = AppCoordinator();

        final paths = coordinator.paths;

        // Should include root path + paths from ShopModule and SettingsModule
        expect(paths.length, greaterThan(1));

        // Check that shop path exists
        final shopModule = coordinator.getModule<ShopModule>();
        expect(paths, contains(shopModule.shopPath));

        // Check that settings path exists
        final settingsModule = coordinator.getModule<SettingsModule>();
        expect(paths, contains(settingsModule.settingsPath));
      });

      test('includes super paths', () {
        final coordinator = AppCoordinator();

        final paths = coordinator.paths;

        // Should include root path
        expect(paths, contains(coordinator.root));
      });

      test('modules without paths still work', () {
        final coordinator = SingleModuleCoordinator();

        final paths = coordinator.paths;

        // Should only have root path
        expect(paths.length, equals(1));
        expect(paths, contains(coordinator.root));
      });
    });

    group('Layout Definition', () {
      test('calls defineLayout on all modules', () {
        var authLayoutCalled = false;
        var shopLayoutCalled = false;
        var settingsLayoutCalled = false;

        _TestLayoutCoordinator(
          onAuthLayout: () => authLayoutCalled = true,
          onShopLayout: () => shopLayoutCalled = true,
          onSettingsLayout: () => settingsLayoutCalled = true,
        );

        // defineLayout is called during coordinator construction
        expect(authLayoutCalled, isTrue);
        expect(shopLayoutCalled, isTrue);
        expect(settingsLayoutCalled, isTrue);
      });

      test('allows modules to register layouts', () {
        final coordinator = AppCoordinator();

        // Shop module should have registered ShopLayout
        final shopModule = coordinator.getModule<ShopModule>();
        expect(shopModule.shopPath, isNotNull);
      });
    });

    group('Converter Definition', () {
      test('calls defineConverter on all modules', () {
        var authConverterCalled = false;
        var shopConverterCalled = false;
        var settingsConverterCalled = false;

        _TestConverterCoordinator(
          onAuthConverter: () => authConverterCalled = true,
          onShopConverter: () => shopConverterCalled = true,
          onSettingsConverter: () => settingsConverterCalled = true,
        );

        // defineConverter is called during coordinator construction
        expect(authConverterCalled, isTrue);
        expect(shopConverterCalled, isTrue);
        expect(settingsConverterCalled, isTrue);
      });
    });

    group('Module Isolation', () {
      test('modules do not interfere with each other', () async {
        final coordinator = AppCoordinator();

        // Each module should only handle its own routes
        final authRoute = await coordinator.parseRouteFromUri(
          Uri.parse('/auth/login'),
        );
        expect(authRoute, isA<AuthLoginRoute>());

        final shopRoute = await coordinator.parseRouteFromUri(
          Uri.parse('/shop'),
        );
        expect(shopRoute, isA<ShopHomeRoute>());

        // Modules should not handle each other's routes
        final notShopRoute = await coordinator.parseRouteFromUri(
          Uri.parse('/auth/shop'),
        );
        expect(notShopRoute, isA<NotFoundRoute>());
      });

      test('modules maintain separate path instances', () {
        final coordinator = AppCoordinator();

        final shopModule = coordinator.getModule<ShopModule>();
        final settingsModule = coordinator.getModule<SettingsModule>();

        expect(shopModule.shopPath, isNot(equals(settingsModule.settingsPath)));
      });
    });

    group('Edge Cases', () {
      test('handles empty URI', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(Uri.parse('/'));

        // Should fall through to notFoundRoute
        expect(route, isA<NotFoundRoute>());
      });

      test('handles URI with query parameters', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/auth/login?redirect=/home'),
        );

        expect(route, isA<AuthLoginRoute>());
      });

      test('handles URI with fragments', () async {
        final coordinator = AppCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/auth/login#section'),
        );

        expect(route, isA<AuthLoginRoute>());
      });

      test('handles multiple consecutive null returns', () async {
        final coordinator = EmptyModulesCoordinator();

        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/any/route'),
        );

        expect(route, isA<NotFoundRoute>());
      });
    });

    group('Integration Tests', () {
      test('full flow: parse route and navigate', () async {
        final coordinator = AppCoordinator();

        // Parse route from URI
        final route = await coordinator.parseRouteFromUri(
          Uri.parse('/shop/products/456'),
        );

        expect(route, isA<ShopProductRoute>());
        expect((route as ShopProductRoute).id, equals('456'));

        // Push route
        coordinator.push(route);
        await Future.delayed(Duration.zero);

        // Verify route is in stack
        expect(coordinator.root.stack.isNotEmpty, isTrue);
      });

      test('module paths are accessible for navigation', () async {
        final coordinator = AppCoordinator();

        final shopModule = coordinator.getModule<ShopModule>();

        // Module paths should be accessible and functional
        expect(shopModule.shopPath, isNotNull);
        expect(shopModule.shopPath.debugLabel, equals('shop'));

        // Should be able to push directly to module's path
        shopModule.shopPath.push(ShopHomeRoute());
        await Future.delayed(Duration.zero);
        expect(shopModule.shopPath.stack.length, equals(1));
        expect(shopModule.shopPath.stack.last, isA<ShopHomeRoute>());
      });

      test('coordinator can access module-specific functionality', () {
        final coordinator = AppCoordinator();

        final shopModule = coordinator.getModule<ShopModule>();

        // Module-specific paths should be accessible
        expect(shopModule.shopPath, isNotNull);
        expect(shopModule.shopPath.debugLabel, equals('shop'));
      });
    });
  });

  group('RouteModule', () {
    test('can be instantiated with coordinator', () {
      final coordinator = AppCoordinator();
      final module = AuthModule(coordinator);

      expect(module.coordinator, equals(coordinator));
    });

    test('default paths returns empty list', () {
      final coordinator = AppCoordinator();
      final module = AuthModule(coordinator);

      expect(module.paths, isEmpty);
    });

    test('default defineLayout does nothing', () {
      final coordinator = AppCoordinator();
      final module = AuthModule(coordinator);

      // Should not throw
      expect(() => module.defineLayout(), returnsNormally);
    });

    test('default defineConverter does nothing', () {
      final coordinator = AppCoordinator();
      final module = AuthModule(coordinator);

      // Should not throw
      expect(() => module.defineConverter(), returnsNormally);
    });

    test('can override paths getter', () {
      final coordinator = AppCoordinator();
      final shopModule = coordinator.getModule<ShopModule>();

      expect(shopModule.paths.length, equals(1));
      expect(shopModule.paths.first, equals(shopModule.shopPath));
    });

    test('can override defineLayout', () {
      final coordinator = AppCoordinator();
      final shopModule = coordinator.getModule<ShopModule>();

      // Shop module defines layout, should not throw
      expect(() => shopModule.defineLayout(), returnsNormally);
    });
  });
}

// ============================================================================
// Test Helper Coordinators
// ============================================================================

class _TestLayoutCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  _TestLayoutCoordinator({
    required this.onAuthLayout,
    required this.onShopLayout,
    required this.onSettingsLayout,
  });

  final VoidCallback onAuthLayout;
  final VoidCallback onShopLayout;
  final VoidCallback onSettingsLayout;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    _TestAuthModule(this, onLayout: onAuthLayout),
    _TestShopModule(this, onLayout: onShopLayout),
    _TestSettingsModule(this, onLayout: onSettingsLayout),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class _TestAuthModule extends RouteModule<AppRoute> {
  _TestAuthModule(super.coordinator, {required this.onLayout});

  final VoidCallback onLayout;

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() => onLayout();
}

class _TestShopModule extends RouteModule<AppRoute> {
  _TestShopModule(super.coordinator, {required this.onLayout});

  final VoidCallback onLayout;

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() => onLayout();
}

class _TestSettingsModule extends RouteModule<AppRoute> {
  _TestSettingsModule(super.coordinator, {required this.onLayout});

  final VoidCallback onLayout;

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() => onLayout();
}

class _TestConverterCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  _TestConverterCoordinator({
    required this.onAuthConverter,
    required this.onShopConverter,
    required this.onSettingsConverter,
  });

  final VoidCallback onAuthConverter;
  final VoidCallback onShopConverter;
  final VoidCallback onSettingsConverter;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    _TestAuthConverterModule(this, onConverter: onAuthConverter),
    _TestShopConverterModule(this, onConverter: onShopConverter),
    _TestSettingsConverterModule(this, onConverter: onSettingsConverter),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class _TestAuthConverterModule extends RouteModule<AppRoute> {
  _TestAuthConverterModule(super.coordinator, {required this.onConverter});

  final VoidCallback onConverter;

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineConverter() => onConverter();
}

class _TestShopConverterModule extends RouteModule<AppRoute> {
  _TestShopConverterModule(super.coordinator, {required this.onConverter});

  final VoidCallback onConverter;

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineConverter() => onConverter();
}

class _TestSettingsConverterModule extends RouteModule<AppRoute> {
  _TestSettingsConverterModule(super.coordinator, {required this.onConverter});

  final VoidCallback onConverter;

  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineConverter() => onConverter();
}
