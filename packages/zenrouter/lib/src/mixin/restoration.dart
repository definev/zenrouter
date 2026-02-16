import 'package:zenrouter/zenrouter.dart';

/// Defines the strategy used to serialize and deserialize a route for state restoration.
///
/// ## What This Enum Represents
///
/// When Flutter needs to save your app's navigation state (for example, when the operating
/// system terminates your app to free memory), each route in the navigation stack must be
/// converted to a format that can be persisted. This enum determines which serialization
/// strategy ZenRouter uses for a particular route type.
///
/// ## The Two Strategies
///
/// **[unique]** - URI-based serialization:
/// This strategy serializes routes by converting them to their URI representation using
/// [RouteUnique.toUri]. The URI string is saved, and during restoration, the string is
/// parsed back into a route using your coordinator's [Coordinator.parseRouteFromUri] method.
/// This is the default and simplest strategy, suitable for routes where all necessary
/// information can be encoded in the URL path and query parameters.
///
/// **[converter]** - Custom serialization:
/// This strategy uses a custom [RestorableConverter] that you implement to serialize and
/// deserialize the route. This is necessary when your route contains complex data that
/// cannot (or should not) be represented in a URI, such as in-memory objects, computed
/// state, or data that's too large for a URL.
///
/// ## When to Use Each Strategy
///
/// Use **[unique]** when:
/// - Your route can be fully represented by its URI (path and query parameters)
/// - You want the simplest implementation with no custom serialization code
/// - The route's state can be reconstructed from the URL alone
/// - Examples: `/home`, `/products/123`, `/search?q=laptop`
///
/// Use **[converter]** when:
/// - Your route contains complex objects that can't be in a URL
/// - You need to preserve in-memory state like form data or user selections
/// - The amount of data is too large to reasonably fit in a URL
/// - You want explicit control over what gets saved and restored
/// - Examples: Routes with shopping cart items, complex filter objects, or rich text content
///
/// See also:
/// - [RouteRestorable] mixin for implementing restorable routes
/// - [RestorableConverter] for creating custom serializers
enum RestorationStrategy { unique, converter }

