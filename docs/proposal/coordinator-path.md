# Proposal: CoordinatorPath

**Status:** deferred — after 3.0  
**Date:** 2026-08-18  
**Scope:** `zenrouter_core`, `zenrouter`  
**Does not ship in 3.0.**

A first-class way to compose two **independent** Coordinators the way `StackPath` composes `RouteTarget`s.

---

## Problem

ZenRouter can nest routes and nest modules. It cannot stack **navigation domains**.

| Primitive | Independent? | What it actually does |
|---|---|---|
| `RouteModule` / Coordinator-as-Module | No | Child overrides `coordinator` → `isRouteModule = true`. Same `T`, same `root`, same URL, same `NavigationCommit`. |
| `IndexedStackPath` / `BranchedStackPath` / `RouteLayout` | No | Nested **routes** inside **one** Coordinator. Items are `RouteTarget`, same `T`. |
| `CoordinatorView` | Yes | Widget embed of `layoutBuilder` without `Router`. No push/pop of coordinators, no URI compose, no `tryPop` bubble, no history, no restore of a coordinator stack. |

`StackPath<T extends RouteTarget>` cannot hold a Coordinator. A Coordinator is not a `RouteTarget`.

The missing shape:

```text
StackPath  : RouteTarget  ::  CoordinatorPath : CoordinatorMount
```

Each mount keeps its own `T`, paths, manifest, guards, and session. The host owns only **which domain is on the stack**.

---

## Why 3.0 primitives are not enough

Coordinator-as-Module is the opposite of independence:

```dart
// packages/zenrouter_core/lib/src/coordinator/base.dart
late final CoordinatorCore<T> rootCoordinator =
    isRouteModule ? coordinator : this;

late final bool isRouteModule = () {
  try { coordinator; return true; }
  on UnimplementedError { return false; }
}();
```

```dart
// packages/zenrouter/lib/src/coordinator/base.dart
late final NavigationPath<T> _root = isRouteModule
    ? coordinator.root as NavigationPath<T>
    : NavigationPath.createWith(label: 'root', coordinator: this);
```

`currentUri` always comes from the root coordinator. `tryPop` only walks `StackMutatable` of **one** `T`. `RouteManifest.fromFragments` is one graph with unique IDs.

`CoordinatorView` is the correct *embed*, not a *path*. Host must wire URL, back, lifecycle, and restoration by hand.

### Workaround that already works (not the primitive)

```dart
class ShopMiniAppRoute extends AppRoute {
  ShopMiniAppRoute(this.shop);
  final ShopCoordinator shop; // standalone, ShopRoute ≠ AppRoute

  @override
  Uri toUri() => Uri.parse('/mini/shop');

  @override
  Widget build(covariant AppCoordinator c, BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        final inner = await shop.tryPop();
        if (inner != true) c.tryPop();
      },
      child: CoordinatorView<ShopRoute>(
        coordinator: shop,
        initialUri: Uri.parse('/'),
      ),
    );
  }
}
```

Covers “open a mini-app, then dismiss it.” Does **not** cover:

- Deep link `/mini/shop/product/42` into the child stack
- Browser history for child `push` (host sees one route)
- Live `currentUri` = prefix + `shop.currentUri`
- Restore of the mount stack + each child
- Typed `Future<R?>` when popping the whole Coordinator
- Devtools / `NavigationCommit` seeing a coordinator stack

Use this recipe until the primitive ships. Do not promote it into kernel APIs in 3.0.

---

## Proposed primitive

Do **not** put Coordinator into `StackPath`. Add a new path type and a mount protocol. Independent coordinators have **different** `T`.

### `CoordinatorMount`

Adapter, not a route. Child is standalone (`isRouteModule == false`). Do not override `coordinator`.

```dart
abstract class CoordinatorMount {
  String get id;
  Uri get prefix;              // /mini/shop
  CoordinatorCore get child;   // own T

  Future<RouteUri?> resolveFromHost(Uri hostUri); // strip prefix → child.parse
  Uri composeToHost(Uri childUri);                // prefix + child.currentUri
}
```

