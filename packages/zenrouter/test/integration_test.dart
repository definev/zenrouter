import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Complete integration test with all features
class IntegrationCoordinator extends Coordinator<AppRoute> {
  final tabPath = NavigationPath<TabRoute>();

  @override
  List<NavigationPath> get paths => [root, tabPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['login'] => LoginRoute(),
      ['dashboard'] => DashboardRoute(),
      ['settings'] => SettingsRoute(),
      ['tabs', 'profile'] => ProfileTabRoute(),
      ['tabs', 'notifications'] => NotificationsTabRoute(),
      _ => HomeRoute(),
    };
  }
}

sealed class AppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(IntegrationCoordinator coordinator) =>
      coordinator.root;
}

// Simple routes
class HomeRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => coordinator.push(DashboardRoute()),
          child: const Text('Go to Dashboard'),
        ),
      ),
    );
  }
}

class LoginRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Login'));
  }
}

// Protected route with redirect
class DashboardRoute extends AppRoute
    with RouteBuilder, RouteRedirect<AppRoute> {
  bool isAuthenticated = false;

  @override
  Uri toUri() => Uri.parse('/dashboard');

  @override
  FutureOr<AppRoute> redirect() {
    return isAuthenticated ? this : LoginRoute();
  }

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Dashboard'));
  }
}

// Route with guard
class SettingsRoute extends AppRoute with RouteBuilder, RouteGuard {
  bool hasUnsavedChanges = false;
  bool allowPop = true;

  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  FutureOr<bool> popGuard() => allowPop;

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }
}

// Shell routes
sealed class TabRoute extends AppRoute with RouteShell<TabRoute> {
  static final host = TabShellHost();

  @override
  TabRoute get shellHost => host;

  @override
  NavigationPath getPath(IntegrationCoordinator coordinator) =>
      coordinator.tabPath;
}

class TabShellHost extends TabRoute with RouteShellHost, RouteBuilder {
  @override
  NavigationPath getHostPath(IntegrationCoordinator coordinator) =>
      coordinator.root;

  @override
  Uri? toUri() => null;

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Tab Shell'));
  }
}

class ProfileTabRoute extends TabRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/tabs/profile');

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return const Text('Profile Tab');
  }
}

class NotificationsTabRoute extends TabRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/tabs/notifications');

  @override
  Widget build(IntegrationCoordinator coordinator, BuildContext context) {
    return const Text('Notifications Tab');
  }
}

void main() {
  group('Integration Tests', () {
    test('complete navigation flow: push, pop, replace', () async {
      final coordinator = IntegrationCoordinator();

      // Start with home
      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<HomeRoute>());

      // Push settings
      coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 2);

      // Pop back to home
      coordinator.pop();
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<HomeRoute>());

      // Replace with login
      coordinator.replace(LoginRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<LoginRoute>());
    });

    test('redirect chain: unauthenticated user redirected to login', () async {
      final coordinator = IntegrationCoordinator();

      final dashboard = DashboardRoute();
      dashboard.isAuthenticated = false;

      coordinator.push(dashboard);
      await Future.delayed(Duration.zero);

      // Should be redirected to login
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<LoginRoute>());
    });

    test('redirect chain: authenticated user sees dashboard', () async {
      final coordinator = IntegrationCoordinator();

      final dashboard = DashboardRoute();
      dashboard.isAuthenticated = true;

      coordinator.push(dashboard);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, dashboard);
    });

    test('route guard prevents pop', () async {
      final coordinator = IntegrationCoordinator();

      final settings = SettingsRoute();
      settings.hasUnsavedChanges = true;
      settings.allowPop = false;

      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      coordinator.pop();
      await Future.delayed(const Duration(milliseconds: 20));

      // Should still be on settings
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, settings);
    });

    test('route guard allows pop when confirmed', () async {
      final coordinator = IntegrationCoordinator();

      final settings = SettingsRoute();
      settings.hasUnsavedChanges = true;
      settings.allowPop = true;

      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      coordinator.pop();
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack, isEmpty);
    });

    test('multi-shell scenario: tabs navigation', () async {
      final coordinator = IntegrationCoordinator();

      // Push first tab
      coordinator.push(ProfileTabRoute());
      await Future.delayed(Duration.zero);

      // Check shell host is in root
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<TabShellHost>());

      // Check tab is in shell path
      expect(coordinator.tabPath.stack.length, 1);
      expect(coordinator.tabPath.stack.first, isA<ProfileTabRoute>());

      // Push second tab
      coordinator.push(NotificationsTabRoute());
      await Future.delayed(Duration.zero);

      // Root should still have only the shell host
      expect(coordinator.root.stack.length, 1);

      // Shell path should have both tabs
      expect(coordinator.tabPath.stack.length, 2);
      expect(coordinator.tabPath.stack.last, isA<NotificationsTabRoute>());
    });

    test('deep linking: parse and navigate from URI', () async {
      final coordinator = IntegrationCoordinator();

      await coordinator.recoverRouteFromUri(Uri.parse('/settings'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<SettingsRoute>());
      expect(coordinator.currentUri.path, '/settings');
    });

    test('deep linking with shell route', () async {
      final coordinator = IntegrationCoordinator();

      await coordinator.recoverRouteFromUri(Uri.parse('/tabs/profile'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<TabShellHost>());
      expect(coordinator.tabPath.stack.length, 1);
      expect(coordinator.tabPath.stack.first, isA<ProfileTabRoute>());
    });

    test('complex scenario: redirect + guard + shell', () async {
      final coordinator = IntegrationCoordinator();

      // Start with authenticated dashboard
      final dashboard = DashboardRoute();
      dashboard.isAuthenticated = true;
      coordinator.push(dashboard);
      await Future.delayed(Duration.zero);

      // Navigate to tab
      coordinator.push(ProfileTabRoute());
      await Future.delayed(Duration.zero);

      // Should have shell host and dashboard in root
      expect(coordinator.root.stack.length, 2);

      // Navigate to settings with guard
      final settings = SettingsRoute();
      settings.allowPop = false;
      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 3);

      // Try to pop (should be prevented)
      coordinator.pop();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(coordinator.root.stack.length, 3);

      // Allow pop
      settings.allowPop = true;
      coordinator.pop();
      await Future.delayed(Duration.zero);

      // Should be back at shell
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.activePath, coordinator.tabPath);
    });

    test('tryPop handles guards correctly', () async {
      final coordinator = IntegrationCoordinator();

      final settings = SettingsRoute();
      settings.allowPop = false;

      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      final result = await coordinator.tryPop();

      // Should return false since it not allowed to pop
      expect(result, false);
      expect(coordinator.root.stack.length, 1);
    });

    test('URI synchronization throughout navigation', () async {
      final coordinator = IntegrationCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.currentUri.path, '/');

      coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);
      expect(coordinator.currentUri.path, '/settings');

      coordinator.pop();
      await Future.delayed(Duration.zero);
      expect(coordinator.currentUri.path, '/');
    });

    test('pushOrMoveToTop in tab scenario', () async {
      final coordinator = IntegrationCoordinator();

      final profile = ProfileTabRoute();
      final notifications = NotificationsTabRoute();

      coordinator.push(profile);
      await Future.delayed(Duration.zero);
      coordinator.push(notifications);
      await Future.delayed(Duration.zero);

      expect(coordinator.tabPath.stack.length, 2);

      // Move profile to top
      coordinator.pushOrMoveToTop(profile);
      await Future.delayed(Duration.zero);

      expect(coordinator.tabPath.stack.length, 2);
      expect(coordinator.tabPath.stack.last, profile);
    });
  });
}
