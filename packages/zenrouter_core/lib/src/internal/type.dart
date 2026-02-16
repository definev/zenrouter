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
