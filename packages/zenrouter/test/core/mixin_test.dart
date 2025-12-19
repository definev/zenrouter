import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Application Setup
// ============================================================================

/// Base route for all test routes
abstract class TestAppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

/// Simple route for navigation testing
class SimpleRoute extends TestAppRoute {
  SimpleRoute({this.id = 'default'});
  final String id;

  @override
  Uri toUri() => Uri.parse('/simple/$id');

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(key: ValueKey('simple-$id'), body: Text('Simple: $id'));
  }

  @override
  List<Object?> get props => [id];
}

// ============================================================================
// RouteTransition Tests
// ============================================================================

/// Route with Material transition
class MaterialTransitionRoute extends TestAppRoute with RouteTransition {
  @override
  Uri toUri() => Uri.parse('/material-transition');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.material(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('material-transition'),
      appBar: AppBar(title: const Text('Material Transition')),
      body: const Center(child: Text('Material Page')),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Route with Cupertino transition
class CupertinoTransitionRoute extends TestAppRoute with RouteTransition {
  @override
  Uri toUri() => Uri.parse('/cupertino-transition');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.cupertino(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('cupertino-transition'),
      appBar: AppBar(title: const Text('Cupertino Transition')),
      body: const Center(child: Text('Cupertino Page')),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Route with Dialog transition
class DialogTransitionRoute extends TestAppRoute with RouteTransition {
  @override
  Uri toUri() => Uri.parse('/dialog-transition');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.dialog(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return AlertDialog(
      key: const ValueKey('dialog-transition'),
      title: const Text('Dialog Transition'),
      content: const Text('Dialog Content'),
      actions: [
        TextButton(
          key: const ValueKey('dialog-close'),
          onPressed: () => coordinator.pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  List<Object?> get props => [];
}

/// Route with Sheet transition
class SheetTransitionRoute extends TestAppRoute with RouteTransition {
  @override
  Uri toUri() => Uri.parse('/sheet-transition');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.sheet(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Container(
      key: const ValueKey('sheet-transition'),
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(child: Text('Sheet Content')),
    );
  }

  @override
  List<Object?> get props => [];
}

// ============================================================================
// RouteGuard Tests
// ============================================================================

/// Route with configurable pop guard
class GuardedPopRoute extends TestAppRoute with RouteGuard {
  GuardedPopRoute({this.allowPop = false, this.popDelay = Duration.zero});
  final bool allowPop;
  final Duration popDelay;

  @override
  Uri toUri() => Uri.parse('/guarded-pop');

  @override
  Future<bool> popGuard() async {
    if (popDelay > Duration.zero) {
      await Future.delayed(popDelay);
    }
    return allowPop;
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('guarded-pop'),
      appBar: AppBar(title: const Text('Guarded Page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Allow Pop: $allowPop'),
          ElevatedButton(
            key: const ValueKey('try-pop'),
            onPressed: () => coordinator.pop(),
            child: const Text('Try Pop'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [allowPop, popDelay];
}

/// Route with guard that shows confirmation dialog
class ConfirmationGuardRoute extends TestAppRoute with RouteGuard {
  ConfirmationGuardRoute({this.showConfirmation = true});
  final bool showConfirmation;
  bool _wasConfirmationShown = false;

  bool get wasConfirmationShown => _wasConfirmationShown;

  @override
  Uri toUri() => Uri.parse('/confirmation-guard');

  @override
  Future<bool> popGuard() async {
    if (showConfirmation) {
      _wasConfirmationShown = true;
      // Simulate showing a confirmation dialog
      return false;
    }
    return true;
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('confirmation-guard'),
      body: const Text('Confirmation Guard'),
    );
  }

  @override
  List<Object?> get props => [showConfirmation];
}

// ============================================================================
// RouteRedirect Tests
// ============================================================================

/// Route that redirects to another route
class BasicRedirectRoute extends TestAppRoute with RouteRedirect<TestAppRoute> {
  BasicRedirectRoute({required this.targetId});
  final String targetId;

  @override
  Uri toUri() => Uri.parse('/redirect/$targetId');

  @override
  FutureOr<TestAppRoute> redirect() => SimpleRoute(id: targetId);

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const SizedBox.shrink(); // Should never be shown
  }

  @override
  List<Object?> get props => [targetId];
}

/// Route that redirects asynchronously
class AsyncRedirectRoute extends TestAppRoute with RouteRedirect<TestAppRoute> {
  AsyncRedirectRoute({
    required this.targetId,
    this.delay = const Duration(milliseconds: 50),
  });
  final String targetId;
  final Duration delay;

  @override
  Uri toUri() => Uri.parse('/async-redirect/$targetId');

  @override
  Future<TestAppRoute> redirect() async {
    await Future.delayed(delay);
    return SimpleRoute(id: targetId);
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const SizedBox.shrink(); // Should never be shown
  }

  @override
  List<Object?> get props => [targetId, delay];
}

/// Route that conditionally redirects based on auth state
class AuthRedirectRoute extends TestAppRoute with RouteRedirect<TestAppRoute> {
  AuthRedirectRoute({required this.isAuthenticated});
  final bool isAuthenticated;

  @override
  Uri toUri() => Uri.parse('/auth-redirect');

  @override
  FutureOr<TestAppRoute?> redirect() {
    if (!isAuthenticated) {
      return LoginRoute();
    }
    return null; // Stay on current route
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('auth-redirect'),
      body: const Text('Protected Content'),
    );
  }

  @override
  List<Object?> get props => [isAuthenticated];
}

/// Login route for auth redirect testing
class LoginRoute extends TestAppRoute {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('login'),
      body: const Text('Login Page'),
    );
  }

  @override
  List<Object?> get props => [];
}

/// Route that redirects in a chain
class ChainRedirectRoute extends TestAppRoute with RouteRedirect<TestAppRoute> {
  ChainRedirectRoute({required this.step});
  final int step;

  @override
  Uri toUri() => Uri.parse('/chain-redirect/$step');

  @override
  FutureOr<TestAppRoute> redirect() {
    if (step < 3) {
      return ChainRedirectRoute(step: step + 1);
    }
    return SimpleRoute(id: 'final');
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return const SizedBox.shrink();
  }

  @override
  List<Object?> get props => [step];
}

// ============================================================================
// RouteDeeplink Tests
// ============================================================================

/// Route with push deep link strategy
class PushDeeplinkRoute extends TestAppRoute with RouteDeepLink {
  PushDeeplinkRoute({required this.path});
  final String path;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;

  @override
  Uri toUri() => Uri.parse('/deeplink/push/$path');

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: ValueKey('push-deeplink-$path'),
      body: Text('Push Deeplink: $path'),
    );
  }

  @override
  List<Object?> get props => [path];
}

/// Route with replace deep link strategy
class ReplaceDeeplinkRoute extends TestAppRoute with RouteDeepLink {
  ReplaceDeeplinkRoute({required this.path});
  final String path;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.replace;

  @override
  Uri toUri() => Uri.parse('/deeplink/replace/$path');

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: ValueKey('replace-deeplink-$path'),
      body: Text('Replace Deeplink: $path'),
    );
  }

  @override
  List<Object?> get props => [path];
}

/// Route with custom deep link strategy
class CustomDeeplinkRoute extends TestAppRoute with RouteDeepLink {
  CustomDeeplinkRoute({required this.path});
  final String path;
  bool handlerCalled = false;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Uri toUri() => Uri.parse('/deeplink/custom/$path');

  @override
  void deeplinkHandler(covariant MixinTestCoordinator coordinator, Uri uri) {
    handlerCalled = true;
    // Custom handling: navigate to a profile instead
    coordinator.push(SimpleRoute(id: 'custom-handled-$path'));
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: ValueKey('custom-deeplink-$path'),
      body: Text('Custom Deeplink: $path'),
    );
  }

  @override
  List<Object?> get props => [path];
}

/// Route with async custom deep link handler
class AsyncCustomDeeplinkRoute extends TestAppRoute with RouteDeepLink {
  AsyncCustomDeeplinkRoute({required this.path});
  final String path;
  bool handlerCompleted = false;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Uri toUri() => Uri.parse('/deeplink/async-custom/$path');

  @override
  Future<void> deeplinkHandler(
    covariant MixinTestCoordinator coordinator,
    Uri uri,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));
    handlerCompleted = true;
    coordinator.push(SimpleRoute(id: 'async-custom-$path'));
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: ValueKey('async-custom-deeplink-$path'),
      body: Text('Async Custom Deeplink: $path'),
    );
  }

  @override
  List<Object?> get props => [path];
}

