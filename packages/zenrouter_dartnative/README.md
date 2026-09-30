# ZenRouter DartNative

A native presentation stack driven by `zenrouter_core`, plus platform-clean
indexed and branched paths for persistent layouts. This package uses DartNative
widgets and native presentation primitives, not Flutter's Router,
Navigator.pages, path classes, or layout builders.
It is intentionally outside the repository's Flutter pub workspace. No changes
to the core routing engine or existing Flutter adapter are required.

## Installation

Add `zenrouter_dartnative` to your DartNative app's `pubspec.yaml`:

```yaml
dependencies:
  dartnative: ^1.0.0
  zenrouter_dartnative: ^0.1.0
```

Run **`dn pub get`**, not `flutter pub get`. DartNative's command resolves its framework and platform bindings from the installed SDK.

```dart
import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri(path: '/');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: const Text('Hello from native navigation'),
  );
}

class AppCoordinator extends Coordinator<AppRoute> {
  AppCoordinator() : super(initialRoute: HomeRoute());

  @override
  AppRoute? parseRouteFromUri(Uri uri) => uri.path == '/' ? HomeRoute() : null;
}

// After DartNativePluginRegistrant.registerAll():
void mountApp() {
  final coordinator = AppCoordinator();
  runApp(CoordinatorView<AppRoute>(
    coordinator: coordinator,
    onError: (error, stack) => dnLog('$error\n$stack'),
  ));
}
```

Routes use the core `RouteTarget` with the adapter's `RouteUnique` mixin.
Their `build(coordinator, context)` method receives the coordinator directly.

Inside a child widget, use `CoordinatorScope.of<AppRoute>(context)` to obtain its
coordinator. The scope is installed in **every** native screen, since pushed
screens do not share the root's widget ancestry. The example uses a regular
coordinator with `parseRouteFromUri`, dynamic parameters, guards, and a
not-found route. Its Barista feature coordinator demonstrates coordinators used as route
modules and nested tab layouts.

## Supported contract

- One persistent native root plus an ordered stack of route presentations.
- `push<R>` / `pop(result)`, `pushSilently`, `pushReplacement`, `replace`.
- `navigate` to push or pop back to an existing destination; redirects and URI
  actions from core. `recoverUri` is routing, not an OS incoming-link listener.
- Distinct route instances with equal values/URIs retain separate lifecycles.
- Native Back acknowledges the exact presented entry; results complete once.
- `RouteGuard`, asynchronous pop decisions, reactive `canPopListenable`.
- A single root route is never popped. Android root Back optionally calls
  `onExitRequested`, defaulting to `SystemNavigator.pop`, after its guard allows.
- Stable built-in adapter: native screen. Experimental convenience adapters:
  detent sheet, content-sized bottom sheet, centered dialog, and the iOS
  keyboard overlay.
- App/plugin-defined presentations implement one open interface; routing and
  synchronization code do not switch on presentation type.
- `NavigationPath`, `IndexedStackPath`, and `BranchedStackPath`
  provide layout topology without importing the Flutter package.
- `RouteLayout` and `IndexedStackPathBuilder` keep the coordinator as the
  source of truth while the application chooses its DartNative shell widgets.
- `CoordinatorModular` composes feature coordinators as route modules. Modules
  share the parent's root presentation stack and navigation transactions.

Choose presentation per route:

```dart
class EditSheetRoute extends AppRoute {
  @override
  Presentation get presentation =>
      const ExperimentalModalSheetPresentation(
        detent: SheetDetent.medium,
      );

  @override
  Uri toUri() => Uri(path: '/edit');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) =>
      const EditPanel();
}
```

For a custom native/plugin container, implement `Presentation` and return
a `PresentationHandle` from `present(context)`. The adapter must render
`context.builder`, expose a result Future when the native primitive has one,
and make `handle.dismiss(result)` request removal. The router merges the result
Future, `PopScope.didPop`, and disposal of the builder subtree, since
presentation primitives may report system dismissal through only one of those
paths. Keep the builder mounted exactly while the presentation is visible. For
interactive or external dismissal, the adapter must ensure at least one signal
fires; otherwise use a controller or native callback to complete `result`.
`context.entryToken` provides identity when equal routes are presented more
than once. Set `canMountAsRoot` only when the route has a meaningful inline
persistent-root representation.

Supply a **fresh, already-resolved** initial route. To resolve an initial URI,
await `coordinator.recoverUri(uri)` before mounting the host. Use fresh instances
for new entries; a route's result completer cannot be reused after removal.
Sheet/dialog/overlay routes cannot be used as the initial route or become root
through `replace`; push them, or give a custom presentation explicit root support.

`push` and `pushReplacement` complete when the route is **removed**, not when it
is presented. `pushSilently` completes at a **logical commit**, which may precede
native presentation. Do not await a pop-result future inside
`runNavigationTransaction`; that blocks later navigation transactions.

## Bottom navigation

Bottom navigation is an indexed layout, not a presentation. The path owns the
selected tab; the widget only renders a snapshot and sends selection intents:

```dart
late final tabs = IndexedStackPath<AppRoute>.createWith(
  [FeedRoute(), ProfileRoute()],
  coordinator: this,
  label: 'tabs',
);

@override
List<StackPath> get paths => [...super.paths, tabs];
```

```dart
IndexedStackPathBuilder<AppRoute>(
  coordinator: coordinator,
  path: coordinator.tabs,
  builder: (_, layout) => Scaffold(
    body: IndexedStack(
      index: layout.activeIndex,
      children: layout.children,
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: layout.activeIndex,
      onTap: (index) => unawaited(layout.selectIndex(index)),
      items: items,
    ),
  ),
)
```

