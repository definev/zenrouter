// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/src/path/commit.dart';
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

class SelfRedirectRoute extends ComposeRoute with RouteRedirect<ComposeRoute> {
  SelfRedirectRoute(super.id);

  int redirectCalls = 0;

  @override
  FutureOr<ComposeRoute> redirect() {
    redirectCalls++;
    return this;
  }
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

    test('Mutatable.pushSilently is callable on the shared contract', () async {
      final coordinator = MutatableOnlyCoordinator();
      final Mutatable<ComposeRoute> mutatable = coordinator;
      final route = ComposeRoute('via-contract');

      await mutatable.pushSilently(route);

      expect(coordinator.root.activeRoute, route);
      coordinator.root.reset();
    });
  });

  group('Navigation transactions', () {
    test(
      'serializes concurrent top-level mutations without merging them',
      () async {
        final coordinator = MutatableOnlyCoordinator();
        final first = coordinator.push<Object>(ComposeRoute('a'));
        final second = coordinator.push<Object>(ComposeRoute('b'));

        await pumpEventQueue();

        expect(coordinator.root.stack.map((route) => route.id), ['a', 'b']);
        coordinator.root.reset();
        await Future.wait([first, second]);
      },
    );

    test('publishes one commit for nested coordinator mutations', () async {
      final coordinator = MutatableOnlyCoordinator();
      var notifications = 0;
      coordinator.addListener(() => notifications++);

      await coordinator.runNavigationTransaction(() async {
        await coordinator.pushSilently(ComposeRoute('a'));
        await coordinator.pushSilently(ComposeRoute('b'));
      }, historyIntent: NavigationHistoryIntent.replace);

      expect(notifications, 1);
      expect(coordinator.root.stack.length, 2);
      expect(
        coordinator.lastNavigationCommit,
        isA<NavigationCommit>()
            .having((commit) => commit.revision, 'revision', 1)
            .having(
              (commit) => commit.previousUri,
              'previousUri',
              Uri.parse('/'),
            )
            .having(
              (commit) => commit.currentUri,
              'currentUri',
              Uri.parse('/b'),
            )
            .having(
              (commit) => commit.historyIntent,
              'historyIntent',
              NavigationHistoryIntent.replace,
            ),
      );
      coordinator.root.reset();
    });

    test('a no-op transaction does not publish or leak intent', () async {
      final coordinator = MutatableOnlyCoordinator();
      var notifications = 0;
      coordinator.addListener(() => notifications++);

      await coordinator.runNavigationTransaction(
        () {},
        historyIntent: NavigationHistoryIntent.push,
      );

      expect(notifications, 0);
      expect(coordinator.lastNavigationCommit, isNull);
      expect(
        coordinator.consumeHistoryIntent(),
        NavigationHistoryIntent.automatic,
      );
    });

    test('publishes changed state before rethrowing an error', () async {
      final coordinator = MutatableOnlyCoordinator();
      var notifications = 0;
      coordinator.addListener(() => notifications++);

      await expectLater(
        coordinator.runNavigationTransaction(() async {
          await (coordinator.root as ComposeStackPath).pushSilently(
            ComposeRoute('committed-before-error'),
          );
          throw StateError('transaction failed');
        }, historyIntent: NavigationHistoryIntent.replace),
        throwsA(isA<StateError>()),
      );

      expect(notifications, 1);
      expect(
        coordinator.lastNavigationCommit?.currentUri,
        Uri.parse('/committed-before-error'),
      );
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

    test('recoverUri throws when parse returns null', () async {
      final coordinator = _NullParseCoordinator();
      expect(
        () => coordinator.recoverUri(Uri.parse('/missing')),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('parseRouteFromUri'),
          ),
        ),
      );
    });

    test('recoverUri parses then recovers', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.recoverUri(Uri.parse('/from-uri'));
      await pumpEventQueue();
      expect(coordinator.root.activeRoute?.id, 'from-uri');
      coordinator.root.reset();
    });
  });

  group('Coordinator URI actions', () {
    test('navigateUri parses then navigates', () async {
      final coordinator = FullCapabilityCoordinator();

      await coordinator.navigateUri(Uri.parse('/navigated'));

      expect(coordinator.root.activeRoute?.id, 'navigated');
      coordinator.root.reset();
    });

    test('pushUri waits for the parsed route result', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('base'));

      final result = coordinator.pushUri<String>(Uri.parse('/pushed'));
      await pumpEventQueue();
      final pushedRoute = coordinator.root.activeRoute!;
      expect(pushedRoute.id, 'pushed');

      await coordinator.pop('done');
      expect(await result, 'done');
      coordinator.root.reset();
    });

    test('pushSilentlyUri completes after commit', () async {
      final coordinator = FullCapabilityCoordinator();

      await coordinator.pushSilentlyUri(Uri.parse('/silent'));

      final route = coordinator.root.activeRoute!;
      expect(route.id, 'silent');
      expect(route.onResult.isCompleted, isFalse);
      coordinator.root.reset();
    });

    test('replaceUri parses then replaces', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('old'));

      await coordinator.replaceUri(Uri.parse('/replacement'));

      expect(coordinator.root.stack.map((route) => route.id), ['replacement']);
      coordinator.root.reset();
    });

    test('recoverUri parses then applies deep-link behavior', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('old'));

      await coordinator.recoverUri(Uri.parse('/recovered'));

      expect(coordinator.root.stack.map((route) => route.id), ['recovered']);
      coordinator.root.reset();
    });

    test('throws when no route matches the location', () async {
      final coordinator = _NullParseCoordinator();

      await expectLater(
        coordinator.pushSilentlyUri(Uri.parse('/missing')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('parseRouteFromUri'),
          ),
        ),
      );
    });

    test('pushReplacementUri replaces the current route', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('old'));

      final replacement = coordinator.pushReplacementUri<Object, String>(
        Uri.parse('/replacement'),
        result: 'done',
      );
      await pumpEventQueue();

      expect(coordinator.root.stack.map((route) => route.id), ['replacement']);
      coordinator.root.reset();
      await replacement;
    });

    test(
      'pushReplacement with a deeper stack commits without a Flutter pop',
      () async {
        final coordinator = FullCapabilityCoordinator();
        await coordinator.pushSilently(ComposeRoute('base'));
        await coordinator.pushSilently(ComposeRoute('old'));

        unawaited(
          coordinator.pushReplacement(
            ComposeRoute('replacement'),
            result: 'done',
          ),
        );
        await pumpEventQueue();

        expect(coordinator.root.stack.map((route) => route.id), [
          'base',
          'replacement',
        ]);
        coordinator.root.reset();
      },
    );

    test('pushOrMoveToTopUri moves an existing route to the top', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('first'));
      await coordinator.pushSilently(ComposeRoute('second'));

      await coordinator.pushOrMoveToTopUri(Uri.parse('/first'));

      expect(coordinator.root.stack.map((route) => route.id), [
        'second',
        'first',
      ]);
      coordinator.root.reset();
    });
  });

  group('URI coordinator actions', () {
    test('uri.navigateWith parses then navigates', () async {
      final coordinator = FullCapabilityCoordinator();

      await Uri.parse('/navigated').navigateWith(coordinator);

      expect(coordinator.root.activeRoute?.id, 'navigated');
      coordinator.root.reset();
    });

    test('uri.pushWith waits for the parsed route result', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('base'));

      final Future<String?> result = Uri.parse('/pushed').pushWith(coordinator);
      await pumpEventQueue();
      expect(coordinator.root.activeRoute!.id, 'pushed');

      await coordinator.pop('done');
      expect(await result, 'done');
      coordinator.root.reset();
    });

    test('uri.pushSilentlyWith completes after commit', () async {
      final coordinator = FullCapabilityCoordinator();

      await Uri.parse('/silent').pushSilentlyWith(coordinator);

      final route = coordinator.root.activeRoute!;
      expect(route.id, 'silent');
      expect(route.onResult.isCompleted, isFalse);
      coordinator.root.reset();
    });

    test('uri.replaceWith parses then replaces', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('old'));

      await Uri.parse('/replacement').replaceWith(coordinator);

      expect(coordinator.root.stack.map((route) => route.id), ['replacement']);
      coordinator.root.reset();
    });

    test('uri.recoverWith parses then applies deep-link behavior', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('old'));

      await Uri.parse('/recovered').recoverWith(coordinator);

      expect(coordinator.root.stack.map((route) => route.id), ['recovered']);
      coordinator.root.reset();
    });

    test('uri.pushReplacementWith replaces the current route', () async {
      final coordinator = FullCapabilityCoordinator();
      await coordinator.pushSilently(ComposeRoute('old'));

      final replacement = Uri.parse(
        '/replacement',
      ).pushReplacementWith(coordinator, result: 'done');
      await pumpEventQueue();

      expect(coordinator.root.stack.map((route) => route.id), ['replacement']);
      coordinator.root.reset();
      await replacement;
    });

    test(
      'uri.pushOrMoveToTopWith moves an existing route to the top',
      () async {
        final coordinator = FullCapabilityCoordinator();
        await coordinator.pushSilently(ComposeRoute('first'));
        await coordinator.pushSilently(ComposeRoute('second'));

        await Uri.parse('/first').pushOrMoveToTopWith(coordinator);

        expect(coordinator.root.stack.map((route) => route.id), [
          'second',
          'first',
        ]);
        coordinator.root.reset();
      },
    );

    test('throws when no route matches the location', () async {
      final coordinator = _NullParseCoordinator();

      await expectLater(
        Uri.parse('/missing').pushSilentlyWith(coordinator),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('parseRouteFromUri'),
          ),
        ),
      );
    });
  });

  group('Shared contracts', () {
    test('StackMutatable implements Mutatable and Navigatable', () {
      final path = ComposeStackPath();
      expect(path, isA<Mutatable>());
      expect(path, isA<Navigatable>());
      expect(path, isA<StackCommit>());
    });
  });

  group('Coordinator resolves redirects once', () {
    test(
      'pushOrMoveToTop does not re-enter path redirect resolution',
      () async {
        final coordinator = FullCapabilityCoordinator();
        final route = SelfRedirectRoute('once');

        await coordinator.pushOrMoveToTop(route);

        expect(route.redirectCalls, 1);
        expect(coordinator.root.activeRoute, route);
        coordinator.root.reset();
      },
    );

    test('navigate does not re-enter path redirect resolution', () async {
      final coordinator = FullCapabilityCoordinator();
      final route = SelfRedirectRoute('once');

      await coordinator.navigate(route);

      expect(route.redirectCalls, 1);
      expect(coordinator.root.activeRoute, route);
      coordinator.root.reset();
    });

    test('push does not re-enter path redirect resolution', () async {
      final coordinator = FullCapabilityCoordinator();
      final route = SelfRedirectRoute('once');

      unawaited(coordinator.push(route));
      await pumpEventQueue();

      expect(route.redirectCalls, 1);
      expect(coordinator.root.activeRoute, route);
      coordinator.root.reset();
    });

    test('pushSilently does not re-enter path redirect resolution', () async {
      final coordinator = FullCapabilityCoordinator();
      final route = SelfRedirectRoute('once');

      await coordinator.pushSilently(route);

      expect(route.redirectCalls, 1);
      expect(coordinator.root.activeRoute, route);
      coordinator.root.reset();
    });

    test(
      'pushReplacement does not re-enter path redirect resolution',
      () async {
        final coordinator = FullCapabilityCoordinator();
        final route = SelfRedirectRoute('once');

        unawaited(coordinator.pushReplacement(route));
        await pumpEventQueue();

        expect(route.redirectCalls, 1);
        expect(coordinator.root.activeRoute, route);
        coordinator.root.reset();
      },
    );

    test('path-level navigate still resolves redirects itself', () async {
      final path = ComposeStackPath();
      final route = SelfRedirectRoute('path');

      await path.navigate(route);

      expect(route.redirectCalls, 1);
      expect(path.activeRoute, route);
      path.reset();
    });
  });
}

class _NullParseCoordinator extends FullCapabilityCoordinator {
  @override
  FutureOr<ComposeRoute?> parseRouteFromUri(Uri uri) => null;
}
