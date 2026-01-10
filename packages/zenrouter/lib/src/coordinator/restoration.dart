part of 'router.dart';

/// A widget that enables state restoration for a [Coordinator] and its navigation hierarchy.
///
/// ## What This Widget Does
///
/// [CoordinatorRestorable] wraps your application's root widget to provide automatic
/// state restoration for the entire navigation stack managed by the [Coordinator].
/// When the operating system needs to reclaim resources and later restores your
/// application, this widget ensures that the user returns to exactly where they left
/// off, including the complete navigation history, active routes, and even nested
/// navigation stacks.
///
/// ## Where It Fits in the Architecture
///
/// **Important: This widget is used internally by [CoordinatorRouterDelegate] and you
/// typically do not need to use it directly.** The [CoordinatorRouterDelegate.build]
/// method automatically wraps your app's content with this widget when restoration is
/// enabled. It integrates with Flutter's [RestorationMixin] to participate in the
/// framework's restoration protocol, automatically saving and restoring state when
/// the application is backgrounded or terminated by the system.
///
/// The restoration hierarchy looks like this:
/// ```
/// MaterialApp.router(restorationScopeId: 'app')
///   └─ Router(routerDelegate: coordinator.routerDelegate)
///       └─ CoordinatorRestorable (automatically added by routerDelegate.build)
///           └─ NavigationStack(restorationId: 'root_stack')
///               └─ Your app widgets
/// ```
///
/// ## When Restoration Happens Automatically
///
/// Restoration is automatically enabled for your application when you provide a
/// `restorationScopeId` to [MaterialApp.router]. The framework handles all the
/// wrapping and state management internally. This is important for mobile
/// applications where the operating system may terminate your app to free memory,
/// and users expect to return to their previous screen when reopening the app.
///
/// **Restoration works automatically when:**
/// - You provide `restorationScopeId` to MaterialApp.router
/// - All your paths have unique `debugLabel` values
/// - You implement synchronous route parsing (or override `parseRouteFromUriSync`)
/// - Complex routes use [RouteRestorable] with registered converters
///
/// **Restoration is skipped when:**
/// - No `restorationScopeId` is provided to MaterialApp
/// - Your app is stateless or has only simple navigation
/// - You intentionally want users to start fresh on each launch
///
/// ## How to Enable Restoration
///
/// **Step 1: Enable restoration in your MaterialApp**
///
/// Provide a `restorationScopeId` to your [MaterialApp.router]. This automatically
/// enables the restoration framework for your entire application:
///
/// ```dart
/// MaterialApp.router(
///   restorationScopeId: 'main',  // This is all you need to enable restoration!
///   routerDelegate: coordinator.routerDelegate,
///   routeInformationParser: coordinator.routeInformationParser,
/// )
/// ```
///
/// **That's it!** The [CoordinatorRouterDelegate] automatically uses this widget
/// internally. You don't need to wrap anything manually.
///
/// **Step 2: Ensure all paths have debug labels**
///
/// Every [StackPath] that participates in restoration must have a unique `debugLabel`.
/// This label is used as a key to identify which path's state belongs to which data
/// when restoring. Without this, restoration will fail with an assertion error:
///
/// ```dart
/// class MyCoordinator extends Coordinator<MyRoute> {
///   late final tabsPath = NavigationPath<MyRoute>.create(
///     label: 'tabs',  // Required for restoration
///   );
///
///   @override
///   List<StackPath> get paths => [root, tabsPath];
/// }
/// ```
///
/// **Step 3: Implement synchronous route parsing**
///
/// If your [Coordinator.parseRouteFromUri] is asynchronous, you must override
/// [Coordinator.parseRouteFromUriSync] with a synchronous version. Restoration
/// cannot wait for asynchronous operations:
///
/// ```dart
/// class MyCoordinator extends Coordinator<MyRoute> {
///   @override
///   Future<MyRoute> parseRouteFromUri(Uri uri) async {
///     // Async version (for normal navigation)
///     await someAsyncOperation();
///     return MyRoute.fromUri(uri);
///   }
///
///   @override
///   RouteUriParserSync<MyRoute> get parseRouteFromUriSync {
///     // Synchronous version (for restoration)
///     return (Uri uri) => MyRoute.fromUri(uri);
///   }
/// }
/// ```
///
/// **Step 4: Handle complex routes with custom serialization**
///
/// For routes that cannot be fully represented by a URI alone (e.g., routes with
/// in-memory state or complex objects), implement [RouteRestorable] with a custom
/// [RestorableConverter]:
///
/// ```dart
/// class ProductDetailRoute extends MyRoute with RouteRestorable<ProductDetailRoute> {
///   ProductDetailRoute({required this.product});
///
///   final Product product;  // Complex object that can't be in URL
///
///   @override
///   RestorationStrategy get strategy => RestorationStrategy.converter;
///
///   @override
///   RestorableConverter<ProductDetailRoute> get converter =>
///       const ProductDetailConverter();
/// }
///
/// class ProductDetailConverter extends RestorableConverter<ProductDetailRoute> {
///   const ProductDetailConverter();
///
///   @override
///   String get key => 'product_detail';
///
///   @override
///   Map<String, dynamic> serialize(ProductDetailRoute route) {
///     return {'productId': route.product.id, 'productName': route.product.name};
///   }
///
///   @override
///   ProductDetailRoute deserialize(Map<String, dynamic> data) {
///     return ProductDetailRoute(
///       product: Product(id: data['productId'], name: data['productName']),
///     );
///   }
/// }
/// ```
///
/// ## Important Considerations
///
/// **Restoration only saves navigation structure, not widget state:**
/// If individual screens have their own state (form inputs, scroll positions, etc.),
/// those widgets need their own [RestorationMixin] implementation. This widget only
/// restores which routes are on the stack and which route is active.
///
/// **Debug labels must be stable across app versions:**
/// If you change a path's `debugLabel` between app versions, restoration data for
/// that path will be lost. Plan your path naming strategy carefully.
///
/// **Restoration happens synchronously on startup:**
/// The restoration process blocks the UI from rendering until complete. Keep your
/// route parsing logic fast to avoid slow startup times.
///
/// See also:
/// - [RouteRestorable] for custom route serialization
/// - [RestorableConverter] for implementing custom converters
/// - [NavigationStack] which handles restoration for individual navigation paths
class CoordinatorRestorable extends StatefulWidget {
  const CoordinatorRestorable({
    super.key,
    required this.restorationId,
    required this.coordinator,
    required this.child,
  });