/// A mixin that enables custom state restoration for routes that cannot be fully represented by a URI.
///
/// ## What This Mixin Does
///
/// [RouteRestorable] extends [RouteTarget] to provide explicit control over how a route is
/// serialized to and deserialized from restoration data. While [RouteUnique] routes can only
/// be saved as URI strings, [RouteRestorable] routes can preserve arbitrary complex state
/// through custom serialization logic. This is essential for routes that carry rich data
/// objects, computed state, or information that doesn't belong in a URL.
///
/// ## Where to Use This Mixin
///
/// Apply this mixin to any route class that needs to preserve state beyond what can be
/// encoded in a URI. This is particularly common for:
/// - Detail pages with complex loaded data (avoiding refetching on restore)
/// - Routes with form state or user input that's not yet submitted
/// - Routes with computed or derived state that's expensive to recreate
/// - Routes with objects from your domain model (products, users, documents, etc.)
///
/// ## When Restoration Happens
///
/// **Serialization** ([serialize] is called):
/// Whenever the coordinator's state changes and Flutter needs to save navigation state to
/// the restoration bucket. This happens automatically in the background, typically when the
/// app goes to the background, the user switches to another app, or the system needs to free memory.
///
/// **Deserialization** ([deserialize] is called):
/// During app launch when Flutter detects existing restoration data. This happens when the system
/// restores your app after terminating it, when the user force-quits and relaunches the app
/// (on some platforms), or during development when hot restart occurs with restoration enabled.
///
/// ## How to Implement Custom Restoration
///
/// Complete implementation example combining all required pieces:
///
/// ```dart
/// // 1. Define your route with RouteRestorable
/// class BookDetailRoute extends AppRoute with RouteRestorable<BookDetailRoute> {
///   BookDetailRoute({required this.book});
///
///   final Book book;  // Complex object that can't be in URL
///
///   @override
///   RestorationStrategy get strategy => RestorationStrategy.converter;
///
///   @override
///   RestorableConverter<BookDetailRoute> get converter => const BookDetailConverter();
///
///   @override
///   String get restorationId => 'book_${book.id}';
///
///   @override
///   Uri toUri() => Uri.parse('/books/${book.id}');
/// }
///
/// // 2. Implement the converter
/// class BookDetailConverter extends RestorableConverter<BookDetailRoute> {
///   const BookDetailConverter();
///
///   @override
///   String get key => 'book_detail';
///
///   @override
///   Map<String, dynamic> serialize(BookDetailRoute route) => {
///     'id': route.book.id,
///     'title': route.book.title,
///     'author': route.book.author,
///   };
///
///   @override
///   BookDetailRoute deserialize(Map<String, dynamic> data) => BookDetailRoute(
///     book: Book(
///       id: data['id'],
///       title: data['title'],
///       author: data['author'],
///     ),
///   );
/// }
///
/// // 3. Register in your coordinator
/// class AppCoordinator extends Coordinator<AppRoute> {
///   @override
///   void defineConverter() {
///     RestorableConverter.defineConverter('book_detail', BookDetailConverter.new);
///   }
/// }
/// ```
///
/// ## Important Considerations
///
/// **Converter keys must be globally unique and stable:** Never change a converter's key in
/// production as it will break restoration for existing users. Prefix keys with your app or
/// package name to avoid collisions.
///
/// **Serialize efficiently:** Only serialize the minimum data needed to reconstruct the route.
/// Large serialized data slows down app startup during restoration.
///
/// **Handle missing data gracefully:** Your deserialize method should handle cases where data
/// might be missing or invalid from older app versions. Provide sensible defaults or fail gracefully.
///
/// See also:
/// - [RestorableConverter] for implementing the serialization logic
/// - [RestorationStrategy] for understanding the available strategies
/// - [CoordinatorRestorable] for the overall restoration orchestration
mixin RouteRestorable<T extends RouteTarget> on RouteTarget {
  /// Serializes a [RouteRestorable] route into a map that can be persisted.
  ///
  /// This static method is called internally by the restoration system to convert a route
  /// into a format that can be saved to the restoration bucket. It inspects the route's
  /// [restorationStrategy] and delegates to either URI-based or converter-based serialization.
  Map<String, dynamic> serialize() => {
    'strategy': restorationStrategy.name,
    if (restorationStrategy == RestorationStrategy.converter) ...{
      'converter': converter.key,
      'value': converter.serialize(this as T),
    } else if (restorationStrategy == RestorationStrategy.unique &&
        this is RouteUnique) ...{
      'value': (this as RouteUnique).toUri().toString(),
    },
  };

  /// Deserializes restoration data back into a [RouteTarget] instance.
  ///
  /// This static method is called during app startup when restoration data exists. It
  /// examines the [data] map to determine which restoration strategy was used and
  /// then delegates to the appropriate deserialization method.
  ///
  /// For [RestorationStrategy.unique] routes, it requires a [parseRouteFromUri] function
  /// to convert the saved URI string back into a route object.
  ///
  /// For [RestorationStrategy.converter] routes, it looks up the converter by key and
  /// uses it to deserialize the route.
  static T deserialize<T extends RouteTarget>(
    Map<String, dynamic> data, {
    required RouteUriParserSync<T>? parseRouteFromUri,
  }) {
    final rawStrategy = data['strategy'];
    if (rawStrategy == null || rawStrategy is! String) {
      throw UnimplementedError();
    }
    final strategy = RestorationStrategy.values.asNameMap()[rawStrategy]!;
    assert(
      (strategy == RestorationStrategy.converter ||
          (strategy == RestorationStrategy.unique &&
              parseRouteFromUri != null)),
      'Invalid strategy: $strategy or parseRouteFromUri is null when parsing .unique strategy',
    );
    switch (strategy) {
      case RestorationStrategy.unique:
        final value = parseRouteFromUri!(Uri.parse(data['value']! as String));
        if (value is Future) throw UnimplementedError();
        return value;
      case RestorationStrategy.converter:
        final converter = RestorableConverter.buildConverter(
          data['converter']! as String,
        );
        if (converter == null) throw UnimplementedError();
        final route = converter.deserialize((data['value']! as Map).cast());
        return route as T;
    }
  }

  // coverage:ignore-start
  /// The restoration strategy to use for this route.
  ///
  /// Defaults to [RestorationStrategy.unique], which serializes the route using its URI.
  /// Override to return [RestorationStrategy.converter] when you need custom serialization.
  RestorationStrategy get restorationStrategy => RestorationStrategy.unique;

  /// The converter to use when [restorationStrategy] is [RestorationStrategy.converter].
  ///
  /// This getter must be overridden (it throws [UnimplementedError] by default) when using
  /// custom serialization. Return an instance of your [RestorableConverter] implementation.
  RestorableConverter<T> get converter => throw UnimplementedError();
  // coverage:ignore-end

  /// The unique identifier for this route in the restoration system.
  ///
  /// This must be unique within your application and stable across app versions. It's used
  /// by Flutter's restoration framework to associate saved state with route instances.
  String get restorationId;
}

