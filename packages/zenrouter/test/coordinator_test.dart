import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Test routes
class TestCoordinator extends Coordinator<AppRoute> {
  final shellPath = NavigationPath<ShellRoute>();

  @override
  List<NavigationPath> get paths => [root, shellPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['tab', 'one'] => TabOneRoute(),
      ['tab', 'two'] => TabTwoRoute(),
      _ => HomeRoute(),
    };
  }
}

sealed class AppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(TestCoordinator coordinator) => coordinator.root;
}

class HomeRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }
}

class SettingsRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }
}

class ProfileRoute extends AppRoute with RouteBuilder {
  final String userId;
  ProfileRoute(this.userId);

  @override
  Uri toUri() => Uri.parse('/profile/$userId');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Profile: $userId'));
  }
}

sealed class ShellRoute extends AppRoute with RouteShell<ShellRoute> {
  static final host = ShellHostRoute();

  @override
  ShellRoute get shellHost => host;

  @override
  NavigationPath getPath(TestCoordinator coordinator) => coordinator.shellPath;
}

class ShellHostRoute extends ShellRoute with RouteShellHost {
  @override
  NavigationPath getHostPath(TestCoordinator coordinator) => coordinator.root;

  @override
  Uri? toUri() => null;
}

class TabOneRoute extends ShellRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/tab/one');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Text('Tab One');
  }
}

class TabTwoRoute extends ShellRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/tab/two');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Text('Tab Two');
  }
}

class RedirectRoute extends AppRoute with RouteRedirect<AppRoute> {
  final AppRoute target;
  RedirectRoute(this.target);

  @override
  FutureOr<AppRoute> redirect() => target;

  @override
  Uri? toUri() => target.toUri();
}

class DeepLinkRoute extends AppRoute with RouteBuilder, RouteDeepLink {
  final String id;
  DeepLinkRoute(this.id);

  @override
  Uri toUri() => Uri.parse('/deeplink/$id');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('DeepLink: $id'));
  }

  @override
  FutureOr<void> deeplinkHandler(TestCoordinator coordinator, Uri uri) {
    // Custom deep link handling
    coordinator.replace(HomeRoute());
    coordinator.push(this);
  }
}

void main() {
  group('Coordinator', () {
    test('parseRouteFromUri parses root path', () {
      final coordinator = TestCoordinator();
      final route = coordinator.parseRouteFromUri(Uri.parse('/'));

      expect(route, isA<HomeRoute>());
    });

    test('parseRouteFromUri parses settings path', () {
      final coordinator = TestCoordinator();
      final route = coordinator.parseRouteFromUri(Uri.parse('/settings'));

      expect(route, isA<SettingsRoute>());
    });

    test('parseRouteFromUri parses path with parameters', () {
      final coordinator = TestCoordinator();
      final route =
          coordinator.parseRouteFromUri(Uri.parse('/profile/123'))
              as ProfileRoute;

      expect(route, isA<ProfileRoute>());
      expect(route.userId, '123');
    });

    test('parseRouteFromUri returns default for unknown path', () {
      final coordinator = TestCoordinator();
      final route = coordinator.parseRouteFromUri(Uri.parse('/unknown'));

      expect(route, isA<HomeRoute>());
    });

    test('push adds route to correct path', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<HomeRoute>());
    });

    test('replace clears path and adds route', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      coordinator.replace(SettingsRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<SettingsRoute>());
    });

    test('pop removes route from active path', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);

      coordinator.pop();
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<HomeRoute>());
    });

    test('currentUri returns URI of current route', () async {
      final coordinator = TestCoordinator();

      coordinator.push(SettingsRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.currentUri.path, '/settings');
    });

    test('currentUri returns / when stack is empty', () {
      final coordinator = TestCoordinator();

      expect(coordinator.currentUri.path, '/');
    });

    test('activePath returns root when no shell is active', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.activePath, coordinator.root);
    });

    test('recoverRouteFromUri with replace strategy', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      await coordinator.recoverRouteFromUri(Uri.parse('/settings'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<SettingsRoute>());
    });

    test('tryPop returns true when route popped', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      final result = await coordinator.tryPop();

      expect(result, true);
      expect(coordinator.root.stack, isEmpty);
    });

    test('tryPop returns false when stack is empty', () async {
      final coordinator = TestCoordinator();

      final result = await coordinator.tryPop();

      expect(result, false);
    });

    test('pushOrMoveToTop moves existing route to top', () async {
      final coordinator = TestCoordinator();

      final home = HomeRoute();
      final settings = SettingsRoute();

      coordinator.push(home);
      await Future.delayed(Duration.zero);
      coordinator.push(settings);
      await Future.delayed(Duration.zero);

      coordinator.pushOrMoveToTop(home);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.last, home);
    });

    test('handles redirect in push', () async {
      final coordinator = TestCoordinator();

      final target = SettingsRoute();
      final redirect = RedirectRoute(target);

      coordinator.push(redirect);
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, target);
    });
  });

  group('Coordinator - Shell Routing', () {
    test('pushing shell route adds shell host to root', () async {
      final coordinator = TestCoordinator();

      coordinator.push(TabOneRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<ShellHostRoute>());
      expect(coordinator.shellPath.stack.length, 1);
      expect(coordinator.shellPath.stack.first, isA<TabOneRoute>());
    });

    test('multiple shell routes share same host', () async {
      final coordinator = TestCoordinator();

      coordinator.push(TabOneRoute());
      await Future.delayed(Duration.zero);

      coordinator.push(TabTwoRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.shellPath.stack.length, 2);
    });

    test('activePath returns shell path when shell is active', () async {
      final coordinator = TestCoordinator();

      coordinator.push(TabOneRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.activePath, coordinator.shellPath);
    });
  });

  group('Coordinator - Deep Linking', () {
    test('RouteDeepLink uses custom handler', () async {
      final coordinator = TestCoordinator();

      final route = DeepLinkRoute('123');

      // Manually test deeplinkHandler
      await route.deeplinkHandler(coordinator, Uri.parse('/deeplink/123'));
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.stack.first, isA<HomeRoute>());
      expect(coordinator.root.stack.last, isA<DeepLinkRoute>());
    });
  });

  group('Coordinator - Notifications', () {
    test('notifies listeners on push', () async {
      final coordinator = TestCoordinator();
      var notified = false;

      coordinator.addListener(() {
        notified = true;
      });

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(notified, true);
    });

    test('notifies listeners on pop', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      await Future.delayed(Duration.zero);

      var notified = false;
      coordinator.addListener(() {
        notified = true;
      });

      coordinator.pop();

      expect(notified, true);
    });
  });
}
