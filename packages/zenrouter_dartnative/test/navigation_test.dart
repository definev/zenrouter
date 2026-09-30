import 'dart:async';

import 'package:test/test.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative_core.dart';
import 'package:zenrouter_dartnative/src/session.dart';

class TestRoute extends RouteUri {
  TestRoute(this.name, {this.parentLayoutKey});
  final String name;
  @override
  final Object? parentLayoutKey;
  int pops = 0;
  int discards = 0;

  @override
  List<Object?> get props => [name];
  @override
  Uri toUri() => Uri(path: '/$name');
  @override
  void onDidPop(Object? result, CoordinatorCore? coordinator) {
    pops++;
    super.onDidPop(result, coordinator);
  }

  @override
  void onDiscard() {
    discards++;
    super.onDiscard();
  }
}

class GuardedRoute extends TestRoute with RouteGuard {
  GuardedRoute(super.name, this.decision);
  final FutureOr<bool> Function() decision;
  int checks = 0;
  @override
  FutureOr<bool> popGuard() {
    checks++;
    return decision();
  }
}

class RedirectedRoute extends TestRoute with RouteRedirect<TestRoute> {
  RedirectedRoute(this.target) : super('redirect');
  final TestRoute? target;
  @override
  FutureOr<TestRoute?> redirectWith(CoordinatorCore coordinator) => target;
}

class NonRootRoute extends TestRoute implements RootMountable {
  NonRootRoute(super.name);

  @override
  bool get canMountAsRoot => false;
}

class TestCoordinator extends Coordinator<TestRoute> {
  TestCoordinator() : super(initialRoute: TestRoute('home'));
  @override
  TestRoute? parseRouteFromUri(Uri uri) =>
      uri.path == '/missing' ? null : TestRoute(uri.pathSegments.join('/'));
}

class TabRoute extends TestRoute {
  TabRoute(super.name);

  @override
  Object get parentLayoutKey => 'tabs';
}

class GuardedTabRoute extends TabRoute with RouteGuard {
  GuardedTabRoute(super.name, this.decision);

  final FutureOr<bool> Function() decision;
  int checks = 0;

  @override
  FutureOr<bool> popGuard() {
    checks++;
    return decision();
  }
}

class TabsLayoutRoute extends TestRoute with RouteLayoutParent<TestRoute> {
  TabsLayoutRoute() : super('tabs');

  @override
  Object get layoutKey => 'tabs';

  @override
  IndexedStackPath<TestRoute> resolvePath(
    covariant TabsCoordinator coordinator,
  ) => coordinator.tabs;
}

class TabsCoordinator extends Coordinator<TestRoute> {
  TabsCoordinator({List<TestRoute>? tabs})
    : _configuredTabs = tabs,
      super(initialRoute: TabsLayoutRoute()) {
    defineLayoutParent(TabsLayoutRoute.new);
  }

  final List<TestRoute>? _configuredTabs;

  late final tabs = IndexedStackPath<TestRoute>.createWith(
    _configuredTabs ?? [TabRoute('feed'), TabRoute('profile')],
    coordinator: this,
    label: 'tabs',
  );

  @override
  List<StackPath> get paths => [...super.paths, tabs];

  @override
  TestRoute? parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['feed'] => TabRoute('feed'),
    ['profile'] => TabRoute('profile'),
    _ => null,
  };
}

class _DetachedLayoutRoute extends TestRoute with RouteLayoutParent<TestRoute> {
  _DetachedLayoutRoute(super.name, this.layoutKey, this.path);

  @override
  final Object layoutKey;
  final NavigationPath<TestRoute> path;

  @override
  NavigationPath<TestRoute> resolvePath(CoordinatorCore coordinator) => path;
}

class FakeDriver implements PresentationDriver<TestRoute> {
  final stack = <NavigationEntry<TestRoute>>[];
  final callbacks = <Object, void Function(Object?)>{};
  final commands = <String>[];
  Completer<void>? holdNextPresentation;
  Object? failNextPresentation;
  bool duplicatePopCallback = false;

  List<String> get names => stack.map((entry) => entry.route.name).toList();