  /// The restoration identifier used to save and restore this coordinator's state.
  ///
  /// This ID must be unique within the parent restoration scope. It becomes part
  /// of the restoration bucket hierarchy and is used to associate saved state
  /// with this specific coordinator instance.
  final String restorationId;

  /// The coordinator whose navigation state will be saved and restored.
  ///
  /// This coordinator's entire navigation hierarchy, including all [StackPath]
  /// instances and their route stacks, will be persisted when the application
  /// goes into the background and restored when it returns.
  final Coordinator coordinator;

  /// The child widget to render.
  ///
  /// This is typically the [Router] or root widget of your application's
  /// navigation hierarchy.
  final Widget child;

  @override
  State<CoordinatorRestorable> createState() => _CoordinatorRestorableState();
}

class _CoordinatorRestorableState extends State<CoordinatorRestorable>
    with RestorationMixin {
  late final _restorable = _CoordinatorRestorable(widget.coordinator);
  late final _activeRoute = ActiveRouteRestorable(
    initialRoute: widget.coordinator.activePath.activeRoute,
    parseRouteFromUri: widget.coordinator.parseRouteFromUriSync,
  );

  void _saveCoordinator() {
    final result = <String, dynamic>{};
    for (final path in widget.coordinator.paths) {
      if (path is NavigationPath) {
        assert(
          path.debugLabel != null,
          'NavigationPath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.stack;
      }
      if (path is IndexedStackPath) {
        assert(
          path.debugLabel != null,
          'IndexedStackPath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.activeIndex;
      }
    }

    _restorable.value = result;
  }

  void _saveActiveRoute() {
    _activeRoute.value = widget.coordinator.activePath.activeRoute;
  }

  void _restoreCoordinator() async {
    final raw = _restorable.value;

    for (final MapEntry(:key, :value) in raw.entries) {
      final path = widget.coordinator.paths.firstWhereOrNull(
        (p) => p.debugLabel == key,
      );

      if (path case RestorablePath path) {
        path.restore(value);
      }
    }
    if (_activeRoute.value case RouteUnique route) {
      widget.coordinator.navigate(route);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_saveCoordinator);
    widget.coordinator.addListener(_saveActiveRoute);
  }

  @override
  void didUpdateWidget(covariant CoordinatorRestorable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coordinator != oldWidget.coordinator) {
      // coverage:ignore-start
      oldWidget.coordinator.removeListener(_saveCoordinator);
      widget.coordinator.addListener(_saveCoordinator);
      oldWidget.coordinator.removeListener(_saveActiveRoute);
      widget.coordinator.addListener(_saveActiveRoute);
      // coverage:ignore-end
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_saveCoordinator);
    widget.coordinator.removeListener(_saveActiveRoute);
    _restorable.dispose();
    _activeRoute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorable, '_restorable');
    registerForRestoration(_activeRoute, '_activeRoute');
    if (initialRestore) {
      _restoreCoordinator();
    }
  }
}

