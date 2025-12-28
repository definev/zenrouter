import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// A mixin that adds state restoration capabilities to navigation paths.
///
/// ## What This Mixin Does
///
/// [RestorablePath] provides the contract for serializing and deserializing navigation
/// state within a [StackPath]. It enables paths to save their current navigation stack
/// to persistent storage and restore it later, allowing users to return to exactly where
/// they left off even after the app is terminated by the system.
///
/// This mixin defines three core operations that each path type must implement:
/// - **Serialization**: Converting the current navigation state to a persistable format
/// - **Deserialization**: Reconstructing navigation data from the persisted format
/// - **Restoration**: Applying the deserialized data back to the navigation stack
///
/// ## Where It's Used
///
/// This mixin is applied to concrete path types that need restoration support:
/// - [NavigationPath]: Uses it to serialize/deserialize the route stack
/// - [IndexedStackPath]: Uses it to serialize/deserialize the active tab index
///
/// The mixin is used internally by the restoration framework and you typically interact
/// with the concrete implementations rather than this mixin directly.
///
/// ## Type Parameters
///
/// - `T`: The route type that extends [RouteTarget]
/// - `S`: The serialized format (e.g., `List<dynamic>` for route stacks, `int` for indices)
/// - `D`: The deserialized format (e.g., `List<T>` for routes, `int` for index values)
///
/// ## How Paths Implement Restoration
///
/// **NavigationPath example:**
/// ```dart
/// class NavigationPath<T extends RouteTarget> extends StackPath<T>
///     with RestorablePath<T, List<dynamic>, List<T>> {
///
///   @override
///   List<dynamic> serialize() {
///     // Convert stack to primitives (strings, maps)
///     return stack.map((route) => /* serialize route */).toList();
///   }
///
///   @override
///   List<T> deserialize(List<dynamic> data) {
///     // Convert primitives back to route objects
///     return data.map((item) => /* deserialize route */).toList();
///   }
///
///   @override
///   void restore(List<T> data) {
///     // Replace current stack with restored routes
///     reset();
///     for (final route in data) {
///       push(route);
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [NavigationPath] for the full stack restoration implementation
/// - [IndexedStackPath] for tab index restoration implementation
/// - [CoordinatorRestorable] for how restoration is orchestrated at the coordinator level
mixin RestorablePath<T extends RouteTarget, S, D> on StackPath<T> {
  /// Serializes the current navigation state into a persistable format.
  ///
  /// This method is called automatically by the restoration framework when the app
  /// needs to save its state (e.g., when backgrounded). The returned value should
  /// contain all necessary information to recreate the current navigation state.
  ///
  /// The serialized format (type `S`) must be compatible with Flutter's restoration
  /// system, typically primitive types like lists, maps, strings, and numbers.
  S serialize();

  /// Deserializes previously saved navigation state back into route objects.
  ///
  /// This method converts the persisted data (type `S`) back into the format needed
  /// to restore the navigation stack (type `D`). It's called during app launch when
  /// restoration data exists.
  ///
  /// The [data] parameter contains the value previously returned by [serialize].
  D deserialize(S data);

  /// Restores the navigation state from deserialized data.
  ///
  /// This method applies the deserialized routes or state to the actual navigation
  /// stack, replacing the current state with the restored one. It's called after
  /// [deserialize] to actually update the navigation.
  ///
  /// Implementations should clear the existing state and apply the restored data.
  void restore(D data);
}

