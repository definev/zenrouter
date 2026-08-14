import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/routing/cancellation.dart';
import 'package:zenrouter_core/src/routing/hydration.dart';

const _noHydrationData = _NoHydrationData();

final class _NoHydrationData {
  const _NoHydrationData();
}

Map<String, List<String>> _freezeHeaders(Map<String, List<String>> headers) =>
    Map<String, List<String>>.unmodifiable({
      for (final entry in headers.entries)
        entry.key.toLowerCase(): List<String>.unmodifiable(entry.value),
    });

String _normalizeMethod(String method) {
  final normalized = method.trim().toUpperCase();
  if (normalized.isEmpty) {
    throw ArgumentError.value(method, 'method', 'Must not be empty');
  }
  return normalized;
}

Map<String, List<String>> _withoutBodyHeaders(
  Map<String, List<String>> headers,
) => Map<String, List<String>>.from(headers)
  ..remove('content-encoding')
  ..remove('content-language')
  ..remove('content-length')
  ..remove('content-location')
  ..remove('content-type')
  ..remove('transfer-encoding');

/// Request-scoped input shared by navigation and server rendering adapters.
final class RouteRequest {
  RouteRequest({
    required this.uri,
    String method = 'GET',
    Map<String, List<String>> headers = const {},
    this.body,
    this.state,
    RouteCancellationToken? cancellationToken,
  }) : method = _normalizeMethod(method),
       headers = _freezeHeaders(headers),
       cancellationToken = cancellationToken ?? RouteCancellationToken();

  /// Convenience request for client-side navigation.
  RouteRequest.navigation(
    this.uri, {
    this.state,
    RouteCancellationToken? cancellationToken,
  }) : method = 'GET',
       headers = const {},
       body = null,
       cancellationToken = cancellationToken ?? RouteCancellationToken();

  final Uri uri;
  final String method;
  final Map<String, List<String>> headers;
  final Object? body;

  /// Adapter-owned state such as a browser history entry or request context.
  final Object? state;

  /// Cooperative cancellation shared across redirects for this request.
  final RouteCancellationToken cancellationToken;
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
    RouteHydrationPayload? hydration,
    @Deprecated('Use hydration') Object? data = _noHydrationData,
  }) : assert(statusCode >= 100 && statusCode <= 599),
       headers = _freezeHeaders(headers),
       hydration =
           hydration ??
           (identical(data, _noHydrationData)
               ? null
               : RouteHydrationPayload(routeUri: request.uri, data: data)) {
    if (hydration != null && !identical(data, _noHydrationData)) {
      throw ArgumentError('Provide either hydration or legacy data, not both');
    }
  }

  final RouteRequest request;
  final int statusCode;
  final Map<String, List<String>> headers;

  /// Versioned, serializable loader data associated with this resolution.
  final RouteHydrationPayload? hydration;

  /// Compatibility view of [RouteHydrationPayload.data].
  @Deprecated('Use hydration?.data')
  Object? get data => hydration?.data;
}

/// A successfully matched route.
final class MatchedRouteResolution<T extends RouteUri>
    extends RouteResolution<T> {
  MatchedRouteResolution({
    required super.request,
    required this.route,
    super.statusCode = 200,
    super.headers,
    super.hydration,
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
    super.hydration,
    super.data,
  });

  final T? route;
}

/// A redirect outcome that an HTTP or browser adapter can apply correctly.
final class RedirectRouteResolution<T extends RouteUri>
    extends RouteResolution<T> {
  static const supportedStatusCodes = <int>{301, 302, 303, 307, 308};

  RedirectRouteResolution({
    required super.request,
    required this.location,
    super.statusCode = 302,
    super.headers,
    super.hydration,
    super.data,
  }) {
    if (!supportedStatusCodes.contains(statusCode)) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Supported redirect statuses are 301, 302, 303, 307, and 308',
      );
    }
  }

  final Uri location;

  /// Builds the follow-up request using RFC-compatible redirect semantics.
  ///
  /// - 307/308 preserve method and body.
  /// - 303 changes every method except HEAD to GET.
  /// - 301/302 change POST to GET for historical user-agent compatibility.
  RouteRequest createRedirectRequest() {
    final previousMethod = request.method;
    final redirectedMethod = switch (statusCode) {
      303 when previousMethod != 'HEAD' => 'GET',
      301 || 302 when previousMethod == 'POST' => 'GET',
      _ => previousMethod,
    };
    final preservesBody = switch (statusCode) {
      303 => false,
      _ => redirectedMethod == previousMethod,
    };

    return RouteRequest(
      uri: request.uri.resolveUri(location),
      method: redirectedMethod,
      headers: preservesBody
          ? request.headers
          : _withoutBodyHeaders(request.headers),
      body: preservesBody ? request.body : null,
      state: request.state,
      cancellationToken: request.cancellationToken,
    );
  }
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
    super.hydration,
    super.data,
  });

  final Object error;
  final StackTrace stackTrace;
}

/// Seam implemented by routing kernels and consumed by rendering adapters.
abstract interface class RouteResolver<T extends RouteUri> {
  Future<RouteResolution<T>> resolveRoute(RouteRequest request);
}