/// A [RestorableValue] that manages the restoration of the currently active route in the navigation stack.
///
/// ## What This Class Does
///
/// [ActiveRouteRestorable] is responsible for remembering which route was active (visible to the user)
/// when the application was backgrounded or terminated. When the application restores, this ensures
/// that the user returns to the exact same screen they were viewing, not just somewhere in the
/// navigation stack. This is a critical component of providing a seamless user experience where
/// interruptions from the operating system are invisible to the user.
///
/// ## Where It Fits in the Architecture
///
/// This class is used internally by [_CoordinatorRestorableState] to track the active route
/// separately from the full navigation stack. While the coordinator saves the entire stack of
/// routes for each path, this class specifically tracks which single route from which path
/// was active when the app was paused. Upon restoration, the coordinator uses this information
/// to navigate to the correct route using [Coordinator.navigate].
///
/// The restoration data flow looks like this:
/// ```
/// CoordinatorRestorableState
///   ├─ _CoordinatorRestorable       (saves ALL routes in ALL paths)
///   └─ ActiveRouteRestorable        (saves the ONE active route)
///        └─ On restore → Coordinator.navigate(activeRoute)
/// ```
///
/// ## When This Gets Called
///
/// **Saving (toPrimitives):**
/// This is called whenever the coordinator's active route changes. The [_CoordinatorRestorableState]
/// listens to coordinator changes via `_saveActiveRoute()` and updates this restorable's value,
/// which triggers serialization to the restoration bucket.
///
/// **Restoring (fromPrimitives):**
/// This is called during app startup when Flutter detects existing restoration data. It happens
/// synchronously before the first frame is rendered, ensuring the user never sees an intermediate
/// state. The restoration process deserializes the saved data back into a route object that the
/// coordinator can navigate to.
///
/// ## How It Handles Different Route Types
///
/// This class intelligently handles two different route serialization strategies:
///
/// **Strategy 1: RouteUnique (URI-based)**
/// Routes that implement [RouteUnique] can be completely represented by their URI. These are
/// serialized as simple strings and deserialized by calling [parseRouteFromUri]:
///
/// ```dart
/// // Route definition
/// class HomeRoute extends RouteTarget with RouteUnique {
///   @override
///   Uri toUri() => Uri.parse('/home');
/// }
///
/// // Serialized as: "/home"
/// // Deserialized via: parseRouteFromUri(Uri.parse("/home"))
/// ```
///
/// **Strategy 2: RouteRestorable (Custom serialization)**
/// Routes that implement [RouteRestorable] with custom converters can preserve complex state
/// that wouldn't fit in a URI. These are serialized as maps containing the converter key and
/// serialized data:
///
/// ```dart
/// // Route definition
/// class ProductRoute extends RouteTarget with RouteRestorable<ProductRoute> {
///   ProductRoute({required this.product});
///   final Product product;
///
///   @override
///   RestorationStrategy get strategy => RestorationStrategy.converter;
///
///   @override
///   RestorableConverter<ProductRoute> get converter => ProductConverter();
/// }
///
/// // Serialized as: {"strategy": "converter", "converter": "product", "value": {...}}
/// // Deserialized via: ProductConverter().deserialize(data)
/// ```
///
/// The class automatically detects which strategy to use by checking if the route implements
/// [RouteRestorable] during serialization, and by examining the data structure during
/// deserialization.
///
/// ## Important Implementation Details
///
/// **Null handling:**
/// This class properly handles null values, which occur when no route is active yet (app first
/// launch) or when the active route shouldn't be restored. The [createDefaultValue] returns
/// the [initialRoute] provided during construction, or null if none was provided.
///
/// **Type safety:**
/// The generic type parameter `<T extends RouteUnique>` ensures compile-time type safety while
/// still allowing the class to work with any route type that implements [RouteUnique]. The
/// route is cast to `T` after deserialization, which is safe because we control the serialization
/// format.
///
/// **Deserialization format detection:**
/// The [fromPrimitives] method uses pattern matching to detect whether the saved data is a
/// simple string (URI-based) or a map (custom converter-based), and handles each case appropriately.
///
/// See also:
/// - [RouteRestorable] for implementing custom route serialization
/// - [CoordinatorRestorable] for the overall restoration orchestration
/// - [RestorableValue] (Flutter framework) for the base restoration mechanism
class ActiveRouteRestorable<T extends RouteUnique> extends RestorableValue<T?> {
  ActiveRouteRestorable({
    required this.initialRoute,
    required this.parseRouteFromUri,
  });

