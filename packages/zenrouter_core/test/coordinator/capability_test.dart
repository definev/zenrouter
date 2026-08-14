// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class ComposeRoute extends RouteUri {
  ComposeRoute(this.id, {this.deeplinkStrategy});

  final String id;
  final DeeplinkStrategy? deeplinkStrategy;

  @override
  Uri get identifier => toUri();

  @override
  Uri toUri() => Uri.parse('/$id');

  @override
  Object? get parentLayoutKey => null;

  @override
  List<Object?> get props => [id];
}

class DeeplinkComposeRoute extends ComposeRoute with RouteDeepLink {
  DeeplinkComposeRoute(super.id, {required DeeplinkStrategy strategy})
    : super(deeplinkStrategy: strategy);

  @override
  DeeplinkStrategy get deeplinkStrategy => super.deeplinkStrategy!;

  @override
  FutureOr<void> deeplinkHandler(
    covariant CoordinatorCore coordinator,
    Uri uri,
  ) {
    customHandlerCalled = true;
  }

  bool customHandlerCalled = false;
}

mixin _TestListenable {
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}

class ComposeStackPath extends StackPath<ComposeRoute>
    with _TestListenable, StackMutatable<ComposeRoute> {
  ComposeStackPath({super.coordinator}) : super([]);

  @override
  ComposeRoute? get activeRoute => stack.isEmpty ? null : stack.last;

  @override
  PathKey get pathKey => const PathKey('compose');

  @override
  void reset() => clear();

  @override
  Future<void> activateRoute(ComposeRoute route) => pushSilently(route);
}

/// Mutatable-only: can push/pop/replace, no navigate/recover.
class MutatableOnlyCoordinator extends CoordinatorCore<ComposeRoute>
    with
        _TestListenable,
        CoordinatorLayoutCore<ComposeRoute>,
        CoordinatorMutatable<ComposeRoute> {
  late final ComposeStackPath _root = ComposeStackPath(coordinator: this);

  @override
  StackPath<ComposeRoute> get root => _root;

  @override
  FutureOr<ComposeRoute?> parseRouteFromUri(Uri uri) =>
      ComposeRoute(uri.pathSegments.isEmpty ? 'home' : uri.pathSegments.last);
}

/// Full stack operations + recover for deep-link handler tests.
class FullCapabilityCoordinator extends CoordinatorCore<ComposeRoute>
    with
        _TestListenable,
        CoordinatorLayoutCore<ComposeRoute>,
        CoordinatorNavigatable<ComposeRoute>,
        CoordinatorMutatable<ComposeRoute>,
        CoordinatorRecoverable<ComposeRoute> {
  late final ComposeStackPath _root = ComposeStackPath(coordinator: this);

  @override
  StackPath<ComposeRoute> get root => _root;

  @override
  FutureOr<ComposeRoute?> parseRouteFromUri(Uri uri) {
    final id = uri.pathSegments.isEmpty ? 'home' : uri.pathSegments.last;
    return ComposeRoute(id);
  }
}

