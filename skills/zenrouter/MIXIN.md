# Route Mixins Reference

All mixins that can be applied to a `RouteTarget` to extend its capabilities.

---

## Mixin Hierarchy

```
RouteTarget (base class)
├── RouteIdentity<T>         ← URI/string identity
│   └── RouteLayoutChild     ← declares parentLayoutKey
│       ├── RouteUri          ← combines identity + layout child (abstract)
│       │   ├── RouteDeepLink ← deep link strategy
│       │   └── RouteUnique   ← concrete: build(), toUri(), layout resolution
│       │       ├── RouteTransition      ← custom page transition
│       │       ├── RouteQueryParameters ← reactive URL query params
│       │       └── RouteLayout<T>       ← shell/tab layout (wraps child routes)
│       └── RouteLayoutParent ← resolves StackPath for child routes
├── RouteGuard               ← blocks pop
├── RouteRedirect<T>         ← redirects before display
├── RouteRedirectRule<T>     ← composable redirect chain
└── RouteRestorable<T>       ← state restoration after process death
```

---

## zenrouter_core Mixins

### RouteIdentity\<T\>

**Package:** `zenrouter_core` · **Applies to:** `RouteTarget`

Provides a typed `identifier` getter for route identity in the navigation system.

```dart
mixin RouteIdentity<T> on RouteTarget {
  T get identifier;
}
```

> [!NOTE]
> Most routes use `RouteUnique` (which implements `RouteUri` → `RouteIdentity<Uri>`) rather than using this directly.

---

### RouteLayoutChild

**Package:** `zenrouter_core` · **Applies to:** `RouteTarget`

Declares which layout parent a route belongs to via `parentLayoutKey`.

```dart
mixin RouteLayoutChild on RouteTarget {
  Object? get parentLayoutKey;                                     // key matching a RouteLayoutParent.layoutKey
  RouteLayoutParent? createParentLayout(CoordinatorCore coordinator);
  RouteLayoutParent? resolveParentLayout(CoordinatorCore coordinator);
}
```

- `parentLayoutKey` — `null` means no parent layout (renders directly on the root stack).
- `resolveParentLayout` — reuses an active layout if one with the same key exists, otherwise creates a new one.
- Automatically included via `RouteUri` / `RouteUnique`.

---

### RouteLayoutParent\<T\>

**Package:** `zenrouter_core` · **Applies to:** `RouteLayoutChild`

Declares a layout that manages a `StackPath` of child routes.

```dart
mixin RouteLayoutParent<T extends RouteTarget> on RouteLayoutChild {
  StackPath resolvePath(CoordinatorCore coordinator);
  Object get layoutKey;   // default in RouteLayout: runtimeType
}
```

- Equality is based on `layoutKey` + `parentLayoutKey` — the coordinator reuses existing instances.
- `onDidPop` resets the child `StackPath`.

---

### RouteGuard

**Package:** `zenrouter_core` · **Applies to:** `RouteTarget`

Intercepts pop operations so you can block or confirm navigation away.

```dart
mixin RouteGuard on RouteTarget {
  FutureOr<bool> popGuard();                              // return false to block pop
  FutureOr<bool> popGuardWith(CoordinatorCore coordinator); // same, with coordinator access
}
```

**Example — confirmation dialog:**

```dart
class EditRoute extends AppRoute with RouteGuard {
  @override
  Future<bool> popGuardWith(covariant AppCoordinator coordinator) async {
    return await showDialog<bool>(
      context: coordinator.navigator.context,
      builder: (_) => AlertDialog(
        title: Text('Discard changes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(_, true), child: Text('Discard')),
        ],
      ),
    ) ?? false;
  }
}
```

---

### RouteRedirect\<T\>

**Package:** `zenrouter_core` · **Applies to:** `RouteTarget`

Simple redirect: return `this` to proceed, another route to redirect, or `null` to cancel.

```dart
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  FutureOr<T> redirect();                              // without coordinator
  FutureOr<T?> redirectWith(CoordinatorCore coordinator); // with coordinator
}
```

