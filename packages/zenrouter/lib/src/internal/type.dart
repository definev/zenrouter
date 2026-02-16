import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// Synchronous parser function that converts a [Uri] into a route instance.
///
/// This typedef defines a function signature for parsing URIs into route objects.
/// The parser should extract route information from the URI and construct
/// an appropriate route instance of type [T].
///
/// **Parameters:**
/// - `uri`: The URI to parse into a route.
///
/// **Returns:**
/// A route instance of type [T] that represents the parsed URI.
///
/// **Example:**
/// ```dart
/// RouteUriParserSync<AppRoute> parser = (Uri uri) {
///   final path = uri.path;
///   if (path == '/home') return HomeRoute();
///   if (path == '/settings') return SettingsRoute();
///   return NotFoundRoute();
/// };
/// ```
typedef RouteUriParserSync<T extends RouteTarget> = T Function(Uri uri);

/// Builder function for creating a layout widget that wraps route content.
///
/// This typedef defines a function signature for building layout widgets that
/// can wrap and decorate the content of routes in a navigation stack. Layouts
/// are useful for adding common UI elements like app bars, navigation rails,
/// or background decorations around route content.
///
/// **Parameters:**
/// - `coordinator`: The coordinator managing navigation state.
/// - `path`: The current navigation stack path containing the route.
/// - `layout`: Optional layout instance that may contain additional configuration.
///
/// **Returns:**
/// A [Widget] that provides the layout structure for the route.
///
/// See also:
/// - [RouteLayoutConstructor], which creates layout instances.
/// - [RouteLayout], the base class for layout implementations.
typedef RouteLayoutBuilder<T extends RouteUnique> =
    Widget Function(
      CoordinatorCore coordinator,
      StackPath<T> path,
      RouteLayout<T>? layout,
    );

/// Constructor function for creating a layout instance.
///
/// This typedef defines a function signature for constructing [RouteLayout]
/// instances. Layout constructors are typically used in route definitions to
/// specify which layout should wrap the route's content.
///
/// **Returns:**
/// A new [RouteLayout] instance of type [T].
///
/// **Example:**
/// ```dart
/// RouteLayoutConstructor<AppRoute> constructor = () => MainLayout();
/// ```
///
/// See also:
/// - [RouteLayoutBuilder], which builds the layout widget.
/// - [RouteLayout], the base class for layout implementations.
typedef RouteLayoutConstructor<T extends RouteUnique> =
    RouteLayout<T> Function();

/// Constructor function for creating a layout instance.
///
/// This typedef defines a function signature for constructing [RouteLayout]
/// instances. Layout constructors are typically used in route definitions to
/// specify which layout should wrap the route's content.
///
/// **Returns:**
/// A new [RouteLayout] instance of type [T].
///
/// **Example:**
/// ```dart
/// RouteLayoutConstructor<AppRoute> constructor = () => MainLayout();
/// ```
///
/// See also:
/// - [RouteLayoutBuilder], which builds the layout widget.
/// - [RouteLayout], the base class for layout implementations.
typedef RouteLayoutWithKeyConstructor<T extends RouteUnique> =
    RouteLayout<T> Function(Object layoutKey);

/// Widget builder for query parameters.
///
/// You can use this typedef to allow passing the [RouteQueryParameters.selectorBuilder] to inner widgets.
typedef QuerySelectorBuilder<T> =
    Widget Function({
      required T Function(Map<String, String> queries) selector,
      required Widget Function(BuildContext context, T value) builder,
    });

/// Constructor function for creating a restorable value converter.
///
/// This typedef defines a function signature for constructing [RestorableConverter]
/// instances. Restorable converters are used to serialize and deserialize route
/// data for state restoration, allowing routes to be recreated after app restarts
/// or process death.
///
/// **Type Parameters:**
/// - `T`: The type of object that can be converted. Must be a non-nullable Object.
///
/// **Returns:**
/// A new [RestorableConverter] instance that can convert values of type [T].
///
/// **Example:**
/// ```dart
/// RestoratableConverterConstructor<User> converter = () => UserConverter();
/// ```
///
/// See also:
/// - [RestorableConverter], the base class for implementing converters.
/// - [RouteRestoration], mixin for routes that support state restoration.
typedef RestoratableConverterConstructor<T extends Object> =
    RestorableConverter<T> Function();

/// Callback that builds a [Page] from a route and child widget.
///
/// This typedef defines a function signature for creating [Page] instances that
/// wrap route widgets in the navigation stack. Pages are the fundamental building
/// blocks used by Flutter's [Navigator] to manage routes.
///
/// **Parameters:**
/// - `context`: The build context for the page.
/// - `routeKey`: A unique key identifying this route instance. Typically derived
///   from the route's identity.
/// - `child`: The widget content to be wrapped by the page.
///
/// **Returns:**
/// A [Page] instance that wraps the child widget.
///
/// **Example:**
/// ```dart
/// PageCallback<AppRoute> callback = (context, routeKey, child) {
///   return MaterialPage(
///     key: routeKey,
///     child: child,
///   );
/// };
/// ```
///
/// See also:
/// - [StackTransition], which provides different page transition styles.
typedef PageCallback<T> =
    Page<void> Function(
      BuildContext context,
      ValueKey<T> routeKey,
      Widget child,
    );

/// Callback that maps routes to their [StackTransition].
///
/// Used by [NavigationStack] to determine how each route should be displayed.
///
/// **Example - Route-based transitions:**
/// ```dart
/// NavigationStack(
///   path: coordinator.root,
///   coordinator: coordinator,
///   resolver: (route) {
///     return switch (route) {
///       // Dialogs use dialog transition
///       ConfirmRoute() => StackTransition.dialog(route.build(coordinator, context)),
///
///       // Sheets use sheet transition
///       ShareRoute() => StackTransition.sheet(route.build(coordinator, context)),
///
///       // iOS gets cupertino, others get material
///       _ when Platform.isIOS => StackTransition.cupertino(
///         route.build(coordinator, context),
///       ),
///       _ => StackTransition.material(route.build(coordinator, context)),
///     };
///   },
/// )
/// ```
///
/// **Example - RouteTransition mixin:**
/// Routes can also define their own transition by mixing in [RouteTransition]:
/// ```dart
/// class SettingsRoute extends RouteTarget with RouteUnique, RouteTransition {
///   @override
///   StackTransition<T> transition<T extends RouteUnique>(Coordinator coordinator) {
///     return StackTransition.cupertino(build(coordinator, context));
///   }
/// }
/// ```
typedef StackTransitionResolver<T extends RouteTarget> =
    StackTransition<T> Function(T route);