// ============================================================================
// Combined Mixins Tests
// ============================================================================

/// Route with RouteTransition + RouteGuard
class TransitionGuardRoute extends TestAppRoute
    with RouteTransition, RouteGuard {
  TransitionGuardRoute({this.allowPop = false});
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/transition-guard');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.cupertino(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('transition-guard'),
      appBar: AppBar(title: const Text('Transition + Guard')),
      body: Column(
        children: [
          Text('Allow Pop: $allowPop'),
          ElevatedButton(
            key: const ValueKey('try-pop'),
            onPressed: () => coordinator.pop(),
            child: const Text('Try Pop'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [allowPop];
}

/// Route with RouteRedirect + RouteGuard
class RedirectGuardRoute extends TestAppRoute
    with RouteRedirect<TestAppRoute>, RouteGuard {
  RedirectGuardRoute({required this.shouldRedirect, this.allowPop = false});
  final bool shouldRedirect;
  final bool allowPop;

  @override
  Uri toUri() => Uri.parse('/redirect-guard');

  @override
  FutureOr<TestAppRoute?> redirect() {
    if (shouldRedirect) {
      return SimpleRoute(id: 'redirected');
    }
    return null;
  }

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: const ValueKey('redirect-guard'),
      body: const Text('Redirect + Guard'),
    );
  }

  @override
  List<Object?> get props => [shouldRedirect, allowPop];
}

/// Route with RouteDeeplink + RouteGuard
class DeeplinkGuardRoute extends TestAppRoute with RouteDeepLink, RouteGuard {
  DeeplinkGuardRoute({required this.path, this.allowPop = false});
  final String path;
  final bool allowPop;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;

  @override
  Uri toUri() => Uri.parse('/deeplink-guard/$path');

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: ValueKey('deeplink-guard-$path'),
      body: Text('Deeplink + Guard: $path'),
    );
  }

  @override
  List<Object?> get props => [path, allowPop];
}