void main() {
  group('Compose-your-own coordinator', () {
    test('MutatableOnlyCoordinator can push and pop', () async {
      final coordinator = MutatableOnlyCoordinator();
      // push futures complete on pop/clear — do not await them here
      unawaited(coordinator.push(ComposeRoute('a')));
      await pumpEventQueue();
      unawaited(coordinator.push(ComposeRoute('b')));
      await pumpEventQueue();
      expect(coordinator.root.stack.length, 2);

      await coordinator.pop();
      expect(coordinator.root.stack.length, 1);
      expect(coordinator.root.activeRoute?.id, 'a');

      // Complete remaining push future so the test zone can finish
      coordinator.root.reset();
    });

    test('MutatableOnlyCoordinator is not Navigatable', () {
      final coordinator = MutatableOnlyCoordinator();
      expect(coordinator, isA<Mutatable>());
      expect(coordinator, isNot(isA<Navigatable>()));
      expect(coordinator, isNot(isA<CoordinatorRecoverable>()));
    });

    test('FullCapabilityCoordinator implements shared contracts', () {
      final coordinator = FullCapabilityCoordinator();
      expect(coordinator, isA<Navigatable>());
      expect(coordinator, isA<Mutatable>());
      expect(coordinator, isA<CoordinatorRecoverable>());
    });

    test('navigate completes after commit without waiting for pop', () async {
      final coordinator = FullCapabilityCoordinator();
      final route = ComposeRoute('committed');

      await coordinator.navigate(route);

      expect(coordinator.root.activeRoute, route);
      expect(route.onResult.isCompleted, isFalse);
      coordinator.root.reset();
    });

    test('pushSilently completes after commit without a pop result', () async {
      final coordinator = MutatableOnlyCoordinator();
      final route = ComposeRoute('committed');

      await coordinator.pushSilently(route);

      expect(coordinator.root.activeRoute, route);
      expect(route.onResult.isCompleted, isFalse);
      coordinator.root.reset();
    });
  });

  group('CoordinatorRecoverable.defineDeeplinkHandler', () {
    test('overrides replace strategy', () async {
      final coordinator = FullCapabilityCoordinator();
      var customReplaceCalled = false;

      coordinator.defineDeeplinkHandler(DeeplinkStrategy.replace, (c, route) {
        customReplaceCalled = true;
        unawaited(c.push(route));
      });

      unawaited(coordinator.push(ComposeRoute('base')));
      await pumpEventQueue();
      expect(coordinator.root.stack.length, 1);

      await coordinator.recover(ComposeRoute('deep'));
      await pumpEventQueue();

      expect(customReplaceCalled, isTrue);
      // Custom handler used push instead of replace → stack grew
      expect(coordinator.root.stack.length, 2);
      expect(coordinator.root.activeRoute?.id, 'deep');

      coordinator.root.reset();
    });

    test('awaits asynchronous registered handlers', () async {
      final coordinator = FullCapabilityCoordinator();
      final handlerGate = Completer<void>();
      var recoveryCompleted = false;

      coordinator.defineDeeplinkHandler(
        DeeplinkStrategy.replace,
        (c, route) async => handlerGate.future,
      );

      final recovery = coordinator.recover(ComposeRoute('deep')).then((_) {
        recoveryCompleted = true;
      });
      await pumpEventQueue();
      expect(recoveryCompleted, isFalse);

      handlerGate.complete();
      await recovery;
      expect(recoveryCompleted, isTrue);
    });

    test('propagates registered handler failures', () async {
      final coordinator = FullCapabilityCoordinator();

      coordinator.defineDeeplinkHandler(
        DeeplinkStrategy.replace,
        (c, route) async => throw StateError('handler failed'),
      );

      await expectLater(
        coordinator.recover(ComposeRoute('deep')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'handler failed',
          ),
        ),
      );
    });

    test('custom strategy still uses RouteDeepLink.deeplinkHandler', () async {
      final coordinator = FullCapabilityCoordinator();
      final route = DeeplinkComposeRoute(
        'custom',
        strategy: DeeplinkStrategy.custom,
      );

      await coordinator.recover(route);
      expect(route.customHandlerCalled, isTrue);
    });

    test('push strategy completes once the route is committed', () async {
      final coordinator = FullCapabilityCoordinator();
      final route = DeeplinkComposeRoute(
        'pushed',
        strategy: DeeplinkStrategy.push,
      );

      await coordinator.recover(route);

      expect(coordinator.root.activeRoute, route);
      expect(route.onResult.isCompleted, isFalse);
      coordinator.root.reset();
    });

    test('recoverRouteFromUri throws when parse returns null', () async {
      final coordinator = _NullParseCoordinator();
      expect(
        () => coordinator.recoverRouteFromUri(Uri.parse('/missing')),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('parseRouteFromUri'),
          ),
        ),
      );
    });

    test('recoverRouteFromUri parses then recovers', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.recoverRouteFromUri(Uri.parse('/from-uri'));
      await pumpEventQueue();
      expect(coordinator.root.activeRoute?.id, 'from-uri');
      coordinator.root.reset();
    });
  });

  group('Shared contracts', () {
    test('StackMutatable implements Mutatable and Navigatable', () {
      final path = ComposeStackPath();
      expect(path, isA<Mutatable>());
      expect(path, isA<Navigatable>());
    });
  });
}

class _NullParseCoordinator extends FullCapabilityCoordinator {
  @override
  FutureOr<ComposeRoute?> parseRouteFromUri(Uri uri) => null;
}
