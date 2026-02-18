import 'package:zenrouter_core/src/mixin/uri.dart';

/// Synchronous parser function that converts a [Uri] into a route instance.
///
/// Used by the restoration system to restore navigation state from URLs.
/// The parser extracts route information from the URI and constructs
/// an appropriate route instance of type [T].
typedef RouteUriParserSync<T extends RouteUri> = T Function(Uri uri);