/// Route with RouteTransition + RouteDeeplink
class TransitionDeeplinkRoute extends TestAppRoute
    with RouteTransition, RouteDeepLink {
  TransitionDeeplinkRoute({required this.path});
  final String path;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Uri toUri() => Uri.parse('/transition-deeplink/$path');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.sheet(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  void deeplinkHandler(covariant MixinTestCoordinator coordinator, Uri uri) {
    coordinator.push(SimpleRoute(id: 'transition-deeplink-handled'));
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Container(
      key: ValueKey('transition-deeplink-$path'),
      height: 300,
      color: Colors.blue,
      child: Text('Transition + Deeplink: $path'),
    );
  }

  @override
  List<Object?> get props => [path];
}

/// Route with all mixins: RouteTransition + RouteGuard + RouteRedirect + RouteDeeplink
class FullMixinRoute extends TestAppRoute
    with
        RouteTransition,
        RouteGuard,
        RouteRedirect<TestAppRoute>,
        RouteDeepLink {
  FullMixinRoute({
    required this.id,
    this.allowPop = true,
    this.shouldRedirect = false,
  });
  final String id;
  final bool allowPop;
  final bool shouldRedirect;

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Uri toUri() => Uri.parse('/full-mixin/$id');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    covariant MixinTestCoordinator coordinator,
  ) {
    return StackTransition.cupertino(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }

  @override
  Future<bool> popGuard() async => allowPop;

  @override
  FutureOr<TestAppRoute?> redirect() {
    if (shouldRedirect) {
      return SimpleRoute(id: 'full-mixin-redirected');
    }
    return null;
  }

  @override
  void deeplinkHandler(covariant MixinTestCoordinator coordinator, Uri uri) {
    coordinator.push(SimpleRoute(id: 'full-mixin-deeplink-$id'));
  }

  @override
  Widget build(
    covariant MixinTestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      key: ValueKey('full-mixin-$id'),
      appBar: AppBar(title: Text('Full Mixin: $id')),
      body: Column(
        children: [
          Text('Allow Pop: $allowPop'),
          Text('Should Redirect: $shouldRedirect'),
          ElevatedButton(
            key: const ValueKey('try-pop'),
            onPressed: () => coordinator.pop(),
            child: const Text('Try Pop'),
          ),
        ],
      ),
    );
  }

  @override
  List<Object?> get props => [id, allowPop, shouldRedirect];
}