Tab routes override `Type get layout` with their parent layout type, just as in
ZenRouter. `RouteUnique` exposes that type to core through `parentLayoutKey`.
Register a fresh layout constructor with `path.bindLayout(LayoutRoute.new)`
or `defineLayoutParent`, and include every
additional path in `coordinator.paths`. Programmatic selection should use
`coordinator.selectIndex`; URI, guards, commits, and UI then change atomically.
See the example for the complete `RouteLayout` implementation.

## Coordinator as a route module

Use the same `CoordinatorModular` and `RouteModule` contracts as ZenRouter:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  AppCoordinator() : super(initialRoute: StudioLayoutRoute());

  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [BaristaCoordinator(this)];

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
}

class BaristaCoordinator extends Coordinator<AppRoute> {
  BaristaCoordinator(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  AppRoute? parseRouteFromUri(Uri uri) =>
      uri.path == '/barista' ? BaristaRoute() : null;
}
```

Only the standalone coordinator supplies an `initialRoute`. Initialize the
module's parent field before the superclass constructor runs. Include its
additional paths in `paths`; the modular parent aggregates them automatically.
Mount one `CoordinatorView` with the standalone coordinator. Module `push`,
`pop`, `replace`, and indexed selection operate on that shared navigation tree;
`replace` resets sibling paths too. Resolve layout paths through the owning
module when the callback can receive either the parent or a module coordinator.
See `example/lib/app_route.dart` and the feature layouts for this lookup.

For reactive guards backed by DartNative `ValueNotifier` / `ChangeNotifier`,
return `notifier.toListenableMixin()` from `canPopListenable`, matching the
core-compatible listener conversion in ZenRouter.

## Deliberate limits

- The built-in screen defaults to DartNative's standard native
  `slideFromRight` transition. Other DartNative transitions can be configured,
  but the public SDK inspected does not expose transition completion. Mount
  acknowledgement is not animation completion, so version 0.1.0 does not claim
  exact animation sequencing or predictive gesture parity.
- Root replacement drains pushed screens and swaps root content. Top replacement
  is pop-then-push, not an atomic native replacement. Core publishes one logical
  commit, but native presentation is necessarily a sequence of operations.
- No restoration yet. File-based generation is available through
  `zenrouter_file_generator` with `platform: dartnative`; see the example's
  `main_file_router.dart` entry point and the generator README for its limits.
  `pushOrMoveToTop` rejects moving an existing non-top route; use `navigate`.
- Indexed and branched logical paths are supported. Independent physical native
  navigation stacks per branch are not: the inspected DartNative SDK does not
  expose a nested Navigator host. The current tab renderer keeps tab roots
  mounted and sends detail routes to the global native presentation stack.
- Do not mutate/cast exposed paths directly or omit custom paths from
  `coordinator.paths`.
- The host exclusively owns its ordered native presentations: no raw Navigator
  pushes/pops, unmanaged overlays, or nested hosts. Express managed overlays as
  route presentations so result and Back events remain attributable.
- The `Experimental*Presentation` helpers are suitable for
  coordinator-driven dismissal. In the inspected SDK, external sheet/dialog
  dismissal can bypass the returned Future, `PopScope`, and subtree disposal;
  do not rely on scrim/grabber/swipe dismissal to synchronize routing. A custom
  adapter backed by a native dismissal callback is the intended extension path.
- Programmatic coordinator pops always run route guards. A platform dismissal
  that already happened can only be acknowledged; it cannot be retroactively
  vetoed, so custom interactive adapters must integrate the guard decision
  before allowing the native gesture when that behavior matters.
- No native hot-restart replay adoption. Managed PageRoutes intentionally have
  no registered names. Test with cold launches, not restored native history.
- Mount the host for the app lifetime. It does not own/dispose the coordinator
  and cannot unmount then adopt its old native screens. Dispose the host first.
- Native command failure stops synchronization and calls the required `onError`.
  It does **not** roll back already-completed core route results. Cold restart is
  the recovery policy. The confirmation timeout is an error deadline, never an
  animation delay or success fallback.

## Implementation

`Coordinator` supplies a headless root presentation path, native layout
registration, indexed selection, and core navigation mixins. Platform-neutral
path implementations are duplicated locally on purpose so this package never
depends on Flutter.
`NavigationSession` (internal) snapshots paths at coordinator commits,
matches entries by identity, serializes presentation operations, coalesces
bursts, and suppresses late/duplicate native dismissal events. It is tested
through the same driver interface used by the real DartNative host.

The native driver waits for content mount separately from presentation removal.
It merges the result Future in `PresentationHandle`, the wrapped PopScope
callback, and route-subtree disposal into one identity-scoped removal
notification/result. After a logical guarded pop, the wrapper first enables its
PopScope, records the requested result, then calls the handle's dismiss method
and awaits acknowledgement. Each presentation owns its guard listener
subscription and removes it on widget disposal.

Core `onDidPop`/`onDiscard` describe logical lifecycle, which can precede native
widget disposal. Release widget resources in widget `dispose`, not in route
cleanup while the outgoing screen may still be mounted.

## Development

From this directory:

```sh
dn pub get
dn test
dn analyze --no-pub
```

Use the Dart executable bundled with the same Zero SDK as `dn`. Tests import
`zenrouter_dartnative_core.dart` and the internal session, never native widget
implementations; they run on the Dart VM. The real host requires `dn run/build`,
because SDK Dart sources are header stubs for precompiled implementations.

See [example/README.md](example/README.md) for app setup and manual acceptance
checks, and [VERIFICATION.md](VERIFICATION.md) for what has actually been run.