/// An abstract base class for implementing custom serialization logic for routes.
///
/// ## What This Class Does
///
/// [RestorableConverter] provides the interface for converting route objects to and from
/// primitive data types that can be persisted by Flutter's restoration framework. When a
/// route implements [RouteRestorable] with [RestorationStrategy.converter], it must provide
/// a converter that knows how to break down the route into serializable data (maps, lists,
/// strings, numbers) and reconstruct it from that same data structure.
///
/// ## Where It Fits in the Architecture
///
/// Converters are registered globally in your [Coordinator] via [defineConverter] during
/// initialization. When the restoration system needs to serialize or deserialize a route,
/// it looks up the converter by its unique key and delegates the work to it. This architecture
/// allows converters to be reused across different parts of your application and provides
/// a centralized registry for all custom serialization logic.
///
/// The registration and usage flow:
/// ```
/// App startup:
///   Coordinator.defineConverter() registers converters
///     └─ RestorableConverter.defineConverter('key', constructor)
///         └─ Stored in global _converterTable
///
/// During restoration:
///   RouteRestorable.deserialize(data)
///     └─ RestorableConverter.buildConverter(key)
///         └─ Lookup in _converterTable
///             └─ Call converter.deserialize(data)
/// ```
///
/// ## When This Gets Called
///
/// **[serialize]** is invoked:
/// When the coordinator's navigation state changes and Flutter needs to persist the current
/// state to the restoration bucket. This happens automatically in the background, typically
/// whenever routes are pushed, popped, or their state changes, and the app is in a state
/// where it might be terminated by the system.
///
/// **[deserialize]** is invoked:
/// During app startup, before the first frame is rendered, when Flutter detects existing
/// restoration data. The restoration system calls this method to reconstruct route objects
/// from the previously saved primitive data, allowing the app to return to the exact state
/// it was in before termination.
///
/// ## How to Implement a Custom Converter
///
/// Create a subclass of [RestorableConverter] and implement the three required members:
///
/// ```dart
/// class UserProfileConverter extends RestorableConverter<UserProfileRoute> {
///   const UserProfileConverter();
///
///   // 1. Provide a unique, stable key for this converter
///   @override
///   String get key => 'myapp_user_profile';
///
///   // 2. Convert route to serializable data
///   @override
///   Map<String, dynamic> serialize(UserProfileRoute route) {
///     return {
///       'userId': route.user.id,
///       'userName': route.user.name,
///       'userEmail': route.user.email,
///       'viewMode': route.viewMode.name,  // enum serialized as string
///     };
///   }
///
///   // 3. Reconstruct route from serialized data
///   @override
///   UserProfileRoute deserialize(Map<String, dynamic> data) {
///     return UserProfileRoute(
///       user: User(
///         id: data['userId'] as String,
///         name: data['userName'] as String,
///         email: data['userEmail'] as String,
///       ),
///       viewMode: ViewMode.values.byName(data['viewMode'] as String),
///     );
///   }
/// }
/// ```
///
/// Then register it in your coordinator:
///
/// ```dart
/// class AppCoordinator extends Coordinator<AppRoute> {
///   @override
///   void defineConverter() {
///     RestorableConverter.defineConverter(
///       'myapp_user_profile',
///       () => const UserProfileConverter(),
///     );
///   }
/// }
/// ```
///
/// ## Important Implementation Guidelines
///
/// **Keys must be globally unique:** The [key] getter must return a string that uniquely
/// identifies this converter across your entire application and all installed packages.
/// Use a prefix like your app or package name to avoid collisions with third-party code.
///
/// **Keys must never change:** Once deployed to production, never change a converter's key.
/// Changing it will cause restoration to fail for users who have saved state with the old
/// key. If you need to change the serialization format, add versioning within your converter
/// instead of changing the key.
///
/// **Only serialize necessary data:** The [serialize] method should only output the minimum
/// data needed to reconstruct the route. Avoid serializing computed values, large objects,
/// or anything that can be derived or refetched. Remember that this data is saved to disk
/// and loaded synchronously at startup, so excessive data will slow down app launch.
///
/// **Handle version changes gracefully:** Your [deserialize] method should be defensive
/// about missing or unexpected data. Users might restore from data saved by an older version
/// of your app, so handle missing fields with sensible defaults:
///
/// ```dart
/// @override
/// MyRoute deserialize(Map<String, dynamic> data) {
///   return MyRoute(
///     id: data['id'] as String,
///     // Provide default for fields that might be missing in old data
///     newField: data['newField'] as String? ?? 'default_value',
///   );
/// }
/// ```
///
/// **Use const constructors:** Converters should be stateless and use const constructors
/// for better performance. The same converter instance can be used for multiple serialization
/// and deserialization operations.
///
/// ## Global Registry Pattern
///
/// The converter registry is a global singleton map that associates converter keys with
/// constructor functions. This design allows converters to be registered once during app
/// initialization and then efficiently looked up during restoration without maintaining
/// references to coordinator instances or other complex state management.
///
/// See also:
/// - [RouteRestorable] for implementing routes that use converters
/// - [RestorationStrategy.converter] for when to use custom serialization
abstract class RestorableConverter<T extends Object> {
  // coverage:ignore-start
  const RestorableConverter();
  // coverage:ignore-end

