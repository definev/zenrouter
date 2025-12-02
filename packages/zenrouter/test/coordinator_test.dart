import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Test routes
class TestCoordinator extends Coordinator<AppRoute> {
  static final instance = TestCoordinator._();
  TestCoordinator._();

  factory TestCoordinator() => instance..reset();

  void reset() => replace(parseRouteFromUri(Uri.parse('/')));

  final shellPath = NavigationPath<AppRoute>();

  @override
  List<NavigationPath> get paths => [root, shellPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      ['shell', 'one'] => ShellChildOneRoute(),
      ['shell', 'two'] => ShellChildTwoRoute(),
      _ => HomeRoute(),
    };
  }
}

sealed class AppRoute extends RouteTarget with RouteUnique {}

// Root host
class RootHostRoute extends AppRoute with RouteHost<AppRoute> {
  static final instance = RootHostRoute();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  RouteHost? get host => null;

  @override
  HostType get hostType => HostType.navigationStack;

  @override
  NavigationPath get path => TestCoordinator.instance.root;

  @override
  bool operator ==(Object other) => other is RootHostRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

// Shell host
class ShellHostRoute extends AppRoute with RouteHost<AppRoute> {
  static final instance = ShellHostRoute();

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  HostType get hostType => HostType.navigationStack;

  @override
  NavigationPath get path => TestCoordinator.instance.shellPath;

  @override
  Uri toUri() => Uri.parse('/shell');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Shell Host'));
  }

  @override
  bool operator ==(Object other) => other is ShellHostRoute;

  @override
  int get hashCode => runtimeType.hashCode;
}

class HomeRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }
}

class SettingsRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }
}

class ProfileRoute extends AppRoute with RouteDestinationMixin {
  final String userId;
  ProfileRoute(this.userId);

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri toUri() => Uri.parse('/profile/$userId');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Profile: $userId'));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileRoute && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

class ShellChildOneRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => ShellHostRoute.instance;

  @override
  Uri toUri() => Uri.parse('/shell/one');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Text('Shell Child One');
  }
}

class ShellChildTwoRoute extends AppRoute with RouteDestinationMixin {
  @override
  RouteHost? get host => ShellHostRoute.instance;

  @override
  Uri toUri() => Uri.parse('/shell/two');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Text('Shell Child Two');
  }
}

class RedirectRoute extends AppRoute with RouteRedirect<AppRoute> {
  final AppRoute target;
  RedirectRoute(this.target);

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  FutureOr<AppRoute?> redirect() => target;

  @override
  Uri toUri() => target.toUri();

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }
}

class DeepLinkRoute extends AppRoute with RouteDestinationMixin, RouteDeepLink {
  final String id;
  DeepLinkRoute(this.id);

  @override
  RouteHost? get host => RootHostRoute.instance;

  @override
  Uri toUri() => Uri.parse('/deeplink/$id');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('DeepLink: $id'));
  }

  @override
  FutureOr<void> deeplinkHandler(covariant Coordinator coordinator, Uri uri) {
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

    test('push adds route to root path', () async {
      final coordinator = TestCoordinator();

      coordinator.replace(HomeRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<HomeRoute>());
    });

    test('replace clears all paths and adds route', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());
      coordinator.replace(SettingsRoute());

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<SettingsRoute>());
    });

    test('pop removes route from nearest dynamic path', () async {
      final coordinator = TestCoordinator();

      coordinator.push(ShellChildOneRoute());
      Future.delayed(Duration.zero);
      coordinator.push(ShellChildTwoRoute());
      Future.delayed(Duration.zero);

      expect(coordinator.shellPath.stack.length, 2);

      coordinator.pop();

      expect(coordinator.shellPath.stack.length, 1);
      expect(coordinator.shellPath.stack.first, isA<ShellChildOneRoute>());
    });

    test('currentUri returns URI of active route', () async {
      final coordinator = TestCoordinator();

      coordinator.push(SettingsRoute());

      expect(coordinator.currentUri.path, '/settings');
    });

    test('currentUri returns / when stack is empty', () {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());

      expect(coordinator.currentUri.path, '/');
    });

    test('nearestPath returns root when no nested navigation', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());

      // HomeRoute is in root, so nearestPath should be root
      expect(coordinator.nearestPath, coordinator.root);
    });

    test('nearestPath returns shell path when shell route active', () async {
      final coordinator = TestCoordinator();

      coordinator.push(ShellChildOneRoute());

      expect(coordinator.nearestPath, coordinator.shellPath);
    });

    test('recoverRouteFromUri with replace strategy', () async {
      final coordinator = TestCoordinator();

      coordinator.push(HomeRoute());

      coordinator.recoverRouteFromUri(Uri.parse('/settings'));

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<SettingsRoute>());
    });

    test('tryPop returns true when route popped', () async {
      final coordinator = TestCoordinator();

      coordinator.push(ShellChildOneRoute());

      final result = await coordinator.tryPop();

      expect(result, true);
      expect(coordinator.shellPath.stack, isEmpty);
    });

    test('pushOrMoveToTop moves existing route to top', () async {
      final coordinator = TestCoordinator();

      final one = ShellChildOneRoute();
      final two = ShellChildTwoRoute();

      coordinator.push(one);
      coordinator.push(two);

      coordinator.pushOrMoveToTop(one);

      expect(coordinator.shellPath.stack.length, 2);
      expect(coordinator.shellPath.stack.last, one);
    });

    test('handles redirect in push', () async {
      final coordinator = TestCoordinator();

      final target = SettingsRoute();
      final redirect = RedirectRoute(target);

      coordinator.push(redirect);
      await Future.delayed(Duration.zero);

      // Should have pushed the target, not the redirect
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<RootHostRoute>());
    });
  });

  group('Coordinator - Host Navigation', () {
    test('pushing shell route sets up host in root', () async {
      final coordinator = TestCoordinator();

      coordinator.push(ShellChildOneRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.stack.first, isA<ShellHostRoute>());
      expect(coordinator.shellPath.stack.length, 1);
      expect(coordinator.shellPath.stack.first, isA<ShellChildOneRoute>());
    });

    test('multiple shell routes share same host', () async {
      final coordinator = TestCoordinator();

      coordinator.push(ShellChildOneRoute());
      await Future.delayed(Duration.zero);

      coordinator.push(ShellChildTwoRoute());
      await Future.delayed(Duration.zero);

      expect(coordinator.root.stack.length, 1);
      expect(coordinator.shellPath.stack.length, 2);
    });

    test('pathSegments includes host paths', () async {
      final coordinator = TestCoordinator();

      coordinator.push(ShellChildOneRoute());
      await Future.delayed(Duration.zero);

      final segments = coordinator.pathSegments;
      expect(segments.length, 2);
      expect(segments[0], coordinator.root);
      expect(segments[1], coordinator.shellPath);
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
      expect(coordinator.root.stack.first, isA<RootHostRoute>());
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

      coordinator.push(ShellChildOneRoute());
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