/// A [RestorableValue] that manages the restoration of navigation route stacks.
///
/// ## What This Class Does
///
/// [NavigationPathRestorable] is the bridge between Flutter's restoration framework
/// and ZenRouter's navigation state. It implements Flutter's [RestorableValue] protocol
/// to save and restore a list of routes, handling the conversion between route objects
/// and the primitive types (strings, maps) that Flutter's restoration system can persist.
///
/// This class is used internally by [NavigationPath] to provide automatic state
/// restoration. You typically don't interact with this class directly - instead,
/// it works behind the scenes when you enable restoration by providing a
/// `restorationScopeId` to your MaterialApp.
///
/// ## Where It Fits in the Architecture
///
/// The restoration data flow:
/// ```
/// Flutter Restoration System
///   ↕ (primitives: strings, maps, lists)
/// NavigationPathRestorable
///   ↕ (route objects: HomeRoute, DetailRoute, etc.)
/// NavigationPath
///   ↕ (navigation stack)
/// Your App
/// ```
///
/// ## How It Handles Different Route Types
///
/// **RouteUnique routes (URI-based):**
/// - Serialized as URI strings: `"/home"`, `"/products/123"`
/// - Deserialized by parsing the URI and calling [parseRouteFromUri]
/// - Simple, compact, works for routes that can be fully represented by a URL
///
/// **RouteRestorable routes (custom converters):**
/// - Serialized as maps containing strategy and custom data
/// - Deserialized using registered [RestorableConverter] instances
/// - Supports complex routes with rich state that doesn't fit in a URL
///
/// ## When Serialization/Deserialization Happens
///
/// **Serialization ([toPrimitives]):**
/// - Called by Flutter when the app is backgrounded
/// - Called when the system needs to save state to free memory
/// - Converts each route in the stack to either a string or map
///
/// **Deserialization ([fromPrimitives]):**
/// - Called by Flutter when restoring the app after termination
/// - Called during hot restart in development (if enabled)
/// - Reconstructs route objects from the saved strings/maps
///
/// ## Example Output
///
/// For a navigation stack containing:
/// ```dart
/// [
///   HomeRoute(),
///   ProductDetailRoute(id: "123", data: {...}),
///   SettingsRoute(),
/// ]
/// ```
///
/// Serialized to:
/// ```dart
/// [
///   "/home",                              // RouteUnique as string
///   {                                     // RouteRestorable as map
///     "strategy": "converter",
///     "converter": "product_detail",
///     "value": {"id": "123", "data": {...}}
///   },
///   "/settings",                          // RouteUnique as string
/// ]
/// ```
///
/// See also:
/// - [RestorableValue] - Flutter's base class for restorable values
/// - [NavigationPath] - Uses this class for stack restoration
/// - [RouteRestorable] - Mixin for routes that need custom serialization
class NavigationPathRestorable<T extends RouteTarget>
    extends RestorableValue<List<T>> {
  /// Creates a restorable navigation path with the given route parser.
  ///
  /// The [parseRouteFromUri] function is used to convert URI strings back into
  /// route objects during deserialization. This must be a synchronous function
  /// that can handle all possible URIs that might be saved in the restoration data.
  NavigationPathRestorable(this.parseRouteFromUri);

  /// The function used to parse URIs back into route objects during restoration.
  ///
  /// This is typically the coordinator's [Coordinator.parseRouteFromUriSync] method.
  /// It must be synchronous because restoration happens during app initialization
  /// and cannot wait for asynchronous operations.
  final T Function(Uri uri) parseRouteFromUri;

  @override
  List<T> createDefaultValue() => [];

  @override
  void didUpdateValue(List<T>? oldValue) => notifyListeners();

  /// Converts saved primitive data back into a list of route objects.
  ///
  /// This is called by Flutter's restoration framework when the app is being
  /// restored. It receives the data that was previously returned by [toPrimitives]
  /// and reconstructs the route stack.
  ///
  /// Returns a list of route objects ready to be restored to the navigation stack.
  @override
  List<T> fromPrimitives(Object? data) => [
    for (final route in data as List)
      RouteTarget.deserialize(route, parseRouteFromUri: parseRouteFromUri) as T,
  ];

  /// Converts the current route stack into primitive types for persistence.
  ///
  /// This is called by Flutter's restoration framework when the app needs to
  /// save its state. It converts each route in [value] to either:
  /// - A URI string (for RouteUnique routes)
  /// - A map with serialization data (for RouteRestorable routes)
  ///
  /// The returned list contains only primitive types that Flutter's restoration
  /// system can persist (strings, maps, lists, numbers, booleans).
  ///
  /// Throws [UnimplementedError] if a route doesn't implement either [RouteUnique]
  /// or [RouteRestorable], as there's no way to serialize it.
  @override
  Object? toPrimitives() => [
    for (final route in value) RouteTarget.serialize(route),
  ];
}
