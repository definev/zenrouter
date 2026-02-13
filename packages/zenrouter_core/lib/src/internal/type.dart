
import 'package:zenrouter_core/src/mixin/identity.dart';
import 'package:zenrouter_core/src/mixin/layout.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

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
/// - [RoutePath], the base class for layout implementations.
typedef RoutePathConstructor<T extends RouteIdentity> =
    RoutePath<T> Function();

