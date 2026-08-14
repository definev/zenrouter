import 'package:zenrouter_core/src/mixin/uri.dart';

Map<String, List<String>> _freezeHeaders(Map<String, List<String>> headers) =>
    Map<String, List<String>>.unmodifiable({
      for (final entry in headers.entries)
        entry.key.toLowerCase(): List<String>.unmodifiable(entry.value),
    });

/// Request-scoped input shared by navigation and server rendering adapters.
final class RouteRequest {
  RouteRequest({
    required this.uri,
    this.method = 'GET',
    Map<String, List<String>> headers = const {},
    this.body,
    this.state,
  }) : headers = _freezeHeaders(headers);

  /// Convenience request for client-side navigation.
  RouteRequest.navigation(this.uri, {this.state})
    : method = 'GET',
      headers = const {},
      body = null;

  final Uri uri;
  final String method;
  final Map<String, List<String>> headers;
  final Object? body;

  /// Adapter-owned state such as a browser history entry or request context.
  final Object? state;
}

/// Marker for a route that renders a not-found result while preserving the
/// originally requested URI.
mixin RouteNotFound on RouteUri {}

/// Typed outcome produced before any rendering adapter runs.
sealed class RouteResolution<T extends RouteUri> {
  RouteResolution({
    required this.request,
    required this.statusCode,
    Map<String, List<String>> headers = const {},
    this.data,
  }) : assert(statusCode >= 100 && statusCode <= 599),
       headers = _freezeHeaders(headers);

  final RouteRequest request;
  final int statusCode;
  final Map<String, List<String>> headers;

  /// Loader or adapter-neutral hydration data associated with this resolution.
  final Object? data;
}

/// A successfully matched route.
final class MatchedRouteResolution<T extends RouteUri>
    extends RouteResolution<T> {
  MatchedRouteResolution({
    required super.request,
    required this.route,
    super.statusCode = 200,
    super.headers,
    super.data,
  });

  final T route;
}

/// A not-found outcome. [route] may render a framework-specific 404 page.
final class NotFoundRouteResolution<T extends RouteUri>
    extends RouteResolution<T> {
  NotFoundRouteResolution({
    required super.request,
    this.route,
    super.statusCode = 404,
    super.headers,
    super.data,
  });

  final T? route;
}

/// A redirect outcome that an HTTP or browser adapter can apply correctly.
final class RedirectRouteResolution<T extends RouteUri>
    extends RouteResolution<T> {
  RedirectRouteResolution({
    required super.request,
    required this.location,
    super.statusCode = 302,
    super.headers,
    super.data,
  }) : assert(statusCode >= 300 && statusCode <= 399);

  final Uri location;
}

/// A typed routing failure suitable for an error page or HTTP 5xx response.
final class ErrorRouteResolution<T extends RouteUri>
    extends RouteResolution<T> {
  ErrorRouteResolution({
    required super.request,
    required this.error,
    required this.stackTrace,
    super.statusCode = 500,
    super.headers,
    super.data,
  });

  final Object error;
  final StackTrace stackTrace;
}

/// Seam implemented by routing kernels and consumed by rendering adapters.
abstract interface class RouteResolver<T extends RouteUri> {
  Future<RouteResolution<T>> resolveRoute(RouteRequest request);
}