// ============================================================================
// Test Coordinator
// ============================================================================

class MixinTestCoordinator extends Coordinator<TestAppRoute> {
  @override
  void defineLayout() {}

  @override
  List<StackPath> get paths => [root];

  @override
  TestAppRoute parseRouteFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return SimpleRoute(id: 'home');

    return switch (segments) {
      ['simple', final id] => SimpleRoute(id: id),
      ['material-transition'] => MaterialTransitionRoute(),
      ['cupertino-transition'] => CupertinoTransitionRoute(),
      ['dialog-transition'] => DialogTransitionRoute(),
      ['sheet-transition'] => SheetTransitionRoute(),
      ['guarded-pop'] => GuardedPopRoute(),
      ['confirmation-guard'] => ConfirmationGuardRoute(),
      ['redirect', final targetId] => BasicRedirectRoute(targetId: targetId),
      ['async-redirect', final targetId] => AsyncRedirectRoute(
        targetId: targetId,
      ),
      ['auth-redirect'] => AuthRedirectRoute(isAuthenticated: false),
      ['login'] => LoginRoute(),
      ['chain-redirect', final step] => ChainRedirectRoute(
        step: int.parse(step),
      ),
      ['deeplink', 'push', final path] => PushDeeplinkRoute(path: path),
      ['deeplink', 'replace', final path] => ReplaceDeeplinkRoute(path: path),
      ['deeplink', 'custom', final path] => CustomDeeplinkRoute(path: path),
      ['deeplink', 'async-custom', final path] => AsyncCustomDeeplinkRoute(
        path: path,
      ),
      ['transition-guard'] => TransitionGuardRoute(),
      ['redirect-guard'] => RedirectGuardRoute(shouldRedirect: false),
      ['deeplink-guard', final path] => DeeplinkGuardRoute(path: path),
      ['transition-deeplink', final path] => TransitionDeeplinkRoute(
        path: path,
      ),
      ['full-mixin', final id] => FullMixinRoute(id: id),
      _ => SimpleRoute(id: 'home'),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('RouteTransition Mixin Tests', () {
    testWidgets('Material transition route renders correctly', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(MaterialTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('material-transition')), findsOneWidget);
      expect(find.text('Material Page'), findsOneWidget);
    });

    testWidgets('Cupertino transition route renders correctly', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(CupertinoTransitionRoute());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cupertino-transition')),
        findsOneWidget,
      );
      expect(find.text('Cupertino Page'), findsOneWidget);
    });

    testWidgets('Dialog transition route renders as dialog', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(DialogTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog-transition')), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Sheet transition route renders as bottom sheet', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(SheetTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sheet-transition')), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('Dialog transition can be closed and returns to previous', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Should start with home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);

      coordinator.push(DialogTransitionRoute());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog-transition')), findsOneWidget);

      // Close the dialog
      await tester.tap(find.byKey(const ValueKey('dialog-close')));
      await tester.pumpAndSettle();

      // Should be back to home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });
  });

  group('RouteGuard Mixin Tests', () {
    testWidgets('Guard prevents pop when allowPop is false', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(GuardedPopRoute(allowPop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Try to pop
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should still be on guarded page
      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);
      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('Guard allows pop when allowPop is true', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(GuardedPopRoute(allowPop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);

      // Try to pop
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      // Should be back to home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('Guard is called during pop', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final guardRoute = ConfirmationGuardRoute(showConfirmation: true);
      coordinator.push(guardRoute);
      await tester.pumpAndSettle();

      expect(guardRoute.wasConfirmationShown, isFalse);

      // Try to pop - this will trigger the guard
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(guardRoute.wasConfirmationShown, isTrue);
    });

    testWidgets('Async guard waits for completion', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push guard with delay
      coordinator.push(
        GuardedPopRoute(
          allowPop: true,
          popDelay: const Duration(milliseconds: 100),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guarded-pop')), findsOneWidget);

      // Pop - await the guard
      coordinator.pop();
      await tester.pumpAndSettle();

      // Should eventually return to home
      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });
  });

  group('RouteRedirect Mixin Tests', () {
    testWidgets('Basic redirect navigates to target route', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(BasicRedirectRoute(targetId: 'redirected-target'));
      await tester.pumpAndSettle();

      // Should show target route, not redirect route
      expect(
        find.byKey(const ValueKey('simple-redirected-target')),
        findsOneWidget,
      );
      expect(find.text('Simple: redirected-target'), findsOneWidget);
    });

    testWidgets('Async redirect waits and navigates', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(
        AsyncRedirectRoute(
          targetId: 'async-target',
          delay: const Duration(milliseconds: 50),
        ),
      );
      await tester.pumpAndSettle();

      // Should show target route after async delay
      expect(find.byKey(const ValueKey('simple-async-target')), findsOneWidget);
    });

    testWidgets('Auth redirect redirects unauthenticated users', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(AuthRedirectRoute(isAuthenticated: false));
      await tester.pumpAndSettle();

      // Should redirect to login page
      expect(find.byKey(const ValueKey('login')), findsOneWidget);
    });

    testWidgets('Auth redirect allows authenticated users', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(AuthRedirectRoute(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Should show protected content
      expect(find.byKey(const ValueKey('auth-redirect')), findsOneWidget);
      expect(find.text('Protected Content'), findsOneWidget);
    });

    testWidgets('Chain redirect follows through multiple redirects', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      coordinator.push(ChainRedirectRoute(step: 1));
      await tester.pumpAndSettle();

      // Should resolve to final route after chain: 1 -> 2 -> 3 -> SimpleRoute('final')
      expect(find.byKey(const ValueKey('simple-final')), findsOneWidget);
    });
  });

  group('RouteDeeplink Mixin Tests', () {
    testWidgets('Push strategy adds to existing stack', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push some routes first
      coordinator.push(SimpleRoute(id: 'first'));
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Push deeplink
      coordinator.push(PushDeeplinkRoute(path: 'test'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThan(stackLengthBefore));
      expect(find.byKey(const ValueKey('push-deeplink-test')), findsOneWidget);
    });

    testWidgets('Replace strategy clears and replaces stack', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push some routes first
      coordinator.push(SimpleRoute(id: 'one'));
      await tester.pumpAndSettle();
      coordinator.push(SimpleRoute(id: 'two'));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, greaterThan(1));

      // Use recoverRouteFromUri for replace behavior
      await coordinator.recoverRouteFromUri(
        Uri.parse('/deeplink/replace/replaced'),
      );
      await tester.pumpAndSettle();

      // Stack should be cleared
      expect(coordinator.root.stack.length, 1);
      expect(
        find.byKey(const ValueKey('replace-deeplink-replaced')),
        findsOneWidget,
      );
    });

    testWidgets('Custom strategy calls deeplinkHandler', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final customRoute = CustomDeeplinkRoute(path: 'handled');
      coordinator.recover(customRoute);
      await tester.pumpAndSettle();

      // Handler should navigate to custom handled route
      expect(
        find.byKey(const ValueKey('simple-custom-handled-handled')),
        findsOneWidget,
      );
    });

    testWidgets('Async custom handler completes', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      final asyncRoute = AsyncCustomDeeplinkRoute(path: 'async');

      await tester.runAsync(() async {
        await coordinator.recover(asyncRoute);

        // The recover method doesn't await async deeplinkHandler,
        // so we need to wait for it manually (50ms delay in handler + buffer)
        await tester.pumpAndSettle();

        expect(asyncRoute.handlerCompleted, isTrue);
        expect(coordinator.root.activeRoute, isA<SimpleRoute>());
        expect(
          (coordinator.root.activeRoute as SimpleRoute).id,
          'async-custom-async',
        );
      });
    });
  });

  group('Combined Mixins Tests', () {
    testWidgets('TransitionGuardRoute respects both transition and guard', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push route that blocks popping
      coordinator.push(TransitionGuardRoute(allowPop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('transition-guard')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Try pop - should be blocked
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
      expect(find.byKey(const ValueKey('transition-guard')), findsOneWidget);
    });

    testWidgets('TransitionGuardRoute allows pop when guard returns true', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push route that allows popping
      coordinator.push(TransitionGuardRoute(allowPop: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('transition-guard')), findsOneWidget);

      // Try pop - should succeed
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('RedirectGuardRoute combines redirect and guard', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push route that redirects
      coordinator.push(
        RedirectGuardRoute(shouldRedirect: true, allowPop: false),
      );
      await tester.pumpAndSettle();

      // Should redirect to SimpleRoute
      expect(find.byKey(const ValueKey('simple-redirected')), findsOneWidget);
    });

    testWidgets('DeeplinkGuardRoute combines deeplink and guard', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push deeplink guard route
      coordinator.push(DeeplinkGuardRoute(path: 'test', allowPop: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('deeplink-guard-test')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Try pop - should be blocked
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('TransitionDeeplinkRoute combines transition and deeplink', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Use recover to trigger custom deep link handling
      coordinator.recover(TransitionDeeplinkRoute(path: 'combo'));
      await tester.pumpAndSettle();

      // Custom handler navigates to different route
      expect(
        find.byKey(const ValueKey('simple-transition-deeplink-handled')),
        findsOneWidget,
      );
    });

    testWidgets('FullMixinRoute works with all mixins together', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push full mixin route that doesn't redirect and allows pop
      coordinator.push(
        FullMixinRoute(id: 'full', allowPop: true, shouldRedirect: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('full-mixin-full')), findsOneWidget);
      expect(find.text('Allow Pop: true'), findsOneWidget);

      // Pop should work
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });

    testWidgets('FullMixinRoute redirect takes priority', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push full mixin route that redirects
      coordinator.push(FullMixinRoute(id: 'redirecting', shouldRedirect: true));
      await tester.pumpAndSettle();

      // Should redirect
      expect(
        find.byKey(const ValueKey('simple-full-mixin-redirected')),
        findsOneWidget,
      );
    });

    testWidgets('FullMixinRoute deeplink handler works with recover', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Use recover to trigger custom deep link handling
      coordinator.recover(FullMixinRoute(id: 'deeplink-test'));
      await tester.pumpAndSettle();

      // Custom handler navigates to deeplink route
      expect(
        find.byKey(const ValueKey('simple-full-mixin-deeplink-deeplink-test')),
        findsOneWidget,
      );
    });

    testWidgets('FullMixinRoute guard blocks pop when configured', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push full mixin route that blocks pop
      coordinator.push(
        FullMixinRoute(id: 'blocked', allowPop: false, shouldRedirect: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('full-mixin-blocked')), findsOneWidget);
      final stackLengthBefore = coordinator.root.stack.length;

      // Pop should be blocked
      await tester.tap(find.byKey(const ValueKey('try-pop')));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
      expect(find.byKey(const ValueKey('full-mixin-blocked')), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    testWidgets('Multiple guards in stack are checked correctly', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push multiple guarded routes
      coordinator.push(GuardedPopRoute(allowPop: true));
      await tester.pumpAndSettle();
      coordinator.push(GuardedPopRoute(allowPop: false));
      await tester.pumpAndSettle();

      final stackLengthBefore = coordinator.root.stack.length;

      // Pop should be blocked by second guard
      coordinator.pop();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.length, stackLengthBefore);
    });

    testWidgets('Redirect returning null stays on current route', (
      tester,
    ) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Push redirect that returns null (authenticated)
      coordinator.push(AuthRedirectRoute(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Should stay on auth redirect route, not redirect
      expect(find.byKey(const ValueKey('auth-redirect')), findsOneWidget);
    });

    testWidgets('Transition types are correctly applied', (tester) async {
      final coordinator = MixinTestCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        ),
      );
      await tester.pumpAndSettle();

      // Test each transition type is rendered
      for (final route in [
        MaterialTransitionRoute(),
        CupertinoTransitionRoute(),
        DialogTransitionRoute(),
        SheetTransitionRoute(),
      ]) {
        coordinator.push(route);
        await tester.pumpAndSettle();

        // Pop and reset
        coordinator.pop();
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const ValueKey('simple-home')), findsOneWidget);
    });
  });
}
