import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

typedef VoidCallback = void Function();

class TestRoute extends RouteUri {
  TestRoute(this.uri);

  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  List<Object?> get props => [uri];
}

class MissingRoute extends TestRoute with RouteNotFound {
  MissingRoute(super.uri);
}

mixin _TestListenable {
  void addListener(VoidCallback listener) {}
  void removeListener(VoidCallback listener) {}
  void notifyListeners() {}
}

class _TestPath extends StackPath<TestRoute> with _TestListenable {
  _TestPath() : super([]);

  @override
  TestRoute? get activeRoute => stack.lastOrNull;

  @override
  PathKey get pathKey => const PathKey('resolution-test');

  @override
  Future<void> activateRoute(TestRoute route) async {}

  @override
  void reset() {}
}

class TestCoordinator extends CoordinatorCore<TestRoute> with _TestListenable {
  TestCoordinator(this.parser);

  final FutureOr<TestRoute?> Function(Uri uri) parser;

  @override
  late final StackPath<TestRoute> root = _TestPath();

  @override
  FutureOr<TestRoute?> parseRouteFromUri(Uri uri) => parser(uri);

  @override
  void defineLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  ) {}

  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) => null;
}

void main() {
  test('legacy parser resolves a matched route', () async {
    final coordinator = TestCoordinator(TestRoute.new);
    final request = RouteRequest.navigation(Uri.parse('/products/1'));

    final resolution = await coordinator.resolveRoute(request);

    expect(resolution, isA<MatchedRouteResolution<TestRoute>>());
    expect(resolution.statusCode, 200);
    expect(
      (resolution as MatchedRouteResolution<TestRoute>).route.toUri(),
      request.uri,
    );
  });

  test('null parser result becomes a typed 404', () async {
    final coordinator = TestCoordinator((_) => null);
    final request = RouteRequest.navigation(Uri.parse('/missing'));

    final resolution = await coordinator.resolveRoute(request);

    expect(resolution, isA<NotFoundRouteResolution<TestRoute>>());
    expect(resolution.statusCode, 404);
  });

  test('not-found route preserves requested URI and 404 status', () async {
    final requestedUri = Uri.parse('/still-missing?from=test');
    final coordinator = TestCoordinator(MissingRoute.new);

    final resolution = await coordinator.resolveRoute(
      RouteRequest.navigation(requestedUri),
    );

    final notFound = resolution as NotFoundRouteResolution<TestRoute>;
    expect(notFound.statusCode, 404);
    expect(notFound.route?.toUri(), requestedUri);
  });

  test('parser failure becomes a typed 500 outcome', () async {
    final coordinator = TestCoordinator((_) => throw StateError('broken'));

    final resolution = await coordinator.resolveRoute(
      RouteRequest.navigation(Uri.parse('/broken')),
    );

    expect(resolution, isA<ErrorRouteResolution<TestRoute>>());
    expect(resolution.statusCode, 500);
    expect(
      (resolution as ErrorRouteResolution<TestRoute>).error,
      isA<StateError>(),
    );
  });

  test('request and response headers are frozen and normalized', () {
    final sourceHeaders = <String, List<String>>{
      'X-Test': ['a'],
    };
    final request = RouteRequest(uri: Uri.parse('/'), headers: sourceHeaders);
    final resolution = RedirectRouteResolution<TestRoute>(
      request: request,
      location: Uri.parse('/login'),
      statusCode: 307,
      headers: const {
        'Location': ['/login'],
      },
    );

    sourceHeaders['X-Test']!.add('b');

    expect(request.headers, {
      'x-test': ['a'],
    });
    expect(resolution.headers, {
      'location': ['/login'],
    });
    expect(
      () => resolution.headers['location']!.add('/other'),
      throwsUnsupportedError,
    );
  });

  group('redirect continuation', () {
    test('normalizes request methods and rejects an empty method', () {
      expect(
        RouteRequest(uri: Uri.parse('/'), method: ' post ').method,
        'POST',
      );
      expect(
        () => RouteRequest(uri: Uri.parse('/'), method: '  '),
        throwsArgumentError,
      );
    });

    for (final statusCode in [301, 302]) {
      test('$statusCode converts POST to GET and drops body headers', () {
        final token = RouteCancellationToken();
        final state = Object();
        final request = RouteRequest(
          uri: Uri.parse('https://example.test/orders/current'),
          method: 'POST',
          headers: const {
            'Content-Type': ['application/json'],
            'Content-Length': ['12'],
            'X-Trace': ['trace-1'],
          },
          body: '{"ok":true}',
          state: state,
          cancellationToken: token,
        );
        final redirect = RedirectRouteResolution<TestRoute>(
          request: request,
          location: Uri.parse('../next'),
          statusCode: statusCode,
        );

        final followUp = redirect.createRedirectRequest();

        expect(followUp.uri, Uri.parse('https://example.test/next'));
        expect(followUp.method, 'GET');
        expect(followUp.body, isNull);
        expect(followUp.headers, {
          'x-trace': ['trace-1'],
        });
        expect(followUp.state, same(state));
        expect(followUp.cancellationToken, same(token));
      });
    }

    test('303 converts non-HEAD methods to GET', () {
      final put = RouteRequest(
        uri: Uri.parse('/submit'),
        method: 'PUT',
        body: 'payload',
      );
      final head = RouteRequest(uri: Uri.parse('/submit'), method: 'HEAD');

      expect(
        RedirectRouteResolution<TestRoute>(
          request: put,
          location: Uri.parse('/result'),
          statusCode: 303,
        ).createRedirectRequest(),
        isA<RouteRequest>()
            .having((request) => request.method, 'method', 'GET')
            .having((request) => request.body, 'body', isNull),
      );
      expect(
        RedirectRouteResolution<TestRoute>(
          request: head,
          location: Uri.parse('/result'),
          statusCode: 303,
        ).createRedirectRequest().method,
        'HEAD',
      );
    });

    for (final statusCode in [307, 308]) {
      test('$statusCode preserves method, body, and body headers', () {
        final request = RouteRequest(
          uri: Uri.parse('/submit'),
          method: 'PATCH',
          headers: const {
            'Content-Type': ['application/json'],
          },
          body: 'payload',
        );

        final followUp = RedirectRouteResolution<TestRoute>(
          request: request,
          location: Uri.parse('/other'),
          statusCode: statusCode,
        ).createRedirectRequest();

        expect(followUp.method, 'PATCH');
        expect(followUp.body, 'payload');
        expect(followUp.headers['content-type'], ['application/json']);
      });
    }

    test('rejects status codes without redirect method semantics', () {
      final request = RouteRequest.navigation(Uri.parse('/'));

      for (final statusCode in [300, 304, 305, 306, 309]) {
        expect(
          () => RedirectRouteResolution<TestRoute>(
            request: request,
            location: Uri.parse('/other'),
            statusCode: statusCode,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('route resolution cancellation', () {
    test('token is idempotent and exposes its reason', () async {
      final token = RouteCancellationToken();

      expect(token.cancel('newer navigation'), isTrue);
      expect(token.cancel('ignored'), isFalse);
      expect(token.reason, 'newer navigation');
      expect(await token.whenCancelled, 'newer navigation');
      expect(
        token.throwIfCancelled,
        throwsA(
          isA<RouteResolutionCancelled>().having(
            (error) => error.reason,
            'reason',
            'newer navigation',
          ),
        ),
      );
      expect(
        const RouteResolutionCancelled().toString(),
        'Route resolution cancelled',
      );
      expect(
        const RouteResolutionCancelled('gone').toString(),
        'Route resolution cancelled: gone',
      );
    });

    test(
      'default resolver propagates cancellation instead of creating 500',
      () async {
        final token = RouteCancellationToken()..cancel('disconnected');
        final coordinator = TestCoordinator(TestRoute.new);

        await expectLater(
          coordinator.resolveRoute(
            RouteRequest.navigation(
              Uri.parse('/cancelled'),
              cancellationToken: token,
            ),
          ),
          throwsA(isA<RouteResolutionCancelled>()),
        );
      },
    );
  });
}
