# CoordinatorView Guide

`CoordinatorView` embeds a standalone [`Coordinator`](../api/coordinator.md) in any widget tree **without** wrapping the subtree in Flutter's `Router`. Use it when navigation state should live inside a surface the host owns—super apps, plugin panes, side-by-side panels, or dialogs—while the outer app keeps a normal `MaterialApp` (or its own `MaterialApp.router`).

---

## What `CoordinatorView` Does

`CoordinatorView` is a small `StatefulWidget` that:

1. Calls `coordinator.layoutBuilder` to render the coordinator's navigation tree (same widget tree as `CoordinatorRouterDelegate.build`, minus restoration wrapping).
2. Optionally applies `initialUri` **once** when the coordinator's **root** [`NavigationPath`](../api/navigation-paths.md) is still empty.

```dart
MaterialApp(
  home: Scaffold(
    body: CoordinatorView<AppRoute>(
      coordinator: panelCoordinator,
      initialUri: Uri.parse('/settings'),
    ),
  ),
);
```

The coordinator must implement `CoordinatorLayoutBuilder`—in practice, extend [`Coordinator`](../api/coordinator.md), which mixes in `CoordinatorLayout` and provides `layoutBuilder` by default.

> **Note:** Default builders for [`NavigationPath`](../api/navigation-paths.md) / [`IndexedStackPath`](../api/navigation-paths.md) require a full `Coordinator`, not a bare `CoordinatorCore`. See [route-layout — default builders](route-layout.md#default-layout-builders-require-coordinator).

---

## When to Use It

| Scenario | Use `CoordinatorView` | Use `MaterialApp.router(routerConfig: coordinator)` |
|----------|----------------------|------------------------------------------------------|
| Full-screen app with browser URL and system back | ❌ | ✅ |
| Multiple independent coordinators on one screen | ✅ | ❌ (one `Router` per app) |
| Mini-app / module inside a host shell | ✅ | Host owns top-level URL |
| Dialog or split pane with its own stack | ✅ | Awkward to nest `Router` |
| Process-death restoration out of the box | ❌ (see below) | ✅ via `CoordinatorRestorable` |

**Rule of thumb:** If the **host** should own the platform URL and back button, embed with `CoordinatorView`. If this coordinator **is** the app root on web/mobile, use `routerConfig`.

---

## `initialUri` Semantics

`initialUri` seeds navigation only when **all** of the following are true:

- `initialUri` is non-null.
- `coordinator.root.stack` is **empty** (not "any path has routes").
- After the first frame, `parseRouteFromUri` returns a non-null route; then `navigate` runs and the view calls `setState`.

```dart
CoordinatorView<AppRoute>(
  coordinator: coordinator,
  initialUri: Uri.parse('/shop/products/42'),
)
```

### Behaviors covered by tests

| Case | Result |
|------|--------|
| Root already has routes (e.g. after `replace`) | `initialUri` is **ignored** |
| Widget remounted with same coordinator, new `initialUri` | Stack **preserved**; new URI ignored |
| Coordinator instance swapped, root empty | New coordinator gets its `initialUri` |
| `initialUri` set later while root still empty | Applied on next frame (e.g. host resolves link async) |
| `initialUri` updated while root already has routes | **Ignored** |
| `parseRouteFromUri` returns `null` | No navigation; stack stays empty |
| Async `parseRouteFromUri` | Works; UI updates after future completes |

### What `initialUri` is **not**

- Not a live deep-link channel while the embed is open.
- Not aware of routes on **non-root** paths (tabs, nested stacks) when root is empty.
- Not a substitute for `CoordinatorRouterDelegate.setNewRoutePath`.

For host-driven navigation after the surface is running, call `coordinator.navigate(...)`, `push`, or your own `openUri(Uri)` wrapper explicitly.

---

## Parallel Coordinators Example

Each panel needs its **own** `Coordinator` instance and **own** `CoordinatorView`. Do not mount the same coordinator in two views at once.

```dart
class ParallelPanelsScreen extends StatelessWidget {
  ParallelPanelsScreen({super.key});

  final _coordinatorA = PanelCoordinator();
  final _coordinatorB = PanelCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Row(
        children: [
          Expanded(
            child: CoordinatorView<PanelRoute>(
              coordinator: _coordinatorA,
              initialUri: Uri.parse('/'),
            ),
          ),
          Expanded(
            child: CoordinatorView<PanelRoute>(
              coordinator: _coordinatorB,
              initialUri: Uri.parse('/detail/b'),
            ),
          ),
        ],
      ),
    );
  }
}
```

Each `PanelCoordinator` has its own `root` path, `routerDelegate.navigatorKey`, and layout table. Stacks evolve independently.

---

## Host / Mini-App Pattern

A typical super-app split:

1. **`CoordinatorView(initialUri: …)`** — first open when the mini-app's root stack is empty.
2. **`openUri(Uri)` (or `navigate`)** — host pushes subsequent deep links while the surface stays mounted.
3. **`Offstage` / keep-alive** — coordinator may outlive the widget; dispose the coordinator when the window is destroyed.

```dart
class MiniAppSurface extends StatelessWidget {
  const MiniAppSurface({
    required this.bundle,
    this.deepLink,
  });

  final MiniAppBundle bundle;
  final Uri? deepLink;

  @override
  Widget build(BuildContext context) {
    return CoordinatorView<MiniAppRoute>(
      coordinator: bundle.coordinator,
      initialUri: deepLink,
    );
  }
}

// Host API — not handled by CoordinatorView
Future<void> openMiniApp(Uri uri) async {
  final route = await bundle.coordinator.parseRouteFromUri(uri);
  if (route != null) {
    await bundle.coordinator.navigate(route);
  }
}
```

---

## Comparison with `MaterialApp.router`

With `routerConfig: coordinator`, [`CoordinatorRouterDelegate`](../api/coordinator.md#coordinatorrouterdelegate--coordinatorrouteparser) provides:

| Feature | `routerConfig` | `CoordinatorView` |
|---------|----------------|-------------------|
| Browser back/forward, URL bar | `setNewRoutePath` | Host or manual |
| `currentUri` ↔ platform URL | Automatic | Host tracks if needed |
| System back at app root | `popRoute` → `tryPop` | Host policy + in-stack `PopScope` |
| State restoration | `CoordinatorRestorable` in delegate | Wrap yourself (see below) |
| `RouteDeepLink` / `recover` via delegate | Yes | Call `recover` explicitly |
| Query param URL sync (`RouteQueryParameters`) | `markNeedRebuild` updates URL | No-op for platform URL |

`CoordinatorView` only builds `layoutBuilder` and optionally runs the `initialUri` bootstrap. Everything else is intentional host responsibility.

---

## Pitfalls and Mitigations

### Empty first frame

An empty root stack renders nothing (`NavigationStack` returns `SizedBox.shrink`). `initialUri` runs **after** the first frame, so users may flash blank UI.

**Mitigation:** Pre-seed `root` (e.g. `replace(HomeRoute())`), push a default route before showing the surface, or navigate synchronously in the coordinator constructor—not only via deferred `initialUri`.

### `initialUri` only checks `root.stack`

If tabs or nested paths hold state while `root` is still empty, `initialUri` may still run and conflict with pre-seeded layout paths. After the user clears **root** but tabs remain, changing `initialUri` or coordinator identity can re-trigger bootstrap.

**Mitigation:** Ensure activating layouts fills `root`, or treat "initialized" in your host API separately from `root.isEmpty`.

### No automatic URL sync

`coordinator.currentUri` still updates, but nothing pushes it to the browser unless the host does.

### System back button

Without `Router`, Android back may hit the **host** navigator first. At stack depth 1, `tryPop` returns `false` with no delegate to bubble to the host.

**Mitigation:** `PopScope` in the host chrome, or forward back to `coordinator.tryPop()` when the embed has focus.

### State restoration

`CoordinatorRouterDelegate.build` wraps `CoordinatorRestorable`. `CoordinatorView` does not.

**Mitigation:**

```dart
RestorationScope(
  restorationId: 'mini-app-${bundle.id}',
  child: CoordinatorRestorable(
    coordinator: coordinator,
    child: CoordinatorView<AppRoute>(coordinator: coordinator),
  ),
)
```

### `coordinator.navigator`

Root `NavigationStack` uses `routerDelegate.navigatorKey` even without a `Router`. `coordinator.navigator` throws if called before the first route is built or after dispose.

### Rebuilds

UI updates come from path `Listenable`s inside `NavigationStack`, not from `CoordinatorView.setState` (except after `initialUri`). Code that calls `coordinator.notifyListeners()` needs a `ListenableBuilder` on the coordinator where required.

### Lifecycle

- Disposing `CoordinatorView` does **not** dispose the coordinator.
- One coordinator → one `CoordinatorView` at a time.
- Swapping `coordinator` in `didUpdateWidget` re-runs `initialUri` only if the new instance's `root` is empty.

### Modular coordinators

`CoordinatorView` is for **standalone** coordinators with their own `root`. Child [`RouteModule`](../guides/coordinator-modular.md) coordinators share the parent's root and must not use `routerDelegate` as `RouterConfig`; embedding them with `CoordinatorView` without understanding path sharing leads to confusing stacks.

### Async races

`_initializeCoordinatorIfNeeded` is not cancelled. Concurrent host `openUri` and `initialUri` can race. `parseRouteFromUri` returning `null` fails silently—navigate to `notFoundRoute` yourself if needed.

---

## Checklist for Standalone Embeds

- [ ] One `Coordinator` instance per embed surface
- [ ] `initialUri` for first paint only; explicit `navigate` / `openUri` for later links
- [ ] Avoid blank first frame (pre-seed or sync navigate)
- [ ] Host back-button policy documented
- [ ] Restoration wrapper if you need it
- [ ] Explicit `coordinator.dispose()` when the window is torn down
- [ ] Do not use modular child coordinators as standalone embeds without path sharing design

---

## API Reference

### `CoordinatorView<T extends RouteUri>`

| Parameter | Type | Description |
|-----------|------|-------------|
| `coordinator` | `CoordinatorLayoutBuilder<T>` | Provides `layoutBuilder`; typically your `Coordinator` subclass |
| `initialUri` | `Uri?` | Parsed once when `root.stack` is empty; ignored otherwise |

### Related types

- `CoordinatorLayoutBuilder` — `layoutBuilder(BuildContext)` contract (on `Coordinator` via `CoordinatorLayout`)
- [`Coordinator`](../api/coordinator.md) — full navigation hub
- [`CoordinatorRouterDelegate`](../api/coordinator.md#coordinatorrouterdelegate--coordinatorrouteparser) — platform integration when using `routerConfig`

---

## Next Steps

- [Coordinator API](../api/coordinator.md) — navigation methods, layouts, restoration
- [Route Layout Guide](./route-layout.md) — shells, tabs, nested stacks
- [Coordinator Modular](./coordinator-modular.md) — feature modules (distinct from embed pattern)
- Tests: `packages/zenrouter/test/coordinator/view_test.dart`

---

**Need help?** [github.com/definev/zenrouter/issues](https://github.com/definev/zenrouter/issues)