### `CoordinatorPath`

Analog of `NavigationPath`, items are mounts:

| `StackPath` | `CoordinatorPath` |
|---|---|
| Item: `RouteTarget` of one `T` | Item: `CoordinatorMount` (heterogeneous `T`) |
| `push` / `pop` / `replace` route | `push` / `pop` / `replace` mount |
| `activeRoute` | `activeMount` |
| Layout via `bindLayout` | Host renders `CoordinatorView(active.child)` |

Later analogs (not required for v1):

- Indexed: keep-alive mini-apps (WeChat-style tabs of coordinators)
- Branched: each branch is a full Coordinator

### Five host seams that must change — only when opted in

1. **`currentUri`** — `activeMount.composeToHost(child.currentUri)` while a mount is active. Child `notifyListeners` must publish a host `NavigationCommit`.
2. **`resolveRoute` / `parseRouteFromUri`** — match prefix, delegate to the child resolver. Do **not** flatten two `RouteManifest`s (ID collisions, different `T`).
3. **`tryPop` / `pop` / system back** — child `tryPop()` first; only if the child is at root, pop the mount. Flutter: `ChildBackButtonDispatcher` on the child, not a second `RootBackButtonDispatcher`.
4. **History intent** — one browser history. Policy is **per-mount**, not global:
   - host `replace` URL (child-internal steps), or
   - host `push` (browser back steps through the child), or
   - host URI unchanged (safest default).
5. **Restoration** — persist `CoordinatorPath.stack` (id + prefix + seed URI), then restore each child with its own `CoordinatorRestorable` / `restorationId`. `CoordinatorView` does not wrap restoration today.

Host integration should be an **opt-in mixin** (e.g. `CoordinatorMountable`), not a change to every `CoordinatorCore`.

---

## Compatibility — non-negotiable

This feature **can** ship without breaking 3.x **if** it stays beside `StackPath`, not inside it.

Rule: an app that never calls `pushMount` / never mixes the mount mixin must observe **bit-identical** `currentUri`, `tryPop`, `replace`, and restore buckets.

| Implementation | Breaks apps that do not use mounts? | Notes |
|---|---|---|
| New types + opt-in mixin; `paths` does not contain mounts | No | **Required approach** |
| Host-route + `CoordinatorView` recipe only | No | Interim |
| `CoordinatorPath extends StackPath` stuffed into `paths` | Yes | `replace()` resets every mount; restore/devtools assume `RouteTarget` |
| Global change to `tryPop` / `currentUri` | Yes | Semantic break; double-pop with existing `PopScope` glue |
| Heterogeneous `T` on `CoordinatorModular` | Yes | Breaks the module invariant |
| Flatten two manifests into one graph | Yes | ID / path ambiguity |
| Nested `MaterialApp.router` by default | Yes | Two Routers fight one URL bar |

Seams that must **not** be reused for this:

- `isRouteModule` / `CoordinatorModular.defineModules`
- `RouteManifest.fromFragments`
- `List<StackPath> get paths` (kernel, restore, `replace()`, dispose, devtools all iterate this and assume `RouteTarget` stacks)

`replace()` today:

```dart
for (final path in paths) {
  path.reset();
}
```

If a mount lives in `paths`, logout/`replace(Home)` wipes every live mini-app.

---

## When this is the right primitive

Use it only when the boundary is an **app**, not a feature.

**Yes**

- Super-app / mini-program: host pushes `ShopMiniApp`, `ChatMiniApp`; each team ships its own Coordinator and `T`; dismiss = pop mount.
- Partner / SDK flow: checkout, KYC, payment. Host must not import their graph; they must not depend on `AppRoute`. `push(kycMount)` → `Future<KycResult?>`.
- White-label / packaged product: own version, own restore.
- Modal sub-app that already has tabs/stacks inside and returns a result.

