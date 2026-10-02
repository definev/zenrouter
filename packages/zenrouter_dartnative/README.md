# ZenRouter DartNative

<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

**Native navigation and route presentations for DartNative.**

[![pub package](https://img.shields.io/pub/v/zenrouter_dartnative.svg)](https://pub.dev/packages/zenrouter_dartnative)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/definev/zenrouter/graph/badge.svg?flag=zenrouter_dartnative)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter_dartnative)

</div>

---

A native presentation stack driven by `zenrouter_core`, plus platform-clean
indexed and branched paths for persistent layouts. Built natively with DartNative
widgets and native presentation primitives.

## Installation

Add `zenrouter_dartnative` to your DartNative app's `pubspec.yaml`:

```yaml
dependencies:
  dartnative: ^1.0.0
  zenrouter_dartnative: ^0.1.1
```

Run **`dn pub get`**. DartNative's command resolves its framework and platform bindings from the installed SDK.

```dart
import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri(path: '/');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Green Coffee Shelf')),
    body: Center(
      child: Button(
        title: 'Open Lot Yirgacheffe',
        onPressed: () => coordinator.push(LotRoute(id: 'yirga')),
      ),
    ),
  );
}

class LotRoute extends AppRoute {
  LotRoute({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri(pathSegments: ['lots', id]);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Lot $id')),
    body: Center(
      child: Button(
        title: 'Start Cupping',
        onPressed: () => coordinator.push(CuppingRoute(lotId: id)),
      ),
    ),
  );
}

class CuppingRoute extends AppRoute {
  CuppingRoute({required this.lotId, this.score});
  final String lotId;
  final int? score;

  @override
  List<Object?> get props => [lotId, score];

  @override
  Uri toUri() => Uri(
    pathSegments: ['lots', lotId, 'cupping'],
    queryParameters: score != null ? {'score': '$score'} : null,
  );

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Cupping $lotId')),
    body: Center(
      child: Button(
        title: 'Save & Return Score',
        onPressed: () => coordinator.pop('Score: 92'),
      ),
    ),
  );
}

class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute(this.uri);
  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not Found')),
    body: Center(child: Text('Unknown URI: $uri')),
  );
}

class AppCoordinator extends Coordinator<AppRoute> {
  AppCoordinator() : super(initialRoute: HomeRoute());

  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async =>
      switch (uri.pathSegments) {
        [] || ['lots'] => HomeRoute(),
        ['lots', final id] => LotRoute(id: id),
        ['lots', final id, 'cupping'] => CuppingRoute(
          lotId: id,
          score: int.tryParse(uri.queryParameters['score'] ?? ''),
        ),
        _ => NotFoundRoute(uri),
      };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
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
Their `build(coordinator, context)` method receives the coordinator directly,
and parameterized routes override `props` to ensure predictable value equality.

`parseRouteFromUri` uses Dart pattern matching on `uri.pathSegments` to resolve destinations:
- `[] || ['lots']`: Matches the root or `/lots`.
- `['lots', final id]`: Extracts dynamic path variables (`/lots/yirga` → `id: 'yirga'`).
- `['lots', final id, 'cupping']`: Matches nested subpaths with extracted variables.
- `uri.queryParameters`: Reads query parameters (e.g. `?score=92`).
- `_`: Fallback for unmatched URIs, returning a `RouteNotFound` destination that preserves the original URI.

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
  provide native layout topology.
- `RouteLayout` and `IndexedStackPathBuilder` keep the coordinator as the
  source of truth while the application chooses its DartNative shell widgets.
- `CoordinatorModular` composes feature coordinators as route modules. Modules
  share the parent's root presentation stack and navigation transactions.

| Method | Behavior |
|---|---|
| `push<R>` | Push presentation onto the native stack and await removal result |
| `pushSilently` | Push presentation without waiting for result (completes on commit) |
| `pushReplacement` | Pop top presentation then push new route in one logical commit |
| `pop(result)` | Dismiss top presentation with a typed result |
| `navigate` | Pop back to an existing route, or push if absent |
| `replace` | Drain pushed presentations and swap root content |
| `recoverUri` | Parse URI and synchronize coordinator state |

## Presentations

Choose presentation per route:

| Presentation | Surface | Description |
|---|---|---|
| `ScreenPresentation` | Full screen | Native `slideFromRight` transition (default) |
| `ExperimentalModalSheetPresentation` | Bottom sheet | Detent-based native modal sheet (iOS & Android) |
| `ExperimentalContentSheetPresentation` | Bottom sheet | Content-sized modal bottom sheet |
| `ExperimentalDialogPresentation` | Centered dialog | Native modal dialog with corner radius, dimming, and iOS config |
| `ExperimentalIosOverlayPresentation` | Keyboard overlay | iOS native keyboard-attached overlay |

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

class SampleOrderDialogRoute extends AppRoute {
  @override
  Presentation get presentation => const ExperimentalDialogPresentation(
    cornerRadius: 20,
    dimOpacity: 0.35,
    ios: DialogIOSConfig(),
  );

  @override
  Uri toUri() => Uri(path: '/dialog/sample');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) =>
      const SampleOrderDialog();
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

| Path | Role |
|---|---|
| `NavigationPath` | Nested route stack |
| `IndexedStackPath` | Persistent tabs sharing the root stack |
| `BranchedStackPath` | Tabs retaining independent child stack states |

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
  acknowledgement is not animation completion, so version 0.1.1 does not claim
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
registration, indexed selection, and core navigation mixins with self-contained,
platform-neutral path implementations.
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