  /// The initial route to use when no restoration data is available.
  ///
  /// This is typically null for a fresh app launch, but can be set to provide a
  /// default route when restoration data doesn't exist.
  final T? initialRoute;

  /// Function to parse a route from a URI string.
  ///
  /// This must be a synchronous version of your coordinator's route parser. It's
  /// used to deserialize [RouteUnique] routes that were saved as URI strings.
  /// The function should handle all possible URIs that your application can generate.
  final RouteUriParserSync<RouteUnique> parseRouteFromUri;

  @override
  T? createDefaultValue() => initialRoute;

  @override
  void didUpdateValue(T? oldValue) {
    notifyListeners();
  }

  @override
  T? fromPrimitives(Object? data) {
    // Never happen
    // coverage:ignore-start
    if (data == null) return null;
    // coverage:ignore-end
    return RouteTarget.deserialize(data, parseRouteFromUri: parseRouteFromUri);
  }

  @override
  Object? toPrimitives() {
    if (value == null) return null;
    return RouteTarget.serialize(value!);
  }
}

class _CoordinatorRestorable<T extends RouteUnique>
    extends RestorableValue<Map<String, dynamic>> {
  _CoordinatorRestorable(this.coordinator);
  final Coordinator coordinator;

  @override
  Map<String, dynamic> createDefaultValue() {
    final map = <String, dynamic>{};
    for (final path in coordinator.paths) {
      if (path is NavigationPath) {
        assert(
          path.debugLabel != null,
          'NavigationPath must have a debugLabel for restoration to work',
        );
        map[path.debugLabel!] = path.stack.cast<T>();
        continue;
      }
      if (path is IndexedStackPath) {
        assert(
          path.debugLabel != null,
          'IndexedStackPath must have a debugLabel for restoration to work',
        );
        map[path.debugLabel!] = path.activeIndex;
        continue;
      }
    }
    return map;
  }

  @override
  void didUpdateValue(Map<String, dynamic>? oldValue) {
    notifyListeners();
  }

  @override
  Map<String, dynamic> fromPrimitives(Object? data) {
    final result = <String, dynamic>{};

    final map = (data as Map).cast<String, dynamic>();
    for (final pathEntry in map.entries) {
      final path = coordinator.paths.firstWhereOrNull(
        (p) => p.debugLabel == pathEntry.key,
      );
      if (path case NavigationPath path) {
        assert(
          path.debugLabel != null,
          'NavigationPath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.deserialize(
          pathEntry.value,
          coordinator.parseRouteFromUriSync,
        );
      }
      if (path case RestorablePath path) {
        assert(
          path.debugLabel != null,
          'RestorablePath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.deserialize(pathEntry.value);
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> toPrimitives() {
    final result = <String, dynamic>{};

    for (final path in coordinator.paths) {
      if (path case RestorablePath path) {
        assert(
          path.debugLabel != null,
          'RestorablePath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.serialize();
      }
    }

    return result;
  }
}