**No — 3.0 primitives are correct**

| Need | Use |
|---|---|
| Feature in the same app, same URL, same back | `RouteModule` / Coordinator-as-Module |
| Shop V1/V2 side by side, cross-navigate | Coordinator-as-Module |
| Tabs / stateful shell | `IndexedStackPath` / `BranchedStackPath` |
| Two panels, no stack | `CoordinatorView` in parallel |
| Nested screens in one feature | `RouteLayout` + `NavigationPath` |

Heuristic: if both sides **must** share `T`, URL, and one Back button → module. If they **must not** share `T` and each domain can be disposed as a unit → `CoordinatorPath`.

---

## What not to build

- Force two Coordinators onto a shared `AppRoute` and call it independence.
- Let `StackPath` accept Coordinator (breaks guard/redirect/page identity).
- Nested `MaterialApp.router` as the composition mechanism.
- Change default `isRouteModule` detection.
- Ship this by thickening Flutter `Coordinator` with server/mini-app behavior.

---

## Suggested rollout (post-3.0)

### Phase 0 — recipe only (can land as docs anytime)

Document the host-route + `CoordinatorView` + `PopScope` + prefix convention. No kernel change. Enough to prove a real super-app/SDK need.

### Phase 1 — primitive, opt-in, no `paths` coupling

- `CoordinatorMount` + `CoordinatorPath` in `zenrouter_core`
- `CoordinatorMountable` mixin
- Flutter: render active child via `CoordinatorView`; `ChildBackButtonDispatcher`
- Tests: host without mixin is bit-identical; prefix resolve; pop bubble; `replace` on host does not reset child unless asked

### Phase 2 — session seams

- Live URI compose + per-mount history policy
- Restoration of the mount stack
- Typed pop result from a mount
- Devtools shows the coordinator stack

### Phase 3 — only with a real product

- Indexed/keep-alive mounts
- Capability boundary (child cannot see host routes)
- Versioned mount contract

Do not start Phase 1 without a concrete super-app or SDK consumer. Phase 0 is the filter.

---

## Place in the longer kernel

`CoordinatorPath` is **one axis** of “location kernel”, not the next ceiling after 3.0.

3.0 already split topology (`RouteManifest`), decision (`RouteResolution`), and commit (`NavigationCommit`) from widgets. The Flutter-router ceiling is done. Remaining depth is orthogonal:

1. **Second adapter** (HTTP/CLI on `zenrouter_core` only) — proves the kernel.
2. **Richer `NavigationCommit`** — replayable deltas, not just URI snapshots. Mounts become `PushMount` intents.
3. **Loaders on the layout chain** — hydration leaves the empty envelope.
4. **This proposal** — isolate location *spaces* (graph-of-graphs).
5. **Manifest as scheduler** — prefetch, parallel resolve, typed navigate by ID.

If those land, zenrouter still does not leave navigation. It owns **application location** (where you may be, what a request means, how you move, how the move is recorded). Flutter remains the first adapter.

No library has that whole kernel today (Remix wins request lifecycle, React Navigation wins stack session, reitit wins isomorphic match). That is context, not a 3.0 deliverable.

---

## Open questions (decide with a real consumer)

1. Default history policy: host URI unchanged, host `replace`, or host `push`?
2. Lifecycle: create on push / keep-alive / dispose on pop?
3. May two mounts of the same `Coordinator` type coexist?
4. Does `replace(hostRoute)` dismiss mounts, or only host stacks?
5. Deep link to an unknown prefix: host 404, or leave the current mount?

---

## References

- `packages/zenrouter/doc/guides/coordinator-view.md`
- `packages/zenrouter/doc/guides/coordinator-as-module.md`
- `packages/zenrouter/doc/recipes/route-versioning.md`
- `packages/zenrouter/doc/architecture/web-navigation-backbone-technical-report-vi.md`
- `CONTEXT.md` — Route Manifest, Navigation Commit, invariants
