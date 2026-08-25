# State restoration

Restores the navigation stack after the OS kills the process (common on
Android). Nested layouts are restored from the same URIs.

## Setup

```dart
MaterialApp.router(
  restorationScopeId: 'app_state',
  routerConfig: coordinator,
)
```

Restoration applies the stack before the first frame, so parsing must be
synchronous. Sync `RouteBinding` factories are sufficient.

If a factory is async (`RouteBinding.deferred`, or `await` in `create`),
override `parseRouteFromUriSync`:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, AppRouteId> {
  @override
  AppRoute parseRouteFromUriSync(Uri uri) {
    final match = manifest.match(uri);
    if (match == null) return NotFoundRoute(uri);
    return switch (match.id) {
      AppRouteId.home => HomeRoute(),
      AppRouteId.product =>
        ProductRoute(id: match.pathParameters['id']!),
    };
  }
}
```

---

## URI restoration

Default. Saves `toUri()` and recreates the route via the binding (or
`parseRouteFromUri`). Use when all state is in the URL.

```dart
class ProductRoute extends AppRoute {
  ProductRoute(this.id);
  final String id;

  @override
  Uri toUri() => AppCoordinator.manifest.location(
    AppRouteId.product,
    pathParameters: {'id': id},
  );
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ProductPage(id: id);
  }
}
```

On restore, the URI is matched again and the binding reconstructs the route.

---

## Converter restoration

Sometimes your route contains complex state that can't (or shouldn't) be put into the URL—like a large form object, a specific filter configuration, or private data.

For these cases, use `RouteRestorable` and a `RestorableConverter`.

### 1. Implement `RouteRestorable`

Mixin `RouteRestorable` and override the restoration properties.

```dart
class FilterRoute extends AppRoute with RouteRestorable<FilterRoute> {
  FilterRoute({required this.filters});
  
  final FilterData filters; // Complex object not in URL

  @override
  String get restorationId => 'filter_route';

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.converter;

  @override
  RestorableConverter<FilterRoute> get converter => const FilterConverter();

  @override
  Uri toUri() => AppCoordinator.manifest.location(AppRouteId.filters);
  
  // ... build method
}
```

### 2. Create the Converter

The converter handles serializing your route to a Map and back.

```dart
class FilterConverter extends RestorableConverter<FilterRoute> {
  const FilterConverter();
  
  // Unique key for this converter
  @override
  String get key => 'filter_converter';

  @override
  Map<String, dynamic> serialize(FilterRoute route) {
    return {
      'categories': route.filters.categories,
      'minPrice': route.filters.minPrice,
      'maxPrice': route.filters.maxPrice,
    };
  }

  @override
  FilterRoute deserialize(Map<String, dynamic> data) {
    return FilterRoute(
      filters: FilterData(
        categories: List<String>.from(data['categories']),
        minPrice: data['minPrice'],
        maxPrice: data['maxPrice'],
      ),
    );
  }
}
```

### 3. Register the Converter

Register the converter in `init()`. Do not use the deprecated
`defineConverter` hook.

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void init() {
    super.init();
    defineRestorableConverter(
      'filter_converter',
      () => const FilterConverter(),
    );
  }

  // ... rest of coordinator
}
```

---

## How to test

You can simulate process death to verify your restoration logic.

### Android
1. Run your app on an emulator or device.
2. Navigate deep into your app.
3. Press the **Home** button to background the app.
4. Run this command in your terminal:
   ```bash
   adb shell am kill <your.package.name>
   ```
5. Tap the app icon to relaunch it. It should open exactly where you left off.

### iOS
1. Run your app on the Simulator.
2. Navigate deep into your app.
3. Press **Home** (Cmd+Shift+H) to background the app.
4. In Xcode (or Simulator menu), go to **Debug > Simulate Memory Warning**.
5. Relaunch the app.

> [!NOTE]
> On iOS, "Simulate Memory Warning" doesn't always kill the app immediately. For a more reliable test, you can use **Device > Restart** on the simulator while the state is saved, but Android is generally easier for testing this specific behavior.