  @override
  Future<void> mountRoot(NavigationEntry<TestRoute> entry) async {
    commands.add('root:${entry.route.name}');
    expect(stack.length, lessThanOrEqualTo(1));
    stack
      ..clear()
      ..add(entry);
  }

  @override
  Future<void> present(
    NavigationEntry<TestRoute> entry,
    void Function(Object?) onDismissed,
  ) async {
    commands.add('present:${entry.route.name}');
    if (failNextPresentation case final error?) {
      failNextPresentation = null;
      throw error;
    }
    stack.add(entry);
    callbacks[entry.token] = onDismissed;
    final hold = holdNextPresentation;
    holdNextPresentation = null;
    if (hold != null) await hold.future;
  }

  @override
  Future<void> dismiss(NavigationEntry<TestRoute> entry, Object? result) async {
    commands.add('dismiss:${entry.route.name}:$result');
    expect(identical(stack.last, entry), isTrue);
    stack.removeLast();
    callbacks[entry.token]!(result);
    if (duplicatePopCallback) callbacks[entry.token]!(result);
  }

  void systemPop([Object? result]) {
    final entry = stack.removeLast();
    callbacks[entry.token]!(result);
  }
}

void main() {
  group('native indexed paths', () {
    test(
      'coordinator owns tab selection, URI, and one atomic commit',
      () async {
        final coordinator = TabsCoordinator();
        addTearDown(coordinator.dispose);
        var commits = 0;
        coordinator.addListener(() => commits++);

        expect(coordinator.tabs.activeIndex, 0);
        expect(coordinator.currentUri, Uri(path: '/feed'));

        await coordinator.selectIndex(coordinator.tabs, 1);

        expect(coordinator.tabs.activeIndex, 1);
        expect(coordinator.currentUri, Uri(path: '/profile'));
        expect(commits, 1);
        expect(coordinator.root.activeRoute, isA<TabsLayoutRoute>());
      },
    );

    test(
      'tab guard can reject selection without publishing a commit',
      () async {
        final guarded = GuardedTabRoute('feed', () => false);
        final coordinator = TabsCoordinator(
          tabs: [guarded, TabRoute('profile')],
        );
        addTearDown(coordinator.dispose);
        var commits = 0;
        coordinator.addListener(() => commits++);

        await coordinator.selectIndex(coordinator.tabs, 1);

        expect(coordinator.tabs.activeIndex, 0);
        expect(guarded.checks, 1);
        expect(commits, 0);
      },
    );

    test(
      'deep navigation activates its registered parent layout path',
      () async {
        final coordinator = TabsCoordinator();
        addTearDown(coordinator.dispose);

        await coordinator.navigate(TabRoute('profile'));

        expect(coordinator.tabs.activeIndex, 1);
        expect(coordinator.currentUri, Uri(path: '/profile'));
        expect(coordinator.root.stack, hasLength(1));
        expect(coordinator.root.activeRoute, isA<TabsLayoutRoute>());
      },
    );

    test('replace validates then rebuilds the layout hierarchy', () async {
      final coordinator = TabsCoordinator();
      addTearDown(coordinator.dispose);

      await coordinator.selectIndex(coordinator.tabs, 1);
      final oldLayout = coordinator.root.activeRoute;
      await coordinator.replace(TabRoute('profile'));

      expect(coordinator.tabs.activeIndex, 1);
      expect(coordinator.currentUri, Uri(path: '/profile'));
      expect(coordinator.root.activeRoute, isA<TabsLayoutRoute>());
      expect(identical(coordinator.root.activeRoute, oldLayout), isFalse);
    });

    test('branched reset resets selection and every child stack', () async {
      final coordinator = TabsCoordinator();
      addTearDown(coordinator.dispose);
      final feed = NavigationPath<TestRoute>.create(
        routes: [TestRoute('feed-root'), TestRoute('feed-detail')],
      );
      final profile = NavigationPath<TestRoute>.create(
        routes: [TestRoute('profile-root'), TestRoute('profile-detail')],
      );
      addTearDown(feed.dispose);
      addTearDown(profile.dispose);
      final branches = BranchedStackPath<TestRoute>.createWith(
        [
          _DetachedLayoutRoute('feed-layout', 'feed-layout', feed),
          _DetachedLayoutRoute('profile-layout', 'profile-layout', profile),
        ],
        coordinator: coordinator,
        label: 'branches',
      );
      addTearDown(branches.dispose);

      await branches.goToBranch(1);
      branches.reset();

      expect(branches.activeBranchIndex, 0);
      expect(feed.stack, isEmpty);
      expect(profile.stack, isEmpty);
    });
  });

  late TestCoordinator coordinator;
  late FakeDriver driver;
  late NavigationSession<TestRoute> session;
  late List<Object> errors;

  setUp(() async {
    coordinator = TestCoordinator();
    driver = FakeDriver();
    errors = [];
    session = NavigationSession(
      coordinator: coordinator,
      driver: driver,
      onError: (error, _) => errors.add(error),
    )..start();
    await session.settled;
  });

  tearDown(() {
    session.dispose();
    coordinator.dispose();
  });

  test('mounts one permanent root and root pop is a no-op', () async {
    expect(driver.names, ['home']);
    expect(await coordinator.tryPop(), isNull);
    await session.settled;
    expect(driver.commands, ['root:home']);
  });

  test(
    'push mount never waits for result; programmatic pop completes once',
    () async {
      final route = TestRoute('detail');
      final result = coordinator.push<String>(route);
      await Future<void>.delayed(Duration.zero);
      await session.settled;
      expect(driver.names, ['home', 'detail']);
      driver.duplicatePopCallback = true;
      await coordinator.pop('saved');
      await session.settled;
      expect(await result, 'saved');
      expect(route.pops, 1);
      expect(route.discards, 1);
      expect(driver.names, ['home']);
      expect(errors, isEmpty);
    },
  );

  test(
    'native pop of equal URI removes exact entry and returns result',
    () async {
      final first = TestRoute('same');
      final second = TestRoute('same');
      await coordinator.pushSilently(first);
      final result = coordinator.push<int>(second);
      await Future<void>.delayed(Duration.zero);
      await session.settled;
      expect(driver.names, ['home', 'same', 'same']);
      final oldEntry = driver.stack.last;
      driver.systemPop(42);
      await session.settled;
      expect(await result, 42);
      expect(identical(coordinator.root.activeRoute, first), isTrue);
      expect(second.pops, 1);
      expect(first.pops, 0);
      driver.callbacks[oldEntry.token]!(100); // Late duplicate.
      await session.settled;
      expect(second.pops, 1);
      expect(driver.commands.where((c) => c.startsWith('dismiss:')), isEmpty);
    },
  );

  test('blocked guard leaves both stacks unchanged', () async {
    final route = GuardedRoute('edit', () => false);
    await coordinator.pushSilently(route);
    await session.settled;
    expect(await session.requestPop(session.entries.last), isFalse);
    await session.settled;
    expect(driver.names, ['home', 'edit']);
    expect(route.checks, 1);
    expect(route.pops, 0);
  });

  test(
    'double back awaits one asynchronous guard and one native pop',
    () async {
      final decision = Completer<bool>();
      final route = GuardedRoute('edit', () => decision.future);
      await coordinator.pushSilently(route);
      await session.settled;
      final entry = session.entries.last;
      final first = session.requestPop(entry, 'done');
      final second = session.requestPop(entry, 'other');
      expect(identical(first, second), isTrue);
      decision.complete(true);
      expect(await first, isTrue);
      await session.settled;
      expect(route.checks, 1);
      expect(route.resultValue, 'done');
      expect(driver.names, ['home']);
      expect(await session.requestPop(entry), isFalse);
    },
  );

  test(
    'top replacement preserves root and completes old route result',
    () async {
      final old = TestRoute('old');
      final oldResult = coordinator.push<String>(old);
      await Future<void>.delayed(Duration.zero);
      await session.settled;
      final replacement = TestRoute('new');
      final newResult = coordinator.pushReplacement<String, String>(
        replacement,
        result: 'replaced',
      );
      await Future<void>.delayed(Duration.zero);
      await session.settled;
      expect(await oldResult, 'replaced');
      expect(driver.names, ['home', 'new']);
      await coordinator.pop('finished');
      await session.settled;
      expect(await newResult, 'finished');
      expect(old.pops, 1);
    },
  );

  test('guard rejects top replacement without pushing a new screen', () async {
    await coordinator.pushSilently(GuardedRoute('edit', () => false));
    await session.settled;
    expect(await coordinator.pushReplacement(TestRoute('new')), isNull);
    await session.settled;
    expect(driver.names, ['home', 'edit']);
  });

  test('reset drains native suffix then swaps the root', () async {
    final first = TestRoute('one');
    final second = TestRoute('two');
    await coordinator.pushSilently(first);
    await coordinator.pushSilently(second);
    await session.settled;
    await coordinator.replace(TestRoute('login'));
    await session.settled;
    expect(driver.names, ['login']);
    expect(driver.commands.sublist(driver.commands.length - 3), [
      'dismiss:two:null',
      'dismiss:one:null',
      'root:login',
    ]);
    expect(first.discards, 1);
    expect(second.discards, 1);
  });

  test(
    'root pushReplacement changes root without a phantom native push',
    () async {
      unawaited(coordinator.pushReplacement(TestRoute('login')));
      await Future<void>.delayed(Duration.zero);
      await session.settled;
      expect(driver.names, ['login']);
      expect(driver.commands, ['root:home', 'root:login']);
    },
  );

  test('non-root presentation can be pushed but cannot become root', () async {
    final modal = NonRootRoute('sheet');
    await coordinator.pushSilently(modal);
    await session.settled;
    expect(driver.names, ['home', 'sheet']);
    await coordinator.pop();
    await session.settled;

    final replacement = NonRootRoute('dialog');
    await expectLater(coordinator.replace(replacement), throwsUnsupportedError);
    expect(coordinator.root.stack.map((r) => r.name), ['home']);
    await expectLater(
      coordinator.pushReplacement(NonRootRoute('sheet')),
      throwsUnsupportedError,
    );
    expect(coordinator.root.stack.map((r) => r.name), ['home']);
    await session.settled;
    expect(driver.names, ['home']);
  });

  test('navigate pops back to an existing route', () async {
    final first = TestRoute('one');
    await coordinator.pushSilently(first);
    await coordinator.pushSilently(TestRoute('two'));
    await session.settled;
    await coordinator.navigate(TestRoute('one'));
    await session.settled;
    expect(driver.names, ['home', 'one']);
    expect(identical(coordinator.root.activeRoute, first), isTrue);
  });

  test('redirect and URI recovery use core semantics', () async {
    await coordinator.pushSilently(RedirectedRoute(TestRoute('target')));
    await session.settled;
    expect(driver.names, ['home', 'target']);
    await coordinator.pushSilently(RedirectedRoute(null));
    await coordinator.recoverUri(Uri.parse('/login'));
    await session.settled;
    expect(driver.names, ['login']);
    await expectLater(
      coordinator.pushSilentlyUri(Uri.parse('/missing')),
      throwsStateError,
    );
    expect(driver.names, ['login']);
  });

  test(
    'unsupported layout/reorder and reused entries fail before mutation',
    () async {
      final first = TestRoute('one');
      await coordinator.pushSilently(first);
      await coordinator.pushSilently(TestRoute('two'));
      await session.settled;
      await expectLater(
        coordinator.pushOrMoveToTop(TestRoute('one')),
        throwsUnsupportedError,
      );
      await expectLater(
        coordinator.replace(TestRoute('bad', parentLayoutKey: 'x')),
        throwsUnsupportedError,
      );
      await expectLater(coordinator.pushReplacement(first), throwsStateError);
      await expectLater(coordinator.pushSilently(first), throwsStateError);
      await session.settled;
      expect(driver.names, ['home', 'one', 'two']);
      await coordinator.pop();
      await coordinator.pop();
      await session.settled;
      await expectLater(coordinator.pushSilently(first), throwsStateError);
      expect(first.pops, 1);
    },
  );

  test('burst commits coalesce while push is mounting', () async {
    final mounted = Completer<void>();
    driver.holdNextPresentation = mounted;
    await coordinator.pushSilently(TestRoute('one'));
    await Future<void>.delayed(Duration.zero);
    await coordinator.pushSilently(TestRoute('two'));
    await coordinator.replace(TestRoute('login'));
    mounted.complete();
    await session.settled;
    expect(driver.names, ['login']);
    expect(driver.commands, [
      'root:home',
      'present:one',
      'dismiss:one:null',
      'root:login',
    ]);
  });

  test(
    'native pop racing a committed push does not resurrect dismissed entry',
    () async {
      final first = TestRoute('one');
      await coordinator.pushSilently(first);
      await session.settled;
      // Inside the transaction, native pop arrives before the pending commit.
      await coordinator.runNavigationTransaction(() async {
        await coordinator.pushSilently(TestRoute('two'));
        driver.systemPop('native');
      });
      await session.settled;
      expect(driver.names, ['home', 'two']);
      expect(coordinator.root.stack.map((r) => r.name), ['home', 'two']);
      expect(first.pops, 1);
      expect(first.resultValue, 'native');
      expect(driver.commands.where((c) => c == 'present:one').length, 1);
    },
  );

  test(
    'driver failure is reported once and stops subsequent commands',
    () async {
      driver.failNextPresentation = StateError('bridge unavailable');
      await coordinator.pushSilently(TestRoute('one'));
      await expectLater(session.settled, throwsStateError);
      expect(errors, hasLength(1));
      await coordinator.pushSilently(TestRoute('two'));
      await Future<void>.delayed(Duration.zero);
      expect(driver.commands, ['root:home', 'present:one']);
      expect(await session.requestPop(session.entries.last), isFalse);
    },
  );

  test('detach ignores late callbacks and further commits', () async {
    final route = TestRoute('one');
    await coordinator.pushSilently(route);
    await session.settled;
    session.dispose();
    driver.systemPop('late');
    await coordinator.pushSilently(TestRoute('two'));
    await Future<void>.delayed(Duration.zero);
    expect(route.pops, 0);
    expect(driver.commands, ['root:home', 'present:one']);
    expect(() => session.start(), throwsStateError);
  });

  test('a thrown guard releases back request so the user can retry', () async {
    var fail = true;
    final route = GuardedRoute('edit', () {
      if (fail) throw StateError('validation failed');
      return true;
    });
    await coordinator.pushSilently(route);
    await session.settled;
    final entry = session.entries.last;
    await expectLater(session.requestPop(entry), throwsStateError);
    expect(driver.names, ['home', 'edit']);
    fail = false;
    expect(await session.requestPop(entry), isTrue);
    await session.settled;
    expect(driver.names, ['home']);
    expect(errors, isEmpty);
  });

  test(
    'native pop bypasses an async guard that has already been bypassed by platform',
    () async {
      final route = GuardedRoute(
        'edit',
        () => throw StateError('must not run'),
      );
      await coordinator.pushSilently(route);
      await session.settled;
      // The platform can already have authorized the gesture via canPop=true.
      driver.systemPop('native');
      await session.settled;
      expect(route.checks, 0);
      expect(route.pops, 1);
      expect(route.resultValue, 'native');
      expect(driver.names, ['home']);
    },
  );

  test('one transaction presents only its final stack', () async {
    final transient = TestRoute('transient');
    await coordinator.runNavigationTransaction(() async {
      await coordinator.pushSilently(transient);
      await coordinator.pop();
      await coordinator.pushSilently(TestRoute('final'));
    });
    await session.settled;
    expect(driver.commands, ['root:home', 'present:final']);
    expect(transient.pops, 1);
  });

  test(
    'dispose during mount stops the command queue after that mount',
    () async {
      final mounted = Completer<void>();
      driver.holdNextPresentation = mounted;
      await coordinator.pushSilently(TestRoute('one'));
      await Future<void>.delayed(Duration.zero);
      await coordinator.pushSilently(TestRoute('two'));
      session.dispose();
      mounted.complete();
      await session.settled;
      expect(driver.commands, ['root:home', 'present:one']);
      expect(errors, isEmpty);
    },
  );
}