**Redirect resolution chain:**
1. Coordinator calls `redirectWith(coordinator)` (or `redirect()` if no coordinator).
2. If result is `this` → stop, display this route.
3. If result is another route → repeat resolution on the new route.
4. If result is `null` → cancel navigation.

**Example:**

```dart
class ProfileRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  AppRoute redirect() {
    if (featureFlags.isProfileV2) return ProfileV2Route();
    return this;
  }
}
```

---

### RouteRedirectRule\<T\>

**Package:** `zenrouter_core` · **Applies to:** `RouteTarget` (implements `RouteRedirect`)

Delegates redirect logic to a composable list of `RedirectRule<T>` objects. See [ADVANCED.md — RedirectRule](./ADVANCED.md#redirectrule) for full details.

```dart
mixin RouteRedirectRule<T extends RouteTarget> on RouteTarget implements RouteRedirect<T> {
  List<RedirectRule> get redirectRules;
}
```

Rules are evaluated in order. Each returns a `RedirectResult`:

| Result | Meaning |
|:-------|:--------|
| `.continueRedirect()` | Pass to next rule |
| `.redirectTo(route)` | Redirect; stops chain |
| `.stop()` | Cancel navigation entirely |

---

### RouteDeepLink

**Package:** `zenrouter_core` · **Applies to:** `RouteUri`

Controls how the coordinator handles a route activated via a URL/deep link.

```dart
mixin RouteDeepLink on RouteUri {
  DeeplinkStrategy get deeplinkStrategy;
  FutureOr<void> deeplinkHandler(CoordinatorCore coordinator, Uri uri); // for custom strategy
}
```

| Strategy | Behaviour |
|:---------|:----------|
| `DeeplinkStrategy.replace` | Replace the active route (default for all routes) |
| `DeeplinkStrategy.navigate` | Navigate; pops back if route is already in stack |
| `DeeplinkStrategy.push` | Push onto existing stack |
| `DeeplinkStrategy.custom` | Call `deeplinkHandler` for full control |

**Example:**

```dart
class NotificationRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
}
```

---

## zenrouter (Flutter) Mixins

### RouteUnique

**Package:** `zenrouter` · **Applies to:** `RouteTarget` (implements `RouteUri`)

The **primary mixin for coordinator-managed routes**. Provides `build()`, `toUri()`, layout resolution, and `parentLayoutKey`.

```dart
mixin RouteUnique on RouteTarget implements RouteUri {
  Uri toUri();
  Widget build(CoordinatorCore coordinator, BuildContext context);
  Type? get layout;                       // shorthand for parentLayoutKey
  Object? get parentLayoutKey => layout;  // defaults to layout
}
```

- `build()` receives the **concrete coordinator type** (covariant) — giving type-safe access to custom paths.
- `layout` / `parentLayoutKey` — set to the `Type` of the target `RouteLayout` (or its `layoutKey`).
- Override `props` when the route carries parameters for correct identity.

---

### RouteLayout\<T\>

**Package:** `zenrouter` · **Applies to:** `RouteUnique` (mixes in `RouteLayoutParent`)

A route that wraps child routes — sidebar, tab bar, header, drawer, etc.

```dart
mixin RouteLayout<T extends RouteUnique> on RouteUnique implements RouteLayoutParent<T> {
  StackPath<RouteUnique> resolvePath(CoordinatorCore coordinator);
  Object get layoutKey => runtimeType;   // default
  Widget buildPath(Coordinator coordinator);  // renders child route
}
```

**Rules:**
- Call `buildPath(coordinator)` to render the active child — do **not** call `super.build()`.
- Register via `NavigationPath..bindLayout(LayoutClass.new)` in the module.
- `layoutKey` defaults to `runtimeType`.

See [SKILL.md §5](./SKILL.md#5-layout).

---

### RouteTransition

**Package:** `zenrouter` · **Applies to:** `RouteUnique`

Overrides the default page transition for a specific route.

```dart
mixin RouteTransition on RouteUnique {
  StackTransition<T> transition<T extends RouteUnique>(CoordinatorCore coordinator);
}
```

**Example:**

```dart
class ModalRoute extends AppRoute with RouteTransition {
  @override
  StackTransition<T> transition<T extends RouteUnique>(CoordinatorCore coordinator) =>
      StackTransition.sheet(build(coordinator as AppCoordinator, coordinator.navigator.context));
}
```

---

### RouteQueryParameters

**Package:** `zenrouter` · **Applies to:** `RouteUnique`

Adds reactive URL query parameters that update the browser URL without navigation transitions.

```dart
mixin RouteQueryParameters on RouteUnique {
  ValueNotifier<Map<String, String>> get queryNotifier;
  Map<String, String> get queries;
  String? query(String name);
  void updateQueries(Coordinator coordinator, {required Map<String, String> queries});
}
```

**Key behaviour:** Query parameter changes are excluded from `props`, so they update the URL without triggering route identity changes or navigation animations.

**Example:**

```dart
class ProductListRoute extends AppRoute with RouteQueryParameters {
  @override
  final queryNotifier = ValueNotifier<Map<String, String>>({});

  void setPage(int page, AppCoordinator coordinator) {
    updateQueries(coordinator, queries: {...queries, 'page': '$page'});
  }

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: queryNotifier,
      builder: (_, queries, __) => ProductList(page: int.parse(queries['page'] ?? '1')),
    );
  }
}
```

---

### RouteRestorable\<T\>

**Package:** `zenrouter` · **Applies to:** `RouteTarget`

Enables state restoration after process death. Two strategies:

| Strategy | How it works |
|:---------|:-------------|
| `RestorationStrategy.unique` (default) | Serialises via `toUri()` → restores via `parseRouteFromUri` |
| `RestorationStrategy.converter` | Uses a custom `RestorableConverter<T>` for complex data |

```dart
mixin RouteRestorable<T extends RouteTarget> on RouteTarget {
  RestorationStrategy get restorationStrategy;  // default: .unique
  RestorableConverter<T> get converter;         // required for .converter strategy
  String get restorationId;                     // unique stable id
}
```

**Example with custom converter:**

```dart
class BookDetailRoute extends AppRoute with RouteRestorable<BookDetailRoute> {
  BookDetailRoute({required this.book});
  final Book book;

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.converter;

  @override
  RestorableConverter<BookDetailRoute> get converter => const BookDetailConverter();

  @override
  String get restorationId => 'book_${book.id}';
}

class BookDetailConverter extends RestorableConverter<BookDetailRoute> {
  const BookDetailConverter();

  @override
  String get key => 'book_detail';

  @override
  Map<String, dynamic> serialize(BookDetailRoute route) => {
    'id': route.book.id,
    'title': route.book.title,
  };

  @override
  BookDetailRoute deserialize(Map<String, dynamic> data) => BookDetailRoute(
    book: Book(id: data['id'], title: data['title']),
  );
}

// Register in coordinator:
@override
void defineConverter() {
  defineRestorableConverter('book_detail', BookDetailConverter.new);
}
```

---

## Quick Reference

| Mixin | Package | Applies to | Purpose |
|:------|:--------|:-----------|:--------|
| `RouteIdentity<T>` | core | `RouteTarget` | Typed identifier |
| `RouteLayoutChild` | core | `RouteTarget` | Declares parent layout |
| `RouteLayoutParent<T>` | core | `RouteLayoutChild` | Manages child StackPath |
| `RouteGuard` | core | `RouteTarget` | Blocks pop |
| `RouteRedirect<T>` | core | `RouteTarget` | Simple redirect |
| `RouteRedirectRule<T>` | core | `RouteTarget` | Composable redirect chain |
| `RouteDeepLink` | core | `RouteUri` | Deep link strategy |
| `RouteUnique` | zenrouter | `RouteTarget` | build + toUri + layout |
| `RouteLayout<T>` | zenrouter | `RouteUnique` | Shell/tab layout |
| `RouteTransition` | zenrouter | `RouteUnique` | Custom page transition |
| `RouteQueryParameters` | zenrouter | `RouteUnique` | Reactive URL query params |
| `RouteRestorable<T>` | zenrouter | `RouteTarget` | State restoration |