  /// The global registry mapping converter keys to their constructor functions.
  ///
  /// This table is populated during app initialization via [defineConverter] and queried
  /// during restoration via [buildConverter]. It persists for the entire application lifetime.
  static final Map<String, RestoratableConverterConstructor> _converterTable =
      {};

  /// Registers a converter in the global registry.
  ///
  /// Call this method during coordinator initialization ([Coordinator.defineConverter]) to
  /// make your custom converter available to the restoration system. The [key] must match
  /// the key returned by your converter's [key] getter, and the [constructor] should be a
  /// function that creates a new instance of your converter (typically a const constructor).
  ///
  /// Example:
  /// ```dart
  /// RestorableConverter.defineConverter(
  ///   'user_profile',
  ///   () => const UserProfileConverter(),
  /// );
  /// ```
  static void defineConverter<T extends Object>(
    String key,
    RestoratableConverterConstructor<T> constructor,
  ) => _converterTable[key] = constructor;

  /// Looks up and constructs a converter by its key.
  ///
  /// This method is called internally during route deserialization to find the appropriate
  /// converter for a given route type. Returns `null` if no converter is registered with
  /// the given [key], which typically indicates a configuration error or version mismatch.
  static RestorableConverter? buildConverter(String key) {
    if (!_converterTable.containsKey(key)) return null;
    return _converterTable[key]!();
  }

  /// Converts [RouteTarget] to primitive data
  ///
  /// This is called by Flutter's restoration framework when the app is being
  /// killed.
  ///
  /// Built-in Types supports:
  /// - [RouteLayout] - Serialize [RouteLayout]
  /// - [RouteRestorable] - Call custom `serialize` method
  /// - [RouteUnique] - Leverage `toUri` for serialization
  static Object serializeRoute(RouteTarget value) => switch (value) {
    RouteLayout() => value.serialize(),
    RouteRestorable() => value.serialize(),
    RouteUnique() => value.toUri().toString(),
    _ => throw UnimplementedError(),
  };

  /// Converts saved primitive data back into a route object.
  ///
  /// This is called by Flutter's restoration framework when the app is being
  /// restored. It receives the data that was previously returned by [toPrimitives]
  /// and reconstructs the route stack.
  static RT? deserializeRoute<RT extends RouteTarget>(
    Object value, {
    required RouteLayoutParentConstructor? resolveRouteLayoutParent,
    required GetLayoutKeyCallback? getLayoutKey,
    required RouteUriParserSync? parseRouteFromUri,
  }) => switch (value) {
    String() => parseRouteFromUri!(Uri.parse(value)) as RT,
    Map()
        when value['type'] == 'layout' &&
            resolveRouteLayoutParent != null &&
            getLayoutKey != null =>
      RouteLayout.deserialize(
            resolveRouteLayoutParent,
            getLayoutKey,
            value.cast(),
          )
          as RT,
    Map() =>
      RouteRestorable.deserialize(
            value.cast(),
            parseRouteFromUri: parseRouteFromUri,
          )
          as RT,
    // coverage:ignore-start
    _ => null,
    // coverage:ignore-end
  };

  /// The unique identifier for this converter.
  ///
  /// This key is used to store and retrieve converter instances from the global registry.
  /// It must be unique across your application and stable across app versions. Changing
  /// this key in a deployed app will break restoration for existing users.
  String get key;

  /// Converts a route into primitive data that can be persisted.
  ///
  /// The returned map should only contain primitive Dart types (String, int, double, bool,
  /// List, Map) that can be serialized by Flutter's restoration framework. Avoid complex
  /// objects, closures, or circular references.
  Map<String, dynamic> serialize(T route);

  /// Reconstructs a route from previously serialized data.
  ///
  /// This method receives the same map structure that was returned by [serialize] and must
  /// reconstruct the original route object. Handle missing or invalid data gracefully to
  /// support restoration from older app versions.
  T deserialize(Map<String, dynamic> data);
}
