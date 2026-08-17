# State Restoration Guide

State restoration allows your Flutter app to save its state before the operating system kills the process (to free up resources) and restore it when the user returns. This is crucial for a seamless user experience, especially on Android.

ZenRouter makes state restoration simple and type-safe, handling deeply nested navigation stacks and complex route parameters automatically.

---

## 🚀 Basic Setup

To enable state restoration, you need to configure two things:

### 1. Enable Restoration in MaterialApp

Add a `restorationScopeId` to your `MaterialApp.router`. This ID tells Flutter to enable the restoration subsystem.

```dart
MaterialApp.router(
  restorationScopeId: 'app_state', // Required to enable restoration
  routerConfig: coordinator,
)
```

### 2. Ensure Synchronous Parsing

When the app restarts, the restoration system needs to modify the route stack *synchronously* before the first frame. Therefore, your URI parsing logic must be synchronous.

If your standard `parseRouteFromUri` is already synchronous, you're good to go. If it's asynchronous (e.g., waiting for async loading), you **must** override `parseRouteFromUriSync`:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // ...
  
  @override
  AppRoute parseRouteFromUriSync(Uri uri) {
    // Must return an AppRoute synchronously
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      _ => NotFoundRoute(),
    };
  }
}
```

---

## 🧩 Strategy 1: URI-Based Restoration

This is the default and simplest strategy. It works for any route that implements `RouteUnique`. ZenRouter simply saves the route's URI and restores it by re-parsing that URI.

**Best for:** Routes where all state is contained in the URL (e.g., `/product/123`).

```dart
class ProductRoute extends AppRoute {
  ProductRoute(this.id);
  final String id;

  @override
  Uri toUri() => Uri.parse('/product/$id');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ProductPage(id: id);
  }
}
```

Nothing else is needed! When the app is restored, ZenRouter calls `parseRouteFromUri` with `/product/123` and recreates the route.

---

## 🛠️ Strategy 2: Custom Restoration

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
  Uri toUri() => Uri.parse('/filters'); // URL doesn't contain the data
  
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

Finally, register your converter in your Coordinator. This is required so ZenRouter knows how to find it during startup.

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineConverter() {
    RestorableConverter.defineConverter(
      'filter_converter', 
      () => const FilterConverter(),
    );
  }
  
  // ... rest of coordinator
}
```

---

## 🧪 How to Test

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
